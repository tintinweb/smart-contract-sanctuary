pragma solidity ^0.4.22;

contract Logger {

    // Allowed withdrawals of previous bids
    mapping(address => uint) pendingReturns;

    // Set to true at the end, disallows any change
    bool ended;

    // Events that will be fired on changes.
    event LogEvent(bytes data);

    /// Fallback function to handle ethereum that was send straight to the contract
    /// Unfortunately we cannot use a referral address this way.
    function() payable public {
        emit LogEvent(msg.data);
    }
}