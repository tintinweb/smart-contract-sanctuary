// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0 <0.7.0;

import "../prize-pool/PrizePool.sol";
import "../prize-strategy/single-random-winner/SingleRandomWinner.sol";

contract PrizePoolBuilder {
  using SafeCast for uint256;

  event PrizePoolCreated (
    address indexed creator,
    address indexed prizePool
  );

  function _setupSingleRandomWinner(
    PrizePool prizePool,
    SingleRandomWinner singleRandomWinner,
    uint256 ticketCreditRateMantissa,
    uint256 ticketCreditLimitMantissa
  ) internal {
    address ticket = address(singleRandomWinner.ticket());

    prizePool.setPrizeStrategy(singleRandomWinner);

    prizePool.addControlledToken(ticket);
    prizePool.addControlledToken(address(singleRandomWinner.sponsorship()));

    prizePool.setCreditPlanOf(
      ticket,
      ticketCreditRateMantissa.toUint128(),
      ticketCreditLimitMantissa.toUint128()
    );
  }
}