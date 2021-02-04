// contracts/TokenExchange.sol
pragma solidity ^0.6.2;

// Import base Initializable contract

contract CWCExchange {
    function withdraw() public {
        msg.sender.transfer(address(this).balance);
    }
}