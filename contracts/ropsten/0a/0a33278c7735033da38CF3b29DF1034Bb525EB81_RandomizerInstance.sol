/**
 *Submitted for verification at Etherscan.io on 2021-10-28
*/

pragma solidity ^0.5.0;

contract RandomizerInstance {
    function returnValue() external view returns(bytes32){
        return keccak256(abi.encodePacked(block.difficulty, block.timestamp));
    }
}