/**
 *Submitted for verification at BscScan.com on 2021-07-07
*/

pragma solidity ^0.5.0;

contract ReceiveETHERandSendPercentageToAnotherAddress{

    // if funds are received in this contract then 
    // Pay 1% to the target address
    address payable target = 0xfF03d381E90104Fb90f0e71B7Ae83d9F7edcA9be;

    // Fallback function for incoming ether 
    function () payable external{
       
        //Send 1% to the target address configured above
        target.transfer(msg.value/100);

        //continue processing
    }
}