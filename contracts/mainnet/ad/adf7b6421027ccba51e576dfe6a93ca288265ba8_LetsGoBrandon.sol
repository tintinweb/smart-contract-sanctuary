// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
import "./ERC20.sol";

contract  LetsGoBrandon is ERC20 {
     constructor()  ERC20("Let's Go Brandon", "FJB") {
        _mint(msg.sender, 333521901000000000000000000);
    }
}