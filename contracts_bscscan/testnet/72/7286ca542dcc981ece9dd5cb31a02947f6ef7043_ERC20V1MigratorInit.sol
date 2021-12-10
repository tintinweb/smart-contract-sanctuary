// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "./ERC20V1Migrator.sol";
import "./Initializable.sol";

contract ERC20V1MigratorInit is Initializable, ERC20V1Migrator {
  function initialize (
    address contracAddress,
    address nextContracAddress,
    address developerAddress,
    uint mininumBalance,
    uint amountFee,
    uint8 contracAddressDecimal
  ) initializer public {
    __ERC20V1Migrator_init(
      contracAddress,
      nextContracAddress,
      developerAddress,
      mininumBalance,
      amountFee,
      contracAddressDecimal
    );
  }
}