pragma solidity ^0.5.0;

import "./Context.sol";
import "./ERC20.sol";
import "./ERC20Detailed.sol";
import "./ERC20Burnable.sol";

/**
 * @title Next Generation Orb ERC20 Coin
 */
 
contract NextGenerationOrb is Context, ERC20, ERC20Detailed, ERC20Burnable {

    constructor () public ERC20Detailed("Next Generation Orb", "NGO", 9) {
        _mint(_msgSender(), 3200000000 * (10 ** uint256(decimals())));
    }
}