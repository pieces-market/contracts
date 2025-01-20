// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {Auctioner} from "../../src/Auctioner.sol";
import {Asset} from "../../src/Asset.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import "../../src/extensions/ERC721AVotes.sol";

import {IAuctioner} from "../../src/interfaces/IAuctioner.sol";
import {IAsset} from "../../src/interfaces/IAsset.sol";
import {IERC721A} from "@ERC721A/contracts/IERC721A.sol";
import {IVotes} from "@openzeppelin/contracts/governance/utils/IVotes.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

contract AssetTest is Test {
    Auctioner private auctioner;
    Asset private asset;

    uint256 private constant STARTING_BALANCE = 100 ether;
    address private constant PIECES_MARKET = 0x7eAFE197018d6dfFeF84442Ef113A22A4a191CCD;

    address private ADMIN = vm.addr(vm.envUint("ADMIN_KEY"));
    address private BROKER = vm.addr(vm.envUint("BROKER_KEY"));
    address private FOUNDATION = vm.addr(vm.envUint("FOUNDATION_KEY"));
    address private USER = makeAddr("user");
    address private DEVIL = makeAddr("devil");
    address private MARKETPLACE = makeAddr("marketplace");

    function setUp() public {
        vm.startPrank(ADMIN);
        auctioner = new Auctioner(FOUNDATION, address(0));

        address precomputedAsset = vm.computeCreateAddress(address(auctioner), vm.getNonce(address(auctioner)));

        vm.recordLogs();
        vm.expectEmit(true, true, true, true, address(auctioner));
        emit IAuctioner.Create(0, precomputedAsset, 2 ether, 100, 10, block.timestamp, block.timestamp + 7 days, BROKER, 500, 6000);
        auctioner.create("Asset", "AST", "https:", 2 ether, 100, 10, block.timestamp, block.timestamp + 7 days, BROKER, 500, 6000);
        vm.stopPrank();

        Vm.Log[] memory entries = vm.getRecordedLogs();
        address createdAsset = address(uint160(uint256(entries[2].topics[2])));
        asset = Asset(payable(createdAsset));

        console.log("Auctioner: ", address(auctioner));
        console.log("Asset: ", address(asset));

        deal(USER, STARTING_BALANCE);
        deal(DEVIL, STARTING_BALANCE);
        deal(MARKETPLACE, STARTING_BALANCE);
    }

    function testCountsTotalMintedTokensAndAssignsCorrectURIAndRevertsForNonExistenToken() public {
        vm.prank(USER);
        auctioner.buy{value: 6 ether}(0, 3);

        vm.prank(DEVIL);
        auctioner.buy{value: 8 ether}(0, 4);

        vm.expectRevert(IERC721A.URIQueryForNonexistentToken.selector);
        asset.tokenURI(7);

        uint totalMinted = asset.totalMinted();
        assertEq(totalMinted, 7);

        string memory userTokenURI = asset.tokenURI(2);
        string memory devTokenURI = asset.tokenURI(5);

        assertEq(userTokenURI, "https:");
        assertEq(devTokenURI, "https:");
    }

    function testCanReceiveVotingPower() public {
        vm.prank(USER);
        auctioner.buy{value: 6 ether}(0, 3);

        /// @dev USE BELOW IF CLOCK() IS SET FOR TIMESTAMP
        vm.warp(block.timestamp + 1);

        /// @dev USE BELOW IF CLOCK() IS SET FOR BLOCK NUMBER
        // vm.roll(block.number + 1);

        uint snapshotVotes = asset.getPastVotes(USER, asset.clock() - 1);
        assertEq(snapshotVotes, 3);
    }

    function testCanTransferTokensAndAdjustVotingPower() public {
        vm.prank(USER);
        auctioner.buy{value: 6 ether}(0, 3);

        vm.warp(block.timestamp + 1);

        console.log("Clock: ", asset.clock());

        uint snapshotVotes;
        snapshotVotes = asset.getPastVotes(USER, asset.clock() - 1);
        assertEq(snapshotVotes, 3);

        vm.startPrank(USER);
        asset.safeTransferFrom(USER, DEVIL, 0);
        asset.safeTransferFrom(USER, DEVIL, 2);
        vm.stopPrank();

        vm.warp(block.timestamp + 1);

        snapshotVotes = asset.getPastVotes(USER, asset.clock() - 1);
        assertEq(snapshotVotes, 1);
        snapshotVotes = asset.getPastVotes(DEVIL, asset.clock() - 1);
        assertEq(snapshotVotes, 2);
    }

    function testCanBatchTransferTokensAndAdjustVotingPower() public {
        vm.prank(USER);
        auctioner.buy{value: 6 ether}(0, 3);

        vm.warp(block.timestamp + 1);

        console.log("Clock: ", asset.clock());

        uint snapshotVotes;
        snapshotVotes = asset.getPastVotes(USER, asset.clock() - 1);
        assertEq(snapshotVotes, 3);

        asset.tokensOfOwner(USER);
        uint[] memory tokens = new uint[](2);
        tokens[0] = 0;
        tokens[1] = 2;

        vm.prank(USER);
        asset.safeBatchTransferFrom(USER, DEVIL, tokens);

        vm.warp(block.timestamp + 1);

        snapshotVotes = asset.getPastVotes(USER, asset.clock() - 1);
        assertEq(snapshotVotes, 1);
        snapshotVotes = asset.getPastVotes(DEVIL, asset.clock() - 1);
        assertEq(snapshotVotes, 2);
    }

    function testCannotDelegateVotesWithoutTokensTransfer() public {
        vm.startPrank(DEVIL);
        vm.expectRevert(IAsset.VotesDelegationOnlyOnTokensTransfer.selector);
        asset.delegate(BROKER);

        vm.expectRevert(IAsset.VotesDelegationOnlyOnTokensTransfer.selector);
        asset.delegateBySig(BROKER, 6, 6, 6, "", "");
    }

    function testCanSupportInterfaces() public view {
        bytes4 votesInterfaceId = type(IVotes).interfaceId;
        bytes4 erc165InterfaceId = type(IERC165).interfaceId;

        assertTrue(asset.supportsInterface(votesInterfaceId));
        assertTrue(asset.supportsInterface(erc165InterfaceId));
    }

    /// @dev COVERAGE DOES NOT ACCEPT 'MockCallRevert', SO THER IS MISSING BRANCH FOR THIS ERROR In COVERAGE
    function testClockMode() public view {
        uint256 currentClock = asset.clock();
        uint256 currentTimestamp = block.timestamp;

        assertEq(currentClock, currentTimestamp);
        assertEq(asset.CLOCK_MODE(), "mode=timestamp");

        // vm.expectRevert(Votes.ERC6372InconsistentClock.selector);
        // vm.mockCallRevert(address(asset), abi.encodeWithSignature("CLOCK_MODE()"), abi.encodeWithSelector(Votes.ERC6372InconsistentClock.selector));
        // asset.CLOCK_MODE();

        // vm.expectRevert(Votes.ERC6372InconsistentClock.selector);
        // try asset.CLOCK_MODE() returns (string memory /*ret*/) {
        //     fail();
        // } catch (bytes memory /*err*/) {
        //     //bytes4 selector = abi.decode("", (bytes4));
        //     assertEq(0x6ff0714000000000000000000000000000000000000000000000000000000000, Votes.ERC6372InconsistentClock.selector);
        // }
    }

    function testCantCreateAssetWithIncorrectRoyaltyFeeNominator() public {
        vm.prank(ADMIN);
        vm.expectRevert(abi.encodeWithSelector(ERC2981.ERC2981InvalidDefaultRoyalty.selector, 10001, 10000));
        auctioner.create("Asset", "AST", "https:", 2 ether, 100, 10, block.timestamp, block.timestamp + 7 days, BROKER, 10001, 50);
    }

    function testCantCreateAssetWithIncorrectBrokerFeeNominator() public {
        vm.prank(ADMIN);
        vm.expectRevert(abi.encodeWithSelector(IAsset.InvalidBrokerFee.selector));
        auctioner.create("Asset", "AST", "https:", 2 ether, 100, 10, block.timestamp, block.timestamp + 7 days, BROKER, 500, 10001);
    }

    function testDefaultRoyaltiesAndRoyaltyValue() public {
        vm.prank(USER);
        auctioner.buy{value: 6 ether}(0, 3);

        vm.prank(DEVIL);
        auctioner.buy{value: 8 ether}(0, 4);

        (address receiver, uint256 royaltyValue) = asset.royaltyInfo(3, 0.0000000017 ether);

        assertEq(receiver, address(asset));
        /// @dev 5% from 1700000000 WEI
        assertEq(royaltyValue, 85000000);
    }

    function testCantExecuteEmitRoyaltyEventIfNotAsset() public {
        vm.prank(DEVIL);
        vm.expectRevert(abi.encodeWithSelector(IAuctioner.Auctioner__NotEligibleCaller.selector));
        auctioner.emitRoyaltySplit(MARKETPLACE, BROKER, 0.3 ether, PIECES_MARKET, 0.2 ether, 0.5 ether);
    }

    function testMarketplacePayment() public {
        console.log("Testing Marketplace Transfer...");
        console.log("Asset: ", address(asset));
        console.log("BROKER: ", BROKER);
        console.log("Pieces: ", FOUNDATION);

        (, uint256 royaltyValue) = asset.royaltyInfo(3, 10 ether);

        vm.prank(MARKETPLACE);
        vm.expectEmit(true, true, true, true, address(auctioner));
        emit IAuctioner.RoyaltySplitExecuted(MARKETPLACE, BROKER, 0.3 ether, PIECES_MARKET, 0.2 ether, 0.5 ether);
        (bool marketplaceRoyaltyTransfer, ) = address(asset).call{value: royaltyValue}("");
        assertEq(true, marketplaceRoyaltyTransfer);

        // Royalty: 5% - 0.5 ether
        // Broker Fee: 40% - Broker: 0.3 ether Pieces: 0.2 ether

        assertEq(address(asset).balance, 0);
        assertEq(MARKETPLACE.balance, 99.5 ether);
        assertEq(BROKER.balance, 0.3 ether);
        assertEq(FOUNDATION.balance, 0.2 ether);
    }
}
