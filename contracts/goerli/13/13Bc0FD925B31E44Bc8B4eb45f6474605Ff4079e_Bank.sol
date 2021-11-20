/**
 *Submitted for verification at Etherscan.io on 2021-11-20
*/

//SPDX-License-Identifier: Unlicense
pragma solidity 0.7.0;

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

library DSMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }
    function max(uint x, uint y) internal pure returns (uint z) {
        return x >= y ? x : y;
    }
    function imin(int x, int y) internal pure returns (int z) {
        return x <= y ? x : y;
    }
    function imax(int x, int y) internal pure returns (int z) {
        return x >= y ? x : y;
    }

    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;

    //rounds to zero if x*y < WAD / 2
    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
    //rounds to zero if x*y < WAD / 2
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }
    //rounds to zero if x*y < WAD / 2
    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
    //rounds to zero if x*y < RAY / 2
    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    // This famous algorithm is called "exponentiation by squaring"
    // and calculates x^n with x as fixed-point and n as regular unsigned.
    //
    // It's O(log n), instead of O(n) for naive repeated multiplication.
    //
    // These facts are why it works:
    //
    //  If n is even, then x^n = (x^2)^(n/2).
    //  If n is odd,  then x^n = x * x^(n-1),
    //   and applying the equation for even x gives
    //    x^n = x * (x^2)^((n-1) / 2).
    //
    //  Also, EVM division is flooring and
    //    floor[(n-1) / 2] = floor[n / 2].
    //
    function rpow(uint x, uint n) internal pure returns (uint z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
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

contract Bank is IBank {
    address internal constant ethToken = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    
    address private hakToken;
    address private priceOracle;

    mapping(address => Account) public ETHBankAccount;
    mapping(address => Account) public HAKBankAccount;
    mapping(address => Account) public ETHBorrowed;

    constructor(address _priceOracle, address _hakToken) {
        hakToken = _hakToken;
        priceOracle = _priceOracle;
    }
    function deposit(address token, uint256 amount)
        payable
        external
        override
        returns (bool) {
            require(amount > 0, "Too small amount!");
            // TODO add requires for tokens
            if(token == ethToken){
                require(msg.value == amount);
                ETHBankAccount[msg.sender].interest = DSMath.add(ETHBankAccount[msg.sender].interest, calculateDepositInterest(token));
                ETHBankAccount[msg.sender].deposit = DSMath.add(ETHBankAccount[msg.sender].deposit, amount);
                ETHBankAccount[msg.sender].lastInterestBlock = block.number;
            } else if(token == hakToken) {
                require(IERC20(hakToken).transferFrom(msg.sender, address(this), amount), "Bank not allowed to transfer funds");
                HAKBankAccount[msg.sender].interest = DSMath.add(HAKBankAccount[msg.sender].interest, calculateDepositInterest(token));
                HAKBankAccount[msg.sender].deposit = DSMath.add(HAKBankAccount[msg.sender].deposit, amount);
                HAKBankAccount[msg.sender].lastInterestBlock = block.number;
            } else {
                require(false, "token not supported");
            }
            emit Deposit(msg.sender, token, amount);
            return true;
        }
    
    function withdraw(address token, uint256 amount)
        external
        override
        returns (uint256) {
            require(amount >= 0, "Too small amount!");
            if(token == ethToken){
                require(address(this).balance >= amount, "Bank doesn't have enough funds");
                ETHBankAccount[msg.sender].interest = DSMath.add(ETHBankAccount[msg.sender].interest, calculateDepositInterest(token));
                require(DSMath.add(ETHBankAccount[msg.sender].deposit, ETHBankAccount[msg.sender].interest) > 0, "no balance");
                require(DSMath.add(ETHBankAccount[msg.sender].deposit, ETHBankAccount[msg.sender].interest) >= amount, "amount exceeds balance");
                
                if(amount == 0) {
                    amount = ETHBankAccount[msg.sender].deposit + ETHBankAccount[msg.sender].interest;
                }
                if(ETHBankAccount[msg.sender].interest >= amount){
                    ETHBankAccount[msg.sender].interest = DSMath.sub(ETHBankAccount[msg.sender].interest, amount);
                } else {
                    uint256 tempAmount = amount;
                    tempAmount = DSMath.sub(tempAmount, ETHBankAccount[msg.sender].interest);
                    ETHBankAccount[msg.sender].interest = 0;
                    ETHBankAccount[msg.sender].deposit = DSMath.sub(ETHBankAccount[msg.sender].deposit, tempAmount);
                }
                (bool sent, bytes memory data) = msg.sender.call{value: amount}("");
                require(sent, "Failed to send Ether");
                ETHBankAccount[msg.sender].lastInterestBlock = block.number;
                
            } else if (token == hakToken) {
                require(IERC20(hakToken).balanceOf(address(this)) >= amount, "Bank doesn't have enough funds");
                HAKBankAccount[msg.sender].interest = DSMath.add(HAKBankAccount[msg.sender].interest, calculateDepositInterest(token));
                require(DSMath.add(HAKBankAccount[msg.sender].deposit, HAKBankAccount[msg.sender].interest) > 0, "no balance");
                require(DSMath.add(HAKBankAccount[msg.sender].deposit, HAKBankAccount[msg.sender].interest) >= amount, "amount exceeds balance");
                
                if(amount == 0) {
                    amount = HAKBankAccount[msg.sender].deposit + HAKBankAccount[msg.sender].interest;
                }
                if(HAKBankAccount[msg.sender].interest >= amount){
                    HAKBankAccount[msg.sender].interest = DSMath.sub(HAKBankAccount[msg.sender].interest, amount);
                } else {
                    uint256 tempAmount = amount;
                    tempAmount = DSMath.sub(tempAmount, HAKBankAccount[msg.sender].interest);
                    HAKBankAccount[msg.sender].interest = 0;
                    HAKBankAccount[msg.sender].deposit = DSMath.sub(HAKBankAccount[msg.sender].deposit, tempAmount);
                }
                IERC20(hakToken).transfer(msg.sender, amount);
                HAKBankAccount[msg.sender].lastInterestBlock = block.number;
            } else {
                require(false, "token not supported");
            }
            emit Withdraw(msg.sender, token, amount);
        }

    function borrow(address token, uint256 amount)
        external
        override
        returns (uint256) {
            require(token == ethToken, "token not supported");
            require(calcBorrowedInterest(msg.sender), "Could not calculate interest on debt");
            require(HAKBankAccount[msg.sender].deposit + HAKBankAccount[msg.sender].deposit > 0, "no collateral deposited");

            if(amount==0){
                // calculate maximum amount
                uint256 totalHakTokens = DSMath.add(HAKBankAccount[msg.sender].deposit, HAKBankAccount[msg.sender].interest + calculateDepositInterest(hakToken));
                uint256 max_amount = DSMath.wmul(IPriceOracle(priceOracle).getVirtualPrice(hakToken), DSMath.mul(totalHakTokens, 10000) / 15000);
                amount = DSMath.sub(DSMath.sub(max_amount, ETHBorrowed[msg.sender].deposit), ETHBorrowed[msg.sender].interest);
                //uint256 max_amount = DSMath.sub(DSMath.sub(DSMath.wdiv(DSMath.mul(DSMath.add(HAKBankAccount[msg.sender].deposit, HAKBankAccount[msg.sender].interest) , 10000), 15000), borrowed[msg.sender]), owedInterest[msg.sender]);
                
                // update borrowed amount
                ETHBorrowed[msg.sender].deposit = DSMath.add(ETHBorrowed[msg.sender].deposit, amount);
            } else {
                // calculate new collateral ratio
                uint256 totalHakTokens = DSMath.add(HAKBankAccount[msg.sender].deposit, HAKBankAccount[msg.sender].interest);
                uint256 totalBorrowed = DSMath.add(ETHBorrowed[msg.sender].deposit, DSMath.add(ETHBorrowed[msg.sender].interest, amount));
                uint256 tentative_coll_ratio =DSMath.wmul(IPriceOracle(priceOracle).getVirtualPrice(hakToken), DSMath.mul(totalHakTokens, 10000)) / totalBorrowed;
                require(tentative_coll_ratio >= 15000, "borrow would exceed collateral ratio");
                
                // update borrowed amount
                ETHBorrowed[msg.sender].deposit = DSMath.add(ETHBorrowed[msg.sender].deposit, amount);
            }
            require(address(this).balance >= amount, "Bank doesn't have enough funds");
            
            (bool sent, bytes memory data) = msg.sender.call{value: amount}("");
            require(sent, "Failed to send Ether");
            
            uint256 new_coll_ratio = getCollateralRatio(hakToken, msg.sender);
            
            emit Borrow(msg.sender, token, amount, new_coll_ratio);
                        
            return new_coll_ratio;
        }

    function repay(address token, uint256 amount)
        payable
        external
        override
        returns (uint256) {
            require(token == ethToken, "token not supported");
            require(ETHBorrowed[msg.sender].deposit + ETHBorrowed[msg.sender].interest > 0, "nothing to repay");
            require(calcBorrowedInterest(msg.sender), "Could not calculate interest on debt");
            //TODO: maybe this is not required, case in which we need to send overpayments back
            require(ETHBorrowed[msg.sender].deposit + ETHBorrowed[msg.sender].interest >= msg.value);
            require(amount <= msg.value, "msg.value < amount to repay");
            
            repayHelper(token, msg.sender, msg.sender, msg.value);

            return ETHBorrowed[msg.sender].deposit;
        }

    function liquidate(address token, address account)
        payable
        external
        override
        returns (bool) {
            require(token == hakToken, "token not supported");
            require(calcBorrowedInterest(msg.sender), "Could not calculate interest on debt");
            require(account != msg.sender, "cannot liquidate own position");
            require(getCollateralRatio(hakToken, account) < 15000, "healty position");
            uint256 amountToPay = DSMath.add(ETHBorrowed[account].deposit, ETHBorrowed[account].interest + calculateInterest(5, ETHBorrowed[account].lastInterestBlock, ETHBorrowed[account].deposit));
            
            require(msg.value >= amountToPay, "insufficient ETH sent by liquidator");
            // repay the loan
            repayHelper(ethToken, account, msg.sender, amountToPay);
            
            if(amountToPay < msg.value) {
                (bool sent, bytes memory data) = msg.sender.call{value: msg.value - amountToPay}("");
                require(sent, "Failed to send Ether");
            }
            
            emit Liquidate(msg.sender, account, hakToken, HAKBankAccount[account].deposit, msg.value - amountToPay);
        }
        
    function repayHelper(address token, address borrower, address repayer, uint256 amount)
        private
        returns (bool) {
            require(token == ethToken, "token not supported");
            //require(ERC20(ethToken).approve(address(this), amount), "Bank not allowed to transfer funds");
            //require(ERC20(ethToken).transferFrom(repayer, address(this), amount), "Bank not allowed to transfer funds");
            
            if(amount <= ETHBorrowed[borrower].interest){
                ETHBorrowed[borrower].interest = DSMath.sub(ETHBorrowed[borrower].interest, amount);
            } else {
                uint256 remainingAmount = amount - ETHBorrowed[borrower].interest;
                ETHBorrowed[borrower].interest = 0;
                
                if(remainingAmount > ETHBorrowed[borrower].deposit) {
                    ETHBorrowed[borrower].deposit = 0;
                } else {
                    ETHBorrowed[borrower].deposit = DSMath.sub(ETHBorrowed[borrower].deposit, remainingAmount);   
                }
                
            }
            
            emit Repay(repayer, token, ETHBorrowed[borrower].deposit + ETHBorrowed[borrower].interest);
        }

    // TODO implement: wenn sich der Preis von HAK token ändert => jeden Block die Ratio checken und ggf. liquidieren
    function getCollateralRatio(address token, address account)
        view
        public
        override
        returns (uint256) {
            require(token == hakToken, "wrong input token");
            if (ETHBorrowed[account].deposit == 0) {
                return type(uint256).max;
            }
            //HAKBankAccount[account].interest += calculateDepositInterest(token); 
            //HAKBankAccount[account].lastInterestBlock = block.number;
            uint256 deposited = DSMath.wmul(IPriceOracle(priceOracle).getVirtualPrice(hakToken), DSMath.add(HAKBankAccount[account].deposit, HAKBankAccount[account].interest + calculateDepositInterest(token)));
            uint256 owedInterest = calculateInterest(5, ETHBorrowed[account].lastInterestBlock, ETHBorrowed[account].deposit);
            uint256 borrowed = DSMath.add(ETHBorrowed[account].deposit, DSMath.add(ETHBorrowed[account].interest, owedInterest));
            return DSMath.mul(deposited, 10000) / borrowed;
        }

    function calcBorrowedInterest(address account)
        private 
        returns (bool) {
            uint256 owedInterest = calculateInterest(5, ETHBorrowed[account].lastInterestBlock, ETHBorrowed[account].deposit);
            ETHBorrowed[account].interest = DSMath.add(ETHBorrowed[account].interest, owedInterest);
            ETHBorrowed[account].lastInterestBlock = block.number;
            return true;
        }

    function getBalance(address token)
        view
        public
        override
        returns (uint256) {
            if(token == ethToken){
                return DSMath.add(ETHBankAccount[msg.sender].deposit, ETHBankAccount[msg.sender].interest + calculateDepositInterest(token));
            } else if(token == hakToken) {
                return DSMath.add(HAKBankAccount[msg.sender].deposit, HAKBankAccount[msg.sender].interest + calculateDepositInterest(token));
            } else {
                require(false, "Token not recognized");
            }
        }
        
    function calculateDepositInterest(address token) view private returns (uint256) {
        if(token == ethToken){
            return calculateInterest(3, ETHBankAccount[msg.sender].lastInterestBlock, ETHBankAccount[msg.sender].deposit);
        } else if (token == hakToken) {
            return calculateInterest(3, HAKBankAccount[msg.sender].lastInterestBlock, HAKBankAccount[msg.sender].deposit);
        }
    }
    
    function calculateInterest(uint256 interestRate, uint256 lastInterestBlock, uint256 amount) view private returns (uint256) {
        uint256 nrOfBlocksElapsed = DSMath.sub(block.number, lastInterestBlock);
        
        return DSMath.mul(DSMath.mul(interestRate, nrOfBlocksElapsed), amount) / 10000;
    }
}