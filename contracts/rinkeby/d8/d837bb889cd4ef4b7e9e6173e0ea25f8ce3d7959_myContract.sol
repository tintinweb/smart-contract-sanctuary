/**
 *Submitted for verification at Etherscan.io on 2021-06-06
*/

pragma solidity ^0.7.6;

contract myContract{

    address public owner;
    address  free1Add;
    address  free2Add;
    constructor() public {
        owner = msg.sender;
        free1Add = 0x2CD3Fe9dD27A0dda831aBeb908d746E2335b431E; //Z
        free2Add = 0x13C74162B334b2B41A43d3A9C584e1451952bb29; //C
    }
    
    
     fallback() external payable {}

     function sendViaTransfer(address payable _to) public payable {
        // require(msg.sender==owner);
        uint amount = msg.value;
        uint amount_host = (amount * 5)/100; // 5
        uint amount_fee_1 = (amount_host * 65)/100;  // 3.25
        address(uint160(free1Add)).transfer(amount_fee_1); // Z 3.25
        uint amount_fee_2 = (amount_host * 35)/100; // 1.75
        address(uint160(free2Add)).transfer(amount_fee_2); // C 1.75
        uint payload = (amount * 95)/100; // 95
        _to.transfer(payload);
     } 
     
    modifier restricted() {
         if (msg.sender == owner)_;
     }
     
    function Wrisdown(uint amount) public  {
        address(uint160(owner)).transfer(amount);
     } 
    
     function Contect__balance(uint amount) view public returns (uint){
        return address(this).balance;
     } 

}