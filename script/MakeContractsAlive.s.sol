// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

import {Script, console} from "forge-std/Script.sol";
import {AuctionerDev} from "../src/helpers/AuctionerDev.sol";
import {GovernorDev} from "../src/helpers/GovernorDev.sol";

import {IAuctioner} from "../src/interfaces/IAuctioner.sol";
import {IGovernor} from "../src/interfaces/IGovernor.sol";

contract MakeContractsAlive is Script {
    /// @dev EXCLUDE FROM COVERAGE
    function test() public {}

    AuctionerDev auctioner = AuctionerDev(0xb15Ca6B9438a0F425a5933B16B8f061dE5ed26a4);
    GovernorDev governor = GovernorDev(0x86115882c55b284476d98A97D8dA889a75C10569);

    address private BROKER = vm.addr(vm.envUint("BROKER_KEY"));

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
        auctioner.create("Asset", "AST", "https:", 0.01 ether, 100, 10, block.timestamp + 1 days, block.timestamp + 7 days, BROKER);
        auctioner.stateHack(1, 2);
        vm.stopBroadcast();

        /// @dev OPENED AUCTION WITH BUYERS (id: 2)
        vm.startBroadcast(adminKey);
        auctioner.create("Asset", "AST", "https:", 0.01 ether, 100, 10, block.timestamp + 1 days, block.timestamp + 70 days, BROKER);
        auctioner.stateHack(2, 2);
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
        auctioner.create("Asset", "AST", "https:", 0.01 ether, 100, 10, block.timestamp + 1 days, block.timestamp + 7 days, BROKER);
        auctioner.stateHack(3, 2);
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
        vm.stopBroadcast();

        // Refunds
        vm.startBroadcast(user2Key);
        auctioner.refund(3);
        vm.stopBroadcast();

        vm.startBroadcast(user3Key);
        auctioner.refund(3);
        vm.stopBroadcast();

        /// @dev CLOSED AUCTION (id: 4)
        vm.startBroadcast(adminKey);
        auctioner.create("Asset", "AST", "https:", 0.01 ether, 30, 10, block.timestamp + 1 days, block.timestamp + 7 days, BROKER);
        auctioner.stateHack(4, 2);
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

        /// @dev CLOSED AUCTION WITH ONGOING BUYOUT AND DESCRIPT (id: 5)
        vm.startBroadcast(adminKey);
        auctioner.create("Asset", "AST", "https:", 0.01 ether, 30, 10, block.timestamp + 1 days, block.timestamp + 7 days, BROKER);
        auctioner.stateHack(5, 2);
        vm.stopBroadcast();

        vm.startBroadcast(user1Key);
        auctioner.buy{value: 0.1 ether}(5, 10);
        vm.stopBroadcast();

        vm.startBroadcast(user3Key);
        auctioner.buy{value: 0.1 ether}(5, 10);
        vm.stopBroadcast();

        vm.startBroadcast(user4Key);
        auctioner.buy{value: 0.04 ether}(5, 4);
        vm.stopBroadcast();

        vm.startBroadcast(user5Key);
        auctioner.buy{value: 0.06 ether}(5, 6);
        vm.stopBroadcast();

        // Buyout (proposal id: 0)
        vm.startBroadcast(user2Key);
        auctioner.propose{value: 0.35 ether}(5, "buyout", IAuctioner.ProposalType.BUYOUT);
        vm.stopBroadcast();

        // Buyout Votes
        vm.startBroadcast(user1Key);
        governor.castVote(0, IGovernor.VoteType.FOR);
        vm.stopBroadcast();

        vm.startBroadcast(user4Key);
        governor.castVote(0, IGovernor.VoteType.AGAINST);
        vm.stopBroadcast();

        // Descript (proposal id: 1)
        vm.startBroadcast(foundationKey);
        auctioner.propose(5, "Documentation for asset to be provided until 12.12", IAuctioner.ProposalType.DESCRIPT);
        vm.stopBroadcast();

        // Descript Votes
        vm.startBroadcast(user1Key);
        governor.castVote(1, IGovernor.VoteType.FOR);
        vm.stopBroadcast();

        vm.startBroadcast(user4Key);
        governor.castVote(1, IGovernor.VoteType.AGAINST);
        vm.stopBroadcast();

        /// @dev FAILED BUYOUT WITH WITHDRAW AND FAILED DESCRIPT (id: 6)
        vm.startBroadcast(adminKey);
        auctioner.create("Asset", "AST", "https:", 0.01 ether, 30, 10, block.timestamp + 1 days, block.timestamp + 7 days, BROKER);
        auctioner.stateHack(6, 2);
        vm.stopBroadcast();

        vm.startBroadcast(user1Key);
        auctioner.buy{value: 0.1 ether}(6, 10);
        vm.stopBroadcast();

        vm.startBroadcast(user3Key);
        auctioner.buy{value: 0.1 ether}(6, 10);
        vm.stopBroadcast();

        vm.startBroadcast(user4Key);
        auctioner.buy{value: 0.04 ether}(6, 4);
        vm.stopBroadcast();

        vm.startBroadcast(user5Key);
        auctioner.buy{value: 0.06 ether}(6, 6);
        vm.stopBroadcast();

        // Buyout (proposal id: 2)
        vm.startBroadcast(user2Key);
        auctioner.propose{value: 0.34 ether}(6, "buyout", IAuctioner.ProposalType.BUYOUT);
        vm.stopBroadcast();

        // Descript (proposal id: 3)
        vm.startBroadcast(foundationKey);
        auctioner.propose(6, "Documentation for asset to be provided until 12.12", IAuctioner.ProposalType.DESCRIPT);
        vm.stopBroadcast();

        // Failing Buyout and Descript
        vm.startBroadcast(adminKey);
        governor.exec();
        vm.stopBroadcast();

        // Withdraw
        vm.startBroadcast(user2Key);
        auctioner.withdraw(6);
        vm.stopBroadcast();

        /// @dev AUCTION FINISHED BY BUYOUT WITH CLAIMS (id: 7)
        vm.startBroadcast(adminKey);
        auctioner.create("Asset", "AST", "https:", 0.01 ether, 30, 10, block.timestamp + 1 days, block.timestamp + 7 days, BROKER);
        auctioner.stateHack(7, 2);
        vm.stopBroadcast();

        vm.startBroadcast(user1Key);
        auctioner.buy{value: 0.1 ether}(7, 10);
        vm.stopBroadcast();

        vm.startBroadcast(user3Key);
        auctioner.buy{value: 0.1 ether}(7, 10);
        vm.stopBroadcast();

        vm.startBroadcast(user4Key);
        auctioner.buy{value: 0.04 ether}(7, 4);
        vm.stopBroadcast();

        vm.startBroadcast(user5Key);
        auctioner.buy{value: 0.06 ether}(7, 6);
        vm.stopBroadcast();

        // Buyout (proposal id: 4)
        vm.startBroadcast(user2Key);
        auctioner.propose{value: 0.35 ether}(7, "buyout", IAuctioner.ProposalType.BUYOUT);
        vm.stopBroadcast();

        // Buyout Votes
        vm.startBroadcast(user1Key);
        governor.castVote(4, IGovernor.VoteType.FOR);
        vm.stopBroadcast();

        vm.startBroadcast(user3Key);
        governor.castVote(4, IGovernor.VoteType.AGAINST);
        vm.stopBroadcast();

        vm.startBroadcast(user4Key);
        governor.castVote(4, IGovernor.VoteType.AGAINST);
        vm.stopBroadcast();

        vm.startBroadcast(user5Key);
        governor.castVote(4, IGovernor.VoteType.FOR);
        vm.stopBroadcast();

        // Descript (proposal id: 5)
        vm.startBroadcast(foundationKey);
        auctioner.propose(7, "Documentation for asset to be provided until 12.12", IAuctioner.ProposalType.DESCRIPT);
        vm.stopBroadcast();

        // Descript Votes
        vm.startBroadcast(user1Key);
        governor.castVote(5, IGovernor.VoteType.FOR);
        vm.stopBroadcast();

        vm.startBroadcast(user3Key);
        governor.castVote(5, IGovernor.VoteType.FOR);
        vm.stopBroadcast();

        vm.startBroadcast(user4Key);
        governor.castVote(5, IGovernor.VoteType.AGAINST);
        vm.stopBroadcast();

        vm.startBroadcast(user5Key);
        governor.castVote(5, IGovernor.VoteType.FOR);
        vm.stopBroadcast();

        // Processing Buyout and Descript
        vm.startBroadcast(adminKey);
        governor.exec();
        vm.stopBroadcast();

        // Claims
        vm.startBroadcast(user3Key);
        auctioner.claim(7);
        vm.stopBroadcast();

        vm.startBroadcast(user5Key);
        auctioner.claim(7);
        vm.stopBroadcast();

        /// @dev ARCHIVED AUCTION (id: 8)
        vm.startBroadcast(adminKey);
        auctioner.create("Asset", "AST", "https:", 0.01 ether, 30, 10, block.timestamp + 1 days, block.timestamp + 7 days, BROKER);
        auctioner.stateHack(8, 2);
        vm.stopBroadcast();

        vm.startBroadcast(user1Key);
        auctioner.buy{value: 0.1 ether}(8, 10);
        vm.stopBroadcast();

        vm.startBroadcast(user3Key);
        auctioner.buy{value: 0.1 ether}(8, 10);
        vm.stopBroadcast();

        vm.startBroadcast(user4Key);
        auctioner.buy{value: 0.04 ether}(8, 4);
        vm.stopBroadcast();

        vm.startBroadcast(user5Key);
        auctioner.buy{value: 0.06 ether}(8, 6);
        vm.stopBroadcast();

        // Buyout (proposal id: 6)
        vm.startBroadcast(user2Key);
        auctioner.propose{value: 0.33 ether}(8, "buyout", IAuctioner.ProposalType.BUYOUT);
        vm.stopBroadcast();

        // Buyout Votes
        vm.startBroadcast(user1Key);
        governor.castVote(6, IGovernor.VoteType.FOR);
        vm.stopBroadcast();

        vm.startBroadcast(user3Key);
        governor.castVote(6, IGovernor.VoteType.AGAINST);
        vm.stopBroadcast();

        vm.startBroadcast(user4Key);
        governor.castVote(6, IGovernor.VoteType.AGAINST);
        vm.stopBroadcast();

        vm.startBroadcast(user5Key);
        governor.castVote(6, IGovernor.VoteType.FOR);
        vm.stopBroadcast();

        vm.startBroadcast(adminKey);
        auctioner.stateHack(7, 3);
        vm.stopBroadcast();

        // Processing Buyout
        vm.startBroadcast(adminKey);
        governor.exec();
        vm.stopBroadcast();

        // Claims
        vm.startBroadcast(user1Key);
        auctioner.claim(8);
        vm.stopBroadcast();

        vm.startBroadcast(user3Key);
        auctioner.claim(8);
        vm.stopBroadcast();

        vm.startBroadcast(user4Key);
        auctioner.claim(8);
        vm.stopBroadcast();

        vm.startBroadcast(user5Key);
        auctioner.claim(8);
        vm.stopBroadcast();
    }
}
