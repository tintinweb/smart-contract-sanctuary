// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IValidator.sol";

contract ValidateMultiple is IValidator {

  IValidator[] validators;

  constructor(address[] memory _validators) {
    for (uint i = 0; i < _validators.length; i++) {
      validators.push(IValidator(_validators[i]));
    }
  }

  function errorMessage() external view returns (string memory) {
    string memory error = "";
    for (uint i = 0; i < validators.length; i++) {
      string(abi.encodePacked(error, " and ", validators[i].errorMessage));
    }
    return error;
  }

  function validateMint(address _address) external view returns(bool) {
    bool valid = false;
    for (uint i = 0; i < validators.length; i++) {
      valid = valid || validators[i].validateMint(_address);
    }
    return valid;
  }
}