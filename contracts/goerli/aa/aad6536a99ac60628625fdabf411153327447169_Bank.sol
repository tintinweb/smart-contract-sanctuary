pragma solidity 0.7.0;
//SPDX-License-Identifier: UNLICENSED"
import "IBank.sol";
import "IPriceOracle.sol";

contract Bank is IBank{
    address public priceOracle;
    address public hakToken;
    address owner;
    
    mapping(address => dif) accounts;
    mapping(address => bool) accountExists;
    mapping(address => uint256) balance;
    mapping(address => uint256) borrowed;
    mapping(address => uint256) owedInterest;
    mapping(address => uint256) owedInterestLastBlock;
    
    
    constructor(address _priceOracle, address _hakToken) public {
        priceOracle = _priceOracle;
        hakToken = _hakToken;
        owner = msg.sender;
    }
    
    struct dif {
        Account hak;
        Account eth;
    }
    
    function computeInterest(address token, address ad) internal view returns (uint256){
        Account memory acc;
        if(token != 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            acc = accounts[ad].hak;
        }else{
            acc = accounts[ad].eth;
        }
        if(acc.lastInterestBlock == 0){
            return 0;
        }else{
            uint256 num = block.number - acc.lastInterestBlock;
            uint full = num % 100;
            num = num % 100;
            uint decimal = (num * 3);
            return acc.interest + (acc.deposit*full)/100 + ((acc.deposit*decimal) / 10000);
        }
    }
    
    function computeOwedInterest(address ad) internal{
        if(owedInterestLastBlock[ad] == 0) {
            owedInterest[ad] == 0;
        }else{
            uint256 num = block.number - owedInterestLastBlock[ad];
            uint full = num % 100;
            num = num % 100;
            uint decimal = (num * 5);
            owedInterest[ad] = owedInterest[ad] + (borrowed[ad]*full)/100 + (borrowed[ad]*decimal) / 10000;
        }
    }
    
    function createAccount(address ad) internal{
        accounts[ad] = dif(Account(0, 0, 0), Account(0, 0, 0));
        accountExists[ad] = true;
        owedInterest[ad] = 0;
        owedInterestLastBlock[ad] = 0;
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
    function deposit(address token, uint256 amount) payable external override returns (bool){
        require(token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE || token == hakToken, "token not supported");
        if(!accountExists[msg.sender]) {
            createAccount(msg.sender);
        }
        Account memory acc;
        if(token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            acc = accounts[msg.sender].eth;
        }else{
            acc = accounts[msg.sender].hak;
        }
        if(token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            require(msg.value == amount, "Message value and amount not the same");
            require(msg.value > 0, "Value is 0");
        }
        acc.interest = computeInterest(token, msg.sender);
        acc.lastInterestBlock = block.number;
        acc.deposit += amount;
           if (token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE){
            accounts[msg.sender].eth = acc;
        }
        if (token == hakToken)
        {
            accounts[msg.sender].hak = acc;
        }
        emit Deposit(msg.sender, token, amount);
        return true;
    }

    /**
     * The purpose of this function is to allow end-users to withdraw a given 
     * token amount from theirm  bank account. Upon withdrawal, the user must
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
    function withdraw(address token, uint256 amount) external override returns (uint256){
        require(token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE || token == hakToken, "token not supported");
        require(accountExists[msg.sender] == true, "no balance");
        Account memory acc;
        if(token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            acc = accounts[msg.sender].eth;
        }else{
            acc = accounts[msg.sender].hak;
        }
        uint256 interest = computeInterest(token, msg.sender);
        require(amount <= acc.deposit + interest, "amount exceeds balance");
        acc.interest = computeInterest(token, msg.sender);
        acc.lastInterestBlock = block.number;
        acc.deposit -= amount;
        msg.sender.transfer(amount);
        emit Withdraw(msg.sender, token, amount + acc.interest);
        return amount + acc.interest;
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
    function borrow(address token, uint256 amount) external override returns (uint256){
        IPriceOracle IPriceOracle;
        require(accountExists[msg.sender] == true, "no collateral deposited");
        Account memory acc;
        if(token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            acc = accounts[msg.sender].eth;
        }else{
            acc = accounts[msg.sender].hak;
        }
        uint256 hakInEth = ((accounts[msg.sender].hak.deposit + accounts[msg.sender].hak.interest) * IPriceOracle.getVirtualPrice(priceOracle));
        computeOwedInterest(msg.sender);
        require (token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
        require ((hakInEth * 10000 / (borrowed[msg.sender] + owedInterest[msg.sender])) >= 15000, "borrow would exceed collateral ratio");

        uint256 maxAmount = (hakInEth * 100) / 150;
        maxAmount -= borrowed[msg.sender];
        
        if (amount == 0) {
            balance[msg.sender] += maxAmount;
            borrowed[msg.sender] += maxAmount;
            amount = maxAmount;
        }
        else {
            balance[msg.sender] += amount;
            borrowed[msg.sender] += amount;
        }
        computeOwedInterest(msg.sender);
        owedInterestLastBlock[msg.sender] = block.number;
        emit Borrow(msg.sender, token, amount, (hakInEth / (borrowed[msg.sender] + owedInterest[msg.sender])) * 100);
        return (hakInEth / (borrowed[msg.sender] + owedInterest[msg.sender])) * 100;
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
    function repay(address token, uint256 amount) payable external override returns (uint256){
        require(token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE, "token not supported");
        if(!accountExists[msg.sender]) {
            createAccount(msg.sender);
        }
        Account memory acc;
        if(token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            acc = accounts[msg.sender].eth;
        }else{
            acc = accounts[msg.sender].hak;
        }
        computeOwedInterest(msg.sender);
        require(amount <= borrowed[msg.sender] + owedInterest[msg.sender], "nothing to repay");
        borrowed[msg.sender] = borrowed[msg.sender] + owedInterest[msg.sender] - amount;
        owedInterestLastBlock[msg.sender] = block.number;
        computeOwedInterest;
        emit Repay(msg.sender, token, owedInterest[msg.sender]);
        return owedInterest[msg.sender];
    }
     
    /**
     * The purpose of this function is to allow so called keepers to collect bad
     * debt, that is in case the collateral ratio goes below 150% for any loan. 
     * @param token - the address of the token used as collateral for the loan. 
     * @param account - the account that took out the loan that is now undercollateralized.
     * @return - true if the liquidation was successful, otherwise revert.
     */
    function liquidate(address token, address account) payable external override returns (bool){
        require(token == hakToken, "token not supported");
        require(account != msg.sender, "cannot liquidate own position");
        if(!accountExists[msg.sender]) {
            createAccount(msg.sender);
        }
        Account memory acc;
        if(token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            acc = accounts[msg.sender].eth;
        }else{
            acc = accounts[msg.sender].hak;
        }
        IPriceOracle IPriceOracle;
        uint256 hakInEth = ((accounts[msg.sender].hak.deposit + accounts[msg.sender].hak.interest) * IPriceOracle.getVirtualPrice(priceOracle));
        computeOwedInterest(msg.sender);
        require ((hakInEth * 10000 / (borrowed[msg.sender] + owedInterest[msg.sender])) < 15000);
        borrowed[account] = 0;
        uint256 amountCol = accounts[account].hak.deposit;
        accounts[msg.sender].hak.deposit += accounts[account].hak.deposit;
        accounts[account].hak.deposit = 0;
        emit Liquidate(msg.sender, account, token, amountCol, msg.value-amountCol);
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
    function getCollateralRatio(address token, address account) view external override returns (uint256){
        Account memory acc;
        if(token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            acc = accounts[msg.sender].eth;
        }else{
            acc = accounts[msg.sender].hak;
        }
        IPriceOracle IPriceOracle;
        if (borrowed[account] <= 0) {
            return type(uint256).max;
        }
        return (acc.deposit + acc.interest * IPriceOracle.getVirtualPrice(priceOracle)  / (borrowed[msg.sender] + owedInterest[msg.sender]) ) * 100;
    }

    /**
     * The purpose of this function is to return the balance that the caller 
     * has in their own account for the given token (including interest).
     * @param token - the address of the token for which the balance is computed.
     * @return - the value of the caller's balance with interest, excluding debts.
     */
    function getBalance(address token) view external override returns (uint256){
        Account memory acc;
        if(token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            acc = accounts[msg.sender].eth;
        }else{
            acc = accounts[msg.sender].hak;
        }
        return acc.deposit + acc.interest - borrowed[msg.sender] - owedInterest[msg.sender];
    }
}