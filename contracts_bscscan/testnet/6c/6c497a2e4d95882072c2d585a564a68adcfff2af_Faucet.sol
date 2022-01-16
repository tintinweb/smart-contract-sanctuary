/**
 *Submitted for verification at BscScan.com on 2022-01-15
*/

//SPDX-License-Identifier: MIT

/** 
 * Disclaimer: This contract is eithers based off 
 *  or inspired by Open Zeppelin https://github.com/OpenZeppelin/
 *  Find out more about this and other contracts
 *  at https://medium.zanno.se/
 */

pragma solidity ^0.7.0;

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Faucet {
  using SafeMath for uint256;

  IERC20 ZannoMoney;
  address public owner;
  uint256 public allowance;
  mapping(address => uint256) public balances;

  constructor(address contractAddress, uint256 dripAmount) {
    owner = msg.sender;
    allowance = dripAmount;
    ZannoMoney = IERC20(contractAddress);
  }

  function name() public view virtual returns (string memory) {
    return "ZannoMoney Faucet";
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function available() public view returns (uint256) {
    return ZannoMoney.balanceOf(address(this));
  }

  function received(address recipient) public view returns (uint256) {
    return balances[recipient];
  }

  function _dripTo(address recipient) internal {
    if (recipient == address(0)) return;
    if (balances[recipient] >= allowance) return;

    uint256 transferAmount = allowance - balances[recipient];
    if (available() >= transferAmount) {
      ZannoMoney.transfer(recipient, transferAmount);
      balances[recipient] += transferAmount;
    }
  }

  function _dripToAmount(address recipient, uint256 amt) internal {
    if (recipient == address(0)) return;

    if (available() >= amt) {
      ZannoMoney.transfer(recipient, amt);
      balances[recipient] += amt;
    }
  }

  function drip() external {
    _dripTo(msg.sender);
  }

  function dripsTo(address[] memory dests) external {
    uint256 i = 0;
    while (i < dests.length) {
      _dripTo(dests[i]);
      i++;
    }
  }

  function dripsToAmounts(address[] memory dests, uint256[] memory amts) external onlyOwner {
    uint256 i = 0;
    require(dests.length == amts.length, "Invalid amounts.");

    while (i < dests.length) {
      _dripToAmount(dests[i], amts[i]);
      i++;
    }
  }

  function updateAllowance(uint256 newAmount) public onlyOwner {
    require(newAmount > 0);
    allowance = newAmount;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
  }
}