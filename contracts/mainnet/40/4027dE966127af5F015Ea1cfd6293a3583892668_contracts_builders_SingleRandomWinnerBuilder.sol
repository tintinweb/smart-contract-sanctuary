// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "@pooltogether/pooltogether-rng-contracts/contracts/RNGInterface.sol";
import "../token/TokenListenerInterface.sol";
import "../prize-pool/PrizePool.sol";
import "../prize-strategy/single-random-winner/SingleRandomWinnerProxyFactory.sol";
import "../token/ControlledTokenProxyFactory.sol";
import "../token/TicketProxyFactory.sol";
import "../external/openzeppelin/OpenZeppelinProxyFactoryInterface.sol";

/* solium-disable security/no-block-members */
contract SingleRandomWinnerBuilder {
  using SafeCast for uint256;

  event SingleRandomWinnerCreated (
    address indexed singleRandomWinner,
    address indexed ticket,
    address indexed sponsorship
  );

  struct SingleRandomWinnerConfig {
    RNGInterface rngService;
    uint256 prizePeriodStart;
    uint256 prizePeriodSeconds;
    string ticketName;
    string ticketSymbol;
    string sponsorshipName;
    string sponsorshipSymbol;
    uint256 ticketCreditLimitMantissa;
    uint256 ticketCreditRateMantissa;
    address[] externalERC20Awards;
  }

  ControlledTokenProxyFactory public controlledTokenProxyFactory;
  TicketProxyFactory public ticketProxyFactory;
  SingleRandomWinnerProxyFactory public singleRandomWinnerProxyFactory;
  address public trustedForwarder;

  constructor (
    SingleRandomWinnerProxyFactory _singleRandomWinnerProxyFactory,
    address _trustedForwarder,
    ControlledTokenProxyFactory _controlledTokenProxyFactory,
    TicketProxyFactory _ticketProxyFactory
  ) public {
    require(address(_singleRandomWinnerProxyFactory) != address(0), "SingleRandomWinnerBuilder/single-random-winner-factory-not-zero");
    require(address(_controlledTokenProxyFactory) != address(0), "SingleRandomWinnerBuilder/controlled-token-proxy-factory-not-zero");
    require(address(_ticketProxyFactory) != address(0), "SingleRandomWinnerBuilder/ticket-proxy-factory-not-zero");
    ticketProxyFactory = _ticketProxyFactory;
    singleRandomWinnerProxyFactory = _singleRandomWinnerProxyFactory;
    trustedForwarder = _trustedForwarder;
    controlledTokenProxyFactory = _controlledTokenProxyFactory;
  }

  function createSingleRandomWinner(
    PrizePool prizePool,
    SingleRandomWinnerConfig calldata config,
    uint8 decimals,
    address owner
  ) external returns (SingleRandomWinner) {
    SingleRandomWinner prizeStrategy = singleRandomWinnerProxyFactory.create();

    address ticket = address(
      _createTicket(
        prizePool,
        config.ticketName,
        config.ticketSymbol,
        decimals
      )
    );

    address sponsorship = address(
      _createControlledToken(
        prizePool,
        config.sponsorshipName,
        config.sponsorshipSymbol,
        decimals
      )
    );

    prizeStrategy.initialize(
      trustedForwarder,
      config.prizePeriodStart,
      config.prizePeriodSeconds,
      prizePool,
      ticket,
      sponsorship,
      config.rngService,
      config.externalERC20Awards
    );

    prizeStrategy.transferOwnership(owner);

    emit SingleRandomWinnerCreated(address(prizeStrategy), ticket, sponsorship);

    return prizeStrategy;
  }

  function _createControlledToken(
    TokenControllerInterface controller,
    string memory name,
    string memory symbol,
    uint8 decimals
  ) internal returns (ControlledToken) {
    ControlledToken token = controlledTokenProxyFactory.create();
    token.initialize(string(name), string(symbol), decimals, trustedForwarder, controller);
    return token;
  }

  function _createTicket(
    TokenControllerInterface controller,
    string memory name,
    string memory symbol,
    uint8 decimals
  ) internal returns (Ticket) {
    Ticket ticket = ticketProxyFactory.create();
    ticket.initialize(string(name), string(symbol), decimals, trustedForwarder, controller);
    return ticket;
  }
}
