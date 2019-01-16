pragma solidity ^0.4.25;
contract ERC20 {
    function balanceOf(address who) public view returns(uint);
    function transfer(address to, uint value) public returns(bool);
}
contract Wallet {
    address owner;
    bool locked;
    event Received(address indexed _from, ERC20 indexed _token, uint _amount);
    event Sent(address indexed _destination, ERC20 indexed _token, uint amount);
    constructor() public {
        owner = msg.sender;
        locked = true;
    }
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    function isAllowed(address who) internal view returns(bool) {
        if (who != address(0) && address(this) != who)
        return true;
        else
        return false;
    }
    function isSendable(ERC20 token, uint amount) internal view returns(bool) {
        uint bal = address(this).balance;
        if (ERC20(0) != token)
        bal = token.balanceOf(address(this));
        if (amount > 0 && amount <= bal)
        return true;
        else
        return false;
    }
    function changeOwner(address newOwner) public onlyOwner returns(bool) {
        require(isAllowed(newOwner));
        owner = newOwner;
        return true;
    }
    function switchLock(bool lockState) public onlyOwner returns(bool) {
        locked = lockState;
        return true;
    }
    function() public payable {
        if (msg.value > 0) receive();
    }
    function receive() public payable returns(bool) {
        require(msg.value > 0);
        emit Received(msg.sender, ERC20(0), msg.value);
        return true;
    }
    function payment(address dest, uint amount, ERC20 token) public onlyOwner returns(bool) {
        require(!locked && isAllowed(dest) && isSendable(token, amount));
        if (token == address(0))
        dest.transfer(amount);
        else
        if (!token.transfer(dest, amount)) revert();
        emit Sent(dest, token, amount);
        return true;
    }
}