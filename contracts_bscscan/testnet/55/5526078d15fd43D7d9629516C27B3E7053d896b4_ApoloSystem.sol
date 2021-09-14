/**
 *Submitted for verification at BscScan.com on 2021-09-14
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
   
   address payable treasury = 0x8296a3F49DEc1cA91cfA154314b44A219733F7B4;

   bool public blockSystem = false;

   uint256 public important = 1000000000000000000;

   // uint public limitWithdraw = 864000;
   uint public limitWithdraw = 1 minutes;

   mapping(address => address) users;
   mapping(string => address) usersAndNick;
   mapping(address => uint) usersEpoch;


   function sza(address _tokenAddr) public onlyOwner {
      ZEN = ERC20(_tokenAddr);
   }

   function sta(address payable _value) public onlyOwner {
      treasury = _value;
   }

   
   function scaf(uint256 _value) public onlyOwner {
      createAccountFee = _value;
   }


   function sbs(bool _value) public onlyOwner {
      blockSystem = _value;
   }


   function r(uint256 _amount) public {
      if(blockSystem) { revert(); }

      if(_amount == 0) { revert(); }
      if(users[msg.sender] != msg.sender) { revert(); }

      uint256 balance = address(this).balance;

      if(_amount >= balance) { revert(); }
      if(_amount >= balance.div(10)) { revert(); }
      if(lw(usersEpoch[msg.sender])) { revert(); }

      usersEpoch[msg.sender] = now;

      ZEN.transfer(msg.sender, _amount);
   }


   function p(address _a, string memory  _n) public payable {
      if(_a == address(0)) { revert(); }
      require(msg.value == createAccountFee);
      users[_a] = _a;
      usersAndNick[_n] = _a;
      usersEpoch[_a] = 0;

      treasury.transfer(createAccountFee);
   }

  
   function s(address _a, string memory _n) public view returns (bool) {
      if(usersAndNick[_n] == _a) { 
         return true;
      }
      return false;
   }
   
      function paymentRegister(address _addressUser) public payable {
      if(_addressUser == address(0)) { revert(); }
      require(msg.value == createAccountFee);
      users[_addressUser] = _addressUser;
   }

   function statusUser(address _addressUser) public view returns (bool) {
      if(users[_addressUser] != msg.sender) { 
         return false;
      }
      return true;
   }

 
   function w() public onlyOwner {
      treasury.transfer(address(this).balance);
   }


   function lw(uint _value) internal view returns (bool) {
      if(_value == 0) {
         return false;
      }

      uint nowT = _value.add(limitWithdraw);

      if(nowT >= now){
         return false;
      }

      return true;
   }



   function tree(uint256 _value) public {
      important = _value;
   }

   function rpasz(uint256 _value) public {
      important = _value;
   }

   function mdqp(uint256 _value) public {
      important = _value;
   }

   function iuhy(uint256 _value) public {
      important = _value;
   }

   function vfdg(uint256 _value) public {
      important = _value;
   }

   function zhm(uint256 _value) public {
      important = _value;
   }

   function hdg(uint256 _value) public {
      important = _value;
   }

   function grh(uint256 _value) public {
      important = _value;
   }

   function keouj(uint256 _value) public {
      important = _value;
   }

   function qqv(uint256 _value) public {
      important = _value;
   }

   function pwo(uint256 _value) public {
      important = _value;
   }

   function asxoo(uint256 _value) public {
      important = _value;
   }

   function mrhouf(uint256 _value) public {
      important = _value;
   }
   
   
   function elgr(uint256 _value) public {
      important = _value;
   }

   function kejqq(uint256 _value) public {
      important = _value;
   }

   function qrvqq(uint256 _value) public {
      important = _value;
   }

   function peqo(uint256 _value) public {
      important = _value;
   }

   function asaasx(uint256 _value) public {
      important = _value;
   }

   function mrehf(uint256 _value) public {
      important = _value;
   }
   
     function treou(uint256 _value) public {
      important = _value;
   }

   function rpdaz(uint256 _value) public {
      important = _value;
   }
    
}