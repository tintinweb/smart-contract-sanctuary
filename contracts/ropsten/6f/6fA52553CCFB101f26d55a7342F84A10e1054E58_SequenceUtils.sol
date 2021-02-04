// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "./MultiCallUtils.sol";
import "./RequireUtils.sol";


contract SequenceUtils is 
  MultiCallUtils,
  RequireUtils
{
  constructor(
    address _factory,
    address _mainModule
  ) RequireUtils(
    _factory,
    _mainModule
  ) {}
}