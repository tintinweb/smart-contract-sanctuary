//SourceUnit: 2021-06-07-01  TRC10Sender-0.0.1.sol

pragma solidity ^0.6.0;

library TRC10Sender {
    function send(trcToken token, address payable to, uint256 amount)
        external
    {
        to.transferToken(amount, token);
    }
}