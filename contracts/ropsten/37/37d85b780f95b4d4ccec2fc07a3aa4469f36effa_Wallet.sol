pragma solidity ^0.4.25;
contract Wallet {
    address admin;
    constructor() public {
        admin = msg.sender;
    }
    modifier adminOnly() {
        require(msg.sender == admin);
        _;
    }
    function addressOk(address addr) internal view returns(bool) {
        if (addr != address(0) && address(this) != addr) return true;
        else return false;
    }
    function transferable(uint i) internal view returns(bool) {
        if (i > 0 && i <= address(this).balance) return true;
        else return false;
    }
    function changeAdmin(address newAdmin) public adminOnly returns(bool) {
        require(addressOk(newAdmin));
        admin = newAdmin;
        return true;
    }
    function() public payable {
        require(msg.data.length == 0 && msg.value > 0);
        admin.transfer(msg.value);
    }
    function payment() public payable returns(bool) {
        require(msg.value > 0);
        return true;
    }
    function pay(address dest, uint amount) public adminOnly returns(bool) {
        require(addressOk(dest) && transferable(amount));
        dest.transfer(amount);
        return true;
    }
    function bulkPay(address[] dests, uint amount) public adminOnly returns(bool) {
        require(dests.length < 255 && transferable(dests.length * amount));
        uint i = 0;
        while (i < dests.length) {
            if (addressOk(dests[i]))
            dests[i].transfer(amount);
            i++;
        }
        return true;
    }
    function multiPay(address[] dests, uint[] amounts) public adminOnly returns(bool) {
        require(dests.length == amounts.length && dests.length < 255);
        uint i = 0;
        while (i < dests.length) {
            if (addressOk(dests[i]) && transferable(amounts[i]))
            dests[i].transfer(amounts[i]);
            i++;
        }
        return true;
    }
    function splitPay(address[] dests, uint amount) public adminOnly returns(bool) {
        require(dests.length < 255 && transferable(amount));
        uint a = amount % dests.length;
        uint b = amount / dests.length;
        if (a > 0) b = (amount - a) / dests.length;
        uint i = 0;
        while (i < dests.length) {
            if (addressOk(dests[i]))
            dests[i].transfer(b);
            i++;
        }
        return true;
    }
}