/**
 *Submitted for verification at Etherscan.io on 2021-11-11
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//พินัยกรรม
contract Will{
    address _admin;
    mapping(address=>address) _heir;//mapping(เจ้าของพินัยกรรม=>ทายาท)
    mapping(address=>uint) _balances;
    event Create(address indexed owner,address indexed heir,uint amount);//ใส่indexedเพื่อsearchได้
    event Decrease(address indexed owner,address indexed heir,uint amount);
    
    //ฟังก์ชันที่ถูกใช้งานครั้งแรกครั้งเดียว
    constructor(){
        _admin=msg.sender;
    }
    
    //โอนเงินเข้าใส่payableในท้าย function
    function create(address heir) public payable{
        require(msg.value>0,"amount is zero");
        require(_balances[msg.sender]<=0,"already exists");//ไม่ให้สร้างพินัยกรรมซ้ำ
        
        _heir[msg.sender]=heir;
        _balances[msg.sender]=msg.value;
        emit Create(msg.sender,heir,msg.value);
    }
    
    function decrease(address owner) public{
        require(msg.sender==_admin,"unauthorized");
        require(_balances[owner]>0,"no testament");
        
        emit Decrease(owner,_heir[owner],_balances[owner]);
        //transfer เงินใส่payable
        payable(_heir[owner]).transfer(_balances[owner]);
        _heir[owner]=address(0);
        _balances[owner]=0;
    }
    
    function view_contracts(address owner) public view returns(address heir,uint balance){
        return (_heir[owner],_balances[owner]);
    }
}