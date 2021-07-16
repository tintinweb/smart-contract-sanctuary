// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract CreateToken is ERC20{


    uint256 conversionRate;

    constructor() ERC20("Vrbanj Coin6", "VARBONJ6",2,10000000000000000){
        conversionRate=1000000.00;
        _mint(msg.sender, 10000000000000000);
    }

    function buyFromContract() payable public {
        uint256 amounttosend=(msg.value*conversionRate)/1 ether;
        transferFromContract(msg.sender, amounttosend);
    }

    function buyFromContractCreator() payable public {
        uint256 amounttosend=(msg.value*conversionRate)/1 ether;
        transferBoughtTokens(msg.sender, amounttosend);
    }

  
}