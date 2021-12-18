pragma solidity ^0.8.0;

import "./ERC20.sol";

/**
 * @dev Optional functions from the ERC20 standard.
 */
contract Diosama is ERC20 {


    constructor () public ERC20("diosama", "Ds") {
        _mint(msg.sender, 1000000 * (10 ** uint256(decimals())));
    }
}