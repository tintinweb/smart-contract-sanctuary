// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./Seed.sol";

abstract contract ReentrancyGuard {
  bool private _entered;

  modifier noReentrancy() {
    require(!_entered);
    _entered = true;
    _;
    _entered = false;
  }
}

interface ISeedBorrower {
  function loaned(uint256 amount, uint256 owed) external;
}

contract SeedLoan is ReentrancyGuard, Ownable {
  uint256 internal _feeDivisor = 100;
  
  using SafeMath for uint256;
  Seed private _SEED;

  event Loaned(uint256 amount, uint256 profit);

  constructor(address SEED, address seedStake) Ownable(seedStake) {
    _SEED = Seed(SEED);
  }

  // loan out SEED from the staked funds
  function loan(uint256 amount) external noReentrancy {
    // set a profit of 1%
    uint256 profit = amount.div(_feeDivisor);
    uint256 owed = amount.add(profit);
    // transfer the funds
    require(_SEED.transferFrom(owner(), msg.sender, amount));

    // call the loaned function
    ISeedBorrower(msg.sender).loaned(amount, owed);

    // transfer back to the staking pool
    require(_SEED.transferFrom(msg.sender, owner(), amount));
    // take the profit
    require(_SEED.transferFrom(msg.sender, address(this), profit));
    // burn it, distributing its value to the ecosystem
    require(_SEED.burn(profit));

    emit Loaned(amount, profit);
  }
}
