/**
 *Submitted for verification at Etherscan.io on 2021-11-29
*/

pragma solidity ^0.8.10;
// SPDX-License-Identifier: MIT

interface Origins {
        function deposit() external payable;
}

contract OriginsDao {
    address originsContract;
    Origins public _origins;
    fallback() payable external {}
    receive() external payable {}

    constructor()  {
        originsContract = 0xd067c22089a5c8Ab9bEc4a77C571A624e18f25E8;
        _origins = Origins(originsContract);
    }


    function distribute() public payable { 
        _origins.deposit{value: address(this).balance};

    }

    
    
}