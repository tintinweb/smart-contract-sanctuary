pragma solidity ^0.8.0;

import "./ERC20Burnable.sol";
contract CLOCKS is ERC20Burnable {
    constructor() ERC20('Uniclocks','CLOCKS'){
        _mint(msg.sender, 350 * 10 ** 18);
    }
}