/**
 *Submitted for verification at Etherscan.io on 2022-01-12
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract SecretCode {
    string private secret_code;
    mapping(address => bool) secret_agent;

    constructor(string memory _secret) {
        secret_code = _secret;
    }

    function leakSecretCode(uint16 _secret_number) public view returns (string memory) {
        require(_secret_number == 1);
        require(secret_agent[msg.sender] == true);
        
        return secret_code;
    }

    function validateMySelf() public {
      secret_agent[msg.sender] = true;
    }
}