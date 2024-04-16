

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

### Membership //TODO

Membership is a way to control who has access to your Registry. The default implementation defines any address as a "member", which means anyone can register tracks in the Catalog. You can extend this logic to define your own rules such as NFT-gates, minimal ERC-20 balance amounts, or a generic whitelist. See Membership.sol in `./contracts/src/Membership.sol`

1. Deploy contract `pnpm 1_deploy_Membership --chain mumbai`


### Registry

#### Technical Overview

The Registry is an upgradeable contract and the only one in the protocol. It follows an Upgradeable Beacon pattern in which a Beacon contract containing the the implementation address is deployed and controlled by an Authorized account. Any proxy that is deployed will refer to this Beacon contract for the implementation address.

The Registry uses a Namespaced Storage Layout defined in [ERC-7201](https://eips.ethereum.org/EIPS/eip-7201)

The [Foundry Upgrades](https://docs.openzeppelin.com/upgrades-plugins/1.x/api-foundry-upgrades) library is used for ease of upgradeable contract deployment and customizable upgrade safety validations.






## Automatic track verification

All registered tracks have a status that is used to represent their authenticity. Upon registration a track is given a status of PENDING, this status can be updated to VALIDATED or INVALIDATED by a privileged account. A track cannot be used to create a release without a status of VALIDATED. This step can by bypassed by a catalog owner granting the registering account with the AUTO_VERIFIED_ROLE. We have added a script that allows the catalog owner to do this from the command line. To grant the AUTO_VERIFIED_ROLE to one or more addresses you can run this command from the root: 

`pnpm add_verified_roles <address1> <address2> ....`

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
