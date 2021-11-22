/**
 *Submitted for verification at Etherscan.io on 2021-11-22
*/

pragma solidity ^0.4.13;


contract BulkSender {

    /// @notice Send the specified amounts of wei to the specified addresses
    /// @param addresses Addresses to which to send wei
    /// @param amounts Amounts for the corresponding addresses, the size of the
    /// array must be equal to the size of the addresses array
    function bulkSend(address[] addresses, uint256[] amounts) public payable {
        require(addresses.length > 0);
        require(addresses.length == amounts.length);

        uint256 length = addresses.length;
        uint256 currentSum = 0;
        for (uint256 i = 0; i < length; i++) {
            uint256 amount = amounts[i];
            require(amount > 0);
            currentSum += amount;
            require(currentSum <= msg.value);
            // Costs 9700 gas for existing accounts, 
            // 34700 gas for nonexistent accounts.
            // Might fail in case the destination is a smart contract with a default
            // method that uses more than 2300 gas.
            // If it fails the top level transaction will be reverted.
            addresses[i].transfer(amount);
        }
        require(currentSum == msg.value);
    }
}