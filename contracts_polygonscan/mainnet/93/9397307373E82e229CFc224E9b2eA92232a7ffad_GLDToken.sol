// contracts/Moneys-beta.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC20.sol";

contract GLDToken is ERC20 {
    constructor() ERC20("Moneyes Beta Token", "MEYSB") {
        _mint(msg.sender, 1000000 * 10 ** 18);
    }
}