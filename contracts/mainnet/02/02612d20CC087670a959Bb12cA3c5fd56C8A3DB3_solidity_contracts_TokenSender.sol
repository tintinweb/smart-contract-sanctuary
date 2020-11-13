pragma solidity 0.5.17;

/// @dev Interface of sender contract for approveAndCall pattern.
interface TokenSender {
    function approveAndCall(address _spender, uint256 _value, bytes calldata _extraData) external;
}