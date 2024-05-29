

## Getting Started

1. Install dependencies
```bash
pnpm i
```

2. Set up environment variables
```bash
cp ./contracts/.env-local ./contracts/.env
# Add your values to ./contracts/.env
```

## Generate Smart Contract Documentation

1. `pnpm c:docs`
2. Visit [localhost:8080](localhost:8080)

## Contracts

### Membership 

Membership is a way to control who has access to the Registry. 

### Registry

#### General Overview

The Registry allows onchain registration, verification and permissioning for Artists, their tracks and any releases that use those tracks.

**Artist**

- An artist is registered using the IPFS hash that points to their metadata.
- When first registered an Artist has a status of Pending and must be verified before being able to have tracks registered to them.
- Each registered artist is assigned a unique ID in the form `Artist-DROP-<chain id>-<artist count>`
- At registration a list of controller accounts are assigned to the artist. These accounts can perform actions such as updating the Artist metadata, Registering a track to the artist and adding or removing other controllers accounts.

**Track**

- An track is registered to an Artist using the IPFS hash that points to their metadata.
- When first registered a Track has a status of Pending and must be verified before being able to be added to a release.
- A track can only be registered to a verified artist.
- A user can register a track to an artist only if they are listed as a controller for that artist.
- Each registered track is assigned a unique ID in the form `TRACK-DROP-<chain id>-<artist count>`
- At registration a list of controller accounts or are assigned to the track. These accounts can perform actions such as updating the Track metadata, updating the Track beneficiary, adding or removing other controllers and minting releases containing the track.

**Release**

- A Release is registered using the IPFS hash that points to their metadata.
- At registration a list of controller accounts are assigned to the Release. These accounts can perform actions such as updating the Release metadata, adding or removing other controllers and registering Release tokens to the Release.
- In order for tracks to be included in a Release they must be registered and verified.
- Each registered track is assigned a unique ID in the form `RELEASE-DROP-<chain id>-<artist count>`
- In order for any Release tokens to be registered to the Release, all tracks on the release must have been granted access from a track controller

**Release Token**

- A Release token can be any token that has a Token Id and Metadata, it is up to a Release controller to verify that a token is legitimate and add it to a Release. 
- A Release token can be on any EVM chain
- A Release token is registered to a release using it's Contract address, Chain Id and Token Id 


#### Technical Overview

The Registry is an upgradeable contract and the only one in the protocol. It follows an Upgradeable Beacon pattern in which a Beacon contract containing the the implementation address is deployed and controlled by an Authorized account. Any proxy that is deployed will refer to this Beacon contract for the implementation address.

The Registry uses a Namespaced Storage Layout defined in [ERC-7201](https://eips.ethereum.org/EIPS/eip-7201)

The [Foundry Upgrades](https://docs.openzeppelin.com/upgrades-plugins/1.x/api-foundry-upgrades) library is used for ease of upgradeable contract deployment and customizable upgrade safety validations.



## Generate Smart Contract Documentation

### Deploy ReleasesFactory
`pnpm _deploy_ReleasesFactory --chain mumbai --sender <ADDRESS>`

### Deploy OpenReleasesFactory
`pnpm _deploy_OpenReleasesFactory --chain mumbai --sender <ADDRESS>`

## Smart Contract Testing

Navigate to the contracts directory and run

```bash
pnpm test
```

To generate a coverage report run

```bash
pnpm coverage
```

## License

`drop-protocol` is [Apache licensed](LICENSE).

## Contributing

Contributions are welcome and appreciated! Check out the
[contributing guide](CONTRIBUTING.md) before you dive in.

## Code of Conduct

Everyone interacting in this repo is expected to follow the
[code of conduct](CODE_OF_CONDUCT.md).
