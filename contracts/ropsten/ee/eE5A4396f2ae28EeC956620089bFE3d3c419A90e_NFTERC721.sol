// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
 
import "./ERC721Pausable.sol";
import "./Counters.sol";

contract NFTERC721 is ERC721Pausable {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor(string memory tokenName, string memory tokenSymbol) ERC721(tokenName, tokenSymbol) {
        _tokenIds.reset(999); // It starts from 1000 when the first NFT is being minted
    }

    function mintNFT(address recipient, string memory tokenURI)
        public onlyOwner
        returns (uint256)
    {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();

        _safeMint(recipient, newItemId);
        _setTokenURI(newItemId, tokenURI);

        return newItemId;
    } 

    function burnNFT(uint256 tokenId) public {
        _burn(tokenId);
    }

}