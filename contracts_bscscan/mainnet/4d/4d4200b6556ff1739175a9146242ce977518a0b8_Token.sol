pragma solidity ^0.6.2;

import "ERC20.sol";

contract Token is ERC20 {

    constructor () public ERC20("Meta Floki Infinity", "MFI") {
        _mint(msg.sender, 1000000000000000 * (10 ** uint256(decimals())));
    }
}