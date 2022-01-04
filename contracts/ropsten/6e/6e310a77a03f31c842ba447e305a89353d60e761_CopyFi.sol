/**
 *Submitted for verification at Etherscan.io on 2022-01-03
*/

pragma solidity 0.6.0;

interface IERC20 {

  function totalSupply() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract CopyFi {

  IERC20 public token;
  mapping(address => uint256) deposits;

  using SafeMath for uint256;

  constructor(address simpleUSDCAddress) public {
    token = IERC20(simpleUSDCAddress);
  }

  function depositOf(address user) external view returns (uint256) {
    return deposits[user];
  }

  function deposit(uint256 amount) external returns (bool) {
    require(amount > 0);

    uint256 allowance = token.allowance(msg.sender, address(this));
    require(allowance >= amount);

    require(token.balanceOf(msg.sender) >= amount);

    token.transferFrom(msg.sender, address(this), amount);

    deposits[msg.sender] = deposits[msg.sender].add(amount);
    return true;
  }

  function withdrawn(uint256 amount) external returns (bool) {
    require(deposits[msg.sender] >= amount);
    token.transfer(msg.sender, amount);
    deposits[msg.sender] = deposits[msg.sender].sub(amount);
    return true;
  }
}

library SafeMath {
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