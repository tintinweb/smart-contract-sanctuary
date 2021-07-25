// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20Pausable.sol";
import "./Ownable.sol";
import "./TokenTimelock.sol";

contract Test1Coin is ERC20Pausable, Ownable {
  uint8 private DECIMALS = 18;
  uint256 private MAX_TOKEN_COUNT = 10000;
  uint256 private INITIAL_SUPPLY = MAX_TOKEN_COUNT * (10 ** uint256(DECIMALS));
  
  // Lock
  mapping (address => address) public lockStatus;
  event Lock(address _receiver, uint256 _amount);

  // Airdrop
  mapping (address => uint256) public airDropHistory;
  event AirDrop(address _receiver, uint256 _amount);

  constructor()
  ERC20("Test1Coin", "T1C")
  public {
    super._mint(msg.sender, INITIAL_SUPPLY);
  }

  function decimals() public view virtual override returns (uint8) {
    return DECIMALS;
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

  function lockToken(address beneficiary, uint256 amount, uint256 releaseTime, bool isOwnable) onlyOwner public {
    TokenTimelock lockContract = new TokenTimelock(this, beneficiary, releaseTime, msg.sender, isOwnable);

    transfer(address(lockContract), amount);
    lockStatus[beneficiary] = address(lockContract);
    emit Lock(beneficiary, amount);
  }
}