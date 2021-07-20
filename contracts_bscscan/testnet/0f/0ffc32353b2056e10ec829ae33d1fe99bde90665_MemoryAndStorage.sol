/**
 *Submitted for verification at BscScan.com on 2021-07-19
*/

pragma solidity ^0.4.24;
contract MemoryAndStorage {

    mapping(address => Userr) _balance;
    
    struct Userr{
         uint balance;
     }

    function receivedEther(uint value) payable external {
        _balance[msg.sender].balance +=  value;//msg.value; 
    }
    
    function getBalanceUserTranserEther() public returns (uint) {
        return _balance[msg.sender].balance;
    } 

}