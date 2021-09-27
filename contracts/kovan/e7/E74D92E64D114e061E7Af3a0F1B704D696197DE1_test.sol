/**
 *Submitted for verification at Etherscan.io on 2021-09-27
*/

pragma solidity ^0.5.17;

contract test {
    
    string public m = "妈";
  
    function play1() public view returns (bytes32){
    bytes32  a = keccak256(abi.encodePacked(block.coinbase, block.timestamp));
    return a;
    }
    
   
    function change(string memory str) public {
        m = string(abi.encodePacked(m,str));
    }
    
}