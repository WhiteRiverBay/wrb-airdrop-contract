// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";

contract BatchAirdropScript is Script {
    function setUp() public {}

    function run() public {
        vm.broadcast();
    }
}