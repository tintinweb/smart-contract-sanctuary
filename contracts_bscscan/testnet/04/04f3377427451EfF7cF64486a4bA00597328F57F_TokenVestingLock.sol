/**
 *Submitted for verification at BscScan.com on 2021-11-20
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
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

interface Token {
    function balanceOf(address) external returns (uint);
    function transferFrom(address, address, uint) external returns (bool);
    function transfer(address, uint) external returns (bool);
}

interface LegacyToken {
    function transfer(address, uint) external;
}

contract TokenVestingLock is Ownable {
    using SafeMath for uint;
    
    // ========== CONTRACT VARIABLES ===============
    
    // enter token contract address here
    address public constant tokenAddress = address(0);
    
    // enter token locked amount here
    uint public constant tokensLocked = 1000e18;
    
    // enter unlock duration here
    uint public constant lockDuration = 300 days;
    
    // DON'T Change This - unlock 100% Tokens over lockDuration
    uint public constant unlockRate = 100e2;
    
    // ======== END CONTRACT VARIABLES ===============
    
    uint public lastClaimedTime;
    uint public deployTime;

    constructor() public {
        deployTime = now;
        lastClaimedTime = now;
    }
    
    function claim() external onlyOwner {
        uint pendingUnlocked = getPendingUnlocked();
        uint contractBalance = Token(tokenAddress).balanceOf(address(this));
        uint amountToSend = pendingUnlocked;
        if (contractBalance < pendingUnlocked) {
            amountToSend = contractBalance;
        }
        require(Token(tokenAddress).transfer(owner, amountToSend), "Could not transfer Tokens.");
        lastClaimedTime = now;
    }
    
    function getPendingUnlocked() public view returns (uint) {
        uint timeDiff = now.sub(lastClaimedTime);
        uint pendingUnlocked = tokensLocked
                                    .mul(unlockRate)
                                    .mul(timeDiff)
                                    .div(lockDuration)
                                    .div(100e2);
        return pendingUnlocked;
    }
    
    // function to allow admin to claim *other* ERC20 tokens sent to this contract (by mistake)
    function transferAnyERC20Tokens(address tokenContractAddress, address tokenRecipient, uint amount) external onlyOwner {
        require(tokenContractAddress != tokenAddress || now > deployTime.add(lockDuration), "Cannot transfer out locked tokens yet!");
        require(Token(tokenContractAddress).transfer(tokenRecipient, amount), "Transfer failed!");
    }
    
    // function to allow admin to claim *other* ERC20 tokens sent to this contract (by mistake)
    function transferAnyLegacyERC20Tokens(address tokenContractAddress, address tokenRecipient, uint amount) external onlyOwner {
        require(tokenContractAddress != tokenAddress || now > deployTime.add(lockDuration), "Cannot transfer out locked tokens yet!");
        LegacyToken(tokenContractAddress).transfer(tokenRecipient, amount);
    }
}