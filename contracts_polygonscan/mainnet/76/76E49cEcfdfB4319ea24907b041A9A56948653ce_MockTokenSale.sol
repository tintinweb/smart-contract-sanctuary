/**
 *Submitted for verification at polygonscan.com on 2022-01-17
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

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

library LowGasSafeMath {
    /// @notice Returns x + y, reverts if sum overflows uint256
    /// @param x The augend
    /// @param y The addend
    /// @return z The sum of x and y
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }

    /// @notice Returns x - y, reverts if underflows
    /// @param x The minuend
    /// @param y The subtrahend
    /// @return z The difference of x and y
    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }

    /// @notice Returns x * y, reverts if overflows
    /// @param x The multiplicand
    /// @param y The multiplier
    /// @return z The product of x and y
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(x == 0 || (z = x * y) / x == y);
    }

    /// @notice Returns x + y, reverts if overflows or underflows
    /// @param x The augend
    /// @param y The addend
    /// @return z The sum of x and y
    function add(int256 x, int256 y) internal pure returns (int256 z) {
        require((z = x + y) >= x == (y >= 0));
    }

    /// @notice Returns x - y, reverts if overflows or underflows
    /// @param x The minuend
    /// @param y The subtrahend
    /// @return z The difference of x and y
    function sub(int256 x, int256 y) internal pure returns (int256 z) {
        require((z = x - y) <= x == (y >= 0));
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function sqrrt(uint256 a) internal pure returns (uint c) {
        if (a > 3) {
            c = a;
            uint b = add( div( a, 2), 1 );
            while (b < c) {
                c = b;
                b = div( add( div( a, b ), b), 2 );
            }
        } else if (a != 0) {
            c = 1;
        }
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
        // This method relies in extcodesize, which returns 0 for contracts in
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
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

    function addressToString(address _address) internal pure returns(string memory) {
        bytes32 _bytes = bytes32(uint256(_address));
        bytes memory HEX = "0123456789abcdef";
        bytes memory _addr = new bytes(42);

        _addr[0] = '0';
        _addr[1] = 'x';

        for(uint256 i = 0; i < 20; i++) {
            _addr[2+i*2] = HEX[uint8(_bytes[i + 12] >> 4)];
            _addr[3+i*2] = HEX[uint8(_bytes[i + 12] & 0x0f)];
        }

        return string(_addr);

    }
}

library SafeERC20 {
    using LowGasSafeMath for uint256;
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
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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

/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
   */
    bool private initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
   */
    bool private initializing;

    /**
     * @dev Modifier to use in the initializer function of a contract.
   */
    modifier initializer() {
        require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

        bool isTopLevelCall = !initializing;
        if (isTopLevelCall) {
            initializing = true;
            initialized = true;
        }

        _;

        if (isTopLevelCall) {
            initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }
}

interface IOwnable {
    function owner() external view returns (address);

    function renounceOwnership() external;

    function transferOwnership( address newOwner_ ) external;
}

contract Ownable is IOwnable, Initializable {

    address internal _owner;
    address internal _pendingOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OwnershipTransferring(address indexed owner, address indexed pendingOwner);

    function __Ownable_init_unchain() internal initializer {
        require(_owner == address(0));
        _owner = msg.sender;
        emit OwnershipTransferred( address(0), _owner );
    }

    function owner() public view override returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require( _owner == msg.sender, "Ownable: caller is not the owner" );
        _;
    }

    function renounceOwnership() public virtual override onlyOwner() {
        emit OwnershipTransferred( _owner, address(0) );
        _owner = address(0);
    }

    function transferOwnership( address newOwner_ ) public virtual override onlyOwner() {
        require( newOwner_ != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferring( _owner, newOwner_ );
        _pendingOwner = newOwner_;
    }

    function acceptOwnership() external {
        require(_pendingOwner == msg.sender, "Permission denied");
        emit OwnershipTransferred( _owner, msg.sender );
        _owner = msg.sender;
    }
}

interface IERC20Mintable {
    function mint( uint256 amount_ ) external;

    function mint( address account_, uint256 ammount_ ) external;
}

