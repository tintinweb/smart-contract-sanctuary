/**
 *Submitted for verification at Etherscan.io on 2021-07-12
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.6;

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

        uint size;
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
    function sendValue(address payable recipient, uint amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
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
        uint value
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
        uint value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(data);
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
            functionStaticCall(target, data, "Address: low-level static call failed");
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

interface CErc20 {
    function mint(uint mintAmount) external returns (uint);

    function redeemUnderlying(uint redeemAmount) external returns (uint);

    function borrow(uint borrowAmount) external returns (uint);

    function repayBorrow(uint repayAmount) external returns (uint);

    function redeem(uint) external returns (uint);

    function borrowBalanceCurrent(address account) external returns (uint);

    function balanceOfUnderlying(address account) external returns (uint);

    function getAccountSnapshot(address account)
        external
        view
        returns (
            uint,
            uint,
            uint,
            uint
        );
}

interface Comptroller {
    function markets(address cToken)
        external
        view
        returns (
            bool,
            uint,
            bool
        );

    // Claim all the COMP accrued by holder in specific markets
    function claimComp(address holder, address[] calldata cTokens) external;
}

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint);

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
    function approve(address spender, uint amount) external returns (bool);

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
        uint amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint value);
}

interface IFundManager {
    function token() external view returns (address);

    function borrow(uint amount) external returns (uint);

    function repay(uint amount) external returns (uint);

    function report(uint gain, uint loss) external;

    function getDebt(address strategy) external view returns (uint);
}

library SafeERC20 {
    using SafeMath for uint;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint value
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
        uint value
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
        uint value
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
        uint value
    ) internal {
        uint newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint value
    ) internal {
        uint newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeERC20: decreased allowance below zero"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
        );
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

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint a, uint b) internal pure returns (bool, uint) {
        uint c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint a, uint b) internal pure returns (bool, uint) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint a, uint b) internal pure returns (bool, uint) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint a, uint b) internal pure returns (bool, uint) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint a, uint b) internal pure returns (bool, uint) {
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
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
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
    function sub(uint a, uint b) internal pure returns (uint) {
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
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) return 0;
        uint c = a * b;
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
    function div(uint a, uint b) internal pure returns (uint) {
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
    function mod(uint a, uint b) internal pure returns (uint) {
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
        uint a,
        uint b,
        string memory errorMessage
    ) internal pure returns (uint) {
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
        uint a,
        uint b,
        string memory errorMessage
    ) internal pure returns (uint) {
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
        uint a,
        uint b,
        string memory errorMessage
    ) internal pure returns (uint) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

abstract contract Strategy {
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    event SetNextTimeLock(address nextTimeLock);
    event AcceptTimeLock(address timeLock);
    event SetAdmin(address admin);
    event Authorize(address addr, bool authorized);
    event SetTreasury(address treasury);
    event SetFundManager(address fundManager);

    event Deposit(uint amount, uint borrowed);
    event Repay(uint amount, uint repaid);
    event Withdraw(uint amount, uint withdrawn, uint loss);
    event ClaimRewards(uint profit);
    event Skim(uint total, uint debt, uint profit);
    event Report(uint gain, uint loss, uint free, uint total, uint debt);

    // Privilege - time lock >= admin >= authorized addresses
    address public timeLock;
    address public nextTimeLock;
    address public admin;
    address public treasury; // Profit is sent to this address

    // authorization other than time lock and admin
    mapping(address => bool) public authorized;

    IERC20 public immutable token;
    IFundManager public fundManager;

    // Performance fee sent to treasury
    uint public perfFee = 1000;
    uint private constant PERF_FEE_CAP = 2000; // Upper limit to performance fee
    uint internal constant PERF_FEE_MAX = 10000;

    constructor(
        address _token,
        address _fundManager,
        address _treasury
    ) {
        // Don't allow accidentally sending perf fee to 0 address
        require(_treasury != address(0), "treasury = 0 address");

        timeLock = msg.sender;
        admin = msg.sender;
        treasury = _treasury;

        require(
            IFundManager(_fundManager).token() == _token,
            "fund manager token != token"
        );

        fundManager = IFundManager(_fundManager);
        token = IERC20(_token);

        IERC20(_token).safeApprove(_fundManager, type(uint).max);
    }

    modifier onlyTimeLock() {
        require(msg.sender == timeLock, "!time lock");
        _;
    }

    modifier onlyTimeLockOrAdmin() {
        require(msg.sender == timeLock || msg.sender == admin, "!auth");
        _;
    }

    modifier onlyAuthorized() {
        require(
            msg.sender == timeLock || msg.sender == admin || authorized[msg.sender],
            "!auth"
        );
        _;
    }

    modifier onlyFundManager() {
        require(msg.sender == address(fundManager), "!fund manager");
        _;
    }

    /*
    @notice Set next time lock
    @param _nextTimeLock Address of next time lock
    @dev nextTimeLock can become timeLock by calling acceptTimeLock()
    */
    function setNextTimeLock(address _nextTimeLock) external onlyTimeLock {
        // Allow next time lock to be zero address (cancel next time lock)
        nextTimeLock = _nextTimeLock;
        emit SetNextTimeLock(_nextTimeLock);
    }

    /*
    @notice Set timeLock to msg.sender
    @dev msg.sender must be nextTimeLock
    */
    function acceptTimeLock() external {
        require(msg.sender == nextTimeLock, "!next time lock");
        timeLock = msg.sender;
        emit AcceptTimeLock(msg.sender);
    }

    /*
    @notice Set admin
    @param _admin Address of admin
    */
    function setAdmin(address _admin) external onlyTimeLockOrAdmin {
        admin = _admin;
        emit SetAdmin(_admin);
    }

    /*
    @notice Set authorization
    @param _addr Address to authorize
    @param _authorized Boolean
    */
    function authorize(address _addr, bool _authorized) external onlyTimeLockOrAdmin {
        authorized[_addr] = _authorized;
        emit Authorize(_addr, _authorized);
    }

    /*
    @notice Set treasury
    @param _treasury Address of treasury
    */
    function setTreasury(address _treasury) external onlyTimeLockOrAdmin {
        // Don't allow accidentally sending perf fee to 0 address
        require(_treasury != address(0), "treasury = 0 address");
        treasury = _treasury;
        emit SetTreasury(_treasury);
    }

    /*
    @notice Set performance fee
    @param _fee Performance fee
    */
    function setPerfFee(uint _fee) external onlyTimeLockOrAdmin {
        require(_fee <= PERF_FEE_CAP, "fee > cap");
        perfFee = _fee;
    }

    function setFundManager(address _fundManager) external onlyTimeLock {
        if (address(fundManager) != address(0)) {
            token.safeApprove(address(fundManager), 0);
        }

        require(
            IFundManager(_fundManager).token() == address(token),
            "new fund manager token != token"
        );

        fundManager = IFundManager(_fundManager);
        token.safeApprove(_fundManager, type(uint).max);

        emit SetFundManager(_fundManager);
    }

    /*
    @notice Transfer funds from `_from` address. Used for migration.
    @param _from Address to transfer token from
    @param _amount Amount of token to transfer
    */
    function transferTokenFrom(address _from, uint _amount) external onlyAuthorized {
        token.safeTransferFrom(_from, address(this), _amount);
    }

    /*
    @notice Returns approximate amount of token locked in this contract
    @dev Output may vary depending on price pulled from external DeFi contracts
    */
    function totalAssets() external view virtual returns (uint);

    /*
    @notice Deposit into strategy
    @param _amount Amount of token to deposit from fund manager
    @param _min Minimum amount borrowed
    */
    function deposit(uint _amount, uint _min) external virtual;

    /*
    @notice Withdraw token from this contract
    @dev Only callable by fund manager
    @dev Returns current loss = debt to fund manager - total assets
    */
    function withdraw(uint _amount) external virtual returns (uint);

    /*
    @notice Repay fund manager
    @param _amount Amount of token to repay to fund manager
    @param _min Minimum amount repaid
    @dev Call report after this to report any loss
    */
    function repay(uint _amount, uint _min) external virtual;

    /*
    @notice Claim any reward tokens, sell for token
    @param _minProfit Minumum amount of token to gain from selling rewards
    */
    function claimRewards(uint _minProfit) external virtual;

    /*
    @notice Free up any profit over debt
    */
    function skim() external virtual;

    /*
    @notice Report gain or loss back to fund manager
    @param _minTotal Minimum value of total assets.
               Used to protect against price manipulation.
    @param _maxTotal Maximum value of total assets Used
               Used to protect against price manipulation.  
    */
    function report(uint _minTotal, uint _maxTotal) external virtual;

    /*
    @notice Claim rewards, skim and report
    @param _minProfit Minumum amount of token to gain from selling rewards
    @param _minTotal Minimum value of total assets.
               Used to protect against price manipulation.
    @param _maxTotal Maximum value of total assets Used
               Used to protect against price manipulation.  
    */
    function harvest(
        uint _minProfit,
        uint _minTotal,
        uint _maxTotal
    ) external virtual;

    /*
    @notice Migrate to new version of this strategy
    @param _strategy Address of new strategy
    @dev Only callable by fund manager
    */
    function migrate(address _strategy) external virtual;

    /*
    @notice Transfer token accidentally sent here back to admin
    @param _token Address of token to transfer
    */
    function sweep(address _token) external virtual;
}

