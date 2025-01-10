// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

import {ERC721A} from "@ERC721A/contracts/ERC721A.sol";
import {ERC721AQueryable} from "@ERC721A/contracts/extensions/ERC721AQueryable.sol";
import "./extensions/ERC721AVotes.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {IVotes} from "@openzeppelin/contracts/governance/utils/IVotes.sol";

/// @title Asset Contract
/// @notice ERC721A representation of Asset with cheap batch minting function
contract Asset is ERC721A, ERC721AQueryable, EIP712, ERC721AVotes, ERC2981, Ownable {
    /// @dev Errors
    error VotesDelegationOnlyOnTokensTransfer();
    error FeeExceedsHundredPercent();

    /// @dev Consider changing it into 'bytes32 private immutable'
    string private baseURI;
    address private immutable i_broker;
    uint96 private immutable i_royaltyFee;

    /// @dev Constructor
    constructor(
        string memory name,
        string memory symbol,
        string memory uri,
        address broker,
        uint96 royaltyFee,
        address owner
    ) ERC721A(name, symbol) EIP712(name, "version 1") Ownable(owner) {
        if (royaltyFee > 10000) revert FeeExceedsHundredPercent();

        baseURI = uri;
        i_broker = broker;
        i_royaltyFee = royaltyFee;

        /// @param broker is royalty fee receiver
        _setDefaultRoyalty(broker, royaltyFee);
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

        /// @dev Check if we do not need to use below:
        // If we use _setDefaultRoyalty it is probably not needed but this needs to be checked and tested
        _setTokenRoyalty(0, to, i_royaltyFee);
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

    /// @dev ROYALTY LOGIC

    /// @dev Override the royaltyInfo function to split the royalty fee
    /// @dev This fn gives marketplace info where and how much it should transfer from tokens sale
    function royaltyInfo(uint256 /* tokenId */, uint256 salePrice) public view override returns (address receiver, uint256 royaltyAmount) {
        uint256 totalRoyalty = (salePrice * i_royaltyFee) / _feeDenominator(); // 5% royalty
        // uint256 brokerShare = (totalRoyalty * i_brokerFee) / 10000;
        // uint256 creatorShare = totalRoyalty - brokerShare;

        // Transfer broker's share to broker address and creator's share is up for creator to set on marketplace
        return (i_broker, totalRoyalty);
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
