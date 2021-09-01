/**
 *Submitted for verification at Etherscan.io on 2021-09-01
*/

// SPDX-License-Identifier: 0BSD

pragma solidity ^0.8.7;

interface ERC20 {
    function transfer(address to, uint tokens) external;
    function transferFrom(address from, address to, uint tokens) external;
}

contract UnicryptIsBad { // THIS ONLY WORKS FOR NON-REBASING TOKENS!

    mapping(uint => address) public idToOwner;
    mapping(uint => address) public idToTokenAddress;
    mapping(uint => uint) public idToAmount;
    mapping(uint => uint) public idToUnlockDate;
    uint public currentId;

    function lockERC20Token(address tokenAddress, uint amount, uint unlockDate) public {
        require(amount > 0, "amount must be greater than 0");
        idToOwner[currentId] = msg.sender;
        idToTokenAddress[currentId] = tokenAddress;
        idToAmount[currentId] = amount;
        idToUnlockDate[currentId] = unlockDate;
        emit TokenLocked(tokenAddress, msg.sender, amount, unlockDate, currentId);
        ERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);
        currentId++;
    }

    function unlockERC20Token(uint id) public {
        require(block.timestamp >= idToUnlockDate[id], "not yet unlockable");
        require(idToAmount[currentId] != 0, "already unlocked");
        idToAmount[currentId] = 0;
        ERC20(idToTokenAddress[id]).transfer(idToOwner[id], idToAmount[id]);
    }

    event TokenLocked(address indexed tokenAddress, address indexed locker, uint amount, uint unlockDate, uint id);

}