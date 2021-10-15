// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from './Ownable.sol';
import './ERC721Business.sol';
import './ERC721Enumerable.sol';

contract FoundersEditionNFT is Context, Ownable, ERC721Business {
 
    string private _baseTokenURI;

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

    function updateMinter(address minter) onlyOwner public virtual {
        _minter = minter;
    }


}