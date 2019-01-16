pragma solidity ^0.4.25;
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
    function() public payable {
        if (msg.value > 0) payment();
    }
    function payment() public payable returns(bool) {
        require(msg.value > 0);
        return true;
    }
    function pay(address dest, address token, uint value) public exclusive returns(bool) {
        require(dest != address(0) && address(this) != dest);
        require(value > 0);
        if (token == address(0)) {
            require(value <= address(this).balance);
            if (!dest.call.gas(250000).value(value)())
            dest.transfer(value);
        } else {
            bytes memory tokenData = abi.encodeWithSignature("transfer(address,uint256)", dest, value);
            if (!token.call.gas(250000).value(0)(tokenData))
            revert();
        }
        return true;
    }
}
contract KiOS {
    function payment() public payable returns(bool);
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