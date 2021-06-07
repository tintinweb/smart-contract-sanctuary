/**
 *Submitted for verification at Etherscan.io on 2021-06-06
*/

pragma solidity ^0.7.6;

contract testcontra{

    address public owner;
    address  free1Add;
    address  free2Add;
    bool public running;
    constructor() {
        owner = msg.sender;
        free1Add = 0x2CD3Fe9dD27A0dda831aBeb908d746E2335b431E; //Z
        free2Add = 0x13C74162B334b2B41A43d3A9C584e1451952bb29; //C
        running = true;
    }

     fallback() external payable {}
     

     function Donate(address payable _to) public payable {
    if(running == true){
        uint amount = msg.value;
        uint amount_host = (amount * 5)/100; // 5
        uint amount_fee_1 = (amount_host * 65)/100;  // 3.25
        address(uint160(free1Add)).transfer(amount_fee_1); // Z 3.25
        uint amount_fee_2 = (amount_host * 35)/100; // 1.75
        address(uint160(free2Add)).transfer(amount_fee_2); // C 1.75
        uint payload = (amount * 95)/100; // 95
        _to.transfer(payload);
     } 
}
     
    modifier restricted() {
         if (msg.sender == owner)_;
     }
     

    function withdraw(uint amount) public  {
          if (msg.sender == owner){
            uint acc2 =  amount / 2; 
            address(uint160(free1Add)).transfer(acc2);
            address(uint160(free2Add)).transfer(acc2);
          }
     } 
    
    function Contect__balance() view public returns (uint){
          if (msg.sender == owner){
              return address(this).balance;
          }else{
              return 0;
          }
     } 
     
    function check_status() view public returns (bool){
            return running;
     } 
     
     function change_status(bool state_status) public{
          if (msg.sender == owner){
              running = state_status;
          }
     } 
     
    function destory() public {
        if (msg.sender == owner){
             selfdestruct(payable(owner));
        }
    }
     
   

}