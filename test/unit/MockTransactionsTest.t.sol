// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {AuctionerDev} from "../../src/helpers/AuctionerDev.sol";
import {GovernorDev} from "../../src/helpers/GovernorDev.sol";
import {DeployPiecesMarketDev} from "../../script/DeployPiecesMarketDev.s.sol";

import {IAuctioner} from "../../src/interfaces/IAuctioner.sol";
import {IGovernor} from "../../src/interfaces/IGovernor.sol";

contract MockTransactionsTest is Test {
    DeployPiecesMarketDev private piecesDeployer;
    AuctionerDev private auctioner;
    GovernorDev private governor;

    uint256 private constant STARTING_BALANCE = 100 ether;

    address private ADMIN = vm.addr(vm.envUint("ADMIN_KEY"));
    address private BROKER = vm.addr(vm.envUint("BROKER_KEY"));
    address private FOUNDATION = vm.addr(vm.envUint("FOUNDATION_KEY"));

    address private USER1 = vm.addr(vm.envUint("USER1_KEY"));
    address private USER2 = vm.addr(vm.envUint("USER2_KEY"));
    address private USER3 = vm.addr(vm.envUint("USER3_KEY"));
    address private USER4 = vm.addr(vm.envUint("USER4_KEY"));
    address private USER5 = vm.addr(vm.envUint("USER5_KEY"));

    function setUp() public {
        piecesDeployer = new DeployPiecesMarketDev();
        (auctioner, governor) = piecesDeployer.run();

        deal(ADMIN, STARTING_BALANCE);
        deal(FOUNDATION, STARTING_BALANCE);
        deal(BROKER, STARTING_BALANCE);

        deal(USER1, STARTING_BALANCE);
        deal(USER2, STARTING_BALANCE);
        deal(USER3, STARTING_BALANCE);
        deal(USER4, STARTING_BALANCE);
        deal(USER5, STARTING_BALANCE);
    }

    function testMockedTransactionsFlow() public {
        /// @dev SCHEDULED AUCTION (id: 0)
        vm.startPrank(ADMIN);
        auctioner.create("Asset", "AST", "https:", 0.01 ether, 100, 10, block.timestamp + 3 days, block.timestamp + 10 days, BROKER);
        vm.stopPrank();

        /// @dev OPENED AUCTION (id: 1)
        vm.startPrank(ADMIN);
        auctioner.create("Asset", "AST", "https:", 0.01 ether, 100, 10, block.timestamp, block.timestamp + 7 days, BROKER);
        vm.stopPrank();

        /// @dev OPENED AUCTION WITH BUYERS (id: 2)
        vm.startPrank(ADMIN);
        auctioner.create("Asset", "AST", "https:", 0.01 ether, 100, 10, block.timestamp, block.timestamp + 70 days, BROKER);
        vm.stopPrank();

        vm.startPrank(USER1);
        auctioner.buy{value: 0.04 ether}(2, 4);
        vm.stopPrank();

        vm.startPrank(USER2);
        auctioner.buy{value: 0.01 ether}(2, 1);
        vm.stopPrank();

        vm.startPrank(USER3);
        auctioner.buy{value: 0.1 ether}(2, 10);
        vm.stopPrank();

        /// @dev FAILED AUCTION WITH REFUNDS (id: 3)
        vm.startPrank(ADMIN);
        auctioner.create("Asset", "AST", "https:", 0.01 ether, 100, 10, block.timestamp, block.timestamp + 7 days, BROKER);
        vm.stopPrank();

        vm.startPrank(USER1);
        auctioner.buy{value: 0.04 ether}(3, 4);
        vm.stopPrank();

        vm.startPrank(USER2);
        auctioner.buy{value: 0.01 ether}(3, 1);
        vm.stopPrank();

        vm.startPrank(USER3);
        auctioner.buy{value: 0.1 ether}(3, 10);
        vm.stopPrank();

        // Auction Failed
        vm.startPrank(ADMIN);
        auctioner.stateHack(3, 4);

        // Refunds
        vm.startPrank(USER2);
        auctioner.refund(3);
        vm.stopPrank();

        vm.startPrank(USER3);
        auctioner.refund(3);
        vm.stopPrank();

        /// @dev CLOSED AUCTION (id: 4)
        vm.startPrank(ADMIN);
        auctioner.create("Asset", "AST", "https:", 0.01 ether, 30, 10, block.timestamp, block.timestamp + 7 days, BROKER);
        vm.stopPrank();

        vm.startPrank(USER1);
        auctioner.buy{value: 0.1 ether}(4, 10);
        vm.stopPrank();

        vm.startPrank(USER3);
        auctioner.buy{value: 0.1 ether}(4, 10);
        vm.stopPrank();

        vm.startPrank(USER4);
        auctioner.buy{value: 0.04 ether}(4, 4);
        vm.stopPrank();

        vm.startPrank(USER5);
        auctioner.buy{value: 0.06 ether}(4, 6);
        vm.stopPrank();

        /// @dev CLOSED AUCTION WITH ONGOING BUYOUT AND DESCRIPT (id: 5)
        vm.startPrank(ADMIN);
        auctioner.create("Asset", "AST", "https:", 0.01 ether, 30, 10, block.timestamp, block.timestamp + 7 days, BROKER);
        vm.stopPrank();

        vm.startPrank(USER1);
        auctioner.buy{value: 0.1 ether}(5, 10);
        vm.stopPrank();

        vm.startPrank(USER3);
        auctioner.buy{value: 0.1 ether}(5, 10);
        vm.stopPrank();

        vm.startPrank(USER4);
        auctioner.buy{value: 0.04 ether}(5, 4);
        vm.stopPrank();

        vm.startPrank(USER5);
        auctioner.buy{value: 0.06 ether}(5, 6);
        vm.stopPrank();

        // Buyout (proposal id: 0)
        vm.startPrank(USER2);
        auctioner.propose{value: 0.35 ether}(5, "buyout", IAuctioner.ProposalType.BUYOUT);
        vm.stopPrank();

        vm.warp(block.timestamp + 1);

        // Buyout Votes
        vm.startPrank(USER1);
        governor.castVote(0, IGovernor.VoteType.FOR);
        vm.stopPrank();

        vm.startPrank(USER4);
        governor.castVote(0, IGovernor.VoteType.AGAINST);
        vm.stopPrank();

        // Descript (proposal id: 1)
        vm.startPrank(FOUNDATION);
        auctioner.propose(5, "Documentation for asset to be provided until 12.12", IAuctioner.ProposalType.DESCRIPT);
        vm.stopPrank();

        vm.warp(block.timestamp + 1);

        // Descript Votes
        vm.startPrank(USER1);
        governor.castVote(1, IGovernor.VoteType.FOR);
        vm.stopPrank();

        vm.startPrank(USER4);
        governor.castVote(1, IGovernor.VoteType.AGAINST);
        vm.stopPrank();

        /// @dev FAILED BUYOUT WITH WITHDRAW AND FAILED DESCRIPT (id: 6)
        vm.startPrank(ADMIN);
        auctioner.create("Asset", "AST", "https:", 0.01 ether, 30, 10, block.timestamp, block.timestamp + 7 days, BROKER);
        vm.stopPrank();

        vm.startPrank(USER1);
        auctioner.buy{value: 0.1 ether}(6, 10);
        vm.stopPrank();

        vm.startPrank(USER3);
        auctioner.buy{value: 0.1 ether}(6, 10);
        vm.stopPrank();

        vm.startPrank(USER4);
        auctioner.buy{value: 0.04 ether}(6, 4);
        vm.stopPrank();

        vm.startPrank(USER5);
        auctioner.buy{value: 0.06 ether}(6, 6);
        vm.stopPrank();

        // Buyout (proposal id: 2)
        vm.startPrank(USER2);
        auctioner.propose{value: 0.34 ether}(6, "buyout", IAuctioner.ProposalType.BUYOUT);
        vm.stopPrank();

        // Descript (proposal id: 3)
        vm.startPrank(FOUNDATION);
        auctioner.propose(6, "Documentation for asset to be provided until 12.12", IAuctioner.ProposalType.DESCRIPT);
        vm.stopPrank();

        vm.warp(block.timestamp + 1);

        // Failing Buyout and Descript
        vm.startPrank(ADMIN);
        governor.exec();
        vm.stopPrank();

        // Withdraw
        vm.startPrank(USER2);
        auctioner.withdraw(6);
        vm.stopPrank();

        /// @dev AUCTION FINISHED BY BUYOUT WITH CLAIMS (id: 7)
        vm.startPrank(ADMIN);
        auctioner.create("Asset", "AST", "https:", 0.01 ether, 30, 10, block.timestamp, block.timestamp + 7 days, BROKER);
        vm.stopPrank();

        vm.startPrank(USER1);
        auctioner.buy{value: 0.1 ether}(7, 10);
        vm.stopPrank();

        vm.startPrank(USER3);
        auctioner.buy{value: 0.1 ether}(7, 10);
        vm.stopPrank();

        vm.startPrank(USER4);
        auctioner.buy{value: 0.04 ether}(7, 4);
        vm.stopPrank();

        vm.startPrank(USER5);
        auctioner.buy{value: 0.06 ether}(7, 6);
        vm.stopPrank();

        // Buyout (proposal id: 4)
        vm.startPrank(USER2);
        auctioner.propose{value: 0.35 ether}(7, "buyout", IAuctioner.ProposalType.BUYOUT);
        vm.stopPrank();

        vm.warp(block.timestamp + 1);

        // Buyout Votes
        vm.startPrank(USER1);
        governor.castVote(4, IGovernor.VoteType.FOR);
        vm.stopPrank();

        vm.startPrank(USER3);
        governor.castVote(4, IGovernor.VoteType.AGAINST);
        vm.stopPrank();

        vm.startPrank(USER4);
        governor.castVote(4, IGovernor.VoteType.AGAINST);
        vm.stopPrank();

        vm.startPrank(USER5);
        governor.castVote(4, IGovernor.VoteType.FOR);
        vm.stopPrank();

        // Descript (proposal id: 5)
        vm.startPrank(FOUNDATION);
        auctioner.propose(7, "Documentation for asset to be provided until 12.12", IAuctioner.ProposalType.DESCRIPT);
        vm.stopPrank();

        vm.warp(block.timestamp + 1);

        // Descript Votes
        vm.startPrank(USER1);
        governor.castVote(5, IGovernor.VoteType.FOR);
        vm.stopPrank();

        vm.startPrank(USER3);
        governor.castVote(5, IGovernor.VoteType.FOR);
        vm.stopPrank();

        vm.startPrank(USER4);
        governor.castVote(5, IGovernor.VoteType.AGAINST);
        vm.stopPrank();

        vm.startPrank(USER5);
        governor.castVote(5, IGovernor.VoteType.FOR);
        vm.stopPrank();

        vm.warp(block.timestamp + 1);

        // Processing Buyout and Descript
        vm.startPrank(ADMIN);
        governor.exec();
        vm.stopPrank();

        // Claims
        vm.startPrank(USER3);
        auctioner.claim(7);
        vm.stopPrank();

        vm.startPrank(USER5);
        auctioner.claim(7);
        vm.stopPrank();

        /// @dev ARCHIVED AUCTION (id: 8)
        vm.startPrank(ADMIN);
        auctioner.create("Asset", "AST", "https:", 0.01 ether, 30, 10, block.timestamp, block.timestamp + 7 days, BROKER);
        vm.stopPrank();

        vm.startPrank(USER1);
        auctioner.buy{value: 0.1 ether}(8, 10);
        vm.stopPrank();

        vm.startPrank(USER3);
        auctioner.buy{value: 0.1 ether}(8, 10);
        vm.stopPrank();

        vm.startPrank(USER4);
        auctioner.buy{value: 0.04 ether}(8, 4);
        vm.stopPrank();

        vm.startPrank(USER5);
        auctioner.buy{value: 0.06 ether}(8, 6);
        vm.stopPrank();

        // Buyout (proposal id: 6)
        vm.startPrank(USER2);
        auctioner.propose{value: 0.33 ether}(8, "buyout", IAuctioner.ProposalType.BUYOUT);
        vm.stopPrank();

        vm.warp(block.timestamp + 1);

        // Buyout Votes
        vm.startPrank(USER1);
        governor.castVote(6, IGovernor.VoteType.FOR);
        vm.stopPrank();

        vm.startPrank(USER3);
        governor.castVote(6, IGovernor.VoteType.AGAINST);
        vm.stopPrank();

        vm.startPrank(USER4);
        governor.castVote(6, IGovernor.VoteType.AGAINST);
        vm.stopPrank();

        vm.startPrank(USER5);
        governor.castVote(6, IGovernor.VoteType.FOR);
        vm.stopPrank();

        vm.warp(block.timestamp + 1);

        // Processing Buyout
        vm.startPrank(ADMIN);
        governor.exec();
        vm.stopPrank();

        // Claims
        vm.startPrank(USER1);
        auctioner.claim(8);
        vm.stopPrank();

        vm.startPrank(USER3);
        auctioner.claim(8);
        vm.stopPrank();

        vm.startPrank(USER4);
        auctioner.claim(8);
        vm.stopPrank();

        vm.startPrank(USER5);
        auctioner.claim(8);
        vm.stopPrank();
    }
}
