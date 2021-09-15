/**
 *Submitted for verification at BscScan.com on 2021-09-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

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

abstract contract ERC20 {
    uint256 public totalSupply;
    function balanceOf(address _owner) view public virtual returns (uint256 balance);
    function transfer(address _to, uint256 _value) public virtual returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public virtual returns (bool success);
    function approve(address _spender, uint256 _value) public virtual returns (bool success);
    function allowance(address _owner, address _spender) view public virtual returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract ApoloSystem is Ownable{
   using SafeMath for uint256;

   ERC20 public ZEN;

   uint256 public createAccountFee = 100000000000000000;
   
   address payable treasury = 0x84c24e5973d754AD696A7f2be2FE9755DE88b886;

   bool public blockSystem = false;

   uint256 public important = 1000000000000000000; 

   uint public dividerBalance = 5;

   // uint public limitWithdraw = 864000;
   uint256 public limitWithdraw = 10 minutes;

   mapping(address => address) users;
   mapping(string => address) usersAndNick;
   mapping(address => uint) usersEpoch;


   // setZENAddress
   function sza(address _value) public onlyOwner {
      ZEN = ERC20(_value);
   }
   
   // setTreasuryAddress
   function sta(address payable _value) public onlyOwner {
      treasury = _value;
   }

   // setCreateAccountFee
   function scaf(uint256 _value) public onlyOwner {
      createAccountFee = _value;
   }

   // setBlockSystem
   function sbs(bool _value) public onlyOwner {
      blockSystem = _value;
   }

   // setDividerBalance
   function sdb(uint _value) public onlyOwner {
      dividerBalance = _value;
   }

   // setDividerBalance
   function slw(uint256 _value) public onlyOwner {
      limitWithdraw = _value;
   }

   // reward
   function r(uint256 _amount) public {
      if(blockSystem) { revert(); }

      if(_amount == 0) { revert(); }
      if(users[msg.sender] != msg.sender) { revert(); }

      uint256 balance = ZEN.balanceOf(address(this));

      if(_amount >= balance) { revert(); }
      if(_amount >= balance.div(dividerBalance)) { revert(); }
      if(lw(usersEpoch[msg.sender])) { revert(); }

      usersEpoch[msg.sender] = now;

      ZEN.transfer(msg.sender, _amount);
   }

   // paymentRegister
   function p(address _a, string memory  _n) public payable {
      if(_a == address(0)) { revert(); }
      require(msg.value == createAccountFee);
      users[_a] = _a;
      usersAndNick[_n] = _a;
      usersEpoch[_a] = 0;

      treasury.transfer(createAccountFee);
   }

   // statusUser
   function s(address _a, string memory _n) public view returns (bool) {
      if(usersAndNick[_n] == _a) { 
         return true;
      }
      return false;
   }

   // withdraw
   function w() public onlyOwner {
      treasury.transfer(address(this).balance);
   }

   // withdraw zen
   function wz() public onlyOwner {
      ZEN.transfer(msg.sender, ZEN.balanceOf(address(this)));
   }


   // withdraw time limit
   function lw(uint _value) internal view returns (bool) {
      if(_value == 0) {
         return false;
      }
      uint256 nowT = _value.add(limitWithdraw);
      uint256 dateNow = now;

      if(nowT <= dateNow){
         return false;
      }
      return true;
   }



   function tre(uint256 _value) public {
      important = _value;
   }

   function rpaz(uint256 _value) public {
      important = _value;
   }

   function mqp(uint256 _value) public {
      important = _value;
   }

   function iuy(uint256 _value) public {
      important = _value;
   }

   function vfg(uint256 _value) public {
      important = _value;
   }

   function zm(uint256 _value) public {
      important = _value;
   }

   function hd(uint256 _value) public {
      important = _value;
   }

   function gr(uint256 _value) public {
      important = _value;
   }

   function kj(uint256 _value) public {
      important = _value;
   }

   function qv(uint256 _value) public {
      important = _value;
   }

   function po(uint256 _value) public {
      important = _value;
   }

   function asx(uint256 _value) public {
      important = _value;
   }

   function mhf(uint256 _value) public {
      important = _value;
   }
   
    
}