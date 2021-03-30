pragma solidity ^0.5.0;

import "./Context.sol";
import "./ERC20.sol";
import "./ERC20Detailed.sol";
import "./ERC20Burnable.sol";

contract Questtoken is Context, ERC20, ERC20Detailed, ERC20Burnable {

    constructor () public ERC20Detailed("Quest Token", "Quest", 18) {
        _mint(_msgSender(), 2100000000 * (10 ** uint256(decimals())));
    }
}