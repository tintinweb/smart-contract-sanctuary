// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0 <0.7.0;

import "../PeriodicPrizeStrategy.sol";

/* solium-disable security/no-block-members */
contract SingleRandomWinner is PeriodicPrizeStrategy {
  function _distribute(uint256 randomNumber) internal override {
    uint256 prize = prizePool.captureAwardBalance();
    address winner = ticket.draw(randomNumber);
    if (winner != address(0)) {
      _awardTickets(winner, prize);
      _awardAllExternalTokens(winner);
    }
  }
}
