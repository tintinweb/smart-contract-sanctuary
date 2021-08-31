/**
 *Submitted for verification at Etherscan.io on 2021-08-30
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

contract SebastianTokenAirdrop {
    ISebastianToken token;
    address sebastianTokenAddress;
    uint256 airdropAmount = 100;
    address owner;

    mapping(address => uint256) lastTransaction;

    constructor(address tokenAddress) {
        token = ISebastianToken(address(tokenAddress));
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function setAirdropAmount(uint amount) public onlyOwner {
        airdropAmount = amount;
    }

    function getAirdrop() public returns (uint256) {
        require(lastTransaction[msg.sender] < block.timestamp - 1 days, "You can take airdrop once every 5 seconds");
        token.mint(airdropAmount);
        lastTransaction[msg.sender] = block.timestamp;
        return lastTransaction[msg.sender];
    }
}

contract ISebastianToken {
    function transfer(address to, uint256 amount) public { }
    function balanceOf(address account) public view returns (uint256) { }
    function mint(uint256 amount) external { }
}