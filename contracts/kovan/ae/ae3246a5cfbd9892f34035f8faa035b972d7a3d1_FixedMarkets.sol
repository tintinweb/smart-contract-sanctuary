/**
 *Submitted for verification at Etherscan.io on 2021-03-24
*/

// SPDX-License-Identifier: AGPL V3.0
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

contract FixedMarkets {
    struct s_borrow
    {
        uint startblock;
        uint period;
        uint fixedRate;
        uint amount;
    }
    
    
    struct s_deposit
    {
        uint startblock;
        uint period;
        uint fixedRate;
        uint amount;
    }
    
    mapping (address => s_borrow[]) internal accountBorrows;

    mapping (address => s_deposit[]) internal accountDeposits;

    function addBorrow(address account) external returns(bool)
    {
        accountBorrows[account].push(s_borrow(1,100,124567,100));
        return true;
    }
    
    function addDeposit(address account) external returns(bool)
    {
        accountDeposits[account].push(s_deposit(1,101,12234567,1100));
        return true;
    }
    
    function getBorrows(address account) external view returns (s_borrow[] memory)
    {
        return accountBorrows[account];
    }
    function getDeposits(address account) external view returns (s_deposit[] memory)
    {
        return accountDeposits[account];
    }
    
}