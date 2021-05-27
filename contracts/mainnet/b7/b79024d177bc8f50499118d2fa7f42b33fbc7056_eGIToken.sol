// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract eGIToken is ERC20("eGame", "eGI"), Ownable {
    event Mint(uint256 amount);
    event MintFinished();
    event Burn(uint256 amount);

    uint8 public constant DECIMALS=8;
    uint256 public constant INITIAL_SUPPLY=50000000000*(10**uint256(DECIMALS));
    bool public mintingFinished=false;

    constructor () {
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    function mint(uint256 amount) onlyOwner canMint public{
        uint256 amount2=amount*(10**uint256(DECIMALS));
        _mint(msg.sender,amount2);

        emit Mint(amount);
    }

    function burn(uint256 amount) onlyOwner public {
        uint256 amount2=amount*(10**uint256(DECIMALS));
        _burn(msg.sender,amount2);

        emit Burn(amount);
    }

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    function finishingMinting() onlyOwner canMint public returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }
}