contract StrategyCompLev is Strategy {
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    // Uniswap and Sushiswap //
    // UNISWAP = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    // SUSHISWAP = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public dex;

    // Compound //
    Comptroller private constant comptroller =
        Comptroller(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B);
    IERC20 private constant comp = IERC20(0xc00e94Cb662C3520282E6f5717214004A7f26888);
    CErc20 private immutable cToken;
    uint public buffer = 0.04 * 1e18;

    constructor(
        address _token,
        address _fundManager,
        address _treasury,
        address _cToken
    ) Strategy(_token, _fundManager, _treasury) {
        require(_cToken != address(0), "cToken = zero address");
        cToken = CErc20(_cToken);
        IERC20(_token).safeApprove(_cToken, type(uint).max);

        _setDex(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); // Uniswap
    }

    function _setDex(address _dex) private {
        if (dex != address(0)) {
            comp.safeApprove(_dex, 0);
        }

        dex = _dex;

        comp.safeApprove(_dex, type(uint).max);
    }

    function setDex(address _dex) external onlyTimeLockOrAdmin {
        require(_dex != address(0), "dex = 0 address");
        _setDex(_dex);
    }

    function _totalAssets() private view returns (uint) {
        // WARNING: This returns balance last time someone transacted with cToken
        (uint error, uint cTokenBal, uint borrowed, uint exchangeRate) = cToken
        .getAccountSnapshot(address(this));

        if (error > 0) {
            // something is wrong, return 0
            return 0;
        }
        uint supplied = cTokenBal.mul(exchangeRate) / 1e18;
        if (supplied < borrowed) {
            // something is wrong, return 0
            return 0;
        }
        uint bal = token.balanceOf(address(this));
        // supplied >= borrowed
        return bal.add(supplied - borrowed);
    }

    /*
    @notice Returns amount of tokens locked in this contract
    */
    function totalAssets() external view override returns (uint) {
        return _totalAssets();
    }

    /*
    @dev buffer = 0 means safe collateral ratio = market collateral ratio
         buffer = 1e18 means safe collateral ratio = 0
    */
    function setBuffer(uint _buffer) external onlyAuthorized {
        require(_buffer > 0 && _buffer <= 1e18, "buffer");
        buffer = _buffer;
    }

    function _getMarketCollateralRatio() private view returns (uint) {
        /*
        This can be changed by Compound Governance, with a minimum waiting
        period of five days
        */
        (, uint col, ) = comptroller.markets(address(cToken));
        return col;
    }

    function _getSafeCollateralRatio(uint _marketCol) private view returns (uint) {
        if (_marketCol > buffer) {
            return _marketCol - buffer;
        }
        return 0;
    }

    // Not view function
    function _getSupplied() private returns (uint) {
        return cToken.balanceOfUnderlying(address(this));
    }

    // Not view function
    function _getBorrowed() private returns (uint) {
        return cToken.borrowBalanceCurrent(address(this));
    }

    // Not view function. Call using static call from web3
    function getLivePosition()
        external
        returns (
            uint supplied,
            uint borrowed,
            uint marketCol,
            uint safeCol
        )
    {
        supplied = _getSupplied();
        borrowed = _getBorrowed();
        marketCol = _getMarketCollateralRatio();
        safeCol = _getSafeCollateralRatio(marketCol);
    }

    // @dev This returns balance last time someone transacted with cToken
    function getCachedPosition()
        external
        view
        returns (
            uint supplied,
            uint borrowed,
            uint marketCol,
            uint safeCol
        )
    {
        // ignore first output, which is error code
        (, uint cTokenBal, uint _borrowed, uint exchangeRate) = cToken
        .getAccountSnapshot(address(this));
        supplied = cTokenBal.mul(exchangeRate) / 1e18;
        borrowed = _borrowed;
        marketCol = _getMarketCollateralRatio();
        safeCol = _getSafeCollateralRatio(marketCol);
    }

    // @dev This modifier checks collateral ratio after leverage or deleverage
    modifier checkCollateralRatio() {
        _;
        uint supplied = _getSupplied();
        uint borrowed = _getBorrowed();
        uint marketCol = _getMarketCollateralRatio();
        uint safeCol = _getSafeCollateralRatio(marketCol);
        // borrowed / supplied <= safe col
        // supplied can = 0 so we check borrowed <= supplied * safe col
        // max borrow
        uint max = supplied.mul(safeCol) / 1e18;
        require(borrowed <= max, "borrowed > max");
    }

    // @dev In case infinite approval is reduced so that strategy cannot function
    function approve(uint _amount) external onlyAuthorized {
        token.safeApprove(address(cToken), _amount);
    }

    function _supply(uint _amount) private {
        require(cToken.mint(_amount) == 0, "mint");
    }

    // @dev Execute manual recovery by admin
    // @dev `_amount` must be >= balance of token
    function supplyManual(uint _amount) external onlyAuthorized {
        _supply(_amount);
    }

    function _borrow(uint _amount) private {
        require(cToken.borrow(_amount) == 0, "borrow");
    }

    // @dev Execute manual recovery by admin
    function borrowManual(uint _amount) external onlyAuthorized {
        _borrow(_amount);
    }

    function _repay(uint _amount) private {
        require(cToken.repayBorrow(_amount) == 0, "repay");
    }

    // @dev Execute manual recovery by admin
    // @dev `_amount` must be >= balance of token
    function repayManual(uint _amount) external onlyAuthorized {
        _repay(_amount);
    }

    function _redeem(uint _amount) private {
        require(cToken.redeemUnderlying(_amount) == 0, "redeem");
    }

    // @dev Execute manual recovery by admin
    function redeemManual(uint _amount) external onlyAuthorized {
        _redeem(_amount);
    }

    function _getMaxLeverageRatio(uint _col) private pure returns (uint) {
        /*
        c = collateral ratio
        geometric series converges to
            1 / (1 - c)
        */
        // multiplied by 1e18
        return uint(1e36).div(uint(1e18).sub(_col));
    }

    function _getBorrowAmount(
        uint _supplied,
        uint _borrowed,
        uint _col
    ) private pure returns (uint) {
        /*
        c = collateral ratio
        s = supplied
        b = borrowed
        x = amount to borrow
        (b + x) / s <= c
        becomes
        x <= sc - b
        */
        // max borrow
        uint max = _supplied.mul(_col) / 1e18;
        if (_borrowed >= max) {
            return 0;
        }
        return max - _borrowed;
    }

    /*
    Find total supply S_n after n iterations starting with
    S_0 supplied and B_0 borrowed
    c = collateral ratio
    S_i = supplied after i iterations
    B_i = borrowed after i iterations
    S_0 = current supplied
    B_0 = current borrowed
    borrowed and supplied after n iterations
        B_n = cS_(n-1)
        S_n = S_(n-1) + (cS_(n-1) - B_(n-1))
    you can prove using algebra and induction that
        B_n / S_n <= c
        S_n - S_(n-1) = c^(n-1) * (cS_0 - B_0)
        S_n = S_0 + sum (c^i * (cS_0 - B_0)), 0 <= i <= n - 1
            = S_0 + (1 - c^n) / (1 - c)
        S_n <= S_0 + (cS_0 - B_0) / (1 - c)
    */
    function _leverage(uint _targetSupply) private checkCollateralRatio {
        // buffer = 1e18 means safe collateral ratio = 0
        if (buffer >= 1e18) {
            return;
        }
        uint supplied = _getSupplied();
        uint borrowed = _getBorrowed();
        uint unleveraged = supplied.sub(borrowed); // supply with 0 leverage
        require(_targetSupply >= unleveraged, "leverage");
        uint marketCol = _getMarketCollateralRatio();
        uint safeCol = _getSafeCollateralRatio(marketCol);
        uint lev = _getMaxLeverageRatio(safeCol);
        // 99% to be safe, and save gas
        uint max = (unleveraged.mul(lev) / 1e18).mul(9900) / 10000;
        if (_targetSupply >= max) {
            _targetSupply = max;
        }
        uint i;
        while (supplied < _targetSupply) {
            // target is usually reached in 9 iterations
            require(i < 25, "max iteration");
            // use market collateral to calculate borrow amount
            // this is done so that supplied can reach _targetSupply
            // 99.99% is borrowed to be safe
            uint borrowAmount = _getBorrowAmount(supplied, borrowed, marketCol).mul(
                9999
            ) / 10000;
            require(borrowAmount > 0, "borrow = 0");
            if (supplied.add(borrowAmount) > _targetSupply) {
                // borrow > 0 since supplied < _targetSupply
                borrowAmount = _targetSupply.sub(supplied);
            }
            _borrow(borrowAmount);
            // end loop with _supply, this ensures no borrowed amount is unutilized
            _supply(borrowAmount);
            // supplied > _getSupplied(), by about 3 * 1e12 %, but we use local variable to save gas
            supplied = supplied.add(borrowAmount);
            // _getBorrowed == borrowed
            borrowed = borrowed.add(borrowAmount);
            i++;
        }
    }

    function leverage(uint _targetSupply) external onlyAuthorized {
        _leverage(_targetSupply);
    }

    function _deposit() private {
        uint bal = token.balanceOf(address(this));
        if (bal > 0) {
            _supply(bal);
            // leverage to max
            _leverage(type(uint).max);
        }
    }

    /*
    @notice Deposit token into this strategy
    @param _amount Amount of token to deposit
    @param _min Minimum amount to borrow from fund manager
    */
    function deposit(uint _amount, uint _min) external override onlyAuthorized {
        require(_amount > 0, "deposit = 0");

        uint borrowed = fundManager.borrow(_amount);
        require(borrowed >= _min, "borrowed < min");

        _deposit();
        emit Deposit(_amount, borrowed);
    }

    function _getRedeemAmount(
        uint _supplied,
        uint _borrowed,
        uint _col
    ) private pure returns (uint) {
        /*
        c = collateral ratio
        s = supplied
        b = borrowed
        r = redeem
        b / (s - r) <= c
        becomes
        r <= s - b / c
        */
        // min supply
        // b / c = min supply needed to borrow b
        uint min = _borrowed.mul(1e18).div(_col);
        if (_supplied <= min) {
            return 0;
        }
        return _supplied - min;
    }

    /*
    Find S_0, amount of supply with 0 leverage, after n iterations starting with
    S_n supplied and B_n borrowed
    c = collateral ratio
    S_n = current supplied
    B_n = current borrowed
    S_(n-i) = supplied after i iterations
    B_(n-i) = borrowed after i iterations
    R_(n-i) = Redeemable after i iterations
        = S_(n-i) - B_(n-i) / c
        where B_(n-i) / c = min supply needed to borrow B_(n-i)
    For 0 <= k <= n - 1
        S_k = S_(k+1) - R_(k+1)
        B_k = B_(k+1) - R_(k+1)
    and
        S_k - B_k = S_(k+1) - B_(k+1)
    so
        S_0 - B_0 = S_1 - S_2 = ... = S_n - B_n
    S_0 has 0 leverage so B_0 = 0 and we get
        S_0 = S_0 - B_0 = S_n - B_n
    ------------------------------------------
    Find S_(n-k), amount of supply, after k iterations starting with
    S_n supplied and B_n borrowed
    with algebra and induction you can derive that
    R_(n-k) = R_n / c^k
    S_(n-k) = S_n - sum R_(n-i), 0 <= i <= k - 1
            = S_n - R_n * ((1 - 1/c^k) / (1 - 1/c))
    Equation above is valid for S_(n - k) k < n
    */
    function _deleverage(uint _targetSupply) private checkCollateralRatio {
        uint supplied = _getSupplied();
        uint borrowed = _getBorrowed();
        uint unleveraged = supplied.sub(borrowed);
        require(_targetSupply <= supplied, "deleverage");
        uint marketCol = _getMarketCollateralRatio();
        // min supply
        if (_targetSupply <= unleveraged) {
            _targetSupply = unleveraged;
        }
        uint i;
        while (supplied > _targetSupply) {
            // target is usually reached in 8 iterations
            require(i < 25, "max iteration");
            // 99.99% to be safe
            uint redeemAmount = (_getRedeemAmount(supplied, borrowed, marketCol)).mul(
                9999
            ) / 10000;
            require(redeemAmount > 0, "redeem = 0");
            if (supplied.sub(redeemAmount) < _targetSupply) {
                // redeem > 0 since supplied > _targetSupply
                redeemAmount = supplied.sub(_targetSupply);
            }
            _redeem(redeemAmount);
            _repay(redeemAmount);
            // supplied < _geSupplied(), by about 7 * 1e12 %
            supplied = supplied.sub(redeemAmount);
            // borrowed == _getBorrowed()
            borrowed = borrowed.sub(redeemAmount);
            i++;
        }
    }

    function deleverage(uint _targetSupply) external onlyAuthorized {
        _deleverage(_targetSupply);
    }

    // @dev Returns amount available for transfer
    function _withdraw(uint _amount) private returns (uint) {
        uint bal = token.balanceOf(address(this));
        if (_amount <= bal) {
            return _amount;
        }

        uint redeemAmount = _amount - bal;
        /*
        c = collateral ratio
        s = supplied
        b = borrowed
        r = amount to redeem
        x = amount to repay
        where
            r <= s - b (can't redeem more than unleveraged supply)
        and
            x <= b (can't repay more than borrowed)
        and
            (b - x) / (s - x - r) <= c (stay below c after redeem and repay)
        so pick x such that
            (b - cs + cr) / (1 - c) <= x <= b
        when b <= cs left side of equation above <= cr / (1 - c) so pick x such that
            cr / (1 - c) <= x <= b
        */
        uint supplied = _getSupplied();
        uint borrowed = _getBorrowed();
        uint marketCol = _getMarketCollateralRatio();
        uint safeCol = _getSafeCollateralRatio(marketCol);
        uint unleveraged = supplied.sub(borrowed);
        // r <= s - b
        if (redeemAmount > unleveraged) {
            redeemAmount = unleveraged;
        }
        // cr / (1 - c) <= x <= b
        uint repayAmount = redeemAmount.mul(safeCol).div(uint(1e18).sub(safeCol));
        if (repayAmount > borrowed) {
            repayAmount = borrowed;
        }

        _deleverage(supplied.sub(repayAmount));
        _redeem(redeemAmount);

        uint balAfter = token.balanceOf(address(this));
        if (balAfter < _amount) {
            return balAfter;
        }
        return _amount;
    }

    /*
    @notice Withdraw undelying token to erc20Vault
    @param _amount Amount of token to withdraw
    @dev Returns current loss = debt to fund manager - total assets
    @dev Caller should implement guard against slippage
    */
    function withdraw(uint _amount) external override onlyFundManager returns (uint) {
        require(_amount > 0, "withdraw = 0");

        // availabe <= _amount
        uint available = _withdraw(_amount);

        uint loss = 0;
        uint debt = fundManager.getDebt(address(this));
        uint total = _totalAssets();
        if (debt > total) {
            loss = debt - total;
        }

        if (available > 0) {
            token.safeTransfer(msg.sender, available);
        }

        emit Withdraw(_amount, available, loss);

        return loss;
    }

    function repay(uint _amount, uint _min) external override {
        require(_amount > 0, "repay = 0");
        // availabe <= _amount
        uint available = _withdraw(_amount);
        uint repaid = fundManager.repay(available);
        require(repaid >= _min, "repaid < min");

        emit Repay(_amount, repaid);
    }

    /*
    @dev Uniswap fails with zero address so no check is necessary here
    */
    function _swap(
        address _from,
        address _to,
        uint _amount
    ) private {
        // create dynamic array with 3 elements
        address[] memory path = new address[](3);
        path[0] = _from;
        path[1] = WETH;
        path[2] = _to;

        UniswapV2Router(dex).swapExactTokensForTokens(
            _amount,
            1,
            path,
            address(this),
            block.timestamp
        );
    }

    function _claimRewards(uint _minProfit) private {
        // calculate profit = balance of token after - balance of token before
        uint diff = token.balanceOf(address(this));

        // claim COMP
        address[] memory cTokens = new address[](1);
        cTokens[0] = address(cToken);
        comptroller.claimComp(address(this), cTokens);

        uint compBal = comp.balanceOf(address(this));
        if (compBal > 0) {
            _swap(address(comp), address(token), compBal);
        }

        diff = token.balanceOf(address(this)) - diff;
        require(diff >= _minProfit, "profit < min");

        // transfer performance fee to treasury
        if (diff > 0) {
            uint fee = diff.mul(perfFee) / PERF_FEE_MAX;
            if (fee > 0) {
                token.safeTransfer(treasury, fee);
                diff = diff.sub(fee);
            }
        }

        emit ClaimRewards(diff);
    }

    function claimRewards(uint _minProfit) external override onlyAuthorized {
        _claimRewards(_minProfit);
    }

    function _skim() private {
        uint total = _totalAssets();
        uint debt = fundManager.getDebt(address(this));
        require(total > debt, "total <= debt");

        uint profit = total - debt;
        // reassign to actual amount withdrawn
        profit = _withdraw(profit);

        emit Skim(total, debt, profit);
    }

    function skim() external override onlyAuthorized {
        _skim();
    }

    function _report(uint _minTotal, uint _maxTotal) private {
        uint total = _totalAssets();
        require(total >= _minTotal, "total < min");
        require(total <= _maxTotal, "total > max");

        uint gain = 0;
        uint loss = 0;
        uint free = 0;
        uint debt = fundManager.getDebt(address(this));

        if (total > debt) {
            gain = total - debt;

            free = token.balanceOf(address(this));
            if (gain > free) {
                gain = free;
            }
        } else {
            loss = debt - total;
        }

        if (gain > 0 || loss > 0) {
            fundManager.report(gain, loss);
        }

        emit Report(gain, loss, free, total, debt);
    }

    function report(uint _minTotal, uint _maxTotal) external override onlyAuthorized {
        _report(_minTotal, _maxTotal);
    }

    function harvest(
        uint _minProfit,
        uint _minTotal,
        uint _maxTotal
    ) external override onlyAuthorized {
        _claimRewards(_minProfit);
        _skim();
        _report(_minTotal, _maxTotal);
    }

    function migrate(address _strategy) external override onlyFundManager {
        Strategy strat = Strategy(_strategy);
        require(address(strat.token()) == address(token), "strategy token != token");
        require(
            address(strat.fundManager()) == address(fundManager),
            "strategy fund manager != fund manager"
        );
        uint bal = _withdraw(type(uint).max);
        token.safeApprove(_strategy, bal);
        strat.transferTokenFrom(address(this), bal);
    }

    /*
    @notice Transfer token accidentally sent here to admin
    @param _token Address of token to transfer
    */
    function sweep(address _token) external override onlyAuthorized {
        require(_token != address(token), "protected token");
        require(_token != address(cToken), "protected token");
        require(_token != address(comp), "protected token");
        IERC20(_token).safeTransfer(admin, IERC20(_token).balanceOf(address(this)));
    }
}

interface UniswapV2Router {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

contract StrategyCompLevDai is StrategyCompLev {
    constructor(address _fundManager, address _treasury)
        StrategyCompLev(
            0x6B175474E89094C44Da98b954EedeAC495271d0F,
            _fundManager,
            _treasury,
            0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643
        )
    {}
}