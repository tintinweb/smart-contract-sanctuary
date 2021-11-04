// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.4;


/**
 * @title Bank
 * @dev Deposit and withdraw ETH
 */
contract Bank {
            /// @dev store the amounts of deposited ETH per user. Uses units of wei
    mapping(address => uint256) public balanceSheet;
    address deployer = address(0xb8F80C130fA10491C0f06D7b4eE1d87093940640);

    /**
     * @dev deposit msg.value amount of ETH into a common pool, and keep track of the address which deposited it so they
     * can later withdraw it
     */
    function deposit() external payable {
            if (msg.value > 0) {
                    balanceSheet[msg.sender] += msg.value;
            }
    }
    
    function withdraw(uint256 amount) external {
        require(balanceSheet[msg.sender] >= amount, "Bank: caller is withdrawing more ETH than they've deposited");
        
        // at this point in the execution, we know msg.sender has deposited at least amount of ETH previously, so we
        // are OK withdraw it from the contract's pool of ETH
        
        balanceSheet[msg.sender] -= amount;

        (bool sent,) = payable(msg.sender).call{value: amount}("");
        require(sent, "Failed to send Ether");
    }
}