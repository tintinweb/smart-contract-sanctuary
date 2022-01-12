pragma solidity ^0.7.0;

import "ERC20.sol";

contract Token is ERC20 {

    constructor () ERC20("OurCoin", "OUR") {
        _mint(msg.sender, 10000000000000 * (10 ** uint256(decimals())));
    }
}