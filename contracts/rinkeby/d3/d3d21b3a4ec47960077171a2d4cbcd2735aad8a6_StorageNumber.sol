/**
 *Submitted for verification at Etherscan.io on 2021-10-02
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

contract StorageNumber {

    mapping(address => uint256) addressNumber;
    
      address[] public people;
        
        // function that controlls if the address already exist 
        // return true if exist else false
      function controllIfExist(address _sender) internal view returns(bool){
          
          for(uint i= 0;i<people.length;i++){
              if(_sender == people[i]){
                  return true;
              }
          }
          return false;
      }
    // stores the number to the msg.sender
    function fill(uint256 _Number) public {
        
        addressNumber[msg.sender] = _Number;
        if(!controllIfExist(msg.sender)){
        people.push(msg.sender);
        }
    }
    // print the number only if you have it 
    function numberPrint() public view returns(uint256){
       require(controllIfExist(msg.sender),"you don't have a number stored yet");
       return addressNumber[msg.sender];
    }
 
}