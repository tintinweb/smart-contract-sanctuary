/**
 *Submitted for verification at Etherscan.io on 2021-10-22
*/

pragma solidity ^0.7.0;

contract testCounter{
    uint public allcounter = 0;
    address public address_now;
    uint public nosamecounter = 0;
    
    function vote() public{
        if (address_now == msg.sender){
            allcounter++;
        }
        else {
            nosamecounter++;
            allcounter++;
            address_now = msg.sender;
        }
        
    } 
    
    function getcounter() public view returns(uint _allCounter){
        _allCounter = allcounter;
        return _allCounter;
    }
    
    function getnosamecounter()public view returns(uint){
        return nosamecounter;
    }
    
    
    function getaddress_now() public view returns(address){
        return address_now;
    }
    
}