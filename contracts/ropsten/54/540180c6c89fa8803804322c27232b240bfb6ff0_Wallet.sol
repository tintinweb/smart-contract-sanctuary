pragma solidity ^0.4.25;
contract ERC20 {
    function balanceOf(address who) public view returns(uint);
    function transfer(address dest, uint amount) public returns(bool);
}
contract Wallet {
    address public owner;
    event ReceiveEther(address indexed _from, uint _amount);
    event Sent(address indexed destination, address indexed token, uint amount);
    constructor() public {
        owner = msg.sender;
    }
    modifier admin() {
        require(msg.sender == owner);
        _;
    }
    function addressOk(address who) public view returns(bool) {
        if (who != address(0) && address(this) != who) return true;
        else return false;
    }
    function sendable(address token, uint amount) public view returns(bool) {
        uint bal = address(this).balance;
        if (token != address(0)) bal = ERC20(token).balanceOf(address(this));
        if (amount > 0 && amount <= bal) return true;
        else return false;
    }
    function changeOwner(address newOwner) public admin returns(bool) {
        require(addressOk(newOwner));
        owner = newOwner;
        return true;
    }
    function() public payable {}
    function payment() public payable returns(bool) {
        require(msg.value > 0);
        emit ReceiveEther(msg.sender, msg.value);
        return true;
    }
    function sendTo(address dest, uint amount, address token) public admin returns(bool) {
        require(addressOk(dest) && sendable(token, amount));
        if (token == address(0)) {
            if (!dest.call.gas(250000).value(amount)())
            dest.transfer(amount);
        } else {
            if (!ERC20(token).transfer(dest, amount))
            revert();
        }
        emit Sent(dest, token, amount);
        return;
    }
}