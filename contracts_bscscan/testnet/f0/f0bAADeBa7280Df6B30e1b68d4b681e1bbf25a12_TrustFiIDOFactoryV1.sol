// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import "./interface/ITrustFiIDOFactoryV1.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";


contract TrustFiIDOFactoryV1 is ITrustFiIDOFactoryV1 {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address internal constant ZERO = address(0);
    uint256 public poolCount = 0;

    mapping(uint256 => PoolStakeInfo) internal poolStakeInfos; //Ore pool pledge information，poolID->PoolStakeInfo
    mapping(uint256 => mapping(address => UserStakeInfo)) internal userStakeInfos; //User pledges information，poolID->user-UserStakeInfo

    Commission public supportCommission; // Commission collection

    address public admin; // Platform administrator
    mapping(address => bool) public operateOwner; // Operation permission
    mapping(address => bool) public financeOwner; // Financial permissions
    mapping(uint256 =>mapping(address => uint256)) public poolWhiteList; //Create a whitelist and create a pool for free
    mapping(uint256 => uint256 ) public poolWhiteListAmount;

    constructor(address _defaultPayToken) {
        admin = msg.sender;
        _setOperateOwner(admin, true);
        supportCommission.supportCommToken = _defaultPayToken;
        supportCommission.isSupported = true;
    }

     ////////////////////////////////////////////////////////////////////////////////////
     // Verify admin permission
    modifier onlyAdmin() {
        require(admin == msg.sender, "TrustFiStaking:FORBIDDEN_NOT_PLATFORM_ADMIN");
        _;
    }

    // Verify operation permissions
    modifier onlyOperater() {
        require(operateOwner[msg.sender], "TrustFiStaking:FORBIDDEN_NOT_OPERATER");
        _;
    }

    // Verify financial permissions
    modifier onlyFinanceOwner() {
        require(financeOwner[msg.sender], "TrustFiStaking:FORBIDDEN_NOT_FINANCE_OWNER");
        _;
    }

    // modify the owner
    function transferOwnership(address _admin) external onlyAdmin override{
        require(ZERO != _admin, "TrustFiStaking:INVALID_ADDRESSES");
        emit TransferOwnership(admin, _admin);
        admin = _admin;
    }

    function _setOperateOwner(address user, bool state) internal {
        operateOwner[user] = state; // Set the operation permission
        emit OperateOwnerEvent(user, state);
    }

    // Set the operation permission
    function setOperateOwner(address user, bool state) external onlyAdmin override{
        _setOperateOwner(user, state);
    }

    // Set financial permissions
    function setFinanceOwner(address user, bool state) external onlyAdmin override{
        financeOwner[user] = state;
        emit FinanceOwnerEvent(user, state);
    }



    /**
        @notice Sets the currency and quantity of payment
        @param _token Supports commission currencies
        @param _state Indicates the currency status
    */
    function setSupportCommToken(address _token,bool _state) external override onlyOperater{
        require(ZERO != _token, "INTBoxNFTFactory:INVALID_ADDRESS");
        supportCommission.supportCommToken = _token;
        supportCommission.isSupported = _state;
        emit CommissionEvent(_token, _state);
    }



    /** Obtain user pledge information */
    function getUserStakeInfo(uint256 poolId, address user) external view override returns (UserStakeInfo memory) {
        return userStakeInfos[poolId][user];
    }

    /** Obtain ore pool information */
    function getPoolStakeInfo(uint256 poolId) external view override returns (PoolStakeInfo memory) {
        return poolStakeInfos[poolId];
    }


    /** The pledge */
    function stake(uint256 poolId, uint256 amount) external  override {

        PoolStakeInfo storage poolStakeInfo = poolStakeInfos[poolId];
        UserStakeInfo storage userStakeInfo = userStakeInfos[poolId][msg.sender];

        require(poolStakeInfo.startTime > 0 && block.timestamp > poolStakeInfo.startTime,"TrustFiIDO:START_TIME_ERROR");
        require(poolStakeInfo.endTime > 0 && block.timestamp < poolStakeInfo.endTime,"TrustFiIDO:END_TIME_ERROR");
        require(amount <= poolWhiteList[poolId][msg.sender] && amount.add(userStakeInfo.amount) <= poolWhiteList[poolId][msg.sender],"TrustFiIDO:USER_STAKE_AMOUNT_ERROR");
        if(supportCommission.isSupported){
            require(IERC20(supportCommission.supportCommToken).balanceOf(msg.sender) > amount,"TrustFiIDO:USER_TOKEN_NOT_ENOUGH");
            IERC20(supportCommission.supportCommToken).safeTransferFrom(msg.sender, address(this), amount);
        }

        userStakeInfo.amount = amount.add(userStakeInfo.amount);
        userStakeInfo.lastStakeTime = block.timestamp;

        poolStakeInfo.amount = amount.add(poolStakeInfo.amount);

        emit Stake(poolId,msg.sender,amount,poolStakeInfo.IDOToken);
    }


    function getPoolUserStakeAmount(uint256 poolId,address user)  external view override returns (uint256 amount){
        UserStakeInfo storage userStakeInfo = userStakeInfos[poolId][msg.sender];
        uint256 whiteListAmount = poolWhiteList[poolId][user];
        amount = whiteListAmount.sub(userStakeInfo.amount);
    }



    /**
     */
    function addPool(uint256 startTime, uint256 endTime, address IDOToken) external override onlyOperater {
        uint256 _pool = poolCount;
        poolCount = poolCount.add(1);

        PoolStakeInfo storage poolStakeInfo = poolStakeInfos[_pool];
        poolStakeInfo.startTime = startTime; //startTime
        poolStakeInfo.endTime = endTime; //endTime
        poolStakeInfo.IDOToken = IDOToken; //IDO token

        emit AddPool(_pool,startTime,endTime,IDOToken);
    }

    function editPool(uint256 poolId,uint256 startTime,uint256 endTime,address IDOToken) external override onlyOperater {

        PoolStakeInfo storage poolStakeInfo = poolStakeInfos[poolId];
        poolStakeInfo.startTime = startTime; //startTime
        poolStakeInfo.endTime = endTime; //endTime
        poolStakeInfo.IDOToken = IDOToken; //IDO token

        emit EditPool(poolId,startTime,endTime,IDOToken);
    }


    function closePool(uint256 poolId) external override onlyOperater {
        PoolStakeInfo storage poolStakeInfo = poolStakeInfos[poolId];
        poolStakeInfo.endTime = block.timestamp; //End time of the ore pool

        emit ClosePool(poolId);
    }

    function addPoolWhiteList(uint256 poolId,address[] memory users,uint256[] memory amounts) external override onlyOperater{
        require(users.length == amounts.length,"TrustFiIDO:USER_AMOUNTS_LENGTH_ERROR");
        PoolStakeInfo memory poolStakeInfo = poolStakeInfos[poolId];
        require(poolStakeInfo.startTime >0,"TrustFiIDO:POOL_NOT_EXIST");
        uint256 allAmount = 0;
        for(uint256 i = 0;i< users.length;i++){
            poolWhiteList[poolId][users[i]] = amounts[i];
            allAmount = allAmount.add(amounts[i]);
        }
        poolWhiteListAmount[poolId] = allAmount;
    }

    function poolNumbers(address _IDOToken) override external view returns (uint256[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < poolCount; i++) {
            if (_IDOToken == poolStakeInfos[i].IDOToken) {
                count = count.add(1);
            }
        }

        uint256[] memory numbers = new uint256[](count);
        count = 0;
        for (uint256 i = 0; i < poolCount; i++) {
            if (_IDOToken == poolStakeInfos[i].IDOToken) {
                numbers[count] = i;
                count = count.add(1);
            }
        }

        return numbers;
    }

    /**
        @notice Receive specified token, specified amount of commission
        @param token token address
        @param _dst Address for receiving commissions
        @param amount Amount of commission received
    */
    function withdrawCommission(address token,address _dst,uint256 amount) external override onlyFinanceOwner {
        require(ZERO != _dst, "TrustFiIDO:INVALID_ADDRESS");

        uint256 b = IERC20(token).balanceOf(address(this));
        require(b >= amount, "TrustFiIDO:INVALID_TOKEN_AMOUNT");
        IERC20(token).safeTransfer(_dst, amount);

        emit withdrawCommissionEvent(_dst,amount);
    }


}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import './BaseStruct.sol';

