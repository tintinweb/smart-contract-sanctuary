// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;

import "./ERC721.sol";
import "./DSAuth.sol";
import "./Counters.sol";

contract ImgToken is ERC721, DSAuth {

    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.UintSet;
    using SafeMath for uint256;

    mapping (uint256 => string) public tokenURIByTokenId;

    mapping (string => uint256) public tokenIdByTokenURI;

    Counters.Counter private _tokenIds;

    event mintedToken(uint256 id, string tokenURI, address to);

    constructor () ERC721("ImgToken", "IT") public {
        _setBaseURI('https://as1.ftcdn.net/jpg/02/');
    }

    function setBaseURI(string memory baseURI_) public auth {
      _setBaseURI(baseURI_);
    }

    function mintUniqueTokenTo(
        address to,
        string memory tokenURI
    ) auth public returns (uint256) {
        uint256 _tokenId = tokenIdByTokenURI[tokenURI];
        require(!(_tokenId > 0), "this token already exists!");

        // mint token
        _tokenIds.increment();
        uint256 id = _tokenIds.current();
        tokenIdByTokenURI[tokenURI] = id;
        tokenURIByTokenId[id] = tokenURI;

        _mint(to, id);
        _setTokenURI(id, tokenURI);

        emit mintedToken(id, tokenURI, to);

        return id;
    }
}