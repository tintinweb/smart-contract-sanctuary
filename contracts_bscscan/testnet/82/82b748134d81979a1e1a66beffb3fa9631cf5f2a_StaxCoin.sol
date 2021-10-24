// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

//import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
//import "@openzeppelin/contracts/access/Ownable.sol";
import "../JoeToken_flat.sol";

contract StaxCoin is JoeToken {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) public {}
}