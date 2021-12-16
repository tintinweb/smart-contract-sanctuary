// 0.5.1-c8a2
pragma solidity ^0.5.0;

import "./ERC20.sol";
import "./ERC20Detailed.sol";

/**
 * @title SimpleToken
 * @dev Very simple ERC20 Token example, where all tokens are pre-assigned to the creator.
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `ERC20` functions.
 */
contract XXX15 is BurnableToken, PausableToken, MintableToken, ERC20Detailed, MultiSendToken, WithdrawalToken{

    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
    constructor () public ERC20Detailed("XXX15", "XXX15", 2) {
        _mint(msg.sender, 100000000000 * (10 ** uint256(decimals())));
    }
}