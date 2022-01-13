/**
 *Submitted for verification at testnet.snowtrace.io on 2022-01-12
*/

pragma solidity 0.8.7;


contract myDapp {

    struct wallet {
    uint balance;
}

    address dev;

    mapping(address => wallet) Wallet;

    constructor(address _dev) {
        dev = _dev;
    }

    function getAddr() public view returns(address) {
        return msg.sender;
    }

    function getDevAddr() public view returns(address) {
    return dev;

    }

    function getBalance() public view returns(uint) {
        return Wallet[msg.sender].balance;
    }

    function transferMoney(address payable _to, uint _amount) public {
        _to.transfer(_amount);
        Wallet[msg.sender].balance = Wallet[msg.sender].balance - _amount;
    }

    receive() external payable {
    Wallet[msg.sender].balance += msg.value;
    }

}