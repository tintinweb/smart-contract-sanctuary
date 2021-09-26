/**
 *Submitted for verification at Etherscan.io on 2021-09-26
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

contract Quote {
    // string ความหมายเหมือน SPSS คือเป็นตัวอักษร ส่วนสีขาวคือชื่อของประเภท (ฟ้า) นั้นๆ
    // this is to kept my favourite quote
    string favoriteQuote;
    
    //internal working code
    //สร้างคำสั่งชื่อ set quote ที่ทุกคน public สามารถเอาไปใช้ได้
    //รับตัวแปรประเภท strinเg โดยเก็บ data ไว้บน memory ไม่ต้องเก็บไว้บน blockchain ตัวแปรชื่อ _quote จะทำงานใน setQuote เท่านั้น
    // ประเภทของข้อมูล (string คือเป็น text) เก็บไว้ใน memory เท่านั้น รับค่าเดียวคือค่า quote เท่านั้น
    // _เป็นการ note เฉยๆ
    // = เป็นการassignment ไม่ได้มีความหมายว่าเท่ากัน เหมือนคณิตศาสตร์
    function setQuote(string memory _quote) public {
        
        favoriteQuote = _quote;
    }

}