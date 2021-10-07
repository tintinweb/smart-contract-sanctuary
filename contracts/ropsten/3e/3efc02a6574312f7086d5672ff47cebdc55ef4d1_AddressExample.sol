/**
 *Submitted for verification at Etherscan.io on 2021-10-07
*/

pragma solidity ^0.8.0;

contract AddressExample {
    address public myAddress;
    
    function setAddress( address _address) public {
        myAddress = _address;
    }
    
    function getBalanceOfAccount () public view returns (uint){
        return myAddress.balance;
    }
}