// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract CreateToken is ERC20{


    uint256 conversionRate;

    constructor() ERC20("Vrbanj Coin5", "VARBONJ5",2,10000000000000000){
        conversionRate=100000000;
        _mint(msg.sender, 10000000000000000);
    }

    function buyFromContract() payable public {
        transferFromContract(msg.sender, 200000);
    }

    function buyFromContractCreator() payable public {
        transferBoughtTokens(msg.sender, 100000);
    }

    function tokenRate() public view virtual returns (uint256) {
        return 1 ether /1000000000000000000*conversionRate;
    }

   

}