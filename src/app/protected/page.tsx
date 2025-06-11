import { LogoutButton } from "@/components/logout-button";
import { createClient } from "@/lib/supabase/server";
import { redirect } from "next/navigation";

export default async function ProtectedPage() {
  const supabase = await createClient();
  const { data, error } = await supabase.auth.getClaims();

  if (error || !data) {
    redirect("/auth/login");
  }

  const email = data.claims.email;
  const employeeId = data.claims.app_metadata.employee_id || "No Employee";
  const organisationId =
    data.claims.app_metadata.organisation_id || "No Organisation";

  return (
    <div className="flex h-svh w-full items-center justify-center bg-gray-50 px-4">
      <div className="max-w-md w-full bg-white p-8 rounded-2xl shadow-md text-center space-y-6">
        <h1 className="text-2xl font-bold text-gray-800">Welcome</h1>
        <div className="text-gray-700 space-y-2">
          <p>
            <span className="font-medium">Email:</span> {email}
          </p>
          <p>
            <span className="font-medium">Employee ID:</span> {employeeId}
          </p>
          <p>
            <span className="font-medium">Organisation ID:</span>{" "}
            {organisationId}
          </p>
        </div>
        <LogoutButton />
      </div>
    </div>
  );
}
