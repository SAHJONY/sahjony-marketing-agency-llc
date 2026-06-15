import Link from "next/link";

export default function AdminPage() {
  return (
    <main className="flex min-h-screen flex-col items-center justify-center p-8">
      <h1 className="text-3xl font-bold mb-4">Admin Dashboard</h1>
      <p className="mb-2">This is a placeholder admin page.</p>
      <Link href="/" className="text-blue-600 hover:underline">Back to Home</Link>
    </main>
  );
}
