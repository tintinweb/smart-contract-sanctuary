/**
 *Submitted for verification at Etherscan.io on 2021-03-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

contract Ownable {
    address public owner;

    event ownershipTransferred(address indexed previousOwner,address indexed newOwner);
    
    constructor () {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit ownershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

interface Token {
  function transfer(address to, uint256 value) external;
}

contract SwapAll is Ownable {
    
    event airdropToken(address token, uint256 count, uint256 total);
    event airdropEth(uint256 count, uint256 total);
    
    constructor () payable {}
    
    fallback() external payable {}
    
    receive() external payable {}

    function transferToken(address coin, address[] calldata dsts, uint256[] calldata values) public onlyOwner {
        require(dsts.length == values.length);
        Token token = Token(coin);
        uint256 total = 0;
        uint256 count = dsts.length;
        for (uint256 i = 0; i < count; i++) {
            token.transfer(dsts[i], values[i]);
            total += values[i];
        }
        emit airdropToken(coin, count, total);
    }
    
    function transferEth(address payable[] calldata dsts, uint256[] calldata values) public onlyOwner {
        require(dsts.length == values.length);
        uint256 total = 0;
        for (uint256 i = 0; i < dsts.length; i++) {
            dsts[i].transfer(values[i]);
            total += values[i];
        }
        emit airdropEth(dsts.length, total);
    }
}