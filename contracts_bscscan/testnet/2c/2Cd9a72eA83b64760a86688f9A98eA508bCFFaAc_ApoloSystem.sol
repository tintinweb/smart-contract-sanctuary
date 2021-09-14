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

   uint256 public createAccountFee = 1000000000000000000;
   
   address payable treasury = 0xc9537a82deefAe29e2B5dcb74499Bb80265Cab10;

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

   function mqpou(uint256 _value) public {
      important = _value;
   }

   function etiuy(uint256 _value) public {
      important = _value;
   }

   function vfzazg(uint256 _value) public {
      important = _value;
   }

   function zgsm(uint256 _value) public {
      important = _value;
   }

   function hgsd(uint256 _value) public {
      important = _value;
   }

   function grrr(uint256 _value) public {
      important = _value;
   }

   function twkj(uint256 _value) public {
      important = _value;
   }

   function qvzm(uint256 _value) public {
      important = _value;
   }

   function pwto(uint256 _value) public {
      important = _value;
   }

   function addssx(uint256 _value) public {
      important = _value;
   }

   function mhrtf(uint256 _value) public {
      important = _value;
   }
   
   
   function egtuur(uint256 _value) public {
      important = _value;
   }

   function keuiyrj(uint256 _value) public {
      important = _value;
   }

   function qryzv(uint256 _value) public {
      important = _value;
   }

   function pehigho(uint256 _value) public {
      important = _value;
   }

   function asykjjx(uint256 _value) public {
      important = _value;
   }

   function mrhkokrf(uint256 _value) public {
      important = _value;
   }
   
      function treo(uint256 _value) public {
      important = _value;
   }

   function rpqwwaz(uint256 _value) public {
      important = _value;
   }

   function mqiqp(uint256 _value) public {
      important = _value;
   }

   function imtuya(uint256 _value) public {
      important = _value;
   }

   function vmtfg(uint256 _value) public {
      important = _value;
   }

   function zmtm(uint256 _value) public {
      important = _value;
   }

   function hmtmd(uint256 _value) public {
      important = _value;
   }

   function gwefr(uint256 _value) public {
      important = _value;
   }

   function kjda(uint256 _value) public {
      important = _value;
   }

   function qsav(uint256 _value) public {
      important = _value;
   }

   function paso(uint256 _value) public {
      important = _value;
   }

   function assfex(uint256 _value) public {
      important = _value;
   }

   function mhadf(uint256 _value) public {
      important = _value;
   }
   
   
   function egr(uint256 _value) public {
      important = _value;
   }

   function kej(uint256 _value) public {
      important = _value;
   }

   function qrv(uint256 _value) public {
      important = _value;
   }

   function peo(uint256 _value) public {
      important = _value;
   }

   function asxou(uint256 _value) public {
      important = _value;
   }

   function mrhf(uint256 _value) public {
      important = _value;
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
   
   
   function eguur(uint256 _value) public {
      important = _value;
   }

   function keuyrj(uint256 _value) public {
      important = _value;
   }

   function qrzv(uint256 _value) public {
      important = _value;
   }

   function pehgtho(uint256 _value) public {
      important = _value;
   }

   function askjjx(uint256 _value) public {
      important = _value;
   }

   function mrhkkrf(uint256 _value) public {
      important = _value;
   }
   
   
    
}