/**
 *Submitted for verification at Etherscan.io on 2021-06-15
*/

pragma solidity ^0.5.8;

contract MockContract {
    function transfer(address payable _reciver, uint amount) payable public {
        _reciver.transfer(amount);
    }
}