/**
 *Submitted for verification at Etherscan.io on 2021-09-14
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract List{
    uint limitnum = 20;
    struct person {
        bool seo;
        string name;
    }
    person[] sample;
    function store (bool seo, string memory name) public {
        if(sample.length < limitnum){
            sample.push(person(seo,name));
        }    
    }
    function show (uint n) public view returns(string memory name) {
        name = sample[n-1].name;
 
    }
    
    
}