/**
 *Submitted for verification at Etherscan.io on 2022-01-11
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract uSC{
    string public ValidationHash ;
    bool public isFirstRun = false;

    constructor(){
        isFirstRun = true;
    }

    function _SetHASH(string memory _userInput) public {
        require(isFirstRun, "Already setup");
        ValidationHash = _userInput;
        isFirstRun = false;
    }   
       
    function _Validate(string memory pass) public view returns(bool){
        return keccak256(bytes(ValidationHash)) == keccak256(bytes(pass));
    }
}