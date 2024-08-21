// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

import {Script, console} from "forge-std/Script.sol";
import {Auctioner} from "../src/Auctioner.sol";
import {Governor} from "../src/Governor.sol";

contract MakeContractsAlive is Script {
    Auctioner auctioner = Auctioner(0x530Ec5617Db81acA931CE9B57a9CF2549f903Ef2);
    Governor governor = Governor(0xb30Dfc59152b458036317d3c9848C4Ed21C39003);

    address private BROKER = 0xcE2AC9c129C533f5129f8e1603188d315b42378E;
    address private FOUNDATION = 0x7eAFE197018d6dfFeF84442Ef113A22A4a191CCD;

    address private USER1 = 0x4508eb621165E5ca94598701BA367010c7694C3b;
    address private USER2 = 0x855d4215f43D9CA04be168f726059AeAaBb1080C;
    address private USER3 = 0x207c29F426F9AeB83446D6a2FD522F8138dD92af;
    address private USER4 = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
    address private USER5 = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;

    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerKey);
        /// @dev This will have index '2'
        auctioner.create("Asset", "AST", "https:", 2 ether, 100, 10, block.timestamp, block.timestamp + 7 days, BROKER);
        vm.stopBroadcast();
    }
}
