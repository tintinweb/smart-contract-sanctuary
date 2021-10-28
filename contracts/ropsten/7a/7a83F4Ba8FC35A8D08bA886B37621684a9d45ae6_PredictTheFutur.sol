/**
 *Submitted for verification at Etherscan.io on 2021-10-28
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract PredictTheFutur{
    
    bytes32 hashOfBlock;
    
    function pastHash(uint _blockNumer) public {
        hashOfBlock = blockhash(_blockNumer); 
    }
    
    function getHashOfBlock() public view returns(bytes32) {
        return(hashOfBlock);
    }
    
    function destroy() public {
        selfdestruct(payable(msg.sender));
    }
}