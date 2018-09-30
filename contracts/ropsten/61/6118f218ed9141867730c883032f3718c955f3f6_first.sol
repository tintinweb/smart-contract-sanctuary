pragma solidity ^0.4.25;
//import "github.com/oraclize/ethereum-api/oraclizeAPI.sol";
contract first  {
     string public message_rop;
     address public tempaddr;
     uint public bal;
     address public owner;
     address public destinationAddress;
    constructor() public {
        
    }

     function hello(string intialmessage) public{
         message_rop=intialmessage;
     }
     function setmessager(string newmessage) public{
         message_rop=newmessage;
     }
     function setaddress(address newaddress) public{
         destinationAddress=newaddress;
         owner=newaddress;
         //bal = address(tempaddr).balance;
     }
    
    function checkbalance(address rk) public {
        bal = rk.balance/1000000000000000000;
    }
    function send(address _receiver, uint amount) public payable returns (uint256){
        _receiver.transfer(amount);
    }
    function sendeth( uint amount) public payable{
        owner.transfer(amount);
    }
   
    function confirmCollRecv (uint _certNum) 
    public 
    returns (bool) {
        destinationAddress.send(_certNum);
        return true;
    }
    function buyIt() public payable {
        // msg.value is how much ether was sent
        require(msg.value == 2);
    
        // send the ether to "owner"
        owner.transfer(msg.value);
    
        // msg.sender is the new "owner"
        owner = msg.sender;
    }
     
      
}