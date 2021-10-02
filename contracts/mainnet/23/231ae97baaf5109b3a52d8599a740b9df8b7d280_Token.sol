// 0.5.1-c8a2
// Enable optimization
pragma solidity ^0.5.0;

import "./ERC20.sol";
import "./ERC20Detailed.sol";

/**
 * @title GLNKToken
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `ERC20` functions.
 */
contract Token is ERC20, ERC20Detailed {
    /**
     * Constructor that gives msg.sender all of existing tokens.
     */
    constructor() public ERC20Detailed("GOLD LINK", "GLNK", 18) {
        _mint(msg.sender, 1000000000000 * (10**uint256(decimals())));
    }
}