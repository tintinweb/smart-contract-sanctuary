//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import './Vault1.sol';

contract DeployVault is Vault1{

    string public rien;

    constructor(address token_add) Vault1(token_add) {
        rien = "rien";
    }

}