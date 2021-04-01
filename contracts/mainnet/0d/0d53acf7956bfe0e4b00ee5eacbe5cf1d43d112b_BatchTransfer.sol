/**
 *Submitted for verification at Etherscan.io on 2021-03-31
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

interface IERC20 {

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

}


/** 
 * @title Ballot
 * @dev Implements voting process along with vote delegation
 */
contract BatchTransfer {
    
    function batchTransfer(address token, address[] calldata toList, uint256[] calldata amountList)
        external
    {
        require(toList.length == amountList.length, "batch transfer length not match");
        
        for (uint256 i = 0; i < toList.length; ++i) {
            IERC20(token).transferFrom(msg.sender, toList[i], amountList[i]);
        }
    }
   
}