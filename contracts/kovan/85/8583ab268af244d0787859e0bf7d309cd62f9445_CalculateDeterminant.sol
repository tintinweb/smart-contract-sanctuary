//SPDX-License-Identifier:MIT
pragma solidity ^0.8.4;
contract CalculateDeterminant{
  
function getData(bytes memory b)public pure returns(uint32,bytes memory){
    return abi.decode(b,(uint32,bytes));
}
}