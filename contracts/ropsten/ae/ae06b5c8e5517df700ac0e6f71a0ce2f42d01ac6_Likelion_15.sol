/**
 *Submitted for verification at Etherscan.io on 2021-05-18
*/

//Seo sangcheol

pragma solidity 0.8.1;

contract Likelion_15 {
    
    string send;
    string rec;
    uint amt;
    
    function tran(string memory a, string memory b, uint c) public returns(string memory, string memory, uint) {
        send = a;
        rec = b;
        amt = c;
        return(send, rec, amt);
    }
    
    function even(uint a, uint b, uint c, uint d, uint e, uint f) public view returns(uint) {
        uint cnt;
        
        if(a%2==0) {
          cnt = cnt+1;
    }
        if(b%2==0) {
          cnt = cnt+1;
    }
    if(c%2==0) {
          cnt = cnt+1;
    }
    if(d%2==0) {
          cnt = cnt+1;
    }
    if(e%2==0) {
          cnt = cnt+1;
    }
    if(f%2==0) {
          cnt = cnt+1;
    }
    return(cnt);
    }
}