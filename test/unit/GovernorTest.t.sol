// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {Auctioner} from "../../src/Auctioner.sol";
import {Asset} from "../../src/Asset.sol";
import {Governor} from "../../src/Governor.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {DeployPiecesMarket} from "../../script/DeployPiecesMarket.s.sol";

import {IAuctioner} from "../../src/interfaces/IAuctioner.sol";
import {IGovernor} from "../../src/interfaces/IGovernor.sol";

contract GovernorTest is Test {
    DeployPiecesMarket private piecesDeployer;
    Auctioner private auctioner;
    Asset private asset;
    Governor private governor;

    bytes encodedBuyoutFn;
    bytes encodedDescriptFn;

    uint256 private constant STARTING_BALANCE = 100 ether;

    address private ADMIN = vm.addr(vm.envUint("ADMIN_KEY"));
    address private BROKER = vm.addr(vm.envUint("BROKER_KEY"));
    address private FOUNDATION = vm.addr(vm.envUint("FOUNDATION_KEY"));
    address private USER = makeAddr("user");
    address private BUYER = makeAddr("buyer");
    address private DEVIL = makeAddr("devil");

    function setUp() public {
        piecesDeployer = new DeployPiecesMarket();
        (auctioner, governor) = piecesDeployer.run();

        vm.startPrank(ADMIN);
        vm.recordLogs();
        auctioner.create("Asset", "AST", "https:", 2 ether, 100, 10, block.timestamp, block.timestamp + 7 days, BROKER, 500);
        auctioner.create("Asset", "AST", "https:", 2 ether, 100, 10, block.timestamp, block.timestamp + 7 days, BROKER, 500);
        vm.stopPrank();

        Vm.Log[] memory entries = vm.getRecordedLogs();
        address createdAsset = address(uint160(uint256(entries[1].topics[2])));
        asset = Asset(createdAsset);

        encodedBuyoutFn = abi.encodeWithSignature("buyout(uint256)", 0);
        encodedDescriptFn = abi.encodeWithSelector(auctioner.descript.selector, 0, "vamp");

        deal(ADMIN, STARTING_BALANCE);
        deal(FOUNDATION, STARTING_BALANCE);
        deal(BROKER, STARTING_BALANCE);
        deal(USER, STARTING_BALANCE);
        deal(BUYER, STARTING_BALANCE);
        deal(DEVIL, STARTING_BALANCE);
    }

    //////////////////////////////////////////////////////
    //              Propose Function Tests              //
    //////////////////////////////////////////////////////

    function testCantMakeProposalIfNotAuctioner() public {
        vm.prank(DEVIL);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, DEVIL));
        governor.propose(0, address(asset), "buyout", encodedBuyoutFn);
    }

    function testCanMakeBothTypesOfProposal() public proposalMade {
        vm.prank(address(auctioner));
        vm.expectEmit(true, true, true, true, address(governor));
        emit IGovernor.Propose(1, 0, address(asset), block.timestamp, block.timestamp + 7 days, "buyout!", 0);
        vm.expectEmit(true, true, true, true, address(governor));
        emit IGovernor.StateChange(1, IGovernor.ProposalState.ACTIVE);
        governor.propose(0, address(asset), "buyout!", encodedBuyoutFn);

        vm.prank(address(auctioner));
        vm.expectEmit(true, true, true, true, address(governor));
        emit IGovernor.Propose(2, 0, address(asset), block.timestamp, block.timestamp + 7 days, "descript!", 1);
        vm.expectEmit(true, true, true, true, address(governor));
        emit IGovernor.StateChange(2, IGovernor.ProposalState.ACTIVE);
        governor.propose(0, address(asset), "descript!", encodedDescriptFn);

        // AuctionId 1
        encodedBuyoutFn = abi.encodeWithSignature("buyout(uint256)", 1);

        vm.prank(address(auctioner));
        vm.expectEmit(true, true, true, true, address(governor));
        emit IGovernor.Propose(3, 1, address(asset), block.timestamp, block.timestamp + 7 days, "buyout!", 0);
        vm.expectEmit(true, true, true, true, address(governor));
        emit IGovernor.StateChange(3, IGovernor.ProposalState.ACTIVE);
        governor.propose(1, address(asset), "buyout!", encodedBuyoutFn);
    }

    /////////////////////////////////////////////////////////
    //              Cast Votes Function Tests              //
    /////////////////////////////////////////////////////////

    function testCantVoteForNonExistentProposal() public {
        vm.prank(USER);
        auctioner.buy{value: 6 ether}(0, 3);

        vm.prank(USER);
        vm.expectRevert(IGovernor.Governor__ProposalDoesNotExist.selector);
        governor.castVote(0, IGovernor.VoteType.FOR);
    }

    function testCantVoteForNotActiveProposal() public proposalMade {
        vm.prank(USER);
        auctioner.buy{value: 6 ether}(0, 3);

        vm.warp(block.timestamp + 8 days);

        (bool isExecNeeded, ) = governor.checker();
        if (isExecNeeded) governor.exec();

        vm.prank(USER);
        vm.expectRevert(IGovernor.Governor__ProposalNotActive.selector);
        governor.castVote(0, IGovernor.VoteType.FOR);
    }

    function testCantVoteWithoutVotingPower() public proposalMade {
        vm.warp(block.timestamp + 1);

        vm.prank(USER);
        vm.expectRevert(IGovernor.Governor__ZeroVotingPower.selector);
        governor.castVote(0, IGovernor.VoteType.FOR);
    }

    function testBuyerCanVote() public proposalMade {
        vm.prank(USER);
        auctioner.buy{value: 6 ether}(0, 3);

        vm.warp(block.timestamp + 1);

        uint snapshotVotes = asset.getPastVotes(USER, asset.clock() - 1);

        assertEq(snapshotVotes, 3);
        assertEq(asset.balanceOf(USER), 3);
        assertEq(asset.getVotes(USER), 3);

        vm.prank(USER);
        governor.castVote(0, IGovernor.VoteType.FOR);
    }

    function testAftermarketBuyerCanVote() public {
        vm.prank(USER);
        auctioner.buy{value: 6 ether}(0, 3);

        vm.warp(block.timestamp + 1);

        uint snapshotVotes;
        snapshotVotes = asset.getPastVotes(USER, asset.clock() - 1);

        assertEq(snapshotVotes, 3);
        assertEq(asset.balanceOf(USER), 3);
        assertEq(asset.getVotes(USER), 3);

        uint256[] memory tokensToTransfer = new uint256[](2);
        tokensToTransfer[0] = 0;
        tokensToTransfer[1] = 2;

        vm.startPrank(USER);
        asset.safeBatchTransferFrom(USER, DEVIL, tokensToTransfer);
        vm.stopPrank();

        vm.warp(block.timestamp + 1);

        snapshotVotes = asset.getPastVotes(USER, asset.clock() - 1);
        uint devilSnapshotVotes = asset.getPastVotes(DEVIL, asset.clock() - 1);

        assertEq(snapshotVotes, 1);
        assertEq(asset.balanceOf(USER), 1);
        assertEq(asset.getVotes(USER), 1);

        assertEq(devilSnapshotVotes, 2);
        assertEq(asset.balanceOf(DEVIL), 2);
        assertEq(asset.getVotes(DEVIL), 2);

        vm.warp(block.timestamp + 1);

        /// @dev We create proposal when both DEVIL and USER got voting power, so they can vote
        vm.prank(address(auctioner));
        governor.propose(0, address(asset), "buyout!", encodedBuyoutFn);

        vm.warp(block.timestamp + 1);

        vm.prank(USER);
        governor.castVote(0, IGovernor.VoteType.FOR);

        vm.prank(DEVIL);
        governor.castVote(0, IGovernor.VoteType.FOR);

        (uint forVotes, uint againstVotes) = governor.proposalVotes(0);

        assertEq(forVotes, 3);
        assertEq(againstVotes, 0);
    }

    function testAftermarketBuyerCantVote() public proposalMade {
        vm.prank(USER);
        auctioner.buy{value: 6 ether}(0, 3);

        vm.warp(block.timestamp + 1);

        uint snapshotVotes;
        snapshotVotes = asset.getPastVotes(USER, asset.clock() - 1);

        assertEq(snapshotVotes, 3);
        assertEq(asset.balanceOf(USER), 3);
        assertEq(asset.getVotes(USER), 3);

        vm.startPrank(USER);
        asset.safeTransferFrom(USER, DEVIL, 0);
        asset.safeTransferFrom(USER, DEVIL, 2);
        vm.stopPrank();

        vm.warp(block.timestamp + 1);

        snapshotVotes = asset.getPastVotes(USER, asset.clock() - 1);
        uint devilSnapshotVotes = asset.getPastVotes(DEVIL, asset.clock() - 1);

        assertEq(snapshotVotes, 1);
        assertEq(asset.balanceOf(USER), 1);
        assertEq(asset.getVotes(USER), 1);

        assertEq(devilSnapshotVotes, 2);
        assertEq(asset.balanceOf(DEVIL), 2);
        assertEq(asset.getVotes(DEVIL), 2);

        vm.prank(DEVIL);
        vm.expectRevert(IGovernor.Governor__ZeroVotingPower.selector);
        governor.castVote(0, IGovernor.VoteType.FOR);
    }

    function testCantVoteMultipleTimes() public proposalMade {
        vm.prank(USER);
        auctioner.buy{value: 6 ether}(0, 3);

        vm.warp(block.timestamp + 1);

        uint snapshotVotes;
        snapshotVotes = asset.getPastVotes(USER, asset.clock() - 1);

        assertEq(snapshotVotes, 3);
        assertEq(asset.balanceOf(USER), 3);
        assertEq(asset.getVotes(USER), 3);

        vm.prank(USER);
        governor.castVote(0, IGovernor.VoteType.FOR);

        vm.prank(USER);
        vm.expectRevert(IGovernor.Governor__AlreadyVoted.selector);
        governor.castVote(0, IGovernor.VoteType.FOR);

        /// @dev Transfer To Devil
        vm.startPrank(USER);
        asset.safeTransferFrom(USER, DEVIL, 0);
        asset.safeTransferFrom(USER, DEVIL, 2);
        vm.stopPrank();

        vm.warp(block.timestamp + 1);

        snapshotVotes = asset.getPastVotes(DEVIL, asset.clock() - 1);

        assertEq(snapshotVotes, 2);
        assertEq(asset.balanceOf(DEVIL), 2);
        assertEq(asset.getVotes(DEVIL), 2);

        vm.prank(DEVIL);
        vm.expectRevert(IGovernor.Governor__ZeroVotingPower.selector);
        governor.castVote(0, IGovernor.VoteType.FOR);

        (uint forVotes, uint againstVotes) = governor.proposalVotes(0);

        assertEq(forVotes, 3);
        assertEq(againstVotes, 0);
    }

    function testCanCountVotesForMultipleProposals() public proposalMade {
        vm.prank(USER);
        auctioner.buy{value: 6 ether}(0, 3);

        vm.warp(block.timestamp + 1);

        vm.prank(address(auctioner));
        governor.propose(0, address(asset), "buyout!", encodedBuyoutFn);

        vm.warp(block.timestamp + 1);

        vm.prank(USER);
        governor.castVote(0, IGovernor.VoteType.FOR);

        vm.warp(block.timestamp + 1);

        uint snapshotVotes;
        snapshotVotes = asset.getPastVotes(USER, asset.clock() - 1);

        assertEq(snapshotVotes, 3);
        assertEq(asset.balanceOf(USER), 3);
        assertEq(asset.getVotes(USER), 3);

        vm.warp(block.timestamp + 1);

        vm.prank(USER);
        governor.castVote(1, IGovernor.VoteType.AGAINST);

        vm.warp(block.timestamp + 1);

        snapshotVotes = asset.getPastVotes(USER, asset.clock() - 1);

        assertEq(snapshotVotes, 3);
        assertEq(asset.balanceOf(USER), 3);
        assertEq(asset.getVotes(USER), 3);

        /// @dev We can move below vars to global, so it will be reusable for multiple tests
        uint forVotes;
        uint againstVotes;

        (forVotes, againstVotes) = governor.proposalVotes(0);
        assertEq(forVotes, 3);
        assertEq(againstVotes, 0);

        (forVotes, againstVotes) = governor.proposalVotes(1);
        assertEq(forVotes, 0);
        assertEq(againstVotes, 3);
    }

    function testPreviousTokenADMINCantVote() public {
        vm.prank(USER);
        auctioner.buy{value: 6 ether}(0, 3);

        vm.warp(block.timestamp + 1);

        /// @dev Transfer To Devil
        vm.startPrank(USER);
        asset.safeTransferFrom(USER, DEVIL, 0);
        asset.safeTransferFrom(USER, DEVIL, 1);
        asset.safeTransferFrom(USER, DEVIL, 2);
        vm.stopPrank();

        vm.warp(block.timestamp + 1);

        uint snapshotVotes;
        snapshotVotes = asset.getPastVotes(USER, asset.clock() - 1);

        assertEq(snapshotVotes, 0);
        assertEq(asset.balanceOf(USER), 0);
        assertEq(asset.getVotes(USER), 0);

        snapshotVotes = asset.getPastVotes(DEVIL, asset.clock() - 1);

        assertEq(snapshotVotes, 3);
        assertEq(asset.balanceOf(DEVIL), 3);
        assertEq(asset.getVotes(DEVIL), 3);

        /// @dev Creating proposal on updated votes
        vm.prank(address(auctioner));
        governor.propose(0, address(asset), "buyout!", encodedBuyoutFn);

        vm.warp(block.timestamp + 1);

        vm.prank(USER);
        vm.expectRevert(IGovernor.Governor__ZeroVotingPower.selector);
        governor.castVote(0, IGovernor.VoteType.AGAINST);

        vm.prank(DEVIL);
        governor.castVote(0, IGovernor.VoteType.AGAINST);
    }

    /////////////////////////////////////////////////////////////////
    //              Gelato Automation Functions Tests              //
    /////////////////////////////////////////////////////////////////

    function testCantCallIncorrectlyEncodedFunction() public {
        encodedBuyoutFn = abi.encodeWithSignature("buyoutt(uint256)", 0);
        encodedDescriptFn = abi.encodeWithSignature("descriptt(uint256,string)", 0, "hastur");

        vm.warp(block.timestamp + 7 days);
        vm.prank(BUYER);
        auctioner.buy{value: 6 ether}(0, 3);
        vm.prank(DEVIL);
        auctioner.buy{value: 12 ether}(0, 6);
        vm.prank(USER);
        auctioner.buy{value: 4 ether}(0, 2);

        vm.startPrank(address(auctioner));
        governor.propose(0, address(asset), "buyout!", encodedBuyoutFn); // 0
        vm.stopPrank();

        vm.warp(block.timestamp + 1);

        vm.prank(BUYER);
        governor.castVote(0, IGovernor.VoteType.AGAINST);
        vm.prank(DEVIL);
        governor.castVote(0, IGovernor.VoteType.FOR);
        vm.prank(USER);
        governor.castVote(0, IGovernor.VoteType.AGAINST);

        vm.warp(block.timestamp + 7 days);
        (bool isExecNeeded, ) = governor.checker();
        vm.expectRevert(IGovernor.Governor__ExecuteFailed.selector);
        if (isExecNeeded) governor.exec();

        vm.prank(address(auctioner));
        governor.propose(0, address(asset), "vna", encodedDescriptFn); // 1

        vm.warp(block.timestamp + 1);

        vm.prank(BUYER);
        governor.castVote(1, IGovernor.VoteType.AGAINST);
        vm.prank(DEVIL);
        governor.castVote(1, IGovernor.VoteType.FOR);
        vm.prank(USER);
        governor.castVote(1, IGovernor.VoteType.AGAINST);

        vm.warp(block.timestamp + 7 days);
        (bool isExecNecessary, ) = governor.checker();
        vm.expectRevert(IGovernor.Governor__ExecuteFailed.selector);
        if (isExecNecessary) governor.exec();
    }

    function testAutomationWorksAsIntended() public {
        vm.warp(block.timestamp + 7 days);
        (bool isExecNeeded, ) = governor.checker();
        assertEq(isExecNeeded, false);

        vm.prank(BUYER);
        auctioner.buy{value: 6 ether}(0, 3);

        vm.prank(DEVIL);
        auctioner.buy{value: 12 ether}(0, 6);

        vm.prank(USER);
        auctioner.buy{value: 4 ether}(0, 2);

        vm.startPrank(address(auctioner));
        governor.propose(0, address(asset), "buyout!", encodedBuyoutFn); // 0
        governor.propose(1, address(asset), "buyout!", encodedBuyoutFn); // 1
        vm.warp(block.timestamp + 4 days);
        governor.propose(2, address(asset), "buyout!", encodedBuyoutFn); // 2
        governor.propose(0, address(asset), "vna", encodedDescriptFn); // 3
        vm.warp(block.timestamp + 2 days);
        governor.propose(0, address(asset), "buyout!", encodedBuyoutFn); // 4
        governor.propose(0, address(asset), "vna", encodedDescriptFn); // 5
        vm.stopPrank();

        // We dont need to warp here as we do not vote on proposalId 5, previous proposals are minting blocks
        vm.prank(BUYER);
        governor.castVote(1, IGovernor.VoteType.AGAINST);
        vm.prank(DEVIL);
        governor.castVote(1, IGovernor.VoteType.FOR);
        vm.prank(USER);
        governor.castVote(1, IGovernor.VoteType.AGAINST);

        vm.prank(BUYER);
        governor.castVote(2, IGovernor.VoteType.AGAINST);
        vm.prank(DEVIL);
        governor.castVote(2, IGovernor.VoteType.FOR);
        vm.prank(USER);
        governor.castVote(2, IGovernor.VoteType.AGAINST);

        vm.warp(block.timestamp + 3 days + 1);
        (bool isExecNecessary, bytes memory execPayload) = governor.checker();

        assertEq(isExecNecessary, true);
        assertEq(execPayload, abi.encodeWithSignature("exec()"));

        if (isExecNeeded) {
            vm.expectEmit(true, true, true, true, address(governor));
            emit IGovernor.StateChange(3, IGovernor.ProposalState.FAILED);
            vm.expectEmit(true, true, true, true, address(governor));
            emit IGovernor.StateChange(0, IGovernor.ProposalState.FAILED);
            vm.expectEmit(true, true, true, true, address(governor));
            emit IGovernor.StateChange(2, IGovernor.ProposalState.SUCCEEDED);
            vm.expectEmit(true, true, true, true, address(governor));
            emit IGovernor.StateChange(1, IGovernor.ProposalState.SUCCEEDED);
            governor.exec();
        }

        vm.warp(block.timestamp + 1);

        vm.prank(address(auctioner));
        governor.propose(0, address(asset), "arc", encodedDescriptFn); // 2

        vm.warp(block.timestamp + 7 days + 1);
        vm.expectEmit(true, true, true, true, address(governor));
        emit IGovernor.StateChange(6, IGovernor.ProposalState.FAILED);
        vm.expectEmit(true, true, true, true, address(governor));
        emit IGovernor.StateChange(5, IGovernor.ProposalState.FAILED);
        vm.expectEmit(true, true, true, true, address(governor));
        emit IGovernor.StateChange(4, IGovernor.ProposalState.FAILED);
        governor.exec();

        vm.prank(address(auctioner));
        governor.propose(0, address(asset), "fds", encodedDescriptFn); // 3

        vm.prank(address(auctioner));
        governor.propose(0, address(asset), "buy!", encodedBuyoutFn); // 4
    }

    modifier proposalMade() {
        vm.prank(address(auctioner));
        governor.propose(0, address(asset), "buyout!", encodedBuyoutFn);

        _;
    }
}
