/**
 *Submitted for verification at Etherscan.io on 2021-12-30
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

contract Counter { 

    string public message; 
    
    function setMessage(string memory _message) external { 
        message = _message;
    }

}