/**
 *Submitted for verification at Etherscan.io on 2021-05-03
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

contract BrotherZone{
    
    string greeter = "Harbi";
    string person;
    string harbiGeets = "Hey Bro";
    string othersGreet = "Hey Love";
    
    function famz(string memory name, string memory greet) external view returns(string memory
    ){
        if(keccak256(abi.encodePacked(name)) == keccak256(abi.encodePacked(greeter)) && keccak256(abi.encodePacked(greet)) == keccak256(abi.encodePacked("My boo"))){
            return harbiGeets;
        }
        return othersGreet;
    }
}