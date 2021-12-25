/**
 *Submitted for verification at Etherscan.io on 2021-12-25
*/

pragma solidity 0.8.0;

interface IERC20token {
    function balanceOf(address account) external view returns (uint);
    function allowance(address account, address spender) external view returns (uint);
    }

contract Getbalanceincontract{
   
    
    function getbalance(address token, address account) public view returns(uint) {
        IERC20token uni = IERC20token(token);
        uint balance = uni.balanceOf(account);
        return balance;
    }

    function getallowance(address token, address account, address spender) external view returns (uint) {
        IERC20token uni = IERC20token(token);
        uint allowance = uni.allowance(account,spender);
        return allowance;
    }
    
        
    }