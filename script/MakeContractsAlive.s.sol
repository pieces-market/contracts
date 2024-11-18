// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

import {Script, console} from "forge-std/Script.sol";
import {AuctionerDev} from "../src/helpers/AuctionerDev.sol";
import {GovernorDev} from "../src/helpers/GovernorDev.sol";

import {IAuctioner} from "../src/interfaces/IAuctioner.sol";
import {IGovernor} from "../src/interfaces/IGovernor.sol";

/// @dev We need to update timestamp before each 'CastVote()' and 'exec()' sending our own 'write tx' to blockchain,
/// so make sure timestamp will get updated independently of other users and transactions

contract Phase1 is Script {
    /// @dev EXCLUDE FROM COVERAGE
    function test() public {}

    // Local Auctioner: 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
    // Local Governor: 0x5FbDB2315678afecb367f032d93F642f64180aa3
    AuctionerDev auctioner = AuctionerDev(0x1B255D9B7A8aAF5541D99626460c62703700d50F);
    GovernorDev governor = GovernorDev(0x8dBa2aCcdC79A03AbaA8C876bc3CCAbB1Bf9E789);

    uint256 adminKey = vm.envUint("ADMIN_KEY");
    address BROKER = vm.addr(vm.envUint("BROKER_KEY"));
    uint256 foundationKey = vm.envUint("FOUNDATION_KEY");

    uint256 user1Key = vm.envUint("USER1_KEY");
    uint256 user2Key = vm.envUint("USER2_KEY");
    uint256 user3Key = vm.envUint("USER3_KEY");
    uint256 user4Key = vm.envUint("USER4_KEY");
    uint256 user5Key = vm.envUint("USER5_KEY");

    function run() external {
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

        // Halts execution for 2 seconds
        vm.sleep(2000);

        // Auction Failed
        vm.startBroadcast(adminKey);
        auctioner.stateHack(3, 4);
        vm.stopBroadcast();
    }
}

contract Phase2 is Script {
    /// @dev EXCLUDE FROM COVERAGE
    function test() public {}

    AuctionerDev auctioner = AuctionerDev(0x1B255D9B7A8aAF5541D99626460c62703700d50F);
    GovernorDev governor = GovernorDev(0x8dBa2aCcdC79A03AbaA8C876bc3CCAbB1Bf9E789);

    uint256 adminKey = vm.envUint("ADMIN_KEY");
    address BROKER = vm.addr(vm.envUint("BROKER_KEY"));
    uint256 foundationKey = vm.envUint("FOUNDATION_KEY");

    uint256 user1Key = vm.envUint("USER1_KEY");
    uint256 user2Key = vm.envUint("USER2_KEY");
    uint256 user3Key = vm.envUint("USER3_KEY");
    uint256 user4Key = vm.envUint("USER4_KEY");
    uint256 user5Key = vm.envUint("USER5_KEY");

    function run() external {
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
        auctioner.eventHack(10);
        vm.stopBroadcast();
    }
}

contract Phase3 is Script {
    /// @dev EXCLUDE FROM COVERAGE
    function test() public {}

    AuctionerDev auctioner = AuctionerDev(0x1B255D9B7A8aAF5541D99626460c62703700d50F);
    GovernorDev governor = GovernorDev(0x8dBa2aCcdC79A03AbaA8C876bc3CCAbB1Bf9E789);

    uint256 adminKey = vm.envUint("ADMIN_KEY");
    address BROKER = vm.addr(vm.envUint("BROKER_KEY"));
    uint256 foundationKey = vm.envUint("FOUNDATION_KEY");

    uint256 user1Key = vm.envUint("USER1_KEY");
    uint256 user2Key = vm.envUint("USER2_KEY");
    uint256 user3Key = vm.envUint("USER3_KEY");
    uint256 user4Key = vm.envUint("USER4_KEY");
    uint256 user5Key = vm.envUint("USER5_KEY");

    function run() external {
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
        auctioner.eventHack(10);
        vm.stopBroadcast();
    }
}

contract Phase4 is Script {
    /// @dev EXCLUDE FROM COVERAGE
    function test() public {}

    AuctionerDev auctioner = AuctionerDev(0x1B255D9B7A8aAF5541D99626460c62703700d50F);
    GovernorDev governor = GovernorDev(0x8dBa2aCcdC79A03AbaA8C876bc3CCAbB1Bf9E789);

    uint256 adminKey = vm.envUint("ADMIN_KEY");
    address BROKER = vm.addr(vm.envUint("BROKER_KEY"));
    uint256 foundationKey = vm.envUint("FOUNDATION_KEY");

    uint256 user1Key = vm.envUint("USER1_KEY");
    uint256 user2Key = vm.envUint("USER2_KEY");
    uint256 user3Key = vm.envUint("USER3_KEY");
    uint256 user4Key = vm.envUint("USER4_KEY");
    uint256 user5Key = vm.envUint("USER5_KEY");

    function run() external {
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
        auctioner.propose(6, "Documentation for asset to be provided until 12.06", IAuctioner.ProposalType.DESCRIPT);
        auctioner.eventHack(10);
        vm.stopBroadcast();
    }
}

