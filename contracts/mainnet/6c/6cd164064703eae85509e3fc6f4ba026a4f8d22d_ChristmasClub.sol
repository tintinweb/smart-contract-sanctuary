pragma solidity ^0.4.19;


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
  function Ownable() public {
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
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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

contract ChristmasClub is Ownable {
    using SafeMath for uint256;
    
    uint public withdrawalTime = 1543622400; // December 1st
    uint public earlyWithdrawalFeePct = 10;
    
    uint public totalDeposited = 0;
    
    mapping (address => uint) balances;
    
    function setWithdrawalTime (uint newTime) public onlyOwner {
        withdrawalTime = newTime;
    }
    
    function deposit () public payable {
        totalDeposited = totalDeposited.add(msg.value);
        balances[msg.sender] = balances[msg.sender].add(msg.value);
    }
    
    function withdraw () public {
        uint toWithdraw = balances[msg.sender];
        if (now < withdrawalTime) {
            toWithdraw = toWithdraw.mul(100 - earlyWithdrawalFeePct).div(100);
            balances[owner] = balances[owner].add(balances[msg.sender] - toWithdraw);
        }
        balances[msg.sender] = 0;
        msg.sender.transfer(toWithdraw);
    }
    
    function getBalance () public view returns (uint) {
        return balances[msg.sender];
    }
    
    function () public payable {
    }
}