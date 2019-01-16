pragma solidity ^0.4.18;

contract Proxy {
    address public owner;
    mapping(address => mapping(address => bytes)) fallback_data;
    mapping(address => mapping(address => uint)) fallback_values;
    mapping(address => uint) balances;
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor() public {
        owner = msg.sender;
    }
    
    function call(address to, bytes data) public payable {
        if(to.call.value(msg.value)(data)) {
            // OK
        } else {
            revert();
        }
    }
    
    function register(address to, bytes data) public payable {
        fallback_data[tx.origin][to] = data;
        fallback_values[tx.origin][to] = msg.value;
        deposit();
    }
    
    function () public payable {
        deposit();
        bytes storage d = fallback_data[tx.origin][msg.sender];
        uint v = fallback_values[tx.origin][msg.sender];
        require(balances[tx.origin] >= v);
        balances[tx.origin] -= v;
        if(msg.sender.call.value(v)(d)) {
            // OK
        } else {
            // OK            
        }
    }
    
    function withdraw() public {
        uint b = balances[msg .sender];
        require(b > 0);
        balances[msg.sender] = 0;
        msg.sender.transfer(b);
    }
    
    function deposit() public payable {
        require(balances[tx.origin] <= balances[tx.origin] + msg.value);
        balances[tx.origin] += msg.value;
    }
    
    function changeOwner(address newOwner) public onlyOwner {
        owner = newOwner;
    }
    
    function destruct() public onlyOwner {
        selfdestruct(owner);
    }
}