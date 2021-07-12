// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract CreateToken is ERC20{


    uint256 conversionRate;

    constructor() ERC20("Vrbanj Coin2", "VARBONJ2",2,10000000000){
       
        conversionRate=10000000;
    }

    function buy() payable public {
        uint256 amount = msg.value*conversionRate;
        _mint(msg.sender, amount);
    }

}