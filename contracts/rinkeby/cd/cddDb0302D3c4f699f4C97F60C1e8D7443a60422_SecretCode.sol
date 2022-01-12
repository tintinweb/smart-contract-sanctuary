/**
 *Submitted for verification at Etherscan.io on 2022-01-12
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract SecretCode {
    string private secretCode;
    mapping(address => string) private secretAgentsCode;

    constructor(string memory _secret) {
      secretCode = _secret;
    }

    function leakSecretCode(uint16 _secret_number) public view returns (string memory) {
      require(_secret_number == 1, "Wrong secret code");
      // get your secret code
      return secretAgentsCode[msg.sender];
    }

    function getMySecretCode() public {
      // initialize secret code
      secretAgentsCode[msg.sender] = secretCode;
    }
}