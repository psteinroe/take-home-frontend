import { createClient } from "@/lib/supabase/server";
import { redirect } from "next/navigation";

export async function acceptInvite(inviteId: string | null) {
  const supabase = await createClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    redirect(`/auth/login?forward_to=/protected/accept?invite_id=${inviteId}`);
  }

  if (!inviteId) throw new Error("Missing invite_id");

  const { data: invite, error: inviteError } = await supabase
    .from("employee_invite")
    .select("email")
    .eq("id", inviteId)
    .single();

  if (inviteError || !invite?.email) throw new Error("Invalid invitation");

  if (invite.email !== user.email) {
    throw new Error("This invitation was not sent to your email address");
  }

  const { data: employee, error: employeeError } = await supabase
    .from("employee")
    .select("id")
    .eq("email", user.email)
    .single();

  if (employeeError || !employee?.id)
    throw new Error("No employee found with that email");

  const { error: acceptError } = await supabase.rpc("accept_employee_invite", {
    employee_id: employee.id,
  });

  if (acceptError) throw new Error(acceptError.message);

  redirect("/protected/welcome");
}
