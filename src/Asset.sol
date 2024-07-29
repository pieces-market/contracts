// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

import {ERC721A} from "@ERC721A/contracts/ERC721A.sol";
import {ERC721AQueryable} from "@ERC721A/contracts/extensions/ERC721AQueryable.sol";
import "./extensions/ERC721AVotes.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {IVotes} from "@openzeppelin/contracts/governance/utils/IVotes.sol";

/// @dev ERC721A version of Asset (NFT) contract with cheap multiple minting function
contract Asset is ERC721A, ERC721AQueryable, EIP712, ERC721AVotes, Ownable {
    /// @dev Consider changing it into 'bytes32 private immutable'
    string private baseURI;

    // We are getting 'name' and 'symbol' from Auctioner.sol -> Owner of this contract is Auctioner.sol
    constructor(string memory name, string memory symbol, string memory uri, address owner) ERC721A(name, symbol) EIP712(name, "version 1") Ownable(owner) {
        baseURI = uri;
    }

    /// @dev Override tokenURI to keep 1 URI for all tokens?
    // This will lead to Metadata, which will be unique for each token
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /// @notice Multi-mint function to mint multiple tokens to a single user
    function safeBatchMint(address to, uint256 quantity) external onlyOwner {
        _safeMint(to, quantity);
        _delegate(to, to);
    }

    /// @dev Very expensive function
    function burnBatch(address owner) external onlyOwner {
        uint256[] memory tokenIds = this.tokensOfOwner(owner);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            // _transferVotingUnits(from, to, batchSize); -> to (address(0))
            _burn(tokenIds[i]);
        }
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable virtual override(ERC721A, IERC721A) {
        super.safeTransferFrom(from, to, tokenId);
        _delegate(to, to);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public payable virtual override(ERC721A, IERC721A) {
        super.safeTransferFrom(from, to, tokenId, _data);
        _delegate(to, to);
    }

    /// @dev The following functions are overrides required by Solidity

    function _afterTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal virtual override(ERC721A, ERC721AVotes) {
        super._afterTokenTransfers(from, to, startTokenId, quantity);
    }

    /// @dev Check if we indeed need this -> if ERC721AQueryable included override(ERC721A, IERC721A)
    ///
    /// @dev ERC721a Governance Token Interface Support
    /// @dev Implements the interface support check for ERC721a Governance Token
    /// @notice Checks if the contract implements an interface you query for, including ERC721A and Votes interfaces
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @return True if the contract implements `interfaceId` or if `interfaceId` is the ERC-165 interface
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, IERC721A) returns (bool) {
        return interfaceId == type(IVotes).interfaceId || super.supportsInterface(interfaceId);
    }

    ////////////////////////////////////
    /// @dev VOTING MODULE OVERRIDE'S //
    ////////////////////////////////////

    /// @dev Override Vote functions
    function clock() public view override returns (uint48) {
        return Time.timestamp();
    }

    /// @dev Override Vote functions
    function CLOCK_MODE() public view override returns (string memory) {
        // Check that the clock was not modified
        if (clock() != Time.timestamp()) {
            revert ERC6372InconsistentClock();
        }
        return "mode=timestamp&from=default";
    }
}
