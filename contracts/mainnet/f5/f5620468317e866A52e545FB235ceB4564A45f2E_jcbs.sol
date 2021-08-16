pragma solidity ^0.4.21; 
import "./eip.sol"; 
contract jcbs is EIP20{ 

uint public INITIAL_SUPPLY = 5000000000000000000; 
constructor() public EIP20(5000000000000000000,"JACOBS TOKEN",9,"JCBS"){
  } 
}