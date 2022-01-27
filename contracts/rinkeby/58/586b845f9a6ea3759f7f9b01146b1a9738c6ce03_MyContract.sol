/**
 *Submitted for verification at Etherscan.io on 2022-01-27
*/

// SPDX-License-Identifier: MIT  //ต้องใส่ไม่งั้นติด warning
pragma solidity ^0.8.0; //ใส่เพื่อบอกว่าจะใช้ compiler ตั้งแต่ v.0.8.0 ขึ้นมา
contract  MyContract {

    // bool status = false;
   // string public name = "PowerEEx"; // ถ้าไม่ใส่ public คือจะเป้น private โดยอัตโนมัติ
    string _name; 
   // int amount = 0;
    uint _balance;
  

  // เอาไว้กำหนดค่าเร่มต้นของระบบ ใส่ค่าให้ตัวแปร
    constructor(string memory name, uint balance){   //Contructor มีจ่ายค่าแก๊ส
        require(balance > 0, "more than 0");  //กฎเกณฑ์ข้อบังคับ อันนี้คือบังคับให้ balance> 0
        _name = name;
        _balance= balance;
     

    }

    function getBalance() public view returns(uint balance){  //Function view ไม่มีการจ่ายค่าแก๊ส
        return _balance;
    }

    function getfixvalue() public pure returns (int fixvalue) {  //Function view ไม่มีการจ่ายค่าแก๊ส
        return 50000;
    } 

    function deposite(uint amount) public {  //การเปลี่ยนแปลงค่าใน smart contract จะต้องมีการตรวจสอบ หมายความว่าต้องจ่ายค่าแกีส
        _balance+=amount;
        
    }

    function withdraw(uint amount) public {
        _balance-=amount;
        
    }

}