/**
 *Submitted for verification at Etherscan.io on 2021-10-07
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    uint256 number;

    function store(uint256 num) public {
        number = num;
    }

    function retrieve() public view returns (uint256){
        return number;
    }
    
    function howmanydays() public view returns (uint256){
        uint256 oldtime =1617088368;
        uint256 nowtime=block.timestamp;
        uint256 offset=nowtime-oldtime;
        uint256 offsetdays=offset / 180 days;
        return offsetdays;
    }
}