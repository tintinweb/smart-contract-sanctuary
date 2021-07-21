// 0.5.1-c8a2
// Enable optimization
pragma solidity ^0.5.0;

import "./ERC20Burnable.sol";
import "./ERC20Detailed.sol";

/**
 * @title SimpleToken
 * @dev Very simple ERC20 Token example, where all tokens are pre-assigned to the creator.
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `ERC20` functions.
 */
contract Token is ERC20Burnable, ERC20Detailed {

    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
    constructor () public ERC20Detailed("BLOG", "BLOG", 6) {
        _mint(msg.sender, 26000000 * (10 ** uint256(decimals())));
    }
}