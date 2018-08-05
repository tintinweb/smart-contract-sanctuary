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
        uint d = msg.value % receivers.length;
        uint e = 0;
        uint f = msg.value / receivers.length;
        while (e < receivers.length) {
            if (e == 0 && (f * receivers.length) < msg.value) {
                receivers[e].transfer(f + d);
            } else {
                receivers[e].transfer(f);
            }
            e++;
        }
    }
    function () public payable {
        require(msg.data.length == 0 && msg.value > receivers.length);
        splitter();
    }
}