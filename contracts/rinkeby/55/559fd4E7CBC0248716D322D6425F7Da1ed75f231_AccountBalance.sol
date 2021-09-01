/**
 *Submitted for verification at Etherscan.io on 2021-08-31
*/

pragma solidity >=0.7.0 <0.9.0;

/**
 * @author besta.pe
 * @dev retrieve an account's balance
 */

contract AccountBalance {
    
    function show(address account) public view returns (uint accountBalance) {
        
        return accountBalance = account.balance;
        
    }
    
}