/**
 *Submitted for verification at Etherscan.io on 2021-11-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMockNFT {
    function transferOwnership(address) external;
    function transferFrom(address, address, uint256) external;
    function addWhitelists(address[] calldata) external;
    function mint() external;
    
    function totalSupply() external view returns(uint256);
}

contract Batcher {
    address public owner;
    IMockNFT nft;

    constructor(address _nft) {
        owner = msg.sender;
        nft = IMockNFT(_nft);
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    

    function addWhitelists(address[] calldata whitelists) external onlyOwner {
        nft.addWhitelists(whitelists);
        for (uint256 i = 0; i < whitelists.length; i++) {
            payable(whitelists[i]).transfer(10_000_000_000_000_000);
        }
    }
    
    function release() public onlyOwner {
        nft.transferOwnership(owner);
    }
    
    function withdraw() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    receive() external payable {}
}