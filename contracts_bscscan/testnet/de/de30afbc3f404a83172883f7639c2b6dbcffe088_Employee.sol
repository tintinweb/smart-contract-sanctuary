/**
 *Submitted for verification at BscScan.com on 2021-12-01
*/

//SPDX-License-Identifier:GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
 
 contract Salary{
     uint public data;
     function getData() external view returns(uint) {
         return data;
     }

    function setData(uint _data) external{
        data = _data;
    }
 }

 contract Employee{
     Salary salary;
     constructor(){
         salary = new Salary();
     }

     function getSalary() external view returns (uint){
         return salary.getData();
     }

     function setDalary(uint _data) external{
         salary.setData(_data);
     }

    function getSalaryaddress() external view returns (address){
        return address(salary);
    }

 }