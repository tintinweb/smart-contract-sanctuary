/*

This token was created by DexLot to represent a token that meets the requirements for creating a presale.
This extends the ERC20 and Ownable contracts from OpenZepplin. All credit for those contracts goes to them.

https://dexlot.app
https://t.me/DexLot

*/

// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./PresaleReady.sol";

contract PresaleReadyExample is PresaleReady {
    uint8 private _decimals = 18;
    uint256 private _totalSupply = 1000000000 * 10 ** _decimals;

    uint256 public sellFee = 2; // 2 percent

    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol, _decimals) {
        // Make sure the owner has a least enough tokens to create the presale! Here we just give the owner the full supply.
        _mint(msg.sender, _totalSupply);
        
        // Add additional constructor code here
    }

    // Please note that contracts compiled with Solidity 0.8.0 and higher will automatically revert on any underflows/overflows
    // (In other words, starting with Solidity 0.8.0, SafeMath is no longer required)

    function _transfer(address from, address to, uint256 value) internal override {
        // Make sure to check !whitelisted[from] before taking fees!
        if (from != owner() && to != owner() && !whitelisted[from]) {
            uint256 fee = value * sellFee / 100;

            super._transfer(from, address(this), fee);
            value -= fee;
        }

        super._transfer(from, to, value);
    }
}