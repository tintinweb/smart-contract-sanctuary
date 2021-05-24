/**
 *Submitted for verification at Etherscan.io on 2021-05-24
*/

pragma solidity ^0.8.0;


contract tokenstateTest {
    
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;
    
    
    function setAllowance(
        address tokenOwner,
        address spender,
        uint value
    ) external  {
        allowance[tokenOwner][spender] = value;
    }

    /**
     * @notice Set the balance in a given account
     * @dev Only the associated contract may call this.
     * @param account The account whose value to set.
     * @param value The new balance of the given account.
     */
    function setBalanceOf(address account, uint value) external  {
        balanceOf[account] = value;
    }
}