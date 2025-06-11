import { createClient } from "@/lib/supabase/client";
import { useEffect, useState } from "react";

type Invite = {
  id: string;
  email: string;
};

export function usePendingInvites() {
  const [invites, setInvites] = useState<Invite[]>([]);
  const [copiedIndex, setCopiedIndex] = useState<number | null>(null);
  const supabase = createClient();

  useEffect(() => {
    const fetchInvites = async () => {
      const {
        data: { user },
      } = await supabase.auth.getUser();
      if (!user) return;

      const { data: employees } = await supabase
        .from("employee")
        .select("id")
        .eq("user_id", user.id)
        .limit(1);

      const employee = employees?.[0];
      if (!employee) return;

      const { data, error } = await supabase
        .from("employee_invite")
        .select("id, email")
        .eq("accepted", false)
        .eq("employee_id", employee.id);

      if (!error && data) {
        setInvites(data);
      }
    };

    fetchInvites();
  }, [supabase]);

  const handleCopy = (inviteId: string, index: number) => {
    const url = `${window.location.origin}/protected/accept?invite_id=${inviteId}`;
    navigator.clipboard.writeText(url);
    setCopiedIndex(index);
    setTimeout(() => setCopiedIndex(null), 1500);
  };

  return { invites, copiedIndex, handleCopy };
}
