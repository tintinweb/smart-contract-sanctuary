pragma solidity ^0.4.24;

contract Books{
    struct Book {
        string name; // 이름
        address cpty_cd1; //당사
        address cpty_cd2; //거래상대방
        bool approve11; // 당사 승인1
        bool approve12; // 당사 승인2
        bool approve21; // 타사 승인1
        bool approve22; // 타사 승인2
        
        bool trade; // 거래 여부
        
        uint unconfirm_rcv_amt;
        uint unconfirm_pay_amt;
        uint pay_amt;
        uint rcv_amt;
        
    }
    mapping(uint => Book) public bookStatus; // 북 정보
    
    event trade(uint code, string name, address cpty_cd1, address cpty_cd2);
    event cf(uint code, address from, address to, uint amt);

    function AddBook(uint code, string name, address cpty_cd) public {
        Book storage b = bookStatus[code];
        
        require(b.trade == false);
        
        b.name = name;
        b.cpty_cd1 = msg.sender;
        b.cpty_cd2 = cpty_cd;
        b.approve11 = false;
        b.approve12 = false;
        b.approve21 = false;
        b.approve22 = false;
        
        b.trade = false;
    }
    
    function Approve(uint code, bool isCheker) public {
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
        
        if ( b.approve12 == true && b.approve22 == true ) {
            b.trade = true;
            emit trade(code, b.name, b.cpty_cd1, b.cpty_cd2);
        }
    }
    
    function cf_request(uint code, uint amt) public {
        Book storage b = bookStatus[code];
        
        require(msg.sender == b.cpty_cd1 || msg.sender == b.cpty_cd2);
        require(b.trade == true);
        
        if (msg.sender == bookStatus[code].cpty_cd1) {
            b.unconfirm_pay_amt = amt;
        } else if (msg.sender == bookStatus[code].cpty_cd2) {
            b.unconfirm_rcv_amt = amt;
        }
    }
    
    function cf_confirm(uint code, uint amt) public {
        Book storage b = bookStatus[code];
        
        require(msg.sender == b.cpty_cd1 || msg.sender == b.cpty_cd2);
        require(b.trade == true);
        require(amt != 0);
        
        if (msg.sender == bookStatus[code].cpty_cd1) {
            require(b.unconfirm_rcv_amt == amt);
            b.unconfirm_rcv_amt = 0;
            b.rcv_amt += amt;
            emit cf(code, bookStatus[code].cpty_cd2, bookStatus[code].cpty_cd1, amt);
        } else if (msg.sender == bookStatus[code].cpty_cd2) {
            require(b.unconfirm_pay_amt == amt);
            b.unconfirm_pay_amt = 0;
            b.pay_amt += amt;
            emit cf(code, bookStatus[code].cpty_cd1, bookStatus[code].cpty_cd2, amt);
        }
    }
 
}