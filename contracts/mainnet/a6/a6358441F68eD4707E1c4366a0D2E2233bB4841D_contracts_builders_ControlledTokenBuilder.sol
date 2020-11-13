// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "../token/ControlledTokenProxyFactory.sol";
import "../token/TicketProxyFactory.sol";

/* solium-disable security/no-block-members */
contract ControlledTokenBuilder {

  event CreatedControlledToken(address indexed token);
  event CreatedTicket(address indexed token);

  address public trustedForwarder;
  ControlledTokenProxyFactory public controlledTokenProxyFactory;
  TicketProxyFactory public ticketProxyFactory;

  struct ControlledTokenConfig {
    string name;
    string symbol;
    uint8 decimals;
    TokenControllerInterface controller;
  }

  constructor (
    address _trustedForwarder,
    ControlledTokenProxyFactory _controlledTokenProxyFactory,
    TicketProxyFactory _ticketProxyFactory
  ) public {
    require(address(_controlledTokenProxyFactory) != address(0), "ControlledTokenBuilder/controlledTokenProxyFactory-not-zero");
    require(address(_ticketProxyFactory) != address(0), "ControlledTokenBuilder/ticketProxyFactory-not-zero");
    controlledTokenProxyFactory = _controlledTokenProxyFactory;
    trustedForwarder = _trustedForwarder;
    ticketProxyFactory = _ticketProxyFactory;
  }

  function createControlledToken(
    ControlledTokenConfig calldata config
  ) external returns (ControlledToken) {
    ControlledToken token = controlledTokenProxyFactory.create();

    token.initialize(
      config.name,
      config.symbol,
      config.decimals,
      trustedForwarder,
      config.controller
    );

    emit CreatedControlledToken(address(token));

    return token;
  }

  function createTicket(
    ControlledTokenConfig calldata config
  ) external returns (Ticket) {
    Ticket token = ticketProxyFactory.create();

    token.initialize(
      config.name,
      config.symbol,
      config.decimals,
      trustedForwarder,
      config.controller
    );

    emit CreatedTicket(address(token));

    return token;
  }
}
