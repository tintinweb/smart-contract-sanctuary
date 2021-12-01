/**
 *Submitted for verification at Etherscan.io on 2021-11-30
*/

pragma solidity ^0.8.10;
// SPDX-License-Identifier: MIT

interface Origins {
        function deposit() external payable;
}

contract OriginsDao {
    fallback() payable external {}
    receive() external payable {}

    address originsContract;
    Origins origins;

    constructor()  {
        originsContract = 0xd067c22089a5c8Ab9bEc4a77C571A624e18f25E8;
        origins = Origins(originsContract);
    }

    function distribute() public { 
        origins.deposit{value: address(this).balance}();

    }

    function getContractBalance() public view returns(uint256) {
        return address(this).balance;
    }

    
    
}