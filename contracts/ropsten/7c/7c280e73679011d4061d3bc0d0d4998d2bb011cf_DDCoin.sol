// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./ERC20Optional.sol";

contract DDCoin is ERC20Optional {
    uint256 private _initial_supply = 5000000000 * ( 10 ** 18 );
    string private _sayHello = 'hello DDC';

    constructor() public ERC20("DDCoin", "DDC") {
        _mint(msg.sender, _initial_supply);
    }

    function sayHello() public view returns (string memory) {
        return _sayHello;
    }
}