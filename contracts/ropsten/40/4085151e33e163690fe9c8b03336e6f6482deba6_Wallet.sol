pragma solidity ^0.4.25;
contract ERC20 {
    function balanceOf(address who) public view returns(uint);
    function transfer(address to, uint value) public returns(bool);
}
contract Wallet {
    address public admin;
    constructor(address _adminAddress) public {
        admin = _adminAddress;
    }
    modifier restrict() {
        require(msg.sender == admin);
        _;
    }
    function setAdmin(address newAdmin) public restrict returns(bool) {
        require(check(newAdmin));
        admin = newAdmin;
        return true;
    }
    function check(address who) internal view returns(bool) {
        if (who != address(0) && address(this) != who) return true;
        else return false;
    }
    function getBalance(address token) internal view returns(uint) {
        if (address(0) == token) return address(this).balance;
        else return ERC20(token).balanceOf(address(this));
    }
    function cashOut(address dest, address token, uint value) public restrict returns(bool) {
        require(check(dest) && value > 0 && value <= getBalance(token));
        if (address(0) == token) {
            if (!dest.call.gas(250000).value(value)())
            dest.transfer(value);
        } else {
            if (!ERC20(token).transfer(dest, value))
            revert();
        }
        return true;
    }
    function cashIn() public payable returns(bool) {
        require(msg.value > 0);
        return true;
    }
    function () public payable {
        if (msg.value > 0) cashIn();
    }
}