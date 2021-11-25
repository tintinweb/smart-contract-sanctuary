/**
 *Submitted for verification at Etherscan.io on 2021-11-25
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface ERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract RegioFaucet {
    uint256 waitTime = 60;

    ERC20 tokenInstance;

    mapping(address => uint256) lastTimeWithdrawal;

    constructor(address _tokenAddress) {
        require(_tokenAddress != address(0));
        tokenInstance = ERC20(_tokenAddress);
    }

    function withdraw() public {
        require(isAllowedToWithdraw(msg.sender), "Please wait 1 min before attempting to withdraw.");
        tokenInstance.transfer(msg.sender, 100*10**18);

    }

    function isAllowedToWithdraw(address _address) public view returns (bool) {
        if(lastTimeWithdrawal[_address] == 0
            ||
            lastTimeWithdrawal[_address] >= (lastTimeWithdrawal[msg.sender] + waitTime)
        ) {
            return true;
        }

        return false;

    }
}