// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract CreateToken is ERC20{


    uint256 conversionRate;

    constructor() ERC20("Vrbanj Coin6", "VARBONJ6",2,10000000000000000){
        conversionRate=1000000;
        _mint(msg.sender, 10000000000000000);
    }

    function buyFromContract() payable public {
        transferFromContract(msg.sender, msg.value/1000000000000000000*conversionRate);
    }

    function buyFromContractCreator() payable public {
        
        transferBoughtTokens(msg.sender, msg.value/1000000000000000000*conversionRate);
    }

    function tokenRate() public view virtual returns (uint256) {
        return 1 ether /1000000000000000000*conversionRate;
    }

  
}