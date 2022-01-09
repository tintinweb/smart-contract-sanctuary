/**
 *Submitted for verification at Etherscan.io on 2022-01-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract MyContract{

// นิยามตัวแปร
// default access modifier เป็น private 
string _name;
uint _balance;

// default constructor 
// การกำหนดค่าเริ่มต้น ผ่าน constuctor 
// constructor จะถูกเรียกใช้งานครั้งเดียวและถูกทำงานอัตโมมัตืในตอนเริ่มต้นรัน smart contract 
constructor(string memory name, uint balance){
    // require เพื่อตรวจสอบเงื่อนไข
    // เปิดบัญชีใหม่ต้องฝากเงิน 500 ขึ้นไป 
    _name = name;
    _balance = balance;
}
// รูปแบบของการ return ค่า -> pure , view 
// ค่าที่ return ทำงานกับ attribute หรือ state จะต้องระุเป็น view   
// ค่าที่ return ทำงานกับ ค่าคงที่จะระบุเป็น pure
function getBalance() public view returns(uint balance){
    return _balance;
}
}