// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface DRToken {
    function mintTo(address _to, uint256 collection) external; 
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function transferFrom(address sender, address to, uint256 id) external; 
    function balanceOf(address owner) external returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external returns (uint256);
}

contract GiveawayMinter {

    uint256          public mintedTokenId = 0;
    address          public Registry;
    DRToken          public nft;
    uint8            internal NextCollectionId = 0;
    
    constructor(address _gr, address _nft) {
        Registry = _gr;
        nft = DRToken(_nft);
    }

    function getNextCollectionId() internal returns (uint8) {
        if(NextCollectionId == 8) {
            NextCollectionId = 0;
        }
        return NextCollectionId++;
    }

    function fulfill(address _receiver) public returns (uint256) {
        require(msg.sender == Registry, "GiveawayMinter: not authorized!");
        // mint a new token to receiver address
        nft.mintTo(_receiver, getNextCollectionId());
        return ++mintedTokenId;
    }

}