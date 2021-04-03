/**
 *Submitted for verification at Etherscan.io on 2021-04-03
*/

pragma solidity ^0.5.17; // ประกาศเวอร์ชั่นที่จะใช้ version 0.5.17 ล่าสุด

contract Gnoy {
    uint256 s;
    constructor(uint256 init) public { // จะเรียกตอนจะเอา smart contract ไป deploy จะถูกเรียกอัตโนมัติครั้งนึง
        s = init;
    }
    
    function add(uint256 val) public { // ด้านขวาของชื่อเรียก modifier => public private ฯลฯ
        s += val; // ไม่ต้องใส่ this
    }
}