/**
 *Submitted for verification at Etherscan.io on 2021-08-06
*/

pragma solidity ^0.6.0;

contract Attack{
    bytes32 public answerHash;
    function Try(string memory _response) public payable
    {
        

        answerHash = keccak256(abi.encode(_response));
        
    }
}