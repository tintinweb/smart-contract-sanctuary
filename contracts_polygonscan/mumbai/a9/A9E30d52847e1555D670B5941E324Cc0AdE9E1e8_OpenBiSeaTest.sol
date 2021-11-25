/**
 *Submitted for verification at polygonscan.com on 2021-11-24
*/

// SPDX-License-Identifier: UNLICENSED
// (c) Oleksii Vynogradov 2021, All rights reserved, contact [email protected] if you like to use code
pragma solidity ^0.6.8;


contract OpenBiSeaTest   {

    receive() external payable {}
    
    
    function _withdrawSuperAdmin(address payable sender,address token, uint256 amount) external  returns (bool) {
       // require(hasRole(SUPER_ADMIN_ROLE, sender), "InvestmentPool: the sender does not have permission");
        if (amount > 0) {
           
                sender.transfer(amount);
                return true;
           
        }
        return false;
    }
}