// contract/CeramicTokenLogic.sol

// SPDX-License-Identifier: MIT or Apache-2
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./ERC1967Administration.sol";
import "./ERC20.sol";


contract CeramicTokenLogic is Initializable, ERC1967Administration, ERC20 {
    constructor() {
        lockLogicContract();
    }

    function lockLogicContract() initializer internal {}

    function initialize() initializer public {
        __ERC1967Administration_init();
        __ERC20_init("Ceramic", "FIRE");

        _mint(msg.sender, 1337000000 * 10 ** decimals());
    }
}