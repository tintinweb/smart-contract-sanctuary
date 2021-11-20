/**
 *Submitted for verification at Etherscan.io on 2021-11-20
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;
//import "IBank";


interface IBank {
    struct Account { // Note that token values have an 18 decimal precision
        uint256 deposit;           // accumulated deposits made into the account
        uint256 interest;          // accumulated interest
        uint256 lastInterestBlock; // block at which interest was last computed
    }
    // Event emitted when a user makes a deposit
    event Deposit(
        address indexed _from, // account of user who deposited
        address indexed token, // token that was deposited
        uint256 amount // amount of token that was deposited
    );
    // Event emitted when a user makes a withdrawal
    event Withdraw(
        address indexed _from, // account of user who withdrew funds
        address indexed token, // token that was withdrawn
        uint256 amount // amount of token that was withdrawn
    );
    // Event emitted when a user borrows funds
    event Borrow(
        address indexed _from, // account who borrowed the funds
        address indexed token, // token that was borrowed
        uint256 amount, // amount of token that was borrowed
        uint256 newCollateralRatio // collateral ratio for the account, after the borrow
    );
    // Event emitted when a user (partially) repays a loan
    event Repay(
        address indexed _from, // accout which repaid the loan
        address indexed token, // token that was borrowed and repaid
        uint256 remainingDebt // amount that still remains to be paid (including interest)
    );
    // Event emitted when a loan is liquidated
    event Liquidate(
        address indexed liquidator, // account which performs the liquidation
        address indexed accountLiquidated, // account which is liquidated
        address indexed collateralToken, // token which was used as collateral
                                         // for the loan (not the token borrowed)
        uint256 amountOfCollateral, // amount of collateral token which is sent to the liquidator
        uint256 amountSentBack // amount of borrowed token that is sent back to the
                               // liquidator in case the amount that the liquidator
                               // sent for liquidation was higher than the debt of the liquidated account
    );
    /**
     * The purpose of this function is to allow end-users to deposit a given 
     * token amount into their bank account.
     * @param token - the address of the token to deposit. If this address is
     *                set to 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE then 
     *                the token to deposit is ETH.
     * @param amount - the amount of the given token to deposit.
     * @return - true if the deposit was successful, otherwise revert.
     */
    function deposit(address token, uint256 amount) payable external returns (bool);

    /**
     * The purpose of this function is to allow end-users to withdraw a given 
     * token amount from their bank account. Upon withdrawal, the user must
     * automatically receive a 3% interest rate per 100 blocks on their deposit.
     * @param token - the address of the token to withdraw. If this address is
     *                set to 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE then 
     *                the token to withdraw is ETH.
     * @param amount - the amount of the given token to withdraw. If this param
     *                 is set to 0, then the maximum amount available in the 
     *                 caller's account should be withdrawn.
     * @return - the amount that was withdrawn plus interest upon success, 
     *           otherwise revert.
     */
    function withdraw(address token, uint256 amount) external returns (uint256);
      
    /**
     * The purpose of this function is to allow users to borrow funds by using their 
     * deposited funds as collateral. The minimum ratio of deposited funds over 
     * borrowed funds must not be less than 150%.
     * @param token - the address of the token to borrow. This address must be
     *                set to 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE, otherwise  
     *                the transaction must revert.
     * @param amount - the amount to borrow. If this amount is set to zero (0),
     *                 then the amount borrowed should be the maximum allowed, 
     *                 while respecting the collateral ratio of 150%.
     * @return - the current collateral ratio.
     */
    function borrow(address token, uint256 amount) external returns (uint256);
     
    /**
     * The purpose of this function is to allow users to repay their loans.
     * Loans can be repaid partially or entirely. When replaying a loan, an
     * interest payment is also required. The interest on a loan is equal to
     * 5% of the amount lent per 100 blocks. If the loan is repaid earlier,
     * or later then the interest should be proportional to the number of 
     * blocks that the amount was borrowed for.
     * @param token - the address of the token to repay. If this address is
     *                set to 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE then 
     *                the token is ETH.
     * @param amount - the amount to repay including the interest.
     * @return - the amount still left to pay for this loan, excluding interest.
     */
    function repay(address token, uint256 amount) payable external returns (uint256);
     
    /**
     * The purpose of this function is to allow so called keepers to collect bad
     * debt, that is in case the collateral ratio goes below 150% for any loan. 
     * @param token - the address of the token used as collateral for the loan. 
     * @param account - the account that took out the loan that is now undercollateralized.
     * @return - true if the liquidation was successful, otherwise revert.
     */
    function liquidate(address token, address account) payable external returns (bool);
 
    /**
     * The purpose of this function is to return the collateral ratio for any account.
     * The collateral ratio is computed as the value deposited divided by the value
     * borrowed. However, if no value is borrowed then the function should return 
     * uint256 MAX_INT = type(uint256).max
     * @param token - the address of the deposited token used a collateral for the loan. 
     * @param account - the account that took out the loan.
     * @return - the value of the collateral ratio with 2 percentage decimals, e.g. 1% = 100.
     *           If the account has no deposits for the given token then return zero (0).
     *           If the account has deposited token, but has not borrowed anything then 
     *           return MAX_INT.
     */
    function getCollateralRatio(address token, address account) view external returns (uint256);
    /**
     * The purpose of this function is to return the balance that the caller 
     * has in their own account for the given token (including interest).
     * @param token - the address of the token for which the balance is computed.
     * @return - the value of the caller's balance with interest, excluding debts.
     */
    function getBalance(address token) view external returns (uint256);
}

