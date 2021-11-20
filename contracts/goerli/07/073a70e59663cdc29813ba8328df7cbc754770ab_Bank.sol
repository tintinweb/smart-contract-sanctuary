/**
 *Submitted for verification at Etherscan.io on 2021-11-20
*/

//SPDX-License-Identifier: Unlicense
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

contract PriceOracle is IPriceOracle {

    address poAddress;
    PriceOracle deployed;

    constructor (address _poAddress) {
        deployed = PriceOracle(_poAddress);
    }

    /**
     * The purpose of this function is to retrieve the price of the given token
     * in ETH. For example if the price of a HAK token is worth 0.5 ETH, then
     * this function will return 500000000000000000 (5e17) because ETH has 18 
     * decimals. Note that this price is not fixed and might change at any moment,
     * according to the demand and supply on the open market.
     * @param token - the ERC20 token for which you want to get the price in ETH.
     * @return - the price in ETH of the given token at that moment in time.
     */
    function getVirtualPrice(address token) view external override returns (uint256){
        return deployed.getVirtualPrice(token);
    }
}

contract Bank is IBank {
    
    PriceOracle po;
  
    mapping(address=>Account) accETH; //use to access the ETHaccount
    mapping(address=>Account) accHAK; //use to access the HAKaccount
    mapping(address=>Account) borrowers; //use to access the account of the ledning contract

    constructor(address _priceOracle, address _hakToken) {}
    function updateInterest(Account memory _account, uint256 interestRate) internal {
        //if (_account != accHAK[address(this)] || _account != accETH[address(this)] ){
        //uint256 blockDifference = block.number - _account.lastInterestBlock;
        _account.interest += _account.deposit * interestRate / 100;
        _account.lastInterestBlock = block.number;
            
        //}
    }
    
    function deposit(address token, uint256 amount)
        payable
        external
        override
        returns (bool) {
            if (amount <= 0){
                revert();
            } else {
                if (token == address(0xBefeeD4CB8c6DD190793b1c97B72B60272f3EA6C)){  //when it is HAK
                Account memory HAK = accHAK[msg.sender];
                updateInterest(HAK, 103);
                HAK.deposit += amount;
                HAK.lastInterestBlock = block.number;
                emit Deposit(msg.sender, address(0xBefeeD4CB8c6DD190793b1c97B72B60272f3EA6C), amount);
                return true;
                    
                } else if (token == address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)) {
                Account memory ETH = accETH[msg.sender];
                updateInterest(ETH, 103);
                ETH.deposit += amount;
                ETH.lastInterestBlock = block.number;
                emit Deposit(msg.sender, address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE), amount);
                return true;    
                } else {
			revert("Unsupported Coin");
		}
		
                
            }
            
        }


     function withdraw(address token, uint256 amount)
        external
        override
        returns (uint256) {
            //first figure out the currency
            Account memory Uaccount;
            if (token == address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)){
                Uaccount = accETH[msg.sender];
            } else if (token == address(0xBefeeD4CB8c6DD190793b1c97B72B60272f3EA6C)){
                Uaccount = accHAK[msg.sender];
            }
            if (Uaccount.deposit<amount){
                revert();
            } else {
                uint256 interestBefore = Uaccount.interest;
                Uaccount.deposit -= amount;
                updateInterest(Uaccount, 103);
                uint256 interestAfter = Uaccount.interest;
                uint256 interestAmount= interestAfter - interestBefore;
                uint256 totalWithdraw = interestAmount + amount;
                emit Withdraw(msg.sender, token, totalWithdraw );
                return totalWithdraw;
               
                
            }
            
        }

    function borrow(address token, uint256 amount)
        external
        override
        returns (uint256) {
            //A bank customer must be able to borrow ETH from the bank using the HAK token as collateral.
            //first we need the HAK Tokens in the user's HAK account
            if (token != address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)){
                revert();
            }
            uint256 collateralRatio = this.getCollateralRatio(token, msg.sender);
            if (collateralRatio < 150){
                revert();
            } else {
                Account memory HAK = accHAK[msg.sender];
                HAK.deposit -= collateralRatio * amount; //takes out the collateralRatio * amount worth of HAK
                accETH[msg.sender].deposit += amount; //adds this amount to the ETH account
                //minus the amount from the bank
               //address(this).balance -= 
               uint256 newCollateralRatio = this.getCollateralRatio(token, msg.sender);
                emit Borrow(msg.sender, address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE), amount, newCollateralRatio);
                return newCollateralRatio;
            }
            
        }

