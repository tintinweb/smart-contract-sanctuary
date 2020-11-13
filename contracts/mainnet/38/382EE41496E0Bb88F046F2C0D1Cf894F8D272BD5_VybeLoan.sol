// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Vybe.sol";
import "./IVybeBorrower.sol";

contract VybeLoan is ReentrancyGuard, Ownable {
  using SafeMath for uint256;

  Vybe private _VYBE;
  uint256 internal _feeDivisor = 100;

  event Loaned(uint256 amount, uint256 profit);

  constructor(address VYBE, address vybeStake) Ownable(vybeStake) {
    _VYBE = Vybe(VYBE);
  }

  function loan(uint256 amount) external noReentrancy {
    uint256 profit = amount.div(_feeDivisor);
    uint256 owed = amount.add(profit);
    require(_VYBE.transferFrom(owner(), msg.sender, amount));

    IVybeBorrower(msg.sender).loaned(amount, owed);

    require(_VYBE.transferFrom(msg.sender, owner(), amount));
    require(_VYBE.transferFrom(msg.sender, address(this), profit));
    require(_VYBE.burn(profit));

    emit Loaned(amount, profit);
  }
}
