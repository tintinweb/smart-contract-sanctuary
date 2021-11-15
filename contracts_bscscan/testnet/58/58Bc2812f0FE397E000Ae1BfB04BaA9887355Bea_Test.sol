//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;

contract Test{
    constructor(){
    }

    function getMonthSinceLastClaim(uint256 lastClaim) internal view returns(uint256){
        return (block.timestamp - lastClaim) / (30 days);
    }

}

