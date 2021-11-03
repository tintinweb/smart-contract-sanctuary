/**
 *Submitted for verification at polygonscan.com on 2021-11-03
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;


// 
/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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

    constructor() {
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */

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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface IwETH {
	function balanceOf(address) external view returns (uint256);
	function deposit() external payable;
	function withdraw(uint256 wad) external;
	function approve(address guy, uint wad) external returns (bool);
	function transferFrom(address src, address dst, uint256 wad) external returns (bool);
	function transfer(address dst, uint wad) external returns (bool);
}

interface IAddressesProvider {
	function getLendingPool() external returns (address);
	function getPriceOracle() external view returns (address);
}

interface ILendingPool {
	function deposit(
		address asset,
		uint256 amount,
		address onBehalfOf,
		uint16 referralCode
	) external;	
	 function withdraw(
		address asset,
		uint256 amount,
		address to
	) external returns (uint256);
	function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);
}

interface IPriceOracle {
	function getAssetPrice(address _asset) external view returns (uint256);
}

library DataTypes {
	// refer to the whitepaper, section 1.1 basic concepts for a formal description of these properties.
	struct ReserveData {
		//stores the reserve configuration
		ReserveConfigurationMap configuration;
		//the liquidity index. Expressed in ray
		uint128 liquidityIndex;
		//variable borrow index. Expressed in ray
		uint128 variableBorrowIndex;
		//the current supply rate. Expressed in ray
		uint128 currentLiquidityRate;
		//the current variable borrow rate. Expressed in ray
		uint128 currentVariableBorrowRate;
		//the current stable borrow rate. Expressed in ray
		uint128 currentStableBorrowRate;
		uint40 lastUpdateTimestamp;
		//tokens addresses
		address aTokenAddress;
		address stableDebtTokenAddress;
		address variableDebtTokenAddress;
		//address of the interest rate strategy
		address interestRateStrategyAddress;
		//the id of the reserve. Represents the position in the list of the active reserves
		uint8 id;
	}
	struct ReserveConfigurationMap {
		//bit 0-15: LTV
		//bit 16-31: Liq. threshold
		//bit 32-47: Liq. bonus
		//bit 48-55: Decimals
		//bit 56: Reserve is active
		//bit 57: reserve is frozen
		//bit 58: borrowing is enabled
		//bit 59: stable rate borrowing enabled
		//bit 60-63: reserved
		//bit 64-79: reserve factor
		uint256 data;
	}
}

interface IRewardsController {
	function getRewardsBalance(address[] calldata assets, address user) external view returns(uint256);
	function claimRewards(address[] calldata assets, uint256 amount, address to) external returns (uint256);
}

// 
interface ILender {
	function wETH() external view returns(address);
	function borrowCoefficient() external view returns (uint256);
	function liquidationCoefficient() external view returns (uint256);
	function liquidationBonusCoefficient() external view returns (uint256);
}

