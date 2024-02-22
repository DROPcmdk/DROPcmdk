import * as Client from '@web3-storage/w3up-client';

const spaceDID = process.env
  .NEXT_PUBLIC_WEB3_STORAGE_SPACE_DID as `did:key:${string}`;

export async function POST(request: Request): Promise<Response> {
  const client = await Client.create();
  const account = await client.login('mike@modadao.io');
  // const space = await client.createSpace('drop-protocol');
  // await account.provision(space.did());

  const formData = await request.formData();
  const file = formData.get('file') as Blob;

  const CID = await client.uploadFile(file);

  console.log(CID);

  return new Response(JSON.stringify({ CID }), { status: 200 });
}
