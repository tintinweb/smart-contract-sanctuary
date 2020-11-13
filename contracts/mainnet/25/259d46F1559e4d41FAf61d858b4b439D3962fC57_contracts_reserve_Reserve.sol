// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.7.0;

import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";

import "./ReserveInterface.sol";
import "../prize-pool/PrizePoolInterface.sol";

/// @title Interface that allows a user to draw an address using an index
contract Reserve is OwnableUpgradeSafe, ReserveInterface {

  event ReserveRateMantissaSet(uint256 rateMantissa);

  uint256 public rateMantissa;

  constructor () public {
    __Ownable_init();
  }

  function setRateMantissa(
    uint256 _rateMantissa
  )
    external
    onlyOwner
  {
    rateMantissa = _rateMantissa;

    emit ReserveRateMantissaSet(rateMantissa);
  }

  function withdrawReserve(address prizePool, address to) external onlyOwner returns (uint256) {
    return PrizePoolInterface(prizePool).withdrawReserve(to);
  }

  function reserveRateMantissa(address) external view override returns (uint256) {
    return rateMantissa;
  }
}
