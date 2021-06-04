/**
 *Submitted for verification at Etherscan.io on 2021-06-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @dev This contract is deployed as an interim patch while the DateTime library is upgraded. 
 */
contract Test {


	address public original = 0x1a6184CD4C5Bea62B0116de7962EE7315B7bcBce;

    function getMonth0() public view returns (bool) {
        
        DateTimeAPI dateTime = DateTimeAPI(original);
        uint value = dateTime.getMonth(block.timestamp);
        
        if (value == 6) {
            return true;
        }
        false;
    }


    address public update = 0x740a637ADD6492e5FaA907AF0fe708770B737058;

    function getMonth1() public view returns (bool) {

        DateTimeAPI dateTime = DateTimeAPI(update);
        uint value = dateTime.getMonth(block.timestamp);
        
        if (value == 6) {
            return true;
        }
        false;
    }


    address public patch = 0x2a837A67f756517654bf43548b2B4CBEd364B4D0; 

    function getMonth2() public view returns (bool) {
        
        DateTimeAPI dateTime = DateTimeAPI(patch);
        uint value = dateTime.getMonth(block.timestamp);
        
        if (value == 6) {
            return true;
        }
        false;
    }

}

abstract contract DateTimeAPI {
    function getMonth(uint timestamp) public view virtual returns (uint8);
}