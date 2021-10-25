pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/IFarmPool.sol";
import "./interfaces/IPancake.sol";
import "./libs/Initializable.sol";
import "./libs/Mainable.sol";
import "./libs/Recoverable.sol";

contract FarmPool is IFarmPool, Initializable, Mainable, Recoverable {
    // 所有币对池，token0 -> token1 -> status, 0=不存在, 1=开启, 2=关闭
    mapping(address => mapping(address => uint8)) allPairPoolMap;

    // 所有币对
    string[] allPairs;

    // LP池状态, 0=禁用, 1=启用
    uint8 lpPoolStatus = 1;

    // 矿池, pooltype -> token0 -> token1 -> user -> [amount0, amount1]
    mapping(uint8 => mapping(address => mapping(address => mapping(address => uint256[2])))) pariPoolMap;

    // 币对池状态, 0=不存在, 1=开启, 2=禁用
    uint8 PairPoolStatusNotExits = 0;
    uint8 PairPoolStatusEnabled = 1;
    uint8 PairPoolStatusDisabled = 2;

    // 用户单个矿池算力, pooltype -> useraddr -> hashrate
    mapping(uint8 => mapping(address => uint256)) userPoolHashrateMap;

    // 用户币对总算力
    mapping(address => uint256) userHashrateMap;

    // 用户单个矿池奖励
    mapping(address => uint256) userPoolRewardMap;

    // 用户全部奖励
    mapping(address => uint256) userRewardMap;

    // 全网算力
    uint256 totalHashrate = 0;

    // 全网最小算力
    uint256 minTotalHashrate = 0;

    // 全网最大算力
    uint256 maxTotalHashrate = 0;

    // 用户质押的币对, useraddr => pooltype => token0 => token1
    mapping(address => mapping(uint8 => mapping(address => address))) userpariPoolMap;

    // 池子类型, 0=未指定
    uint8 constant PoolTypePoolLP = 1;
    uint8 constant PoolTypePoolPair = 2;

    // 币对池类型
    uint8 constant PairPoolTypeUnknown = 0;
    uint8 constant PairPoolType82 = 1;
    uint8 constant PairPoolType73 = 2;
    uint8 constant PairPoolType55 = 3;

    // 质押事件, poolType -> userAddr -> token0 -> amount0 -> token1 -> amount1
    event PairStaked(uint8, address, address, uint256, address, uint256);

    // 解押事件, poolType -> userAddr -> token0 -> amount0 -> token1 -> amount1
    event PairUnstaked(uint8, address, address, uint256, address, uint256);

    // 增加或扣减币对算力, useraddr -> pooltype -> hashrate
    event AddPairHashrate(address, uint8, uint256);
    event SubPairHashrate(address, uint8, uint256);

    // 增加或扣减LP算力, useraddr, lpaddr, hashrate
    event AddLPHashrate(address, address, uint256);
    event SubLPHashrate(address, address, uint256);

    // 增加币对事件, sender -> token0 -> token1 -> status -> pairname
    event PairAdded(address, address, address, uint8, string);

    // 接口
    IPancake pancake;
    IFarmUser farmUser;

    fallback() external {

    }

    // 初始化
    function init(IPancake _pancake, IFarmUser _farmUser, uint256 _minTotalHashrate, uint256 _maxTotalHashrate) external override onlyMain {
        pancake = _pancake;
        farmUser = _farmUser;

        minTotalHashrate = _minTotalHashrate;
        maxTotalHashrate = _maxTotalHashrate;

        initialized = true;
    }

    // 质押LP
    function stakeLP(address lpToken) external override returns(bool) {
        return true;
    }

    // 解押LP
    function unstakeLP(address lpToken) external override returns(bool) {
        return true;
    }

    // 质押币对
    function stakePair(address userAddr, address token0, uint256 amount0, address token1, uint256 amount1) 
        external override onlyMain needInit returns(bool) {
        require(validPairPool(token0, token1), "Invalid pool.");

        // 判断金额比例, 返回不同池子类型
        uint8 poolType = getPairPoolType(token0, amount0, token1, amount1);
        require(poolType != PairPoolTypeUnknown, "Staking amount not match.");

        // 检查token0余额
        uint256 token0Quota = IERC20(token0).allowance(userAddr, address(this));
        require(token0Quota > amount0, "Amount0 quota not enough.");

        // 检查token1余额
        uint256 token1Quota = IERC20(token1).allowance(userAddr, address(this));
        require(token1Quota > amount1, "Amount0 quota not enough.");

        // 转移代币
        IERC20(token0).transferFrom(userAddr, address(this), amount0);
        IERC20(token1).transferFrom(userAddr, address(this), amount1);

        bool overflow = false;
        uint256 totalAmount0 = 0;
        uint256 totalAmount1 = 0;

        // 读取质押数量
        uint256[2] storage amounts = pariPoolMap[poolType][token0][token1][userAddr];
        
        (overflow, totalAmount0) = SafeMath.tryAdd(amounts[0], amount0);
        require(overflow, "Amount0 is too big.");

        (overflow, totalAmount1) = SafeMath.tryAdd(amounts[1], amount0);
        require(overflow, "Amount1 is too big.");

        // 用户币对池算力
        uint256 userHashrate = userPoolHashrateMap[poolType][userAddr];

        // 更新币对池算力
        addPairHashrate(poolType, userAddr, userHashrate);
        
 
        emit PairStaked(poolType, userAddr, token0, amount0, token1, amount1);
        return true;
    }

    // 解除币对质押, 用户地址, 交易对id
    function unstakePair(address userAddr, uint8 poolType, address token0, address token1) 
        external override onlyMain needInit returns(bool) {
        // 检查质押币对是否存在
        uint256[2] storage amounts = pariPoolMap[poolType][token0][token1][userAddr];
        uint256 amount0 = amounts[0];
        uint256 amount1 = amounts[1];

        require(amount0 > 0 && amount1 > 0, "Not stake token");
        
        // 解押币对
        IERC20(token0).transfer(userAddr, amount0);
        IERC20(token1).transfer(userAddr, amount1);

        uint256 userHashrate = userPoolHashrateMap[poolType][userAddr];

        // 减少币对池算力
        subPairHashrate(poolType, userAddr, userHashrate);

        // 解押事件
        emit PairUnstaked(poolType, userAddr, token0, amount0, token1, amount1);
        return true;
    }

    // 禁用LP池
    function disableLPPool(address token0, address token1) external onlyOwner {
        lpPoolStatus = 0;
    }

    // 开启LP池
    function enableLPPool(address token0, address token1) external onlyOwner {
        lpPoolStatus = 1;
    }

    // 禁用币对池
    function disablePairPool(address token0, address token1) external onlyOwner {
        allPairPoolMap[token0][token1] = 2;
    }

    // 开启币对池
    function enablePairPool(address token0, address token1) external onlyOwner {
        allPairPoolMap[token0][token1] = 1;
    }

    // 验证币对
    function validPairPool(address token0, address token1) public view returns(bool) {
        uint8 status = allPairPoolMap[token0][token1];
        if (status > 0) {
            return true;
        }

        return false;
    }

    // 增加用户币对算力
    function addPairHashrate(uint8 poolType, address userAddr, uint256 hashrate) private {
        bool overflow = false;
        uint256 userHashrate = userPoolHashrateMap[poolType][userAddr];

        (overflow, userHashrate) = SafeMath.tryAdd(userHashrate, hashrate);
        require(!overflow, "userHashrate add overflow");

        // 更新用户及全网算力
        userPoolHashrateMap[poolType][userAddr] = userHashrate;
        
        (overflow, totalHashrate) = SafeMath.tryAdd(totalHashrate, hashrate);
        require(!overflow, "totalHashrate add overflow");

        emit AddPairHashrate(userAddr, poolType, hashrate);
    }

    // 扣减用户币对算力
    function subPairHashrate(uint8 poolType, address userAddr, uint256 hashrate) private {
        bool overflow = false;
        uint256 userHashrate = userPoolHashrateMap[poolType][userAddr];

        (overflow, userHashrate) = SafeMath.trySub(userHashrate, hashrate);
        require(!overflow, "userHashrate sub overflow");

        // 更新用户及全网算力
        userPoolHashrateMap[poolType][userAddr] = userHashrate;
        
        (overflow, totalHashrate) = SafeMath.trySub(totalHashrate, hashrate);
        require(!overflow, "totalHashrate sub overflow");

        emit SubPairHashrate(userAddr, poolType, hashrate);
    }

    // 获取全网算力
    function getTotalHashrate() external override returns(uint256) {
        return totalHashrate;
    }

    // TODO: 获取池子类型, 根据当时的两个币种的价格
    function getPairPoolType(address token0, uint256 amount0, address token1, uint256 amount1) private returns(uint8) {
        uint256 tokn0Price = pancake.getUsdtPrice(token0);
        uint256 token1Price = pancake.getUsdtPrice(token1);

        return PairPoolType82;
    }

    // 获取用户币对质押数量
    function getPairStakeAmounts(uint8 poolType, address token0, address token1, address userAddr) public view returns(uint256, uint256) {
        uint256[2] storage amounts = pariPoolMap[poolType][token0][token1][userAddr];
        return (amounts[0], amounts[1]);
    }

    // 增加币对, 只能增加不能移除
    function addPair(address token0, address token1, uint8 status, string calldata pairName) public onlyOwner {
        require(status == PairPoolStatusEnabled || status == PairPoolStatusDisabled, "Pair status is invalid.");
        require(allPairPoolMap[token0][token1] == 0, "Pair is exists.");

        allPairs.push(pairName);
        allPairPoolMap[token0][token1] = status;

        emit PairAdded(_msgSender(), token0, token1, status, pairName);
    }

    // 返回所有币对
    function getAllPairs() public view returns(string[] memory) {
        return allPairs;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IFarmUser.sol";
import "./IPancake.sol";

interface IFarmPool {
    // 初始化
    function init(IPancake pancake, IFarmUser farmUser, uint256 minTotalHashrate, uint256 maxTotalHashrate) external;

    // 质押LP
    function stakeLP(address lpToken) external returns(bool);

    // 解押LP
    function unstakeLP(address lpToken) external returns(bool);

    // 质押币对
    function stakePair(address userAddr, address token0, uint256 amount0, address token1, uint256 amount1) external returns(bool);

    // 解押币对
    function unstakePair(address userAddr, uint8 poolType, address token0, address token1) external returns(bool);

    // 获取全部算力
    function getTotalHashrate() external returns(uint256);
}

pragma solidity ^0.8.0;

interface IPancake {

    // 初始化
    function init(address usdtAddr, uint8 usdtDecimals) external;

    // 获取token的usdt价格
    function getUsdtPrice(address token) external returns (uint256);
}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

// 可被主合约调用的
abstract contract Initializable {
    // 是否已初始化
    bool initialized = false;

    modifier needInit() {
        require(initialized, "FarmPair not init.");
        _;
    }
}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

// 可被主合约调用的
abstract contract Mainable is Ownable {
    address main;

    modifier onlyMain() {
        require(_msgSender() == main, "Invalid call.");
        _;
    }

    // 设置主合约
    function setMain(address _main) public onlyOwner {
        main = _main;
    }
}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract Recoverable is Ownable {
    event Received(address indexed, uint256);
    event Recover(address indexed, uint256);
    event RecoverToken(address indexed, uint256);

    receive() external virtual payable {
        // custom function code
        emit Received(_msgSender(), msg.value);   
    }

    function recover(address toAddr) public virtual onlyOwner {
        uint256 balance = address(this).balance;

        Address.sendValue(payable(toAddr), balance);
        emit Recover(toAddr, balance);
    }

    function recoverToken(IERC20 token, address toAddr) public virtual onlyOwner {
        uint256 balance = token.balanceOf(address(this));

        token.transfer(toAddr, balance);
        emit RecoverToken(toAddr, balance);
    }
}

// SPDX-License-Identifier: MIT

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

pragma solidity ^0.8.0;

interface IFarmUser {
    // 初始化
    function init() external;
}