// SPDX-License-Identifier: Unlicensed

pragma solidity 0.7.5;

import "./ERC20.sol";

contract CTFv1 is ERC20 {
    constructor() ERC20("ctfv1", "CTFv1") {
        _mint(_msgSender(), 60000 * 10 ** 18);
    }
}