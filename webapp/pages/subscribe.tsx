import SubscribeButton from '../components/SubscribeButton';

const pricing = [
  { name: 'Basic', priceId: 'price_1Basic', description: 'Starter plan', amount: '$9/mo' },
  { name: 'Pro', priceId: 'price_1Pro', description: 'Growth plan', amount: '$29/mo' },
  { name: 'Enterprise', priceId: 'price_1Ent', description: 'Scale plan', amount: '$99/mo' },
];

export default function SubscribePage() {
  return (
    <div className="max-w-4xl mx-auto p-8">
      <h1 className="text-3xl font-bold mb-6">Choose a plan</h1>
      <div className="grid md:grid-cols-3 gap-8">
        {pricing.map((p) => (
          <div key={p.name} className="p-6 border rounded shadow">
            <h2 className="text-xl font-semibold mb-2">{p.name}</h2>
            <p className="mb-2 text-gray-600">{p.description}</p>
            <p className="text-2xl font-bold mb-4">{p.amount}</p>
            <SubscribeButton priceId={p.priceId} />
          </div>
        ))}
      </div>
    </div>
  );
}
