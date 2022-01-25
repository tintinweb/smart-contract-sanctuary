/**
 *Submitted for verification at Etherscan.io on 2022-01-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract MyContract {

//นิยามตัวแปร
/*
โครงสร้างการนิยามตัวแปร
type access_modifier(private) name;
*/
bool status = false;
//นิยมใช้เพมื่อเป็น private _ตัวแปร
string _name;
int _amount = 0;
uint _balance; //นิยมนิยามแค่ชื่อ ไม่ต้องใส่ค่าก่อน

constructor(string memory name, uint balance) {
    //ตรวจสอบค่าเริ่มต้น
    require(balance >=500, "balance greter or equal 500thb");
    //insert ค่าตัวแปร จาก cons ที่รับ
    _name = name;
    _balance = balance;
}
//view = อ่านข้อมูลจาก smart contact ไม่ต้องจ่ายค่า gas
function getBalance() public view returns(uint balance){
    return _balance;
}

//pure return ค่าเป็นค่าคงที่ ไม่ต้องจ่ายค่า gas
// function getBalance2() public pure returns(uint balance){
//     return 50;
// }

// function deposite(uint amount) public {
//     _balance+=amount;
// }


}