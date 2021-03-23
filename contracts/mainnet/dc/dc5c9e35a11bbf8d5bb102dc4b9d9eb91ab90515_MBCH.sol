//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental SMTChecker;
import "MToken.sol";
/// @title MBCH
contract MBCH is MToken {
    constructor() MToken("Matrix BCH Token", "MBCH", 8, (ERC20ControllerViewIf)(0)){}
}