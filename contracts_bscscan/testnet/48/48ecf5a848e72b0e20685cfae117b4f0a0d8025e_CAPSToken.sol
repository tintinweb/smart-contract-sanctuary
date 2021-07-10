/**
 *Submitted for verification at BscScan.com on 2021-07-10
*/

/**
 *Submitted for verification at BscScan.com on 2021-04-29
*/

pragma solidity ^0.4.19;

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

contract ERC20 {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
//   function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
//   function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);


    
}



contract CAPSToken is  Ownable{

using SafeMath for uint256;

//token attributes

string public name = "capstone";                 //name of the token

string public symbol = "CAPS";                      // symbol of the token

uint8 public decimals = 9;       
// decimals
uint256 private decimalFactor = 10**uint256(decimals);

uint256 public totalSupply = 1* 10**9 * 10**uint256(decimals);  // total supply of STACK Tokens


///////////////////////////////////////// MODIFIERS /////////////////////////////////////////////////

// Checks whether it can transfer or otherwise throws.

  modifier nonZeroAddress(address _to) {
    require(_to != 0x0);
    _;
  }

////////////////////////////////////////// FUNCTIONS //////////////////////////////////////////////

// Returns current token Owner

  function CurrentOwner() public view returns (address) {
    return owner;
  }
  
// totolBNB calculate        
// uint internal totalBNBReceive;

//  function TotalBNBReceive() public onlyOwner returns(uint){
//      return totalBNBReceive;
//  }
 
function BNBCollection(uint val) internal {
        owner.transfer(val);
}
    
    function() payable public{
       BNBCollection(msg.value);
    }
}