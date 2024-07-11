// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

import {Script, console} from "forge-std/Script.sol";
import {Auctioner} from "../src/Auctioner.sol";

contract DeployAuctioner is Script {
    function run() public {
        uint deployerKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerKey);
        Auctioner auctioner = new Auctioner();
        console.log("Deployed Auctioner:", address(auctioner));
        console.log("Owner: ", auctioner.owner());
        vm.stopBroadcast();
    }
}
