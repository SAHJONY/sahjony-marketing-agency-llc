import Link from "next/link";

export default function Home() {
  return (
    <main className="flex min-h-screen flex-col items-center justify-center p-8">
      <h1 className="text-4xl font-bold mb-4">FrontDesk Agents Platform</h1>
      <p className="mb-6 text-lg">Your unified CRM – email, tasks, calendar & analytics.</p>
      <nav className="flex flex-col gap-3">
        <Link href="/admin" className="text-blue-600 hover:underline">Admin Dashboard</Link>
        <Link href="/dashboard" className="text-blue-600 hover:underline">Founder Dashboard</Link>
        <Link href="/ai" className="text-blue-600 hover:underline">AI Playground</Link>
        <Link href="/subscribe" className="text-blue-600 hover:underline">Subscribe</Link>
      </nav>
    </main>
  );
}
