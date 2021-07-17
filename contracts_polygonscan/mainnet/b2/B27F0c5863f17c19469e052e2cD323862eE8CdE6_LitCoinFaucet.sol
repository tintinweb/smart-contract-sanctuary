//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;

import "./SafeMath.sol";
import "./IERC20.sol";

contract LitCoinFaucet {
  using SafeMath for uint256;

  IERC20 litCoin;
  address public owner;
  uint256 public allowance;
  mapping(address => uint256) public balances;

  constructor(address contractAddress, uint256 dripAmount) {
    owner = msg.sender;
    allowance = dripAmount;
    litCoin = IERC20(contractAddress);
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function available() public view returns (uint256) {
    return litCoin.balanceOf(address(this));
  }

  function received(address recipient) public view returns (uint256) {
    return balances[recipient];
  }

  function _dripTo(address recipient) internal {
    if (recipient == address(0)) return;
    if (balances[recipient] >= allowance) return;

    uint256 transferAmount = allowance - balances[recipient];
    if (available() >= transferAmount) {
      litCoin.transfer(recipient, transferAmount);
      balances[recipient] += transferAmount;
    }
  }

  function _dripToAmount(address recipient, uint256 amt) internal {
    if (recipient == address(0)) return;

    uint256 transferAmount;
    if (msg.sender == owner) {
      transferAmount = amt;
    } else {
      if (balances[recipient] >= amt) return;
      transferAmount = amt - balances[recipient];
    }
    if (available() >= transferAmount) {
      litCoin.transfer(recipient, transferAmount);
      balances[recipient] += transferAmount;
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

  function dripsToAmounts(address[] memory dests, uint256[] memory amts) external {
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