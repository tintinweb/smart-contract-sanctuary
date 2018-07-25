pragma solidity ^0.4.24;

contract Test {

    address creator;
    uint donate_num;

    function Test() {
        creator = msg.sender;
        donate_num = msg.value;
    }

    function donate() {
        donate_num += msg.value;
    }

    function getBalance() view returns(uint) {
        return this.balance;
    }

    function kill() {
        if (msg.sender == creator) {
            selfdestruct(creator);
        }
    }

}