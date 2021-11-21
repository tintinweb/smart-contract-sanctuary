/**
 *Submitted for verification at Etherscan.io on 2021-11-21
*/

/**
 *Submitted for verification at Etherscan.io on 2021-11-21
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
    struct Customer {
        IBank.Account ethAccount;
        IBank.Account hakAccount;
        uint256 borrowed;
        uint256 borrowInterest;
        uint256 borrowBlock;
    }

    struct SimpleBank {
        address bank;
        uint256 ethAmount;
        uint256 hakAmount;
    }

    IPriceOracle private priceOracle;
    address private hakToken;
    address private ethToken = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    IERC20 private hak;
    IERC20 private eth;

    SimpleBank private bank;

    mapping(address => Customer) private customerAccounts;

    constructor(address _priceOracle, address _hakToken) {
        priceOracle = IPriceOracle(_priceOracle);
        hakToken = _hakToken;
        bank = SimpleBank(msg.sender, 0, 0);
        hak = IERC20(hakToken);
        eth = IERC20(ethToken);
    }

    function deposit(address token, uint256 amount)
        payable
        external
        override
        returns (bool) {
            Customer storage customer = customerAccounts[msg.sender];
            if (token == hakToken) {
                hak.transferFrom(msg.sender, bank.bank, amount);
                uint256 hakInterest = DSMath.mul(
                    DSMath.sub(block.number, customer.hakAccount.lastInterestBlock), 3);
                customer.hakAccount.lastInterestBlock = block.number;
                uint256 hakInterestVal = DSMath.mul(customer.hakAccount.deposit, hakInterest) / 10000;
                customer.hakAccount.interest = DSMath.add(customer.hakAccount.interest, hakInterestVal);
                customer.hakAccount.deposit = DSMath.add(customer.hakAccount.deposit, amount);
                bank.hakAmount = DSMath.add(bank.hakAmount, amount);
                emit Deposit(msg.sender, token, amount);
                return true;
            } else if(token == ethToken) {
                require(amount == msg.value, "amount not equal to sent");
                uint256 ethInterest = DSMath.mul(
                    DSMath.sub(block.number, customer.ethAccount.lastInterestBlock), 3);
                customer.ethAccount.lastInterestBlock = block.number;
                uint256 ethInterestVal = DSMath.mul(customer.ethAccount.deposit, ethInterest) / 10000;
                customer.ethAccount.interest = DSMath.add(customer.ethAccount.interest, ethInterestVal);
                customer.ethAccount.deposit = DSMath.add(customer.ethAccount.deposit, amount);
                bank.ethAmount = DSMath.add(bank.ethAmount, amount);
                emit Deposit(msg.sender, token, amount);
                return true;
            }
            revert("token not supported");
        }

    function withdraw(address token, uint256 amount)
        external
        override
        returns (uint256) {
            Customer storage customer = customerAccounts[msg.sender];
            if (token == hakToken) {
                require(customer.hakAccount.deposit != 0, "no balance");
                if (amount == 0) {
                    amount = customer.hakAccount.deposit;
                }
                uint256 hakInterest = DSMath.mul(
                    DSMath.sub(block.number, customer.hakAccount.lastInterestBlock), 3);
                customer.hakAccount.lastInterestBlock = block.number;
                uint256 hakInterestVal = DSMath.mul(customer.hakAccount.deposit, hakInterest) / 10000;
                uint256 toSend = DSMath.add(DSMath.add(amount, hakInterestVal), customer.hakAccount.interest);
                customer.hakAccount.interest = 0;
                require(amount <= customer.hakAccount.deposit, "amount exceeds balance");
                require(toSend <= bank.hakAmount, "eth bankrupt");
                bank.hakAmount = DSMath.sub(bank.hakAmount, toSend);
                customer.hakAccount.deposit = DSMath.sub(customer.hakAccount.deposit, amount);
                payable(msg.sender).transfer(toSend);
                emit Withdraw(msg.sender, token, toSend);
                return toSend;
            } else if (token == ethToken) {
                require(customer.ethAccount.deposit != 0, "no balance");
                if (amount == 0) {
                    amount = customer.ethAccount.deposit;
                }
                uint256 ethInterest = DSMath.mul(
                    DSMath.sub(block.number, customer.ethAccount.lastInterestBlock), 3);
                customer.ethAccount.lastInterestBlock = block.number;
                uint256 ethInterestVal = DSMath.mul(customer.ethAccount.deposit, ethInterest) / 10000;
                uint256 toSend = DSMath.add(DSMath.add(amount, ethInterestVal), customer.ethAccount.interest);
                customer.ethAccount.interest = 0;
                require(amount <= customer.ethAccount.deposit, "amount exceeds balance");
                require(toSend <= bank.ethAmount, "eth bankrupt");
                bank.ethAmount = DSMath.sub(bank.ethAmount, toSend);
                customer.ethAccount.deposit = DSMath.sub(customer.ethAccount.deposit, amount);
                payable(msg.sender).transfer(toSend);
                emit Withdraw(msg.sender, token, toSend);
                return toSend;
            }
            revert("token not supported");
        }

    function borrow(address token, uint256 amount)
        external
        override
        returns (uint256) {
            Customer storage customer = customerAccounts[msg.sender];
            require(token == ethToken, "token not supported");
            require(customer.hakAccount.deposit > 0, "no collateral deposited");
            require(amount <= bank.ethAmount, "eth bank bankrupt");
            address payable account = msg.sender;
            if (customer.borrowed == 0) {
                customer.borrowBlock = block.number;
            }
            uint256 ethHakPrice = priceOracle.getVirtualPrice(hakToken);
            uint256 cRatio = _getCollateralRatio(customer, amount);
            require(cRatio >= 15000, "borrow would exceed collateral ratio");
            uint256 borrowInterest = DSMath.mul(customer.borrowed,
                DSMath.mul(DSMath.sub(block.number, customer.borrowBlock), 5)) / 10000;
            customer.borrowInterest = DSMath.add(customer.borrowInterest, borrowInterest);
            customer.borrowBlock = block.number;
            customer.borrowed = DSMath.add(customer.borrowed, amount);
            if (amount == 0) {
                uint256 d_i_curr = DSMath.mul(
                    DSMath.sub(block.number, customer.hakAccount.lastInterestBlock), 3);
                customer.hakAccount.lastInterestBlock = block.number;
                uint256 d_i_curr_val = DSMath.mul(customer.hakAccount.deposit, d_i_curr) / 10000;
                uint256 d = customer.hakAccount.deposit;
                uint256 d_i = DSMath.add(customer.hakAccount.interest, d_i_curr_val);
                uint256 totalDeposit = DSMath.mul(DSMath.add(d, d_i), ethHakPrice) / 10 ** 18;
                customer.hakAccount.interest = d_i;
                uint256 b_i = DSMath.mul(
                    DSMath.sub(block.number, customer.borrowBlock), 5);
                uint256 maxBorrow = DSMath.mul(DSMath.sub((DSMath.mul(
                    totalDeposit, 10000) / 15000), customer.borrowInterest) / DSMath.add(100, b_i), 100);
                uint256 toSend = DSMath.sub(maxBorrow, customer.borrowed);
                if (toSend > bank.ethAmount) {
                    toSend = bank.ethAmount;
                }
                bank.ethAmount = DSMath.sub(bank.ethAmount, toSend);
                customer.borrowed = maxBorrow;
                account.transfer(toSend);
                emit Borrow(account, ethToken, toSend, 15000);
                return 15000;
            } else {
                account.transfer(amount);
                emit Borrow(account, ethToken, amount, cRatio);
                return cRatio;
            }
        }

    function repay(address token, uint256 amount)
        payable
        external
        override
        returns (uint256) {
            require(token == ethToken, "token not supported");
            require(amount <= msg.value, "msg.value < amount to repay");
            uint256 toSendBack = DSMath.sub(msg.value, amount);
            Customer storage customer = customerAccounts[msg.sender];
            address payable account = msg.sender;
            bank.ethAmount = DSMath.add(bank.ethAmount, amount);
            require(DSMath.add(customer.borrowed, customer.borrowInterest) > 0, "nothing to repay");
            uint256 borrowInterest = DSMath.mul(
                DSMath.sub(block.number, customer.borrowBlock), 5);
            uint256 borrowInterestVal = DSMath.mul(borrowInterest, customer.borrowed) / 10000;
            customer.borrowInterest = DSMath.add(customer.borrowInterest, borrowInterestVal);
            if (amount == 0) {
                amount = DSMath.add(customer.borrowed, customer.borrowInterest);
                if (amount > msg.value) {
                    amount = msg.value;
                }
                toSendBack = DSMath.sub(msg.value, amount);
            }
            if (amount >= customer.borrowInterest) {
                amount = DSMath.sub(amount, customer.borrowInterest);
                customer.borrowInterest = 0;
            } else {
                customer.borrowInterest = DSMath.sub(customer.borrowInterest, amount);
                amount = 0;
            }
            if (amount >= customer.borrowed) {
                amount = DSMath.sub(amount, customer.borrowed);
                customer.borrowed = 0;
            } else {
                customer.borrowed = DSMath.sub(customer.borrowed, amount);
                amount = 0;
            }
            toSendBack = DSMath.add(toSendBack, amount);
            account.transfer(toSendBack);
            emit IBank.Repay(account, token, customer.borrowed);
            return customer.borrowed;
        }

    function liquidate(address token, address account)
        payable
        external
        override
        returns (bool) {
            require(token == hakToken, "token not supported");
            require(account != msg.sender, "cannot liquidate own position");
            require(getCollateralRatio(token, account) < 15000, "healty position");
            address payable payer = msg.sender;
            Customer storage customer = customerAccounts[account];
            uint256 borrowInterest = DSMath.mul(
                DSMath.sub(block.number, customer.borrowBlock), 5);
            uint256 debt = DSMath.add(DSMath.add(customer.borrowed, customer.borrowInterest),
                DSMath.mul(borrowInterest, customer.borrowed) / 10000);
            require(debt <= msg.value, "insufficient ETH sent by liquidator");
            uint256 sendBack = DSMath.sub(msg.value, debt);
            bank.ethAmount = DSMath.add(bank.ethAmount, debt);
            payer.transfer(sendBack);
            customer.borrowed = 0;
            uint256 amountCollateral = DSMath.add(customer.hakAccount.deposit, customer.hakAccount.interest);
            uint256 hakInterest = DSMath.mul(
                DSMath.sub(block.number, customer.hakAccount.lastInterestBlock), 3);
            uint256 hakInterestVal = DSMath.mul(customer.hakAccount.deposit, hakInterest) / 10000;
            amountCollateral = DSMath.add(amountCollateral, hakInterestVal);
            customerAccounts[payer].hakAccount.deposit = DSMath.add(
                customerAccounts[payer].hakAccount.deposit, amountCollateral);
            customer.hakAccount.deposit = 0;
            customer.hakAccount.interest = 0;
            customer.hakAccount.lastInterestBlock = block.number;
            hak.transfer(payer, amountCollateral);
            emit IBank.Liquidate(
                payer, account, token, amountCollateral, sendBack);
            return true;
        }

    function getCollateralRatio(address token, address account)
        view
        public
        override
        returns (uint256) {
            Customer memory customer = customerAccounts[account];
            if (token != hakToken) {
                revert("token not supported");
            }
            uint256 ethHakPrice = priceOracle.getVirtualPrice(hakToken);
            if (customer.hakAccount.deposit == 0) {
                return 0;
            }
            if (customer.borrowed == 0) {
                return type(uint256).max;
            }
            uint256 borrowInterest = DSMath.mul(
                DSMath.sub(block.number, customer.borrowBlock), 5);
            uint256 debt = DSMath.add(DSMath.add(customer.borrowed, customer.borrowInterest),
                DSMath.mul(borrowInterest, customer.borrowed) / 10000);
            uint256 depositInterest = DSMath.mul(
                DSMath.sub(block.number, customer.hakAccount.lastInterestBlock), 3);
            uint256 depositInterestVal = DSMath.mul(customer.hakAccount.deposit, depositInterest) / 10000;
            uint256 depositVal = DSMath.mul(DSMath.add(customer.hakAccount.deposit,
                DSMath.add(customer.hakAccount.interest, depositInterestVal)), ethHakPrice);
            return (depositVal / debt) / 10**14;
        }

    function getBalance(address token)
        view
        public
        override
        returns (uint256) {
            Customer memory customer = customerAccounts[msg.sender];
            if (token == hakToken) {
                uint256 hakInterest = DSMath.mul(
                    DSMath.sub(block.number, customer.hakAccount.lastInterestBlock), 3);
                customer.hakAccount.lastInterestBlock = block.number;
                uint256 hakInterestVal = DSMath.mul(customer.hakAccount.deposit, hakInterest) / 10000;
                customer.hakAccount.interest = DSMath.add(customer.hakAccount.interest, hakInterestVal);
                return DSMath.add(customer.hakAccount.deposit,
                    customer.hakAccount.interest);
            } else if (token == ethToken) {
                uint256 ethInterest = DSMath.mul(
                    DSMath.sub(block.number, customer.ethAccount.lastInterestBlock), 3);
                customer.ethAccount.lastInterestBlock = block.number;
                uint256 ethInterestVal = DSMath.mul(customer.ethAccount.deposit, ethInterest) / 10000;
                customer.ethAccount.interest = DSMath.add(customer.ethAccount.interest, ethInterestVal);
                uint256 borrowInterest = DSMath.mul(
                    DSMath.sub(block.number, customer.borrowBlock), 5);
                uint256 debt = DSMath.add(DSMath.add(customer.borrowed, customer.borrowInterest),
                    DSMath.mul(borrowInterest, customer.borrowed) / 10000);
                return DSMath.sub(DSMath.add(customer.ethAccount.deposit,
                    customer.ethAccount.interest), debt);
            } else {
                revert("token not supported");
            }
        }

    function _getCollateralRatio(Customer memory customer, uint256 extraDebt)
        view
        private
        returns (uint256) {
            if (customer.hakAccount.deposit == 0) {
                return 0;
            }
            if (DSMath.add(customer.borrowed, extraDebt) == 0) {
                return type(uint256).max;
            }
            uint256 ethHakPrice = priceOracle.getVirtualPrice(hakToken);
            uint256 borrowInterest = DSMath.mul(
                DSMath.sub(block.number, customer.borrowBlock), 5);
            uint256 debt = DSMath.add(DSMath.add(customer.borrowed, customer.borrowInterest),
                DSMath.mul(borrowInterest, customer.borrowed) / 10000);
            debt = DSMath.add(debt, extraDebt);
            uint256 depositInterest = DSMath.mul(
                DSMath.sub(block.number, customer.hakAccount.lastInterestBlock), 3);
            uint256 depositInterestVal = DSMath.mul(customer.hakAccount.deposit, depositInterest) / 10000;
            uint256 depositVal = DSMath.mul(DSMath.add(customer.hakAccount.deposit,
                DSMath.add(customer.hakAccount.interest, depositInterestVal)), ethHakPrice);
            return (depositVal / debt) / 10**14;
    }
}