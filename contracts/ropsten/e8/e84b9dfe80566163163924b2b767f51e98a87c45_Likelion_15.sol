/**
 *Submitted for verification at Etherscan.io on 2021-05-18
*/

//YOUNG DO JANG
pragma solidity 0.8.0;

contract Likelion_15 {
    uint [] transactionlist;
    uint [] floor2;
    uint [] floor3;
    uint [] floor4;
    uint count;
    
    function pushtransaction(uint i) public {
        transactionlist.push(i);
        for(uint i=0; i < transactionlist.length;i++) {
            
        count ++;
        
        }
    }
    
    function setmerkleroot() public  {
        uint a;
        uint b;
        uint c;
        uint d;
        uint e;
        
        if(count==8) {
            for(uint i =1;i<transactionlist.length/2;i++) {
                a = transactionlist[2*i-1];
                b = transactionlist[2*i];
                c = 10*a+b;
                
                floor2.push(c);
            }
            
            for(uint i =1;i<floor2.length/2;i++) {
                a = transactionlist[2*i-1];
                b = transactionlist[2*i];
                c = 100*a+b;
                
                floor3.push(c);
            }
            for(uint i =1;i<floor3.length/2;i++) {
                a = transactionlist[2*i-1];
                b = transactionlist[2*i];
                c = 10000*a+b;
                
                floor4.push(c);
            } //여기까지입니다
            
       }else if(count<8 && count>4 && count%2==0) {
            
            for(uint i =1;i<transactionlist.length/2;i++) {
                a = transactionlist[2*i-1];
                b = transactionlist[2*i];
                c = 10*a+b;
                
                floor2.push(c);
            }
            d = c;
            floor2.push(d);
            
            for(uint i =1;i<count/4;i++) {
                a = transactionlist[2*i-1];
                b = transactionlist[2*i];
                c = 100*a+b;
                
                floor3.push(c);
            }
            for(uint i =1;i<count/8;i++) {
                a = transactionlist[2*i-1];
                b = transactionlist[2*i];
                c = 10000*a+b;
                
                floor4.push(c);
            }
            
        }
        
        
    }
}