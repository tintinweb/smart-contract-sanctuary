// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

import "IERC20.sol";

import "IBank.sol";
import "IPriceOracle.sol";

contract Bank is IBank{

    mapping(address => Account) etherAccounts;
    mapping(address => Account) hakAccounts;
    mapping(address => Account) borrowed;
    
    address private PriceOracle = 0xc3F639B8a6831ff50aD8113B438E2Ef873845552;
    address private HAK = 0xBefeeD4CB8c6DD190793b1c97B72B60272f3EA6C;
    
    address private ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

     constructor(address _PriceOracle, address _HAK) {
         PriceOracle = _PriceOracle;
         HAK = _HAK;
     }

    function call_oracle(address token) private view returns (uint256) {
        return IPriceOracle(PriceOracle).getVirtualPrice(token);
    }
    
    function helper_collateral(address token, address account) private view returns (uint256) {
            if (token != ETH || borrowed[account].deposit + borrowed[account].interest == 0) {
            return type(uint256).max;
        }
        return (hakAccounts[account].deposit + hakAccounts[account].interest)* 10000 / (borrowed[account].deposit + borrowed[account].interest);
    }


    function calc_interest(Account storage user) private {
        user.interest += uint256(uint256(block.number - user.lastInterestBlock) * user.deposit) / 3333;
        user.lastInterestBlock = block.number;
    }
    
    function calc_temp_interest(Account memory user) private view returns (uint256){
        return (((block.number - user.lastInterestBlock) * user.deposit) / 3333);
    }

    function deposit(address token, uint256 amount) override payable external returns (bool) {
        
        if (amount == 0) {
            revert();
        }
        if(token == HAK){
            if(!IERC20(token).transferFrom(msg.sender, address(this), amount)){
                revert();
            }
            Account storage account = hakAccounts[msg.sender];
            calc_interest(account);
            account.deposit += amount;
        }else if (token == ETH){
            Account storage account = etherAccounts[msg.sender];
            calc_interest(account);
            account.deposit += amount;
        }else{
            revert("token not supported");
        }

        emit Deposit(msg.sender, token, amount);
        return true;
    }
    
    function withdraw(address token, uint256 amount) override external returns (uint256) {
        
        //Interest missing
        
        if (token == ETH){
            Account storage account = etherAccounts[msg.sender];
            calc_interest(account);
            if(account.deposit == 0){
                revert("no balance");
            }
            if (amount > account.deposit){
                revert("amount exceeds balance");
            }else if (amount == 0){
                uint256 result = account.deposit + account.interest;
                msg.sender.transfer(result);
                
                emit Withdraw(msg.sender, token, result);
                
                account.deposit = 0;
                account.interest = 0;
                
                return result;
            }else{
                uint256 result = amount + account.interest;
                msg.sender.transfer(result);
                
                emit Withdraw(msg.sender, token, result);
                
                account.deposit -= amount;
                account.interest = 0;
                
                return result;
            }

        }else if (token == HAK) {
            Account storage account = hakAccounts[msg.sender];
            calc_interest(account);
            if(account.deposit == 0){
                revert("no balance");
            }
            if (amount > account.deposit){
                revert("amount exceeds balance");
            }else if (amount == 0){
                uint256 result = account.deposit + account.interest;
                if(!IERC20(token).transfer(msg.sender, result)){
                    revert();
                }
                
                emit Withdraw(msg.sender, token, result);
                
                account.deposit = 0;
                account.interest = 0;
                
                return result;
            }else{
                uint256 result = amount + account.interest;
                if(!IERC20(token).transfer(msg.sender, result)){
                    revert();
                }
                
                emit Withdraw(msg.sender, token, result);
                account.deposit -= amount;
                account.interest = 0;
                
                return result;
            }
        }else{
            revert("token not supported");
        }
    }
    
    function borrow(address token, uint256 amount) override external returns (uint256) {

        //TODO: CHECK if We can go bankrupt
        
        if (token == ETH) {
            if (hakAccounts[msg.sender].deposit + hakAccounts[msg.sender].interest == 0) {
                revert("no collateral deposited");
            }
            if (amount==0) {
                //etherAccounts[account].deposit * 10000 / borrowed[account]
                // x = (etherAccounts[account].deposit * 10000 / max(15000))-borrowed[account]
                uint256 x = ((etherAccounts[msg.sender].deposit + etherAccounts[msg.sender].interest) * 10000 / 15000 ) - (borrowed[msg.sender].deposit + borrowed[msg.sender].interest);
                if (x<=0) {
                    revert("msg.value < amount to repay");
                }
                msg.sender.transfer(x);
                emit Borrow(msg.sender, token, x, helper_collateral(token, msg.sender));
            }
            if (helper_collateral(token, msg.sender) >=15000) {
                borrowed[msg.sender].deposit += amount;
                msg.sender.transfer(amount);
                emit Borrow(msg.sender, token, amount, helper_collateral(token, msg.sender)); 
            }
            else {
                revert("borrow would exceed collateral ratio");
            }
        }
        else {
            revert("token not supported");
        }

        return 0;
    }
    
    function repay(address token, uint256 amount) override payable external returns (uint256) {
        //5% 
        if (token == ETH) {
            if (borrowed[msg.sender].deposit == 0) {
                revert ("nothing to repay");
            }else {
                if (helper_collateral(token, msg.sender)<15000) {
                    revert("msg.value < amount to repay");
                }
                if (borrowed[msg.sender].interest - amount<0){
                    uint256 rest =  amount - borrowed[msg.sender].interest;
                    borrowed[msg.sender].deposit -= rest;
                }else {
                    borrowed[msg.sender].interest -= amount;
                }
                IERC20(token).transferFrom(msg.sender, address(this), amount);
            }
        } else {
            revert ("token not supported");
        }
        return 0;
    }
    
    function liquidate(address token, address account) override payable external returns (bool) {
  //5% 
        if (token == ETH) {
            if (borrowed[msg.sender].deposit == 0) {
                revert ("token not supported");
            }else {
                if (helper_collateral(token, msg.sender)<15000) {
                    revert("msg.value < amount to repay");
                }
                if (borrowed[msg.sender].interest + borrowed[msg.sender].deposit - msg.value==0)
                IERC20(token).transferFrom(msg.sender, account, borrowed[msg.sender].interest + borrowed[msg.sender].deposit);
                return true;
                }
        } else {
            revert ("token not supported");
        }
    }
    
    function getCollateralRatio(address token, address account) override view external returns (uint256){
        return helper_collateral(token, account);
    }
    
    function getBalance(address token) override view external returns (uint256){
        // ether = ETH
        if (token == ETH) {
            Account storage account = etherAccounts[msg.sender];
            return account.deposit + calc_temp_interest(account);
        }else if (token == HAK){
            Account storage account = hakAccounts[msg.sender];
            return account.deposit + calc_temp_interest(account);
        }else{
            revert("token not supported");
        }
    }
}