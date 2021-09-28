/**
 *Submitted for verification at Etherscan.io on 2021-09-28
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    uint256 number;
    function loop(uint t) public pure returns (uint){
        uint n;
        for(uint i=0;i<t;i++){
            n++;
        }
        return n;
    }
    function internalCall(uint t) public view returns (uint256){
        uint res = this.loop{gas:10000000}(t);
        return res;
    }
}