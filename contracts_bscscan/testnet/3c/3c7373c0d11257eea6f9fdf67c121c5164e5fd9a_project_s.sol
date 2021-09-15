// "SPDX-License-Identifier: UNLICENSED" for non-open-source code. Please see https://spdx.org for more information.
pragma solidity ^0.8.7;
import "./ERC20.sol";
contract project_s is ERC20 {
    constructor() ERC20("fckthesystem", "fts") {
        _mint(msg.sender, 1000 * 10 ** 18);
    }

}