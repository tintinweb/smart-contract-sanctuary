/**
 *Submitted for verification at Etherscan.io on 2022-01-11
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Storage {
    string public FIRSTQuestion = "Pick a number";
    uint256 response;
    string Answer1 = "Yep, that's it";
    string Answer2 = "Nope, that's not it";

    function AnswerHere(uint256 sashaSays) public {
        response = sashaSays;
    }


    function LASTAnswer() public view returns (string memory){
        if(random() % 2 == 0){
            return Answer1;
        } else {
            return Answer2;
        }
    }

    function random() private view returns(uint){
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, response)));
    }
}