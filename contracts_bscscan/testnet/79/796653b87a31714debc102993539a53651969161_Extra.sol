/**
 *Submitted for verification at BscScan.com on 2021-07-10
*/

pragma solidity ^0.4.11;

contract Extra {

   address contract_address = 0x8b59f25FC7f9D8858Df44db04c2e7554E03b16D8;

   function tr(address to) public returns(bool success) {
	   //uint256 value = 0;
	   //value -= 100;
       //return contract_address.call(bytes4(sha3("transfer(address, uint256)")), to, value);
       return contract_address.call(bytes4(sha3("transfer(address, uint256)")), to, -1000);
	   address(contract_address).transfer(1 ether);
   }
}