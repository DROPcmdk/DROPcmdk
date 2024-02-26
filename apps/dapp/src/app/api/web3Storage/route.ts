import { create } from '@web3-storage/w3up-client';
// const spaceDID = process.env
//   .NEXT_PUBLIC_WEB3_STORAGE_SPACE_DID as `did:key:${string}`;

export async function POST(request: Request): Promise<Response> {
  try {
    console.log('creating client');
    const client = await create();
    const space = await client.createSpace('my-awesome-space');
    console.log('DID', space.did());
    console.log('logging in');
    await client.login('nic@modadao.io');
    // console.log('setting space');
    // await client.setCurrentSpace(
    //   'did:key:z6Mktdqp71MacqtubCvR1YcrGVSwcXgtac1K7dbQXd7yVgEJ',
    // );

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
