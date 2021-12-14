/**
 *Submitted for verification at Etherscan.io on 2021-12-14
*/

//SPDX-License-Identifier: None

pragma solidity ^0.8.0;

contract verifiable {

    uint8 private a = 1;

    function read() external view returns(uint8){
        return(a);
    }

}