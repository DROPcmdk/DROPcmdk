// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

/**
 * @notice IReleasesFactory defines an interface for a factory contract that deploys trustless Releases contracts.
 */
interface IReleasesFactory {
    /**
     * @notice Emitted when a new releases contract is created
     */
    event ReleasesCreated(
        address indexed releasesOwner, address indexed releases, string name, string symbol
    );

    /**
     * @notice Creates a new releases contract
     * @param name The name of the releases contract
     * @param symbol The symbol of the releases contract
     */
    function create(string calldata name, string calldata symbol) external returns (address);
}
