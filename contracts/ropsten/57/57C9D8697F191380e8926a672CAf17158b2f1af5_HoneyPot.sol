pragma solidity 0.4.21;

contract HoneyPot {
    mapping (address => uint) public balances;

    function HoneyPot() payable public {
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