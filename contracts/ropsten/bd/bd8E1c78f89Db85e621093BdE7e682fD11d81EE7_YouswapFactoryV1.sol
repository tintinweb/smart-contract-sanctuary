/**
 *Submitted for verification at Etherscan.io on 2021-03-12
*/

// File: @openzeppelin/contracts/utils/Address.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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

// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity >=0.6.0 <0.8.0;

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

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol

pragma solidity >=0.6.0 <0.8.0;




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
    using SafeMath for uint256;
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
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
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


// File: localhost/contract/interface/IYouswapPoolV1.sol

pragma solidity 0.7.4;

interface IYouswapPoolV1 {

    function initialize(address, address, uint256, uint256) external;

    function transferOwner(address) external;

}


// File: localhost/contract/library/ErrorCode.sol

pragma solidity 0.7.4;

library ErrorCode {

    string constant FORBIDDEN = 'YouSwap:FORBIDDEN';
    string constant IDENTICAL_ADDRESSES = 'YouSwap:IDENTICAL_ADDRESSES';
    string constant ZERO_ADDRESS = 'YouSwap:ZERO_ADDRESS';
    string constant INVALID_ADDRESSES = 'YouSwap:INVALID_ADDRESSES';
    string constant BALANCE_INSUFFICIENT = 'YouSwap:BALANCE_INSUFFICIENT';
    string constant REWARDTOTAL_LESS_THAN_REWARDPROVIDE = 'YouSwap:REWARDTOTAL_LESS_THAN_REWARDPROVIDE';
    string constant PARAMETER_TOO_LONG = 'YouSwap:PARAMETER_TOO_LONG';
    string constant REGISTERED = 'YouSwap:REGISTERED';
    // string constant xxx = 'YouSwap:xxxxx';
    // string constant xxx = 'YouSwap:xxxxx';
    // string constant xxx = 'YouSwap:xxxxx';
    // string constant xxx = 'YouSwap:xxxxx';
    // string constant xxx = 'YouSwap:xxxxx';

}
// File: localhost/contract/implement/YouswapPoolV1.sol

pragma solidity 0.7.4;



contract YouswapPoolV1 is IYouswapPoolV1 {

    address public factory;
    address public pool;
    address public lp;
    uint256 public startBlock;
    uint256 public rewardTotal;
    
    constructor() {
        factory = msg.sender;
    }

    function initialize(address _pool, address _lp, uint256 _startBlock, uint256 _rewardTotal) override external {
        require(factory == msg.sender, ErrorCode.FORBIDDEN);
        require((factory != _pool) && (factory != _lp) && (_pool != _lp), ErrorCode.FORBIDDEN);
        pool = _pool;
        lp = _lp;
        startBlock = _startBlock;
        rewardTotal = _rewardTotal;
    }

    function transferOwner(address _factory) override external {
        require(factory == msg.sender, ErrorCode.FORBIDDEN);
        require((address(0) != _factory) && (msg.sender != _factory), ErrorCode.FORBIDDEN);
        require((pool != _factory) && (lp != _factory), ErrorCode.FORBIDDEN);
        factory = _factory;
    }

}
// File: localhost/contract/interface/IYouswapInviteV1.sol

pragma solidity 0.7.4;

interface IYouswapInviteV1 {

    struct UserInfo {
        address up;//上级
        address[] down;//下级
        uint256 startBlock;//邀请块高
    }

    event InviteV1(address indexed owner, address indexed upper, uint256 indexed height);//被邀请人的地址，邀请人的地址，邀请块高

    function inviteLength() external view returns (uint256);//邀请人数

    function inviteDown(address) external view returns (address[] memory);//下级邀请

    function inviteUp(address) external view returns (address);//上级邀请

    function inviteInfoV1(address) external view returns (address[] memory, address[] memory);//下级邀请

    function inviteInfoV2(address) external view returns (uint256, uint256);//下级邀请
    
    function invite(address) external returns (bool);//注册邀请关系
    
    function inviteBatch(address[] memory) external returns (uint, uint);//注册邀请关系，输入数量，成功数量

}
// File: localhost/contract/interface/ITokenYou.sol

pragma solidity 0.7.4;

interface ITokenYou {
    
    function mint(address recipient, uint256 amount) external;
    
