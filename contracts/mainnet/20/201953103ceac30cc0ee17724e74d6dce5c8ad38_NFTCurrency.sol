// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./ERC20Optional.sol";

contract NFTCurrency is ERC20Optional {
    uint256 private _initial_supply = 5000000000 * ( 10 ** 18 );

    constructor() public ERC20("NFT Currency", "NFTC") {
        _mint(msg.sender, _initial_supply);
    }
}