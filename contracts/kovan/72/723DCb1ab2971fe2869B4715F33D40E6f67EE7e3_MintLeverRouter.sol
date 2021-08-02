/**
 *Submitted for verification at Etherscan.io on 2021-08-02
*/

// File: localhost/mint/openzeppelin/contracts/utils/Strings.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
    
    function concat(string memory self, string memory other) internal pure returns (string memory) {
        bytes memory _self = bytes(self);
        bytes memory _other = bytes(other);
        string memory ret = new string(_self.length + _other.length);
        bytes memory bret = bytes(ret);
        uint k = 0;
        for (uint256 i = 0; i < _self.length; i++) {
            bret[k++] = _self[i];
        }
        for (uint256 i = 0; i < _other.length; i++) {
            bret[k++] = _other[i];
        }
        return string(ret);
    }
    
}

// File: localhost/mint/openzeppelin/contracts/utils/Address.sol

 

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

// File: localhost/mint/openzeppelin/contracts/math/SafeMath.sol

 

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
        require(c >= a, "PSafeMath: addition overflow");
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
        require(b <= a, "PSafeMath: subtraction overflow");
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
        require(c / a == b, "PSafeMath: multiplication overflow");
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
        require(b > 0, "PSafeMath: division by zero");
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
        require(b > 0, "PSafeMath: modulo by zero");
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

