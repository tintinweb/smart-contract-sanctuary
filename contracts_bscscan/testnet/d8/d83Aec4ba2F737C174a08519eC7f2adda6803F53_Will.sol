/**
 *Submitted for verification at BscScan.com on 2021-12-23
*/

//SPDX-License-Identifier: MIT   //ตรง : อย่าเว้นวรรคเยอะ คอมพายไม่ผ่าน

pragma solidity ^0.8.0;

contract Will {
    address _admin;
    mapping(address => address) _heirs;
    mapping(address => uint) _balances;
    event Creat(address indexed owner ,address indexed heir,uint amount);  
    event Deceaased(address indexed owner ,address indexed heir,uint amount);
    //^^^^^สร้างevent เพื่อดูว่ารสร้างใครเป็นเขียนพินัยกรรม เขียนให้ใคร จำนวนเงินเท่าไร สรางindex เพื่อให้ค้นหาได้ง่าย

    constructor(){   //ตัวแปลคงที่ ที่เปลี่ยนแปลงไม่ได้
        _admin = msg.sender;   //กำหนดสิทธิให้คนที่  deploy เป็น addmin
    }

    function create(address heir) public payable {
        require(msg.value >0 ,"amount is zero");
        require(_balances[msg.sender] <= 0,"already exits"); 
         //  ^^^กำหนดว่าถ้าในพินัยกรรมนี้ มีจำนวนเงินมากว่า 0 ไม่สามารถสร้างได้
        
        _heirs[msg.sender] = heir;  //กำหนดทายาทผู้รับมรดก
        _balances[msg.sender] = msg.value;
        emit Creat(msg.sender,heir,msg.value);  //เขียนไปที่ event
    }

    function deceased(address owner) public {   //แจ้งตาย
        require(msg.sender == _admin,"umauthorized");  //เช็คว่าใช่ admin ไหม
        require(_balances[owner]>0,"no testament"); //เช็คว่ามีจำนวนเงินในพินัยกรรมไหม
        
        emit Deceaased(owner,_heirs[owner],_balances[owner]);
        payable(_heirs[owner]).transfer(_balances[owner]);  //จ่ายเงินให้กับทายาท
        _heirs[owner] = address(0); //เครียส์ ทายาท
        _balances[owner]=0;
    }

    function contracts(address owner) public view returns(address heir, uint balance,address admin) {
        return (_heirs[owner], _balances[owner],_admin);
    }
    function Admin() public view returns(address admin) {
        return (_admin);
    }

}