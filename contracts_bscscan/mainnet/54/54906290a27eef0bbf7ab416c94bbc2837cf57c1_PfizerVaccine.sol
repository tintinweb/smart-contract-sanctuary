// SPDX-License-Identifier: None
pragma solidity ^0.8.2;

import "ERC20.sol";

contract PfizerVaccine is ERC20 {
    constructor() ERC20("Pfizer Vaccine", "Pfizer") {
        _mint(msg.sender, 3000000000 * 10 ** decimals());
    }
}