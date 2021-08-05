/**
 *Submitted for verification at Etherscan.io on 2020-12-15
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.6.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


abstract contract ERC20 {
    function balanceOf(address account) external view virtual returns (uint256);
    function transfer(address recipient, uint256 amount) external virtual returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external virtual returns (bool);
}

contract Timlock is Context {
    using SafeMath for uint256;
    
    mapping (address => mapping (address => LockedInfo)) private lockedMap;
    
    struct LockedInfo {
        uint256 lockedAmount;
        uint256 lockedHours;
        uint256 startTimestamp;
    }

    // Events
    event Locked(address locker, address tokenAddress, uint256 lockAmount, uint256 lockHours);
    event Unlocked(address unlocker, address tokenAddress, uint256 unlockAmount);
    
    constructor () public {
    }
    
    function lock(address tokenAddress, uint256 lockAmount, uint256 lockHours) external returns (bool) {
        uint256 tokenBalance = ERC20(tokenAddress).balanceOf(_msgSender());
        uint256 prevLockedAmount = ERC20(tokenAddress).balanceOf(address(this));
        require( lockAmount <= tokenBalance, 'Lock: the lock amount exceeds the balance' );
        require(
                ERC20(tokenAddress).transferFrom(_msgSender(), address(this), lockAmount),
                'Lock failed'
        );
        
        uint256 currentLockedAmount = ERC20(tokenAddress).balanceOf(address(this));
        
        lockedMap[_msgSender()][tokenAddress].lockedAmount = lockedMap[_msgSender()][tokenAddress].lockedAmount.add(currentLockedAmount.sub(prevLockedAmount));
        lockedMap[_msgSender()][tokenAddress].lockedHours = lockHours;
        lockedMap[_msgSender()][tokenAddress].startTimestamp = now;
        
        emit Locked(_msgSender(), tokenAddress, lockedMap[_msgSender()][tokenAddress].lockedAmount, lockHours);
    }
    
    function unlock(address tokenAddress) external returns (bool) {
        uint256 currentTimestamp = now;
        uint256 unlockableTimestamp = lockedMap[_msgSender()][tokenAddress].startTimestamp.add(lockedMap[_msgSender()][tokenAddress].lockedHours.mul(uint256(3600)));
        require(unlockableTimestamp <= currentTimestamp, 'Unlock: you could not unlock now.');
        
        require(
            ERC20(tokenAddress).transfer(_msgSender(), lockedMap[_msgSender()][tokenAddress].lockedAmount),
            'Unlock failed'
        );
        
        lockedMap[_msgSender()][tokenAddress].lockedAmount = 0;
        lockedMap[_msgSender()][tokenAddress].startTimestamp = 0;
        emit Unlocked(_msgSender(), tokenAddress, lockedMap[_msgSender()][tokenAddress].lockedAmount);
    }
    
    function unlockableTimestamp(address tokenAddress) external view returns (uint256) {
        if(lockedMap[_msgSender()][tokenAddress].startTimestamp > 0)
            return lockedMap[_msgSender()][tokenAddress].startTimestamp.add(lockedMap[_msgSender()][tokenAddress].lockedHours.mul(uint256(3600)));
        return 0;
    }
    
    function lockedAmount(address tokenAddress) external view returns (uint256) {
        return lockedMap[_msgSender()][tokenAddress].lockedAmount;
    }
    
}