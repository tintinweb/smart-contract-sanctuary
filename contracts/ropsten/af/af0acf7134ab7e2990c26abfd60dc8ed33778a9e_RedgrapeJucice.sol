/**
 *Submitted for verification at Etherscan.io on 2021-04-03
*/

pragma solidity ^0.5.17;

contract RedgrapeJucice {
    
    //mapping (uint256 => address) nft;  This is NFT Non-Fungible-Token
    
    //mapping (address => uint) balance; This address balance
    
    //string s;
    
    //gas limit ถ้าเซ็ตค่าต่ำ ถ้าเกินจะไม่สามารถทำธุรกรรมได้
    
    //how to send original code to blockchain verify and publish
    uint256 s;
    
    /*constructor(string name) {
        //This function will be compile by itself once time when deploy
        
        this.s = name; // 
    }*/
    
    constructor(uint256 init) public{
        s = init;
    }
    
    function add(uint256 val) public {
        s += val;
    }
    
}