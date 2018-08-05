pragma solidity ^0.4.24;
contract SplitEther {
    address admin;
    address[] receivers;
    constructor () public {
        admin = msg.sender;
        receivers.push(msg.sender);
    }
    function isAdmin() internal view returns(bool) {
        return (msg.sender == admin);
    }
    function passed(address[] _addr) internal view returns(uint a) {
        uint b = 0;
        a = 0;
        while (b < _addr.length) {
            if (_addr[b] != address(0) && address(this) != _addr[b]) a += 1;
            b++;
        }
        return a;
    }
    function updateReceivers(address[] _recipients) public {
        require(isAdmin());
        require(_recipients.length > 0);
        require(passed(_recipients) == _recipients.length);
        delete(receivers);
        receivers = _recipients;
    }
    function updateAdmin(address _addr) public {
        require(isAdmin());
        require(_addr != address(0) && address(this) != _addr);
        admin = _addr;
    }
    function splitter() public payable {
        uint c = msg.value;
        uint d = msg.value % receivers.length;
        if (d > 0) {
            admin.transfer(d);
            c -= d;
        }
        uint e = 0;
        uint f = c / receivers.length;
        while (e < receivers.length) {
            receivers[e].transfer(f);
            e++;
        }
    }
    function () public payable {
        require(msg.data.length == 0 && msg.value > receivers.length);
        splitter();
    }
}