import { create } from '@web3-storage/w3up-client';

const spaceDID =
  (process.env
    .NEXT_PUBLIC_WEB3_STORAGE_SPACE_DID as `did:${string}:${string}`) || '';

export const setSpace = async () => {
  const client = await create();
  console.log('client', client);

  const space = await client.setCurrentSpace(spaceDID);
  console.log('space', space);
  return space;
};
