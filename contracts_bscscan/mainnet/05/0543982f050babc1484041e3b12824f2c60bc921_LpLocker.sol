/**
 *Submitted for verification at BscScan.com on 2021-07-25
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IPancakeERC20 {
    function approve(address spender, uint value) external returns (bool);
    function balanceOf(address owner) external view returns (uint);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

contract LpLocker {
    uint256 currentTimestamp;
    struct LP {
        uint256 amount;
        uint256 lockTime;
        uint256 unlockTime;
    }
    mapping(address => mapping(address => LP)) public lpBox;    // user address => pair address => LP
    uint256[] lpList;

    event LockLP(address from, address PancakePairAddress, uint256 amount, uint256 second);
    event LPWithdrawEd(address from, address PancakePairAddress, uint256 amount);
    
    function refreshCurrentTimestamp() public {
        currentTimestamp = block.timestamp;
    }

    function lockLP(uint256 lpAmount, uint256 second, address PancakePairAddress) public {
        IPancakeERC20 ipe = IPancakeERC20(PancakePairAddress);

        // ipe.approve(address(this), lpAmount);
        ipe.transferFrom(msg.sender, address(this), lpAmount);

        lpBox[msg.sender][PancakePairAddress].amount += lpAmount;
        lpBox[msg.sender][PancakePairAddress].lockTime = block.timestamp;
        lpBox[msg.sender][PancakePairAddress].unlockTime = block.timestamp + second;

        emit LockLP(msg.sender, PancakePairAddress, lpAmount, second);
    }

    function withdrawLP(address PancakePairAddress) public {
        LP memory lp = lpBox[msg.sender][PancakePairAddress];
        require(block.timestamp > lp.unlockTime, "time not finished");

        IPancakeERC20 ipe = IPancakeERC20(PancakePairAddress);
        ipe.transfer(msg.sender, lp.amount);

        emit LPWithdrawEd(msg.sender, PancakePairAddress, lp.amount);
    }

    function getLPDuration(address walletAddress, address PancakePairAddress) public view returns(uint256) {
        uint256 unlockTime = lpBox[walletAddress][PancakePairAddress].unlockTime;
        return (unlockTime <= block.timestamp) ? 0 : unlockTime - block.timestamp;
    }
}