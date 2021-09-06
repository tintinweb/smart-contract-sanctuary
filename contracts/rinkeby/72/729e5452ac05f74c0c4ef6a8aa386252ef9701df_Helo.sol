/**
 *Submitted for verification at Etherscan.io on 2021-09-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Owner
 * @dev Set & change owner
 */
contract Helo {
    string something;
    function setSomething( string memory sdf)public view  {
        sdf=something;
    }
    function saySomething()public view returns( string memory){
        return something;
    }
}