// File: localhost/mint/openzeppelin/contracts/token/ERC20/SafeERC20.sol

 

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
            "PSafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "PSafeERC20: decreased allowance below zero");
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

        bytes memory returndata = address(token).functionCall(data, "PSafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "PSafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: localhost/mint/interface/IEarning.sol

 

pragma solidity 0.7.4;

interface IEarning {
    
    event ClaimReward(address indexed token, uint256 amount);
    
    function init(address[] memory parameters) external;
    
    function setConfig(address _config) external;
    
    function getStakeToken() external view returns (address);

    function stake(address user, uint256 amount) external;

    function unStake(address user, uint256 amount) external returns (uint256);
    
    function pendingRewards(address user) external view returns (address[] memory, uint256[] memory);
    
    function claimRewardsV1(address user) external returns (address[] memory, uint256[] memory);

    function claimRewardsV2() external returns (address[] memory, uint256[] memory);

    function getRewardTokens() external view returns (address[] memory);
    
    function getLPTokens() external view returns (uint256, uint256, address[] memory, uint256[] memory);
    
    function getRewardTokenInfos() external view returns (address[] memory rewardTokens, uint256[] memory rewardPerBlocks);
}
// File: localhost/mint/interface/IMintLever.sol

 

pragma solidity 0.7.4;


interface IMintLever {
    
    event Pair(address indexed tokenA, address indexed tokenB);

    event Earning(address indexed earning);

    event Data(address indexed data);
    
    function init(uint256 id, address owner, address config) external;
    
    function addBond(address token, uint256 amount) external;

    function removeBond(address token, uint256 amount) external;
    
    function removeAllBond(uint256 deadLine) external;

    function repayFromWallet(address token, uint256 amount, uint256 deadLine) external;

    function repayFromBond(address token, uint256 amount, uint256 deadLine) external;
    
    //
    
    function openPosition(uint256 amountA, uint256 amountB, uint256 leverage, address borrowToken, uint256 deadLine) external;
    
    function closePosition(uint256 percentage, address receiveToken,uint256 deadLine) external;
    
    function directClearingPosition(address user, uint256 deadLine) external;

    function indirectClearingPosition(address user, address token, uint256 amount) external;
    
}
// File: localhost/mint/interface/IOperateType.sol

 

pragma solidity 0.7.4;

interface IOperateType {
    
    enum PositionOperateType {
        None,//0
        Open,//1:开仓
        Add,//2:加仓
        Close,//3:平仓
        AddBond,//4:添加保证金
        RemoveBond,//5:减少保证金
        RemoveAllBond,//6:一键移除保证金
        RepayFromWallet,// 7:从钱包还款
        RepayFromBond,//8:从保证金还款
        DirectClearing,//9:直接清算
        IndirectClearing//10:偿还清算
    }
    
    enum MathOperateType {
        Add,//0
        Sub//1
    }
    
}
// File: localhost/mint/interface/IMintLeverData.sol

 

pragma solidity 0.7.4;

pragma experimental ABIEncoderV2;


interface IMintLeverData {
    
    struct UserInfo {
        uint256 id;
        address tokenA;
        address tokenB;
        address capital;
        uint256 capitalAmount;
        address borrowToken;
        uint256 borrowAmount;
    }
    
    function init(uint256 _id) external;
    
    function setToken(address _tokenA, address _tokenB, address _capital) external;
    
    function setConfig(address _config) external;
    
    function getId() external view returns (uint256);

    function getTokenA() external view returns (address);
    
    function getTokenB() external view returns (address);
    
    function addTokenAmount(address user, uint256 amountA, uint256 amountB) external returns (uint256, uint256);
    
    function getTokenAmount(address user) external view returns (uint256, uint256);
    
    function getCapital() external view returns (address);
    
    function getCapitalAmount(address user) external view returns (uint256);
    
    function updateCapitalAmount(address user, uint256 amount, IOperateType.MathOperateType operateType) external returns (uint256);
    
    function getBondsCount(address user) external view returns (uint256);
    
    function getBondToken(address user) external view returns (address[] memory);
    
    function getBondTokenAmount(address user, address token) external view returns (uint256);

    function getBondPTokenAmount(address user, address token) external view returns (uint256);

    function claimBondPTokenAmount(address user, address to , address token, uint256 amount) external;

    function claimAllBondPToken(address user, address to) external returns (address[] memory, uint256[] memory);
    
    function updatePTokenAmount(address user, address token, uint256 amount, IOperateType.MathOperateType operateType) external returns (uint256);
        
    function getBorrowToken(address user) external view returns (address);
    
    function getBorrowAmountV1(address user) external view returns (uint256);

    function getBorrowAmountV2(address user) external returns (uint256);
    
    function getUserInfo(address user) external returns (UserInfo memory);
    
    function initPosition(address user, address borrowToken) external returns (IOperateType.PositionOperateType);
    
    function sendPosition(address user, IOperateType.PositionOperateType operateType) external;
    
    function addBond(address user, address token, uint256 amount) external;
    
    function removeBond(address user, address token, uint256 amount) external;
    
    function removeAllBond(address user, uint256 deadLine) external;

    function removeAllBondRepay(address user, uint256 deadLine) external;
    
    function repayFromWallet(address user, address token, uint256 amount, uint256 deadLine) external;
    
    function repayFromBond(address user, address token, uint256 amount, uint256 deadLine) external;
    
    
    
    
}
// File: localhost/mint/implement/ParameterCheck.sol

 

pragma solidity 0.7.4;

abstract contract ParameterCheck {
    
    modifier nonZeroAddress(address _address) {
        require(address(0) != _address, "publics:parameter_is_zero_address");
        _;
    }
    
    modifier nonZeroAmount(uint256 amount) {
        require(0 < amount, "publics:parameter_is_zero");
        _;
    }
    
}
// File: localhost/mint/implement/Owner.sol

 

pragma solidity 0.7.4;


abstract contract Owner is ParameterCheck {
    
    event TransferOwnership(address indexed oldOwner, address indexed newOwner);
    
    address public owner;

    modifier onlyOwner() {
        require(owner == msg.sender, "publics:not_owner");
        _;
    }
    
    function transferOwnership(address _owner) public onlyOwner nonZeroAddress(_owner) {
        owner = _owner;
        emit TransferOwnership(owner, _owner);
    }
    
}
// File: localhost/mint/implement/Lock.sol

 

pragma solidity 0.7.4;

abstract contract Lock {
    
    bool private locked = false;
    
    modifier lock() {
        require(!locked, "publics:locked");
        locked = true;
        _;
        locked = false;
    }
    
}
// File: localhost/mint/implement/MintLever.sol

 

pragma solidity 0.7.4;









abstract contract MintLever is IMintLever, Lock, Owner {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    IConfig public config;
    IMintLeverData public data;
    address public earning;
    
    function init(uint256 _id, address _owner, address _config) override external nonZeroAddress(_owner) {
        require(address(0) == owner, "publics:contract_is_already_initialized");
        owner = msg.sender;
        data = IMintLeverData(IConfig(_config).getMintLeverFactory().cloneNormal(IConfig(_config).getMintDataTemplate()));
        data.init(_id);
        setConfig(_config);
        transferOwnership(_owner);
    }
    
    function setConfig(address _config) public onlyOwner nonZeroAddress(_config) {
        config = IConfig(_config);
        data.setConfig(_config);
        if (address(0) != earning) {
            IEarning(earning).setConfig(_config);
        }
    }

    function addBond(address token, uint256 amount) override external lock {
        data.addBond(msg.sender, token, amount);
    }

    function removeBond(address token, uint256 amount) override external lock {
        data.removeBond(msg.sender, token, amount);
    }
    
    function removeAllBond(uint256 deadLine) override external lock {
        data.removeAllBond(msg.sender, deadLine);
    }
    
    function repayFromWallet(address token, uint256 amount, uint256 deadLine) override external lock {
        data.repayFromWallet(msg.sender, token, amount, deadLine);
    }
    
    function repayFromBond(address token, uint256 amount, uint256 deadLine) override external lock {
        data.repayFromBond(msg.sender, token, amount, deadLine);
    }
    
    function _swap(address from, address to, uint256 amount, uint256 deadLine) internal returns (uint256) {
        if (from == to || 0 == amount) {
            return amount;
        }
        IExchange _exchange = config.getExchange();
        IERC20(from).approve(address(_exchange), amount);
        amount = _exchange.swapExtractOut(from, to, address(this), amount, 1, deadLine);
        return amount;
    }
    
    function _redeem(address token, uint256 amount) internal returns (uint256) {
        if (0 < amount) {
            uint256 _code;
            (_code, amount, ) = config.getLoanPublics(token).redeem(amount);
            if (0 != _code) {
               revert(Strings.concat("publics:mint_lever_loan_redeem_error_code:", Strings.toString(_code)));
            }
        }
        return amount;
    }
    
    function _repay(address user, uint256 amount) internal returns (uint256, uint256) {//剩余数量，还款数量
        address _borrowToken = data.getBorrowToken(user);
        if (0 == amount || address(0) == _borrowToken) {
            return (amount, 0);
        }
        ILoanPublics _borrowLoanPublics = config.getLoanPublics(_borrowToken);
        IERC20(_borrowToken).approve(address(_borrowLoanPublics), amount);
        (uint256 _code, uint256 _amount) = _borrowLoanPublics.doCreditLoanRepay(user, amount, data.getId(), ILoanTypeBase.LoanType.MINNING_SWAP_PROTOCOL);
        if (0 != _code) {
            revert(Strings.concat("publics:mint_lever_loan_repay_error_code:", Strings.toString(_code)));
        }
        return (amount.sub(_amount), _amount);
    }
    
    function _safeTransfer(address token, address to, uint256 amount) internal {
        if (0 == amount) {
            return;
        }
        IERC20(token).safeTransfer(to, amount);
    }
    
    function _getLoadPublicsRate(address user, address token) internal view returns (uint256) {
        (uint256 _code, , , uint256 _rate) = config.getLoanPublics(token).getAccountSnapshot(user, data.getId(), ILoanTypeBase.LoanType.MINNING_SWAP_PROTOCOL);
        if (0 != _code) {
            revert(Strings.concat("publics:mint_lever_loan_get_account_snapshot_error_code:", Strings.toString(_code)));
        }
        return _rate;
    }
    
}
// File: localhost/mint/openzeppelin/contracts/utils/Context.sol

 

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: localhost/mint/openzeppelin/contracts/access/Ownable.sol

 

pragma solidity >=0.6.0 <0.8.0;

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
    //constructor () internal {
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
    // function renounceOwnership() public virtual onlyOwner {
    //     emit OwnershipTransferred(_owner, address(0));
    //     _owner = address(0);
    // }

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

// File: localhost/mint/tripartitePlatform/publics/ILoanTypeBase.sol

 

pragma solidity 0.7.4;

interface ILoanTypeBase {
    
    enum LoanType {
        NORMAL,
        MARGIN_SWAP_PROTOCOL,
        MINNING_SWAP_PROTOCOL
    }
    
}
// File: localhost/mint/tripartitePlatform/publics/ILoanPublics.sol

 

pragma solidity 0.7.4;


interface ILoanPublics {

    /**
     *@notice 获取依赖资产地址
     *@return (address): 地址
     */
    // function underlying() external view returns (address);

    /**
     *@notice 真实借款数量（本息)
     *@param _account:实际借款人地址
     *@param _loanType:借款类型
     *@return (uint256): 错误码(0表示正确)
     */
    function borrowBalanceCurrent(address _account, uint256 id, ILoanTypeBase.LoanType _loanType) external returns (uint256);

    /**
     *@notice 用户存款
     *@param _mintAmount: 存入金额
     *@return (uint256, uint256): 错误码(0表示正确), 获取pToken数量
     */
    function mint(uint256 _mintAmount) external returns (uint256, uint256);

    /**
     *@notice 用户指定pToken取款
     *@param _redeemTokens: pToken数量
     *@return (uint256, uint256): 错误码(0表示正确), 获取Token数量，对应pToken数量
     */
    function redeem(uint256 _redeemTokens) external returns (uint256, uint256, uint256);

    /**
     *@notice 用户指定Token取款
     *@param _redeemAmount: Token数量
     *@return (uint256, uint256, uint256): 错误码(0表示正确), 获取Token数量，对应pToken数量
     */
    function redeemUnderlying(uint256 _redeemAmount) external returns (uint256, uint256, uint256);

    /**
     *@notice 获取用户的资产快照信息
     *@param _account: 用户地址
     *@param _id: 仓位id
     *@param _loanType: 借款类型
     *@return (uint256, uint256, uint256, uint256): 错误码(0表示正确), pToken数量, 借款(快照)数量, 兑换率
     */
    function getAccountSnapshot(address _account, uint256 _id, ILoanTypeBase.LoanType _loanType) external view returns (uint256, uint256, uint256, uint256);

    /**
     *@notice 信用贷借款
     *@param _borrower:实际借款人的地址
     *@param _borrowAmount:实际借款数量
     *@param _id: 仓位id
     *@param _loanType:借款类型
     *@return (uint256): 错误码
     */
    function doCreditLoanBorrow(address _borrower, uint256 _borrowAmount, uint256 _id, ILoanTypeBase.LoanType _loanType) external returns (uint256);

    /**
     *@notice 信用贷还款
     *@param _payer:实际还款人的地址
     *@param _repayAmount:实际还款数量
     *@param _id: 仓位id
     *@param _loanType:借款类型
     *@return (uint256, uint256): 错误码, 实际还款数量
     */
    function doCreditLoanRepay(address _payer, uint256 _repayAmount, uint256 _id, ILoanTypeBase.LoanType _loanType) external returns (uint256, uint256);

}

// File: localhost/mint/openzeppelin/contracts/token/ERC20/IERC20.sol

 

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
    自行加入
     */
    function decimals() external view returns (uint8);

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

// File: localhost/mint/tripartitePlatform/publics/IPublics.sol

 

pragma solidity 0.7.4;


interface IPublics is IERC20 {

    function claimComp(address holder) external returns (uint256);
    
}
// File: localhost/mint/interface/IMintLeverFactory.sol

 

pragma solidity 0.7.4;

interface IMintLeverFactory {
    
    function cloneNormal(address template) external returns (address);
    
}
// File: localhost/mint/interface/IAssetPrice.sol

 

pragma solidity 0.7.4;

/**
资产价格
 */
interface IAssetPrice {
    
    /**
    查询资产价格
    
    quote:报价资产合约地址
    base:计价资产合约地址

    code:1
    price:价格
    decimal:精度
     */
    function getPriceV1(address quote, address base) external view returns (uint8, uint256, uint8);
    
    /**
    查询资产价格
    
    quote:报价资产合约地址
    base:计价资产合约地址
    decimal:精度
    
    code:1
    price:价格
     */
    function getPriceV2(address quote, address base, uint8 decimal) external view returns (uint8, uint256);

    /**
    查询资产对USD价格
    
    token:报价资产合约地址
    
    code:1
    price:价格
    decimal:精度
     */
    function getPriceUSDV1(address token) external view returns (uint8, uint256, uint8);
    
    /**
    查询资产对USD价格
    
    token:报价资产合约地址
    decimal:精度
    
    code:1
    price:价格
     */
    function getPriceUSDV2(address token, uint8 decimal) external view returns (uint8, uint256);

    /**
    查询资产价值

    token:报价资产合约地址
    amount:数量
    
    code:1
    usd:USD
    decimal:精度
     */
    function getUSDV1(address token, uint256 amount) external view returns (uint8, uint256, uint8);
    
    /**
    查询资产价值

    token:报价资产合约地址
    amount:数量
    decimal:精度

    code:1
    usd:USD
     */
    function getUSDV2(address token, uint256 amount, uint8 decimal) external view returns (uint8, uint256);
    
}
// File: localhost/mint/interface/IExchange.sol

 

pragma solidity 0.7.4;

interface IExchange {
    
    function swapExtractOut(address tokenIn, address tokenOut, address recipient, uint256 amountIn, uint256 amountOutMin, uint256 deadline) external returns (uint256);
    
    function swapEstimateOut(address tokenIn, address tokenOut, uint256 amountIn) external view returns (uint256);

}
// File: localhost/mint/interface/IMintLeverRouter.sol

 

pragma solidity 0.7.4;

interface IMintLeverRouter {
    
    function canClearing(address mintLever, address user) external view returns (bool);
    
    function getBondUSD(address mintLever, address user, uint8 decimal) external view returns (uint256);
    
    function getDebtUSD(address mintLever, address user, uint8 decimal) external view returns (uint256);
    
    function getBond(address mintLever, address user) external view returns (address[] memory, uint256[] memory);

    function getCapitalUSD(address mintLever, address user, uint8 decimal) external view returns (uint256);

}
// File: localhost/mint/interface/IBorrowProxy.sol

 

pragma solidity 0.7.4;

interface IBorrowProxy {
    
    function setBorrowAccess(address spender, bool state) external;
    
    function borrowV1(address owner, uint256 id, address tokenA, uint256 amountA, address tokenB, uint256 amountB, address borrowToken, uint256 leverage, uint256 deadLine) external returns(uint256, uint256, uint256);

    function borrowV2(address owner, uint256 id, address tokenA, uint256 amountA, address borrowToken, uint256 leverage, uint256 deadLine) external returns (uint256, uint256);

}
// File: localhost/mint/interface/IApproveProxy.sol

 

pragma solidity 0.7.4;

interface IApproveProxy {
    
    function setClaimAccess(address spender, bool state) external;
    
    function claim(address token, address owner, address spender, uint256 amount) external;
        
}
// File: localhost/mint/interface/IConfig.sol

 

pragma solidity 0.7.4;










interface IConfig {
    
    function getOracleDecimal(address quote, address base) external view returns (uint8, uint8);
    
    function getOracleSources(address quote, address base) external view returns (uint8, address[] memory, uint8[] memory, address[] memory);
    
    function getApproveProxy() external view returns (IApproveProxy);
    
    function getBorrowProxy() external view returns (IBorrowProxy);
    
    function getMintRouter() external view returns (IMintLeverRouter);

    function getAssetPrice() external view returns (IAssetPrice);
    
    function getMintDataTemplate() external view returns (address);
    
    function getMintLeverFactory() external view returns (IMintLeverFactory);
    
    function getLoanPublics(address token) external view returns (ILoanPublics);

    function tryGetLoanPublics(address token) external view returns (ILoanPublics);
    
    function isBond(address token) external view returns (bool);

    function isLoan(address token) external view returns (bool);
    
    function getUsdt() external view returns (address);
    
    function getExchange() external view returns (IExchange);

    function getPublics() external view returns (IPublics);
    
    function getPlatformFee() external view returns (address);
    
    function isBlacklist(address user) external view returns (bool);
    
    function isOpen(address mintLever) external view returns (bool);
    
    function isDirectClearing(address mintLever) external view returns (bool);

    function getLeverage(address mintLever) external view returns (uint256, uint256);

    function isLeverage(address mintLever, uint256 leverage) external view returns (bool);
    
    function getPlatformTakeRate(address mintLever) external view returns (uint256);
    
    function getClearingEarningRate(address mintLever) external view returns (uint256);
    
    function getClearingPlatformEarningRate(address mintLever) external view returns (uint256);
    
    function getMaxRiskRate(address mintLever) external view returns (uint256);
    
    function getExtendV1(address key) external view returns (address);

    function getExtendV2(uint256 key) external view returns (address);

    function getExtendV3(address key) external view returns (uint256);

}
// File: localhost/mint/implement/ConfigBase.sol

 

pragma solidity 0.7.4;



abstract contract ConfigBase is Ownable {
    
    event Config_(address indexed config);
    
    IConfig public config;
    
    constructor (IConfig _config) {
        require(address(0) != address(_config), "publics:config_is_zero");
        config = _config;
        emit Config_(address(_config));
    }
    
    function setConfig(IConfig _config) external onlyOwner {
        require(address(0) != address(_config), "publics:config_is_zero");
        config = _config;
        emit Config_(address(_config));
    }
    
}
// File: localhost/mint/implement/MintLeverRouter.sol

 

pragma solidity 0.7.4;






contract MintLeverRouter is IMintLeverRouter, ConfigBase, ParameterCheck {
    
    using SafeMath for uint256;
    
    constructor (IConfig _config) ConfigBase(_config) {
    }
    
    function canClearing(address mintLever, address user) override external nonZeroAddress(mintLever) nonZeroAddress(user) view returns (bool) {
        return this.getMaxRiskRate(mintLever) >= this.getRiskRate(mintLever, user);
    }
    
    function getBondUSD(address mintLever, address user, uint8 decimal) override external nonZeroAddress(mintLever) nonZeroAddress(user) view returns (uint256) {
        uint256 _usd;
        uint256 __usd;
        (address[] memory _tokens, uint256[] memory _amounts) = this.getBond(mintLever, user);
        for (uint256 i = 0; i < _tokens.length; i++) {
            if (0 < _amounts[i]) {
                (, __usd) = config.getAssetPrice().getUSDV2(_tokens[i], _amounts[i], decimal);
                _usd = _usd.add(__usd);
            }
        }
        return _usd;
    }

    function getDebtUSD(address mintLever, address user, uint8 decimal) override external nonZeroAddress(mintLever) nonZeroAddress(user) view returns (uint256) {
        (address _token, uint256 _amount) = this.getDebt(mintLever, user);
        if (0 == _amount) {
            return 0;
        }
        (, uint256 _usd) = config.getAssetPrice().getUSDV2(_token, _amount, decimal);
        return _usd;
    }
    
    function getBond(address mintLever, address user) override external nonZeroAddress(mintLever) nonZeroAddress(user) view returns (address[] memory, uint256[] memory) {
        IMintLeverData _data = MintLever(mintLever).data();
        address[] memory _tokens = _data.getBondToken(user);
        uint256[] memory _amounts = new uint256[](_tokens.length);
        for (uint256 i = 0; i < _tokens.length; i++) {
            _amounts[i] = _data.getBondTokenAmount(user, _tokens[i]);
        }
        return (_tokens, _amounts);
    }
    
    function getPair(address mintLever) external nonZeroAddress(mintLever) view returns (address, address) {
        IMintLeverData _data = MintLever(mintLever).data();
        return (_data.getTokenA(), _data.getTokenB());
    }
    
    function getDebt(address mintLever, address user) external nonZeroAddress(mintLever) nonZeroAddress(user) view returns (address, uint256) {
        IMintLeverData _data = MintLever(mintLever).data();
        return (_data.getBorrowToken(user), _data.getBorrowAmountV1(user));
    }
    
    function getEarning(address mintLever, address user) external nonZeroAddress(mintLever) nonZeroAddress(user) view returns (address[] memory, uint256[] memory) {
        return IEarning(MintLever(mintLever).earning()).pendingRewards(user);
    }
    
    function getStake(address mintLever, address user) external nonZeroAddress(mintLever) nonZeroAddress(user) view returns (address, uint256) {
        IMintLeverData _data = MintLever(mintLever).data();
        return (_data.getCapital(), _data.getCapitalAmount(user));
    }
    
    function getRiskRate(address mintLever, address user) external nonZeroAddress(mintLever) nonZeroAddress(user) view returns (uint256) {
        uint256 debtUSD = this.getDebtUSD(mintLever, user, 14);
        if (0 == debtUSD) {
            return ~uint256(0);
        }
        uint256 bondUSD = this.getCapitalUSD(mintLever, user, 18);
        bondUSD = bondUSD.add(this.getBondUSD(mintLever, user, 18));
        return bondUSD.div(debtUSD);
    }
    
    function getLeverage(address mintLever) external nonZeroAddress(mintLever) view returns (uint256, uint256) {
        return config.getLeverage(mintLever);
    }
    
    function getPlatformTakeRate(address mintLever) external nonZeroAddress(mintLever) view returns (uint256) {
        return config.getPlatformTakeRate(mintLever);
    }
    
    function getClearingEarningRate(address mintLever) external nonZeroAddress(mintLever) view returns (uint256) {
        return config.getClearingEarningRate(mintLever);
    }
    
    function getClearingPlatformEarningRate(address mintLever) external nonZeroAddress(mintLever) view returns (uint256) {
        return config.getClearingPlatformEarningRate(mintLever);
    }
    
    function getMaxRiskRate(address mintLever) external nonZeroAddress(mintLever) view returns (uint256) {
        return config.getMaxRiskRate(mintLever);
    }

    function getTVL(address mintLever, uint8 decimal) external nonZeroAddress(mintLever) view returns (uint256) {
        (uint256 _totalAmount, uint256 _stakeAmount, address[] memory _tokens, uint256[] memory _amounts) = IEarning(MintLever(mintLever).earning()).getLPTokens();
        if (0 == _totalAmount || 0 == _stakeAmount) {
            return 0;
        }
        uint256 _usd;
        uint256 __usd;
        for (uint256 i = 0; i < _tokens.length; i++) {
            (, __usd) = config.getAssetPrice().getUSDV2(_tokens[i], _amounts[i], decimal);
            _usd = _usd.add(__usd);
        }
        return _usd.mul(_stakeAmount).div(_totalAmount);
    }
    
    function getCapitalUSD(address mintLever, address user, uint8 decimal) override external nonZeroAddress(mintLever) nonZeroAddress(user) view returns (uint256) {
        uint256 _usd;
        uint256 __usd;
        MintLever _mintLever = MintLever(mintLever);
        (uint256 _totalAmount, , address[] memory _tokens, uint256[] memory _amounts) = IEarning(_mintLever.earning()).getLPTokens();
        if (0 == _totalAmount) {
            return 0;
        }
        for (uint256 i = 0; i < _tokens.length; i++) {
            (, __usd) = config.getAssetPrice().getUSDV2(_tokens[i], _amounts[i], decimal);
            _usd = _usd.add(__usd);
        }
        return _usd.mul(_mintLever.data().getCapitalAmount(user)).div(_totalAmount);
    }
    
    function getTokenAmountClosePosition(address mintLever, address user, uint256 percentage, address receiveToken) external nonZeroAddress(mintLever) nonZeroAddress(user) view returns (address[] memory, uint256[] memory) {
        require(0 < percentage && percentage <= 100, "publics:percentage_overflow");
        MintLever _mintLever = MintLever(mintLever);
        IMintLeverData _data = _mintLever.data();
        uint256 _amount = _data.getCapitalAmount(user).mul(percentage).div(100);
        (uint256 _totalAmount, , address[] memory _tokens, uint256[] memory _amounts) = IEarning(_mintLever.earning()).getLPTokens();
        for (uint256 i = 0; i < _amounts.length; i++) {
            _amounts[i] = _amount.mul(_amounts[i]).div(_totalAmount);
        }
        return _getTokenAmountClosePosition(mintLever, user, percentage, receiveToken, _tokens, _amounts);
    }
    
    function _getTokenAmountClosePosition(address mintLever, address user, uint256 percentage, address receiveToken, address[] memory tokens, uint256[] memory amounts) internal view returns (address[] memory, uint256[] memory) {
        IMintLeverData _data = MintLever(mintLever).data();
        if (0 < _data.getBorrowAmountV1(user)) {
            uint256 _repayAmount;
            uint256 __repayAmount;
            for (uint256 i = 0; i < amounts.length; i++) {
                __repayAmount = amounts[i].sub(amounts[i].mul(100 - percentage).div(100));
                amounts[i] = amounts[i].sub(__repayAmount);
                _repayAmount = _repayAmount.add(_swapEstimateOut(tokens[i], _data.getBorrowToken(user), __repayAmount));
            }
            if (_data.getBorrowAmountV1(user) < _repayAmount) {
                _repayAmount = _repayAmount.sub(_data.getBorrowAmountV1(user));
                for (uint256 i = 0; i < tokens.length; i++) {
                    amounts[i] = amounts[i].add(_swapEstimateOut(_data.getBorrowToken(user), tokens[i], _repayAmount.div(tokens.length)));
                }
            }
        }
        if (address(0) != receiveToken) {
            uint256 _amount;
            for (uint256 i = 0; i < tokens.length; i++) {
                _amount = _amount.add(_swapEstimateOut(tokens[i], receiveToken, amounts[i]));
            }
            tokens = new address[](1);
            amounts = new uint256[](1);
            tokens[0] = receiveToken;
            amounts[0] = _amount;
        }
        return (tokens, amounts);
    }
    
    function getTokenAmount(address mintLever, address user) external nonZeroAddress(mintLever) nonZeroAddress(user) view returns (address[] memory, uint256[] memory) {
        IMintLeverData _data = MintLever(mintLever).data();
        uint256 _amount = _data.getCapitalAmount(user);
        (uint256 _totalAmount, , address[] memory _tokens, uint256[] memory _amounts) = IEarning(MintLever(mintLever).earning()).getLPTokens();
        for (uint256 i = 0; i < _tokens.length; i++) {
            _amounts[i] = _amount.mul(_amounts[i]).div(_totalAmount);
        }
        return (_tokens, _amounts);
    }
    
    function getAPRs(address[] memory mintLevers, uint8 decimal) external view returns (uint256[] memory) {
        uint256[] memory _aprs = new uint256[](mintLevers.length);
        for (uint256 i = 0; i < mintLevers.length; i++) {
            _aprs[i] = _getAPRInternal(mintLevers[i], decimal);
        }
        return _aprs;
    }
    
    function _getLoadPublicsRate(address user, address token, uint256 id) internal view returns (uint256) {
        (uint256 _code, , , uint256 _rate) = config.getLoanPublics(token).getAccountSnapshot(user, id, ILoanTypeBase.LoanType.MINNING_SWAP_PROTOCOL);
        if (0 != _code) {
            revert(Strings.concat("publics:mint_lever_data_loan_get_account_snapshot_error_code:", Strings.toString(_code)));
        }
        return _rate;
    }

    function _getAPRInternal(address mintLever_, uint8 decimal) internal nonZeroAddress(mintLever_) view returns (uint256) {
        IEarning _earning = IEarning(MintLever(mintLever_).earning());
        (address[] memory _tokens, uint256[] memory _rewardPerBlocks) = _earning.getRewardTokenInfos();
        uint256 _result = 0;
        uint256 _temp = 0;
        uint256 _price = 0;
        for (uint i = 0; i < _tokens.length; i++) {
            (, _price) = config.getAssetPrice().getPriceUSDV2(_tokens[i], decimal);
            _temp = _rewardPerBlocks[i].mul(_price).mul(2102400);
            _result = _result.add(_temp);
        }
        
        uint256 _tvl = this.getTVL(mintLever_, decimal);
        _result = _result.div(_tvl);
        return _result;
    }
    
    function _swapEstimateOut(address from, address to, uint256 amount) internal view returns (uint256) {
        if (from == to || 0 == amount) {
            return amount;
        }
        return config.getExchange().swapEstimateOut(from, to, amount);
    }
    
}