// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./ERC20.sol";
import "./Ownable.sol";
import "./Context.sol";

/**
 * @title Single Witness
 */
 
contract CCToken is Context, ERC20, Ownable {

    using SafeMath for uint256;

    uint256 private _cap;
    /**
     * @dev Constructor
     */
    constructor (string memory name, string memory symbol, uint256 cap, uint256 initialSupply)
        ERC20(name, symbol) {
        require(cap > 0, "CCToken: cap is 0");
        require(initialSupply <= cap, "CCToken: cap exceeded!");
        _cap = cap;
        _mint(_msgSender(), initialSupply);
    }
    
    /**
     * @dev Returns the cap on the token's total supply.
     */
    function getCap() public view returns (uint256) {
        return _cap;
    }

    /**
     * @dev set the cap on the token's total supply.
     */
    function setCap(uint256 cap) onlyOwner external {
        require(cap > 0, "CCToken: cap is 0");
        _cap = cap;
    }
    /**
     * @dev See `ERC20._burn`.
     */
    function burnFrom(address account, uint256 amount) onlyOwner external {
        _burn(account, amount);
    }

    /**
     * @dev See `ERC20._mint`.
     *
     * Requirements:
     *
     * - the caller must have the `MinterRole`.
     */
    function mintTo(address account, uint256 amount) external onlyOwner returns (bool) {
        require(totalSupply().add(amount) <= _cap, "CCToken: cap exceeded!");
        _mint(account, amount);
        return true;
    }
}