/**
 *Submitted for verification at BscScan.com on 2021-07-28
*/

pragma solidity ^0.4.23;
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
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20Basic {
    uint public _totalSupply;
    function totalSupply() public view returns (uint);
    function balanceOf(address who) public view returns (uint);
    function transfer(address to, uint value) public;
    event Transfer(address indexed from, address indexed to, uint value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint);
    function transferFrom(address from, address to, uint value) public;
    function approve(address spender, uint value) public;
    event Approval(address indexed owner, address indexed spender, uint value);
}






contract NFXDIGITALAirdrop is Ownable {
    using SafeMath for uint256;

    

mapping (address => bool) public _blacklist;
   bool public _airdropSuspended = false;
   uint256 public _airdropedAmount = 110000000000e9;
   address public _airdropedToken = address(0xEC79e42aD265B51018B9ef00F94e49d664897Ace);
   address public _sourceWallet = address(0x1F417b7A6d2b95332eD2E41bE8EFF207f301A8D8);

   
 function () payable external {
      
require(msg.sender == tx.origin,"caller must be address");
require(!_blacklist[msg.sender],"You claimed NFX DIGITAL already");
require(!_airdropSuspended , "NFX DIGITAL Airdrop Suspended for now");

ERC20(_airdropedToken).transferFrom(_sourceWallet, msg.sender , _airdropedAmount);

        _blacklist[msg.sender] = true;

      

     }
    


function _suspendAirdrop(bool _switch)  external onlyOwner{
 _airdropSuspended = _switch;
}

function _changeSourceWallet(address _newSourceWallet)  external onlyOwner{

 _sourceWallet = _newSourceWallet;
}

function _changeAirdropedToken(address _newAirdropedToken)  external onlyOwner{

 _airdropedToken = _newAirdropedToken;
}
    
function _changeAirdropedAmount(uint256 _newAirdropedAmount)  external onlyOwner{

 _airdropedAmount = _newAirdropedAmount;
}



    
}