    function decimals() external view returns (uint8);
    
}

// File: localhost/contract/interface/IYouswapFactoryV1.sol

pragma solidity 0.7.4;


interface IYouswapFactoryV1 {

    struct UserInfo {
        uint256 startBlock;//质押开始块高
        uint256 amount;//质押数量
        uint256 invitePower;//邀请算力
        uint256 pledgePower;//质押算力
        uint256 pendingReward;//未领取奖励
        uint256 inviteReward;//总邀请奖励
        uint256 pledgeReward;//总质押奖励
    }

    struct PoolInfo {
        uint256 startBlock;//挖矿开始块高
        uint256 rewardTotal;//矿池总奖励
        uint256 rewardProvide;//矿池已发放奖励
        address lp;//LP地址
        uint16 multiple;//奖励倍数
        uint256 sort;//排序
        uint256 amount;//质押数量
        uint256 lastRewardBlock;//最后发放奖励块高
        uint256 inviteSelf;//邀请自奖励
        uint256 invite1Reward;//1级邀请奖励系数
        uint256 invite2Reward;//2级邀请奖励系数
        uint256 rewardPerBlock;//单个区块奖励
        uint256 totalPower;//总算力
        uint256 endBlock;//挖矿结束块高
    }

    ////////////////////////////////////////////////////////////////////////////////////
    
    event AddPool(address, address, address, uint256);
    event Deposit(address, address, address, address, uint256);
    event Withdraw(address, address, address, address, uint256);

    ////////////////////////////////////////////////////////////////////////////////////

    function transferOwnership(address) external;//修改OWNER

    function setYou(ITokenYou) external;//设置YOU
    
    function addPool(string memory, address, uint256, uint256) external returns (address);//新建矿池

    function poolLength() external view returns (uint256);//矿池数量

    function deposit(address, uint256) external;//质押

    function withdraw(address, uint256) external;//解质押并提取

    function withdrawRewad(address) external;//提取

    function poolPledgeAddresss(address) external view returns (address[] memory);//矿池质押地址

    function getPoolAddress() external view returns (address[] memory);//矿池地址

    function computeReward(address) external;//计算奖励

    function powerScale(address, address) external view returns (uint256);//算力占比

    function setOperateOwner(address, bool) external;//设置运营权限

    ////////////////////////////////////////////////////////////////////////////////////    
    
    function setName(address, string memory) external;//修改矿池名称

    function setInviteSelfReward(address, uint256) external;//修改矿池邀请自奖励系数
    
    function setInvite1Reward(address, uint256) external;//修改矿池1级邀请奖励系数

    function setInvite2Reward(address, uint256) external;//修改矿池2级邀请奖励系数
    
    function setRewardPerBlock(address, uint256) external;//修改矿池区块奖励

    function setRewardTotal(address, uint256) external;//修改矿池总奖励

    function setMultiple(address, uint16) external;//修改矿池倍数
    
    function setSort(address, uint256) external;//修改矿池排序
    
    ////////////////////////////////////////////////////////////////////////////////////
    
    function blockNumber() external view returns (uint256);//当前块高

    function erc20Allowance(address, address, address) external returns (uint256);

    function erc20Balance(address, address) external view returns (uint256);

    function erc20Supply(address) external view returns (uint256);

    ////////////////////////////////////////////////////////////////////////////////////
}
// File: localhost/contract/implement/YouswapFactoryV1.sol

pragma solidity 0.7.4;








