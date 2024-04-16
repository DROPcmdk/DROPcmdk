// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Registry} from "../../src/Registry.sol";

/// @custom:oz-upgrades-from Registry
contract RegistryV2Mock is Registry {
    /// State Variables

    /// @custom:storage-location erc7201:drop.storage.RegistryV2
    struct RegistryV2Storage {
        /// @dev additional variable to test upgradeability
        string _testingUpgradeVariable;
    }

    // Storage location

    // keccak256(abi.encode(uint256(keccak256("drop.storage.RegistryV2")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant RegistryV2StorageLocation =
        0xb8760629ab51d65b8fdd44998b12236c513908a4a393c4bcf5d9b3c642fa5700;

    function _getRegistryV2Storage() private pure returns (RegistryV2Storage storage $Version2) {
        assembly {
            $Version2.slot := RegistryV2StorageLocation
        }
    }

    /// External Functions

    /**
     * @dev For testing upgradeability
     */
    function setTestingUpgradeVariable(string calldata testingUpgradeVariable) external {
        RegistryV2Storage storage $Version2 = _getRegistryV2Storage();
        $Version2._testingUpgradeVariable = testingUpgradeVariable;
    }

    /**
     * @dev For testing upgradeability
     */
    function getTestingUpgradeVariable() external view returns (string memory) {
        RegistryV2Storage storage $Version2 = _getRegistryV2Storage();
        return $Version2._testingUpgradeVariable;
    }
}
