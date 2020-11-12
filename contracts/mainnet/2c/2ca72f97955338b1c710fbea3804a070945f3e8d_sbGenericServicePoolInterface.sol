// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface sbGenericServicePoolInterface {
  function isServiceAccepted(address service) external view returns (bool);
}
