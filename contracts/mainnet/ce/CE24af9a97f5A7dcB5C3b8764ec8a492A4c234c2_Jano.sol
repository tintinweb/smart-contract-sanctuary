pragma solidity ^0.6.0;

import "./ERC20.sol";

contract Jano is ERC20 {

    constructor () public ERC20("Jano", "JNO") {
        _mint(msg.sender, 1000000000000 * (10 ** uint256(decimals())));
    }
}