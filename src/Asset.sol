// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

import {Auctioner} from "./Auctioner.sol";
import {ERC721A} from "@ERC721A/contracts/ERC721A.sol";
import {ERC721AQueryable} from "@ERC721A/contracts/extensions/ERC721AQueryable.sol";
import "./extensions/ERC721AVotes.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {IAsset} from "./interfaces/IAsset.sol";
import {IVotes} from "@openzeppelin/contracts/governance/utils/IVotes.sol";

/// @title Asset Contract
/// @notice ERC721A representation of Asset with cheap batch minting function
contract Asset is ERC721A, ERC721AQueryable, EIP712, ERC721AVotes, ERC2981, Ownable, IAsset {
    string private baseURI;
    address private immutable i_broker;
    uint256 private immutable i_brokerFee;
    address private constant PIECES_MARKET = 0x7eAFE197018d6dfFeF84442Ef113A22A4a191CCD;

    /// @dev Constructor
    /// @param royalty 500 = 5% fee
    /// @param brokerFee 5000 = 50% broker share
    constructor(
        string memory name,
        string memory symbol,
        string memory uri,
        address broker,
        uint96 royalty,
        uint256 brokerFee,
        address owner
    ) ERC721A(name, symbol) EIP712(name, "version 1") Ownable(owner) {
        if (brokerFee > _feeDenominator()) revert InvalidBrokerFee();

        baseURI = uri;
        i_broker = broker;
        i_brokerFee = brokerFee;

        /// @param asset is royalty fee receiver
        _setDefaultRoyalty(address(this), royalty);
    }

    /// @notice Handles incoming royalty payments, splitting the funds between the broker and the pieces market based on the configured broker share
    receive() external payable {
        uint256 brokerShare = (msg.value * i_brokerFee) / _feeDenominator();
        uint256 remainingShare = msg.value - brokerShare;

        (bool brokerTransfer, ) = i_broker.call{value: brokerShare}("");
        (bool piecesTransfer, ) = PIECES_MARKET.call{value: remainingShare}("");

        if (!brokerTransfer || !piecesTransfer) revert RoyaltyTransferFailed();

        // Notify Auctioner of royalty payment split
        Auctioner(owner()).emitRoyaltySplit(msg.sender, i_broker, brokerShare, PIECES_MARKET, remainingShare, msg.value);
    }

    /// @notice Leads to Metadata, which is unique for each token
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /// @dev Prevents tokenURI from adding tokenId to URI as it should be the same for all tokens
    function tokenURI(uint256 tokenId) public view override(ERC721A, IERC721A) returns (string memory) {
        if (!_exists(tokenId)) _revert(URIQueryForNonexistentToken.selector);

        return _baseURI();
    }

    /// @notice Returns total minted tokens amount ignoring performed burns
    /// @dev Call 'totalSupply()' function for amount corrected by burned tokens amount
    function totalMinted() external view returns (uint256) {
        return _totalMinted();
    }

    /// @notice Mints multiple tokens at once to a single user and instantly delegates votes to receiver
    /// @param to Address of receiver of minted tokens
    /// @param quantity Amount of tokens to be minted
    function safeBatchMint(address to, uint256 quantity) external onlyOwner {
        _safeMint(to, quantity);
    }

    /// @notice Burns all tokens owned by user
    /// @param owner Address of tokens owner
    function batchBurn(address owner) external onlyOwner {
        uint256[] memory tokenIds = this.tokensOfOwner(owner);

        _batchBurn(address(0), tokenIds);
    }

    /// @notice Safely transfers `tokenIds` in batch from `from` to `to`
    function safeBatchTransferFrom(address from, address to, uint256[] memory tokenIds) external {
        _safeBatchTransferFrom(msg.sender, from, to, tokenIds, "");
    }

    /// @dev ERC721A FUNCTIONS OVERRIDES ADJUSTING TOKENS LOCK RESTRICTION

    /// @dev This function is blocked intentionally to avoid any potential malfunctions within custom Governor contract
    /// @notice Might be unlocked in further contract versions
    function delegate(address) public pure override {
        revert VotesDelegationOnlyOnTokensTransfer();
    }

    /// @dev This function is blocked intentionally to avoid any potential malfunctions within custom Governor contract
    /// @notice Might be unlocked in further contract versions
    function delegateBySig(address, uint256, uint256, uint8, bytes32, bytes32) public pure override {
        revert VotesDelegationOnlyOnTokensTransfer();
    }

    /// @dev SOLIDITY REQUIRED FUNCTIONS OVERRIDES

    /// @notice Override ERC721A and ERC721AVotes Function
    /// @dev Additionally delegates vote to new token owner
    function _afterTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal override(ERC721A, ERC721AVotes) {
        super._afterTokenTransfers(from, to, startTokenId, quantity);
        if (to != address(0)) _delegate(to, to);
    }

    /// @dev Check if we indeed need this -> if ERC721AQueryable included override(ERC721A, IERC721A)
    ///
    /// @dev ERC721a Governance Token Interface Support
    /// @dev Implements the interface support check for ERC721a Governance Token
    /// @notice Checks if the contract implements an interface you query for, including ERC721A and Votes interfaces
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @return True if the contract implements `interfaceId` or if `interfaceId` is the ERC-165 interface
    function supportsInterface(bytes4 interfaceId) public view override(ERC721A, ERC2981, IERC721A) returns (bool) {
        return
            interfaceId == type(IERC721A).interfaceId ||
            interfaceId == type(ERC721AQueryable).interfaceId ||
            interfaceId == type(IVotes).interfaceId ||
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    ////////////////////////////////////
    /// @dev VOTING MODULE OVERRIDE'S //
    ////////////////////////////////////

    /// @dev Override Vote Function
    /// @notice Changes block.number into block.timestamp for snapshot
    function clock() public view override returns (uint48) {
        return Time.timestamp();
    }

    /// @dev Override Vote Function
    /// @notice Changes block.number into block.timestamp for snapshot
    function CLOCK_MODE() public pure override returns (string memory) {
        // Check that the clock was not modified
        /// @dev Is this check even possible to fail?
        // if (clock() != Time.timestamp()) revert ERC6372InconsistentClock();

        return "mode=timestamp";
    }
}
