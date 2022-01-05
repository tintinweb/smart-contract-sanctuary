/**
 *Submitted for verification at Etherscan.io on 2022-01-05
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;



// Part: IBasicRewards

interface IBasicRewards {
    function stakeFor(address, uint256) external returns (bool);

    function balanceOf(address) external view returns (uint256);

    function earned(address) external view returns (uint256);

    function withdrawAll(bool) external returns (bool);

    function withdraw(uint256, bool) external returns (bool);

    function getReward() external returns (bool);

    function stake(uint256) external returns (bool);
}

// Part: ICurveFactoryPool

interface ICurveFactoryPool {
    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function get_balances() external view returns (uint256[2] memory);

    function add_liquidity(
        uint256[2] memory _amounts,
        uint256 _min_mint_amount,
        address _receiver
    ) external returns (uint256);

    function exchange(
        int128 i,
        int128 j,
        uint256 _dx,
        uint256 _min_dy,
        address _receiver
    ) external returns (uint256);
}

// Part: ICurveV2Pool

interface ICurveV2Pool {
    function get_dy(
        uint256 i,
        uint256 j,
        uint256 dx
    ) external view returns (uint256);

    function exchange_underlying(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 min_dy
    ) external payable returns (uint256);
}

// Part: ICvxCrvDeposit

interface ICvxCrvDeposit {
    function deposit(uint256, bool) external;
}

// Part: IMerkleDistributorV2

interface IMerkleDistributorV2 {
    enum Option {
        Claim,
        ClaimAsETH,
        ClaimAsCRV,
        ClaimAsCVX,
        ClaimAndStake
    }

    function vault() external view returns (address);

    function merkleRoot() external view returns (bytes32);

    function week() external view returns (uint32);

    function frozen() external view returns (bool);

    function isClaimed(uint256 index) external view returns (bool);

    function setApprovals() external;

    function claim(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof,
        Option option
    ) external;

    function freeze() external;

    function unfreeze() external;

    function stake() external;

    function updateMerkleRoot(bytes32 newMerkleRoot, bool unfreeze) external;

    event Claimed(
        uint256 index,
        uint256 amount,
        address indexed account,
        uint256 indexed week,
        Option option
    );
    event MerkleRootUpdated(bytes32 indexed merkleRoot, uint32 indexed week);
}

// Part: IMultiMerkleStash

interface IMultiMerkleStash {
    struct claimParam {
        address token;
        uint256 index;
        uint256 amount;
        bytes32[] merkleProof;
    }

    function isClaimed(address token, uint256 index)
        external
        view
        returns (bool);

    function claim(
        address token,
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external;

    function claimMulti(address account, claimParam[] calldata claims) external;

    function updateMerkleRoot(address token, bytes32 _merkleRoot) external;

    event Claimed(
        address indexed token,
        uint256 index,
        uint256 amount,
        address indexed account,
        uint256 indexed update
    );
    event MerkleRootUpdated(
        address indexed token,
        bytes32 indexed merkleRoot,
        uint256 indexed update
    );
}

// Part: IUniV2Router

interface IUniV2Router {
    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);
}

// Part: IUniV3Router

interface IUniV3Router {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function exactInputSingle(ExactInputSingleParams calldata params)
        external
        returns (uint256 amountOut);
}

// Part: IVotiumRegistry

interface IVotiumRegistry {
    struct Registry {
        uint256 start;
        address to;
        uint256 expiration;
    }

    function registry(address _from)
        external
        view
        returns (Registry memory registry);

    function setRegistry(address _to) external;
}

// Part: IWETH

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

// Part: OpenZeppelin/[email protected]/Address

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

// Part: OpenZeppelin/[email protected]/Context

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// Part: OpenZeppelin/[email protected]/IERC20

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

// Part: OpenZeppelin/[email protected]/Ownable

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// Part: OpenZeppelin/[email protected]/SafeERC20

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

// Part: UnionBase

// Common variables and functions
contract UnionBase {
    address public constant CVXCRV_STAKING_CONTRACT =
        0x3Fe65692bfCD0e6CF84cB1E7d24108E434A7587e;
    address public constant CURVE_CRV_ETH_POOL =
        0x8301AE4fc9c624d1D396cbDAa1ed877821D7C511;
    address public constant CURVE_CVX_ETH_POOL =
        0xB576491F1E6e5E62f1d8F26062Ee822B40B0E0d4;
    address public constant CURVE_CVXCRV_CRV_POOL =
        0x9D0464996170c6B9e75eED71c68B99dDEDf279e8;

    address public constant CRV_TOKEN =
        0xD533a949740bb3306d119CC777fa900bA034cd52;
    address public constant CVXCRV_TOKEN =
        0x62B9c7356A2Dc64a1969e19C23e4f579F9810Aa7;
    address public constant CVX_TOKEN =
        0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;

    uint256 public constant CRVETH_ETH_INDEX = 0;
    uint256 public constant CRVETH_CRV_INDEX = 1;
    int128 public constant CVXCRV_CRV_INDEX = 0;
    int128 public constant CVXCRV_CVXCRV_INDEX = 1;
    uint256 public constant CVXETH_ETH_INDEX = 0;
    uint256 public constant CVXETH_CVX_INDEX = 1;

    IBasicRewards cvxCrvStaking = IBasicRewards(CVXCRV_STAKING_CONTRACT);
    ICurveV2Pool cvxEthSwap = ICurveV2Pool(CURVE_CVX_ETH_POOL);
    ICurveV2Pool crvEthSwap = ICurveV2Pool(CURVE_CRV_ETH_POOL);
    ICurveFactoryPool crvCvxCrvSwap = ICurveFactoryPool(CURVE_CVXCRV_CRV_POOL);

    /// @notice Swap CRV for cvxCRV on Curve
    /// @param amount - amount to swap
    /// @param recipient - where swapped tokens will be sent to
    /// @return amount of CRV obtained after the swap
    function _swapCrvToCvxCrv(uint256 amount, address recipient)
        internal
        returns (uint256)
    {
        return _crvToCvxCrv(amount, recipient, 0);
    }

    /// @notice Swap CRV for cvxCRV on Curve
    /// @param amount - amount to swap
    /// @param recipient - where swapped tokens will be sent to
    /// @param minAmountOut - minimum expected amount of output tokens
    /// @return amount of CRV obtained after the swap
    function _swapCrvToCvxCrv(
        uint256 amount,
        address recipient,
        uint256 minAmountOut
    ) internal returns (uint256) {
        return _crvToCvxCrv(amount, recipient, minAmountOut);
    }

    /// @notice Swap CRV for cvxCRV on Curve
    /// @param amount - amount to swap
    /// @param recipient - where swapped tokens will be sent to
    /// @param minAmountOut - minimum expected amount of output tokens
    /// @return amount of CRV obtained after the swap
    function _crvToCvxCrv(
        uint256 amount,
        address recipient,
        uint256 minAmountOut
    ) internal returns (uint256) {
        return
            crvCvxCrvSwap.exchange(
                CVXCRV_CRV_INDEX,
                CVXCRV_CVXCRV_INDEX,
                amount,
                minAmountOut,
                recipient
            );
    }

    /// @notice Swap cvxCRV for CRV on Curve
    /// @param amount - amount to swap
    /// @param recipient - where swapped tokens will be sent to
    /// @return amount of CRV obtained after the swap
    function _swapCvxCrvToCrv(uint256 amount, address recipient)
        internal
        returns (uint256)
    {
        return _cvxCrvToCrv(amount, recipient, 0);
    }

    /// @notice Swap cvxCRV for CRV on Curve
    /// @param amount - amount to swap
    /// @param recipient - where swapped tokens will be sent to
    /// @param minAmountOut - minimum expected amount of output tokens
    /// @return amount of CRV obtained after the swap
    function _swapCvxCrvToCrv(
        uint256 amount,
        address recipient,
        uint256 minAmountOut
    ) internal returns (uint256) {
        return _cvxCrvToCrv(amount, recipient, minAmountOut);
    }

    /// @notice Swap cvxCRV for CRV on Curve
    /// @param amount - amount to swap
    /// @param recipient - where swapped tokens will be sent to
    /// @param minAmountOut - minimum expected amount of output tokens
    /// @return amount of CRV obtained after the swap
    function _cvxCrvToCrv(
        uint256 amount,
        address recipient,
        uint256 minAmountOut
    ) internal returns (uint256) {
        return
            crvCvxCrvSwap.exchange(
                CVXCRV_CVXCRV_INDEX,
                CVXCRV_CRV_INDEX,
                amount,
                minAmountOut,
                recipient
            );
    }

    /// @notice Swap CRV for native ETH on Curve
    /// @param amount - amount to swap
    /// @return amount of ETH obtained after the swap
    function _swapCrvToEth(uint256 amount) internal returns (uint256) {
        return _crvToEth(amount, 0);
    }

    /// @notice Swap CRV for native ETH on Curve
    /// @param amount - amount to swap
    /// @param minAmountOut - minimum expected amount of output tokens
    /// @return amount of ETH obtained after the swap
    function _swapCrvToEth(uint256 amount, uint256 minAmountOut)
        internal
        returns (uint256)
    {
        return _crvToEth(amount, minAmountOut);
    }

    /// @notice Swap CRV for native ETH on Curve
    /// @param amount - amount to swap
    /// @param minAmountOut - minimum expected amount of output tokens
    /// @return amount of ETH obtained after the swap
    function _crvToEth(uint256 amount, uint256 minAmountOut)
        internal
        returns (uint256)
    {
        return
            crvEthSwap.exchange_underlying{value: 0}(
                CRVETH_CRV_INDEX,
                CRVETH_ETH_INDEX,
                amount,
                minAmountOut
            );
    }

    /// @notice Swap native ETH for CRV on Curve
    /// @param amount - amount to swap
    /// @return amount of CRV obtained after the swap
    function _swapEthToCrv(uint256 amount) internal returns (uint256) {
        return _ethToCrv(amount, 0);
    }

    /// @notice Swap native ETH for CRV on Curve
    /// @param amount - amount to swap
    /// @param minAmountOut - minimum expected amount of output tokens
    /// @return amount of CRV obtained after the swap
    function _swapEthToCrv(uint256 amount, uint256 minAmountOut)
        internal
        returns (uint256)
    {
        return _ethToCrv(amount, minAmountOut);
    }

    /// @notice Swap native ETH for CRV on Curve
    /// @param amount - amount to swap
    /// @param minAmountOut - minimum expected amount of output tokens
    /// @return amount of CRV obtained after the swap
    function _ethToCrv(uint256 amount, uint256 minAmountOut)
        internal
        returns (uint256)
    {
        return
            crvEthSwap.exchange_underlying{value: amount}(
                CRVETH_ETH_INDEX,
                CRVETH_CRV_INDEX,
                amount,
                minAmountOut
            );
    }

    /// @notice Swap native ETH for CVX on Curve
    /// @param amount - amount to swap
    /// @return amount of CRV obtained after the swap
    function _swapEthToCvx(uint256 amount) internal returns (uint256) {
        return _ethToCvx(amount, 0);
    }

    /// @notice Swap native ETH for CVX on Curve
    /// @param amount - amount to swap
    /// @param minAmountOut - minimum expected amount of output tokens
    /// @return amount of CRV obtained after the swap
    function _swapEthToCvx(uint256 amount, uint256 minAmountOut)
        internal
        returns (uint256)
    {
        return _ethToCvx(amount, minAmountOut);
    }

    /// @notice Swap native ETH for CVX on Curve
    /// @param amount - amount to swap
    /// @param minAmountOut - minimum expected amount of output tokens
    /// @return amount of CRV obtained after the swap
    function _ethToCvx(uint256 amount, uint256 minAmountOut)
        internal
        returns (uint256)
    {
        return
            cvxEthSwap.exchange_underlying{value: amount}(
                CVXETH_ETH_INDEX,
                CVXETH_CVX_INDEX,
                amount,
                minAmountOut
            );
    }
}

// File: UnionZap.sol

contract UnionZap is Ownable, UnionBase {
    using SafeERC20 for IERC20;

    address public votiumDistributor =
        0x378Ba9B73309bE80BF4C2c027aAD799766a7ED5A;
    address public unionDistributor;

    address private constant SUSHI_ROUTER =
        0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
    address private constant UNISWAP_ROUTER =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private constant UNIV3_ROUTER =
        0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private constant CVXCRV_DEPOSIT =
        0x8014595F2AB54cD7c604B00E9fb932176fDc86Ae;
    address public constant VOTIUM_REGISTRY =
        0x92e6E43f99809dF84ed2D533e1FD8017eb966ee2;

    uint256 private constant BASE_TX_GAS = 21000;
    uint256 private constant FINAL_TRANSFER_GAS = 50000;

    uint256 public unionDues = 200;
    uint256 public constant FEE_DENOMINATOR = 10000;
    uint256 public constant MAX_DUES = 400;

    mapping(uint256 => address) private routers;
    mapping(uint256 => uint24) private fees;

    struct claimParam {
        address token;
        uint256 index;
        uint256 amount;
        bytes32[] merkleProof;
    }

    event Received(address sender, uint256 amount);
    event Distributed(uint256 amount, uint256 fees, bool locked);
    event DistributorUpdated(address distributor);
    event VotiumDistributorUpdated(address distributor);
    event DuesUpdated(uint256 dues);
    event FundsRetrieved(address token, address to, uint256 amount);

    constructor(address distributor_) {
        unionDistributor = distributor_;
        routers[0] = SUSHI_ROUTER;
        routers[1] = UNISWAP_ROUTER;
        fees[0] = 3000;
        fees[1] = 10000;
    }

    /// @notice Update union fees
    /// @param dues - Fees taken from the collected bribes in bips
    function setUnionDues(uint256 dues) external onlyOwner {
        require(dues <= MAX_DUES, "Dues too high");
        unionDues = dues;
        emit DuesUpdated(dues);
    }

    /// @notice Update the contract used to distribute funds
    /// @param distributor_ - Address of the new contract
    function updateDistributor(address distributor_) external onlyOwner {
        require(distributor_ != address(0));
        unionDistributor = distributor_;
        emit DistributorUpdated(distributor_);
    }

    /// @notice Change forwarding address in Votium registry
    /// @param _to - address that will be forwarded to
    /// @dev To be used in case of migration, rewards can be forwarded to
    /// new contracts
    function setForwarding(address _to) external onlyOwner {
        IVotiumRegistry(VOTIUM_REGISTRY).setRegistry(_to);
    }

    /// @notice Update the votium contract address to claim for
    /// @param distributor_ - Address of the new contract
    function updateVotiumDistributor(address distributor_) external onlyOwner {
        require(distributor_ != address(0));
        votiumDistributor = distributor_;
        emit VotiumDistributorUpdated(distributor_);
    }

    /// @notice Withdraws specified ERC20 tokens to the multisig
    /// @param tokens - the tokens to retrieve
    /// @param to - address to send the tokens to
    /// @dev This is needed to handle tokens that don't have ETH pairs on sushi
    /// or need to be swapped on other chains (NBST, WormholeLUNA...)
    function retrieveTokens(address[] calldata tokens, address to)
        external
        onlyOwner
    {
        require(to != address(0));
        for (uint256 i; i < tokens.length; ++i) {
            address token = tokens[i];
            uint256 tokenBalance = IERC20(token).balanceOf(address(this));
            IERC20(token).safeTransfer(to, tokenBalance);
            emit FundsRetrieved(token, to, tokenBalance);
        }
    }

    /// @notice Execute calls on behalf of contract in case of emergency
    function execute(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external onlyOwner returns (bool, bytes memory) {
        (bool success, bytes memory result) = _to.call{value: _value}(_data);
        return (success, result);
    }

    /// @notice Set approvals for the tokens used when swapping
    function setApprovals() external onlyOwner {
        IERC20(CRV_TOKEN).safeApprove(CURVE_CVXCRV_CRV_POOL, 0);
        IERC20(CRV_TOKEN).safeApprove(CURVE_CVXCRV_CRV_POOL, 2**256 - 1);

        IERC20(CRV_TOKEN).safeApprove(CVXCRV_DEPOSIT, 0);
        IERC20(CRV_TOKEN).safeApprove(CVXCRV_DEPOSIT, 2**256 - 1);

        IERC20(CVXCRV_TOKEN).safeApprove(CVXCRV_STAKING_CONTRACT, 0);
        IERC20(CVXCRV_TOKEN).safeApprove(CVXCRV_STAKING_CONTRACT, 2**256 - 1);
    }

    /// @notice Swap a token for ETH
    /// @param token - address of the token to swap
    /// @param amount - amount of the token to swap
    /// @dev Swaps are executed via Sushi or UniV2 router, will revert if pair
    /// does not exist. Tokens must have a WETH pair.
    function _swapToETH(
        address token,
        uint256 amount,
        address router
    ) internal {
        require(router != address(0));
        address[] memory _path = new address[](2);
        _path[0] = token;
        _path[1] = WETH;

        IERC20(token).safeApprove(router, 0);
        IERC20(token).safeApprove(router, amount);

        IUniV2Router(router).swapExactTokensForETH(
            amount,
            0,
            _path,
            address(this),
            block.timestamp + 1
        );
    }

    /// @notice Swap a token for ETH on UniSwap V3
    /// @param token - address of the token to swap
    /// @param amount - amount of the token to swap
    /// @param fee - the pool's fee
    function _swapToETHUniV3(
        address token,
        uint256 amount,
        uint24 fee
    ) internal {
        IERC20(token).safeApprove(UNIV3_ROUTER, 0);
        IERC20(token).safeApprove(UNIV3_ROUTER, amount);
        IUniV3Router.ExactInputSingleParams memory _params = IUniV3Router
            .ExactInputSingleParams(
                token,
                WETH,
                fee,
                address(this),
                block.timestamp + 1,
                amount,
                1,
                0
            );
        uint256 _wethReceived = IUniV3Router(UNIV3_ROUTER).exactInputSingle(
            _params
        );
        IWETH(WETH).withdraw(_wethReceived);
    }

    /// @notice Claims all specified rewards from Votium
    /// @param claimParams - an array containing the info necessary to claim for
    /// each available token
    /// @dev Used to retrieve tokens that need to be transferred
    function claim(IMultiMerkleStash.claimParam[] calldata claimParams)
        public
        onlyOwner
    {
        require(claimParams.length > 0, "No claims");
        // claim all from votium
        IMultiMerkleStash(votiumDistributor).claimMulti(
            address(this),
            claimParams
        );
    }

    /// @notice Claims all specified rewards and swaps them to ETH
    /// @param claimParams - an array containing the info necessary to claim
    /// @param routerChoices - the router to use for the swap
    /// @param claimBeforeSwap - whether to claim on Votium or not
    /// @param lock - whether to lock or swap crv to cvxcrv
    /// @param stake - whether to stake cvxcrv (if distributor is vault)
    /// @dev routerChoices is a 2-bit bitmap such that
    /// 0b00 (0) - Sushi
    /// 0b01 (1) - UniV2
    /// 0b10 (2) - UniV3 0.3%
    /// 0b11 (3) - UniV3 1%
    /// Ex: 6 = 00 01 10 will swap token 1 on UniV3, 2 on UniV3, last on Sushi
    /// Passing 0 will execute all swaps on sushi
    /// @dev claimBeforeSwap is used in case 3rd party already claimed on Votium
    function _distribute(
        IMultiMerkleStash.claimParam[] calldata claimParams,
        uint256 routerChoices,
        bool claimBeforeSwap,
        bool lock,
        bool stake
    ) internal {
        // initialize gas counting
        uint256 _startGas = gasleft();
        bool _locked = false;

        // claim
        if (claimBeforeSwap) {
            claim(claimParams);
        }

        // swap all claims to ETH
        for (uint256 i; i < claimParams.length; ++i) {
            address _token = claimParams[i].token;
            uint256 _balance = IERC20(_token).balanceOf(address(this));
            // avoid wasting gas / reverting if no balance
            if (_balance <= 1) {
                continue;
            } else {
                // leave one gwei to lower future claim gas costs
                // https://twitter.com/libevm/status/1474870670429360129?s=21
                _balance -= 1;
            }
            // unwrap WETH
            if (_token == WETH) {
                IWETH(WETH).withdraw(_balance);
            }
            // no need to swap bribes paid out in cvxCRV or CRV
            else if ((_token == CRV_TOKEN) || (_token == CVXCRV_TOKEN)) {
                continue;
            } else {
                uint256 _choice = routerChoices & 3;
                if (_choice >= 2) {
                    _swapToETHUniV3(_token, _balance, fees[_choice - 2]);
                } else {
                    _swapToETH(_token, _balance, routers[_choice]);
                }
            }
            routerChoices = routerChoices >> 2;
        }

        uint256 _ethBalance = address(this).balance;

        // swap from ETH to CRV
        uint256 _swappedCrv = _swapEthToCrv(_ethBalance);

        uint256 _crvBalance = IERC20(CRV_TOKEN).balanceOf(address(this));

        // swap on Curve if there is a premium for doing so
        if (!lock) {
            _swapCrvToCvxCrv(_crvBalance, address(this));
        }
        // otherwise deposit & lock
        else {
            ICvxCrvDeposit(CVXCRV_DEPOSIT).deposit(_crvBalance, true);
            _locked = true;
        }

        uint256 _cvxCrvBalance = IERC20(CVXCRV_TOKEN).balanceOf(address(this));

        // freeze distributor before transferring funds
        IMerkleDistributorV2(unionDistributor).freeze();

        // estimate gas cost
        uint256 _gasUsed = _startGas -
            gasleft() +
            BASE_TX_GAS +
            16 *
            msg.data.length +
            FINAL_TRANSFER_GAS;
        // compute the ETH/CRV exchange rate based on previous curve swap
        uint256 _gasCostInCrv = (_gasUsed * tx.gasprice * _swappedCrv) /
            _ethBalance;
        uint256 _fees = (_cvxCrvBalance * unionDues) / FEE_DENOMINATOR;
        uint256 _netDeposit = _cvxCrvBalance - _fees - _gasCostInCrv;

        // transfer funds
        IERC20(CVXCRV_TOKEN).safeTransfer(unionDistributor, _netDeposit);
        if (stake) {
            IMerkleDistributorV2(unionDistributor).stake();
        }
        emit Distributed(_netDeposit, _cvxCrvBalance - _netDeposit, _locked);
    }

    /// @notice External wrapper around _distribute
    /// @param claimParams - an array containing the info necessary to claim
    /// @param routerChoices - the router to use for the swap
    /// @param claimBeforeSwap - whether to claim on Votium or not
    /// @param lock - whether to lock or swap crv to cvxcrv
    function distribute(
        IMultiMerkleStash.claimParam[] calldata claimParams,
        uint256 routerChoices,
        bool claimBeforeSwap,
        bool lock
    ) external onlyOwner {
        _distribute(claimParams, routerChoices, claimBeforeSwap, lock, true);
    }

    /// @notice External wrapper around _distribute
    /// @param claimParams - an array containing the info necessary to claim
    /// @param routerChoices - the router to use for the swap
    /// @param claimBeforeSwap - whether to claim on Votium or not
    /// @param lock - whether to lock or swap crv to cvxcrv
    /// @param stake - whether to stake cvxcrv (if distributor is vault)
    /// @dev Overloads distribute above to allow specifying a stake param to
    /// switch between regular distributor and vault distributor (v2)
    function distribute(
        IMultiMerkleStash.claimParam[] calldata claimParams,
        uint256 routerChoices,
        bool claimBeforeSwap,
        bool lock,
        bool stake
    ) external onlyOwner {
        _distribute(claimParams, routerChoices, claimBeforeSwap, lock, stake);
    }

    // @notice Stakes the accumulated cvxCrv for the owner
    function stakeAccumulated() external onlyOwner {
        cvxCrvStaking.stakeFor(
            owner(),
            IERC20(CVXCRV_TOKEN).balanceOf(address(this)) - 1
        );
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}