/**
 *Submitted for verification at Etherscan.io on 2022-01-20
*/

//SPDX-License-Identifier:MIT
pragma solidity >=0.8.7;
contract kkk {

    uint256 number;
    function store(uint256 num) public {
        number = num;
    }

    function retrieve() public view returns (uint256){
        return number;
    }
}