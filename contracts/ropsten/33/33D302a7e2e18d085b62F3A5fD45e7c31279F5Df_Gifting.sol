/**
 *Submitted for verification at Etherscan.io on 2021-10-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Gifting
 * @dev Store & retrieve value in a variable - value is your gift in ETH value 
 */
contract Gifting {

    uint8 giftETH;

    /**
     * @dev Send value in variable
     * @param giftValue value to send
     */
    function send(uint8 giftValue) public {
        giftETH = giftValue;
    }

    /**
     * @dev Return value 
     * @return value of 'giftETH'
     */
    function retrieve() public view returns (uint8){
        return giftETH;
    }
}