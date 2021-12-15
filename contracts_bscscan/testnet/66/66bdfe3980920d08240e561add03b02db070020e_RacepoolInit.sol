// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "./Racepool.sol";
import "./Initializable.sol";

contract RacepoolInit is Initializable, Racepool {
  function initialize (
    address erc20ContractAddress,
    string memory contractName,
    string memory contractSymbol,
    address contractAdmin,
    uint contractTax
  ) initializer public {
    __Racepool_init(
      erc20ContractAddress,
      contractName,
      contractSymbol,
      contractAdmin,
      contractTax
    );
  }
}