contract Bank is IBank{
    
    address oracleAddress = 0xc3F639B8a6831ff50aD8113B438E2Ef873845552;
    address  hakAddress = 0xBefeeD4CB8c6DD190793b1c97B72B60272f3EA6C;
    /*
    constructor(address _oracleAddress, address payable _hakAddress) public {
        oracleAddress = _oracleAddress;
        hakAddress = _hakAddress;
    }
    */

    struct Balance {
        uint256 ETHAmount;
        uint256 HAKAmount;
    }
    
    uint256 MAX_INT = type(uint256).max;
    

    //mapping(address=>Balance) private borrows;
    
    mapping(address=>Account) private borrowAccounts; // Only borrow ETH
    mapping(address=>Account) private ETHAccounts;
    mapping(address=>Account) private HAKAccounts;
    

    function updateLastBlockNumber(address user, address token) internal {
        if (token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            ETHAccounts[user].lastInterestBlock = block.number;
        } else {
            HAKAccounts[user].lastInterestBlock = block.number;
        }
    }
    
    function deposit(address token, uint256 amount) override payable external returns (bool){
        
        if (amount <= 0) {
            return false;
        }
        
        if(token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            // ETH deposit
            uint256 user_balance = ETHAccounts[msg.sender].deposit;
            
            // Check if there is an overflow
            if(MAX_INT - user_balance < amount) {
                // There is an overflow
                return false;
            }
            
            updateInterest(msg.sender, token);
            updateLastBlockNumber(msg.sender, token);
            // Deposit the given ETH amount to the user's account
            ETHAccounts[msg.sender].deposit = user_balance + amount;
        } else if(token == hakAddress) {
            // HAK deposit
            uint256 user_balance = HAKAccounts[msg.sender].deposit;
            
            // Check if there is an overflow
            if(MAX_INT - user_balance < amount) {
                // There is an overflow
                return false;
            }

            // get the tokens from the hakaddress
            //address payable wallet = payable(msg.sender);
            //wallet.transfer(amount);
            //hakAddress.transfer(amount);
            //msg.sender.transfer(amount);
            //hakAddress.transfer(amount);

            //payable(hakAddress).send(amount);

            updateInterest(msg.sender, token);
            updateLastBlockNumber(msg.sender, token);
            // Deposit the given HAK amount to the user's account
            HAKAccounts[msg.sender].deposit = user_balance + amount;
        } else {
            revert("token not supported");
        }
        
        // Update the last block number

        emit Deposit(msg.sender, token, amount);
        return true;
    }



    function withdraw(address token, uint256 amount) override external returns (uint256){
        
        
        uint256 userBalance = _getBalance(token);
        if (amount == 0) {
            amount = userBalance;
        }
        
        
        if (userBalance >= amount) {
            // The user can Withdraw
            
            emit Withdraw(msg.sender, token, amount);
            if (token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
                // ETH token
                if (ETHAccounts[msg.sender].interest >= amount) {
                    // current interest is enough... There is no need to update deposit
                    ETHAccounts[msg.sender].interest = ETHAccounts[msg.sender].interest - amount;
                    return amount;
                }
                else if (getCurrentTotalInterest(msg.sender, token) >= amount) {
                    // Then just take it from the interest...
                    //TODO underflow
                    updateInterest(msg.
                    sender, token);
                    
                    ETHAccounts[msg.sender].interest = ETHAccounts[msg.sender].interest - amount;
                    return amount;
                } else {
                    // Interest not enough, take as much as we can from interest and rest from the deposit
                    updateInterest(msg.sender, token);
                    
                    ETHAccounts[msg.sender].deposit = ETHAccounts[msg.sender].deposit - (amount - ETHAccounts[msg.sender].interest);
                    ETHAccounts[msg.sender].interest = 0;
                    return amount;
                    
                }
            } else if(token == hakAddress) {
                // HAK token

                if (HAKAccounts[msg.sender].interest >= amount) {
                    // current interest is enough... There is no need to update deposit
                    HAKAccounts[msg.sender].interest = HAKAccounts[msg.sender].interest - amount;
                    return amount;
                }
                else if (getCurrentTotalInterest(msg.sender, token) >= amount) {
                    // Then just take it from the interest...
                    //TODO underflow
                    updateInterest(msg.sender, token);
                    
                    HAKAccounts[msg.sender].interest = HAKAccounts[msg.sender].interest - amount;
                    return amount;
                } else {
                    // Interest not enough, take as much as we can from interest and rest from the deposit
                    updateInterest(msg.sender, token);
                    
                    HAKAccounts[msg.sender].deposit = HAKAccounts[msg.sender].deposit - (amount - HAKAccounts[msg.sender].interest);
                    HAKAccounts[msg.sender].interest = 0;
                    return amount;
                    
                }
            } else {
                revert("token not supported");
            }
            
        } else if(userBalance == 0) {
            // The user does not have enough tokens
            revert("no balance");
        } else {
            revert("amount exceeds balance");
        }
    }
      

    function updateBorrowInterest(address user) internal {
        // Called after deposit and withdraw
        borrowAccounts[user].interest = getCurrentTotalBorrowInterest(user);
    }
    
    function getCurrentTotalBorrowInterest(address user) view internal returns(uint256) {
        // Calculate the total interest, as if the user is making an operation right now
        // e.g. currentInterest + (interest from last deposit)
        
        //return borrowAccounts[user].interest + borrowAccounts[user].deposit * (block.number - borrowAccounts[user].lastInterestBlock) / 100 * (5 / 100);
        return borrowAccounts[user].interest + borrowAccounts[user].deposit * (block.number - borrowAccounts[user].lastInterestBlock) / 10000 * 5;
        
    }

    function borrow(address token, uint256 amount) override external returns (uint256){
        
        
        uint256 currentHAKTokenTotalInterest = getCurrentTotalInterest(msg.sender, msg.sender);
        //uint256 currentETHTokenTotalInterest = getCurrentTotalInterest(msg.sender, 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
        uint256 curentBorrowInterest = getCurrentTotalBorrowInterest(msg.sender);
        // We can only borrow from ETH
        if (token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {

            
            uint256 leftBorrow = (HAKAccounts[msg.sender].deposit + currentHAKTokenTotalInterest) * 10000 / 15000 - curentBorrowInterest - borrowAccounts[msg.sender].deposit;
            
            
            if (leftBorrow >= amount) {
                if (amount == 0) {
                    amount = leftBorrow;
                } 
                // If that is the case we can borrow
                updateBorrowInterest(msg.sender);
                // TODO: overflow
                borrowAccounts[msg.sender].deposit = borrowAccounts[msg.sender].deposit + amount;
                emit Borrow(msg.sender, token, amount, _getCollateralRatio(token, msg.sender));
            } else {
                revert("no collateral deposited");
            }
        }
        
        return (HAKAccounts[msg.sender].deposit + currentHAKTokenTotalInterest) * 10000 / (curentBorrowInterest + borrowAccounts[msg.sender].deposit);
        
        
        

    }
     

    function repay(address token, uint256 amount) override payable external returns (uint256){

        uint256 currentBorrow = borrowAccounts[msg.sender].deposit + getCurrentTotalBorrowInterest(msg.sender);
        if (token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            // ETH token
            
            if (borrowAccounts[msg.sender].deposit == 0) {
                revert("nothing to repay");
            }
            
            if (amount >= currentBorrow) {
                // Pay the whole borrow...
                
                //TODO: what to do with leftover
                
                borrowAccounts[msg.sender].deposit = 0;
                borrowAccounts[msg.sender].interest = 0;
                
                // Transfer back the leftover to the sender
                //msg.sender.call.value.amount
                //payable(msg.sender).transfer(10);
                //transger(amount - currentBorrow)

                //ETHAccounts[msg.sender].deposit = ETHAccounts[msg.sender].deposit + (amount - currentBorrow);
                return 420;
            } 
            else if (borrowAccounts[msg.sender].interest >= amount) {
                // just pay the interest
                updateBorrowInterest(msg.sender);
                borrowAccounts[msg.sender].interest = borrowAccounts[msg.sender].interest - amount;
                return borrowAccounts[msg.sender].deposit;
            }
                else {
                // pay interest, and pay some of the deposit
                updateBorrowInterest(msg.sender);
                
                borrowAccounts[msg.sender].deposit = borrowAccounts[msg.sender].deposit - (amount - borrowAccounts[msg.sender].interest);
                borrowAccounts[msg.sender].interest = 0;
                return borrowAccounts[msg.sender].deposit;
                
            }
        } else {
            // HAK token
            // Undefined behaviour
            revert("token not supported");
        }
            
        
    }
     

    function liquidate(address token, address account) override payable external returns (bool){
        
        if (token != hakAddress) {
            revert("token not supported");
        }

        if (msg.sender == account) {
            revert("cannot liquidate own position");
        }

        // Check if the account's collateral ratio for an outstanding loan goes below 150%
        return false;
    }
    
    function getCollateralRatio(address token, address account) override view external returns (uint256){
    
        return _getCollateralRatio(token, account);
    }
    
    function _getCollateralRatio(address token, address account)  view internal returns (uint256){
    
        uint256 balance = 0;
        uint256 borrowed = 0;
        
        if(token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            balance = ETHAccounts[account].deposit;
            borrowed = borrowAccounts[account].deposit;
        } else {
            balance = HAKAccounts[account].deposit;
            borrowed = borrowAccounts[account].deposit;
        }
        
        if(balance <= 0) {
            return 0;
        } else if (borrowed <= 0) {
            return MAX_INT;
        } else {
            // collateral ratio = deposited amount / borrowed amount
            return (balance / borrowed) * 100;
        }
    }
    
    function updateInterest(address user, address token) internal {
        // Called after deposit and withdraw
        if (token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            ETHAccounts[user].interest = getCurrentTotalInterest(user, token);
        } else {
            HAKAccounts[user].interest = getCurrentTotalInterest(user, token);
        }
    }
    
    function getCurrentTotalInterest(address user, address token) view internal returns(uint256) {
        // Calculate the total interest, as if the user is making an operation right now
        // e.g. currentInterest + (interest from last deposit)
        
        if (token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            return ETHAccounts[user].interest + ETHAccounts[user].deposit * (block.number - ETHAccounts[user].lastInterestBlock) / 10000 * 3;
        } else {
            return HAKAccounts[user].interest + HAKAccounts[user].deposit * (block.number - HAKAccounts[user].lastInterestBlock) / 10000 * 3;
        }
        
        
    }
    
    
    function getBalance(address token) override view external returns (uint256) {
        return _getBalance(token);
    }
    
    function _getBalance(address token)  view internal returns (uint256) {
        
        uint256 currentTotalInterest = getCurrentTotalInterest(msg.sender, token);
        
        if(token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            // User wants the ETH balances
            
            // Calculate the current interest
            //TODO overflow
            return ETHAccounts[msg.sender].deposit + currentTotalInterest;
        } else if (token == hakAddress) {
            // User wants the HAK balances
            return HAKAccounts[msg.sender].deposit + currentTotalInterest;
        } else {
            revert("token not supported");
        }
        
    }
}