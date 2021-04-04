// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./Oraclize.sol";


contract ChoAsset is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor() ERC721("Cho-Asset", "CHO") {}
    
    function baseTokenURI() public pure returns (string memory) {
        return "https://gateway.ipfs.io/ipfs/";
    }
    function mint(address receiver, string memory tokenURI) external onlyOwner returns (uint256) {
        _tokenIds.increment();

        uint256 newNftTokenId = _tokenIds.current();
        _mint(receiver, newNftTokenId);
        _setTokenURI(newNftTokenId, Oraclize.concat(baseTokenURI(), tokenURI) );

        return newNftTokenId;
    }
    
    

}