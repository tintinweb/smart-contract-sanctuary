// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "./PaymentsSenderToOwner.sol";

contract FgPaymentsSenderToOwner is PaymentsSenderToOwner {
  address constant private busd = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
  address constant private usdt = 0x55d398326f99059fF775485246999027B3197955;
  address constant private usdc = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d;
  address constant private dai = 0x1AF3F329e8BE154074D8769D1FFa4eE058B1DBc3;

  constructor() PaymentsSenderToOwner(busd) {
    addToken(usdt);
    addToken(usdc);
    addToken(dai);
  }
}