// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { Scheduller } from  "./VPStorage/Scheduller.sol";
import { InTokenWrapper } from  "./VPStorage/InTokenWrapper.sol";
import { SafeERC20 } from "./lib/SafeERC20.sol";
import { IERC20 } from "./interfaces/IERC20.sol";

contract VPStorage is Scheduller, InTokenWrapper {
	using SafeERC20 for address;
	
	//Calc precision constant
	uint256 private constant CALC_PRECISION = 1e18; 
	//Out Token Interface
	address public immutable outToken;
	// period => Out Tokens available for exchange this period
	mapping (uint256 => uint256) public historyOutTokenForExchange;
	// Out Token units owed to users
	uint256 public outTokenDebt;

	modifier onlyAmountGreaterThanZero(uint256 amount_) {
		require(amount_ != 0, "amount must be greater than 0");
		_;
	}
	
	/** 
	* @dev Exchange constructor, calls constructors of helper classes InTokenWrapper and Scheduller
	* @param outToken_ Out Token contract address
	* @param inToken_ In Token contract address
	* @param periodDays_ period length in Days
	*/
	constructor(
		address outToken_,
		address inToken_,
		uint256 periodDays_
	)
		InTokenWrapper(inToken_)
		Scheduller(periodDays_)
	{
		outToken = outToken_;
	}

	/***************************************
					PRIVATE
	****************************************/

	/** 
	* @dev Updates Period before executing function 
	* @dev If Period changed, calculates new period Out Token for exchange & Out Token Debt
	* @param startNow_ set periodStartTime = now if true
	*/
	function _updatePeriod(bool startNow_)
		override
		internal
	{
		uint256 _period = period; 
		super._updatePeriod(startNow_);
		if(_period != period){
			(uint256 _nextPeriodForExchange, uint256 _previousPeriodDebt) = _getNextOutTokenForExchange(_period);
			historyOutTokenForExchange[period] = _nextPeriodForExchange;
			outTokenDebt += _previousPeriodDebt;
		}
	}

	/** 
	* @dev Returns Out Tokens available for exchange for next period & debt for previous period
	* @param previousPeriod_ - previous period
	*/
	function _getNextOutTokenForExchange(
		uint256 previousPeriod_
	)
		private
		view
		returns (uint256 nextPeriodForExchange_, uint256 previousPeriodDebt_)
	{
		previousPeriodDebt_ = historyOutTokenForExchange[previousPeriod_];
		//If Out Token balance was greater than total In Token balance for previous period
		//reduce previous period debt to total supply
		if(previousPeriodDebt_ > historyTotalSupply(previousPeriod_))
			previousPeriodDebt_ = historyTotalSupply(previousPeriod_);
		nextPeriodForExchange_ = IERC20(outToken).balanceOf(address(this)) - outTokenDebt - previousPeriodDebt_;
	}

	/**
	* @dev Returns OutTokens available for exchange current period
	*/
	function _getOutTokenForExchange()
		private
		view
		returns(uint256 outTokenForExhange_)
	{
		uint256 _period = _currentPeriod();
		if(period == _period)
			outTokenForExhange_ = historyOutTokenForExchange[period];
		else
			(outTokenForExhange_, ) = _getNextOutTokenForExchange(period);
	}

	/**
	* @dev Calculates In Tokens contract will accept from user current period
	* @param user_ Address of the user
	*/
	function _calculateIn(address user_)
		private
		view
		returns(uint256)
	{
		if(userPeriod(user_) != _currentPeriod()){
			return _getOutTokenForExchange();
		}else{
			return _getOutTokenForExchange() - balanceOf(user_);
		}
	}

 	/**
	* @dev Calculates Out Tokens owed to user for past periods
	* @param user_ Address of the user
	*/
	function _calculateOut(address user_) 
		private
		view
		returns (uint256 outAmount_)
	{
		uint256 _period = _currentPeriod();
		uint256 _userPeriod = userPeriod(user_);
		if(_userPeriod != _period){
			uint256 _userPeriodTotalSupply = historyTotalSupply(_userPeriod);
			if(historyOutTokenForExchange[_userPeriod] >= _userPeriodTotalSupply){
				outAmount_ = balanceOf(user_);
			}else{
				outAmount_ = historyOutTokenForExchange[_userPeriod] * balanceOf(user_)
				* CALC_PRECISION / _userPeriodTotalSupply	/	CALC_PRECISION;
			}
		}
	}

	/**
	* @dev Returns InToken balance available for withdraw
	* @param user_ Address of the user
	*/
	function _getInTokenBalanceForWithdraw(address user_)
		private
		view
		returns(uint256 _inBalance)
	{
		if(userPeriod(user_) == _currentPeriod())
			_inBalance = balanceOf(user_);
	}

	/***************************************
					ACTIONS
	****************************************/
	
	function receiveOutToken(uint256 amount_)
		external
		onlyAmountGreaterThanZero(amount_)
	{
		outToken.safeTransferFrom(msg.sender, address(this), amount_);
		_updatePeriod(false);
	}

	/**
	 * @dev Places amount of In Tokes to be exchanged to Out Tokens current period
	 * if user has balance for previous period executeExchage() is done first
	 * @param amount_ of In Tokens Tokens
	 */
	function requestExchange(uint256 amount_)
		external
		onlyAmountGreaterThanZero(amount_)
	{
		_updatePeriod(true);
		require(_calculateIn(msg.sender) >= amount_, "amount greater than contract can accept this period");
		if(userPeriod(msg.sender) != period && balanceOf(msg.sender) != 0)
			executeExchange();
		_deposit(msg.sender, amount_, period);
	}

	/**
	 * @dev Withdraws amount of In Tokens deposited current period
	 * @param amount_ of In Tokens Tokens
	 */
	function requestWithdraw(uint256 amount_)
		external
		onlyAmountGreaterThanZero(amount_)
	{
		_updatePeriod(false);
		require (_getInTokenBalanceForWithdraw(msg.sender) >= amount_, "amount greater balance for current period");
		_withdraw(msg.sender, amount_, period);
	}

	/**
	 * @dev Sends owed Out Tokens to sender for previos periods In Tokens deposits
	 */
	function executeExchange()
		public 
	{
		_updatePeriod(false);
		uint256 _out = _calculateOut(msg.sender);
		require (_out != 0, "nothing to exchange");
		outTokenDebt -= _out;
		outToken.safeTransfer(msg.sender, _out);
		_withdrawExecute(msg.sender, _out);
	}
	
	/***************************************
					GETTERS
	****************************************/

	/**
	* @dev Returns total amount of InTokens locked into contract
	*/
	function getInTokenBalance()
		external
		view
		returns (uint256)
	{
		return totalSupply();
	}

	/**
	* @dev Returns OutTokens available for exchange current period
	*/
	function getOutTokenForExchange()
		external
		view
		returns(uint256)
	{
		return _getOutTokenForExchange();
	}
	
	/**
	* @dev Returns InToken balance available for withdraw
	* @param user_ Address of the user
	*/
	function getInTokenBalanceForWithdraw(address user_)
		external
		view
		returns(uint256)
	{
		return _getInTokenBalanceForWithdraw(user_);
	}

	/**
	* @dev Calculates In Tokens contract will accept from user current period
	* @param user_ Address of the user
	*/
	function calculateIn(address user_)
		external
		view
		returns(uint256)
	{
		return _calculateIn(user_);
	}
	
	/**
	* @dev Calculates Out Tokens owed to user for past periods
	* @param user_ Address of the user
	*/
	function calculateOut(address user_) 
		external
		view
		returns (uint256)
	{
		return _calculateOut(user_);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SafeERC20 {
    
    bytes4 private constant TRANSFER_SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));
    bytes4 private constant TRANSFER_FROM_SELECTOR = bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
    bytes4 private constant APPROVE_SELECTOR = bytes4(keccak256(bytes('approve(address,uint256)')));

    function safeTransfer(address token, address to, uint value)
        internal
    {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(TRANSFER_SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SafeERC20: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value)
        internal
    {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(TRANSFER_FROM_SELECTOR, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SafeERC20: TRANSFER_FROM_FAILED');
    }

    function safeApprove(address token, address spender, uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(APPROVE_SELECTOR, spender, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SafeERC20: APPROVE_FAILED');
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 */
abstract contract ReentrancyGuard {

    uint256 private constant _NOT_ENTERED = 0;
    uint256 private constant _ENTERED = 1;

    uint256 private _status;

    modifier nonReentrant() {
        require(_status == _NOT_ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { IERC20 } from "./IERC20.sol";

/**
 * @dev Interface of the IToken Extends IERC20.
 */
interface IToken is IERC20 {

    /**
     * @dev Destroys tokens from msg.sender account
     */
    function burn(uint256 amount) external;

    /**
     * @dev Destroys tokens from account, allowance checked
     */
    function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Minimal Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     * Returns a boolean value indicating whether the operation succeeded.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     * Returns a boolean value indicating whether the operation succeeded.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     * Returns a boolean value indicating whether the operation succeeded.
     */
    function approve(address spender, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

contract Scheduller {

	//last period recorded
	uint256 public period;
	//period duration in sec
	uint256 public immutable periodTime;
	//last period start time
	uint256 public periodStartTime;

	/**
	 * @dev Scheduller constructor, saves periodTime in seconds
	 * @param periodDays_ period length in Days
	 */
	constructor (
		uint256 periodDays_
	)
	{
		periodTime = periodDays_ * (1 days);
	}

	/**
	 * @dev Updates last period to current
	 * @param startNow_ set periodStartTime = now if true
	 */
	function _updatePeriod (bool startNow_)
		virtual
		internal
	{
		uint256 _period = _currentPeriod();
		if(_period != period){
			period = _period;
			if(startNow_)
				// solhint-disable-next-line not-rely-on-time
				periodStartTime = block.timestamp;
			else
				periodStartTime = 0;
		}else{
			if(startNow_ && periodStartTime == 0)
				// solhint-disable-next-line not-rely-on-time
				periodStartTime = block.timestamp;
		}
	}

	/**
	 * @dev Returns current period
	 */
	function _currentPeriod () 
		internal 
		view 
		returns (uint256 period_)
	{
		period_ = period;
		if(periodStartTime == 0 && period_ != 0)
			return period_;
		if(block.timestamp >= periodStartTime + periodTime)
			period_ += 1; 
	}

	/**
	 * @dev Returns current period
	 */
	function currentPeriod () 
		external 
		view 
		returns (uint256)
	{
		return _currentPeriod(); 
	}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { ReentrancyGuard } from "../lib/ReentrancyGuard.sol";
import { IToken } from  "../interfaces/IToken.sol";

contract InTokenWrapper is ReentrancyGuard {
	address public immutable inToken;

	uint256 private _totalSupply;
	mapping (uint256 => uint256) private _historyTotalSupply;
	mapping(address => uint256) private _balances;
	//mapping to save period user last deposited tokens;
	mapping (address => uint256) private _userPeriod;    

	event RequestedExchange(address indexed user, uint256 amount);
	event RequestedWithdraw(address indexed user, uint256 amount);
	event ExecutedExchange(address indexed user, uint256 outAmount, uint256 inAmount);

	/**
	 * @dev TokenWrapper constructor
	 * @param inToken_ Wrapped token to be exchanged
	 */
	constructor(address inToken_) {
		inToken = inToken_;
	}

	/**
	 * @dev Get the total amount of deposited token
	 * @return uint256 total supply
	 */
	function totalSupply()
		public
		view
		returns (uint256)
	{
		return _totalSupply;
	}

	/**
	 * @dev Get the total amount of token at given period
	 * @param period_ Period for which total supply returned
	 * @return uint256 total supply
	 */
	function historyTotalSupply(uint256 period_)
		public
		view
		returns (uint256)
	{
		return _historyTotalSupply[period_];
	}

	/**
	 * @dev Get the balance of a given account
	 * @param address_ User for which to retrieve balance
	 */
	function balanceOf(address address_)
		public
		view
		returns (uint256)
	{
		return _balances[address_];
	}

	/**
	 * @dev Deposits a given amount of inToken from user
	 * @param user_ User's address     
	 * @param amount_ Units of inToken
	 * @param period_ Current period
	 */
	function _deposit(address user_, uint256 amount_, uint256 period_)
		internal
		nonReentrant
	{
		_balances[user_] += amount_;
		_totalSupply += amount_;
		_historyTotalSupply[period_] += amount_;
		_userPeriod[user_] = period_;
		IToken(inToken).transferFrom(user_, address(this), amount_);
		emit RequestedExchange(user_, amount_);
	}

	/**
	 * @dev Withdraws a given amount of inToken from user
	 * @param user_ User's address
	 * @param amount_ Units of inToken
	 * @param period_ Current period
	 */
	function _withdraw(address user_, uint256 amount_, uint256 period_)
		internal
		nonReentrant
	{
		_balances[user_] -= amount_;
		_totalSupply -= amount_;
		_historyTotalSupply[period_] -= amount_;
		IToken(inToken).transfer(user_, amount_);
		emit RequestedWithdraw(user_, amount_);
	}
	
	/**
	 * @dev Withdraw In Tokens (balance - outAmount_) & burn (outAmount_) after executeExchange
	 * @param user_ User's address 
	 * @param outAmount_ Amount of Out Tokens paid
	 */
	function _withdrawExecute(address user_, uint256 outAmount_)
		internal
		nonReentrant
	{
		uint256 _balance = _balances[user_];
		uint256 _returnAmount = _balance - outAmount_;
		_totalSupply -= _balance;
		_balances[user_] = 0;
		if(_balance > outAmount_)
			IToken(inToken).transfer(user_, _returnAmount);
		IToken(inToken).burn(outAmount_);
		emit ExecutedExchange(user_, outAmount_, _returnAmount);
	}

	/**
	 * @dev Returns Period user last deposited tokens
	 * @param address_ address of the User
	 */
	 function userPeriod(address address_)
		public
		view
		returns (uint256)
	{
		return _userPeriod[address_];
	}

}