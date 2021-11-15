pragma solidity 0.7.6;
pragma abicoder v2;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
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
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(
                oldAllowance >= value,
                "SafeERC20: decreased allowance below zero"
            );
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    newAllowance
                )
            );
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

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

abstract contract IAuxiv3 {
    function getHistoricalPriceCurrency(uint80 roundId, address oracle)
        public
        view
        virtual
        returns (int256);

    function getlatestAnswerCurrency(string memory assetID)
        public
        view
        virtual
        returns (int256);

    function getCurrencyTimeStampForRoundId(uint80 roundId, address oracle)
        public
        view
        virtual
        returns (uint256);

    function getCurrencyAverageDifferenceInTimeStamps(uint256 n, address oracle)
        public
        view
        virtual
        returns (uint256);

    function getCurrencyPriceForTimeStamp(
        uint256 _timestamp,
        string memory assetID
    ) public view virtual returns (int256);

    function getAsset(string memory _AssetID)
        public
        view
        virtual
        returns (address);

    function getOracle(string memory _AssetID)
        public
        view
        virtual
        returns (address);

    function addAsset(
        string memory _AssetID,
        address _AssetAddress,
        address _AssetOracle
    ) public virtual;

    function addPair(string memory Asset1, string memory Asset2) public virtual;

    function checkPairExistance(string memory Asset1, string memory Asset2)
        public
        view
        virtual
        returns (bool);

    function currtousd(uint256 curr, string memory assetID)
        public
        view
        virtual
        returns (uint256);

    function usdtocurr(uint256 usd, string memory assetID)
        public
        view
        virtual
        returns (uint256);
}

