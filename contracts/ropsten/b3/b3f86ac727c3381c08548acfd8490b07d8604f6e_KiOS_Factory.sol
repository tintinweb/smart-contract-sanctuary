pragma solidity ^0.4.25;
contract ERC20 {
    function balanceOf(address who) public view returns(uint);
    function transfer(address to, uint value) public returns(bool);
}
contract KiOS {
    function payment() public payable returns(bool);
}
contract Wallet {
    address owner;
    address reference;
    constructor(address _owner, address _reference) public {
        owner = _owner;
        reference = _reference;
    }
    modifier exclusive() {
        require(msg.sender == owner);
        _;
    }
    function getBalance(address token) internal view returns(uint) {
        if (address(0) == token) return address(this).balance;
        else return ERC20(token).balanceOf(address(this));
    }
    function() public payable {
        if (msg.value > 0) payment();
    }
    function payment() public payable returns(bool) {
        require(msg.value > 0);
        return true;
    }
    function pay(address dest, address token, uint value) public exclusive returns(bool) {
        require(dest != address(0) && address(this) != dest);
        require(value > 0 && value <= getBalance(token));
        if (token == address(0)) {
            if (!KiOS(dest).payment.value(value)())
            dest.transfer(value);
        } else {
            if (!ERC20(token).transfer(dest, value))
            revert();
        }
        return true;
    }
}
contract KiOS_Factory {
    address public admin = 0x5b4403a56A90009a0E4dB20dC4aD33BA084c31d8;
    function generate(address _reference) public payable returns(address) {
        if (msg.sender != admin) {
            require(msg.value >= 1 finney);
            if (!KiOS(admin).payment.value(msg.value)()) revert();
        }
        return address(new Wallet(msg.sender, _reference));
    }
}