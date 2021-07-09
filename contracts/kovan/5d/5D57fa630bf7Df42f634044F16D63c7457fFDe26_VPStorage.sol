/**
 *Submitted for verification at Etherscan.io on 2021-07-09
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
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Destroys tokens from msg.sender account
     */
    function burn(uint256 amount) external;
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
	 * @param _inToken Wrapped token to be exchanged
	 */
	constructor(address _inToken) {
		inToken = IToken(_inToken);
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
	 * @param _period Period for which total supply returned
	 * @return uint256 total supply
	 */
	function historyTotalSupply(uint256 _period)
		public
		view
		returns (uint256)
	{
		return _historyTotalSupply[_period];
	}

	/**
	 * @dev Get the balance of a given account
	 * @param _address User for which to retrieve balance
	 */
	function balanceOf(address _address)
		public
		view
		returns (uint256)
	{
		return _balances[_address];
	}

	/**
	 * @dev Deposits a given amount of inToken from user
	 * @param _user User's address     
	 * @param _amount Units of inToken
	 * @param _period Current period
	 */
	function _deposit(address _user, uint256 _amount, uint256 _period)
		internal
		nonReentrant
	{
		_balances[_user] += _amount;
		_totalSupply += _amount;
		_historyTotalSupply[_period] += _amount;
		_userPeriod[_user] = _period;
		inToken.transferFrom(_user, address(this), _amount);
		emit RequestedExchange(_user, _amount);
	}

	/**
	 * @dev Withdraws a given amount of inToken from user
	 * @param _user User's address
	 * @param _amount Units of inToken
	 * @param _period Current period
	 */
	function _withdraw(address _user, uint256 _amount, uint256 _period)
		internal
		nonReentrant
	{
		_balances[_user] -= _amount;
		_totalSupply += _amount;
		_historyTotalSupply[_period] += _amount;
		inToken.transfer(_user, _amount);
		emit RequestedWithdraw(_user, _amount);
	}
	
	/**
	 * @dev Withdraw In Tokens (balance - _out) & burn (_out) after executeExchange
	 * @param _user User's address 
	 * @param _out Amount of Out Tokens paid
	 */
	function _withdrawExecute(address _user, uint256 _out)
		internal
		nonReentrant
	{
		uint256 _balance = balanceOf(_user);
		uint256 _amount = _balance - _out;
		_totalSupply += _balance;
		_balances[_user] = 0;
		if(_balance > _out)
			inToken.transfer(_user, _amount);
		inToken.burn(_out);
		emit ExecutedExchange(_user, _out, _amount);
	}

	/**
	 * @dev Returns Period user last deposited tokens
	 * @param _address address of the User
	 */
	 function userPeriod(address _address)
		public
		view
		returns (uint256)
	{
		return _userPeriod[_address];
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
     * @param _periodDays period length in Days
     */
    constructor (
    	uint256 _periodDays
    )
    {
    	periodTime = _periodDays * (1 days);
    }

    /**
     * @dev Updates last period to current
     * @param _startNow set periodStartTime = now if true
     */
    function _updatePeriod (bool _startNow)
        internal
    {
        uint256 _currentPeriod = currentPeriod();
        if(_currentPeriod != period){
        	period = _currentPeriod;
            if(_startNow)
                // solhint-disable-next-line not-rely-on-time
                periodStartTime = block.timestamp;
            else
                periodStartTime = 0;
        }else{
            if(_startNow && periodStartTime == 0)
                // solhint-disable-next-line not-rely-on-time
                periodStartTime = block.timestamp;
        }
    }

    /**
     * @dev Returns current period
     */
    function currentPeriod () 
        public 
        view 
        returns (uint256 _currentPeriod)
    {
    	_currentPeriod = period;
    	if(periodStartTime == 0 && _currentPeriod != 0)
    		return _currentPeriod;
    	// solhint-disable-next-line not-rely-on-time
    	if(block.timestamp >= periodStartTime + periodTime)
    		_currentPeriod += 1; 
		return _currentPeriod;
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
	
	/** 
	* @dev Updates Period before executing function 
	* @dev If Period changed, calculates new period Out Token for exchange & Out Token Debt
	* @param _startNow set periodStartTime = now if true
	*/
	modifier updatePeriod(bool _startNow) {
		uint256 _period = period; 
		_updatePeriod(_startNow);
		if(_period != period){
			uint256 _nextPeriodForExchange;
			uint256 _previousPeriodDebt;
			(_nextPeriodForExchange, _previousPeriodDebt) = _getOutTokenForExchange(_period);
			historyOutTokenForExchange[period] = _nextPeriodForExchange;
			outTokenDebt += _previousPeriodDebt;
		}
		_;
	}

	/** 
	* @dev Exchange constructor, calls constructors of helper classes InTokenWrapper and Scheduller
	* @param _outToken Out Token contract address
	* @param _inToken In Token contract address
	* @param _periodDays period length in Days
	*/
	constructor(
		address _outToken,
		address _inToken,
		uint256 _periodDays
	)
		InTokenWrapper(_inToken)
		Scheduller(_periodDays)
	{
		outToken = IERC20(_outToken);
	}

	/***************************************
					PRIVATE
	****************************************/

	/** 
	* @dev Returns Out Tokens available for exchange for next period & debt for previous period
	* @param _previousPeriod - previous period
	*/
	function _getOutTokenForExchange(
		uint256 _previousPeriod
	)
		private
		view
		returns (uint256 _nextPeriodForExchange, uint256 _previousPeriodDebt)
	{
		_previousPeriodDebt = historyOutTokenForExchange[_previousPeriod];
		//If Out Token balance was greater than total In Token balance for previous period
		//reduce previous period debt to total supply
		if(_previousPeriodDebt > historyTotalSupply(_previousPeriod))
			_previousPeriodDebt = historyTotalSupply(_previousPeriod);
		_nextPeriodForExchange = outToken.balanceOf(address(this)) - outTokenDebt + _previousPeriodDebt;
		return (_nextPeriodForExchange, _previousPeriodDebt);
	}

 
	/***************************************
					ACTIONS
	****************************************/
	
	/**
	 * @dev Places amount of In Tokes to be exchanged to Out Tokens current period
	 * if user has balance for previous period executeExchage() is done first
	 * @param _amount of In Tokens Tokens
	 */
	function requestExchange(uint256 _amount)
		external
		updatePeriod(true)
	{
		require(_amount != 0, "Cannot exchange 0");
		require(historyOutTokenForExchange[period] != 0, "No Out Tokens for current period");
		address _user = msg.sender;
		uint256 _balance = balanceOf(_user);
		if(userPeriod(_user) != period && _balance != 0){
			executeExchange();
			_balance = 0;
		}
		require(_balance + _amount <= historyOutTokenForExchange[period], 
			"Balance is greater Out Tokens for period");
		_deposit(_user, _amount, period);
	}

	/**
	 * @dev Withdraws amount of In Tokens deposited current period
	 * @param _amount of In Tokens Tokens
	 */
	function requestWithdraw(uint256 _amount)
		external
		updatePeriod(false)
	{
		address _user = msg.sender;
		require (userPeriod(_user) == period, "No balance for current period");
		_withdraw(_user, _amount, period);
	}

	/**
	 * @dev Sends owed Out Tokens to sender for previos periods In Tokens deposits
	 */
	function executeExchange()
		public 
		updatePeriod(false)
	{
		address _user = msg.sender;
		uint256 _out = calculateOut(_user);
		require (_out != 0, "Nothing to exchange");
		outTokenDebt -= _out;
		outToken.safeTransfer(_user, _out);
		_withdrawExecute(_user, _out);
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
		public
		view
		returns(uint256 _outTokenForExhange)
	{
		uint256 _period = currentPeriod();
		if(period == _period)
			_outTokenForExhange = historyOutTokenForExchange[period];
		else
			(_outTokenForExhange, ) = _getOutTokenForExchange(period);
	}
	
	/**
	* @dev Returns InToken balance available for withdraw
	* @param _user Address of the user
	*/
	function getInTokenBalanceForWithdraw(address _user)
		external
		view
		returns(uint256 _balance)
	{
		uint256 _period = currentPeriod();
		uint256 _userPeriod = userPeriod(_user);
		if(_userPeriod == _period)
			_balance = balanceOf(_user);
	}

	/**
	* @dev Calculates In Tokens contract will accept from user current period
	* @param _user Address of the user
	*/
	function calculateIn(address _user)
		external
		view
		returns(uint256 _in)
	{
		uint256 _period = currentPeriod();
		uint256 _userPeriod = userPeriod(_user);
		uint256 _outTokenForExhange = getOutTokenForExchange();
		if(_userPeriod != _period){
			_in = _outTokenForExhange;
		}else{
			_in = _outTokenForExhange - balanceOf(_user);
		}
	}
	
	/**
	* @dev Calculates Out Tokens owed to user for past periods
	* @param _user Address of the user
	*/
	function calculateOut(address _user) 
		public
		view
		returns (uint256 _owed)
	{
		uint256 _period = currentPeriod();
		uint256 _userPeriod = userPeriod(_user);
		uint256 _userPeriodTotalSupply = historyTotalSupply(_userPeriod);
		if(_userPeriod != _period){
			if(historyOutTokenForExchange[_userPeriod] >= _userPeriodTotalSupply){
				_owed = balanceOf(_user);
			}else{
				_owed = historyOutTokenForExchange[_userPeriod] * balanceOf(_user)
				* CALC_PRECISION / _userPeriodTotalSupply	/	CALC_PRECISION;
			}
		}
	}
}