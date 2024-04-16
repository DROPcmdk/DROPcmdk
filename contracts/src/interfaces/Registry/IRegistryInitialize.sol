// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {IMembership} from "../IMembership.sol";
import {IReleasesFactory} from "../Releases/IReleasesFactory.sol";
import {ISplitsFactory} from "../ISplitsFactory.sol";

interface IRegistryInitialize {
    /**
     * @notice Initializes the contract
     * @param owner The account that will gain ownership.
     * @param name The name of the Registry
     * @param membership A custom contract to gate user access.
     * @param splitsFactory The SplitsFactory contract
     */
    function initialize(
        address owner,
        string calldata name,
        IMembership membership,
        ISplitsFactory splitsFactory
    ) external;
}
