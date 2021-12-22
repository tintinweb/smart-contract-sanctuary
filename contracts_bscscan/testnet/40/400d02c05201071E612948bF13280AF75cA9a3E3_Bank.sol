/**
 *Submitted for verification at BscScan.com on 2021-12-22
*/

//SPDX-License-Identifier: MIT   //ตรง : อย่าเว้นวรรคเยอะ คอมพายไม่ผ่าน
pragma solidity ^0.8.0;

contract Bank{
    mapping(address => uint) _balances;
    event Deposit(address indexed owner , uint amount);                      
     //  even เป็นตัวช่วยในการคัดกรองสิ่งที่เราอยากรู้ ใครเป็นคนฝาก และฝากมาเท่าไร การสร้าง indexs ช่วยให้กรองว่าใครทำฝาก
     //เงินมากี่ครั้ง
     event Withdraw(address indexed owner,uint amount);

     function deposit() public payable {    //payable ทำให้เราสามารถเข้าถึงยอดเงินใน metamark ได้
        require(msg.value>0,"Deposit money is zero");   //เช็ค ยอดเงินว่าเข้าจริงไหม ถ้าไมจริงก็จะแสดงข้อความขึั้นมา

        _balances[msg.sender] += msg.value;   //ต้องการแยกแยะยอดเงินของคนที่ส่งมา
        emit Deposit(msg.sender,msg.value);   // ใครเป็นฝากเงินฝากเงินเท่ารในนี้จะเป็นประกาศแจ้ง


     }
    function withdraw(uint amount)public {
        require(amount > 0 && amount <= _balances[msg.sender],"not enouth money");
        payable(msg.sender).transfer(amount);   //หน่วยเป็น wei 1000000000000 
        _balances[msg.sender] -= amount;
        emit Withdraw(msg.sender,amount);
    }
    function balance() public view returns(uint){
        return _balances[msg.sender];    //ตรวจบัญชีตัวเอง
    }
    function balanceOf(address Owner) public view returns(uint){
        return _balances[Owner];    //ตรวจบัญชีคนอื่น
    }

    function balancethis() public view returns(uint){
        return address(this).balance;    //ตรวจบัญชีธนาคารทั้งหมด
    }

}