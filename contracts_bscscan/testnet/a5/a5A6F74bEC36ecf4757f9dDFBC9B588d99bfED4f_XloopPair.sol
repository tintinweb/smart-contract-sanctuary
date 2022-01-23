/**
 *Submitted for verification at BscScan.com on 2022-01-23
*/

/**
 *Submitted for verification at BscScan.com on 2022-01-22
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
pragma experimental ABIEncoderV2;

interface ICloneFactory {
    function clone(address prototype) external returns (address proxy);
}

// introduction of proxy mode design: https://docs.openzeppelin.com/upgrades/2.8/
// minimum implementation of transparent proxy: https://eips.ethereum.org/EIPS/eip-1167

contract CloneFactory is ICloneFactory {
    function clone(address prototype)
        external
        override
        returns (address proxy)
    {
        bytes20 targetBytes = bytes20(prototype);
        assembly {
            let clone := mload(0x40)
            mstore(
                clone,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(clone, 0x14), targetBytes)
            mstore(
                add(clone, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            proxy := create(0, clone, 0x37)
        }
        return proxy;
    }
}

// File: contracts/LIB/Ownable.sol

contract Ownable {
    address private _OWNER_;
    address private _NEW_OWNER_;

    event OwnershipTransferPrepared(
        address indexed previousOwner,
        address indexed newOwner
    );

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function _omsgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function owner() public view virtual returns (address) {
        return _OWNER_;
    }

    function newOwner() public view virtual returns (address) {
        return _NEW_OWNER_;
    }

    modifier onlyOwner() {
        require(_omsgSender() == _OWNER_, "NOT_OWNER");
        _;
    }

    constructor() {
        _OWNER_ = _omsgSender();
        emit OwnershipTransferred(address(0), _OWNER_);
    }

    function transferOwnership(address user) external onlyOwner {
        require(user != address(0), "INVALID_OWNER");
        emit OwnershipTransferPrepared(_OWNER_, user);
        _NEW_OWNER_ = user;
    }

    function claimOwnership() external {
        require(
            _omsgSender() == _NEW_OWNER_ && _omsgSender() != address(0),
            "INVALID_CLAIM"
        );
        emit OwnershipTransferred(_OWNER_, _NEW_OWNER_);
        _OWNER_ = _NEW_OWNER_;
        _NEW_OWNER_ = address(0);
    }
}

// File: contracts/LIB/Address.sol

// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResult(success, returndata, errorMessage);
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

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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

// File: contracts/INTF/IXloopPair.sol

interface IXloopPair {
    function initialize(
        address,
        address,
        address,
        uint256,
        address,
        bool
    ) external;
}

// File: contracts/INTF/IXLT_IERC20.sol

// This is a file copied from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IXLT_IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function name() external view returns (string memory);

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

    function mint(address user, uint256 value) external;
}

// File: contracts/LIB/SafeERC20.sol

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
        IXLT_IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IXLT_IERC20 token,
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
     * {IXLT_IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IXLT_IERC20 token,
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
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IXLT_IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

// File: contracts/INTF/IXloopFactory.sol

interface IXloopFactory {
    function reward(address user) external;
}

// File: contracts/INTF/IXLoopLK.sol

interface IXLoopLK {
    function mint(address user, uint256 value) external returns (bool);

    function burn(address user, uint256 value) external returns (bool);

    function balanceOf(address owner) external view returns (uint256);

    function totalSupply() external view returns (uint256);
}

// File: contracts/LIB/XLTContext.sol

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract XLTContext {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: contracts/LIB/SafeMath.sol

/**
 *
 * @notice Math operations with safety checks that revert on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "MUL_ERROR");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "DIVIDING_ERROR");
        return a / b;
    }

    function divCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 quotient = div(a, b);
        uint256 remainder = a - quotient * b;
        if (remainder > 0) {
            return quotient + 1;
        } else {
            return quotient;
        }
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SUB_ERROR");
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "ADD_ERROR");
        return c;
    }

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = x / 2 + 1;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}

// File: contracts/XloopPair.sol

contract XloopPair is IXloopPair, XLTContext {
    using SafeMath for uint256;
    using SafeERC20 for IXLT_IERC20;

    address private immutable FACTORY;
    bool private PAIR_INITIALIZED = false;

    address public LK_TOKEN;
    uint256 public LK_DIFFDEC;
    address public TOKEN_A;
    address public TOKEN_A_ROOT;
    uint256 public XLT_TOKEN_A;
    uint256 public XLT_TOKEN_B;

    uint256 public XLT_AB_PRICE;
    uint256 public XLT_MAX_AB_PRICE;
    uint256 public XLT_PERSHARE;

    uint256 public PRATE;
    address public PROVIDER;
    address public NEW_PROVIDER;
    uint256 public PTOTAL_FUND;
    uint256 public PTOTAL_FUND_LIMIT;
    uint256 public PTOTAL_FUND_MINI;
    uint256 public PTOTAL_FUND_WITHDRAW;

    bool public IS_REWARD;
    bool public IS_ON_OPEN;
    bool public IS_P_CLOSED;
    bool public IS_P_MINTED;

    uint112 public GRANT_ID;

    constructor() {
        require(_msgSender() != address(0), "ADDR_ZERO");
        FACTORY = _msgSender();
        PAIR_INITIALIZED = false;
    }

    function fatory() public view virtual returns (address) {
        return FACTORY;
    }

    function initialized() public view virtual returns (bool) {
        return PAIR_INITIALIZED;
    }

    bool private _ENTERED_;
    modifier lock() {
        require(!_ENTERED_, "REENTRANT");
        _ENTERED_ = true;
        _;
        _ENTERED_ = false;
    }

    modifier minted() {
        require(IS_P_MINTED == true, "NOT_MINTED");
        _;
    }

    event Deposite(address indexed user, uint256 value, uint256 value_ab);
    event Withdraw(address indexed user, uint256 value, uint256 value_ab);
    event ProviderWithdraw(
        address indexed user,
        uint256 value,
        uint256 value_ab
    );
    event ReturnA(address indexed user, uint256 value);
    event ReturnB(address indexed user, uint256 value);

    event AB(uint256 a, uint256 b);
    event Init(address indexed contracts);
    event InitMinted(address indexed user, address indexed contracts);
    event CloseProject(
        address indexed user,
        address indexed contracts,
        uint256 value
    );
    event SetPFund(
        address indexed user,
        uint256 rate,
        uint256 limit_fund,
        uint256 max_ab_price
    );
    event ProviderTransferPrepared(
        address indexed previousOwner,
        address indexed newOwner
    );
    event ProviderTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function transferProvider(address P_NEW_PROVIDER) external {
        require(
            _msgSender() == PROVIDER || _msgSender() == FACTORY,
            "FORBIDDEN"
        );
        require(P_NEW_PROVIDER != address(0), "INVALID_OWNER");
        NEW_PROVIDER = P_NEW_PROVIDER;
        emit ProviderTransferPrepared(PROVIDER, P_NEW_PROVIDER);
    }

    function claimProvider() external {
        require(
            _msgSender() == NEW_PROVIDER && _msgSender() != address(0),
            "INVALID_CLAIM"
        );
        PROVIDER = NEW_PROVIDER;
        NEW_PROVIDER = address(0);
        emit ProviderTransferred(PROVIDER, NEW_PROVIDER);
    }

    function closeProject() external minted lock {
        // sufficient check
        require(
            _msgSender() == PROVIDER || _msgSender() == FACTORY,
            "FORBIDDEN"
        );
        require(IS_P_CLOSED == false, "IS_P_CLOSED");
        /** balance */
        uint256 return_amount = 0;
        if (PTOTAL_FUND > 0) {
            return_amount = (PTOTAL_FUND.sub(PTOTAL_FUND_WITHDRAW));
            if (return_amount > 0) {
                XLT_TOKEN_A = XLT_TOKEN_A.add(return_amount);
                PTOTAL_FUND = PTOTAL_FUND_WITHDRAW;
            }
        }
        // set state
        IS_P_CLOSED = true;
        emit CloseProject(_msgSender(), address(this), return_amount);
    }

    function setPFund(
        uint256 pershare,
        uint256 rate_fund,
        uint256 limit_fund,
        uint256 max_ab_price
    ) external minted lock {
        require(_msgSender() == PROVIDER, "FORBIDDEN");
        require(
            (pershare > 0 && pershare < 1001) &&
                (PTOTAL_FUND <= limit_fund) &&
                (limit_fund >= PTOTAL_FUND_MINI) &&
                (rate_fund < 1001) &&
                (max_ab_price > 0),
            "PARAM_FAILED"
        );
        require((max_ab_price >= XLT_AB_PRICE), "PARAM_FAILED");
        XLT_PERSHARE = pershare; // Max : (1000/1000)
        PRATE = rate_fund; // Max : (1000/1000)
        PTOTAL_FUND_LIMIT = limit_fund;
        XLT_MAX_AB_PRICE = max_ab_price;
        emit SetPFund(_msgSender(), rate_fund, limit_fund, max_ab_price);
    }

    function setIsOnProviderOpen(bool _IS_ON) external minted lock {
        require(_msgSender() == PROVIDER, "FORBIDDEN");
        IS_ON_OPEN = _IS_ON;
    }

    function setGrant(uint112 p_grant_id) external minted lock {
        require(_msgSender() == PROVIDER, "FORBIDDEN");
        GRANT_ID = p_grant_id;
    }

    // called once by the factory at time of deployment
    function initialize(
        address P_TOKEN_A,
        address P_TOKEN_A_ROOT,
        address P_LK_TOKEN,
        uint256 P_LK_DIFFDEC,
        address P_PROVIDER,
        bool P_IS_REWARD
    ) external lock {
        // sufficient check
        require(
            _msgSender() == FACTORY && PAIR_INITIALIZED == false,
            "FORBIDDEN"
        );
        require(
            (P_TOKEN_A != address(0)) &&
                (P_LK_TOKEN != address(0)) &&
                (P_PROVIDER != address(0)),
            "ADDR_ZERO"
        );
        // set state
        TOKEN_A = P_TOKEN_A;
        TOKEN_A_ROOT = P_TOKEN_A_ROOT;
        LK_TOKEN = P_LK_TOKEN;
        LK_DIFFDEC = (10**P_LK_DIFFDEC);
        PROVIDER = P_PROVIDER;
        IS_REWARD = P_IS_REWARD;
        /** set init */
        PAIR_INITIALIZED = true;
        emit Init(address(this));
        emit ProviderTransferred(address(0), PROVIDER);
    }

    function initialize_mint_token(
        uint256 max_ab_price,
        uint256 pershare,
        uint256 rate_fund,
        uint256 limit_fund,
        uint256 mini_fund,
        bool p_is_on_open,
        uint112 p_grant_id
    ) external lock {
        // sufficient check
        require(_msgSender() == PROVIDER, "FORBIDDEN");
        require(
            (IS_P_CLOSED == false) && (IS_P_MINTED == false),
            "IS_P_CLOSED_MINTED_FAILED"
        );
        require(
            (pershare > 0 && pershare < 1001) &&
                (rate_fund < 1001) &&
                (limit_fund >= mini_fund) &&
                (max_ab_price > 0),
            "PARAM_FAILED"
        );
        // set info
        XLT_PERSHARE = pershare; // Max : (1000/1000)
        PRATE = rate_fund; // Max : (1000/1000)
        PTOTAL_FUND_LIMIT = limit_fund; // limit_fund.mul(LK_DIFFDEC);
        PTOTAL_FUND_MINI = mini_fund; // mini_fund.mul(LK_DIFFDEC);
        XLT_MAX_AB_PRICE = max_ab_price; // max_ab_price.mul(LK_DIFFDEC);
        // set state
        IS_ON_OPEN = p_is_on_open;
        GRANT_ID = p_grant_id;
        IS_P_MINTED = true;
        emit InitMinted(_msgSender(), address(this));
    }

    function providerTransferOut(uint256 amount) external minted lock {
        // sufficient check
        require(_msgSender() == PROVIDER, "FORBIDDEN");
        require(IS_P_CLOSED == false, "IS_P_CLOSED");
        require(
            (amount > 0) &&
                (PTOTAL_FUND.sub(PTOTAL_FUND_WITHDRAW) > 0) &&
                (PTOTAL_FUND > PTOTAL_FUND_MINI),
            "AMOUNT_EXCEEDED"
        );
        uint256 amount_token_a = amount.mul(LK_DIFFDEC);
        require(
            (amount_token_a > 0) &&
                ((PTOTAL_FUND.sub(PTOTAL_FUND_WITHDRAW)) >= amount_token_a),
            "AMOUNT_EXCEEDED"
        );
        uint256 amount_token_a_trans = amount_token_a.div(LK_DIFFDEC);
        require((amount_token_a_trans > 0), "AMOUNT_A_EXCEEDED");
        /** balance */
        IXLT_IERC20(TOKEN_A).safeTransfer(_msgSender(), amount_token_a_trans);
        PTOTAL_FUND_WITHDRAW = PTOTAL_FUND_WITHDRAW.add(amount_token_a);
        emit ProviderWithdraw(_msgSender(), amount, amount_token_a);
    }

    function deposit(uint256 amount) external payable minted lock {
        require((IS_P_CLOSED == false) && (IS_ON_OPEN), "IS_P_CLOSED_OFF");
        uint256 balance1 = IXLT_IERC20(TOKEN_A).balanceOf(_msgSender());
        require((amount > 0) && (balance1 >= amount), "AMOUNT_EXCEEDED");
        /** calculator token */
        uint256 amount_fund = 0;
        uint256 amount_token_a = amount.mul(LK_DIFFDEC);
        uint256 amount_token_b = amount_token_a;
        if (XLT_AB_PRICE < XLT_MAX_AB_PRICE) {
            if (PTOTAL_FUND < PTOTAL_FUND_LIMIT) {
                amount_fund = (amount_token_a.mul(PRATE)).div(1000);
            }
            amount_token_a = (amount_token_a).sub(amount_fund);
            amount_token_b = ((amount_token_a.mul(XLT_PERSHARE)).div(1000));
        }
        if (XLT_TOKEN_A > 0 && XLT_TOKEN_B > 0) {
            amount_token_b = (amount_token_b.mul(XLT_TOKEN_B)).div(XLT_TOKEN_A);
        }
        /** balance */
        require(
            (amount_token_a > 0) && (amount_token_b > 0),
            "AMOUNT_AB_ZERO_FAILED"
        );
        IXLT_IERC20(TOKEN_A).safeTransferFrom(
            _msgSender(),
            address(this),
            amount
        );
        XLT_TOKEN_A = XLT_TOKEN_A.add(amount_token_a);
        XLT_TOKEN_B = XLT_TOKEN_B.add(amount_token_b);
        _updatePriceAB();
        /** fund */
        if (amount_fund > 0) {
            PTOTAL_FUND = PTOTAL_FUND.add(amount_fund);
        }
        /** lk */
        bool success = IXLoopLK(LK_TOKEN).mint(_msgSender(), amount_token_b);
        require(success, "LK_NOT_SUCCESS");
        emit Deposite(_msgSender(), amount, amount_token_b);
        emit AB(XLT_TOKEN_A, XLT_TOKEN_B);
    }

    function getBalanceA() external view returns (uint256) {
        return IXLT_IERC20(TOKEN_A).balanceOf(address(this));
    }

    function getInfo()
        external
        view
        returns (
            address,
            address,
            address,
            address,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            TOKEN_A,
            TOKEN_A_ROOT,
            PROVIDER,
            FACTORY,
            XLT_MAX_AB_PRICE,
            XLT_TOKEN_A,
            XLT_TOKEN_B,
            PTOTAL_FUND,
            PTOTAL_FUND_MINI
        );
    }

    function withdraw(uint256 amount) external payable minted lock {
        require(
            (XLT_TOKEN_A > 0) && (XLT_TOKEN_B > 0),
            "AMOUNT_AB_ZERO_FAILED"
        );
        uint256 balance1 = IXLT_IERC20(LK_TOKEN).balanceOf(_msgSender());
        require((amount > 0) && (balance1 >= amount), "AMOUNT_EXCEEDED");
        /** calculator */
        uint256 amount_token_a = (amount.mul(XLT_TOKEN_A)).div(XLT_TOKEN_B);
        require(
            (amount_token_a > 0) && (amount_token_a <= XLT_TOKEN_A),
            "AMOUNT_A_EXCEEDED"
        );
        uint256 amount_token_a_trans = amount_token_a.div(LK_DIFFDEC);
        require((amount_token_a_trans > 0), "AMOUNT_A_EXCEEDED");
        /** lk */
        bool success = IXLoopLK(LK_TOKEN).burn(_msgSender(), amount);
        require(success, "LK_NOT_SUCCESS");
        /** balance */
        IXLT_IERC20(TOKEN_A).safeTransfer(_msgSender(), amount_token_a_trans);
        XLT_TOKEN_A = XLT_TOKEN_A.sub(amount_token_a);
        XLT_TOKEN_B = XLT_TOKEN_B.sub(amount);
        _updatePriceAB();
        emit Withdraw(_msgSender(), amount, amount_token_a_trans);
        emit AB(XLT_TOKEN_A, XLT_TOKEN_B);
    }

    function _updatePriceAB() private {
        if (XLT_TOKEN_A > 0 && XLT_TOKEN_B > 0) {
            XLT_AB_PRICE = XLT_TOKEN_A.div(XLT_TOKEN_B);
        } else {
            XLT_AB_PRICE = 0;
        }
    }

    function _return_a(address usr, uint256 amount) internal minted lock {
        uint256 balance1 = IXLT_IERC20(TOKEN_A).balanceOf(usr);
        require((amount > 0) && (balance1 >= amount), "AMOUNT_EXCEEDED");
        /** calculator */
        IXLT_IERC20(TOKEN_A).safeTransferFrom(usr, address(this), amount);
        uint256 amount_token_a = amount.mul(LK_DIFFDEC);
        /** balance */
        XLT_TOKEN_A = XLT_TOKEN_A.add(amount_token_a);
        _updatePriceAB();
        emit AB(XLT_TOKEN_A, XLT_TOKEN_B);
        emit ReturnA(usr, amount);
    }

    function returnA(uint256 amount) external payable {
        _return_a(_msgSender(), amount);
    }

    function _return_b(address usr, uint256 amount) internal minted lock {
        uint256 balance1 = IXLT_IERC20(LK_TOKEN).balanceOf(usr);
        require((amount > 0) && (balance1 >= amount), "AMOUNT_EXCEEDED");
        /** lk */
        bool success = IXLoopLK(LK_TOKEN).burn(usr, amount);
        require(success, "LK_NOT_SUCCESS");
        /** balance */
        XLT_TOKEN_B = XLT_TOKEN_B.sub(amount);
        _updatePriceAB();
        emit AB(XLT_TOKEN_A, XLT_TOKEN_B);
        emit ReturnB(usr, amount);
    }

    function returnB(uint256 amount) external payable {
        _return_b(_msgSender(), amount);
    }
}

