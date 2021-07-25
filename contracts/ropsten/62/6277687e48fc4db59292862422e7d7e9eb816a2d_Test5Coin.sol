// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20Pausable.sol";
import "./Ownable.sol";

contract Test5Coin is ERC20Pausable, Ownable {
  uint8 private DECIMALS = 18;
  uint256 private MAX_TOKEN_COUNT = 10000;
  uint256 private INITIAL_SUPPLY = MAX_TOKEN_COUNT * (10 ** uint256(DECIMALS));
  
  // Airdrop
  mapping (address => uint256) private airDropHistory;
  event AirDrop(address _receiver, uint256 _amount);

  // Token Lock
  mapping (address => uint256) private lockedBalances;
  uint256 private unlocktime;

  constructor()
  ERC20("Test5Coin", "T5C")
  public {
    super._mint(msg.sender, INITIAL_SUPPLY);
    unlocktime = 1627259880;    // 2021년 7월 26일 월요일 오전 9:38:00 GMT+09:00
  }

  function decimals() public view virtual override returns (uint8) {
    return DECIMALS;
  }

  modifier timeLock(address from, uint256 amount) { 
    if (block.timestamp < unlocktime) {
      require(amount <= balanceOf(from) - lockedBalances[from]);
    } else {
      lockedBalances[from] = 0;
    }
    _;
  }
  
  function unLockTime() public view virtual returns (uint256) {
    return unlocktime;
  }
  
  function setUnLockTime(uint256 _unlocktime) onlyOwner public virtual {
    unlocktime = _unlocktime;
  }

  function transfer(address recipient, uint256 amount) timeLock(msg.sender, amount) whenNotPaused public virtual override returns (bool) {
    return super.transfer(recipient, amount);
  }

  function transferToLockedBalance(address recipient, uint256 amount) whenNotPaused public virtual returns (bool) {
    if (transfer(recipient, amount)) {
      lockedBalances[recipient] += amount;
      return true;
    }
  }

  function transferFrom(address _from, address recipient, uint256 amount) timeLock(_from, amount) whenNotPaused public virtual override returns (bool) {
    return super.transferFrom(_from, recipient, amount);
  } 

  function dropToken(address[] memory receivers, uint256[] memory values) public {
    require(receivers.length != 0);
    require(receivers.length == values.length);

    for (uint256 i = 0; i < receivers.length; i++) {
      address receiver = receivers[i];
      uint256 amount = values[i];

      transfer(receiver, amount);
      airDropHistory[receiver] += amount;

      emit AirDrop(receiver, amount);
    }
  }
}