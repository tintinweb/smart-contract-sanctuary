/**
 *Submitted for verification at Etherscan.io on 2022-01-25
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract propertyTransfer{

struct owner{
  uint area;
  uint value;
  string name;
  string  location;

}

mapping (uint => owner)public list;


function setowner(uint _key,uint _area,uint _value, string memory _name, string memory _location)public{

  list[_key].area=_area;

  list[_key].value=_value;

  list[_key].name=_name;

  list[_key].location =_location;
  }
  

  function readDetials (uint _key)public view returns(uint,uint, string memory,string memory ){
  
  return(list[_key].area,list[_key].value,list[_key].name,list[_key].location);
        
   }}