/**
 *Submitted for verification at BscScan.com on 2021-12-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

// import "./@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "./@openzeppelin/contracts/utils/Context.sol";
// import "./@openzeppelin/contracts/math/SafeMath.sol";
// import "./@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
// import "./@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
// import "./@openzeppelin/contracts/access/Ownable.sol";
// import "./@openzeppelin/contracts/security/Pausable.sol";


contract KCoin  {

  string public _name;
  string public _symbol;
  uint8 public _decimals;
  uint256 private _totalSupply;
  mapping (address => uint) public _balance; // key-value 
  mapping (address => mapping(address => uint)) public allowance;
  constructor() public {
    _name = "Kiet Token";
    _symbol = "K2TC";
    _decimals = 18;
    _totalSupply = 30000 * 10**18;
     _balance[msg.sender] = _totalSupply;
  }
  event Transfer (address indexed from, address indexed to, uint value);
  event Approve (address indexed spender, address indexed owner, uint value);
 
  // check checking account balance 
  function balanceOf (address owner) public view returns(uint){
      return _balance[owner];
  }
  // tranfer
  function transfer(address to, uint value) public returns(bool){
    require(balanceOf(msg.sender) >= value,'ERROR: insufficient funds');// kiểm tra số tiền trong ví có đủ để chuyển ko
    _balance[to] += value;
    _balance[msg.sender] -= value;
    emit Transfer(msg.sender, to, value);
    return true;
  }
  //delegate transfer
  function transferFrom(address from, address to, uint value) public returns(bool){
    require(balanceOf(msg.sender)>= value, 'ERROR: insufficient funds');
    require(allowance[from][msg.sender] >= value, 'ERROR: insufficient funds');
    _balance[to]+= value;
    _balance[from]-= value;
    emit Transfer(from, to, value);
    return true;
  }
  // approve for delegate transfer
  function approve(address spender, uint value) public returns (bool){
    allowance[msg.sender][spender]= value;
    emit Approve(msg.sender, spender, value);
    return true;
      
  }
}