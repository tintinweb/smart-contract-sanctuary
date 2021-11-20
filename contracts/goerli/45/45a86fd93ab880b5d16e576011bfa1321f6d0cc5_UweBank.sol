/**
 *Submitted for verification at Etherscan.io on 2021-11-20
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

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


contract UweBank is IBank {
    address price_orakle;
    address hak_token;
    //address owner;
    
    struct Loan {
        uint256 sum;
        uint256 collateral;
        uint256 interest;
        uint256 lastInterestBlock;
    }
    
    mapping(address => mapping(address => Account)) public accounts;
    mapping(address => mapping(address => Loan)) public loans;

    constructor(address _price_orakle, address _HAK_token) {
        price_orakle = _price_orakle;
        hak_token = _HAK_token;
        //owner = msg.sender;
    }

    function calcLoanInteresst(address from, address token) internal returns (bool success) {
        require(from != address(0));
        if(loans[from][token].lastInterestBlock == 0) { return false; }     
        uint256 interest_temp = (block.number - loans[from][token].lastInterestBlock) * 10e14 * 5;
        loans[from][token].interest += (loans[from][token].sum * interest_temp) / 10e18;
        return true;
    }

    function calcInterest(address from, address token, uint256 percentage) internal returns (bool success) {
        require(from != address(0));
        if(accounts[from][token].lastInterestBlock == 0) { return false; }     
        uint256 interest_temp = (block.number - accounts[from][token].lastInterestBlock) * 10e14 * percentage;
        accounts[from][token].interest += (accounts[from][token].deposit * interest_temp) / 10e18;
        return true;
    }
    
    function calcPotentiolInterest(address from, address token, uint256 percentage) view internal returns (uint256) {
        require(from != address(0));
        if(accounts[from][token].lastInterestBlock == 0) { return 0; }     
        uint256 interest_temp = (block.number - accounts[from][token].lastInterestBlock) * 10e14 * percentage;
        return (accounts[from][token].deposit * interest_temp) / 10e18;
    }
    
    function getBalanceOfAddress(address from, address token) view internal returns (uint256) {
        require(from != address(0));
        return accounts[from][token].deposit + accounts[from][token].interest;
    }

    /**
     * The purpose of this function is to allow end-users to deposit a given 
     * token amount into their bank account.
     * @param token - the address of the token to deposit. If this address is
     *                set to 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE then 
     *                the token to deposit is ETH.
     * @param amount - the amount of the given token to deposit.
     * @return - true if the deposit was successful, otherwise revert.
     */
    function deposit(address token, uint256 amount) payable override external returns (bool) {
        require(msg.sender != address(0));
        require(token != address(0));
        require(amount > 0);
        
        if(token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            if(msg.value == amount) {
                calcInterest(msg.sender, token, 3);
                accounts[msg.sender][token].deposit = msg.value;
                accounts[msg.sender][token].lastInterestBlock = block.number;
                emit Deposit(msg.sender, token, amount);
                return true;
            }
        } else {
            IERC20 hak = IERC20(hak_token);
            
            require(hak.balanceOf(msg.sender) >= amount);
            require(hak.allowance(msg.sender, address(this)) >= amount);
            
            calcInterest(msg.sender, token, 3);
            accounts[msg.sender][token].lastInterestBlock = block.number;
            
            if(hak.transferFrom(msg.sender, address(this), amount)) {
                accounts[msg.sender][token].deposit += amount;
                emit Deposit(msg.sender, token, amount);
                return true;
            }
        }
        revert();
    }
    
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
    function withdraw(address token, uint256 amount) override external returns (uint256) {
        require(msg.sender != address(0));
        require(amount >= 0);
        require(token != address(0));
        
        if(amount != 0) {
            require(getBalanceOfAddress(msg.sender, token) + calcPotentiolInterest(msg.sender, token, 3) >= amount);
        }
        
        if(token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            if(amount == 0) {
                calcInterest(msg.sender, token, 3);
                uint256 balance = getBalanceOfAddress(msg.sender, token);
                accounts[msg.sender][token].deposit = 0;
                accounts[msg.sender][token].interest = 0;
                accounts[msg.sender][token].lastInterestBlock = block.number;
                
                if(msg.sender.send(balance)) {
                    emit Withdraw(msg.sender, token, balance);
                    return balance;
                }
            } else {
                calcInterest(msg.sender, token, 3);
                accounts[msg.sender][token].lastInterestBlock = block.number;
                
                if(accounts[msg.sender][token].interest >= amount) {
                    accounts[msg.sender][token].interest -= amount;
                } else {
                    accounts[msg.sender][token].deposit -= (amount - accounts[msg.sender][token].interest);
                    accounts[msg.sender][token].interest = 0;
                }
                
                if(msg.sender.send(amount)) {
                    emit Withdraw(msg.sender, token, amount);
                    return amount;
                }
            }
        } else {
            IERC20 hak = IERC20(hak_token);
            
            if(amount == 0) {
                calcInterest(msg.sender, token, 3);
                uint256 balance = getBalanceOfAddress(msg.sender, token);
                accounts[msg.sender][token].deposit = 0;
                accounts[msg.sender][token].interest = 0;
                accounts[msg.sender][token].lastInterestBlock = block.number;
                
                require(hak.balanceOf(address(this)) >= balance);
                
                if(hak.transfer(msg.sender, balance)) {
                    emit Withdraw(msg.sender, token, balance);
                    return balance;
                }
            } else {
                calcInterest(msg.sender, token, 3);
                accounts[msg.sender][token].lastInterestBlock = block.number;
                
                if(accounts[msg.sender][token].interest >= amount) {
                    accounts[msg.sender][token].interest -= amount;
                } else {
                    accounts[msg.sender][token].deposit -= (amount - accounts[msg.sender][token].interest);
                    accounts[msg.sender][token].interest = 0;
                }
                
                require(hak.balanceOf(address(this)) >= amount);
                
                if(hak.transfer(msg.sender, amount)) {
                    emit Withdraw(msg.sender, token, amount);
                    return amount;
                }
            }
        }
        revert();
    }

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
    function borrow(address token, uint256 amount) override external returns (uint256) {
        //getVirtualPrice(address token) view external returns (uint256);
        IPriceOracle price = IPriceOracle(price_orakle);
        address tokenETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
        uint256 col = this.getCollateralRatio(token, msg.sender);
        
        if(col < 15000) {
            col = 15000;
        }
        //uint256 col_amount = col * amount / 10000;

        if(token == tokenETH) {
            calcLoanInteresst(msg.sender, token);
            loans[msg.sender][token].lastInterestBlock = block.number;

            uint256 col_amount = (col * (amount * (10e18 / price.getVirtualPrice(hak_token)))) / 10000;
            require(getBalanceOfAddress(msg.sender, hak_token) + calcPotentiolInterest(msg.sender, hak_token, 3) >= col_amount);
            
            calcInterest(msg.sender, hak_token, 3);
            accounts[msg.sender][hak_token].lastInterestBlock = block.number;
            
            if(accounts[msg.sender][hak_token].interest >= col_amount) {
                    accounts[msg.sender][hak_token].interest -= col_amount;
            } else {
                    accounts[msg.sender][hak_token].deposit -= (col_amount - accounts[msg.sender][hak_token].interest);
                    accounts[msg.sender][hak_token].interest = 0;
            }
            
            loans[msg.sender][token].sum = amount;
            loans[msg.sender][token].collateral = col_amount;
            if(msg.sender.send(amount)) {
                emit Borrow(msg.sender, token, amount, this.getCollateralRatio(token, msg.sender));
                return col;
            }
            
        } else if(token == hak_token){
            calcLoanInteresst(msg.sender, token);
            loans[msg.sender][token].lastInterestBlock = block.number;

            IERC20 hak = IERC20(hak_token);
            uint256 col_amount = (col * ((amount * price.getVirtualPrice(hak_token))) / 10e18) / 10000;
            require(getBalanceOfAddress(msg.sender, tokenETH) + calcPotentiolInterest(msg.sender, tokenETH, 3) >= col);

            calcInterest(msg.sender, tokenETH, 3);
            accounts[msg.sender][tokenETH].lastInterestBlock = block.number;
            
            if(accounts[msg.sender][tokenETH].interest >= col_amount) {
                    accounts[msg.sender][tokenETH].interest -= col_amount;
            } else {
                    accounts[msg.sender][tokenETH].deposit -= (col_amount - accounts[msg.sender][tokenETH].interest);
                    accounts[msg.sender][tokenETH].interest = 0;
            }
            
            loans[msg.sender][token].sum = amount;
            loans[msg.sender][token].collateral = col_amount;

            if(hak.transfer(msg.sender, amount)) {
                emit Borrow(msg.sender, token, amount, this.getCollateralRatio(token, msg.sender));
                return col;
            }
        }
        revert();
    }

    /**
     * The purpose of this function is to allow users to repay their loans.
     * Loans can be repaid partially or entirely. When repaying a loan, an
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
    function repay(address token, uint256 amount) override payable external returns (uint256) {
        address tokenETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
        //loans[msg.sender][token].sum = (loans[msg.sender][token].sum * (5 * 10e16)) / 10e18 + loans[msg.sender][token].sum;
        calcLoanInteresst(msg.sender, token);
        loans[msg.sender][token].lastInterestBlock = block.number;
        if(token == tokenETH) {
            //require(amount == msg.value);
            if(amount >= loans[msg.sender][token].sum + loans[msg.sender][token].interest) {
                loans[msg.sender][token].sum = 0;
                loans[msg.sender][token].interest = 0;
                if(amount - (loans[msg.sender][token].sum + loans[msg.sender][token].interest) == 0) {
                    if(msg.sender.send(amount - loans[msg.sender][token].sum + loans[msg.sender][token].interest)) {
                        accounts[msg.sender][hak_token].deposit += loans[msg.sender][token].collateral;
                        emit Repay(msg.sender, token, 0);
                        return 0;
                    }
                }
                accounts[msg.sender][hak_token].deposit += loans[msg.sender][token].collateral;
                emit Repay(msg.sender, token, 0);
                return 0;
            } else {
                if(loans[msg.sender][token].interest > amount) {
                    loans[msg.sender][token].interest -= amount;
                } else {
                    loans[msg.sender][token].sum -= amount - loans[msg.sender][token].interest;
                    loans[msg.sender][token].interest = 0;
                }
                emit Repay(msg.sender, token, loans[msg.sender][token].sum + loans[msg.sender][token].interest);
                return loans[msg.sender][token].sum;
            }
        } else {
            IERC20 hak = IERC20(hak_token);

            require(hak.allowance(msg.sender, address(this)) >= amount);

            if(!hak.transferFrom(msg.sender, address(this), amount)) {
                revert();
            }
            
            if(amount >= loans[msg.sender][token].sum + loans[msg.sender][token].interest) {
                loans[msg.sender][token].sum = 0;
                loans[msg.sender][token].interest = 0;
                if(amount - (loans[msg.sender][token].sum + loans[msg.sender][token].interest) == 0) {
                    if(hak.transfer(msg.sender, amount - loans[msg.sender][token].sum + loans[msg.sender][token].interest)) {
                        accounts[msg.sender][tokenETH].deposit += loans[msg.sender][token].collateral;
                        emit Repay(msg.sender, token, 0);
                        return 0;
                    }
                }
                accounts[msg.sender][tokenETH].deposit += loans[msg.sender][token].collateral;
                emit Repay(msg.sender, token, 0);
                return 0;
            } else {
                if(loans[msg.sender][token].interest > amount) {
                    loans[msg.sender][token].interest -= amount;
                } else {
                    loans[msg.sender][token].sum -= amount - loans[msg.sender][token].interest;
                    loans[msg.sender][token].interest = 0;
                }
                emit Repay(msg.sender, token, loans[msg.sender][token].sum + loans[msg.sender][token].interest);
                return loans[msg.sender][token].sum;
            }
        }
        revert();
    }
    
    /**
     * The purpose of this function is to allow so called keepers to collect bad
     * debt, that is in case the collateral ratio goes below 150% for any loan. 
     * @param token - the address of the token used as collateral for the loan. 
     * @param account - the account that took out the loan that is now undercollateralized.
     * @return - true if the liquidation was successful, otherwise revert.
     */
    function liquidate(address token, address account) payable override external returns (bool) {
        IPriceOracle price = IPriceOracle(price_orakle);
        address tokenEth = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
        uint256 col = (accounts[account][token].deposit * loans[account][token].interest) / 10e16;
        if(token == tokenEth) {
            if(col < 15000) {
                calcLoanInteresst(account, token);
                uint256 liquid = loans[account][token].interest + loans[account][token].sum;
                //accounts[account][token].deposit -= loans[account][token].interest + loans[account][token].sum;
                if(liquid < accounts[account][token].interest) {
                    accounts[account][token].interest -= liquid;
                    accounts[account][hak_token].deposit += loans[account][token].collateral;
                    emit Liquidate(msg.sender, account, token, 0, liquid);
                    return true;
                } else if(liquid > loans[account][token].interest) {
                    if(liquid <= loans[account][token].interest + accounts[account][token].deposit) {
                        loans[account][token].interest = 0;
                        accounts[account][token].deposit -= liquid - loans[account][token].interest;
                        accounts[account][hak_token].deposit += loans[account][token].collateral;
                        emit Liquidate(msg.sender, account, token, 0, liquid);
                        return true;
                    } else {
                        loans[account][token].interest = 0;
                        accounts[account][token].deposit = 0;
                        liquid -= loans[account][token].interest + accounts[account][token].deposit;
                        liquid = (liquid * price.getVirtualPrice(hak_token)) / 10e8;
                        loans[account][token].collateral -= liquid;
                        accounts[account][hak_token].deposit += loans[account][token].collateral;
                        emit Liquidate(msg.sender, account, token, liquid, loans[account][token].collateral);
                        return true;
                    }
                }
            }
        } else {
            calcLoanInteresst(account, token);
                uint256 liquid = loans[account][token].interest + loans[account][token].sum;
                //accounts[account][token].deposit -= loans[account][token].interest + loans[account][token].sum;
                if(liquid < accounts[account][token].interest) {
                    accounts[account][token].interest -= liquid;
                    accounts[account][tokenEth].deposit += loans[account][token].collateral;
                    emit Liquidate(msg.sender, account, token, 0, liquid);
                    return true;
                } else if(liquid > loans[account][token].interest) {
                    if(liquid <= loans[account][token].interest + accounts[account][token].deposit) {
                        loans[account][token].interest = 0;
                        accounts[account][token].deposit -= liquid - loans[account][token].interest;
                        accounts[account][tokenEth].deposit += loans[account][token].collateral;
                        emit Liquidate(msg.sender, account, token, 0, liquid);
                        return true;
                    } else {
                        loans[account][token].interest = 0;
                        accounts[account][token].deposit = 0;
                        liquid -= loans[account][token].interest + accounts[account][token].deposit;
                        liquid *= 10e18 / price.getVirtualPrice(tokenEth);
                        loans[account][token].collateral -= liquid;
                        accounts[account][tokenEth].deposit += loans[account][token].collateral;
                        emit Liquidate(msg.sender, account, token, liquid, loans[account][token].collateral);
                        return true;
                    }
                }
        }
        revert();
    }

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
    function getCollateralRatio(address token, address account) view override external returns (uint256) {
        require(token != address(0));
        require(account != address(0));
        if(accounts[account][token].deposit == 0) {
            return 0;
        }
        if(loans[account][token].sum == 0) {
            return type(uint256).max;
        }
        return (accounts[account][token].deposit / loans[account][token].sum) * 100;
    }
     
    /**
     * The purpose of this function is to return the balance that the caller 
     * has in their own account for the given token (including interest).
     * @param token - the address of the token for which the balance is computed.
     * @return - the value of the caller's balance with interest, excluding debts.
     */
    function getBalance(address token) view override external returns (uint256) {
        require(msg.sender != address(0));
        return accounts[msg.sender][token].deposit + accounts[msg.sender][token].interest;
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IPriceOracle {
    /**
     * The purpose of this function is to retrieve the price of the given token
     * in ETH. For example if the price of a HAK token is worth 0.5 ETH, then
     * this function will return 500000000000000000 (5e17) because ETH has 18 
     * decimals. Note that this price is not fixed and might change at any moment,
     * according to the demand and supply on the open market.
     * @param token - the ERC20 token for which you want to get the price in ETH.
     * @return - the price in ETH of the given token at that moment in time.
     */
    function getVirtualPrice(address token) view external returns (uint256);
}