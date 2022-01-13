/**
 *Submitted for verification at Etherscan.io on 2022-01-13
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;
 
contract HelpMe {
    string private response;
    mapping(address => bool) hasBought;
    constructor(string memory _res){
        response = _res;
    }

    function buyResponse() public payable {
        require(msg.value > 1);
        if(hasBought[msg.sender] == false){
            hasBought[msg.sender] = true;
        }
    }

    function getResponse() public view returns(string memory){
        if(hasBought[msg.sender] == true){
            return response;
        }
    }
}