contract Phase5 is Script {
    /// @dev EXCLUDE FROM COVERAGE
    function test() public {}

    AuctionerDev auctioner = AuctionerDev(0x1B255D9B7A8aAF5541D99626460c62703700d50F);
    GovernorDev governor = GovernorDev(0x8dBa2aCcdC79A03AbaA8C876bc3CCAbB1Bf9E789);

    uint256 adminKey = vm.envUint("ADMIN_KEY");
    address BROKER = vm.addr(vm.envUint("BROKER_KEY"));
    uint256 foundationKey = vm.envUint("FOUNDATION_KEY");

    uint256 user1Key = vm.envUint("USER1_KEY");
    uint256 user2Key = vm.envUint("USER2_KEY");
    uint256 user3Key = vm.envUint("USER3_KEY");
    uint256 user4Key = vm.envUint("USER4_KEY");
    uint256 user5Key = vm.envUint("USER5_KEY");

    function run() external {
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
        auctioner.eventHack(10);
        vm.stopBroadcast();
    }
}

contract Phase6 is Script {
    /// @dev EXCLUDE FROM COVERAGE
    function test() public {}

    AuctionerDev auctioner = AuctionerDev(0x1B255D9B7A8aAF5541D99626460c62703700d50F);
    GovernorDev governor = GovernorDev(0x8dBa2aCcdC79A03AbaA8C876bc3CCAbB1Bf9E789);

    uint256 adminKey = vm.envUint("ADMIN_KEY");
    address BROKER = vm.addr(vm.envUint("BROKER_KEY"));
    uint256 foundationKey = vm.envUint("FOUNDATION_KEY");

    uint256 user1Key = vm.envUint("USER1_KEY");
    uint256 user2Key = vm.envUint("USER2_KEY");
    uint256 user3Key = vm.envUint("USER3_KEY");
    uint256 user4Key = vm.envUint("USER4_KEY");
    uint256 user5Key = vm.envUint("USER5_KEY");

    function run() external {
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
        auctioner.eventHack(10);
        vm.stopBroadcast();
    }
}

contract Phase7 is Script {
    /// @dev EXCLUDE FROM COVERAGE
    function test() public {}

    AuctionerDev auctioner = AuctionerDev(0x1B255D9B7A8aAF5541D99626460c62703700d50F);
    GovernorDev governor = GovernorDev(0x8dBa2aCcdC79A03AbaA8C876bc3CCAbB1Bf9E789);

    uint256 adminKey = vm.envUint("ADMIN_KEY");
    address BROKER = vm.addr(vm.envUint("BROKER_KEY"));
    uint256 foundationKey = vm.envUint("FOUNDATION_KEY");

    uint256 user1Key = vm.envUint("USER1_KEY");
    uint256 user2Key = vm.envUint("USER2_KEY");
    uint256 user3Key = vm.envUint("USER3_KEY");
    uint256 user4Key = vm.envUint("USER4_KEY");
    uint256 user5Key = vm.envUint("USER5_KEY");

    function run() external {
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
        auctioner.eventHack(10);
        vm.stopBroadcast();
    }
}

contract Phase8 is Script {
    /// @dev EXCLUDE FROM COVERAGE
    function test() public {}

    AuctionerDev auctioner = AuctionerDev(0x1B255D9B7A8aAF5541D99626460c62703700d50F);
    GovernorDev governor = GovernorDev(0x8dBa2aCcdC79A03AbaA8C876bc3CCAbB1Bf9E789);

    uint256 adminKey = vm.envUint("ADMIN_KEY");
    address BROKER = vm.addr(vm.envUint("BROKER_KEY"));
    uint256 foundationKey = vm.envUint("FOUNDATION_KEY");

    uint256 user1Key = vm.envUint("USER1_KEY");
    uint256 user2Key = vm.envUint("USER2_KEY");
    uint256 user3Key = vm.envUint("USER3_KEY");
    uint256 user4Key = vm.envUint("USER4_KEY");
    uint256 user5Key = vm.envUint("USER5_KEY");

    function run() external {
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
    }
}

contract Phase9 is Script {
    /// @dev EXCLUDE FROM COVERAGE
    function test() public {}

    AuctionerDev auctioner = AuctionerDev(0x1B255D9B7A8aAF5541D99626460c62703700d50F);
    GovernorDev governor = GovernorDev(0x8dBa2aCcdC79A03AbaA8C876bc3CCAbB1Bf9E789);

    uint256 adminKey = vm.envUint("ADMIN_KEY");
    address BROKER = vm.addr(vm.envUint("BROKER_KEY"));
    uint256 foundationKey = vm.envUint("FOUNDATION_KEY");

    uint256 user1Key = vm.envUint("USER1_KEY");
    uint256 user2Key = vm.envUint("USER2_KEY");
    uint256 user3Key = vm.envUint("USER3_KEY");
    uint256 user4Key = vm.envUint("USER4_KEY");
    uint256 user5Key = vm.envUint("USER5_KEY");

    function run() external {
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
