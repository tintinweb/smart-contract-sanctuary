/**
 *Submitted for verification at Etherscan.io on 2021-09-05
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

contract SebastianTokenAirdrop {
    ISebastianToken private _token;
    uint256 private _airdropAmount = 100;
    address private _owner;

    mapping(address => uint256) lastTransaction;

    constructor(address tokenAddress) {
        _token = ISebastianToken(address(tokenAddress));
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }

    function setAirdropAmount(uint amount) public onlyOwner {
        _airdropAmount = amount;
    }

    function getAirdrop() public returns (bool) {
        require(lastTransaction[msg.sender] < block.timestamp - 1 days, "You can take airdrop once every 1 day");
        _token.mint(msg.sender, _airdropAmount);
        lastTransaction[msg.sender] = block.timestamp;

        return true;
    }
}

contract ISebastianToken {
    function mint(address to, uint256 amount) external { }
}