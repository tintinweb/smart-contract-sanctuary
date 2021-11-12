// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract GPEX is ERC20("GPEX", "GPX"), Ownable {
    using SafeMath for uint256;

    event Burn(uint256 amount);

    uint8 public constant DECIMALS=8;
    uint256 public constant INITIAL_SUPPLY=1000000000*(10**uint256(DECIMALS));
    bool public mintingFinished=false;

    constructor () {
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    function burn(uint256 amount) onlyOwner public {
        uint256 amount2=amount*(10**uint256(DECIMALS));
        _burn(msg.sender,amount2);

        emit Burn(amount);
    }
}