/**
 *Submitted for verification at Etherscan.io on 2021-11-20
*/

pragma solidity 0.7.0;
// SPDX-License-Identifier: MIT

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
    address priceOracle;
    address hakToken;
    address ethToken;
    address selfAddress;

    uint256 WEI_MULT = 1_000_000_000_000_000_000;

    struct CurrencyBalance {
        uint256 balance;
        uint256 interest;
        uint256 lastBlockNumber;
        uint256 interestRate;
    }


    mapping(address => CurrencyBalance) ethDeposits;
    mapping(address => CurrencyBalance) ethLoans;

    mapping(address => CurrencyBalance) hakDeposits;
    mapping(address => uint256) hakCollaterals;

    constructor(address _priceOracle, address payable _hakToken) {
        priceOracle = _priceOracle;
        hakToken = _hakToken;
        ethToken = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
        selfAddress = address(this);
    }

    function calculateSimpleInterest(CurrencyBalance storage currency) private view returns(uint256) {
        if (currency.lastBlockNumber == 0) {
            return 0;
        } 
        return (block.number - currency.lastBlockNumber) * currency.interestRate * currency.balance / 100 / 100; // 100 blocks interestRate percent
    }

    function updateCurrencyInterest(CurrencyBalance storage currency) private {
        currency.interest += calculateSimpleInterest(currency);
    }

    function addBalance(CurrencyBalance storage currency, uint256 amount) private {
        updateCurrencyInterest(currency);
        currency.balance += amount;
        currency.lastBlockNumber = block.number;
    }

    function removeBalanceAndInterest(CurrencyBalance storage currency, uint256 amount) private returns(uint256) {
        updateCurrencyInterest(currency);
        uint256 totalRemoved = amount + currency.interest;
        currency.balance -= amount;
        currency.interest = 0;
        currency.lastBlockNumber = block.number;
        return totalRemoved;
    }

    function getTotalBalance(CurrencyBalance storage currency) private view returns(uint256) {
        return currency.balance + currency.interest + calculateSimpleInterest(currency);
    } 

    function deposit(address token, uint256 amountEth) payable external override returns (bool) {
        if (token != ethToken && token != hakToken) {
            revert("token not supported");
        }

        uint256 msgValueWei = msg.value * WEI_MULT;
        uint256 amount = amountEth * WEI_MULT;

        CurrencyBalance storage currency;
        if (token == ethToken) {
            amount = msgValueWei <= amount ? msgValueWei : amount;
            currency = ethDeposits[msg.sender];
        } else {        
            uint256 allowanceHak = IERC20(hakToken).allowance(msg.sender, selfAddress);
            if (amount / WEI_MULT > allowanceHak) {
                revert("insufficient allowance");
            }
            bool transferSuccessful = IERC20(hakToken).transferFrom(msg.sender, selfAddress, amount / WEI_MULT);
            if (!transferSuccessful) {
                revert("unsuccessful transfer from");
            }
            currency = hakDeposits[msg.sender];
        }

        currency.interestRate = 3;
        addBalance(currency, amount);        
        emit Deposit(msg.sender, token, amount / WEI_MULT);
        
        return true;
    }

    function withdraw(address token, uint256 amountEth) external override returns (uint256) {
        if (token != ethToken && token != hakToken) {
            revert("token not supported");
        }

        uint256 amount = amountEth * WEI_MULT;

        CurrencyBalance storage currency = token == ethToken ? ethDeposits[msg.sender] : hakDeposits[msg.sender];

        if (currency.balance == 0) {
            revert("no balance");
        }

        if (currency.balance < amount) {
            revert("amount exceeds balance");
        }

        if (token == hakToken && amount > currency.balance - hakCollaterals[msg.sender]) {
            revert("amount exceeds balance");
        }

        if (amount == 0) {
            amount = currency.balance;
        }

        uint256 totalAmount = removeBalanceAndInterest(currency, amount);
        if (token == ethToken) {
            msg.sender.transfer(totalAmount / WEI_MULT);
        } else {
            IERC20(hakToken).transfer(msg.sender, totalAmount / WEI_MULT);
        }
        
        emit Withdraw(msg.sender, token, totalAmount / WEI_MULT);
        return totalAmount / WEI_MULT;
    }

    function borrow(address token, uint256 amountEth) external override returns (uint256) {
        if (token != ethToken) {
            revert("We only loan out ETH");
        }

        uint256 amount = amountEth * WEI_MULT;
        uint256 totalHakDeposited = getTotalBalance(hakDeposits[msg.sender]);
        
        if (totalHakDeposited == 0) {
            revert("no collateral deposited");
        }

        uint256 totalHakAvailable = totalHakDeposited;
        uint256 hakPriceInWei = IPriceOracle(priceOracle).getVirtualPrice(hakToken);
        uint256 maxWeiAvailableToBorrow = hakPriceInWei * totalHakAvailable * 100 / 150 / WEI_MULT ;
        uint256 totalLoans = getTotalBalance(ethLoans[msg.sender]);

        if (amount == 0) {
            amount = maxWeiAvailableToBorrow - totalLoans;
        }

        if (amount > maxWeiAvailableToBorrow - totalLoans) {
            revert("borrow would exceed collateral ratio");
        }

        uint256 newCollateral = (amount + totalLoans) * WEI_MULT * 150 / hakPriceInWei / 100;
        hakCollaterals[msg.sender] =  newCollateral;

        CurrencyBalance storage ethLoan = ethLoans[msg.sender];
        ethLoan.interestRate = 5;
        addBalance(ethLoan, amount);

        uint256 newCollateralRatio = getCollateralRatio(hakToken, msg.sender);

        msg.sender.transfer(amount / WEI_MULT);
        emit Borrow(msg.sender, token, amount / WEI_MULT, newCollateralRatio);

        return newCollateralRatio;
    }

    function repay(address token, uint256 amount) payable external override returns (uint256) {
        if (token != ethToken) {
            revert("token not supported");
        }

        if (msg.value < amount) {
            revert("msg.value < amount to repay");
        }

        amount = msg.value * WEI_MULT;
        uint256 startingAmount = amount;

        CurrencyBalance storage ethBalance = ethLoans[msg.sender];

        if (getTotalBalance(ethBalance) == 0) {
            revert("nothing to repay");
        }

        updateCurrencyInterest(ethBalance);

        if (amount >= ethBalance.interest) {
            amount -= ethBalance.interest;
            ethBalance.interest = 0;
        } else {
            ethBalance.interest -= amount;
            amount = 0;
        }

        if (amount >= ethBalance.balance) {
            ethBalance.balance = 0;
        } else {
            ethBalance.balance -= amount;
        }

        uint256 hakPriceInWei = IPriceOracle(priceOracle).getVirtualPrice(hakToken);
        uint256 totalPayedInHak = (startingAmount - amount) / hakPriceInWei;
        uint256 collateralToFree = hakCollaterals[msg.sender] <= totalPayedInHak ? hakCollaterals[msg.sender]: totalPayedInHak;

        hakCollaterals[msg.sender] -= collateralToFree;

        emit Repay(msg.sender, token, (ethBalance.balance) / WEI_MULT);
        return (ethBalance.balance) / WEI_MULT;
    }

    function liquidate(address token, address account) payable external override returns (bool) {
        if (token != hakToken) {
            revert("token not supported");
        }

        if (account == msg.sender) {
            revert("cannot liquidate own position");
        }

        if (getCollateralRatio(token, account) >= 15000) {
            revert("healty position");
        }

        uint256 collateralToReturn = getTotalBalance(hakDeposits[account]);
        uint256 ethNeeded = (getTotalBalance(ethLoans[account]) - getTotalBalance(ethDeposits[account])) / WEI_MULT;

        if (ethNeeded > msg.value) {
            revert("insufficient ETH sent by liquidator");
        }

        uint256 amountSentBack = msg.value - ethNeeded; 
        msg.sender.transfer(amountSentBack);
        
        IERC20(hakToken).transfer(msg.sender, collateralToReturn / WEI_MULT);

        emit Liquidate(msg.sender, account, hakToken, collateralToReturn / WEI_MULT, amountSentBack);
        return true;
    }

    function getCollateralRatio(address token, address account) view public override returns (uint256) {
        if (token != hakToken) {
            revert("Only know HAK collateral");
        }

        uint256 hakPriceInWei = IPriceOracle(priceOracle).getVirtualPrice(hakToken); // * 1_000_000_000_000_000_000
        uint256 totalHakDepositedWei = getTotalBalance(hakDeposits[account]);
        uint256 totalEthBorrowedWei = getTotalBalance(ethLoans[account]);

        if (totalEthBorrowedWei == 0) {
            return type(uint256).max;
        } 

        return totalHakDepositedWei * hakPriceInWei * 10_000 / totalEthBorrowedWei / WEI_MULT;
    }

    function getBalance(address token) view public override returns (uint256) {
        if (token == ethToken) {
            return getTotalBalance(ethDeposits[msg.sender]) / WEI_MULT;
        } else if (token == hakToken) {
            return getTotalBalance(hakDeposits[msg.sender]) / WEI_MULT;
        } else {
            revert("token not supported");
        }
    }
}