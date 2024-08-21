// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

import {Script, console} from "forge-std/Script.sol";
import {Auctioner} from "../src/Auctioner.sol";
import {Governor} from "../src/Governor.sol";

contract DeployPiecesMarket is Script {
    address private foundation = 0x7eAFE197018d6dfFeF84442Ef113A22A4a191CCD;

    function run() public {
        uint deployerKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerKey);
        Governor governor = new Governor();
        console.log("Governor Deployed:", address(governor));
        console.log("Owner: ", governor.owner());

        Auctioner auctioner = new Auctioner(foundation, address(governor));
        console.log("Auctioner Deployed:", address(auctioner));
        console.log("Owner: ", auctioner.owner());

        governor.transferOwnership(address(auctioner));
        console.log("Governor New Owner:", address(auctioner));
        vm.stopBroadcast();
    }
}
