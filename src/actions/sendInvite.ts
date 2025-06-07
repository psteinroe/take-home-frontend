'use server';

import { Database } from '@/lib/supabase/database';
import { createServerClient } from '@supabase/ssr';
import { cookies } from 'next/headers';
import { Resend } from 'resend';

const resend = new Resend(process.env.RESEND_API_KEY);

export async function sendInvite(email: string) {
  const cookieStore = await cookies();

  const supabase = createServerClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return cookieStore.getAll();
        },
        setAll(cookiesToSet) {
          try {
            cookiesToSet.forEach(({ name, value, options }) =>
              cookieStore.set(name, value, options)
            );
          } catch {}
        }
      }
    }
  );

  const {
    data: { user }
  } = await supabase.auth.getUser();

  if (!user) {
    return { success: false, error: 'Not authenticated' };
  }

  const { data: employees } = await supabase
    .from('employee')
    .select('*')
    .eq('user_id', user.id)
    .limit(1);

  const employee = employees?.[0];

  if (!employee) {
    return { success: false, error: 'No employee record found' };
  }

  const { data: insertedInvites, error: insertError } = await supabase
    .from('employee_invite')
    .insert({
      email,
      employee_id: employee.id,
      organisation_id: employee.organisation_id
    })
    .select('id')
    .limit(1);

  if (insertError || !insertedInvites || insertedInvites.length === 0) {
    return { success: false, error: insertError?.message || 'Insert failed' };
  }

  const inviteId = insertedInvites[0].id;
  const baseUrl = 'http://localhost:3000';
  const inviteLink = `${baseUrl}/protected/accept?invite_id=${inviteId}`;

  try {
    await resend.emails.send({
      from: 'onboarding@resend.dev',
      to: email,
      subject: 'You are invited',
      html: `<p>You were invited to join our app. Click <a href="${inviteLink}">here</a> to accept the invitation.</p>`
    });

    return { success: true };
  } catch (e: any) {
    return { success: false, error: e.message || 'Email failed' };
  }
}
