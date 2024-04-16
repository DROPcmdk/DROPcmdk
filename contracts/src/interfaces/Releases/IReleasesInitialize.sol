// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {IRegistry} from "../Registry/IRegistry.sol";
import {ISplitsFactory} from "../ISplitsFactory.sol";

interface IReleasesInitialize {
    /**
     * @notice Initializes the contract
     * @param admin The address that will be given the role of default admin. See {AccessControl}
     * @param name_ The name of the Releases contract
     * @param symbol_ The symbol of the Releases contract
     */
    function initialize(address admin, string memory name_, string memory symbol_) external;
}
