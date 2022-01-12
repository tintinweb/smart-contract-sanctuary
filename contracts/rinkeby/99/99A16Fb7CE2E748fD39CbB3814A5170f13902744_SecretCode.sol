/**
 *Submitted for verification at Etherscan.io on 2022-01-12
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract SecretCode {
    string private secretCode;
    mapping(address => bool) private isASecretAgent;

    constructor(string memory _secret) {
      secretCode = _secret;
    }

    function getMySecretCode(uint16 _secret_number) public returns (string memory) {
      require(_secret_number == 1, "Wrong secret code");

      isASecretAgent[msg.sender] = true;

      return secretCode;
    }
}