function repay(address token, uint256 amount)
        payable
        external
        override
        returns (uint256) {
            if (amount <= 0){
                revert();
            } else {
                updateInterest(accETH[msg.sender], 105);
                if (borrowers[msg.sender].interest > amount) {
                    borrowers[msg.sender].interest -= amount;
                    return borrowers[msg.sender].interest + borrowers[msg.sender].deposit;
                } else {
                    borrowers[msg.sender].interest = 0;
                    if (amount - borrowers[msg.sender].interest < borrowers[msg.sender].deposit){
                        borrowers[msg.sender].deposit = 0;
                        (bool sent, bytes memory data) = msg.sender.call{value: amount - borrowers[msg.sender].deposit - borrowers[msg.sender].interest}("");
                        assert(sent);
                        return 0;
                         
                    } else {
                    borrowers[msg.sender].deposit +=  borrowers[msg.sender].deposit - amount;}
                    return borrowers[msg.sender].deposit;
                }
            }
        }


    /**
     * The purpose of this function is to allow so called keepers to collect bad
     * debt, that is in case the collateral ratio goes below 150% for any loan. 
     * @param token - the address of the token used as collateral for the loan. 
     * @param account - the account that took out the loan that is now undercollateralized.
     * @return - true if the liquidation was successful, otherwise revert.
     */
    function liquidate(address token, address account) payable external override returns (bool) {
        
        updateInterest(borrowers[account], 105);
        updateInterest(accHAK[account], 103);
        assert(this.getCollateralRatio(token, account) < 15000);

        
        // collect collateral
        uint256 toBePaidOut = accHAK[account].deposit + accHAK[account].interest;
        accHAK[token].deposit = 0;
        accHAK[token].interest = 0;
        
        // wipe debt
        uint256 totalDebt = borrowers[account].deposit + borrowers[account].interest;
        borrowers[account].deposit = 0;
        borrowers[account].interest = 0;
        
        uint256 sendBack;
        if (msg.value < totalDebt) {
            revert();
        } else if (msg.value != totalDebt) {
            sendBack = msg.value - totalDebt;
            (bool sent, bytes memory data) = msg.sender.call{value: sendBack}("");
            require(sent, "Failed to return excess ether");
        }
        
        emit Liquidate(msg.sender, account, address(0xBefeeD4CB8c6DD190793b1c97B72B60272f3EA6C), toBePaidOut, sendBack);
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
    function getCollateralRatio(address token, address account) view external override returns (uint256) {
        // get borrowedAmount from mapping, default value if key does not exist is 0
        
        //updateInterest(borrowers[account], 105);
        //updateInterest(accHAK[account], 103);
        
        uint256 borrowedAmount =  borrowers[account].deposit + borrowers[account].interest;
        uint256 depositedAmount =  accHAK[account].deposit + accHAK[account].interest;
        if (borrowedAmount == 0) {
            return type(uint256).max;
        } else if (depositedAmount == 0) {
            return 0;
        } else {
           return 10000 * depositedAmount * po.getVirtualPrice(token) / borrowedAmount;
        }
    }
    /**
     * The purpose of this function is to return the balance that the caller 
     * has in their own account for the given token (including interest).
     * @param token - the address of the token for which the balance is computed.
     * @return - the value of the caller's balance with interest, excluding debts.
     */
    function getBalance(address token) view external override returns (uint256) {
        if (address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) == token) {
            //updateInterest(accETH[msg.sender], 103);
            return accETH[msg.sender].deposit + accETH[msg.sender].interest;
        } else {
            //updateInterest(accHAK[msg.sender], 103);
            return accHAK[msg.sender].deposit + accHAK[msg.sender].interest;
        }
    }
}