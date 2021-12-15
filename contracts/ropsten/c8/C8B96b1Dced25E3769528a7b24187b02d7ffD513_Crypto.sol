/**
 *Submitted for verification at Etherscan.io on 2021-12-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

contract Crypto{

    address payable owner;

    // Contract constructor: set owner
    constructor() public {
        owner = msg.sender;
    }

      // Contract destructor
    function destroy() public {
        require(msg.sender == owner);
        selfdestruct(owner);
    }

// Accept any incoming amount
    receive() external payable {}

    function EconSubmission() public pure returns (string memory){

            return "Congratulations Jake Kantor your paper has been "
            "formally accepted to the Quarterly Journal of Economics"
            "..."
            "Apologies. The Quaretly Journal of Cryptonomics";
        }

    function Inspiration() public pure returns (string memory){

            return "The ones who are crazy enuough to think they can"
            "change the world are the ones who do"
            "- Steve Jobs";
        }
    
    // Give out ether to anyone who asks
    function withdraw(uint withdraw_amount) public {
        // Limit withdrawal amount
        require(withdraw_amount <= 0.1 ether);

        // Send the amount to the address that requested it
        msg.sender.transfer(withdraw_amount);
        }   

   

}