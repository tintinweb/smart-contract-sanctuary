// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract CreateToken is ERC20{


    uint256 conversionRate;

    constructor() ERC20("Vrbanj Coin2", "VARBONJ2",2){
        _mint(msg.sender, 1000000000000000000000000);
        conversionRate=10000;
    }

    function buy() payable public {
        uint256 amount = msg.value*conversionRate*1**(-18);
        transferFrom(address(0),msg.sender, amount);
    }

}