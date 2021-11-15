// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./interfaces/IHandler.sol";
import "./libraries/Math.sol";
import "./libraries/SafeUint128.sol";
import "./controller/AccessController.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract UniswapV2Handler is AccessController, IHandler {
    using SafeERC20 for IERC20;

    address public lpFeeTaker;

    struct Stake {
        bytes32 id;
        address staker;
        uint256 rootK;
        uint256 lpAmount;
        address poolAddress;
    }

    mapping(bytes32 => Stake) public stakes;

    event RootKUpdated(bytes32 stakeId, uint256 rookK);
    event Update(bytes32 id, uint256 depositTime, address handler, address pool);
    event Withdraw(bytes32 id, uint256 aquaPremium, uint256 tokenDifference, address pool);

    constructor(address factory, address primary, address index)
    AccessController(factory, primary) {
        UNISWAP_V2_FACTORY=factory;
        lpFeeTaker = index;
    }

    function update(
        bytes32 stakeId,
        uint256 lpAmount,
        address lpToken,
        bytes calldata data
    ) 
        external 
        override 
        onlyPrimaryContract 
    {
        (address pool, address staker) = abi.decode(abi.encodePacked(data), (address, address));

        require(whitelistedPools[pool].status == true, "UNISWAP HANDLER :: POOL NOT WHITELISTED.");
        require(stakes[stakeId].rootK == 0, "UNISWAP HANDLER :: STAKE EXIST");

        (uint256 rootK, , ) = calculateTokenAndRootK(lpAmount, lpToken);
        Stake storage s = stakes[stakeId];
        s.rootK = rootK;
        s.staker = staker;
        s.poolAddress = lpToken;
        s.lpAmount = lpAmount;

        emit RootKUpdated(stakeId, rootK);
        emit Update(stakeId, block.timestamp, address(this), pool);
    }

    function withdraw(
        bytes32 id,
        uint256 tokenIdOrAmount,
        address contractAddress
    )
        external
        override
        onlyPrimaryContract
        returns (
            address[] memory token,
            uint256 premium,
            uint128[] memory tokenFees,
            bytes memory data
        )
    {
        uint256[] memory feesArr = new uint256[](2);
        token = new address[](2);
        tokenFees = new uint128[](2);

        (feesArr[0], feesArr[1], token[0], token[1]) = calculateFee(
            id,
            stakes[id].lpAmount,
            tokenIdOrAmount,
            contractAddress
        );

        premium = whitelistedPools[stakes[id].poolAddress].aquaPremium;

        // transferLPTokens(tokenIdOrAmount, feesArr[0], feesArr[1], contractAddress, stakes[id].staker);

        tokenFees[0] = SafeUint128.toUint128(feesArr[0]);
        tokenFees[1] = SafeUint128.toUint128(feesArr[1]);

        if (stakes[id].lpAmount != tokenIdOrAmount) {
            stakes[id].lpAmount -= tokenIdOrAmount;
        } else {
            delete stakes[id];
        }

        return (token, premium, tokenFees, abi.encodePacked(stakes[id].poolAddress));
    }

    function transferLPTokens(
        uint256 amount,
        uint256 tokenFeesA,
        uint256 tokenFeesB,
        address lpToken,
        address staker
    ) internal onlyPrimaryContract {
        uint256 lpTokenFee = calculateLPToken(tokenFeesA, tokenFeesB, lpToken);
        IERC20(lpToken).safeTransfer(staker, amount - lpTokenFee);
        IERC20(lpToken).safeTransfer(lpFeeTaker, lpTokenFee);
    }

    function calculateLPToken(
        uint256 tokenFeesA,
        uint256 tokenFeesB,
        address lpToken
    ) public view returns (uint256 lpAmount) {
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(lpToken).getReserves();
        uint256 lpAmountA = (tokenFeesA * IUniswapV2Pair(lpToken).totalSupply()) / reserve0;
        uint256 lpAmountB = (tokenFeesB * IUniswapV2Pair(lpToken).totalSupply()) / reserve1;
        lpAmount = lpAmountA + lpAmountB;
    }

    function calculateFee(
        bytes32 id,
        uint256 lpAmount,
        uint256 lpUnstakeAmount,
        address lpToken
    )
        internal
        onlyPrimaryContract
        returns (
            uint256 tokenFeesA,
            uint256 tokenFeesB,
            address tokenA,
            address tokenB
        )
    {
        Stake storage s = stakes[id];
        uint256[] memory tokenAmountArr = new uint256[](3);

        uint256 lpPercentage = (lpUnstakeAmount * 10000) / lpAmount;
        (tokenAmountArr[0], tokenAmountArr[1], tokenAmountArr[2]) = calculateTokenAndRootK(lpAmount, lpToken);

        uint256 kDiff;
        uint256 newRootK;

        if (tokenAmountArr[0] < s.rootK) {
            kDiff = (s.rootK - tokenAmountArr[0]);
            newRootK = tokenAmountArr[0];
        } else {
            kDiff = tokenAmountArr[0] - s.rootK;
            newRootK = s.rootK;
        }

        (tokenA, tokenB) = getPairTokens(lpToken);

        kDiff = (kDiff * lpPercentage) / 10000;
        // // fees relative to unstake amount
        // uint256 unstakeAmountInTermsOfK = (tokenAmountArr[0] * lpPercentage) / 10000;

        // // Keep this amount of LP in protocol
        // uint256 feeInTermsOfK = (kDiff * lpPercentage) / 10000;

        // Calculate fee for token0 & token1
        tokenFeesA = (tokenAmountArr[1] * kDiff ) / s.lpAmount;
        tokenFeesB = (tokenAmountArr[2] * kDiff ) / s.lpAmount;

        (lpUnstakeAmount,,) = calculateTokenAndRootK(lpUnstakeAmount,lpToken);
        s.rootK = newRootK - ((s.rootK*lpPercentage)/10000) - kDiff;

        emit RootKUpdated(id, s.rootK);
    }

    function calculateTokenAndRootK(uint256 lpAmount, address lpToken)
        public
        view
        returns (
            uint256 rootK,
            uint256 tokenAAmount,
            uint256 tokenBAmount
        )
    {
        uint256 totalSupply = IUniswapV2Pair(lpToken).totalSupply();
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(lpToken).getReserves();
        tokenAAmount = (lpAmount * reserve0) / totalSupply;
        tokenBAmount = (lpAmount * reserve1) / totalSupply;
        rootK = Math.sqrt(tokenAAmount * tokenBAmount);
    }

    function getPairTokens(address lpToken) public view returns (address, address) {
        return (IUniswapV2Pair(lpToken).token0(), IUniswapV2Pair(lpToken).token1());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface IHandler {
    function withdraw(
        bytes32 id,
        uint256 tokenIdOrAmount,
        address contractAddress
    )
    external
    returns (
        address[] memory token,
        uint256 premium,
        uint128[] memory tokenFees,
        bytes memory data
    );

    function update(
        bytes32 id,
        uint256 tokenValue,
        address contractAddress,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

// A library for performing overflow-safe math, courtesy of DappHub: https://github.com/dapphub/ds-math/blob/d0ef6d6a5f/src/math.sol
// Modified to include only the essentials
library Math {
    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

library SafeUint128 {
    /// @notice Cast a uint256 to a uint128, revert on overflow
    /// @param y The uint256 to be downcasted
    /// @return z The downcasted integer, now type uint128
    function toUint128(uint256 y) internal pure returns (uint128 z) {
        require((z = uint128(y)) == y);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "../interfaces/IAccessController.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

contract AccessController is IAccessController, Ownable {
    
    address public UNISWAP_V2_FACTORY;
    address public AQUA_PRIMARY;

    struct Pool {
        uint256 aquaPremium;
        bool status;
        bytes data;
    }

    mapping(address => Pool) public override whitelistedPools;

    modifier onlyAquaPrimary() {
        require(msg.sender == AQUA_PRIMARY, "UniswapHandler :: Not Aqua Primary.");
        _;
    }

    modifier onlyPrimaryContract {
        require(msg.sender == AQUA_PRIMARY, "UNISWAP HANDLER :: NOT AQUA PRIMARY");
        _;
    }

    event OwnerUpdated(address oldOwner, address newOwner);
    event PoolAdded(address pool, uint256 aquaPremium, bool status);
    event PoolPremiumUpdated(address pool, uint256 oldAquaPremium, uint256 newAquaPremium);
    event AquaPrimaryUpdated(address oldAddress, address newAddress);
    event PoolStatusUpdated(address pool, bool oldStatus, bool newStatus);

    constructor(address factory, address primary) {
        UNISWAP_V2_FACTORY = factory;
        AQUA_PRIMARY = primary;
    }

    function addPools(
        address[] memory tokenA,
        address[] memory tokenB,
        uint256[] memory aquaPremium
    ) external override onlyOwner {
        require(
            (tokenA.length == tokenB.length) && (tokenB.length == aquaPremium.length),
            "Uniswap Handler :: Invalid Args."
        );
        for (uint8 i = 0; i < tokenA.length; i++) {
            address pool = IUniswapV2Factory(UNISWAP_V2_FACTORY).getPair(tokenA[i], tokenB[i]);
            require(pool != address(0), "Uniswap handler :: Pool does not exist");
            whitelistedPools[pool] = Pool(aquaPremium[i], true, abi.encode(0));
            emit PoolAdded(pool, aquaPremium[i], true);
        }
    }

    function updatePremiumOfPool(address pool, uint256 newAquaPremium) external override onlyOwner {
        emit PoolPremiumUpdated(pool, whitelistedPools[pool].aquaPremium, newAquaPremium);
        whitelistedPools[pool].aquaPremium = newAquaPremium;
    }

    function updatePoolStatus(address pool) external override onlyOwner {
        bool status = whitelistedPools[pool].status;
        emit PoolStatusUpdated(pool, status, !status);
        whitelistedPools[pool].status = !status;
    }

    function updatePrimary(address newAddress) external override onlyOwner {
        emit AquaPrimaryUpdated(AQUA_PRIMARY, newAddress);
        AQUA_PRIMARY = newAddress;
    }
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;
interface IAccessController {
    function updatePremiumOfPool(address pool, uint256 newAquaPremium) external;

    function addPools(
        address[] calldata tokenA,
        address[] calldata tokenB,
        uint256[] calldata aquaPremium
    ) external;

    function updatePoolStatus(
        address pool
    ) external;

    function updatePrimary(
        address newAddress
    ) external;

    function whitelistedPools(
        address pool
    )
    external
    returns (
        uint256,
        bool,
        bytes calldata data
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

