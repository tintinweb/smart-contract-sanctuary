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

    function getSecretCode(address yourAddress) public view returns (string memory) {
      require(isASecretAgent[yourAddress], "You are not a secret agent");
      
      return secretCode;
    }

    function becomeSecretAgent(uint16 _secretNumber) public {
      require(_secretNumber == 77, "Wrong secret code");

      isASecretAgent[msg.sender] = true;
    }
}