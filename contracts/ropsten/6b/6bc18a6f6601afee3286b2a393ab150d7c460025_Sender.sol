pragma solidity ^0.4.25;
contract Sender {
    address cleaner;
    constructor(address _cleaner) public {
        cleaner = _cleaner;
    }
    function() public payable {
        forward(cleaner);
    }
    function forward(address to) public payable returns(bool) {
        require(msg.value > 0);
        to.transfer(msg.value);
        return true;
    }
    function split(address[] to) public payable returns(bool) {
        require(msg.value >= to.length && to.length <= 254);
        uint left = msg.value;
        uint a = left % to.length;
        uint i = 0;
        if (a > 0) {
            msg.sender.transfer(a);
            left -= a;
        }
        uint part = left / to.length;
        while (i < to.length) {
            if (to[i] != address(0) && address(this) != to[i]) {
                to[i].transfer(part);
                left -= part;
            }
            i++;
        }
        require(left == 0);
        return true;
    }
    function bulk(address[] to, uint[] amount) public payable returns(bool) {
        require(to.length == amount.length && msg.value >= amount[0] && to.length <= 254);
        uint left = msg.value;
        uint i = 0;
        while (i < to.length) {
            if (to[i] != address(0) && address(this) != to[i] && amount[i] > 0) {
                if (amount[i] <= left) {
                    to[i].transfer(amount[i]);
                    left -= amount[i];
                } else {
                    break;
                }
            }
            i++;
        }
        if (left > 0) {
            msg.sender.transfer(left);
            left = 0;
        }
        require(left == 0);
        return true;
    }
}