/**
 *Submitted for verification at Etherscan.io on 2021-02-10
*/

pragma solidity ^0.5.0;

contract Arrays {
    
    function airdropByOwner(uint256[] memory _age, uint256[] memory _amount) public returns (bool){
          require(_age.length == _amount.length,"Invalid Array");
          return true;
      }
}