// File: contracts/XloopLK.sol

contract XloopLK is IXLoopLK, XLTContext {
    using SafeMath for uint256;

    address public immutable FACTORY;
    bool private _initialized = false;

    uint8 private _decimals;
    string private _symbol;
    string private _name;
    uint256 private _totalSupply;
    address private _pair;
    bool private _is_reward;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Mint(address indexed user, uint256 value);
    event Burn(address indexed user, uint256 value);

    constructor() {
        require(_msgSender() != address(0), "ADDR_ZERO");
        FACTORY = _msgSender();
    }

    function fatory() public view virtual returns (address) {
        return FACTORY;
    }

    function initialized() public view virtual returns (bool) {
        return _initialized;
    }

    function initialize(
        address p_pair,
        string memory p_name,
        string memory p_symbol,
        uint8 p_decimal,
        bool p_is_reward
    ) external {
        require(_msgSender() == FACTORY && _initialized == false, "FORBIDDEN");
        _pair = p_pair;
        _name = p_name;
        _symbol = p_symbol;
        _decimals = p_decimal;
        _is_reward = p_is_reward;
        _initialized = true;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function pair() external view returns (address) {
        return _pair;
    }

    function isReward() external view returns (bool) {
        return _is_reward;
    }

    modifier onlyPair() {
        require(_msgSender() == _pair, "NOT_PAIR_OWNER");
        _;
    }

    /**
     * @dev transfer token for a specified address
     * @param to The address to transfer to.
     * @param amount The amount to be transferred.
     */
    function transfer(address to, uint256 amount) public returns (bool) {
        require(amount <= _balances[_msgSender()], "BALANCE_NOT_ENOUGH");
        _balances[_msgSender()] = _balances[_msgSender()].sub(amount);
        _balances[to] = _balances[to].add(amount);
        emit Transfer(_msgSender(), to, amount);
        // Reward
        if (_is_reward) {
            IXloopFactory(FACTORY).reward(_msgSender());
        }
        return true;
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param owner The address to query the the balance of.
     * @return balance An uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address owner) external view returns (uint256 balance) {
        return _balances[owner];
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param amount uint256 the amount of tokens to be transferred
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        require(amount <= _balances[from], "BALANCE_NOT_ENOUGH");
        require(
            amount <= _allowances[from][_msgSender()],
            "ALLOWANCE_NOT_ENOUGH"
        );
        _balances[from] = _balances[from].sub(amount);
        _balances[to] = _balances[to].add(amount);
        _allowances[from][_msgSender()] = _allowances[from][_msgSender()].sub(
            amount
        );
        emit Transfer(from, to, amount);
        // Reward
        if (_is_reward) {
            IXloopFactory(FACTORY).reward(from);
        }
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of _msgSender().
     * @param spender The address which will spend the funds.
     * @param amount The amount of tokens to be spent.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        _allowances[_msgSender()][spender] = amount;
        emit Approval(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner _allowances to a spender.
     * @param owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address owner, address spender)
        public
        view
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function mint(address user, uint256 amount)
        external
        onlyPair
        returns (bool)
    {
        _balances[user] = _balances[user].add(amount);
        _totalSupply = _totalSupply.add(amount);
        emit Transfer(address(0), user, amount);
        return true;
    }

    function burn(address user, uint256 amount)
        external
        onlyPair
        returns (bool)
    {
        require(amount > 0 && amount <= _balances[user], "BALANCE_NOT_ENOUGH");
        _balances[user] = _balances[user].sub(amount);
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(user, address(0), amount);
        return true;
    }
}

// File: contracts/XloopToken.sol

contract XloopToken is XLTContext {
    using SafeMath for uint256;

    uint8 private _decimals;
    string private _symbol;
    string private _name;
    uint256 private _totalSupply;
    uint256 private _max_mint = (2**256) - (1000000000000000);
    address private immutable _pair;

    constructor(address provider) {
        require(
            _msgSender() != address(0) && provider != address(0),
            "ADDR_ZERO"
        );
        _pair = _msgSender();
        _decimals = 4;
        _symbol = "XLOOP";
        _name = "Xloop Token";
        /** mint to provider */
        _totalSupply = 1000000 * (100000) * (10**_decimals);
        _balances[provider] = _totalSupply;
        emit Transfer(address(0), provider, _totalSupply);
    }

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function pair() external view returns (address) {
        return _pair;
    }

    modifier onlyPair() {
        require(_msgSender() == _pair, "NOT_PAIR_OWNER");
        _;
    }

    /**
     * @dev transfer token for a specified address
     * @param to The address to transfer to.
     * @param amount The amount to be transferred.
     */
    function transfer(address to, uint256 amount) public returns (bool) {
        require(amount <= _balances[_msgSender()], "BALANCE_NOT_ENOUGH");
        _balances[_msgSender()] = _balances[_msgSender()].sub(amount);
        _balances[to] = _balances[to].add(amount);
        emit Transfer(_msgSender(), to, amount);
        return true;
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param owner The address to query the the balance of.
     * @return balance An uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address owner) external view returns (uint256 balance) {
        return _balances[owner];
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param amount uint256 the amount of tokens to be transferred
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        require(amount <= _balances[from], "BALANCE_NOT_ENOUGH");
        require(
            amount <= _allowances[from][_msgSender()],
            "ALLOWANCE_NOT_ENOUGH"
        );
        _balances[from] = _balances[from].sub(amount);
        _balances[to] = _balances[to].add(amount);
        _allowances[from][_msgSender()] = _allowances[from][_msgSender()].sub(
            amount
        );
        emit Transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of _msgSender().
     * @param spender The address which will spend the funds.
     * @param amount The amount of tokens to be spent.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        _allowances[_msgSender()][spender] = amount;
        emit Approval(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner _allowances to a spender.
     * @param owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address owner, address spender)
        public
        view
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function _mint(address user, uint256 amount) private {
        if (_totalSupply.add(amount) < _max_mint) {
            _balances[user] = _balances[user].add((amount));
            _totalSupply = _totalSupply.add(amount);
            emit Transfer(address(0), user, amount);
        }
    }

    function mint(address user, uint256 amount) external onlyPair {
        _mint(user, amount);
    }

    function burn(uint256 amount) external {
        require(
            amount > 0 && amount <= _balances[_msgSender()],
            "BALANCE_NOT_ENOUGH"
        );
        _balances[_msgSender()] = _balances[_msgSender()].sub(amount);
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(_msgSender(), address(0), amount);
    }
}

// File: contracts/XloopFactory.sol

contract XloopFactory is CloneFactory, XLTContext, Ownable {
    address private immutable XloopPairTemp;
    address private immutable XloopLKTemp;
    address private Xloop;

    uint256 private RewardRate = 250;
    uint112 private AllPairsCounter;
    mapping(address => address) private AllPairs;
    mapping(address => address) private AllLK;

    bool private CheckWhiteList = true;
    mapping(address => bool) private WhiteList;
    mapping(address => bool) private XloopGATEList;

    event EventPairCreated(
        address indexed P_TOKEN_A,
        address indexed pair,
        address indexed lk,
        address provider,
        uint112 counter
    );
    event EventHardPairLKCreated(
        address indexed P_TOKEN_A,
        address indexed pair,
        address indexed lk,
        address provider,
        uint112 counter
    );
    event EventWhiteList(address indexed P_TOKEN_A, bool IS_ON);
    event EventXloopGATEList(address indexed P_TOKEN_A, bool IS_ON);
    event EventCheckWhiteList(bool IS_ON);
    event EventSetRewardRate(uint256 rate);

    constructor() {
        require(_msgSender() != address(0), "ADDR_ZERO");
        XloopPairTemp = address(new XloopPair());
        XloopLKTemp = address(new XloopLK());
        Xloop = address(new XloopToken(_msgSender()));
    }

    function xloopPairTemp() external view returns (address) {
        return XloopPairTemp;
    }

    function xloopLKTemp() external view returns (address) {
        return XloopLKTemp;
    }

    function xloop() external view returns (address) {
        return Xloop;
    }

    function pairsCounter() external view returns (uint112) {
        return AllPairsCounter;
    }

    function rewardRate() external view returns (uint256) {
        return RewardRate;
    }

    bool private _ENTERED_;
    modifier lock() {
        require(!_ENTERED_, "REENTRANT");
        _ENTERED_ = true;
        _;
        _ENTERED_ = false;
    }

    function _createPair() private returns (address, address) {
        /** create pair */
        address pair = this.clone(XloopPairTemp);
        address lk = this.clone(XloopLKTemp);
        return (pair, lk);
    }

    function createPair(
        address P_TOKEN_A,
        string memory _name,
        string memory _symbol,
        uint8 _decimal,
        uint8 _diffdec
    ) external lock returns (address, address) {
        require(
            ((_msgSender() != address(0)) &&
                (P_TOKEN_A != address(0)) &&
                (P_TOKEN_A != XloopPairTemp) &&
                (P_TOKEN_A != XloopLKTemp)),
            "IDENTICAL_ADDRESSES"
        );
        address P_TOKEN_A_ROOT = P_TOKEN_A;
        if (AllLK[P_TOKEN_A] != address(0)) {
            P_TOKEN_A_ROOT = AllLK[P_TOKEN_A];
        } else {
            if (CheckWhiteList && _msgSender() != owner()) {
                require(WhiteList[P_TOKEN_A_ROOT], "TOKEN_INVALID");
            }
        }
        require(
            _diffdec > 0 && _diffdec <= 36 && _decimal <= 36,
            "DECIMAL_ERROR"
        );
        /** create pair */
        (address _PAIR, address _LK) = _createPair();
        require(
            (_PAIR != address(0)) &&
                (_LK != address(0)) &&
                (_PAIR != XloopPairTemp) &&
                (_LK != XloopLKTemp),
            "PAIR_ERROR"
        );
        bool _is_reward = false;
        if (P_TOKEN_A_ROOT == Xloop || XloopGATEList[P_TOKEN_A_ROOT]) {
            _is_reward = true;
        }
        XloopLK(_LK).initialize(_PAIR, _name, _symbol, _decimal, _is_reward);
        XloopPair(_PAIR).initialize(
            P_TOKEN_A,
            P_TOKEN_A_ROOT,
            _LK,
            _diffdec,
            _msgSender(),
            _is_reward
        );
        /** set state */
        AllLK[_LK] = P_TOKEN_A_ROOT;
        AllPairs[_PAIR] = _msgSender();
        AllPairsCounter = AllPairsCounter + 1;
        emit EventPairCreated(
            P_TOKEN_A,
            _PAIR,
            _LK,
            _msgSender(),
            AllPairsCounter
        );
        return (_PAIR, _LK);
    }

    function reward(address usr) external {
        if (AllLK[_msgSender()] != address(0) && (RewardRate > 0)) {
            IXLT_IERC20(Xloop).mint(usr, RewardRate);
        }
    }

    function verifyProvider(address pair) external view returns (bool) {
        if (AllPairs[pair] == _msgSender()) {
            return true;
        } else {
            return false;
        }
    }

    function verifyPair(address pair) external view returns (address) {
        return AllPairs[pair];
    }

    function verifyWhiteList(address pair) external view returns (bool) {
        return WhiteList[pair];
    }

    function verifyXloopGATE(address pair) external view returns (bool) {
        return XloopGATEList[pair];
    }

    /* onlyOwner */
    function hardPair(
        address P_TOKEN_A,
        address P_TOKEN_A_ROOT,
        address _PAIR,
        address _LK
    ) external onlyOwner lock {
        require(
            P_TOKEN_A != address(0) &&
                P_TOKEN_A_ROOT != address(0) &&
                _LK != address(0),
            "PAIR_ERROR"
        );
        AllLK[_LK] = P_TOKEN_A_ROOT;
        AllPairs[_PAIR] = _msgSender();
        AllPairsCounter = AllPairsCounter + 1;
        emit EventHardPairLKCreated(
            P_TOKEN_A,
            _PAIR,
            _LK,
            _msgSender(),
            AllPairsCounter
        );
    }

    /* onlyOwner */
    function setWhiteList(address P_TOKEN_A, bool P_IS_ON) external onlyOwner {
        require(P_TOKEN_A != address(0), "ADDR_ZERO");
        WhiteList[P_TOKEN_A] = P_IS_ON;
        emit EventWhiteList(P_TOKEN_A, P_IS_ON);
    }

    /* onlyOwner */
    function setCheckWhiteList(bool P_IS_ON) external onlyOwner {
        CheckWhiteList = P_IS_ON;
        emit EventCheckWhiteList(P_IS_ON);
    }

    /* onlyOwner */
    function setCheckWhiteList(uint256 rate) external onlyOwner {
        RewardRate = rate;
        emit EventSetRewardRate(rate);
    }

    /* onlyOwner */
    function setXloopGATE(address P_TOKEN_A, bool P_IS_ON)
        external
        onlyOwner
        lock
    {
        require(P_TOKEN_A != address(0), "ADDR_ZERO");
        XloopGATEList[P_TOKEN_A] = P_IS_ON;
        emit EventXloopGATEList(P_TOKEN_A, P_IS_ON);
    }

    /* onlyOwner */
    function setXloop(address P_TOKEN) external onlyOwner lock {
        Xloop = P_TOKEN;
    }

    /* Project Management onlyOwner */
    function closeProject(address _PAIR) external onlyOwner {
        XloopPair(_PAIR).closeProject();
    }

    /* Project Management onlyOwner */
    function transferProvider(address _PAIR, address newOwner)
        external
        onlyOwner
    {
        require(newOwner != address(0), "INVALID_OWNER");
        XloopPair(_PAIR).transferProvider(newOwner);
    }
}