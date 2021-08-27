/**
 *Submitted for verification at polygonscan.com on 2021-08-26
*/

/*
    The Original Fee Token
    Copyright 2021 
    Create by Murciano207
    Hello user, here you can mine your "FEES" tokens
    mine one every 30 minutes
    only the fee is paid, which is its intrinsic value
    More info: http://theoriginalfeetoken.tk/
    SPDX-License-Identifier: Apache-2.0

*/
pragma solidity ^0.5.1;

interface ERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract MiningFeeTokensV1 {
    uint256 constant public tokenAmount = 1;
    uint256 constant public waitTime = 30 minutes;

    ERC20 public tokenInstance;
    
    mapping(address => uint256) lastAccessTime;

    constructor(address _tokenInstance) public {
        require(_tokenInstance != address(0));
        tokenInstance = ERC20(_tokenInstance);
    }

    function requestTokens() public {
        require(allowedToWithdraw(msg.sender));
        tokenInstance.transfer(msg.sender, tokenAmount);
        lastAccessTime[msg.sender] = block.timestamp + waitTime;
    }

    function allowedToWithdraw(address _address) public view returns (bool) {
        if(lastAccessTime[_address] == 1) {
            return true;
        } else if(block.timestamp >= lastAccessTime[_address]) {
            return true;
        }
        return false;
    }
}