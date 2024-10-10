// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

import {Script, console} from "forge-std/Script.sol";
import {AuctionerDev} from "../src/helpers/AuctionerDev.sol";
import {Governor} from "../src/Governor.sol";

contract MakeContractsAlive is Script {
    /// @dev EXCLUDE FROM COVERAGE
    function test() public {}

    AuctionerDev auctioner = AuctionerDev(0x7C6130CddFf24A8246240C8c453D036B30cA3584);
    Governor governor = Governor(0x61824F20307Fbe0B8205bD7bE79A4278D2cd1CfD);

    address private ADMIN = vm.addr(vm.envUint("ADMIN_KEY"));
    address private BROKER = vm.addr(vm.envUint("BROKER_KEY"));
    address private FOUNDATION = vm.addr(vm.envUint("FOUNDATION_KEY"));

    address private USER1 = vm.addr(vm.envUint("USER1_KEY"));
    address private USER2 = vm.addr(vm.envUint("USER2_KEY"));
    address private USER3 = vm.addr(vm.envUint("USER3_KEY"));
    address private USER4 = vm.addr(vm.envUint("USER4_KEY"));
    address private USER5 = vm.addr(vm.envUint("USER5_KEY"));

    function run() external {
        uint256 adminKey = vm.envUint("ADMIN_KEY");

        uint256 foundationKey = vm.envUint("FOUNDATION_KEY");

        uint256 user1Key = vm.envUint("USER1_KEY");
        uint256 user2Key = vm.envUint("USER2_KEY");
        uint256 user3Key = vm.envUint("USER3_KEY");
        uint256 user4Key = vm.envUint("USER4_KEY");
        uint256 user5Key = vm.envUint("USER5_KEY");

        /// @dev SCHEDULED AUCTION (id: 0)
        vm.startBroadcast(adminKey);
        auctioner.create("Asset", "AST", "https:", 0.01 ether, 100, 10, block.timestamp + 3 days, block.timestamp + 10 days, BROKER);
        vm.stopBroadcast();

        /// @dev OPENED AUCTION (id: 1)
        vm.startBroadcast(adminKey);
        auctioner.create("Asset", "AST", "https:", 0.01 ether, 100, 10, block.timestamp, block.timestamp + 7 days, BROKER);
        vm.stopBroadcast();

        /// @dev OPENED AUCTION WITH BUYERS (id: 2)
        vm.startBroadcast(adminKey);
        auctioner.create("Asset", "AST", "https:", 0.01 ether, 100, 10, block.timestamp, block.timestamp + 70 days, BROKER);
        vm.stopBroadcast();

        vm.startBroadcast(user1Key);
        auctioner.buy{value: 0.04 ether}(2, 4);
        vm.stopBroadcast();

        vm.startBroadcast(user2Key);
        auctioner.buy{value: 0.01 ether}(2, 1);
        vm.stopBroadcast();

        vm.startBroadcast(user3Key);
        auctioner.buy{value: 0.1 ether}(2, 10);
        vm.stopBroadcast();

        /// @dev FAILED AUCTION WITH REFUNDS (id: 3)
        vm.startBroadcast(adminKey);
        auctioner.create("Asset", "AST", "https:", 0.01 ether, 100, 10, block.timestamp, block.timestamp + 7 days, BROKER);
        vm.stopBroadcast();

        vm.startBroadcast(user1Key);
        auctioner.buy{value: 0.04 ether}(3, 4);
        vm.stopBroadcast();

        vm.startBroadcast(user2Key);
        auctioner.buy{value: 0.01 ether}(3, 1);
        vm.stopBroadcast();

        vm.startBroadcast(user3Key);
        auctioner.buy{value: 0.1 ether}(3, 10);
        vm.stopBroadcast();

        // Auction Failed
        vm.startBroadcast(adminKey);
        auctioner.stateHack(3, 4);

        // Refunds
        vm.startBroadcast(user2Key);
        auctioner.refund(3);
        vm.stopBroadcast();

        vm.startBroadcast(user3Key);
        auctioner.refund(3);
        vm.stopBroadcast();

        /// @dev CLOSED AUCTION (id: 4)
        vm.startBroadcast(adminKey);
        auctioner.create("Asset", "AST", "https:", 0.01 ether, 30, 10, block.timestamp, block.timestamp + 7 days, BROKER);
        vm.stopBroadcast();

        vm.startBroadcast(user1Key);
        auctioner.buy{value: 0.1 ether}(4, 10);
        vm.stopBroadcast();

        vm.startBroadcast(user3Key);
        auctioner.buy{value: 0.1 ether}(4, 10);
        vm.stopBroadcast();

        vm.startBroadcast(user4Key);
        auctioner.buy{value: 0.04 ether}(4, 4);
        vm.stopBroadcast();

        vm.startBroadcast(user5Key);
        auctioner.buy{value: 0.06 ether}(4, 6);
        vm.stopBroadcast();
    }
}
