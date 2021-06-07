/**
 *Submitted for verification at Etherscan.io on 2021-06-06
*/

pragma solidity ^0.4.26;

contract Tufa {
uint _token;
uint abc;
  mapping(address => uint) authentications;
  
   function accessToken() public returns (uint){
      // _token = token;
       address prover = msg.sender;
       abc = uint( uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty))));
    //uint256 abc = uint256( uint256(keccak256(_token)));
    authentications[prover] = abc;
    return abc;
    }

  function getClientToken(address prover) public view returns (uint) {
    return authentications[prover];
  }
}