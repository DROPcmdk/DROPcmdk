// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {IReleasesFactory} from "./interfaces/Releases/IReleasesFactory.sol";
import {IReleasesInitialize} from "./interfaces/Releases/IReleasesInitialize.sol";
import {IRegistry} from "./interfaces/Registry/IRegistry.sol";
import {ISplitsFactory} from "./interfaces/ISplitsFactory.sol";

/**
 * @notice ReleasesFactory creates Trustless Release contracts and registers them with a Catalog.
 */
contract ReleasesFactory is IReleasesFactory {
    address public releasesMaster;

    /**
     * @notice Constructor
     * @param releasesMaster_ The address of the Releases implementation contract
     */
    constructor(address releasesMaster_) {
        releasesMaster = releasesMaster_;
    }

    /// @inheritdoc IReleasesFactory
    function create(string calldata name, string calldata symbol) external returns (address) {
        address releasesClone = Clones.clone(releasesMaster);

        IReleasesInitialize(releasesClone).initialize(msg.sender, name, symbol);

        emit ReleasesCreated(msg.sender, releasesClone, name, symbol);

        return releasesClone;
    }
}