contract Borrower is Ownable, ReentrancyGuard {
	using SafeERC20 for IERC20;

	uint256 constant public PCT_PRECISION = 1e6;

	IwETH public wETH;
	ILender public lender;
	IERC20 public reserve; 
	uint256 public reserveDecimals;
	IERC20 public aToken;

	IAddressesProvider public addressProvider;
	ILendingPool public lendingPool;
	IPriceOracle public priceOracle;
	uint16 private referralCode;
	IRewardsController public rewardsController;
	address rewardsBeneficiary;

	uint256 public totalBalance;
	struct UserData {
		uint256 balance; // amount in reserve decimals
		uint256 debt;	// amount in ETH decimals (18)
	}
	mapping(address => UserData) private userData;

	mapping (address => uint256) public feePaid;

	event Deposit(address borrower, uint256 amount);
	event Withdraw(address borrower, uint256 amount);
	event Borrow(address borrower, uint256 amount);
	event Repay(address borrower, uint256 amount);
	event Liquidate(address borrower, uint256 amountLiqidated, address liquidator);

	modifier onlyAmountGreaterThanZero(uint256 amount_) {
		require(amount_ != 0, "amount must be greater than 0");
		_;
	}

	constructor(
		address lender_,
		address reserve_,
		uint256 reserveDecimals_,
		address addressProvider_,
		uint16 referralCode_, 
		address rewardsController_,
		address rewardsBeneficiary_) 
	{
		lender = ILender(lender_);
		wETH = IwETH(lender.wETH());
		reserve = IERC20(reserve_);
		reserveDecimals = reserveDecimals_;
		addressProvider = IAddressesProvider(addressProvider_);
		referralCode = referralCode_;
		rewardsController = IRewardsController(rewardsController_);
		updateLendingPoolAddress();
		updateaTokenAddress();
		updatePriceOracle();
		updateRewardsBeneficiary(rewardsBeneficiary_);
	}

	// for wETH withdraw
	receive() external payable {
	}

	/***************************************
					ADMIN
	****************************************/

	function updateLendingPoolAddress()
		public
	{
		address _lendingPool =addressProvider.getLendingPool();
		require(address(lendingPool) != _lendingPool);
		lendingPool = ILendingPool(_lendingPool);
		reserve.safeApprove(_lendingPool, 0);
		reserve.safeApprove(_lendingPool, type(uint256).max);
	}

	function updateaTokenAddress()
		public
	{
		DataTypes.ReserveData memory _reserveData;
		_reserveData = lendingPool.getReserveData(address(reserve));
		require(address(aToken) != _reserveData.aTokenAddress);
		aToken = IERC20(_reserveData.aTokenAddress);
	}

	function updatePriceOracle()
		public
	{
		address _priceOracle = addressProvider.getPriceOracle();
		require(address(priceOracle) != _priceOracle);
		priceOracle =  IPriceOracle(_priceOracle);
	}

	function updateRewardsBeneficiary(address rewardsBeneficiary_)
		public
		onlyOwner
	{
		require(rewardsBeneficiary != rewardsBeneficiary_);
		rewardsBeneficiary = rewardsBeneficiary_;
	}

	function getFee(address lender_, uint256 amount_)
		external
		returns(uint256 feePaid_)
	{
		require(msg.sender == address(lender), "wrong caller");
		require(amount_ > feePaid[lender_], "no fee available");
		feePaid_ = amount_ - feePaid[lender_];		
		require(feePaid_ <= aToken.balanceOf(address(this)) - totalBalance, "bad fee amount");
		feePaid[lender_] += feePaid_;
		lendingPool.withdraw(address(reserve), feePaid_, lender_);
	}

	/***************************************
					PRIVATE
	****************************************/

	function _deposit(uint256 amount_)
		private
		onlyAmountGreaterThanZero(amount_)
	{
		reserve.safeTransferFrom(msg.sender, address(this), amount_);
		lendingPool.deposit(address(reserve), amount_, address(this), referralCode);
		userData[msg.sender].balance += amount_;
		totalBalance += amount_;
		emit Deposit(msg.sender, amount_);
	}

	function _withdraw(uint256 amount_)
		private
		onlyAmountGreaterThanZero(amount_)
	{
		UserData storage _user = userData[msg.sender];
		if(_user.debt != 0){
			require(amount_ <= _getAvailableWithdraw(
				_user.balance, _user.debt, _getPrice(), lender.borrowCoefficient()),
				"amount greater than available to withdraw");
		}else{
			require(_user.balance >= amount_, "amount greater than balance");
		}
		_user.balance -= amount_;
		totalBalance -= amount_;
		lendingPool.withdraw(address(reserve), amount_, msg.sender);
		emit Withdraw(msg.sender, amount_);
	}

	function _borrow(uint256 amount_, bool unwrap_)
		private
		onlyAmountGreaterThanZero(amount_)
		returns(uint256)
	{
		UserData storage _user = userData[msg.sender];
		uint256 _availableBorrow = _getAvailableBorrow(
			_user.balance, _user.debt, _getPrice(), lender.borrowCoefficient());
		require(_availableBorrow != 0,  "no borrow available");
		if(amount_ == type(uint256).max)
			amount_ = _availableBorrow;
		else
			require(amount_ <= _availableBorrow, "not ehough collateral");
		require(wETH.balanceOf(address(lender)) >= amount_, "not enough weth balance on lender contract");
		_user.debt += amount_;
		if(unwrap_){
			wETH.transferFrom(address(lender), address(this), amount_);
			wETH.withdraw(amount_);
			(bool _success, ) = msg.sender.call{value: amount_}("");
			require(_success, "transfer failed");
		}else{
			wETH.transferFrom(address(lender), msg.sender, amount_);
		}		
		emit Borrow(msg.sender, amount_);
		return amount_;
	}

	function _repay(uint256 amount_, bool wrap_)
		private
		onlyAmountGreaterThanZero(amount_)
	{
		UserData storage _user = userData[msg.sender];
		require(_user.debt >= amount_, "amount is greater than debt");
		if(wrap_){
			require(amount_ == msg.value, "wrong msg.value");
			wETH.deposit{value: amount_}();
			wETH.transfer(address(lender), amount_);
		}else{
			require(msg.value == 0, "non-zero msg.value");
			wETH.transferFrom(msg.sender, address(lender), amount_);
		}		
		_user.debt -= amount_;
		emit Repay(msg.sender, amount_);
	}

	function _getAvailableBorrow(uint256 balance_, uint256 debt_, uint256 price_, uint256 borrowCoefficient_)
		private
		view
		returns(uint256)
	{
		uint256 _maxAvailableBorrow = balance_ * price_ * borrowCoefficient_ / (10**reserveDecimals) / PCT_PRECISION;
		if(_maxAvailableBorrow > debt_)
			return _maxAvailableBorrow - debt_;
		else
			return 0;
	}

	function _getAvailableWithdraw(uint256 balance_, uint256 debt_, uint256 price_, uint256 borrowCoefficient_)
		private
		view
		returns(uint256)
	{ 
		uint256 _debtCost = debt_ * (10**reserveDecimals) / price_;
		uint256 _collaterizedBalance =  _debtCost * PCT_PRECISION / borrowCoefficient_;
		if( balance_ > _collaterizedBalance)
			return balance_ - _collaterizedBalance;
		else
			return 0;
	}

	function _getHealthFactor(uint256 balance_, uint256 debt_, uint256 price_, uint256 liquidationCoefficient_)
		private
		view
		returns(uint256)
	{
		uint256 _debtCost = debt_ * (10**reserveDecimals) / price_;
		return balance_ * liquidationCoefficient_ / _debtCost;
	}

	function _getLiquidationAmount(uint256 balance_, uint256 debt_, uint256 price_)
		private
		view
		returns(uint256 liquidationAmount_)
	{
		uint256 _debtCost = debt_ * (10**reserveDecimals) / price_;
		if(balance_ > _debtCost) {
			liquidationAmount_ = _debtCost + (balance_ - _debtCost) * lender.liquidationBonusCoefficient() / PCT_PRECISION;
		}else{
			liquidationAmount_ = balance_;
		}
	}

	function _getPrice()
		private
		view
		returns(uint256 price_)
	{
		price_ = priceOracle.getAssetPrice(address(reserve));
		require(price_ != 0, "oracle price error");
	}

	/***************************************
					ACTIONS
	****************************************/

	function deposit(uint256 amount_)
		external
		nonReentrant
	{
		_deposit(amount_);
	}

	function withdraw(uint256 amount_)
		external
		nonReentrant
	{
		_withdraw(amount_);
	}

	function borrow(uint256 amount_, bool unwrap_)
		external
		nonReentrant
		returns(uint256)
	{
		return _borrow(amount_, unwrap_);
	}

	function repay(uint256 amount_, bool wrap_)
		external
		payable
		nonReentrant
	{
		_repay(amount_, wrap_);
	}

	function depositAndBorrow(uint256 amountDeposit_, uint256 amountBorrow_, bool unwrap_)
		external
		nonReentrant
		returns(uint256)
	{
		_deposit(amountDeposit_);
		return _borrow(amountBorrow_, unwrap_);
	}

	function repayAndWithdraw(uint256 amountRepay_, uint256 amontWithdraw_, bool wrap_)
		external
		payable
		nonReentrant
	{
		_repay(amountRepay_, wrap_);
		_withdraw(amontWithdraw_);
	}

	function liquidate(address borrower_, bool wrap_)
		external
		payable
		nonReentrant
		returns(uint256 liquidationAmount_)
	{
		UserData storage _user = userData[borrower_];
		require(_user.debt != 0, "user has no debt");
		uint256 _price = _getPrice();
		uint256 _liquidationCoefficient = lender.liquidationCoefficient();
		require(_getHealthFactor(_user.balance, _user.debt, _price, _liquidationCoefficient) <= PCT_PRECISION,
			"attempt to liquidate healthy position");
		if(wrap_){
			require(_user.debt == msg.value, "wrong msg.value");
			wETH.deposit{value: _user.debt}();
			wETH.transfer(address(lender), _user.debt);
		}else{
			require(msg.value == 0, "non-zero msg.value");
			wETH.transferFrom(msg.sender, address(lender), _user.debt);
		}
		liquidationAmount_ = _getLiquidationAmount(_user.balance, _user.debt, _price);
		lendingPool.withdraw(address(reserve), liquidationAmount_, msg.sender);
		_user.balance -= liquidationAmount_; 
		_user.debt = 0;
		totalBalance -= liquidationAmount_;
		emit Liquidate(borrower_, liquidationAmount_, msg.sender);
	}	

	function claimRewards()
		external
		returns(uint256)
	{
		address[] memory assets_ = new address[](1);
		assets_[0] = address(aToken);
		return rewardsController.claimRewards(assets_, type(uint256).max, rewardsBeneficiary);
	}

	/***************************************
					GETTERS
	****************************************/
	
	function getUserData(address borrower_)
		external
		view
		returns (
			uint256 balance_,
			uint256 debt_,
			uint256 availableWithdraw_,
			uint256 availableBorrow_,
			uint256 healthFactor_
		)
	{
		UserData memory _user = userData[borrower_];
		uint256 _price = _getPrice();
		balance_ = _user.balance;
		debt_ = _user.debt;
		healthFactor_ = PCT_PRECISION;
		if(_user.balance != 0){
			uint256 _borrowCoefficient = lender.borrowCoefficient();
			if(_user.debt != 0){
				availableWithdraw_ = _getAvailableWithdraw(_user.balance, _user.debt, _price, _borrowCoefficient);
				healthFactor_ = _getHealthFactor(_user.balance, _user.debt, _price, lender.liquidationCoefficient());
			}else{
				availableWithdraw_ = _user.balance;
			}
			availableBorrow_ =  _getAvailableBorrow(_user.balance, _user.debt, _price, _borrowCoefficient);
		}
	}

	function getAvailableBorrow(address borrower_, uint256 amountDeposit_)
		external
		view
		returns(uint256 availableBorrow_)
	{
		UserData memory _user = userData[borrower_];
		if(_user.balance + amountDeposit_ != 0){
			availableBorrow_ = _getAvailableBorrow(
				_user.balance + amountDeposit_, _user.debt, _getPrice(), lender.borrowCoefficient());
		}
	}
	
	function getAvailableWithdraw(address borrower_, uint256 amountRepay_)
		external
		view
		returns(uint256 availableWithdraw_)
	{
		UserData memory _user = userData[borrower_];
		require(_user.debt >= amountRepay_, "repay amount greater than debt");
		if(_user.debt != 0){
			availableWithdraw_ =  _getAvailableWithdraw(
				_user.balance, _user.debt - amountRepay_, _getPrice(), lender.borrowCoefficient());
		}else{
			availableWithdraw_ =  _user.balance;
		}
	}

	function getLiquidationAmount(address borrower_)
		external
		view
		returns(uint256 liquidationAmount_)
	{
		UserData memory _user = userData[borrower_];
		if(_user.debt != 0){
			uint256 _price = _getPrice();
			if(_getHealthFactor(_user.balance, _user.debt, _price, lender.liquidationCoefficient()) <= PCT_PRECISION) {
				liquidationAmount_ = _getLiquidationAmount(_user.balance, _user.debt, _price);
			}
		}
	}

	function getPrice() external view returns(uint256)
	{
		return _getPrice();
	}

	function getRewardsBalance() external view returns(uint256)
	{
		address[] memory assets_ = new address[](1);
		assets_[0] = address(aToken);
		return rewardsController.getRewardsBalance(assets_, address(this));
	}
}