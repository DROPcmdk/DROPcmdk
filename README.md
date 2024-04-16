

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

### Membership 

Membership is a way to control who has access to your Registry. See Membership.sol in `./contracts/src/Membership.sol`

#### Deployment

`pnpm 1_deploy_Membership --chain mumbai`


### Registry

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
