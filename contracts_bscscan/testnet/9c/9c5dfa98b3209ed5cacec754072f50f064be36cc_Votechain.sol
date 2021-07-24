// 0.5.1-c8a2
// Enable optimization
pragma solidity ^0.5.12;

import "./ERC20.sol";
import "./ERC20Detailed.sol";

/**
 * @title Votechain (VBSC2.0) 
 * Symbol          : VBSC
 * Name            : VBSC20
 * Total supply    : 40333333
 * Decimals        : 0
 */
contract Votechain is ERC20, ERC20Detailed {

    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
    constructor () public ERC20Detailed("VBSC20", "VBSC20", 18) {
        _mint(msg.sender, 40333333 * (10 ** uint256(decimals())));
    }
}