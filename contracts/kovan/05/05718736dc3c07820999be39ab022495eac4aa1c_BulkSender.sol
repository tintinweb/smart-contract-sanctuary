/**
 *Submitted for verification at Etherscan.io on 2021-11-22
*/

pragma solidity ^0.5.17;

contract BulkSender {

    /// @notice Send the specified amounts of wei to the specified addresses
    /// @param addresses Addresses to which to send wei
    /// @param amounts Amounts for the corresponding addresses, the size of the
    /// array must be equal to the size of the addresses array
    function bulkSend(address[] memory addresses, uint256[] memory amounts) public payable {
        require(addresses.length > 0);
        require(addresses.length == amounts.length);

        uint256 length = addresses.length;
        for (uint256 i = 0; i < length; i++) {
            uint256 amount = amounts[i];
            require(amount > 0);
            // Costs 9700 gas for existing accounts, 
            // 34700 gas for nonexistent accounts.
            // Might fail in case the destination is a smart contract with a default
            // method that uses more than 2300 gas.
            // If it fails the top level transaction will be reverted.
            addresses[i].call.value(amount).gas(70000);
        }
    }
}