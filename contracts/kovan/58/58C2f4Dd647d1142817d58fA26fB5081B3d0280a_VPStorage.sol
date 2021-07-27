/**
 *Submitted for verification at Etherscan.io on 2021-07-27
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;


// 
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

// 
/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

interface IToken is IERC20 {

    /**
     * @dev Destroys tokens from account, allowance checked if account is not msg.sender
     */
    function burnFrom(address account, uint256 amount) external;
}

contract InTokenWrapper is ReentrancyGuard {
	IToken public inToken;

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
		inToken = IToken(inToken_);
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
		inToken.transferFrom(user_, address(this), amount_);
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
		inToken.transfer(user_, amount_);
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
			inToken.transfer(user_, _returnAmount);
		inToken.burnFrom(address(this), outAmount_);
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

contract Scheduller {

	//last period recorded
	uint256 public period;
	//period duration in sec
	uint256 public periodTime;
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

// 
contract VPStorage is Scheduller, InTokenWrapper {
	using SafeERC20 for IERC20;
	
	//Calc precision constant
	uint256 private constant CALC_PRECISION = 1e18; 
	//Out Token Interface
	IERC20 public outToken;
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
		outToken = IERC20(outToken_);
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
		nextPeriodForExchange_ = outToken.balanceOf(address(this)) - outTokenDebt - previousPeriodDebt_;
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