////////////////////////////////// Mining Core contract //////////////////////////////////////////////////
interface ITrustFiIDOFactoryV1 is BaseStruct {


    ////////////////////////////////// event //////////////////////////////////////////////////
    /**
    add  pool
    poolId: pool id
    startTime: pool start time
    endTime: pool end time
    IDOToken: ido token
    */
    event AddPool(uint256 poolId,uint256 startTime, uint256 endTime,address IDOToken);

    /**
    Closed mine pool
    Factory: Indicates the factory contract
    */
    event ClosePool(uint256 poolId);


    /**
    edit  pool
    poolId: pool id
    startTime: pool start time
    endTime: pool end time
    IDOToken: ido token
    */
    event EditPool(uint256 poolId,uint256 startTime, uint256 endTime,address IDOToken);

    /**
        The pledge
        PoolId: indicates the ID of a pool
        User: user
        Amount: amount pledged
        IDOToken: IDOToken
     */
    event Stake(uint256 poolId, address user,uint256 amount,address IDOToken);

    event withdrawCommissionEvent(address indexed dst,uint256 amount);

        /**
    @notice Transfers owner rights
    @param oldOwner: oldOwner
    @param newOwner: newOwner
     */
    event TransferOwnership(address indexed oldOwner, address indexed newOwner);

