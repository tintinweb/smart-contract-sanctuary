pragma solidity ^0.4.25;
contract ERC20 {
    function balanceOf(address who) public view returns(uint);
    function transfer(address to, uint amount) public returns(bool);
}
contract Wallet {
    address admin;
    event AdminChanged(address indexed oldAdmin, address indexed newAdmin);
    event Received(address indexed sender, ERC20 indexed token, uint amount);
    event Sent(address indexed recipient, ERC20 indexed token, uint amount);
    constructor(address _admin) public {
        admin = _admin;
    }
    modifier restrict() {
        require(msg.sender == admin, "This method is only for admin!");
        _;
    }
    modifier allow(address who) {
        require(who != address(0) && address(this) != who, "The address cannot be the same as the contract and or zero address!");
        _;
    }
    function isSendable(ERC20 token, uint amount) internal view returns(bool) {
        if (amount > 0 && amount <= getBalance(token)) return true;
        else return false;
    }
    function getBalance(ERC20 token) public view returns(uint) {
        if (token == ERC20(0)) return address(this).balance;
        else return token.balanceOf(address(this));
    }
    function changeAdmin(address newAdmin) public restrict allow(newAdmin) returns(bool) {
        admin = newAdmin;
        emit AdminChanged(msg.sender, newAdmin);
        return true;
    }
    function() public payable {
        if (msg.value > 0) receive();
    }
    function receive() public payable returns(bool) {
        require(msg.value > 0, "The transaction value must be more than zero!");
        emit Received(msg.sender, ERC20(0), msg.value);
        return true;
    }
    function sendTo(address recipient, ERC20 token, uint amount) public restrict allow(recipient) returns(bool) {
        require(isSendable(token, amount), "Insufficient balance!");
        require(ERC20(recipient) != token, "The recipient&#39;s address cannot be the same as the token address!");
        if (ERC20(0) == token) recipient.transfer(amount);
        else if (!token.transfer(recipient, amount)) revert();
        emit Sent(recipient, token, amount);
        return true;
    }
}