contract MockTokenSale is Ownable {

    using LowGasSafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public k;
    uint256 public kDenominator;
    uint256 public b;
    uint256 public bDenominator;

    uint256 public t0;

    // address of sell token
    address public token0;
    // address address of buy token
    address public token1;
    // total amount of token0
    uint256 public amountTotal0;
    // total amount of token1
    uint256 public amountTotal1;
    // the timestamp in seconds the pool will open
    uint256 public openAt;
    // the timestamp in seconds the pool will be closed
    uint256 public closeAt;
    // whether or not whitelist is enable
    bool public enableWhiteList;

    // maximum swap amount1
    uint256 public maxAmount1;
    // maximum swap amount1 per wallet
    uint256 public maxAmount1PerWallet;
    uint256 public minAmount1PerWallet;

    mapping(address => bool) public whitelist;
    mapping(address => bool) public inviteable;
    mapping(address => uint256) public amountSwapped0;
    mapping(address => uint256) public amountSwapped1;

    uint256 public ratioInviterReward;
    uint256 public ratioInviteeReward;
    uint256 public amountInviterRewardTotal0;
    uint256 public amountInviteeRewardTotal0;
    mapping(address => uint256) public amountInviterReward0;
    mapping(address => uint256) public amountInviteeReward0;
    mapping(address => uint256) public numberOfInvitee;
    mapping(address => address) public inviters;

    uint256 public constant ratio = 0.2 ether;
    // Marketing promotion
    address payable public marketFund;
    // SynAssets Liquidity Pool(LP) fund
    address payable public liquidityFund;

    bool private _inSwapping;

    /* ====== Event ====== */

    event Swapped(address indexed sender, address indexed inviter, uint256 amount0, uint256 amount1);

    /* ====== Modifier ====== */
    modifier nonReentrant {
        require(!_inSwapping);

        _inSwapping = true;

        _;

        _inSwapping = false;
    }

    function __TokenSale_initialize (
        bool enableWhiteList_,
        address token0_,
        address token1_,
        address payable marketFund_,
        address payable liquidityFund_,
    // avoids stack too deep errors
    // [ k_, kDenominator_, b_, bDenominator_, openAt_, closeAt_, maxAmount1_, maxAmount1PerWallet_, minAmount1PerWallet_, ratioInviterReward_, ratioInviteeReward_ ]
        uint256 [] memory uint256Parameters_
    ) external initializer {
        __Ownable_init_unchain();
        __TokenSale_init_unchain(enableWhiteList_, token0_, token1_, marketFund_, liquidityFund_, uint256Parameters_);
    }

    function __TokenSale_init_unchain (
        bool enableWhiteList_,
        address token0_,
        address token1_,
        address payable marketFund_,
        address payable liquidityFund_,
    // [ k_, kDenominator_, b_, bDenominator_, openAt_, closeAt_, maxAmount1_, maxAmount1PerWallet_, minAmount1PerWallet_, ratioInviterReward_, ratioInviteeReward_ ]
        uint256 [] memory uint256Parameters_
    ) internal initializer {
        require(uint256Parameters_.length == 11, 'Invalid Parameters');

        k = uint256Parameters_[0];
        require(uint256Parameters_[1] != 0);
        kDenominator = uint256Parameters_[1];

        b = uint256Parameters_[2];
        require(uint256Parameters_[3] != 0);
        bDenominator = uint256Parameters_[3];

        require(token0_ != address(0), 'IA');
        token0 = token0_;

//      require(token1_ != address(0), 'IA');
        token1 = token1_;

        openAt = uint256Parameters_[4];
        closeAt = uint256Parameters_[5];
        maxAmount1 = uint256Parameters_[6];
        maxAmount1PerWallet = uint256Parameters_[7];
        minAmount1PerWallet = uint256Parameters_[8];
        marketFund = marketFund_;
        liquidityFund = liquidityFund_;
        ratioInviterReward = uint256Parameters_[9];
        ratioInviteeReward = uint256Parameters_[10];
        enableWhiteList = enableWhiteList_;
    }

    /* ====== Owner FUNCTIONS ====== */
    function addWhitelist(address[] calldata whitelist_) external {
        for (uint256 index = 0; index < whitelist_.length; index ++)
            whitelist[whitelist_[index]] = true;
    }

    function removeWhitelist(address[] calldata whitelist_) external onlyOwner {
        for (uint256 index = 0; index < whitelist_.length; index ++)
            whitelist[whitelist_[index]] = false;
    }

    function addInviteable(address[] calldata inviteable_) external {
        for (uint256 index = 0; index < inviteable_.length; index ++) {
            inviteable[inviteable_[index]] = true;
            whitelist[inviteable_[index]] = true;
        }
    }

    function removeInviteable(address[] calldata inviteable_) external onlyOwner {
        for (uint256 index = 0; index < inviteable_.length; index ++)
            inviteable[inviteable_[index]] = false;
    }

    // [ k_, kDenominator_, b_, bDenominator_, openAt_, closeAt_, maxAmount1_, maxAmount1PerWallet_, minAmount1PerWallet_, ratioInviterReward_, ratioInviteeReward_ ]
    function setParameters(uint256 [] memory uint256Parameters_) external onlyOwner {
        require(uint256Parameters_.length == 11, 'Invalid Parameters');
        if (uint256Parameters_[0] > 0) k = uint256Parameters_[0];
        if (uint256Parameters_[1] > 0) kDenominator = uint256Parameters_[1];
        if (uint256Parameters_[2] > 0) b = uint256Parameters_[2];
        if (uint256Parameters_[3] > 0) bDenominator = uint256Parameters_[3];
        if (uint256Parameters_[4] > 0) openAt = uint256Parameters_[4];
        if (uint256Parameters_[5] > 0) closeAt = uint256Parameters_[5];
        if (uint256Parameters_[6] > 0) maxAmount1 = uint256Parameters_[6];
        if (uint256Parameters_[7] > 0) maxAmount1PerWallet = uint256Parameters_[7];
        if (uint256Parameters_[8] > 0) minAmount1PerWallet = uint256Parameters_[8];
        if (uint256Parameters_[9] > 0) ratioInviterReward = uint256Parameters_[9];
        if (uint256Parameters_[10] > 0) ratioInviteeReward = uint256Parameters_[10];
    }

    /* ====== PUBLIC FUNCTIONS ====== */

    function swap(uint256 amount1_, address inviter_) external payable nonReentrant {
        address payable sender = msg.sender;

        if (inviters[sender] == address(0)) {
            numberOfInvitee[inviter_] ++;
            inviters[sender] = inviter_;
        }
        inviter_ = inviters[sender];

        require(inviteable[inviter_]/* && sender != inviter_*/, 'invalid inviter');
        require(tx.origin == sender, 'disallow contract caller');
        if (enableWhiteList) require(whitelist[sender], 'sender not on whitelist');

        require(openAt <= block.timestamp, 'not open yet');
        require(closeAt > block.timestamp, 'closed already');
        require(minAmount1PerWallet <= amount1_, 'too few');
        require(
            maxAmount1 >= amountTotal1.add(amount1_) &&
            maxAmount1PerWallet >= amountSwapped1[sender].add(amount1_),
                'swapped amount of token1 is exceeded maximum allowance'
        );

        uint256 amount0_ = calcT1(amount1_);
        require(amount0_ < amount1_.mul(bDenominator).div(b), 'wrong price');

        // do transfer
        if (token1 == address(0)) require(msg.value == amount1_, 'invalid amount of ETH');
        else IERC20(token1).safeTransferFrom(sender, address(this), amount1_);
        IERC20Mintable(token0).mint(sender, amount0_);

        // update storage
        t0 = t0.add(amount0_);
        amountTotal0 = amountTotal0.add(amount0_);
        amountTotal1 = amountTotal1.add(amount1_);
        amountSwapped0[sender] = amountSwapped0[sender].add(amount0_);
        amountSwapped1[sender] = amountSwapped1[sender].add(amount1_);

        // send token1 to beneficiary
        uint256 marketFundAmount_ = amount1_.mul(ratio).div(1 ether);
        if (token1 == address(0)) {
            marketFund.transfer(marketFundAmount_);
            liquidityFund.transfer(amount1_.sub(marketFundAmount_));
        } else {
            IERC20(token1).safeTransfer(marketFund, marketFundAmount_);
            IERC20(token1).safeTransfer(liquidityFund, amount1_.sub(marketFundAmount_));
        }

        if (!inviteable[sender]) {
            uint256 inviteeReward_ = amount0_.mul(ratioInviteeReward).div(1 ether);
            uint256 inviterReward_ = amount0_.mul(ratioInviterReward).div(1 ether);
            // update storage
            amountInviteeReward0[sender] = amountInviteeReward0[sender].add(inviteeReward_);
            amountInviterReward0[inviter_] = amountInviterReward0[inviter_].add(inviterReward_);
            amountInviteeRewardTotal0 = amountInviteeRewardTotal0.add(inviteeReward_);
            amountInviterRewardTotal0 = amountInviterRewardTotal0.add(inviterReward_);

            IERC20Mintable(token0).mint(sender, inviteeReward_);
            IERC20Mintable(token0).mint(inviter_, inviterReward_);
        }

        emit Swapped(sender, inviter_, amount0_, amount1_);
    }

    /* ====== VIEW FUNCTIONS ====== */

    function calcT1(uint256 amount_) public view returns (uint256) {
        uint256 t0_ = t0;

        uint256 a_ = k;
        uint256 b_ = uint256(2).mul(b);
        uint256 n_c_ = uint256(2).mul(amount_).add(a_.mul(t0_).mul(t0_).div(kDenominator)).add(b_.mul(t0_).div(bDenominator));

        uint256 b2_add_4ac = b_.mul(kDenominator).div(bDenominator).mul(b_).div(bDenominator).add(uint256(4).mul(a_).mul(n_c_)).mul(kDenominator);

        return b2_add_4ac.sqrrt().sub(b_.mul(kDenominator).div(bDenominator)).div(uint256(2).mul(a_)).sub(t0_);
    }

}