/**
 *Submitted for verification at Etherscan.io on 2021-05-04
*/

pragma solidity ^0.5.7;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}




contract GsnPs {
    using SafeMath for uint;
    address   owner;    // This is the current owner of the contract.
    mapping (address => uint) internal balance;
    
    // Events begin.
    event PsExcute(address from, uint amount);
    event GdpSentFromAccount(address from, address to, uint amount);
    event GdpSentFromContract(address from, address to, uint amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    // Events end.

  uint public target=0;
  uint public blockheight=0;
  uint public fulfillmentrate=100;
  constructor () public {  // the contract's constructor function.
        owner = msg.sender;
    }



// Function to get Balance of the contract.
  function getBalance() public view returns (uint256) {
        
        require(msg.sender == owner); // Only the Owner of this contract can run this function.
        return address(this).balance;
    }

// Function to accept payment and data into the contract.
    function acceptPs() payable public {
        require(fulfillmentrate >=90,"fulfillment rate less than 90% , stop ps");
        balance[address(this)]+= msg.value;  
        emit PsExcute(msg.sender, msg.value);
    }

// Function to withdraw or send Ether from Contract owner's account to a specified account.
    function TransferToGsContractFromOwnerAccount(address payable receiver, uint amount) public {
        require(msg.sender == owner, "You're not owner of the account"); // Only the Owner of this contract can run this function.
        require(amount < address(this).balance, "Insufficient balance.");
        receiver.transfer(amount);
        emit GdpSentFromAccount(msg.sender, receiver, amount);
    }
    
    function transferOwnership(address newOwner) public {
     require(msg.sender == owner, "You're not owner of the contract"); 
     require(newOwner != address(0));
     owner = newOwner;
     emit OwnershipTransferred(owner, newOwner);
   
    }
  
// function to set GSN network's blockheight
   function SetGsnBlockHeight(uint newTarget, uint newBlockheight) public {
        require(msg.sender == owner, "You're not owner of the account");
        blockheight=newBlockheight;
        target=newTarget;
        
   }
   
// Function to get current blockheight of the gsn network.
  function getGsnBlockheight() public view returns (uint256) {
        return blockheight;
    }

// Function to get current block target of the gsn network.
  function getGsnTarget() public view returns (uint256) {
        return target;
    }    

// Function to reset fulfillment rate if it is less than 90%
  function resetFulfillmentRate(uint rate) public{
       require(rate>0,"invalid rate");
       require(rate<=100,"invalid rate");
       fulfillmentrate=rate;
  }
  
  function() external payable {
     emit PsExcute(msg.sender, msg.value);
    // Fallback function.
    }
    
 

    
}