/**
 *Submitted for verification at Etherscan.io on 2021-05-24
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IERC20 {
  function initialize() external;
  function totalSupply() external view returns (uint);
  function balanceOf(address account) external view returns (uint);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint);
  function symbol() external view returns (string memory);
  function decimals() external view returns (uint);
  function approve(address spender, uint amount) external returns (bool);
  function mint(address account, uint amount) external;
  function burn(address account, uint amount) external;
  function transferFrom(address sender, address recipient, uint amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

contract Ownable {

  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() {
    owner = msg.sender;
    emit OwnershipTransferred(address(0), owner);
  }

  modifier onlyOwner() {
    require(isOwner(), "Ownable: caller is not the owner");
    _;
  }

  function isOwner() public view returns (bool) {
    return msg.sender == owner;
  }

  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(owner, address(0));
    owner = address(0);
  }

  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

contract Vesting is Ownable {

  IERC20 public asset;

  uint public startBlock;
  uint public durationBlocks;
  uint public released;

  constructor(
    IERC20 _asset,
    uint _startBlock,
    uint _durationBlocks
  ) {

    require(_asset != IERC20(address(0)), "Vesting: _asset is zero address");
    require(_startBlock + _durationBlocks > block.number, "Vesting: final block is before current block");
    require(_durationBlocks > 0, "Vesting: _duration == 0");

    asset = _asset;
    startBlock = _startBlock;
    durationBlocks = _durationBlocks;
  }

  function release(uint _amount) public onlyOwner {

    require(block.number > startBlock, "Vesting: not started yet");
    uint unreleased = releasableAmount();

    require(unreleased > 0, "Vesting: no assets are due");
    require(unreleased >= _amount, "Vesting: _amount too high");

    released += _amount;
    asset.transfer(owner, _amount);
  }

  function releasableAmount() public view returns (uint) {
    return vestedAmount() - released;
  }

  function vestedAmount() public view returns (uint) {
    uint currentBalance = asset.balanceOf(address(this));
    uint totalBalance = currentBalance + released;

    if (block.number >= startBlock + durationBlocks) {
      return totalBalance;
    } else {
      return totalBalance * (block.number - startBlock) / durationBlocks;
    }
  }
}