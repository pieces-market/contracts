// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {Auctioner} from "../../src/Auctioner.sol";
import {Governor} from "../../src/Governor.sol";
import {Asset} from "../../src/Asset.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {DeployPiecesMarket} from "../../script/DeployPiecesMarket.s.sol";
import {InvalidRecipient} from "../mocks/InvalidRecipient.sol";

import {IAuctioner} from "../../src/interfaces/IAuctioner.sol";
import {IGovernor} from "../../src/interfaces/IGovernor.sol";
import {IERC721A} from "@ERC721A/contracts/IERC721A.sol";

contract AuctionerTest is Test {
    DeployPiecesMarket private piecesDeployer;
    Auctioner private auctioner;
    Asset private asset;
    Governor private governor;

    uint256 private constant STARTING_BALANCE = 500 ether;

    address private OWNER = vm.addr(vm.envUint("PRIVATE_KEY"));
    address private FOUNDATION = vm.addr(vm.envUint("FOUNDATION_KEY"));
    address private BROKER = makeAddr("broker");
    address private USER = makeAddr("user");
    address private BUYER = makeAddr("buyer");
    address private DEVIL = makeAddr("devil");

    function setUp() public {
        piecesDeployer = new DeployPiecesMarket();
        (auctioner, governor) = piecesDeployer.run();

        deal(OWNER, STARTING_BALANCE);
        deal(BROKER, STARTING_BALANCE);
        deal(USER, STARTING_BALANCE);
        deal(BUYER, STARTING_BALANCE);
        deal(DEVIL, STARTING_BALANCE);
        deal(FOUNDATION, STARTING_BALANCE);
    }

    /////////////////////////////////////////////////////
    //              Create Function Tests              //
    /////////////////////////////////////////////////////

    function testCantCreateAuctionIfNotOwnerOrIfPassingIncorrectParameters() public {
        vm.prank(DEVIL);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, DEVIL));
        auctioner.create("Asset", "AST", "https:", 2 ether, 100, 25, block.timestamp, 7, BROKER);

        vm.prank(OWNER);
        vm.expectRevert(IAuctioner.Auctioner__ZeroValueNotAllowed.selector);
        auctioner.create("Asset", "AST", "https:", 0, 100, 25, block.timestamp, 7, BROKER);

        vm.prank(OWNER);
        vm.expectRevert(IAuctioner.Auctioner__ZeroValueNotAllowed.selector);
        auctioner.create("Asset", "AST", "https:", 2 ether, 0, 25, block.timestamp, 7, BROKER);

        vm.prank(OWNER);
        vm.expectRevert(IAuctioner.Auctioner__ZeroValueNotAllowed.selector);
        auctioner.create("Asset", "AST", "https:", 2 ether, 100, 0, block.timestamp, 7, BROKER);

        vm.prank(OWNER);
        vm.expectRevert(IAuctioner.Auctioner__ZeroValueNotAllowed.selector);
        auctioner.create("", "AST", "https:", 2 ether, 100, 25, block.timestamp, 7, BROKER);

        vm.prank(OWNER);
        vm.expectRevert(IAuctioner.Auctioner__ZeroValueNotAllowed.selector);
        auctioner.create("Asset", "", "https:", 2 ether, 100, 25, block.timestamp, 7, BROKER);

        vm.prank(OWNER);
        vm.expectRevert(IAuctioner.Auctioner__ZeroValueNotAllowed.selector);
        auctioner.create("Asset", "AST", "", 2 ether, 100, 25, block.timestamp, 7, BROKER);

        vm.prank(OWNER);
        vm.expectRevert(IAuctioner.Auctioner__IncorrectTimestamp.selector);
        auctioner.create("Asset", "AST", "https:", 2 ether, 100, 25, 0, 7, BROKER);

        vm.prank(OWNER);
        vm.expectRevert(IAuctioner.Auctioner__IncorrectTimestamp.selector);
        auctioner.create("Asset", "AST", "https:", 2 ether, 100, 25, block.timestamp, 0, BROKER);

        vm.prank(OWNER);
        vm.expectRevert(IAuctioner.Auctioner__ZeroAddressNotAllowed.selector);
        auctioner.create("Asset", "AST", "https:", 2 ether, 100, 25, block.timestamp, 7, address(0));
    }

    function testCanCreateAuctionAndEmitCreate() public {
        vm.prank(OWNER);
        vm.expectEmit(false, false, false, false, address(auctioner));
        emit IAuctioner.Create(0, address(asset), 2 ether, 100, 25, block.timestamp, block.timestamp + 7 days, BROKER);
        vm.expectEmit(true, true, true, true, address(auctioner));
        emit IAuctioner.StateChange(0, IAuctioner.AuctionState.OPENED);
        auctioner.create("Asset", "AST", "https:", 2 ether, 100, 25, block.timestamp, 7, BROKER);
    }

    //////////////////////////////////////////////////
    //              Buy Function Tests              //
    //////////////////////////////////////////////////

    function testCantBuyPiecesIfCondidtionsNotMet() public auctionCreated {
        vm.prank(USER);
        vm.expectRevert(IAuctioner.Auctioner__AuctionDoesNotExist.selector);
        auctioner.buy{value: 6 ether}(1, 3);

        vm.prank(USER);
        vm.expectRevert(IERC721A.MintZeroQuantity.selector);
        auctioner.buy{value: 0 ether}(0, 0);

        vm.prank(USER);
        vm.expectRevert(IAuctioner.Auctioner__BuyLimitExceeded.selector);
        auctioner.buy{value: 52 ether}(0, 26);

        vm.prank(USER);
        vm.expectRevert(IAuctioner.Auctioner__IncorrectFundsTransfer.selector);
        auctioner.buy{value: 1 ether}(0, 1);

        vm.prank(USER);
        vm.expectRevert(IAuctioner.Auctioner__IncorrectFundsTransfer.selector);
        auctioner.buy{value: 3 ether}(0, 1);
    }

    function testCantBuyPiecesIfAuctionNotOpened() public auctionCreated auctionClosed {
        vm.prank(USER);
        vm.expectRevert(IAuctioner.Auctioner__AuctionNotOpened.selector);
        auctioner.buy{value: 6 ether}(0, 3);
    }

    function testCantBuyPiecesIfInsufficientAmountLeftForSell() public auctionCreated {
        vm.prank(BROKER);
        auctioner.buy{value: 50 ether}(0, 25);

        vm.prank(DEVIL);
        auctioner.buy{value: 50 ether}(0, 25);

        vm.prank(BUYER);
        auctioner.buy{value: 50 ether}(0, 25);

        vm.prank(FOUNDATION);
        auctioner.buy{value: 48 ether}(0, 24);

        vm.prank(USER);
        vm.expectRevert(IAuctioner.Auctioner__InsufficientPieces.selector);
        auctioner.buy{value: 4 ether}(0, 2);

        vm.prank(FOUNDATION);
        vm.expectEmit(true, true, true, true, address(auctioner));
        emit IAuctioner.StateChange(0, IAuctioner.AuctionState.CLOSED);
        vm.expectEmit(true, true, true, true, address(auctioner));
        emit IAuctioner.TransferToBroker(0, 200 ether, BROKER);
        auctioner.buy{value: 2 ether}(0, 1);
    }

    function testBuyPiecesTransferFail() public {
        InvalidRecipient recipient = new InvalidRecipient();

        vm.prank(OWNER);
        auctioner.create("Asset", "AST", "https:", 2 ether, 100, 25, block.timestamp, 7, address(recipient));

        vm.prank(BROKER);
        auctioner.buy{value: 50 ether}(0, 25);

        vm.prank(DEVIL);
        auctioner.buy{value: 50 ether}(0, 25);

        vm.prank(BUYER);
        auctioner.buy{value: 50 ether}(0, 25);

        vm.prank(FOUNDATION);
        vm.expectRevert(IAuctioner.Auctioner__TransferFailed.selector);
        auctioner.buy{value: 50 ether}(0, 25);
    }

    function testCanBuyPieces() public auctionCreated {
        uint balance = USER.balance;

        vm.prank(USER);
        vm.expectEmit(true, true, true, true, address(auctioner));
        emit IAuctioner.Purchase(0, 3, USER);
        auctioner.buy{value: 6 ether}(0, 3);

        assertEq(USER.balance, balance - 6 ether);
    }

    //////////////////////////////////////////////////////
    //              Propose Function Tests              //
    //////////////////////////////////////////////////////

    function testCantProposeWhenAuctionNotClosed() public auctionCreated {
        vm.prank(DEVIL);
        vm.expectRevert(IAuctioner.Auctioner__AuctionNotClosed.selector);
        auctioner.propose{value: 210 ether}(0, "", IAuctioner.ProposalType.BUYOUT);

        vm.prank(FOUNDATION);
        vm.expectRevert(IAuctioner.Auctioner__AuctionNotClosed.selector);
        auctioner.propose(0, "", IAuctioner.ProposalType.DESCRIPT);
    }

    function testCantProposeForNonExistentAuctionIndex() public auctionCreated auctionClosed {
        vm.prank(DEVIL);
        vm.expectRevert(IAuctioner.Auctioner__AuctionDoesNotExist.selector);
        auctioner.propose{value: 210 ether}(1, "", IAuctioner.ProposalType.BUYOUT);

        vm.prank(FOUNDATION);
        vm.expectRevert(IAuctioner.Auctioner__AuctionDoesNotExist.selector);
        auctioner.propose(1, "", IAuctioner.ProposalType.DESCRIPT);
    }

    function testCantProposeIfOfferTooLowOrProposalAlreadyExist() public auctionCreated auctionClosed {
        vm.prank(DEVIL);
        vm.expectRevert(IAuctioner.Auctioner__InsufficientFunds.selector);
        auctioner.propose{value: 150 ether}(0, "", IAuctioner.ProposalType.BUYOUT);

        vm.prank(OWNER);
        auctioner.propose{value: 210 ether}(0, "", IAuctioner.ProposalType.BUYOUT);

        vm.prank(DEVIL);
        vm.expectRevert(IAuctioner.Auctioner__ProposalInProgress.selector);
        auctioner.propose{value: 230 ether}(0, "", IAuctioner.ProposalType.BUYOUT);

        vm.prank(FOUNDATION);
        auctioner.propose(0, "Description", IAuctioner.ProposalType.DESCRIPT);

        vm.prank(FOUNDATION);
        vm.expectRevert(IAuctioner.Auctioner__ProposalInProgress.selector);
        auctioner.propose(0, "Description", IAuctioner.ProposalType.DESCRIPT);
    }

    function testCantDescriptIfNotFoundationOrNoDescriptionOrAnyTransferValue() public auctionCreated auctionClosed {
        vm.prank(OWNER);
        vm.expectRevert(IAuctioner.Auctioner__UnauthorizedCaller.selector);
        auctioner.propose(0, "", IAuctioner.ProposalType.DESCRIPT);

        vm.prank(FOUNDATION);
        vm.expectRevert(IAuctioner.Auctioner__Overpayment.selector);
        auctioner.propose{value: 1 ether}(0, "", IAuctioner.ProposalType.DESCRIPT);

        vm.prank(FOUNDATION);
        vm.expectRevert(IAuctioner.Auctioner__IncorrectDescriptionSize.selector);
        auctioner.propose(0, "", IAuctioner.ProposalType.DESCRIPT);
    }

    function testFunctionCallFailWhenProposing() public {
        vm.startPrank(OWNER);
        InvalidRecipient newGovernor = new InvalidRecipient();
        Auctioner corruptedAuctioner = new Auctioner(FOUNDATION, address(newGovernor));
        newGovernor.transferOwnership(address(corruptedAuctioner));
        corruptedAuctioner.create("Asset", "AST", "https:", 2 ether, 100, 25, block.timestamp, 7, BROKER);
        vm.stopPrank();

        vm.prank(USER);
        corruptedAuctioner.buy{value: 50 ether}(0, 25);
        vm.prank(DEVIL);
        corruptedAuctioner.buy{value: 50 ether}(0, 25);
        vm.prank(BUYER);
        corruptedAuctioner.buy{value: 50 ether}(0, 25);
        vm.prank(FOUNDATION);
        corruptedAuctioner.buy{value: 50 ether}(0, 25);
        vm.warp(block.timestamp + 7 days + 1);
        (bool upkeep, ) = auctioner.checker();
        if (upkeep) corruptedAuctioner.exec();

        vm.prank(OWNER);
        vm.expectRevert(IAuctioner.Auctioner__FunctionCallFailed.selector);
        corruptedAuctioner.propose{value: 210 ether}(0, "", IAuctioner.ProposalType.BUYOUT);

        vm.prank(FOUNDATION);
        vm.expectRevert(IAuctioner.Auctioner__FunctionCallFailed.selector);
        corruptedAuctioner.propose(0, "I propose to pass dark forest kingom to Astaroth", IAuctioner.ProposalType.DESCRIPT);
    }

    function testCantExecuteBuyoutDescriptOrRejectIfNotGovernor() public auctionCreated {
        vm.prank(DEVIL);
        vm.expectRevert(IAuctioner.Auctioner__UnauthorizedCaller.selector);
        auctioner.buyout(0);

        vm.prank(DEVIL);
        vm.expectRevert(IAuctioner.Auctioner__UnauthorizedCaller.selector);
        auctioner.descript(0, "Description");

        vm.prank(DEVIL);
        vm.expectRevert(IAuctioner.Auctioner__UnauthorizedCaller.selector);
        auctioner.reject(0, bytes(""));
    }

    function testCanBuyout() public auctionCreated auctionClosed {
        uint balance = BROKER.balance;

        vm.prank(BROKER);
        vm.expectEmit(true, true, true, true, address(auctioner));
        emit IAuctioner.Propose(0, 210 ether, BROKER);
        auctioner.propose{value: 210 ether}(0, "", IAuctioner.ProposalType.BUYOUT);

        assertEq(BROKER.balance, balance - 210 ether);

        vm.warp(block.timestamp + 1);

        vm.prank(USER);
        governor.castVote(0, IGovernor.VoteType.FOR);

        vm.prank(DEVIL);
        governor.castVote(0, IGovernor.VoteType(0));

        vm.prank(BUYER);
        governor.castVote(0, IGovernor.VoteType(0));

        vm.warp(block.timestamp + 1 days);
        vm.expectEmit(true, true, true, true, address(auctioner));
        emit IAuctioner.Buyout(0, 210 ether, BROKER);
        vm.expectEmit(true, true, true, true, address(auctioner));
        emit IAuctioner.StateChange(0, IAuctioner.AuctionState.FINISHED);
        governor.exec();
    }

    function testCanDescript() public auctionCreated auctionClosed {
        vm.prank(FOUNDATION);
        vm.expectEmit(true, true, true, true, address(auctioner));
        emit IAuctioner.Propose(0, 0, FOUNDATION);
        auctioner.propose(0, "I propose to pass dark forest kingom to Astaroth", IAuctioner.ProposalType.DESCRIPT);

        vm.warp(block.timestamp + 1);

        vm.prank(USER);
        governor.castVote(0, IGovernor.VoteType.FOR);

        vm.prank(DEVIL);
        governor.castVote(0, IGovernor.VoteType(0));

        vm.prank(BUYER);
        governor.castVote(0, IGovernor.VoteType(0));

        vm.warp(block.timestamp + 1 days);
        vm.expectEmit(true, true, true, true, address(auctioner));
        emit IAuctioner.Descript(0, "I propose to pass dark forest kingom to Astaroth");
        governor.exec();
    }

    function testCanRejectBuyout() public auctionCreated auctionClosed {
        vm.prank(BROKER);
        auctioner.propose{value: 210 ether}(0, "", IAuctioner.ProposalType.BUYOUT);

        vm.warp(block.timestamp + 1);

        vm.prank(USER);
        governor.castVote(0, IGovernor.VoteType.FOR);

        vm.warp(block.timestamp + 1 days);
        vm.expectEmit(true, true, true, true, address(auctioner));
        emit IAuctioner.Reject(0);
        governor.exec();
    }

    function testCanRejectDescript() public auctionCreated auctionClosed {
        vm.prank(FOUNDATION);
        auctioner.propose(0, "I propose to pass dark forest kingom to Astaroth", IAuctioner.ProposalType.DESCRIPT);

        vm.warp(block.timestamp + 1);

        vm.prank(USER);
        governor.castVote(0, IGovernor.VoteType.FOR);

        vm.warp(block.timestamp + 1 days);
        vm.expectEmit(true, true, true, true, address(auctioner));
        emit IAuctioner.Reject(0);
        governor.exec();
    }

    ///////////////////////////////////////////////////////
    //              Withdraw Function Tests              //
    ///////////////////////////////////////////////////////

    function testCantWithdrawForNonExistentAuction() public auctionCreated auctionClosed {
        vm.prank(OWNER);
        vm.expectRevert(IAuctioner.Auctioner__AuctionDoesNotExist.selector);
        auctioner.withdraw(6);

        vm.prank(OWNER);
        vm.expectRevert(IAuctioner.Auctioner__ProposalInProgress.selector);
        auctioner.withdraw(0);
    }

    function testCantWithdrawZeroAmount() public auctionCreated auctionClosed {
        vm.prank(OWNER);
        auctioner.propose{value: 210 ether}(0, "", IAuctioner.ProposalType.BUYOUT);

        vm.warp(block.timestamp + 1 days + 1);
        governor.exec();

        vm.prank(OWNER);
        auctioner.withdraw(0);

        vm.prank(OWNER);
        vm.expectRevert(IAuctioner.Auctioner__InsufficientFunds.selector);
        auctioner.withdraw(0);
    }

    function testWithdrawTransferFail() public auctionCreated auctionClosed {
        InvalidRecipient invalidWithdrawer = new InvalidRecipient();
        deal(address(invalidWithdrawer), 300 ether);

        vm.prank(address(invalidWithdrawer));
        auctioner.propose{value: 210 ether}(0, "", IAuctioner.ProposalType.BUYOUT);

        vm.warp(block.timestamp + 1 days + 1);
        governor.exec();

        vm.prank(address(invalidWithdrawer));
        vm.expectRevert(IAuctioner.Auctioner__TransferFailed.selector);
        auctioner.withdraw(0);
    }

    function testCanWithdraw() public auctionCreated auctionClosed {
        vm.prank(OWNER);
        auctioner.propose{value: 210 ether}(0, "", IAuctioner.ProposalType.BUYOUT);

        vm.warp(block.timestamp + 1 days + 1);
        vm.expectEmit(true, true, true, true, address(governor));
        emit IGovernor.StateChange(0, IGovernor.ProposalState.FAILED);
        vm.expectEmit(true, true, true, true, address(governor));
        emit IGovernor.ProcessProposal(0);
        governor.exec();

        uint balance = OWNER.balance;

        vm.prank(OWNER);
        vm.expectEmit(true, true, true, true, address(auctioner));
        emit IAuctioner.Withdraw(0, 210 ether, OWNER);
        auctioner.withdraw(0);

        assertEq(OWNER.balance, balance + 210 ether);
    }

    /////////////////////////////////////////////////////
    //              Refund Function Tests              //
    /////////////////////////////////////////////////////

    function testCantRefundFromNonExistentOrNotFailedAuction() public auctionCreated {
        vm.prank(USER);
        vm.expectRevert(IAuctioner.Auctioner__AuctionDoesNotExist.selector);
        auctioner.refund(6);

        vm.prank(USER);
        vm.expectRevert(IAuctioner.Auctioner__AuctionNotFailed.selector);
        auctioner.refund(0);
    }

    function testCantRefundZeroAmount() public auctionCreated auctionFailed {
        vm.prank(USER);
        auctioner.refund(0);

        vm.prank(USER);
        vm.expectRevert(IAuctioner.Auctioner__InsufficientFunds.selector);
        auctioner.refund(0);
    }

    function testRefundTransferFail() public auctionCreated {
        InvalidRecipient invalidRefunder = new InvalidRecipient();
        deal(address(invalidRefunder), 100 ether);

        vm.prank(address(invalidRefunder));
        auctioner.buy{value: 50 ether}(0, 25);

        vm.warp(block.timestamp + 7 days + 1);
        (bool upkeep, ) = auctioner.checker();
        if (upkeep) auctioner.exec();

        vm.prank(address(invalidRefunder));
        vm.expectRevert(IAuctioner.Auctioner__TransferFailed.selector);
        auctioner.refund(0);

        assertEq(asset.balanceOf(address(invalidRefunder)), 25);
        assertEq(asset.getPastVotes(address(invalidRefunder), asset.clock() - 1), 25);
    }

    function testCanRefund() public auctionCreated auctionFailed {
        uint userBalance = USER.balance;

        vm.prank(USER);
        vm.expectEmit(true, true, true, true, address(auctioner));
        emit IAuctioner.Refund(0, 8 ether, USER);
        auctioner.refund(0);

        assertEq(USER.balance, userBalance + 8 ether);

        vm.prank(DEVIL);
        vm.expectEmit(true, true, true, true, address(auctioner));
        emit IAuctioner.Refund(0, 10 ether, DEVIL);
        auctioner.refund(0);

        vm.prank(BUYER);
        vm.expectEmit(true, true, true, true, address(auctioner));
        emit IAuctioner.Refund(0, 2 ether, BUYER);
        auctioner.refund(0);
    }

    //////////////////////////////////////////////////////
    //              Fulfill Function Tests              //
    //////////////////////////////////////////////////////

    function testCantFulfillIfRequirementsNotMet() public auctionCreated {
        vm.prank(USER);
        vm.expectRevert(IAuctioner.Auctioner__UnauthorizedCaller.selector);
        auctioner.fulfill(0);

        vm.prank(address(0));
        vm.expectRevert(IAuctioner.Auctioner__AuctionDoesNotExist.selector);
        auctioner.fulfill(6);

        vm.prank(address(0));
        vm.expectRevert(IAuctioner.Auctioner__AuctionNotClosed.selector);
        auctioner.fulfill(0);
    }

    function testCantFulfillIfSentInsufficientFunds() public auctionCreated auctionClosed {
        deal(address(0), 205 ether);

        vm.prank(address(0));
        vm.expectRevert(IAuctioner.Auctioner__InsufficientFunds.selector);
        auctioner.fulfill{value: 199 ether}(0);
    }

    function testCanFulfill() public auctionCreated auctionClosed {
        deal(address(0), 205 ether);

        vm.prank(address(0));
        vm.expectRevert(IAuctioner.Auctioner__InsufficientFunds.selector);
        auctioner.fulfill{value: 199 ether}(0);

        vm.prank(address(0));
        vm.expectEmit(true, true, true, true, address(auctioner));
        emit IAuctioner.Fulfill(0, 200 ether, address(0));
        vm.expectEmit(true, true, true, true, address(auctioner));
        emit IAuctioner.StateChange(0, IAuctioner.AuctionState.FINISHED);
        auctioner.fulfill{value: 200 ether}(0);
    }

    ////////////////////////////////////////////////////
    //              Claim Function Tests              //
    ////////////////////////////////////////////////////

    function testCantClaimIfRequirementsNotMet() public auctionCreated {
        vm.prank(USER);
        vm.expectRevert(IAuctioner.Auctioner__AuctionDoesNotExist.selector);
        auctioner.claim(6);

        vm.prank(USER);
        vm.expectRevert(IAuctioner.Auctioner__AuctionNotFinished.selector);
        auctioner.claim(0);
    }

    function testCantClaimZeroAmount() public auctionCreated auctionClosed auctionFinished {
        vm.prank(USER);
        auctioner.claim(0);

        vm.prank(USER);
        vm.expectRevert(IAuctioner.Auctioner__InsufficientFunds.selector);
        auctioner.claim(0);
    }

    function testClaimTransferFail() public auctionCreated {
        InvalidRecipient invalidRefunder = new InvalidRecipient();
        deal(address(invalidRefunder), 100 ether);

        vm.prank(address(invalidRefunder));
        auctioner.buy{value: 50 ether}(0, 25);

        vm.prank(USER);
        auctioner.buy{value: 50 ether}(0, 25);

        vm.prank(DEVIL);
        auctioner.buy{value: 50 ether}(0, 25);

        vm.prank(BUYER);
        auctioner.buy{value: 50 ether}(0, 25);

        vm.warp(block.timestamp + 1);

        deal(address(0), 205 ether);

        vm.prank(address(0));
        auctioner.fulfill{value: 200 ether}(0);

        vm.prank(address(invalidRefunder));
        vm.expectRevert(IAuctioner.Auctioner__TransferFailed.selector);
        auctioner.claim(0);

        assertEq(asset.balanceOf(address(invalidRefunder)), 25);
        assertEq(asset.getPastVotes(address(invalidRefunder), asset.clock() - 1), 25);
    }

    function testCanClaim() public auctionCreated auctionClosed auctionFinished {
        uint balance = USER.balance;
        assertEq(asset.balanceOf(USER), 25);

        vm.prank(USER);
        vm.expectEmit(true, true, true, true, address(auctioner));
        emit IAuctioner.Claim(0, 50 ether, USER);
        auctioner.claim(0);

        assertEq(USER.balance, balance + 50 ether);
        assertEq(asset.balanceOf(USER), 0);

        vm.prank(DEVIL);
        vm.expectEmit(true, true, true, true, address(auctioner));
        emit IAuctioner.Claim(0, 50 ether, DEVIL);
        auctioner.claim(0);

        vm.prank(BUYER);
        vm.expectEmit(true, true, true, true, address(auctioner));
        emit IAuctioner.Claim(0, 50 ether, BUYER);
        auctioner.claim(0);

        vm.prank(FOUNDATION);
        vm.expectEmit(true, true, true, true, address(auctioner));
        emit IAuctioner.Claim(0, 50 ether, FOUNDATION);
        vm.expectEmit(true, true, true, true, address(auctioner));
        emit IAuctioner.StateChange(0, IAuctioner.AuctionState.ARCHIVED);
        auctioner.claim(0);
    }

    function testCanCheck() public {
        bool upkeep;

        (upkeep, ) = auctioner.checker();
        assertEq(upkeep, false);

        vm.startPrank(OWNER);
        auctioner.create("Asset", "AST", "https:", 2 ether, 100, 10, block.timestamp + 1 days, 2, BROKER); // 0
        auctioner.create("Asset", "AST", "https:", 2 ether, 100, 10, block.timestamp, 7, BROKER); // 1
        auctioner.create("Asset", "AST", "https:", 2 ether, 100, 10, block.timestamp, 3, BROKER); // 2
        auctioner.create("Asset", "AST", "https:", 2 ether, 100, 10, block.timestamp + 4 days, 8, BROKER); // 3
        auctioner.create("Asset", "AST", "https:", 2 ether, 100, 10, block.timestamp + 3 days, 2, BROKER); // 4
        auctioner.create("Asset", "AST", "https:", 2 ether, 100, 10, block.timestamp, 2, BROKER); // 5
        vm.stopPrank();

        vm.warp(block.timestamp + 3 days + 1);
        (upkeep, ) = auctioner.checker();
        assertEq(upkeep, true);
    }

    function testCanRemoveUnprocessedAuctions() public {
        bool upkeep;

        vm.startPrank(OWNER);
        auctioner.create("Asset", "AST", "https:", 2 ether, 100, 10, block.timestamp + 1 days, 2, BROKER); // 0
        auctioner.create("Asset", "AST", "https:", 2 ether, 100, 10, block.timestamp, 7, BROKER); // 1
        auctioner.create("Asset", "AST", "https:", 2 ether, 100, 10, block.timestamp, 3, BROKER); // 2
        auctioner.create("Asset", "AST", "https:", 2 ether, 100, 10, block.timestamp + 4 days, 9, BROKER); // 3
        auctioner.create("Asset", "AST", "https:", 2 ether, 100, 10, block.timestamp + 3 days, 2, BROKER); // 4
        auctioner.create("Asset", "AST", "https:", 2 ether, 100, 10, block.timestamp, 2, BROKER); // 5
        vm.stopPrank();

        vm.warp(block.timestamp + 3 days + 1);
        (upkeep, ) = auctioner.checker();
        vm.expectEmit(true, true, true, true, address(auctioner));
        emit IAuctioner.StateChange(0, IAuctioner.AuctionState.OPENED);
        vm.expectEmit(true, true, true, true, address(auctioner));
        emit IAuctioner.StateChange(0, IAuctioner.AuctionState.FAILED);
        vm.expectEmit(true, true, true, true, address(auctioner));
        emit IAuctioner.StateChange(5, IAuctioner.AuctionState.FAILED);
        vm.expectEmit(true, true, true, true, address(auctioner));
        emit IAuctioner.StateChange(4, IAuctioner.AuctionState.OPENED);
        vm.expectEmit(true, true, true, true, address(auctioner));
        emit IAuctioner.StateChange(2, IAuctioner.AuctionState.FAILED);
        if (upkeep) auctioner.exec();

        vm.warp(block.timestamp + 3 days + 1);
        (upkeep, ) = auctioner.checker();
        vm.expectEmit(true, true, true, true, address(auctioner));
        emit IAuctioner.StateChange(4, IAuctioner.AuctionState.FAILED);
        vm.expectEmit(true, true, true, true, address(auctioner));
        emit IAuctioner.StateChange(3, IAuctioner.AuctionState.OPENED);
        if (upkeep) auctioner.exec();

        vm.prank(OWNER);
        auctioner.create("Asset", "AST", "https:", 2 ether, 100, 10, block.timestamp + 6 days, 10, BROKER); // 6

        vm.warp(block.timestamp + 6 days + 1);
        (upkeep, ) = auctioner.checker();
        vm.expectEmit(true, true, true, true, address(auctioner));
        emit IAuctioner.StateChange(1, IAuctioner.AuctionState.FAILED);
        vm.expectEmit(true, true, true, true, address(auctioner));
        emit IAuctioner.StateChange(6, IAuctioner.AuctionState.OPENED);
        if (upkeep) auctioner.exec();
    }

    modifier auctionCreated() {
        vm.prank(OWNER);
        vm.recordLogs();
        auctioner.create("Asset", "AST", "https:", 2 ether, 100, 25, block.timestamp, 7, BROKER);

        Vm.Log[] memory entries = vm.getRecordedLogs();
        address createdAsset = address(uint160(uint256(entries[1].topics[2])));
        asset = Asset(createdAsset);

        console.log("Asset: ", address(asset));

        _;
    }

    modifier auctionFailed() {
        vm.prank(USER);
        auctioner.buy{value: 8 ether}(0, 4);

        vm.prank(DEVIL);
        auctioner.buy{value: 10 ether}(0, 5);

        vm.prank(BUYER);
        auctioner.buy{value: 2 ether}(0, 1);

        vm.warp(block.timestamp + 7 days + 1);
        (bool upkeep, ) = auctioner.checker();
        if (upkeep) auctioner.exec();

        _;
    }

    modifier auctionClosed() {
        vm.prank(USER);
        auctioner.buy{value: 50 ether}(0, 25);

        vm.prank(DEVIL);
        auctioner.buy{value: 50 ether}(0, 25);

        vm.prank(BUYER);
        auctioner.buy{value: 50 ether}(0, 25);

        vm.prank(FOUNDATION);
        auctioner.buy{value: 50 ether}(0, 25);

        vm.warp(block.timestamp + 7 days + 1);
        (bool upkeep, ) = auctioner.checker();
        if (upkeep) auctioner.exec();

        _;
    }

    modifier auctionFinished() {
        deal(address(0), 205 ether);

        vm.prank(address(0));
        vm.expectEmit(true, true, true, true, address(auctioner));
        emit IAuctioner.StateChange(0, IAuctioner.AuctionState.FINISHED);
        auctioner.fulfill{value: 200 ether}(0);

        _;
    }
}
