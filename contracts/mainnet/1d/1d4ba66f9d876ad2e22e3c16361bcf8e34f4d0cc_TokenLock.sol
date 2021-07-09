/**
 *Submitted for verification at Etherscan.io on 2021-07-08
*/

pragma solidity 0.6.11;
// SPDX-License-Identifier: BSD-3-Clause

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;
    address public pendingOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }
    
    /**
   * @dev Throws if called by any account other than the owner.
   */
    modifier onlyPendingOwner() {
        assert(msg.sender != address(0));
        require(msg.sender == pendingOwner);
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param _newOwner The address to transfer ownership to.
    */
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        pendingOwner = _newOwner;
    }
  
    /**
    * @dev Allows the pendingOwner address to finalize the transfer.
    */
    function claimOwnership() onlyPendingOwner public {
        _transferOwnership(pendingOwner);
        pendingOwner = address(0);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface Token {
    function transfer(address, uint) external returns (bool);
}

interface LegacyToken {
    function transfer(address, uint) external;
}

contract TokenLock is Ownable {
    using SafeMath for uint;
    
    // unix unlock
    uint public unlockTime;
    // max extension allowed - prevents owner from extending indefinitely by mistake
    uint public constant MAX_EXTENSION_ALLOWED = 30 days;
    
    constructor(uint initialUnlockTime) public {
        require(initialUnlockTime > now, "Cannot set an unlock time in past!");
        unlockTime = initialUnlockTime;
    }
    
    function isUnlocked() public view returns (bool) {
        return now > unlockTime;
    }
    
    function extendLock(uint extendedUnlockTimestamp) external onlyOwner {
        require(extendedUnlockTimestamp > now && extendedUnlockTimestamp > unlockTime , "Cannot set an unlock time in past!");
        require(extendedUnlockTimestamp.sub(now) <= MAX_EXTENSION_ALLOWED, "Cannot extend beyond MAX_EXTENSION_ALLOWED period!");
        unlockTime = extendedUnlockTimestamp;
    }
    
    function claim(address tokenAddress, address recipient, uint amount) external onlyOwner {
        require(isUnlocked(), "Not Unlocked Yet!");
        require(Token(tokenAddress).transfer(recipient, amount), "Transfer Failed!");
    }

    function claimLegacyToken(address tokenAddress, address recipient, uint amount) external onlyOwner {
        require(isUnlocked(), "Not Unlocked Yet!");
        LegacyToken(tokenAddress).transfer(recipient, amount);
    }
}