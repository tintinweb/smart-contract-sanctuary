pragma solidity ^0.5.0;

import "./Context.sol";
import "./ERC20.sol";
import "./ERC20Detailed.sol";
import "./ERC20Burnable.sol";

contract blizzard is Context, ERC20, ERC20Detailed, ERC20Burnable {

    constructor () public ERC20Detailed("blizzard Token", "BZD", 9) {
        _mint(_msgSender(), 100000000 * (10 ** uint256(decimals())));
    }
}