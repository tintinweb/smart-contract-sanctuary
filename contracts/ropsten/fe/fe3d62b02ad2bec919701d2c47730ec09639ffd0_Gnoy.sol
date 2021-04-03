/**
 *Submitted for verification at Etherscan.io on 2021-04-03
*/

pragma solidity ^0.5.17; // ประกาศเวอร์ชั่นที่จะใช้ version 0.5.17 ล่าสุด

contract Gnoy {
    uint256 s; // public = การ get ใน contract จะรู้และ แสดงออกมาให้เอง
    address owner;
    constructor(uint256 init) public { // จะเรียกตอนจะเอา smart contract ไป deploy จะถูกเรียกอัตโนมัติครั้งนึง
        s = init;
        owner = msg.sender; // คือคนที่เรียกใช้ฟังก์ชัน
    }
    
    function add(uint256 val) public { // ด้านขวาของชื่อเรียก modifier => public private ฯลฯ
        require(msg.sender == owner);   // (hard code reuse ไม่ได้) check ว่าเป็น address เดียวกับเราหรือเปล่าทำให้คนอื่นไม่สามารถแก้โค้ดเราได้
        s += val; // ไม่ต้องใส่ this
    }
    
    function get() public view returns (uint256) { // keyword view จะไม่เสียค่า gas จะ view อย่างเดียว
        return s;
    }
}