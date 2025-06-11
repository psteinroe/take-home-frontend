"use client";

import { sendInvite } from "@/actions/sendInvite";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { useState } from "react";

export default function InvitePage() {
  const [email, setEmail] = useState("");
  const [status, setStatus] = useState<
    "idle" | "loading" | "success" | "error"
  >("idle");

  const handleInvite = async () => {
    setStatus("loading");
    const result = await sendInvite(email);

    if (result.error) {
      console.error("Insert error:", result.error);
      setStatus("error");
      return;
    }

    setStatus("success");
  };

  return (
    <div className="max-w-md mx-auto mt-10">
      <h1 className="text-xl font-bold mb-4">Invite a new employee</h1>
      <Input
        type="email"
        placeholder="Email"
        value={email}
        onChange={(e) => setEmail(e.target.value)}
        className="border rounded px-3 py-2 w-full mb-2"
      />
      <Button onClick={handleInvite} disabled={status === "loading"}>
        {status === "loading" ? "Inviting..." : "Invite"}
      </Button>

      {status === "success" && (
        <p className="text-green-600 mt-2">Invitation Sent!</p>
      )}
      {status === "error" && (
        <p className="text-red-600 mt-2">Error sending invitation.</p>
      )}
    </div>
  );
}
