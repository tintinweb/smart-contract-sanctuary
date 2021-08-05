/**
 *Submitted for verification at Etherscan.io on 2020-05-15
*/

pragma solidity 0.6.4;

/**
 * @title Sending bulk transactions from the whitelisted wallets.
 */
contract BulkSender {

    /**
     * @dev Gets the list of addresses and the list of amounts to make bulk transactions.
     * @param addresses - address[]
     * @param amounts - uint256[]
     */
    function distribute(address[] calldata addresses, uint256[] calldata amounts) external payable  {
        require(addresses.length > 0, "BulkSender: the length of addresses should be greater than zero");
        require(amounts.length == addresses.length, "BulkSender: the length of addresses is not equal the length of amounts");

        for (uint256 i; i < addresses.length; i++) {
            uint256 value = amounts[i];
            require(value > 0, "BulkSender: the value should be greater then zero");
            address payable _to = address(uint160(addresses[i]));
            _to.transfer(value);
        }

        require(address(this).balance == 0, "All received funds must be transfered");
    }

    fallback() external payable {
        revert();
    }
}