contract YouswapFactoryV1 is IYouswapFactoryV1 {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public owner;
    mapping(address => bool) public operateOwner;
    ITokenYou public you;
    IYouswapInviteV1 public invite;

    address[] public poolAddress;
    mapping(address => PoolInfo) public poolInfo;
    mapping(address => string) public poolName;
    mapping(address => address[]) public pledgeAddresss;
    mapping(address => mapping(address => UserInfo)) public pledgeUserInfo;

    uint256 public inviteSelfReward = 5;
    uint256 public invite1Reward = 15;
    uint256 public invite2Reward = 10;
    uint256 public rewardPerBlock = 0;

    constructor (ITokenYou _you, IYouswapInviteV1 _invite) {
        owner = msg.sender;
        invite = _invite;
        _setOperateOwner(owner, true);
        _setYou(_you);
    }

    ////////////////////////////////////////////////////////////////////////////////////

    function transferOwnership(address _owner) override external {
        require(owner == msg.sender, ErrorCode.FORBIDDEN);
        require((address(0) != _owner) && (owner != _owner), ErrorCode.INVALID_ADDRESSES);
        address oldOwner = owner;
        owner = _owner;
        _setOperateOwner(oldOwner, false);
        _setOperateOwner(owner, true);
    }

    function setYou(ITokenYou _you) override external {
        _setYou(_you);
    }
    
    function _setYou(ITokenYou _you) internal {
        require(owner == msg.sender, ErrorCode.FORBIDDEN);
        you = _you;
        rewardPerBlock = 40*(10**_you.decimals());
    }
    
    function addPool(string memory _name, address _lp, uint256 _startBlock, uint256 _rewardTotal) override external returns (address) {
        require(operateOwner[msg.sender] && (address(0) != _lp) && (address(this) != _lp), ErrorCode.FORBIDDEN);
        _startBlock = _startBlock < block.number ? block.number : _startBlock;
        address pool;
        bytes32 salt = keccak256(abi.encodePacked(poolAddress.length));
        bytes memory bytecode = type(YouswapPoolV1).creationCode;
        assembly {
            pool := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IYouswapPoolV1(pool).initialize(pool, _lp, _startBlock, _rewardTotal);
        poolAddress.push(pool);

        poolName[pool] = _name;
        
        PoolInfo storage _poolInfo = poolInfo[pool];
        _poolInfo.startBlock = _startBlock;
        _poolInfo.rewardTotal = _rewardTotal;
        _poolInfo.rewardProvide = 0;
        _poolInfo.lp = _lp;
        _poolInfo.multiple = 0;
        _poolInfo.sort = poolAddress.length.mul(100);
        _poolInfo.amount = 0;
        _poolInfo.lastRewardBlock = 0;
        _poolInfo.inviteSelf = inviteSelfReward;
        _poolInfo.invite1Reward = invite1Reward;
        _poolInfo.invite2Reward = invite2Reward;
        _poolInfo.rewardPerBlock = rewardPerBlock;
        _poolInfo.totalPower = 0;
        _poolInfo.endBlock = 0;

        emit AddPool(msg.sender, pool, _lp, _rewardTotal);

        return pool;
    }

    function poolLength() override external view returns (uint256) {
        return poolAddress.length;
    }

    function deposit(address _pool, uint256 _amount) override external {
        PoolInfo storage pool = poolInfo[_pool];
        if ((address(0) != pool.lp) && (pool.startBlock <= block.number)) {
            IERC20(pool.lp).safeTransferFrom(msg.sender, address(this), _amount);
            UserInfo storage _userInfo = pledgeUserInfo[_pool][msg.sender];            
            _userInfo.amount = _userInfo.amount.add(_amount);
            pool.amount = pool.amount.add(_amount);
            if (0 == _userInfo.startBlock) {
                _userInfo.startBlock = block.number;
                pledgeAddresss[_pool].push(msg.sender);
            }
            this.computeReward(_pool);

            emit Deposit(_pool, pool.lp, msg.sender, address(this), _amount);
        }
    }

    function withdraw(address _pool, uint256 _amount) override external {
        PoolInfo storage pool = poolInfo[_pool];
        if (address(0) != pool.lp && (pool.startBlock <= block.number)) {
            this.computeReward(_pool);            
            UserInfo storage _userInfo = pledgeUserInfo[_pool][msg.sender];
            if (0 < _amount) {
                require(_amount <= _userInfo.amount, ErrorCode.BALANCE_INSUFFICIENT);            
                IERC20(pool.lp).safeTransfer(msg.sender, _amount);            
                _userInfo.amount = _userInfo.amount.sub(_amount);
                pool.amount = pool.amount.sub(_amount);
                emit Withdraw(_pool, pool.lp, address(this), msg.sender, _amount);
            }
            if (0 < _userInfo.pendingReward) {                
                you.mint(msg.sender, _userInfo.pendingReward);
                _userInfo.pendingReward = 0;
            }
        }
    }

    function withdrawRewad(address _pool) override external {
        PoolInfo storage pool = poolInfo[_pool];
        if (address(0) != pool.lp && (pool.startBlock <= block.number)) {
            this.computeReward(_pool);
            UserInfo storage _userInfo = pledgeUserInfo[_pool][msg.sender];
            if (0 < _userInfo.pendingReward) {
                you.mint(msg.sender, _userInfo.pendingReward);
                _userInfo.pendingReward = 0;
            }
        }
    }

    function poolPledgeAddresss(address _pool) override external view returns (address[] memory) {
        return pledgeAddresss[_pool];
    }

    function getPoolAddress() override external view returns (address[] memory) {
        return poolAddress;
    }

    function computeReward(address _pool) override external {
        PoolInfo storage _poolInfo = poolInfo[_pool];
        if ((_poolInfo.lastRewardBlock < block.number) && (_poolInfo.rewardProvide < _poolInfo.rewardTotal)) {
            address[] memory _addresss = pledgeAddresss[_pool];
            uint len = _addresss.length;
            if (0 < len) {
                uint256 rewardSingle = 0;
                _poolInfo.totalPower = 0;
                mapping(address => UserInfo) storage _pledgeUserInfo = pledgeUserInfo[_pool];            
                for (uint i = 0; i < len; i++) {
                    address _address = _addresss[i];
                    (address[] memory invite1, address[] memory invite2) = invite.inviteInfoV1(_address);
                    UserInfo storage _userInfo = _pledgeUserInfo[_address];
                    _userInfo.invitePower = _userInfo.amount.mul(_poolInfo.inviteSelf).div(100);
                    _userInfo.pledgePower = _userInfo.amount;
                    _poolInfo.totalPower = _poolInfo.totalPower.add(_userInfo.invitePower);
                    _poolInfo.totalPower = _poolInfo.totalPower.add(_userInfo.pledgePower);
                    if (0 < _poolInfo.invite1Reward) {
                        for (uint j = 0; j < invite1.length; j++) {
                            rewardSingle = _pledgeUserInfo[invite1[j]].amount.mul(_poolInfo.invite1Reward).div(100);
                            _userInfo.invitePower = _userInfo.invitePower.add(rewardSingle);
                            _poolInfo.totalPower = _poolInfo.totalPower.add(rewardSingle);
                        }
                    }
                    if (0 < _poolInfo.invite2Reward) {
                        for (uint j = 0; j < invite2.length; j++) {
                            rewardSingle = _pledgeUserInfo[invite2[j]].amount.mul(_poolInfo.invite2Reward).div(100);
                            _userInfo.invitePower = _userInfo.invitePower.add(rewardSingle);
                            _poolInfo.totalPower = _poolInfo.totalPower.add(rewardSingle);
                        }
                    }
                }
                if (0 < _poolInfo.totalPower) {
                    uint256 reward = (block.number - _poolInfo.lastRewardBlock).mul(_poolInfo.rewardPerBlock);
                    if (_poolInfo.lastRewardBlock < _poolInfo.startBlock) {
                        reward = (block.number - _poolInfo.startBlock + 1).mul(_poolInfo.rewardPerBlock);
                    }
                    if ((_poolInfo.rewardTotal.sub(_poolInfo.rewardProvide)) < reward) {
                        reward = _poolInfo.rewardTotal.sub(_poolInfo.rewardProvide);
                        _poolInfo.endBlock = block.number;
                    }
                    for (uint i = 0; i < len; i++) {
                        UserInfo storage _userInfo = pledgeUserInfo[_pool][_addresss[i]];
                        rewardSingle = _userInfo.pledgePower.mul(reward).div(_poolInfo.totalPower);
                        _userInfo.pledgeReward = _userInfo.pledgeReward.add(rewardSingle);
                        _userInfo.pendingReward = _userInfo.pendingReward.add(rewardSingle);
                        _poolInfo.rewardProvide = _poolInfo.rewardProvide.add(rewardSingle);

                        rewardSingle = _userInfo.invitePower.mul(reward).div(_poolInfo.totalPower);
                        _userInfo.inviteReward = _userInfo.inviteReward.add(rewardSingle);
                        _userInfo.pendingReward = _userInfo.pendingReward.add(rewardSingle);
                        _poolInfo.rewardProvide = _poolInfo.rewardProvide.add(rewardSingle);
                    }
                    _poolInfo.lastRewardBlock = block.number;
                }
            }
        }
    }

    function powerScale(address _pool, address _address) override external view returns (uint256) {
        PoolInfo memory pool = poolInfo[_pool];
        if (0 == pool.totalPower) {
            return 0;
        }

        UserInfo memory _userInfo = pledgeUserInfo[_pool][_address];
        return (_userInfo.invitePower.add(_userInfo.pledgePower).mul(1000)).div(pool.totalPower);
    }

    function setOperateOwner(address _address, bool _bool) override external {
        _setOperateOwner(_address, _bool);
    }
    
    function _setOperateOwner(address _address, bool _bool) internal {
        require(owner == msg.sender, ErrorCode.FORBIDDEN);
        operateOwner[_address] = _bool;
    }

    ////////////////////////////////////////////////////////////////////////////////////

    function setName(address _pool, string memory _name) override external {
        require(operateOwner[msg.sender], ErrorCode.FORBIDDEN);
        PoolInfo storage pool = poolInfo[_pool];
        if (address(0) != pool.lp) {
            poolName[_pool] = _name;
        }
    }

    function setInviteSelfReward(address _pool, uint256 _inviteSelf) override external {
        require(operateOwner[msg.sender], ErrorCode.FORBIDDEN);
        PoolInfo storage pool = poolInfo[_pool];
        if ((address(0) != pool.lp) && (0 == pool.endBlock)) {
            pool.inviteSelf = _inviteSelf;
        }
    }

    function setInvite1Reward(address _pool, uint256 _invite1Reward) override external {
        require(operateOwner[msg.sender], ErrorCode.FORBIDDEN);
        PoolInfo storage pool = poolInfo[_pool];
        if ((address(0) != pool.lp) && (0 == pool.endBlock)) {
            pool.invite1Reward = _invite1Reward;
        }
    }

    function setInvite2Reward(address _pool, uint256 _invite2Reward) override external {
        require(operateOwner[msg.sender], ErrorCode.FORBIDDEN);
        PoolInfo storage pool = poolInfo[_pool];
        if ((address(0) != pool.lp) && (0 == pool.endBlock)) {
            pool.invite2Reward = _invite2Reward;
        }
    }

   function setRewardPerBlock(address _pool, uint256 _rewardPerBlock) override external {
        require(operateOwner[msg.sender], ErrorCode.FORBIDDEN);
        PoolInfo storage pool = poolInfo[_pool];
        if ((address(0) != pool.lp) && (0 == pool.endBlock)) {
            pool.rewardPerBlock = _rewardPerBlock;
        }
    }

   function setRewardTotal(address _pool, uint256 _rewardTotal) override external {
        require(operateOwner[msg.sender], ErrorCode.FORBIDDEN);
        PoolInfo storage pool = poolInfo[_pool];
        if ((address(0) != pool.lp) && (0 == pool.endBlock)) {
            require(pool.rewardProvide < _rewardTotal, ErrorCode.REWARDTOTAL_LESS_THAN_REWARDPROVIDE);
            pool.rewardTotal = _rewardTotal;
        }
   }

   function setMultiple(address _pool, uint16 _multiple) override external {
        require(operateOwner[msg.sender], ErrorCode.FORBIDDEN);
        PoolInfo storage pool = poolInfo[_pool];
        if ((address(0) != pool.lp) && (0 == pool.endBlock)) {
            pool.multiple = _multiple;
        }
    }

    function setSort(address _pool, uint256 _sort) override external {
        require(operateOwner[msg.sender], ErrorCode.FORBIDDEN);
        PoolInfo storage pool = poolInfo[_pool];
        if (address(0) != pool.lp) {
            pool.sort = _sort;
        }
    }

    ////////////////////////////////////////////////////////////////////////////////////
    
    function blockNumber() override external view returns (uint256) {
        return block.number;
    }

    function erc20Allowance(address _token, address _owner, address _spender) override external view returns (uint256) {
        return IERC20(_token).allowance(_owner, _spender);
    }

    function erc20Balance(address _token, address _address) override external view returns (uint256) {
        return IERC20(_token).balanceOf(_address);
    }

    function erc20Supply(address _token) override external view returns (uint256) {
        return IERC20(_token).totalSupply();
    }

    ////////////////////////////////////////////////////////////////////////////////////

}