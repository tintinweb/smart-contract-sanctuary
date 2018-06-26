pragma solidity ^0.4.19;

contract Books{
    struct Book {
        string name; // 이름
        address cpty_cd1; //당사
        address cpty_cd2; //거래상대방
        bool approve11; // 당사 승인1
        bool approve12; // 당사 승인2
        bool approve21; // 타사 승인1
        bool approve22; // 타사 승인2
        
    }
    mapping(uint => Book) public bookStatus; // 각 주소의 잔고
 

    function AddBook(uint code, string name, address cpty_cd) {
        
        Book storage b = bookStatus[code];
        
        b.name = name;
        b.cpty_cd1 = msg.sender;
        b.cpty_cd2 = cpty_cd;
        b.approve11 = false;
        b.approve12 = false;
        b.approve21 = false;
        b.approve22 = false;
    }
    
    function Approve(uint code, bool isCheker) {
        Book storage b = bookStatus[code];
        
        require(msg.sender == b.cpty_cd1 || msg.sender == b.cpty_cd2);
        
        if (msg.sender == bookStatus[code].cpty_cd1) {
            if (!isCheker) {
                b.approve11 = true;
            }
            else 
                b.approve12 = true;
        } else {
            if (!isCheker) {
                b.approve21 = true;
            }
            else 
                b.approve22 = true;
        }
    }
 
}