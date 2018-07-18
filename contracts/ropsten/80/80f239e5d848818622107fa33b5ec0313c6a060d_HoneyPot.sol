pragma solidity 0.4.24;

contract HoneyPot {
    mapping (address => uint) public balances;

    constructor() payable public {
        put();
    }

    function put() payable public {
        balances[msg.sender] =+ msg.value;
    }

    function get() public {
        require(msg.sender.call.value(balances[msg.sender])());
        balances[msg.sender] = 0;
    }

    function() private {
        revert();
    }
}