/**
 *Submitted for verification at Etherscan.io on 2021-04-14
*/

pragma solidity ^0.5.17;

contract RedgrapeJucice {
    
    //mapping (uint256 => address) nft;  This is NFT Non-Fungible-Token
    
    //mapping (address => uint) balance; This address balance
    
    //string s;
    
    //gas limit ถ้าเซ็ตค่าต่ำถ้าเกินจะไม่สามารถทำธุรกรรมได้
    
    //how to send original code to blockchain verify and publish
    string  s; // public auto create function read-only
    
    /*constructor(string name) {
        //This function will be compile by itself once time when deploy
        
        this.s = name; // 
    }*/
    
    address owner;
    
    constructor(string memory init) public{
        s = init;
        owner = msg.sender; //msg.sender is owner who is deploy this smart contract
    }
    
    function add(string memory val) public {
        require(msg.sender == owner);
        s = val; //if set s = 0 gas will be retrieve back
    }
    
    function getMessage() public view returns(string memory) { //Use view for doesn't use gas to view 
        return s;
    }
}