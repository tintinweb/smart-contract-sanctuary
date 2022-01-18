//SPDX-License-Identifier: Unlicense
pragma solidity 0.7.0;


import "./interfaces/IERC20.sol";
import "./interfaces/IPriceOracle.sol";

contract Bank { 

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

    IERC20 public HAK;
    IPriceOracle public priceOracle;

    address public constant ETHADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;  

    mapping(address => mapping(address=> Account)) accounts;
    mapping(address => Account) loanAccount;

    constructor(IPriceOracle _priceOracle, IERC20 _HAK) {
        HAK = _HAK;
        priceOracle = _priceOracle;
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
    function deposit(address token, uint256 amount) payable external returns (bool) {
        require(token == address(HAK) || token == ETHADDRESS, "token not supported");
               
        if (accounts[msg.sender][token].deposit>0) {
            _calculateInterest(token, msg.sender);
        } else {
            accounts[msg.sender][token].lastInterestBlock = block.number;
        }

        

        if (token == address(HAK)) {
            accounts[msg.sender][token].deposit += amount; 
            HAK.transferFrom(msg.sender, address(this), amount);
        } else {
            accounts[msg.sender][token].deposit += msg.value; 
        }

        emit Deposit(msg.sender, token, amount);

        return true;
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
    function withdraw(address token, uint256 amount) external returns (uint256) {
        require(token == address(HAK) || token == ETHADDRESS, "token not supported");
        require(accounts[msg.sender][token].deposit>0,"no balance");
        require(amount <= accounts[msg.sender][token].deposit,"amount exceeds balance");

        _calculateInterest(token, msg.sender);

        uint transf = amount;
        if (amount==0) {
            transf =  accounts[msg.sender][token].deposit;
        } 

        accounts[msg.sender][token].deposit-=transf;
        transf += accounts[msg.sender][token].interest;
        accounts[msg.sender][token].interest = 0;

        if (token == address(HAK)){
            HAK.transfer(msg.sender, transf);
        } else {
            payable(msg.sender).transfer(transf);
        }
        emit Withdraw(msg.sender, token, transf);

        return transf;
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
    function borrow(address token, uint256 amount) external returns (uint256) {
        require(accounts[msg.sender][address(HAK)].deposit>0,"no collateral deposited");

        //(getBalance(address(HAK))*priceOracle.getVirtualPrice(address(HAK))* 10000) / (1 ether * (loanAccount[account].deposit+interest));
        uint amountToBorrow = amount;

        if (loanAccount[msg.sender].deposit>0) {
            _calculateLoanInterest(msg.sender);
        } else {
            loanAccount[msg.sender].lastInterestBlock = block.number;
        }
        if (amount==0) {
            amountToBorrow = ((getBalance(address(HAK))*priceOracle.getVirtualPrice(address(HAK))* 10000) / (1 ether * 15000))-loanAccount[msg.sender].interest-loanAccount[msg.sender].deposit;
        }
        loanAccount[msg.sender].deposit += amountToBorrow; 

        uint collateral = getCollateralRatio(token,msg.sender);

        require(collateral>=15000,"borrow would exceed collateral ratio");
        payable(msg.sender).transfer(amountToBorrow);
        emit Borrow(msg.sender,token,amountToBorrow,collateral);

        return collateral;
    }
     
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
    function repay(address token, uint256 amount) external payable  returns (uint256) {
        require(token == ETHADDRESS, "token not supported");
        require(loanAccount[msg.sender].deposit>0,'nothing to repay');
        require(amount <= msg.value, "msg.value < amount to repay");
        _calculateLoanInterest(msg.sender);
        uint payment= msg.value;
        if (loanAccount[msg.sender].interest >= payment) {
            loanAccount[msg.sender].interest -= payment;
        } else {
            payment -= loanAccount[msg.sender].interest;
            loanAccount[msg.sender].interest = 0;
            if (loanAccount[msg.sender].deposit>=payment) {
                loanAccount[msg.sender].deposit-=payment;
            } else {
                loanAccount[msg.sender].deposit = 0;
                loanAccount[msg.sender].lastInterestBlock = 0;
            }
        }
        emit Repay(msg.sender,token,loanAccount[msg.sender].deposit+ loanAccount[msg.sender].interest);

        return loanAccount[msg.sender].deposit;
    }
     
    /**
     * The purpose of this function is to allow so called keepers to collect bad
     * debt, that is in case the collateral ratio goes below 150% for any loan. 
     * @param token - the address of the token used as collateral for the loan. 
     * @param account - the account that took out the loan that is now undercollateralized.
     * @return - true if the liquidation was successful, otherwise revert.
     */
    function liquidate(address token, address account) payable external returns (bool) {
        require(token == address(HAK), "token not supported");
        require(account != msg.sender, "cannot liquidate own position");
        uint collateral = getCollateralRatio(token, account);
        require(collateral<15000,"healty position");
        _calculateLoanInterest(account);
        uint totalDebt = loanAccount[account].deposit+ loanAccount[account].interest;
        require(totalDebt<=msg.value,"insufficient ETH sent by liquidator");
        uint devolution = msg.value - totalDebt;
        loanAccount[account].deposit =0;
        loanAccount[account].interest = 0;
        loanAccount[account].lastInterestBlock = 0;
        uint totalHak = _balance(token,account);
        
        accounts[account][token].deposit = 0;
        accounts[account][token].interest = 0;
        accounts[account][token].lastInterestBlock = 0;
        HAK.transfer(msg.sender, totalHak);
        payable(msg.sender).transfer(devolution);

        emit Liquidate(msg.sender,account,token,totalHak,devolution);

        return true;
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
    function getCollateralRatio(address token, address account) view public returns (uint256) {


        if (accounts[account][address(HAK)].deposit == 0) {
            return 0;
        }
        if (loanAccount[account].deposit == 0) {

            return type(uint256).max;
        }
        uint blocks = block.number - loanAccount[account].lastInterestBlock;
        uint interest = loanAccount[account].interest+ loanAccount[account].deposit*5*blocks/10000;
        uint val =  (_balance(address(HAK),account)*priceOracle.getVirtualPrice(address(HAK))* 10000) / (1 ether * (loanAccount[account].deposit+interest));
        return val;
        
    }

    /**
     * The purpose of this function is to return the balance that the caller 
     * has in their own account for the given token (including interest).
     * @param token - the address of the token for which the balance is computed.
     * @return - the value of the caller's balance with interest, excluding debts.
     */
    function getBalance(address token) view public returns (uint256) {
        require(token == address(HAK) || token == ETHADDRESS, "token not supported");

        uint balance = _balance(token,msg.sender);
        return balance;
        // uint blocks = block.number - accounts[msg.sender][token].lastInterestBlock;
        // uint interest = accounts[msg.sender][token].interest+accounts[msg.sender][token].deposit*3*blocks/10000;
        // return accounts[msg.sender][token].deposit+interest;
    }

    function _balance (address token, address account) view private returns (uint256) {
        uint blocks = block.number - accounts[account][token].lastInterestBlock;
        uint interest = accounts[account][token].interest+accounts[account][token].deposit*3*blocks/10000;
        return accounts[account][token].deposit+interest;
    }

    function _calculateInterest(address token,address account) private {

        uint blocks = block.number - accounts[account][token].lastInterestBlock;
        accounts[account][token].interest+= accounts[account][token].deposit*3*blocks/10000;
        accounts[account][token].lastInterestBlock = block.number;

    } 

    function _calculateLoanInterest(address account) private  {

        uint blocks = block.number - loanAccount[account].lastInterestBlock;
        loanAccount[account].interest+= loanAccount[account].deposit*5*blocks/10000;
        loanAccount[account].lastInterestBlock = block.number;
    }
    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

// SPDX-License-Identifier: MIT;

pragma solidity 0.7.0;

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