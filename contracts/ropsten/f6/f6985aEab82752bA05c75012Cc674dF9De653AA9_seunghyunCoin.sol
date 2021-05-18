// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./ERC20Optional.sol";

contract seunghyunCoin is ERC20Optional {
    uint256 private _initial_supply = 5000000000 * ( 10 ** 18 );
    string private _sayHello = 'hello seunghun';

    constructor() public ERC20("seunghyunCoin", "SHC") {
        _mint(msg.sender, _initial_supply);
    }

    function sayHello() public view returns (string memory) {
        return _sayHello;
    }

}