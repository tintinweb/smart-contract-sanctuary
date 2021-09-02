//SPDX-License-Identifier: UNLICENSED
import "ERC20.sol";

pragma solidity 0.8.0;

contract GameFi is ERC20 {
    constructor(string memory name_, string memory symbol_)
        ERC20(name_, symbol_)
    {
        _mint(msg.sender,1000000000000000000000000000);
    }
}