/**
 *Submitted for verification at Etherscan.io on 2021-12-01
*/

pragma solidity ^0.8.7;

contract ContractWallet {
    constructor() {

    }

    function send(address payable _receiver, uint amount) public {
        _receiver.transfer(amount);
    }
}