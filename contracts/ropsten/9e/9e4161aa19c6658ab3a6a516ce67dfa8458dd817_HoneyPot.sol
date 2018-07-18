pragma solidity 0.4.24;

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