// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IGenArt721CoreV2.sol";
import "./IValidator.sol";

/**
 * Validator that uses an explicit whitelist to control who
 * can receive a mint.
 */
contract ValidateWhitelist is Validator {

  GenArt721CoreContract public artblocksContract;

  string constant ErrorMessage = "address is not in the whitelist";

  mapping(address => bool) public whitelist;

  constructor(address _genArt721Address) public {
    artblocksContract = GenArt721CoreContract(_genArt721Address);
  }
  
  function batchAddToWhitelist(address[] memory _addresses) public {
    for (uint i = 0; i < _addresses.length; i++) {
      addToWhitelist(_addresses[i]);
    }
  }

  function addToWhitelist(address _address) public {
    require(artblocksContract.isWhitelisted(msg.sender), "can only be set by admin");
    whitelist[_address] = true;
  }

  function removeFromWhitelist(address _address) public {
    require(artblocksContract.isWhitelisted(msg.sender), "can only be set by admin");
    whitelist[_address] = false;
  }

  function errorMessage() external view returns (string memory) {
      return ErrorMessage;
  }

  function validateMint(address _address) external view returns(bool) {
    return whitelist[_address];
  }
}