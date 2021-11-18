/**
 *Submitted for verification at arbiscan.io on 2021-11-18
*/

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns token decimals.
     */
    function decimals() external view returns (uint8);

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

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
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

interface IRouter {
    function trading() external view returns (address);

    function capPool() external view returns (address);

    function oracle() external view returns (address);

    function treasury() external view returns (address);

    function darkOracle() external view returns (address);

    function isSupportedCurrency(address currency) external view returns (bool);

    function currencies(uint256 index) external view returns (address);

    function currenciesLength() external view returns (uint256);

    function getDecimals(address currency) external view returns(uint8);

    function getPool(address currency) external view returns (address);

    function getPoolShare(address currency) external view returns(uint256);

    function getCapShare(address currency) external view returns(uint256);

    function getPoolRewards(address currency) external view returns (address);

    function getCapRewards(address currency) external view returns (address);
}

interface ITreasury {
    function fundOracle(address destination, uint256 amount) external;

    function notifyFeeReceived(address currency, uint256 amount) external;
}

interface IPool {
    function totalSupply() external view returns (uint256);

    function creditUserProfit(address destination, uint256 amount) external;
    
    function updateOpenInterest(uint256 amount, bool isDecrease) external;

    function getUtilization() external view returns (uint256);

    function getBalance(address account) external view returns (uint256);

}
contract Trading {

	// All amounts in 8 decimals unless otherwise indicated

	using SafeERC20 for IERC20;
    using Address for address payable;

	// Structs

	struct Product {
		uint64 maxLeverage; // set to 0 to deactivate product
		uint64 liquidationThreshold; // in bps. 8000 = 80%
		uint64 fee; // In sbps (10^6). 0.5% = 5000. 0.025% = 250
		uint64 interest; // For 360 days, in bps. 5.35% = 535
	}

	struct Position {
		uint64 size;
		uint64 margin;
		uint64 timestamp;
		uint64 price;
	}

	struct Order {
		bool isClose;
		uint64 size;
		uint64 margin;
	}

	// Contracts
	address public owner;
	address public router;
	address public treasury;
	address public oracle;

	uint256 public nextPositionId; // Incremental
	uint256 public nextCloseOrderId; // Incremental

	mapping(bytes32 => Product) private products;
	mapping(bytes32 => Position) private positions; // key = currency,user,product,direction
	mapping(bytes32 => Order) private orders; // position key => Order

	mapping(address => uint256) minMargin; // currency => amount

	mapping(address => uint256) pendingFees; // currency => amount

	uint256 public constant UNIT_DECIMALS = 8;
	uint256 public constant UNIT = 10**UNIT_DECIMALS;

	uint256 public constant PRICE_DECIMALS = 8;

	// Events
	event NewOrder(
		bytes32 indexed key,
		address indexed user,
		bytes32 indexed productId,
		address currency,
		bool isLong,
		uint256 margin,
		uint256 size,
		bool isClose
	);

	event PositionUpdated(
		bytes32 indexed key,
		address indexed user,
		bytes32 indexed productId,
		address currency,
		bool isLong,
		uint256 margin,
		uint256 size,
		uint256 price,
		uint256 fee
	);

	event ClosePosition(
		bytes32 indexed key,
		address indexed user,
		bytes32 indexed productId,
		address currency,
		bool isLong,
		uint256 price,
		uint256 margin,
		uint256 size,
		uint256 fee,
		int256 pnl,
		bool wasLiquidated
	);

	constructor() {
		owner = msg.sender;
	}

	// Governance methods

	function setOwner(address newOwner) external onlyOwner {
		owner = newOwner;
	}

	function setRouter(address _router) external onlyOwner {
		router = _router;
		treasury = IRouter(router).treasury();
		oracle = IRouter(router).oracle();
	}

	function setMinMargin(
		address currency,
		uint256 _minMargin
	) external onlyOwner {
		minMargin[currency] = _minMargin;
	}

	function addProduct(bytes32 productId, Product memory _product) external onlyOwner {
		
		Product memory product = products[productId];
		
		require(product.liquidationThreshold == 0, "!product-exists");
		require(_product.liquidationThreshold > 0, "!liqThreshold");

		products[productId] = Product({
			maxLeverage: _product.maxLeverage,
			fee: _product.fee,
			interest: _product.interest,
			liquidationThreshold: _product.liquidationThreshold
		});

	}

	function updateProduct(bytes32 productId, Product memory _product) external onlyOwner {

		Product storage product = products[productId];

		require(product.liquidationThreshold > 0, "!product-does-not-exist");

		product.maxLeverage = _product.maxLeverage;
		product.fee = _product.fee;
		product.interest = _product.interest;
		product.liquidationThreshold = _product.liquidationThreshold;

	}

	// Methods

	function distributeFees(address currency) external {
		uint256 pendingFee = pendingFees[currency];
		if (pendingFee > 0) {
			pendingFees[currency] = 0;
			_transferOut(currency, treasury, pendingFee);
			ITreasury(treasury).notifyFeeReceived(currency, pendingFee * 10**(18-UNIT_DECIMALS));
		}
	}

	function submitOrder(
		bytes32 productId,
		address currency,
		bool isLong,
		uint256 margin,
		uint256 size
	) external payable {

		if (currency == address(0)) { // User is sending ETH
			margin = msg.value / 10**(18 - UNIT_DECIMALS);
		} else {
			require(IRouter(router).isSupportedCurrency(currency), "!currency");
		}

		// Check params
		require(margin > 0, "!margin");
		require(size > 0, "!size");

		bytes32 key = _getPositionKey(msg.sender, productId, currency, isLong);

		Order memory order = orders[key];
		require(order.size == 0, "!order"); // existing order

		Product memory product = products[productId];
		uint256 fee = size * product.fee / 10**6;

		if (currency == address(0)) {
			require(margin > fee, "!margin<fee");
			margin -= fee;
		} else {
			_transferIn(currency, margin + fee);
		}

		require(margin >= minMargin[currency], "!min-margin");

		uint256 leverage = UNIT * size / margin;
		require(leverage >= UNIT, "!leverage");
		require(leverage <= product.maxLeverage, "!max-leverage");

		// Update and check pool utlization
		_updateOpenInterest(currency, size, false);
		address pool = IRouter(router).getPool(currency);
		uint256 utilization = IPool(pool).getUtilization();
		require(utilization < 10**4, "!utilization");

		orders[key] = Order({
			isClose: false,
			size: uint64(size),
			margin: uint64(margin)
		});

		emit NewOrder(
			key,
			msg.sender,
			productId,
			currency,
			isLong,
			margin,
			size,
			false
		);

	}

	function submitCloseOrder(
		bytes32 productId,
		address currency,
		bool isLong,
		uint256 size
	) external payable {

		require(size > 0, "!size");

		bytes32 key = _getPositionKey(msg.sender, productId, currency, isLong);

		Order memory order = orders[key];
		require(order.size == 0, "!order"); // existing order

		// Check position
		Position storage position = positions[key];
		require(position.margin > 0, "!position");

		if (size > position.size) {
			size = position.size;
		}

		Product memory product = products[productId];
		uint256 fee = size * product.fee / 10**6;

		if (currency == address(0)) {
			uint256 fee_units = fee * 10**(18-UNIT_DECIMALS);
			require(msg.value >= fee_units && msg.value <= fee_units * (10**6 + 1)/10**6, "!fee");
		} else {
			_transferIn(currency, fee);
		}

		uint256 margin = size * uint256(position.margin) / uint256(position.size);

		orders[key] = Order({
			isClose: true,
			size: uint64(size),
			margin: uint64(margin)
		});

		emit NewOrder(
			key,
			msg.sender,
			productId,
			currency,
			isLong,
			margin,
			size,
			true
		);

	}

	function cancelOrder(
		bytes32 productId,
		address currency,
		bool isLong
	) external {

		bytes32 key = _getPositionKey(msg.sender, productId, currency, isLong);

		Order memory order = orders[key];
		require(order.size > 0, "!exists");

		Product memory product = products[productId];
		uint256 fee = order.size * product.fee / 10**6;

		_updateOpenInterest(currency, order.size, true);

		delete orders[key];

		// Refund margin + fee
		uint256 marginPlusFee = order.margin + fee;
		_transferOut(currency, msg.sender, marginPlusFee);

	}

	// Set price for newly submitted order (oracle)
	function settleOrder(
		address user,
		bytes32 productId,
		address currency,
		bool isLong,
		uint256 price
	) external onlyOracle {

		bytes32 key = _getPositionKey(user, productId, currency, isLong);

		Order storage order = orders[key];
		require(order.size > 0, "!exists");

		// fee
		Product memory product = products[productId];
		uint256 fee = order.size * product.fee / 10**6;
		pendingFees[currency] += fee;

		if (order.isClose) {
			
			{
				(uint256 margin, uint256 size, int256 pnl) = _settleCloseOrder(user, productId, currency, isLong, price);

				address pool = IRouter(router).getPool(currency);

				if (pnl < 0) {
					{
						uint256 positivePnl = uint256(-1 * pnl);
						_transferOut(currency, pool, positivePnl);
						if (positivePnl < margin) {
							_transferOut(currency, user, margin - positivePnl);
						}
					}
				} else {
					IPool(pool).creditUserProfit(user, uint256(pnl) * 10**(18-UNIT_DECIMALS));
					_transferOut(currency, user, margin);
				}

				_updateOpenInterest(currency, size, true);

				emit ClosePosition(
					key, 
					user,
					productId,
					currency,
					isLong,
					price,
					margin,
					size,
					fee,
					pnl,
					false
				);

			}

		} else {

			// Validate price, returns 8 decimals
			price = _validatePrice(price);

			Position storage position = positions[key];

			uint256 averagePrice = (uint256(position.size) * uint256(position.price) + uint256(order.size) * uint256(price)) / (uint256(position.size) + uint256(order.size));

			if (position.timestamp == 0) {
				position.timestamp = uint64(block.timestamp);
			}

			position.size += uint64(order.size);
			position.margin += uint64(order.margin);
			position.price = uint64(averagePrice);

			delete orders[key];

			emit PositionUpdated(
				key,
				user,
				productId,
				currency,
				isLong,
				position.margin,
				position.size,
				position.price,
				fee
			);

		}

	}

	function _settleCloseOrder(
		address user,
		bytes32 productId,
		address currency,
		bool isLong,
		uint256 price
	) internal returns(uint256, uint256, int256) {

		bytes32 key = _getPositionKey(user, productId, currency, isLong);

		// Check order and params
		Order memory order = orders[key];
		uint256 size = order.size;
		uint256 margin = order.margin;

		Position storage position = positions[key];
		require(position.margin > 0, "!position");

		Product memory product = products[productId];

		price = _validatePrice(price);

		int256 pnl = _getPnL(isLong, price, position.price, size, product.interest, position.timestamp);

		// Check if it's a liquidation
		if (pnl <= -1 * int256(uint256(position.margin) * uint256(product.liquidationThreshold) / 10**4)) {
			pnl = -1 * int256(uint256(position.margin));
			margin = position.margin;
			size = position.size;
			position.margin = 0;
		} else {
			position.margin -= uint64(margin);
			position.size -= uint64(size);
		}
		
		if (position.margin == 0) {
			delete positions[key];
		}

		delete orders[key];

		return (margin, size, pnl);

	}

	// Liquidate positionIds (oracle)
	function liquidatePosition(
		address user,
		bytes32 productId,
		address currency,
		bool isLong,
		uint256 price
	) external onlyOracle {

		bytes32 key = _getPositionKey(user, productId, currency, isLong);

		Position memory position = positions[key];

		if (position.margin == 0 || position.size == 0) {
			return;
		}

		Product storage product = products[productId];

		price = _validatePrice(price);

		int256 pnl = _getPnL(isLong, price, position.price, position.size, product.interest, position.timestamp);

		uint256 threshold = position.margin * product.liquidationThreshold / 10**4;

		if (pnl <= -1 * int256(threshold)) {

			uint256 fee = position.margin - threshold;
			address pool = IRouter(router).getPool(currency);

			_transferOut(currency, pool, threshold);
			_updateOpenInterest(currency, position.size, true);
			pendingFees[currency] += fee;

			emit ClosePosition(
				key, 
				user,
				productId,
				currency,
				isLong,
				price,
				position.margin,
				position.size,
				fee,
				-1 * int256(uint256(position.margin)),
				true
			);

			delete positions[key];

		}

	}

	function releaseMargin(
		address user,
		bytes32 productId,
		address currency,
		bool isLong, 
		bool includeFee
	) external onlyOwner {

		bytes32 key = _getPositionKey(user, productId, currency, isLong);

		Position storage position = positions[key];
		require(position.margin > 0, "!position");

		uint256 margin = position.margin;

		emit ClosePosition(
			key, 
			user,
			productId,
			currency,
			isLong,
			position.price,
			margin,
			position.size,
			0,
			0,
			false
		);

		delete orders[key];

		if (includeFee) {
			Product memory product = products[productId];
			uint256 fee = position.size * product.fee / 10**6;
			margin += fee;
		}

		_updateOpenInterest(currency, position.size, true);
		
		delete positions[key];

		_transferOut(currency, user, margin);

	}

	// To receive ETH
	fallback() external payable {}
	receive() external payable {}

	// Internal methods

	function _getPositionKey(address user, bytes32 productId, address currency, bool isLong) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(user, productId, currency, isLong));
    }

	function _updateOpenInterest(address currency, uint256 amount, bool isDecrease) internal {
		address pool = IRouter(router).getPool(currency);
		IPool(pool).updateOpenInterest(amount * 10**(18 - UNIT_DECIMALS), isDecrease);
	}

	function _transferIn(address currency, uint256 amount) internal {
		if (amount == 0 || currency == address(0)) return;
		// adjust decimals
		uint256 decimals = IRouter(router).getDecimals(currency);
		amount = amount * (10**decimals) / (10**UNIT_DECIMALS);
		IERC20(currency).safeTransferFrom(msg.sender, address(this), amount);
	}

	function _transferOut(address currency, address to, uint256 amount) internal {
		if (amount == 0 || to == address(0)) return;
		// adjust decimals
		uint256 decimals = IRouter(router).getDecimals(currency);
		amount = amount * (10**decimals) / (10**UNIT_DECIMALS);
		if (currency == address(0)) {
			payable(to).sendValue(amount);
		} else {
			IERC20(currency).safeTransfer(to, amount);
		}
	}

	function _validatePrice(
		uint256 price // 8 decimals
	) internal pure returns(uint256) {
		require(price > 0, "!price");
		return price * 10**(UNIT_DECIMALS - PRICE_DECIMALS);
	}
	
	function _getPnL(
		bool isLong,
		uint256 price,
		uint256 positionPrice,
		uint256 size,
		uint256 interest,
		uint256 timestamp
	) internal view returns(int256 _pnl) {

		bool pnlIsNegative;
		uint256 pnl;

		if (isLong) {
			if (price >= positionPrice) {
				pnl = size * (price - positionPrice) / positionPrice;
			} else {
				pnl = size * (positionPrice - price) / positionPrice;
				pnlIsNegative = true;
			}
		} else {
			if (price > positionPrice) {
				pnl = size * (price - positionPrice) / positionPrice;
				pnlIsNegative = true;
			} else {
				pnl = size * (positionPrice - price) / positionPrice;
			}
		}

		// Subtract interest from P/L
		if (block.timestamp >= timestamp + 15 minutes) {

			uint256 _interest = size * interest * (block.timestamp - timestamp) / (UNIT * 10**4 * 360 days);

			if (pnlIsNegative) {
				pnl += _interest;
			} else if (pnl < _interest) {
				pnl = _interest - pnl;
				pnlIsNegative = true;
			} else {
				pnl -= _interest;
			}

		}

		if (pnlIsNegative) {
			_pnl = -1 * int256(pnl);
		} else {
			_pnl = int256(pnl);
		}

		return _pnl;

	}

	// Getters

	function getProduct(bytes32 productId) external view returns(Product memory) {
		return products[productId];
	}

	function getPosition(
		address user,
		address currency,
		bytes32 productId,
		bool isLong
	) external view returns(Position memory position) {
		bytes32 key = _getPositionKey(user, productId, currency, isLong);
		return positions[key];
	}

	function getOrder(
		address user,
		address currency,
		bytes32 productId,
		bool isLong
	) external view returns(Order memory order) {
		bytes32 key = _getPositionKey(user, productId, currency, isLong);
		return orders[key];
	}

	function getOrders(bytes32[] calldata keys) external view returns(Order[] memory _orders) {
		uint256 length = keys.length;
		_orders = new Order[](length);
		for (uint256 i = 0; i < length; i++) {
			_orders[i] = orders[keys[i]];
		}
		return _orders;
	}

	function getPositions(bytes32[] calldata keys) external view returns(Position[] memory _positions) {
		uint256 length = keys.length;
		_positions = new Position[](length);
		for (uint256 i = 0; i < length; i++) {
			_positions[i] = positions[keys[i]];
		}
		return _positions;
	}

	function getPendingFee(address currency) external view returns(uint256) {
		return pendingFees[currency] * 10**(18-UNIT_DECIMALS);
	}

	// Modifiers

	modifier onlyOracle() {
		require(msg.sender == oracle, "!oracle");
		_;
	}

	modifier onlyOwner() {
		require(msg.sender == owner, "!owner");
		_;
	}

}