    /**
    @notice Sets operation rights
    @param user: Business address
    @param state: Permission status
     */
    event OperateOwnerEvent(address indexed user, bool state);

    /// @notice Support currency, create pool commission, supported or not
    event CommissionEvent(address indexed token, bool state);

    /// @notice Sets the financial permission
    event FinanceOwnerEvent(address indexed user, bool state);



    ////////////////////////////////// functions //////////////////////////////////////////////////

    function transferOwnership(address _admin) external;
    function setOperateOwner(address user, bool state) external;
    function setFinanceOwner(address user, bool state) external;
    function setSupportCommToken(address _token,bool _state) external;
    function getUserStakeInfo(uint256 poolId, address user) external view  returns (UserStakeInfo memory);
    function getPoolStakeInfo(uint256 poolId) external view returns (PoolStakeInfo memory);
    function stake(uint256 poolId, uint256 amount) external;
    function getPoolUserStakeAmount(uint256 poolId,address user) external view returns (uint256 amount);
    function addPool(uint256 startTime, uint256 endTime, address IDOToken) external;
    function editPool(uint256 poolId,uint256 startTime,uint256 endTime,address IDOToken) external;
    function closePool(uint256 poolId) external;
    function addPoolWhiteList(uint256 poolId,address[] memory users,uint256[] memory amounts) external;
    function poolNumbers(address _IDOToken) external view returns (uint256[] memory);
    function withdrawCommission(address token,address _dst,uint256 amount) external;

}

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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

// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

interface BaseStruct {



    /** Ore pool pledge information */
    struct PoolStakeInfo {
        uint256 startTime; // IDO start time
        uint256 endTime; // IDO end time
        address IDOToken;//IDO token
        uint256 amount;
    }

    struct Commission { // Commission structure
        address supportCommToken; // pay token
        bool isSupported; // Supported or not
    }


    /** User pledges information */
    struct UserStakeInfo {
        uint256 amount; // Pledge quantity
        uint256 lastStakeTime; // The time of the last mortgage
    }

    struct WhiteListUserInfo {
        address user;
        uint256 amount;
    }
}