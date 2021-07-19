/**
 *Submitted for verification at Etherscan.io on 2021-07-19
*/

pragma solidity ^0.8.4;

/// @notice Reverts all methods with message 'STUB_NOT_CALLABLE'
contract RevertAllStub {
    fallback() external payable {
        revert("STUB_NOT_CALLABLE");
    }
}