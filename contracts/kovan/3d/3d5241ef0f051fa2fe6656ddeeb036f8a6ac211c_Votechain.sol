// 0.5.1-c8a2
// Enable optimization
pragma solidity ^0.5.12;

import "./ERC20.sol";
import "./ERC20Detailed.sol";

/**
 * @title Votechain (VBSC) 
 * Symbol          : VBSC
 * Name            : Votechain
 * Total supply    : 121000000
 * Decimals        : 0
 */
contract Votechain is ERC20, ERC20Detailed {

    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
    constructor () public ERC20Detailed("Votechain", "VBSC", 6) {
        _mint(msg.sender, 121000000 * (10 ** uint256(decimals())));
    }
}