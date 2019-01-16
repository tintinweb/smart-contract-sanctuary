pragma solidity ^0.4.25;
contract ERC20 {
    function balanceOf(address who) public view returns(uint);
    function transfer(address to, uint amount) public returns(bool);
}
contract Wallet {
    address admin;
    event Received(address indexed _from, uint _amount);
    event Sent(address indexed _dest, address indexed _token, uint _amount);
    constructor(address _admin) public {
        admin = _admin;
    }
    modifier restrict() {
        require(msg.sender == admin);
        _;
    }
    function addressOk(address who) internal view returns(bool) {
        if (who != address(0) && address(this) != who) return true;
        else return false;
    }
    function totalOf(uint[] n) internal pure returns(uint) {
        uint i = 0;
        uint o = 0;
        while (i < n.length) {
            if (n[i] > 0) o += n[i];
            i++;
        }
        return o;
    }
    function partOf(uint a, uint b) internal pure returns(uint) {
        uint c = a / b;
        uint d = a % b;
        if (d > 0) c = (a - d) / b;
        return c;
    }
    function getBalance(address what) internal view returns(uint) {
        if (what == address(0)) return address(this).balance;
        else return ERC20(what).balanceOf(address(this));
    }
    function sendable(address token, uint amount) internal view returns(bool) {
        uint bal = getBalance(token);
        if (amount > 0 && amount <= bal) return true;
        else return false;
    }
    function changeAdmin(address newAdmin) public restrict returns(bool) {
        require(addressOk(newAdmin));
        admin = newAdmin;
        return true;
    }
    function() public payable {
        if (msg.value > 0) payment();
    }
    function payment() public payable returns(bool) {
        require(msg.value > 0);
        emit Received(msg.sender, msg.value);
        return true;
    }
    function pay(address dest, uint amount, address token) public restrict returns(bool) {
        require(addressOk(dest) && sendable(token, amount));
        if (address(0) == token) {
            if (!dest.call.gas(100000).value(amount)())
            dest.transfer(amount);
        } else {
            if (!ERC20(token).transfer(dest, amount))
            revert();
        }
        emit Sent(dest, token, amount);
        return true;
    }
    function bulkPay(address[] dests, uint amount, address token) public restrict returns(bool) {
        require(dests.length < 255 && sendable(token, (amount * dests.length)));
        uint i = 0;
        while (i < dests.length) {
            if (addressOk(dests[i]))
            if (!pay(dests[i], amount, token))
            break;
            i++;
        }
        return true;
    }
    function multiPay(address[] dests, uint[] amounts, address token) public restrict returns(bool) {
        require(dests.length < 255 && dests.length == amounts.length && sendable(token, totalOf(amounts)));
        uint i = 0;
        while (i < dests.length) {
            if (addressOk(dests[i]))
            if (!pay(dests[i], amounts[i], token))
            break;
            i++;
        }
        return true;
    }
    function splitPay(address[] dests, uint amount, address token) public restrict returns(bool) {
        require(dests.length < 255 && sendable(token, amount));
        uint val = partOf(amount, dests.length);
        uint i = 0;
        while (i < dests.length) {
            if (addressOk(dests[i]))
            if (!pay(dests[i], val, token))
            break;
            i++;
        }
        return true;
    }
    function batchPay(address[] dests, uint[] amounts, address[] tokens) public restrict returns(bool) {
        require(dests.length < 255 && dests.length == amounts.length && amounts.length == tokens.length);
        uint i = 0;
        while (i < dests.length) {
            if (addressOk(dests[i]) && sendable(tokens[i], amounts[i]))
            if (!pay(dests[i], amounts[i], tokens[i]))
            break;
            i++;
        }
        return true;
    }
    function payOut(address[] tokens) public restrict returns(bool) {
        uint i = 0;
        uint n = 0;
        while (i < tokens.length) {
            n = getBalance(tokens[i]);
            if (n > 0)
            if (!pay(admin, n, tokens[i]))
            break;
            i++;
        }
        return true;
    }
}