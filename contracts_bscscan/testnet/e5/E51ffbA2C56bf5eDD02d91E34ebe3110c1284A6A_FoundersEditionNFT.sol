// SPDX-License-Identifier: Unlicensed (Closed Source)
pragma solidity >=0.4.22 <0.9.0;

import {Ownable} from './Ownable.sol';
import './ERC721.sol';
import './Counters.sol';
import "./SharedStructs.sol";


/// @dev {ERC20} NFT, including:
///
/// - ability for holders to burn (destroy) their tokens.
/// - a minter role that allows for token minting (creation)
/// - a pauser role that allows to stop all token transfers
///
/// This contract uses {AccessControl} to lock permissioned functions using the
/// different roles - head to its documentation for details.
///
/// The account that deploys the contract will be granted the minter and pauser
/// roles, as well as the default admin role, which will let it grant both 
/// minter and pauser roles to other accounts.
   
contract FoundersEditionNFT is Context, Ownable, ERC721 {

    Counters.Counter private _tokenIdTracker;

    string private _baseTokenURI;

    // past owners
    // current owner
    // only owner can see this information

    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI
    ) ERC721(name, symbol) {
        _baseTokenURI = baseTokenURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function mint(
        address to,
        string memory encryptedData,
        string memory orderReference
    ) onlyOwner public virtual {
        // We cannot just use balanceOf to create the new tokenId because tokens
        // can be burned (destroyed), so we need a separate counter.
        SharedStructs.shareholder memory shareholder = SharedStructs.shareholder(
            to,
            encryptedData,
            orderReference);
        _mint(shareholder, Counters.current(_tokenIdTracker));
        Counters.increment(_tokenIdTracker);
    }
}