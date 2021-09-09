// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./ownable.sol";
import "./nf-token-metadata.sol";

contract FluidensityNft is Ownable, NFTokenMetadata {
    uint maxNumberOfToken = 0;
    uint tokenId = 1;

    mapping(uint => uint) tokenPrices;

    event minted(address indexed _minter, uint indexed tokenId, string indexed tokenUri);
    event tokenTransfered(address indexed _from, address indexed _to, string indexed _nftName, uint _tokenId);
    event tokenPriceChanged(uint indexed _tokenId, uint indexed _tokenPrice);

    constructor(string memory _nftName, string memory _nftSymbol, uint _maxNumberOfToken){
        nftName = _nftName;
        nftSymbol = _nftSymbol;
        maxNumberOfToken = _maxNumberOfToken;
    }

    function miniting(address _minter, string memory _tokenUri) public returns (uint _tokenId) {
        //check for max tokens
        require(tokenId <= maxNumberOfToken,"Maximum number of tokens have been minted.");
        super._mint(_minter, tokenId);
        super._setTokenUri(tokenId,_tokenUri);
        tokenId +=1;
        emit minted(_minter,tokenId,_tokenUri);
        return tokenId;
    }

    function setTokenPrice(uint _tokenId, uint _tokenPrice) public {
        tokenPrices[_tokenId] = _tokenPrice;
        emit tokenPriceChanged(_tokenId, _tokenPrice);

    }

}