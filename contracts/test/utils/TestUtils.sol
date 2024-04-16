// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Test, console2} from "forge-std/Test.sol";
import {Wallets} from "./Wallets.sol";

contract TestUtils is Test {
    Wallets internal _w = new Wallets();
    address payable internal _treasury = payable(address(0x123));
}