contract Betting {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    IAuxiv3 internal assetData;
    address public auxiAddress;

    event UpdateUserBalance(
        address User,
        string AssetID,
        uint256 Quantity,
        string Operation
    );

    event CreateBET(
        string betID,
        uint256 betsize,
        string assetID,
        uint256 assetQuantity,
        uint256 end_time,
        uint256 expiry_time,
        string second_assetID
    );

    event DRAW(
        string BETID,
        uint256 PRIMARY_ASSET_VALUE,
        uint256 SECONDARY_ASSET_VALUE,
        uint256 PRIMARY_PRICE,
        uint256 SECONDARY_PRICE
    );

    event PRIMARY_WON(
        string BETID,
        uint256 PRIMARY_ASSET_VALUE,
        uint256 SECONDARY_ASSET_VALUE,
        uint256 PRIMARY_PRICE,
        uint256 SECONDARY_PRICE
    );

    event SECONDARY_WON(
        string BETID,
        uint256 PRIMARY_ASSET_VALUE,
        uint256 SECONDARY_ASSET_VALUE,
        uint256 PRIMARY_PRICE,
        uint256 SECONDARY_PRICE
    );

    event JoinBET(
        address sender,
        string betID,
        string Operation,
        uint256 end_time,
        uint256 bet_size,
        uint256 quantity
    );

    event BetExpired(string BETID);

    string[] public trimAssist;

    uint256 DAY;
    uint256 PRECISION;
    uint256 last_checkpoint_timestamp;
    address public owner;
    uint256 public transfer_fee;
    uint256 public penalty_fee;

    address public fee_address;

    uint256 arbit;
    mapping(uint256 => string[]) public joinedBets;

    struct BET {
        string asset_id_creator;
        uint256 asset_creator_qty;
        string asset_id_joiner;
        uint256 asset_joiner_qty;
        uint256 bet_size;
        uint256 end_time;
        uint256 expiry_time;
        bool completed;
        address creator_address;
        address joiner_address;
    }

    mapping(string => BET) public betids;

    struct userBalance {
        uint256 lockedBalance;
        uint256 totalBalance;
    }

    mapping(address => mapping(string => userBalance)) public balances;

    struct BET_INFO {
        string _bet_id;
        uint256 _bet_size;
        string _asset_id_creator;
        string _asset_id_joiner;
        uint256 _asset_creator_qty;
        uint256 _asset_joiner_qty;
        uint256 _expiry_time;
        uint256 end_time;
        string operation;
    }

    constructor(
        address _auxiAddress,
        address _admin_fee_address,
        uint256 _transfer_fee,
        uint256 _penalty_fee
    ) public {
        auxiAddress = _auxiAddress;
        assetData = IAuxiv3(auxiAddress);
        owner = msg.sender;
        DAY = 86400;
        PRECISION = 10**18;
        transfer_fee = _transfer_fee;
        penalty_fee = _penalty_fee;
        fee_address = _admin_fee_address;
        arbit = 1;
    }

    // Checks if the values of 2 entities have a difference of < 1 in the LSB.
    function normalizeEquality(uint256 val1, uint256 val2) internal pure {
        if (val1 > val2) {
            if (val1 - val2 > 2) {
                revert("values not normally equal");
            }
        } else {
            if (val2 - val1 > 2) {
                revert("values not normally equal");
            }
        }
    }

    // Returns the quantity, i.e the amount of asset for a given bet size.
    function getQuantity(string memory assetID, uint256 _bet_size)
        public
        view
        returns (uint256)
    {
        return (assetData.usdtocurr(_bet_size, assetID));
    }

    // Returns the value, i.e the value of asset for the given quantity.
    function getValue(string memory assetID, uint256 _asset_Quantity)
        public
        view
        returns (uint256)
    {
        return (assetData.currtousd(_asset_Quantity, assetID));
    }

    /*
    Function : createBet
    Params:
        _bet_size : USD Value of the Bet.
        _assetID : Bet Asset Symbol (ETH, BTC, LTC ...)
        _asset_Quantity : Amount of Asset.
        _end_time : Time in seconds, i.e #Seconds after which the bet will end, once a user joins. E.g. 86400 ~ 1 Day
        _expiry_time : Time in seconds, i.e #Seconds after which the bet will expiry if no user joins. E.g 86400 ~ 1 Day
        second_assetID : Bet Assest Symbol (ETH, BTC, LTC ...)
    */
    function createBet(
        uint256 _bet_size,
        string memory _assetID,
        uint256 _asset_Quantity,
        uint256 _end_time,
        uint256 _expiry_time,
        string memory second_assetID
    ) public {
        normalizeEquality(_bet_size, getValue(_assetID, _asset_Quantity));

        require(
            _expiry_time < _end_time,
            "End time can't be less than Expiry time"
        );
        require(
            !stringEquality(_assetID, second_assetID),
            "Both the Coins can't be same"
        );

        // Updating the expiry time w.r.t current timestamp.
        uint256 expiry_time = block.timestamp + _expiry_time;

        // Current wallet balance of the user for the given asset.
        uint256 x = balances[msg.sender][_assetID].totalBalance -
            balances[msg.sender][_assetID].lockedBalance;

        // Deposit more asset incase the wallet balance is not sufficient.
        if (_asset_Quantity > x) {
            IERC20 assetOBJ = IERC20(assetData.getAsset(_assetID));
            assetOBJ.safeTransferFrom(
                msg.sender,
                address(this),
                _asset_Quantity - x
            );

            // Update the user total balance with the deposited quantity.
            updateUserBalance(
                _assetID,
                _asset_Quantity - x,
                "deposit",
                msg.sender
            );
        }

        // Get the timestamp for the current day, i.e rounded off to the start of the day.
        string memory expiry_day = uint2str(
            ((block.timestamp + _end_time) / DAY) * DAY
        );
        string memory blocknum = uint2str(arbit);
        arbit += 1;

        // Generate the bet id.
        string memory _bet_id = string(
            abi.encodePacked(expiry_day, "|", blocknum)
        );

        // Store the bet details.
        BET_INFO memory v1 = BET_INFO(
            _bet_id,
            _bet_size,
            _assetID,
            second_assetID,
            _asset_Quantity,
            0,
            expiry_time,
            _end_time,
            "create"
        );
        updateBetMapping(v1);

        // Add the bet id to the active bet list.
        uint256 end_day_of_bet = (expiry_time / DAY) * DAY;
        string[] storage _bets = joinedBets[end_day_of_bet];
        _bets.push(_bet_id);
        joinedBets[end_day_of_bet] = _bets;

        user_checkpoint(block.timestamp);

        emit CreateBET(
            _bet_id,
            _bet_size,
            _assetID,
            _asset_Quantity,
            _end_time,
            expiry_time,
            second_assetID
        );
    }

    // Checks if two strings are equal or not.
    function stringEquality(string memory a, string memory b)
        public
        pure
        returns (bool)
    {
        return (keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked((b))));
    }

    // Based on the operation update the user balance.
    function updateUserBalance(
        string memory _assetID,
        uint256 _qty,
        string memory _operation,
        address useraddr
    ) internal {
        if (stringEquality(_operation, "deposit")) {
            balances[useraddr][_assetID].totalBalance += _qty;
        } else if (stringEquality(_operation, "join")) {
            balances[useraddr][_assetID].lockedBalance += _qty;
        } else if (stringEquality(_operation, "fullfill")) {
            balances[useraddr][_assetID].lockedBalance -= _qty;
        } else if (stringEquality(_operation, "withdraw")) {
            balances[useraddr][_assetID].totalBalance -= _qty;
        }
        emit UpdateUserBalance(msg.sender, _assetID, _qty, _operation);
    }

    // Update the bet details based on the operation of the user.
    function updateBetMapping(BET_INFO memory valuePass) internal {
        string memory _bet_id = valuePass._bet_id;
        uint256 _bet_size = valuePass._bet_size;
        string memory primary_id = valuePass._asset_id_creator;
        string memory secondry_id = valuePass._asset_id_joiner;
        uint256 QuantityA = valuePass._asset_creator_qty;
        uint256 QuantityB = valuePass._asset_joiner_qty;
        uint256 _expiry_time = valuePass._expiry_time;
        uint256 _end_time = valuePass.end_time;
        string memory _operation = valuePass.operation;

        if (stringEquality(_operation, "create")) {
            betids[_bet_id] = BET(
                primary_id,
                QuantityA,
                secondry_id,
                QuantityB,
                _bet_size,
                _end_time,
                _expiry_time,
                false,
                msg.sender,
                address(0)
            );
        } else if (stringEquality(_operation, "join")) {
            betids[_bet_id].asset_joiner_qty = QuantityB;
            betids[_bet_id].joiner_address = msg.sender;
            betids[_bet_id].asset_id_joiner = secondry_id;
            betids[_bet_id].end_time = block.timestamp + _end_time;
        }
    }

    // Convert interger to string.
    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + (_i % 10)));
            _i /= 10;
        }
        return string(bstr);
    }

    /*
    Function : fullfill
    Params:
        _bet_id : string -> Which bet needs to be fullfilled.
    Returns:
        True: The given bet has either ended / expired.
    */
    function fullfill(string memory _bet_id) public returns (bool) {
        // Get all the bet details w.r.t _bet_id
        BET memory bet = betids[_bet_id];

        /*
        Checks if the bet is not expired.
        Condition:
                 1. Expired time has elapsed
                 2. User has joined the bet.
        */
        if (
            block.timestamp > bet.expiry_time &&
            bet.joiner_address != address(0)
        ) {
            /*
                False -> Someone joined the bet before the bet could expire.

                Checks if the bet has ended.
                */
            if (block.timestamp > bet.end_time) {
                // Get Price of each asset.
                uint256 price_A = uint256(
                    assetData.getCurrencyPriceForTimeStamp(
                        bet.end_time,
                        bet.asset_id_creator
                    )
                );
                uint256 price_B = uint256(
                    assetData.getCurrencyPriceForTimeStamp(
                        bet.end_time,
                        bet.asset_id_joiner
                    )
                );

                // Value of USD for each asset quantity
                uint256 curr_val_A = price_A * bet.asset_creator_qty;
                uint256 curr_val_B = price_B * bet.asset_joiner_qty;

                /*
                    Case: Value of both asset are equal.
                    Action:
                        Update the user balance of both the bet participants, with the quantity of their respective asset.
                    */
                if (curr_val_A == curr_val_B) {
                    //   Fee logic to be implemented here.
                    updateUserBalance(
                        bet.asset_id_creator,
                        bet.asset_creator_qty,
                        "fullfill",
                        bet.creator_address
                    );
                    updateUserBalance(
                        bet.asset_id_joiner,
                        bet.asset_joiner_qty,
                        "fullfill",
                        bet.joiner_address
                    );

                    emit DRAW(
                        _bet_id,
                        curr_val_A,
                        curr_val_B,
                        price_A,
                        price_B
                    );

                    return true;
                }
                /*
                    Case: Asset A value is greater than that of B.
                    Action:
                        1. Determine the Quantity of Asset B that should be transferred as part of the bet winnings.
                        2. Determine the transfer_fees which the admin will take inform of the quantity of asset B.
                        3. Transfer the winnings to the winner.
                    */
                else if (curr_val_A > curr_val_B) {
                    //   Quantity of Asset B that will transferred as part of winnings.
                    uint256 exe_qty;

                    /*
                          Case: If the value of asset B is less than that of the difference between the values of the asset.
                          Action:
                            1. Transfer all the quantity of asset B to the winner.
                          */
                    if (curr_val_A - curr_val_B > curr_val_B) {
                        exe_qty = (curr_val_A - curr_val_B) / price_B;
                    } else {
                        exe_qty = curr_val_B / price_B;
                    }

                    //   Determines the transfer_fee that would be collected by the admin.
                    uint256 transfer_fee_qty = (exe_qty * transfer_fee) /
                        PRECISION;
                    updateUserBalance(
                        bet.asset_id_joiner,
                        transfer_fee_qty,
                        "deposit",
                        fee_address
                    );
                    //   Transfer transfer_fee

                    // Update the Winner balance.
                    updateUserBalance(
                        bet.asset_id_creator,
                        bet.asset_creator_qty,
                        "fullfill",
                        bet.creator_address
                    );
                    updateUserBalance(
                        bet.asset_id_joiner,
                        exe_qty - transfer_fee_qty,
                        "deposit",
                        bet.creator_address
                    );

                    //   Update the Loser balance.
                    updateUserBalance(
                        bet.asset_id_joiner,
                        bet.asset_joiner_qty,
                        "fullfill",
                        bet.joiner_address
                    );

                    //   Reduce the Loser balance by the losing quantity.
                    updateUserBalance(
                        bet.asset_id_joiner,
                        exe_qty,
                        "withdraw",
                        bet.joiner_address
                    );

                    emit PRIMARY_WON(
                        _bet_id,
                        curr_val_A,
                        curr_val_B,
                        price_A,
                        price_B
                    );

                    return true;
                } else if (curr_val_A < curr_val_B) {
                    //   Quantity of Asset A that will transferred as part of winnings.
                    uint256 exe_qty;

                    /*
                          Case: If the value of asset A is less than that of the difference between the values of the asset.
                          Action:
                            1. Transfer all the quantity of asset A to the winner.
                          */
                    if (curr_val_B - curr_val_A > curr_val_A) {
                        exe_qty = curr_val_A / price_A;
                    } else {
                        exe_qty = (curr_val_B - curr_val_A) / price_A;
                    }

                    //   Determines the transfer_fee that would be collected by the admin.
                    uint256 transfer_fee_qty = (exe_qty * transfer_fee) /
                        PRECISION;
                    updateUserBalance(
                        bet.asset_id_creator,
                        transfer_fee_qty,
                        "deposit",
                        fee_address
                    );
                    //   Transfer transfer_fee

                    // Update the Loser balance.
                    updateUserBalance(
                        bet.asset_id_creator,
                        bet.asset_creator_qty,
                        "fullfill",
                        bet.creator_address
                    );

                    //   Reduce the Loser balance by the losing quantity of A.
                    updateUserBalance(
                        bet.asset_id_creator,
                        exe_qty,
                        "withdraw",
                        bet.creator_address
                    );

                    //   Update the Winner balance.
                    updateUserBalance(
                        bet.asset_id_creator,
                        exe_qty - transfer_fee_qty,
                        "deposit",
                        bet.joiner_address
                    );
                    updateUserBalance(
                        bet.asset_id_joiner,
                        bet.asset_joiner_qty,
                        "fullfill",
                        bet.joiner_address
                    );

                    emit SECONDARY_WON(
                        _bet_id,
                        curr_val_A,
                        curr_val_B,
                        price_A,
                        price_B
                    );

                    return true;
                }
            }
        } else if (
            block.timestamp > bet.expiry_time &&
            bet.joiner_address == address(0)
        ) {
            // Update balance of bet creator.
            updateUserBalance(
                bet.asset_id_creator,
                bet.asset_creator_qty,
                "fullfill",
                bet.creator_address
            );

            emit BetExpired(_bet_id);

            return true;
        }
        return false;
    }

    /*
    Function: joinBet
    Params:
        _bet_id : string -> Which bet the user wants to join.
        Qty: integer -> Quantity of the asset.
    */
    function joinBet(string memory _bet_id, uint256 Qty) public returns (bool) {
        // Get all the details of bet for the given bet id.
        BET memory bet = betids[_bet_id];

        require(
            msg.sender != bet.creator_address,
            "Cannot join the bet that's created by you."
        );
        require(block.timestamp < bet.expiry_time, "Bet Expired");
        require(
            bet.joiner_address == address(0),
            "Bet in progress, cannot join"
        );

        normalizeEquality(bet.bet_size, getValue(bet.asset_id_joiner, Qty));

        // Get Price of each asset.
        uint256 price_A = uint256(
            assetData.getlatestAnswerCurrency(bet.asset_id_creator)
        );
        uint256 price_B = uint256(
            assetData.getlatestAnswerCurrency(bet.asset_id_joiner)
        );

        // Current value of bet in USD.
        uint256 bet_value = price_A * bet.asset_creator_qty;

        // Current wallet balance of the user for the asset.
        userBalance memory bal = balances[msg.sender][bet.asset_id_joiner];
        uint256 assest_qty = bal.totalBalance - bal.lockedBalance;

        // Setting the value of bet end time.
        uint256 end_time = block.timestamp + bet.end_time;

        // Day at which the bet will end.
        uint256 end_day = (end_time / DAY) * DAY;

        // Deposit more asset incase the wallet balance is not sufficient.
        if (Qty > assest_qty) {
            uint256 transfer_qty = Qty - assest_qty;

            IERC20 assetOBJ = IERC20(assetData.getAsset(bet.asset_id_joiner));
            assetOBJ.safeTransferFrom(msg.sender, address(this), transfer_qty);

            // Update the user total balance with the deposited quantity.
            updateUserBalance(
                bet.asset_id_joiner,
                transfer_qty,
                "deposit",
                msg.sender
            );
        }

        /*
        Case: Value of both asset are equal.
        */
        if (bet_value == bet.bet_size) {
            // Update the bet details.
            BET_INFO memory v2 = BET_INFO(
                _bet_id,
                bet.bet_size,
                bet.asset_id_creator,
                bet.asset_id_creator,
                bet.asset_creator_qty,
                Qty,
                bet.expiry_time,
                bet.end_time,
                "join"
            );
            updateBetMapping(v2);

            // Update the user locked balance of both the participants.
            updateUserBalance(
                bet.asset_id_creator,
                bet.asset_creator_qty,
                "join",
                bet.creator_address
            );
            updateUserBalance(bet.asset_id_joiner, Qty, "join", msg.sender);
            emit JoinBET(
                msg.sender,
                _bet_id,
                "join",
                end_time,
                bet.bet_size,
                Qty
            );
        }
        /*
        Case: Current value of bet is greater than the bet size.
        */
        else if (bet_value > bet.bet_size) {
            /*
            Update the bet details.
            Locked quantity of Asset A will be bet size / price of A.
            */
            BET_INFO memory v3 = BET_INFO(
                _bet_id,
                bet.bet_size,
                bet.asset_id_creator,
                bet.asset_id_joiner,
                bet.bet_size / price_A,
                Qty,
                bet.expiry_time,
                bet.end_time,
                "join"
            );
            updateBetMapping(v3);

            // Update the user locked balance of both the participants.
            updateUserBalance(
                bet.asset_id_creator,
                bet.bet_size / price_A,
                "join",
                bet.creator_address
            );
            updateUserBalance(bet.asset_id_joiner, Qty, "join", msg.sender);
            emit JoinBET(
                msg.sender,
                _bet_id,
                "join",
                end_time,
                bet.bet_size,
                bet.bet_size / price_A
            );
        }
        /*
        Case: Current value of bet is less than the bet size.
        */
        else if (bet_value < bet.bet_size) {
            /*
            Update the bet details.
            Locked quantity of Asset B will be bet value / price of B.
            */
            BET_INFO memory v4 = BET_INFO(
                _bet_id,
                bet_value,
                bet.asset_id_creator,
                bet.asset_id_joiner,
                bet.asset_creator_qty,
                bet_value / price_B,
                bet.expiry_time,
                bet.end_time,
                "join"
            );
            updateBetMapping(v4);

            // Update the user locked balance of both the participants.
            updateUserBalance(
                bet.asset_id_creator,
                bet.asset_creator_qty,
                "join",
                bet.creator_address
            );
            updateUserBalance(
                bet.asset_id_joiner,
                bet_value / price_B,
                "join",
                msg.sender
            );
            emit JoinBET(
                msg.sender,
                _bet_id,
                "join",
                end_time,
                bet_value,
                bet_value / price_B
            );
        }

        user_checkpoint(block.timestamp);
    }

    /*
    Function: user_checkpoint
    Functionality:
                For the all active bets, it
                    1. fullfill the bets that have ended.
                    2. expires the bets that have expired.
    */
    function user_checkpoint(uint256 _timestamp) internal {
        // timestamp at which the current day started.
        uint256 _day = (_timestamp / DAY) * DAY;

        // All the active bets.
        string[] memory bets = joinedBets[_day];

        uint256 iterations = bets.length;
        if (iterations != 0) {
            // Iterate only the top 10 bets.
            if (iterations > 10) {
                iterations = 10;
            }

            for (uint256 i = 0; i < iterations; i += 1) {
                string memory bet = bets[i];
                bool status = fullfill(bet);
                if (status) {
                    BET memory __bet = betids[bet];
                    __bet.completed = true;
                    betids[bet] = __bet;
                    delete bets[i];
                }
            }
        }

        // Update the active bets array.
        joinedBets[_day] = bets;

        // Remove all the zero values from the active bets array.
        Trimmer(_day);
        last_checkpoint_timestamp = block.timestamp;
    }

    /*
    Function: checkpoint
    Functionality:
                Ensure's that all past ending bets are fullfilled.
    */
    function checkpoint() public {
        require(owner == msg.sender, "Not Authorized.");
        uint256 _curr_timestamp = (block.timestamp / DAY) * DAY;
        uint256 _last_called_timestamp = (last_checkpoint_timestamp / DAY) *
            DAY;
        if (_last_called_timestamp < _curr_timestamp) {
            uint256 diff = (_curr_timestamp - _last_called_timestamp) / DAY;
            for (uint256 i = 0; i < diff; i++) {
                uint256 _timestamp = _curr_timestamp - DAY;
                user_checkpoint(_timestamp);
                _curr_timestamp = _timestamp;
            }
        }
    }

    /*
    Function: Trimmer
    Functionality:
                    Removes the zero values from the active bets array.
    */
    function Trimmer(uint256 _day) internal {
        for (uint256 i = 0; i < joinedBets[_day].length; i++) {
            if (!stringEquality(joinedBets[_day][i], "")) {
                trimAssist.push(joinedBets[_day][i]);
            }
        }
        joinedBets[_day] = trimAssist;
        delete trimAssist;
    }

    /*
    Function: withdraw
    Params:
            1. _qty: integer -> quantity for withdrawal.
            2. _assest_id: string -> which asset is to be withdrawn.
    Functionality:
                    Withdraw the given quantity from the user balance.
    */
    function _withdraw(uint256 _qty, string memory _assest_id) public {
        require(_qty > 0, "Cannot withdraw anything");

        // Get user balance.
        userBalance memory bal = balances[msg.sender][_assest_id];

        // Available balance for withdrawal.
        uint256 curr_bal = bal.totalBalance - bal.lockedBalance;
        require(curr_bal >= _qty, "Not enough balance");

        IERC20 assetOBJ = IERC20(assetData.getAsset(_assest_id));
        assetOBJ.safeTransfer(msg.sender, _qty);

        // Update the user total balance.
        updateUserBalance(_assest_id, _qty, "withdraw", msg.sender);

        user_checkpoint(block.timestamp);
    }

    /*
    Function: withdraw_admin_fees
    Functionality:
                    Withdraw the admin fees.
    */
    function withdraw_admin_fees(string memory _asset_id) public {
        require(
            owner == msg.sender,
            "You cannot withdraw the fees. Not Authorized."
        );

        userBalance memory bal = balances[fee_address][_asset_id];

        // Available balance for withdrawal.
        uint256 curr_bal = bal.totalBalance - bal.lockedBalance;

        IERC20 assetOBJ = IERC20(assetData.getAsset(_asset_id));
        assetOBJ.safeTransfer(fee_address, curr_bal);

        // Update the user total balance.
        updateUserBalance(_asset_id, curr_bal, "withdraw", fee_address);
        user_checkpoint(block.timestamp);
    }

    /*
    Function: set_transfer_fee
    Functionality:
                    Set's the transfer_fee
    */
    function set_transfer_fee(uint256 fee) public {
        require(owner == msg.sender, "Not Authorized.");

        transfer_fee = fee;
    }

    /*
    Function: set_penalty_fee
    Functionality:
                    Set's the penalty_fee
    */
    function set_penalty_fee(uint256 fee) public {
        require(owner == msg.sender, "Not Authorized.");

        penalty_fee = fee;
    }

    /*
    Function: get_admin_fees
    */
    function get_admin_fees(string memory _asset_id)
        public
        view
        returns (uint256)
    {
        require(msg.sender == owner, "Not Authorized.");
        userBalance memory bal = balances[fee_address][_asset_id];
        uint256 curr_bal = bal.totalBalance - bal.lockedBalance;
        return curr_bal;
    }

    /*
    Function: last_checkpoint_called
    */
    function last_checkpoint_called() public view returns (uint256) {
        require(msg.sender == owner, "Not Authorized.");
        return last_checkpoint_timestamp;
    }

    /*
    Function: kill_bet
    Params:
            1. _bet_id: string -> Bet which needs to be killed.
    */
    function kill_bet(string memory _bet_id) public {
        BET memory bet = betids[_bet_id];
        /*
        Condition to kill a bet:
            1. Check if the bet is not expired.
            2. The bet should not be joined.
        */
        require(
            bet.creator_address == msg.sender,
            "You didn't not create this bet."
        );
        require(block.timestamp < bet.expiry_time, "Bet has expired.");
        require(
            bet.joiner_address == address(0),
            "Bet is already in progress. Cannot kill a bet in progress."
        );
        /*
        Penalty for killing the bet.
        */
        uint256 qty = bet.asset_creator_qty;
        uint256 penalty_fee_qty = (qty * penalty_fee) / PRECISION;
        updateUserBalance(
            bet.asset_id_creator,
            penalty_fee_qty,
            "deposit",
            fee_address
        );

        updateUserBalance(
            bet.asset_id_creator,
            penalty_fee_qty,
            "withdraw",
            msg.sender
        );
        updateUserBalance(bet.asset_id_creator, qty, "fullfill", msg.sender);

        // Set expiry_time to zero, hence no one can join the bet.
        bet.expiry_time = 0;
        betids[_bet_id] = bet;
    }
}

