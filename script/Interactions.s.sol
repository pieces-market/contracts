// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

import {Script, console} from "forge-std/Script.sol";
import {Auctioner} from "../src/Auctioner.sol";
import {Governor} from "../src/Governor.sol";

contract Create is Script {
    function run(address auctioner) external {
        uint deployerKey = vm.envUint("ADMIN_KEY");

        vm.startBroadcast(deployerKey);
        Auctioner(auctioner).create(
            "Asset",
            "AST",
            "https:",
            2,
            100,
            10,
            block.timestamp + 1 days,
            block.timestamp + 7 days,
            0xcE2AC9c129C533f5129f8e1603188d315b42378E,
            500,
            5000
        );
        vm.stopBroadcast();
    }
}
