import { acceptInvite } from "@/actions/acceptInvite";

export default async function AcceptInvitePage({
  searchParams,
}: {
  searchParams: { invite_id?: string };
}) {
  try {
    await acceptInvite(searchParams.invite_id ?? null);
    return null;
  } catch (e: any) {
    return (
      <div className="max-w-md mx-auto mt-10 text-center">
        <p className="text-red-600">
          Error: {e?.message || "Unexpected error"}
        </p>
      </div>
    );
  }
}
