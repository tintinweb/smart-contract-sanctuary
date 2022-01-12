/**
 *Submitted for verification at Etherscan.io on 2022-01-12
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract SecretCode {
    string private secret_code;

    constructor(string memory _secret) {
        secret_code = _secret;
    }

    function leakSecretCode(uint16 _secret_number) public view returns (string memory) {
        require(_secret_number == 1);
        
        return secret_code;
    }
}