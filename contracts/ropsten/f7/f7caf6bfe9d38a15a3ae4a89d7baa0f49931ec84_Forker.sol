pragma solidity ^0.4.24;
contract ForkWallet {
    address public unforked;
    constructor(address _unforked) public {
        unforked = _unforked;
    }
    function () public payable {}
    function sendToken(address tokenAddress, address to, uint amount, uint gasLimit) public returns(bool) {
        require(msg.sender == unforked && tokenAddress != address(0));
        require(to != address(0) && address(this) != to);
        require(amount > 0);
        bytes16 araw = bytes16(bytes4(keccak256("transfer(address,uint256)")));
        bytes memory a = abi.encodePacked(araw, to, amount);
        if (!tokenAddress.call.gas(gasLimit).value(0)(a)) return false;
        else return true;
    }
    function sendEther(address to, uint amount, uint gasLimit) public returns(bool) {
        require(msg.sender == unforked);
        require(to != address(0) && address(this) != to);
        require(amount > 0 && amount <= address(this).balance);
        if (!to.call.gas(gasLimit).value(amount)()) to.transfer(amount);
        return true;
    }
    function changeUnforked(address newUnforked) public returns(bool) {
        require(msg.sender == unforked);
        require(newUnforked != address(0) && address(this) != newUnforked);
        unforked = newUnforked;
        return true;
    }
}
contract Forker {
    function forkThis() public returns(address) {
        return address(new ForkWallet(msg.sender));
    }
}