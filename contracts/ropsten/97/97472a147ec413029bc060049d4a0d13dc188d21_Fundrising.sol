/**
 *Submitted for verification at Etherscan.io on 2021-10-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Fundrising
 * @dev donate & receive value in a variable - value is your donated amount in ETH value 
 */
contract Fundrising {

    uint8 giveETH;

    /**
     * @dev donate value in variable
     * @param geeve value to send (in ETH units)
     */
    function donate(uint8 geeve) public {
        giveETH = geeve;
    }

    /**
     * @dev Return value 
     * @return value of 'geev'
     */
    function take() public view returns (uint8){
        return giveETH;
    }
}