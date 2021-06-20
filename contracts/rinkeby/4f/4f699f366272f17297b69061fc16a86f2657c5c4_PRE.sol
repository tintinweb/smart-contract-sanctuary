// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ERC20.sol";
contract PRE is ERC20{
    constructor() ERC20("Prediction","PRE"){
        _mint(msg.sender,100000000*(10 ** uint256(decimals())));
    }
}