//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;
import "./IBank.sol";
import "./PriceOracle.sol";
import "./HAKToken.sol";
contract Bank is IBank {

    address hak_address;
    address oracle_address;
    HAKToken HAK;
    IPriceOracle Oracle;
    address constant ETH_token_address = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    mapping(address => Account) accounts;

    mapping(address => Account) ether_accounts ;

    mapping(address => uint256) owed_interest;  // in ETH
    mapping(address => uint256) loans;  // in ETH
    mapping(address => uint256) last_loan_interest_block;
    uint HAKBalance = 0;
    uint ETHBalance = 0;


    constructor(address oracle_address_, address hak_address_){
        hak_address = hak_address_;
        oracle_address = oracle_address_;
        HAK = HAKToken(hak_address);
        Oracle = IPriceOracle(oracle_address);

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
    function deposit(address token, uint256 amount) payable override external returns (bool){

        if (token == ETH_token_address && msg.value > 0) {
          	require(msg.value >= amount, "insufficient ETH sent");

            ether_accounts[msg.sender].interest += calcETHInterest(msg.sender);
            ether_accounts[msg.sender].lastInterestBlock = block.number;
          	ether_accounts[msg.sender].deposit += amount;
            ETHBalance += msg.value;
        }
        else if ( token == hak_address) {
      		require(HAK.transferFrom(msg.sender, address(this), amount) && amount > 0);

      		HAKBalance += amount;
      		accounts[msg.sender].interest += calcInterest(msg.sender);
          accounts[msg.sender].lastInterestBlock = block.number;
          accounts[msg.sender].deposit += amount;
        } else {
          revert("token not supported");
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
    function withdraw(address token, uint256 amount) override external returns (uint256){

       if (token == ETH_token_address) {

      	  uint networth = getETHBalanceOf(msg.sender);
         	require(networth != 0, "no balance");
      	  uint draw = amount ;
      	  if(amount == 0) { draw = networth; }

      	  uint current_interest_gain = calcETHInterest(msg.sender);
      	  require(networth - calcETHLoan(msg.sender) * 15000 * Oracle.getVirtualPrice(hak_address) / 10000000000000000000000 >=  draw && draw <= ETHBalance, "amount exceeds balance");

      	  uint new_balance = networth - draw;
      	  if(draw <= ether_accounts[msg.sender].interest + calcETHInterest(msg.sender) ){
            ether_accounts[msg.sender].interest += calcETHInterest(msg.sender);
            ether_accounts[msg.sender].interest -= draw;
						ether_accounts[msg.sender].lastInterestBlock = block.number;

          }else{
            ether_accounts[msg.sender].deposit = new_balance;
            ether_accounts[msg.sender].interest = 0;
            ether_accounts[msg.sender].lastInterestBlock = block.number;

          }

          (bool sent, bytes memory data) = msg.sender.call{value: amount}("");
          require(sent, "Failed to send Ether");
          ETHBalance -= draw;
          emit Withdraw(msg.sender, token, draw);
         	return amount;
        } else if ( token == hak_address) {
          	uint draw = amount;
          	if ( amount == 0 ) { draw = getBalanceOf( token, msg.sender );}
            require(getBalanceOf(token, msg.sender) != 0, "no balance");
            require( getBalanceOf(token, msg.sender) >=  draw && HAKBalance >= draw, "amount exceeds balance"); // -debt
            uint new_balance = accounts[msg.sender].deposit + accounts[msg.sender].interest - draw;

          if(draw <= accounts[msg.sender].interest + calcInterest(msg.sender) ){
              accounts[msg.sender].interest += calcInterest(msg.sender);
              accounts[msg.sender].interest -= draw;
              accounts[msg.sender].lastInterestBlock = block.number;

          }else{
            accounts[msg.sender].deposit = new_balance;
            accounts[msg.sender].interest = 0;
            accounts[msg.sender].lastInterestBlock = block.number;

          }

      		require(HAK.transfer( msg.sender, draw));
      		HAKBalance -= draw;

          accounts[msg.sender].lastInterestBlock = block.number;
          emit Withdraw(msg.sender, token, amount);
        	return amount;
        } else {
          revert("token not supported");
        }

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
    function borrow(address token, uint256 amount) override external returns (uint256){
        require(token == ETH_token_address, "token not supported");
      	if ( getBalanceOf(token, msg.sender ) == 0 ) { revert ( "no collateral deposited") ; }
        require(calcNeededCollateral(hak_address, amount) <= maxNewCollateral(hak_address, msg.sender), "borrow would exceed collateral ratio");
        if (amount == 0) {
          amount = maxNewCollateral( token, msg.sender) * Oracle.getVirtualPrice(hak_address) * 20000 / 1000000000000000000 / 30000;
          // Amount is the max possible one without exceeding a collateral ratio of 150%
        }
        owed_interest[msg.sender] += calcCollateralInterest(msg.sender);
        last_loan_interest_block[msg.sender] = block.number;
        loans[msg.sender] += amount;


        (bool sent, bytes memory data) = msg.sender.call{value: amount}("");
        require(sent, "Failed to send Ether");

      	ETHBalance -= amount;
        emit Borrow(msg.sender, token, amount, collateralRatio(token, msg.sender));
        return collateralRatio(token, msg.sender);

    }
    function calcCollateralInterest(address user) internal view returns (uint256){
        return loans[user] * 5 * (block.number - last_loan_interest_block[user]) / 10000;

    }
    function calcETHLoan(address user) internal view returns(uint256){
        return loans[user] + owed_interest[user] + calcCollateralInterest(user);
    }

    function allowedToBorrow(address token, uint256 amount, address user) internal view returns(bool){
        uint networth = getBalanceOf(token, user)  * Oracle.getVirtualPrice(hak_address) / 1000000000000000000; // in ETH
        if (calcETHLoan(user) == 0 && networth > 0 ) {return true;}
        return (networth * 10000 / (calcETHLoan(user)) >= 15000);
    }


    function calcNeededCollateral(address token, uint256 amount) internal view returns(uint256){
        require(token == hak_address);
        // TODO calculate in HAK not in ETH !
        uint wantedLoanInHak = amount * 1000000000000000000  / Oracle.getVirtualPrice(token);
        return wantedLoanInHak * 15000 / 10000; // 1.5x of the HAK value of the wanted allowance.

    }

    function maxNewCollateral(address token, address user)  internal view returns (uint){
        uint owedETH = calcETHLoan(user) * 1000000000000000000 / Oracle.getVirtualPrice(hak_address) ; // Owed ETH in HAK
        uint networth = getBalanceOf(token, user) ;  // HAK networth
        return (networth * 10000 - (15000 * owedETH)) / 10000;
    }

    function collateralSafe(address token, address user) internal view returns(bool){
        uint networth = getBalanceOf(token, user) * Oracle.getVirtualPrice(hak_address) / 1000000000000000000; // in ETH Value
        uint ethloan = calcETHLoan(user);
        if (ethloan == 0){ return true;}
        return (( networth * 10000 /
            ( 15000 * (ethloan)) ) >= 1);
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
    function repay(address token, uint256 amount)  payable override external returns (uint256){
      	require(token == ETH_token_address, "token not supported");
        uint debt = calcETHLoan(msg.sender);
      	if (debt == 0){ revert("nothing to repay"); }
      	if ( msg.value < amount ) {revert("msg.value < amount to repay");}
      	owed_interest[msg.sender] += calcETHInterest(msg.sender);
      	if (msg.value > debt) {
          loans[msg.sender] = 0;
          owed_interest[msg.sender] = 0 ;
        }else {
          uint debt_interest = owed_interest[msg.sender];
          if (msg.value > debt_interest) {
          	owed_interest[msg.sender] = 0 ;
          	loans[msg.sender] = loans[msg.sender] - (msg.value - debt_interest);
          }else{
            owed_interest[msg.sender] -= msg.value ;
          }

        }
        last_loan_interest_block[msg.sender] = block.number;
      	debt -= msg.value;
        ETHBalance += msg.value;
        emit Repay(msg.sender, token, debt); // debt in ETH
      	return loans[msg.sender] ;
    }

    /**
     * The purpose of this function is to allow so called keepers to collect bad
     * debt, that is in case the collateral ratio goes below 150% for any loan.
     * @param token - the address of the token used as collateral for the loan.
     * @param account - the account that took out the loan that is now undercollateralized.
     * @return - true if the liquidation was successful, otherwise revert.
     */
    function liquidate(address token, address account) payable override external returns (bool){
      	require(token == hak_address, "token not supported");
      	require(account != msg.sender, "cannot liquidate own position");
      	require(this.getCollateralRatio(token, account) <= 15000, "healty position");

      	uint owed = calcETHLoan(account);
      	require(msg.value >= owed, "insufficient ETH sent by liquidator");


      	uint col = getBalanceOf(token, account);

      	accounts[account].deposit = 0;
      	accounts[account].interest = 0;
      	accounts[account].lastInterestBlock = block.number;

      	// The liquidator gets the collateral from the liquidated account

      	require(HAK.transfer(msg.sender, col));
      	HAKBalance -= col;
      	// Erase the debts of the liquidated account
      	loans[account] = 0;
        owed_interest[account] = 0;

      	if (msg.value > owed) {
          // Pay back what the liquidator paid in excess
          (bool sent, bytes memory data) = msg.sender.call{value: msg.value-owed}("");
          require(sent, "Failed to send Ether");
        }
      	ETHBalance += owed;


      	emit Liquidate(msg.sender, account, token, col, msg.value-owed);


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
    function getCollateralRatio(address token, address account) view override external returns (uint256){

        uint networth = getBalanceOf(token, account) * Oracle.getVirtualPrice(hak_address) / 1000000000000000000;
        uint owedETH = calcETHLoan(account);

        if(owedETH == 0 ) { return type(uint256).max; }

        else { return networth * 10000 / owedETH ;}
        // collateral Ratio in percentage
    }
    function collateralRatio(address token, address account) view internal returns (uint256){

        uint networth = getBalanceOf(token, account) * Oracle.getVirtualPrice(hak_address) / 1000000000000000000;
        uint owedETH = calcETHLoan(account);

        if(owedETH == 0 ) { return type(uint256).max; }

        else { return networth * 10000 / owedETH ;}
        // collateral Ratio in percentage
    }

    /**
     * The purpose of this function is to return the balance that the caller
     * has in their own account for the given token (including interest).
     * @param token - the address of the token for which the balance is computed.
     * @return - the value of the caller's balance with interest, excluding debts.
     */
    function getBalanceOf(address token, address user) view internal returns (uint256){
        uint interest = calcInterest(user);
        uint sum = accounts[user].interest + accounts[user].deposit + interest ;
        return sum;
    }
    function getETHBalanceOf(address user) view internal returns (uint256){
        uint interest = calcETHInterest(msg.sender);
        uint sum = ether_accounts[msg.sender].interest + ether_accounts[msg.sender].deposit + interest ;
        return sum;
    }

    function getBalance(address token) view override external returns (uint256){
      	if (token == ETH_token_address) {
          return getETHBalanceOf(msg.sender);
        } else if (token == hak_address) {
          return getBalanceOf(token, msg.sender);
        } else {
          revert("token not supported");
        }
    }

    function calcInterest(address user) view internal returns (uint){
        return accounts[user].deposit * 3 / 10000 * (block.number - accounts[user].lastInterestBlock);
    }
    function calcETHInterest(address user) view internal returns (uint){
        return ether_accounts[user].deposit * 3 / 10000 * (block.number - ether_accounts[user].lastInterestBlock);
    }

}