/**
 *Submitted for verification at BscScan.com on 2021-12-01
*/

//SPDX-License-Identifier:GPL-3.0
pragma solidity >=0.6.12;
 
 contract Salary{
     uint public data;
     function getData() external view returns(uint) {
         return data;
     }

    function setData(uint _data) public {
        data = _data;
    }
 }




 contract Employee{
     Salary salary;
     constructor(){
         salary = new Salary();
     }


    address private _owner;
     address private msgSender;
        function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msgSender, "Ownable: caller is not the owner");
        _;
    }


     function getSalary() external view returns (uint){
         return salary.getData();
     }

     function setDalary(uint _data) external{
         salary.setData(_data);
     }

    function getSalaryaddress() view external  returns (address) {
        return address(salary);
    }

 }