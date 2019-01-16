pragma solidity ^0.4.18;

contract Proxy {
    address public owner;
    mapping(address => bytes) fallback_data;
    mapping(address => uint) fallback_values;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function changeOwner(address newOwner) public onlyOwner {
        owner = newOwner;
    }

    function destruct() public onlyOwner {
        selfdestruct(owner);
    }

    function call(address to, bytes data) public payable onlyOwner {
        if (to.call.value(msg.value)(data)) {
            // OK
        } else {
            revert();
        }
    }

    function register(address to, bytes data) public payable onlyOwner {
        fallback_data[to] = data;
        fallback_values[to] = msg.value;
    }

    function withdraw() public onlyOwner {
        uint b = address(this).balance;
        require(b > 0);
        owner.transfer(b);
    }

    function() public payable {
        bytes storage d = fallback_data[msg.sender];
        uint v = fallback_values[msg.sender];
        if (msg.sender.call.value(v)(d)) {
            // OK
        } else {
            // OK
        }
    }
}