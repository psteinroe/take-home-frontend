"use client";

import { usePendingInvites } from "@/hooks/usePendingInvites";

export default function PendingInvitesPage() {
  const { invites, copiedIndex, handleCopy } = usePendingInvites();

  return (
    <div className="max-w-md mx-auto mt-10">
      <h1 className="text-xl font-bold mb-4">Pending Invitations</h1>
      {invites.length === 0 ? (
        <p>No pending invitations.</p>
      ) : (
        <ul className="space-y-4">
          {invites.map((invite, index) => (
            <li
              key={invite.id}
              className="flex justify-between items-center border rounded px-3 py-2"
            >
              <span>{invite.email}</span>
              <button
                onClick={() => handleCopy(invite.id, index)}
                className="bg-gray-200 px-2 py-1 rounded"
              >
                {copiedIndex === index ? "Copied!" : "Copy link"}
              </button>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
