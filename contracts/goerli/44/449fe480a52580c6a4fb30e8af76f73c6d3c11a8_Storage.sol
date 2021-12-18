/**
 *Submitted for verification at Etherscan.io on 2021-12-17
*/

//SPDX-License-Identifier:MIT
pragma solidity 0.8.7;



contract Storage{
    uint256 number;
    
    function store(uint256 test) public {
    number = test; 
    }
    function Retrive () public view returns(uint256){
        return number;

    }


}