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
}