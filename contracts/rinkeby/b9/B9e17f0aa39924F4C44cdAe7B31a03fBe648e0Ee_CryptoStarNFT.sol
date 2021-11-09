/*
MIT License

Copyright (c) 2021 Joshua Iván Mendieta Zurita

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

// SPDX-License-Identifier: MIT License
pragma solidity ^0.8.9;

import "./Address.sol";
import "./Counters.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";

contract CryptoStarNFT is ERC721URIStorage, ERC721Enumerable {
      using Address for address;
      using Counters for uint256;

      uint256 constant TOKEN_MINT_FEE = 1 ether;

      Counters.Counter private _tokenId;

      constructor() ERC721("Crypto Star NFT", "CSN") {    
      }

      function _baseURI() internal view virtual override returns (string memory) {
            return "https://ipfs.io/ipfs/";
      }

      modifier requireAccount() {
            require(Address.isContract(msg.sender) == false, "Only externally-owned accounts can mint tokens");
            _;
      }

      modifier requireTokenMintFee() {
            require(msg.value == TOKEN_MINT_FEE, "The cost for minting a token is 1 ether");
            _;
      }

      function mint(string memory _tokenURI) external payable
      requireAccount
      requireTokenMintFee {
            Counters.increment(_tokenId);
            _safeMint(msg.sender, Counters.current(_tokenId));
            _setTokenURI(Counters.current(_tokenId), _tokenURI);
      }

      function _beforeTokenTransfer(
            address from,
            address to,
            uint256 tokenId
      ) internal virtual override(ERC721, ERC721Enumerable) {
            if (from == address(0)) {
                  _addTokenToAllTokensEnumeration(tokenId);
            } else if (from != to) {
                  _removeTokenFromOwnerEnumeration(from, tokenId);
            }
            if (to == address(0)) {
                  _removeTokenFromAllTokensEnumeration(tokenId);
            } else if (to != from) {
                  _addTokenToOwnerEnumeration(to, tokenId);
            }
      }

      function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721URIStorage) {
            super._burn(tokenId);

            if (bytes(_tokenURIs[tokenId]).length != 0) {
                  delete _tokenURIs[tokenId];
            }
      }

      function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
            return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
      }

      function tokenURI(uint256 tokenId) public view virtual override(ERC721, ERC721URIStorage) returns (string memory) {
            require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

            string memory _tokenURI = _tokenURIs[tokenId];
            string memory base = _baseURI();

            // If there is no base URI, return the token URI.
            if (bytes(base).length == 0) {
                  return _tokenURI;
            }
            // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
            if (bytes(_tokenURI).length > 0) {
                  return string(abi.encodePacked(base, _tokenURI));
            }

            return super.tokenURI(tokenId);
      }
}