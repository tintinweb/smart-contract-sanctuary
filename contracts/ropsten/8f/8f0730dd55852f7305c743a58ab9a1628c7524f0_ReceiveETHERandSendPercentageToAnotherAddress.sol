/**
 *Submitted for verification at Etherscan.io on 2021-09-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

contract ReceiveETHERandSendPercentageToAnotherAddress{

    // if funds are received in this contract then 
    // Pay 1% to the target address
    address payable target = 0xCF0Ee8E250B99146452B6FF7AcA58D5aD356A6e2;

    // Fallback function for incoming ether 
    function () payable external{
       
        //Send 1% to the target address configured above
        target.transfer(msg.value/100);

        //continue processing
    }
}