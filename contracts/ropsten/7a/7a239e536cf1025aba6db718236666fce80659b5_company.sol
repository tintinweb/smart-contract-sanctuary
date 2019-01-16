pragma solidity ^0.4.25;
 contract company{
    uint empid =0;
    mapping(uint => string ) employlist;
       function setValue(string proName) public {
           empid++;
           employlist [empid] = proName;
           
       }
       function getValue(uint _empid) public view returns (string){
           return employlist[_empid];
       }
      function totalpro()public  view returns(uint){
          return empid;
      }
     
     
 }