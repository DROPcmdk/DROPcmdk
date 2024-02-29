import { create } from '@web3-storage/w3up-client';
const spaceDID = process.env
  .NEXT_PUBLIC_WEB3_STORAGE_SPACE_DID as `did:key:${string}`;

export async function POST(request: Request): Promise<Response> {
  try {
    const client = await create();
    await client.setCurrentSpace(spaceDID);

    const formData = await request.formData();
    const file = formData.get('file') as Blob;
    const CID = await client.uploadFile(file);
    console.log(CID);
  } catch (e) {
    console.log('\n\n\n\n\n\n web3 storage error', (e as any).message);
  }
  // await account.provision(spaceDID);

  // console.log(CID);

  return new Response(JSON.stringify({}), { status: 200 });
}
