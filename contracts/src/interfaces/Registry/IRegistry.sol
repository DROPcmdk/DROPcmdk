// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {IArtistRegistration} from "./IArtistRegistration.sol";
import {ITrackRegistration} from "./ITrackRegistration.sol";
import {IReleaseRegistration} from "../Registry/IReleaseRegistration.sol";
import {IRegistryInitialize} from "./IRegistryInitialize.sol";

/// @notice A contract deployed by an organization where artists and labels can register music.
interface IRegistry is
    IArtistRegistration,
    ITrackRegistration,
    IReleaseRegistration,
    IRegistryInitialize
{}
