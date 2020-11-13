pragma solidity ^0.7.4;

import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Mock is ERC20, ERC20Burnable {
    constructor(address initialAccount, uint256 initialBalance) ERC20("MockToken", "MCT") {
        _mint(initialAccount, initialBalance);
    }
}
