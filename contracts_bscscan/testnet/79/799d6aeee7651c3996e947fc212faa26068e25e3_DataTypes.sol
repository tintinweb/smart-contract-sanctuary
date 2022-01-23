/**
 *Submitted for verification at BscScan.com on 2022-01-23
*/

pragma solidity ^0.5.3;

contract DataTypes {

    address public contract_owner;
    address payable public recipient_address;

    uint public transfer_amount;
    uint public recipient_balance;

    constructor() public {
        contract_owner = msg.sender;
    }

    function transferMoneyEth(address payable _recipient_address) public payable returns(uint) {
        recipient_address = _recipient_address;
        transfer_amount = msg.value;
        recipient_address.transfer(transfer_amount);
        recipient_balance = recipient_address.balance;
        return recipient_balance;
    }
}