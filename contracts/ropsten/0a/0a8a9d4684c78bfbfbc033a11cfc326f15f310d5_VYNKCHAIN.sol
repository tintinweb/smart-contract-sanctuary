// 0.5.1-c8a2
// Enable optimization
pragma solidity ^0.5.0;

import "./ERC20.sol";
import "./ERC20Detailed.sol";

/**
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `ERC20` functions.
 */
contract VYNKCHAIN is ERC20, ERC20Detailed {

    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
    constructor (uint256 _totalSupply) public ERC20Detailed("VYNK CHAIN", "VYNC", 4) {
        _mint(msg.sender, _totalSupply);
    }
}