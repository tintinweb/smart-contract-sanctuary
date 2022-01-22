/**
 *Submitted for verification at Etherscan.io on 2022-01-22
*/

pragma solidity ^0.8.0;

contract OnChainNFT {
    struct NFT {
        uint256 id;
        string image;
        uint256 timestamp;
    }

    uint nftCount;

    event NFTCreated(address indexed owner, uint256 indexed id, string image);

    mapping(address => NFT) public NFTs;

    function createNFT(string memory _image) public {
        NFTs[msg.sender] = NFT(nftCount, _image, block.timestamp);
        nftCount++;
        emit NFTCreated(msg.sender, nftCount, _image);
    }

    function getNFT() public view returns (string memory) {
        return NFTs[msg.sender].image;
    }

    function countNFTs() public view returns (uint) {
        return nftCount;
    }

}