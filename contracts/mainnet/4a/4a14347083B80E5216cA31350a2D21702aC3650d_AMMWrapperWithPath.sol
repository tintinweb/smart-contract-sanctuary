// SPDX-License-Identifier: MIT

pragma solidity ^0.6.5;

import "@openzeppelin/contracts/utils/Address.sol";
import "./interfaces/IAllowanceTarget.sol";

/**
 * @dev AllowanceTarget contract
 */
contract AllowanceTarget is IAllowanceTarget {
    using Address for address;

    uint256 constant private TIME_LOCK_DURATION = 1 days;

    address public spender;
    address public newSpender;
    uint256 public timelockExpirationTime;

    modifier onlySpender() {
        require(spender == msg.sender, "AllowanceTarget: not the spender");
        _;
    }


    constructor(address _spender) public {
        require(_spender != address(0), "AllowanceTarget: _spender should not be 0");

        // Set spender
        spender = _spender;
    }


    function setSpenderWithTimelock(address _newSpender) override external onlySpender {
        require(_newSpender.isContract(), "AllowanceTarget: new spender not a contract");
        require(newSpender == address(0) && timelockExpirationTime == 0, "AllowanceTarget: SetSpender in progress");

        timelockExpirationTime = now + TIME_LOCK_DURATION;
        newSpender = _newSpender;
    }

    function completeSetSpender() override external {
        require(timelockExpirationTime != 0, "AllowanceTarget: no pending SetSpender");
        require(now >= timelockExpirationTime, "AllowanceTarget: time lock not expired yet");

        // Set new spender
        spender = newSpender;
        // Reset
        timelockExpirationTime = 0;
        newSpender = address(0);
    }


    function teardown() override external onlySpender {
        selfdestruct(payable(spender));
    }


    /// @dev Execute an arbitrary call. Only an authority can call this.
    /// @param target The call target.
    /// @param callData The call data.
    /// @return resultData The data returned by the call.
    function executeCall(
        address payable target,
        bytes calldata callData
    )
        override
        external
        onlySpender
        returns (bytes memory resultData)
    {
        bool success;
        (success, resultData) = target.call(callData);
        if (!success) {
            // Get the error message returned
            assembly {
                let ptr := mload(0x40)
                let size := returndatasize()
                returndatacopy(ptr, 0, size)
                revert(ptr, size)
            }
        }
    }
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

pragma solidity ^0.6.0;

interface IAllowanceTarget {
    function setSpenderWithTimelock(address _newSpender) external;
    function completeSetSpender() external;
    function executeCall(address payable _target, bytes calldata _callData) external returns (bytes memory resultData);
    function teardown() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.5;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IAllowanceTarget.sol";

/**
 * @dev Spender contract
 */
contract Spender {
    using SafeMath for uint256;

    // Constants do not have storage slot.
    address private constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address private constant ZERO_ADDRESS = address(0);
    uint256 constant private TIME_LOCK_DURATION = 1 days;

    // Below are the variables which consume storage slots.
    address public operator;
    address public pendingOperator;
    address public allowanceTarget;
    mapping(address => bool) private authorized;
    mapping(address => bool) private tokenBlacklist;
    uint256 public numPendingAuthorized;
    mapping(uint256 => address) public pendingAuthorized;
    uint256 public timelockExpirationTime;
    uint256 public contractDeployedTime;
    bool public timelockActivated;
    mapping(address => bool) public consumeGasERC20Tokens;

    // System events
    event TimeLockActivated(uint256 activatedTimeStamp);
    // Operator events
    event TransferOwnership(address newOperator);
    event SetAllowanceTarget(address allowanceTarget);
    event SetNewSpender(address newSpender);
    event SetConsumeGasERC20Token(address token);
    event TearDownAllowanceTarget(uint256 tearDownTimeStamp);
    event BlackListToken(address token, bool isBlacklisted);
    event AuthorizeSpender(address spender, bool isAuthorized);


    /************************************************************
    *          Access control and ownership management          *
    *************************************************************/
    modifier onlyOperator() {
        require(operator == msg.sender, "Spender: not the operator");
        _;
    }

    modifier onlyAuthorized() {
        require(authorized[msg.sender], "Spender: not authorized");
        _;
    }

    function setNewOperator(address _newOperator) external onlyOperator {
        require(_newOperator != address(0), "Spender: operator can not be zero address");
        pendingOperator = _newOperator;
    }

    function acceptAsOperator() external {
        require(pendingOperator == msg.sender, "Spender: only nominated one can accept as new operator");
        operator = pendingOperator;
        pendingOperator = address(0);
        emit TransferOwnership(pendingOperator);
    }


    /************************************************************
    *                    Timelock management                    *
    *************************************************************/
    /// @dev Everyone can activate timelock after the contract has been deployed for more than 1 day.
    function activateTimelock() external {
        bool canActivate = block.timestamp.sub(contractDeployedTime) > 1 days;
        require(canActivate && ! timelockActivated, "Spender: can not activate timelock yet or has been activated");
        timelockActivated = true;

        emit TimeLockActivated(block.timestamp);
    }


    /************************************************************
    *              Constructor and init functions               *
    *************************************************************/
    constructor(address _operator, address[] memory _consumeGasERC20Tokens) public {
        require(_operator != address(0), "Spender: _operator should not be 0");

        // Set operator
        operator = _operator;
        timelockActivated = false;
        contractDeployedTime = block.timestamp;

        for (uint256 i = 0; i < _consumeGasERC20Tokens.length; i++) {
            consumeGasERC20Tokens[_consumeGasERC20Tokens[i]] = true;
        }
    }

    function setAllowanceTarget(address _allowanceTarget) external onlyOperator {
        require(allowanceTarget == address(0), "Spender: can not reset allowance target");

        // Set allowanceTarget
        allowanceTarget = _allowanceTarget;

        emit SetAllowanceTarget(_allowanceTarget);
    }



    /************************************************************
    *          AllowanceTarget interaction functions            *
    *************************************************************/
    function setNewSpender(address _newSpender) external onlyOperator {
        IAllowanceTarget(allowanceTarget).setSpenderWithTimelock(_newSpender);

        emit SetNewSpender(_newSpender);
    }

    function teardownAllowanceTarget() external onlyOperator {
        IAllowanceTarget(allowanceTarget).teardown();

        emit TearDownAllowanceTarget(block.timestamp);
    }



    /************************************************************
    *           Whitelist and blacklist functions               *
    *************************************************************/
    function isBlacklisted(address _tokenAddr) external view returns (bool) {
        return tokenBlacklist[_tokenAddr];
    }

    function blacklist(address[] calldata _tokenAddrs, bool[] calldata _isBlacklisted) external onlyOperator {
        require(_tokenAddrs.length == _isBlacklisted.length, "Spender: length mismatch");
        for (uint256 i = 0; i < _tokenAddrs.length; i++) {
            tokenBlacklist[_tokenAddrs[i]] = _isBlacklisted[i];

            emit BlackListToken(_tokenAddrs[i], _isBlacklisted[i]);
        }
    }
    
    function isAuthorized(address _caller) external view returns (bool) {
        return authorized[_caller];
    }

    function authorize(address[] calldata _pendingAuthorized) external onlyOperator {
        require(_pendingAuthorized.length > 0, "Spender: authorize list is empty");
        require(numPendingAuthorized == 0 && timelockExpirationTime == 0, "Spender: an authorize current in progress");

        if (timelockActivated) {
            numPendingAuthorized = _pendingAuthorized.length;
            for (uint256 i = 0; i < _pendingAuthorized.length; i++) {
                require(_pendingAuthorized[i] != address(0), "Spender: can not authorize zero address");
                pendingAuthorized[i] = _pendingAuthorized[i];
            }
            timelockExpirationTime = now + TIME_LOCK_DURATION;
        } else {
            for (uint256 i = 0; i < _pendingAuthorized.length; i++) {
                require(_pendingAuthorized[i] != address(0), "Spender: can not authorize zero address");
                authorized[_pendingAuthorized[i]] = true;

                emit AuthorizeSpender(_pendingAuthorized[i], true);
            }
        }
    }

    function completeAuthorize() external {
        require(timelockExpirationTime != 0, "Spender: no pending authorize");
        require(now >= timelockExpirationTime, "Spender: time lock not expired yet");

        for (uint256 i = 0; i < numPendingAuthorized; i++) {
            authorized[pendingAuthorized[i]] = true;
            emit AuthorizeSpender(pendingAuthorized[i], true);
            delete pendingAuthorized[i];
        }
        timelockExpirationTime = 0;
        numPendingAuthorized = 0;
    }

    function deauthorize(address[] calldata _deauthorized) external onlyOperator {
        for (uint256 i = 0; i < _deauthorized.length; i++) {
            authorized[_deauthorized[i]] = false;

            emit AuthorizeSpender(_deauthorized[i], false);
        }
    }

    function setConsumeGasERC20Tokens(address[] memory _consumeGasERC20Tokens) external onlyOperator {
        for (uint256 i = 0; i < _consumeGasERC20Tokens.length; i++) {
            consumeGasERC20Tokens[_consumeGasERC20Tokens[i]] = true;

            emit SetConsumeGasERC20Token(_consumeGasERC20Tokens[i]);
        }
    }

    /************************************************************
    *                   External functions                      *
    *************************************************************/
    /// @dev Spend tokens on user's behalf. Only an authority can call this.
    /// @param _user The user to spend token from.
    /// @param _tokenAddr The address of the token.
    /// @param _amount Amount to spend.
    function spendFromUser(address _user, address _tokenAddr, uint256 _amount) external onlyAuthorized {
        require(! tokenBlacklist[_tokenAddr], "Spender: token is blacklisted");

        // Fix gas stipend for non standard ERC20 transfer in case token contract's SafeMath violation is triggered
        // and all gas are consumed.
        uint256 gasStipend;
        if(consumeGasERC20Tokens[_tokenAddr]) gasStipend = 80000;
        else gasStipend = gasleft();

        if (_tokenAddr != ETH_ADDRESS && _tokenAddr != ZERO_ADDRESS) {

            uint256 balanceBefore = IERC20(_tokenAddr).balanceOf(msg.sender);
            (bool callSucceed, bytes memory returndata) = address(allowanceTarget).call{gas: gasStipend}(
                abi.encodeWithSelector(
                    IAllowanceTarget.executeCall.selector,
                    _tokenAddr,
                    abi.encodeWithSelector(
                        IERC20.transferFrom.selector,
                        _user,
                        msg.sender,
                        _amount
                    )
                )
            );
            require(callSucceed, "Spender: ERC20 transferFrom failed");
            bytes memory decodedReturnData = abi.decode(returndata, (bytes));
            if (decodedReturnData.length > 0) { // Return data is optional
                // Tokens like ZRX returns false on failed transfer
                require(abi.decode(decodedReturnData, (bool)), "Spender: ERC20 transferFrom failed");
            }
            // Check balance
            uint256 balanceAfter = IERC20(_tokenAddr).balanceOf(msg.sender);
            require(balanceAfter.sub(balanceBefore) == _amount, "Spender: ERC20 transferFrom amount mismatch");
        }
    }

    /// @dev Spend tokens on user's behalf. Only an authority can call this.
    /// @param _user The user to spend token from.
    /// @param _tokenAddr The address of the token.
    /// @param _receiver The receiver of the token.
    /// @param _amount Amount to spend.
    function spendFromUserTo(address _user, address _tokenAddr, address _receiver, uint256 _amount) external onlyAuthorized {
        require(! tokenBlacklist[_tokenAddr], "Spender: token is blacklisted");

        // Fix gas stipend for non standard ERC20 transfer in case token contract's SafeMath violation is triggered
        // and all gas are consumed.
        uint256 gasStipend;
        if(consumeGasERC20Tokens[_tokenAddr]) gasStipend = 80000;
        else gasStipend = gasleft();

        if (_tokenAddr != ETH_ADDRESS && _tokenAddr != ZERO_ADDRESS) {

            uint256 balanceBefore = IERC20(_tokenAddr).balanceOf(msg.sender);
            (bool callSucceed, bytes memory returndata) = address(allowanceTarget).call{gas: gasStipend}(
                abi.encodeWithSelector(
                    IAllowanceTarget.executeCall.selector,
                    _tokenAddr,
                    abi.encodeWithSelector(
                        IERC20.transferFrom.selector,
                        _user,
                        _receiver,
                        _amount
                    )
                )
            );
            require(callSucceed, "Spender: ERC20 transferFrom failed");
            bytes memory decodedReturnData = abi.decode(returndata, (bytes));
            if (decodedReturnData.length > 0) { // Return data is optional
                // Tokens like ZRX returns false on failed transfer
                require(abi.decode(decodedReturnData, (bool)), "Spender: ERC20 transferFrom failed");
            }
            // Check balance
            uint256 balanceAfter = IERC20(_tokenAddr).balanceOf(msg.sender);
            require(balanceAfter.sub(balanceBefore) == _amount, "Spender: ERC20 transferFrom amount mismatch");
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

pragma solidity ^0.6.5;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../interfaces/IAMM.sol";

contract UserProxyStub {
    using SafeERC20 for IERC20;

    // Constants do not have storage slot.
    uint256 private constant MAX_UINT = 2**256 - 1;
    address private constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address private constant ZERO_ADDRESS = address(0);

    /**
     * @dev Below are the variables which consume storage slots.
     */
    address public operator;
    address public weth;
    address public ammWrapperAddr;
    address public pmmAddr;
    address public rfqAddr;

    receive() external payable {
    }

    /**
     * @dev Access control and ownership management.
     */
    modifier onlyOperator() {
        require(operator == msg.sender, "UserProxyStub: not the operator");
        _;
    }
    /* End of access control and ownership management */


    /**
     * @dev Replacing constructor and initialize the contract. This function should only be called once.
     */
    constructor(address _weth) public {
        operator = msg.sender;
        weth = _weth;
    }

    function upgradePMM(address _pmmAddr) external onlyOperator {
        pmmAddr = _pmmAddr;
    }

    function upgradeAMMWrapper(address _ammWrapperAddr) external onlyOperator {
        ammWrapperAddr = _ammWrapperAddr;
    }

    function upgradeRFQ(address _rfqAddr) external onlyOperator {
        rfqAddr = _rfqAddr;
    }

    function toAMM(bytes calldata _payload) external payable {
        (bool callSucceed,) = ammWrapperAddr.call{value: msg.value}(_payload);
        if (callSucceed == false) {
            // Get the error message returned
            assembly {
                let ptr := mload(0x40)
                let size := returndatasize()
                returndatacopy(ptr, 0, size)
                revert(ptr, size)
            }
        }
    }

    function toPMM(bytes calldata _payload) external payable {
        (bool callSucceed,) = pmmAddr.call{value: msg.value}(_payload);
        if (callSucceed == false) {
            // Get the error message returned
            assembly {
                let ptr := mload(0x40)
                let size := returndatasize()
                returndatacopy(ptr, 0, size)
                revert(ptr, size)
            }
        }
    }

    function toRFQ(bytes calldata _payload) external payable {
        (bool callSucceed,) = rfqAddr.call{value: msg.value}(_payload);
        if (callSucceed == false) {
            // Get the error message returned
            assembly {
                let ptr := mload(0x40)
                let size := returndatasize()
                returndatacopy(ptr, 0, size)
                revert(ptr, size)
            }
        }
    }
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

pragma solidity ^0.6.0;

import "./ISetAllowance.sol";

interface IAMM is ISetAllowance {
    function trade(
        address _makerAddress,
        address _fromAssetAddress,
        address _toAssetAddress,
        uint256 _takerAssetAmount,
        uint256 _makerAssetAmount,
        uint256 _feeFactor,
        address _spender,
        address payable _receiver,
        uint256 _nonce,
        uint256 _deadline,
        bytes memory _sig
    ) payable external returns (uint256);
}

pragma solidity ^0.6.0;

interface ISetAllowance {
    function setAllowance(address[] memory tokenList, address spender) external;
    function closeAllowance(address[] memory tokenList, address spender) external;
}

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../interfaces/ISetAllowance.sol";
import "../interfaces/IERC1271Wallet.sol";

contract ERC1271WalletStub is
    ISetAllowance,
    IERC1271Wallet
{
    using SafeERC20 for IERC20;
    // bytes4(keccak256("isValidSignature(bytes,bytes)"))
    bytes4 constant internal ERC1271_MAGICVALUE = 0x20c13b0b;

    // bytes4(keccak256("isValidSignature(bytes32,bytes)"))
    bytes4 constant internal ERC1271_MAGICVALUE_BYTES32 = 0x1626ba7e;
    uint256 private constant MAX_UINT = 2**256 - 1;
    address public operator;

    modifier onlyOperator() {
        require(operator == msg.sender, "Quoter: not the operator");
        _;
    }

    constructor (address _operator) public {
        operator = _operator;
    }

    function setAllowance(address[] memory _tokenList, address _spender) override external onlyOperator {
        for (uint256 i = 0 ; i < _tokenList.length; i++) {
            IERC20(_tokenList[i]).safeApprove(_spender, MAX_UINT);
        }
    }

    function closeAllowance(address[] memory _tokenList, address _spender) override external onlyOperator {
        for (uint256 i = 0 ; i < _tokenList.length; i++) {
            IERC20(_tokenList[i]).safeApprove(_spender, 0);
        }
    }

    function isValidSignature(
        bytes calldata _data,
        bytes calldata _signature)
        override
        external
        view
        returns (bytes4 magicValue)
    {
        return ERC1271_MAGICVALUE;
    }

    function isValidSignature(
        bytes32 _hash,
        bytes calldata _signature)
        override
        external
        view
        returns (bytes4 magicValue)
    {
        return ERC1271_MAGICVALUE_BYTES32;
    }
}

pragma solidity ^0.6.0;


interface  IERC1271Wallet {

  /**
   * @notice Verifies whether the provided signature is valid with respect to the provided data
   * @dev MUST return the correct magic value if the signature provided is valid for the provided data
   *   > The bytes4 magic value to return when signature is valid is 0x20c13b0b : bytes4(keccak256("isValidSignature(bytes,bytes)")
   *   > This function MAY modify Ethereum's state
   * @param _data       Arbitrary length data signed on the behalf of address(this)
   * @param _signature  Signature byte array associated with _data
   * @return magicValue Magic value 0x20c13b0b if the signature is valid and 0x0 otherwise
   *
   */
  function isValidSignature(
    bytes calldata _data,
    bytes calldata _signature)
    external
    view
    returns (bytes4 magicValue);

  /**
   * @notice Verifies whether the provided signature is valid with respect to the provided hash
   * @dev MUST return the correct magic value if the signature provided is valid for the provided hash
   *   > The bytes4 magic value to return when signature is valid is 0x20c13b0b : bytes4(keccak256("isValidSignature(bytes,bytes)")
   *   > This function MAY modify Ethereum's state
   * @param _hash       keccak256 hash that was signed
   * @param _signature  Signature byte array associated with _data
   * @return magicValue Magic value 0x20c13b0b if the signature is valid and 0x0 otherwise
   */
  function isValidSignature(
    bytes32 _hash,
    bytes calldata _signature)
    external
    view
    returns (bytes4 magicValue);
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./interfaces/ISpender.sol";
import "./interfaces/IWeth.sol";
import "./interfaces/IRFQ.sol";
import "./interfaces/IPermanentStorage.sol";
import "./interfaces/IERC1271Wallet.sol";
import "./utils/RFQLibEIP712.sol";

contract RFQ is
    ReentrancyGuard,
    IRFQ,
    RFQLibEIP712,
    SignatureValidator
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;

    // Constants do not have storage slot.
    string public constant version = "5.2.0";
    uint256 private constant MAX_UINT = 2**256 - 1;
    string public constant SOURCE = "RFQ v1";
    uint256 private constant BPS_MAX = 10000;
    address public immutable userProxy;
    IPermanentStorage public immutable permStorage;
    IWETH public immutable weth;

    // Below are the variables which consume storage slots.
    address public operator;
    ISpender public spender;

    struct GroupedVars {
        bytes32 orderHash;
        bytes32 transactionHash;
    }

    // Operator events
    event TransferOwnership(address newOperator);
    event UpgradeSpender(address newSpender);
    event AllowTransfer(address spender);
    event DisallowTransfer(address spender);
    event DepositETH(uint256 ethBalance);

    event FillOrder(
        string source,
        bytes32 indexed transactionHash,
        bytes32 indexed orderHash,
        address indexed userAddr,
        address takerAssetAddr,
        uint256 takerAssetAmount,
        address makerAddr,
        address makerAssetAddr,
        uint256 makerAssetAmount,
        address receiverAddr,
        uint256 settleAmount,
        uint16 feeFactor
    );


    receive() external payable {}


    /************************************************************
    *          Access control and ownership management          *
    *************************************************************/
    modifier onlyOperator {
        require(operator == msg.sender, "RFQ: not operator");
        _;
    }

    modifier onlyUserProxy() {
        require(address(userProxy) == msg.sender, "RFQ: not the UserProxy contract");
        _;
    }

    function transferOwnership(address _newOperator) external onlyOperator {
        require(_newOperator != address(0), "RFQ: operator can not be zero address");
        operator = _newOperator;

        emit TransferOwnership(_newOperator);
    }


    /************************************************************
    *              Constructor and init functions               *
    *************************************************************/
    constructor (
        address _operator, 
        address _userProxy, 
        ISpender _spender, 
        IPermanentStorage _permStorage, 
        IWETH _weth
    ) public {
        operator = _operator;
        userProxy = _userProxy;
        spender = _spender;
        permStorage = _permStorage;
        weth = _weth;
    }


    /************************************************************
    *           Management functions for Operator               *
    *************************************************************/
    /**
     * @dev set new Spender
     */
    function upgradeSpender(address _newSpender) external onlyOperator {
        require(_newSpender != address(0), "RFQ: spender can not be zero address");
        spender = ISpender(_newSpender);

        emit UpgradeSpender(_newSpender);
    }

    /**
     * @dev approve spender to transfer tokens from this contract. This is used to collect fee.
     */
    function setAllowance(address[] calldata _tokenList, address _spender) override external onlyOperator {
        for (uint256 i = 0 ; i < _tokenList.length; i++) {
            IERC20(_tokenList[i]).safeApprove(_spender, MAX_UINT);

            emit AllowTransfer(_spender);
        }
    }

    function closeAllowance(address[] calldata _tokenList, address _spender) override external onlyOperator {
        for (uint256 i = 0 ; i < _tokenList.length; i++) {
            IERC20(_tokenList[i]).safeApprove(_spender, 0);

            emit DisallowTransfer(_spender);
        }
    }

    /**
     * @dev convert collected ETH to WETH
     */
    function depositETH() external onlyOperator {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            weth.deposit{value: balance}();

            emit DepositETH(balance);
        }
    }


    /************************************************************
    *                   External functions                      *
    *************************************************************/
    function fill(
        RFQLibEIP712.Order memory _order,
        bytes memory _mmSignature,
        bytes memory _userSignature
    )
        override
        payable
        external
        nonReentrant
        onlyUserProxy
        returns (uint256)
    {
        // check the order deadline and fee factor
        require(_order.deadline >= block.timestamp, "RFQ: expired order");
        require(_order.feeFactor < BPS_MAX, "RFQ: invalid fee factor");

        GroupedVars memory vars;

        // Validate signatures
        vars.orderHash = _getOrderHash(_order);
        require(
            isValidSignature(
                _order.makerAddr,
                _getOrderSignDigestFromHash(vars.orderHash),
                bytes(""),
                _mmSignature
            ),
            "RFQ: invalid MM signature"
        );
        vars.transactionHash = _getTransactionHash(_order);
        require(
            isValidSignature(
                _order.takerAddr,
                _getTransactionSignDigestFromHash(vars.transactionHash),
                bytes(""),
                _userSignature
            ),
            "RFQ: invalid user signature"
        );

        // Set transaction as seen, PermanentStorage would throw error if transaction already seen.
        permStorage.setRFQTransactionSeen(vars.transactionHash);

        // Deposit to WETH if taker asset is ETH, else transfer from user
        if (address(weth) == _order.takerAssetAddr) {
            require(
                msg.value == _order.takerAssetAmount,
                "RFQ: insufficient ETH"
            );
            weth.deposit{value: msg.value}();
        } else {
            spender.spendFromUser(_order.takerAddr, _order.takerAssetAddr, _order.takerAssetAmount);
        }
        // Transfer from maker
        spender.spendFromUser(_order.makerAddr, _order.makerAssetAddr, _order.makerAssetAmount);

        // settle token/ETH to user
        return _settle(_order, vars);
    }

    // settle
    function _settle(
        RFQLibEIP712.Order memory _order,
        GroupedVars memory _vars
    ) internal returns(uint256) {
        // Transfer taker asset to maker
        IERC20(_order.takerAssetAddr).safeTransfer(_order.makerAddr, _order.takerAssetAmount);

        // Transfer maker asset to taker, sub fee
        uint256 settleAmount = _order.makerAssetAmount;
        if (_order.feeFactor > 0) {
            // settleAmount = settleAmount * (10000 - feeFactor) / 10000
            settleAmount = settleAmount.mul((BPS_MAX).sub(_order.feeFactor)).div(BPS_MAX);
        }

        // Transfer token/Eth to receiver
        if (_order.makerAssetAddr == address(weth)){
            weth.withdraw(settleAmount);
            payable(_order.receiverAddr).transfer(settleAmount);
        } else {
            IERC20(_order.makerAssetAddr).safeTransfer(_order.receiverAddr, settleAmount);
        }

        emit FillOrder(
            SOURCE,
            _vars.transactionHash,
            _vars.orderHash,
            _order.takerAddr,
            _order.takerAssetAddr,
            _order.takerAssetAmount,
            _order.makerAddr,
            _order.makerAssetAddr,
            _order.makerAssetAmount,
            _order.receiverAddr,
            settleAmount,
            uint16(_order.feeFactor)
        );

        return settleAmount;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

pragma solidity ^0.6.0;

interface ISpender {
    function spendFromUser(address _user, address _tokenAddr, uint256 _amount) external;
    function spendFromUserTo(address _user, address _tokenAddr, address _receiverAddr, uint256 _amount) external;
}

pragma solidity ^0.6.0;

interface IWETH {
    function balanceOf(address account) external view returns (uint256);
    function deposit() external payable;
    function withdraw(uint256 amount) external;
    function transferFrom(address src, address dst, uint wad) external returns (bool);
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../utils/RFQLibEIP712.sol";
import "./ISetAllowance.sol";

interface IRFQ is ISetAllowance {
    function fill(
        RFQLibEIP712.Order memory _order,
        bytes memory _mmSignature,
        bytes memory _userSignature
    ) external payable returns (uint256);
}

pragma solidity ^0.6.0;

interface IPermanentStorage {
    function wethAddr() external view returns (address);
    function getCurvePoolInfo(address _makerAddr, address _takerAssetAddr, address _makerAssetAddr) external view returns (int128 takerAssetIndex, int128 makerAssetIndex, uint16 swapMethod, bool supportGetDx);
    function setCurvePoolInfo(address _makerAddr, address[] calldata _underlyingCoins, address[] calldata _coins, bool _supportGetDx) external;
    function isTransactionSeen(bytes32 _transactionHash) external view returns (bool);  // Kept for backward compatability. Should be removed from AMM 5.2.1 upward
    function isAMMTransactionSeen(bytes32 _transactionHash) external view returns (bool);
    function isRFQTransactionSeen(bytes32 _transactionHash) external view returns (bool);
    function isRelayerValid(address _relayer) external view returns (bool);
    function setTransactionSeen(bytes32 _transactionHash) external;  // Kept for backward compatability. Should be removed from AMM 5.2.1 upward
    function setAMMTransactionSeen(bytes32 _transactionHash) external;
    function setRFQTransactionSeen(bytes32 _transactionHash) external;
    function setRelayersValid(address[] memory _relayers, bool[] memory _isValids) external;
}

pragma solidity ^0.6.0;

import "./BaseLibEIP712.sol";
import "./SignatureValidator.sol";

contract RFQLibEIP712 is BaseLibEIP712 {
    /***********************************|
    |             Constants             |
    |__________________________________*/
    

    struct Order {
        address takerAddr;
        address makerAddr;
        address takerAssetAddr;
        address makerAssetAddr;
        uint256 takerAssetAmount;
        uint256 makerAssetAmount;
        address receiverAddr;
        uint256 salt;
        uint256 deadline;
        uint256 feeFactor;
    }

    bytes32 public constant ORDER_TYPEHASH = keccak256(
        abi.encodePacked(
            "Order(",
            "address takerAddr,",
            "address makerAddr,",
            "address takerAssetAddr,",
            "address makerAssetAddr,",
            "uint256 takerAssetAmount,",
            "uint256 makerAssetAmount,",
            "uint256 salt,",
            "uint256 deadline,",
            "uint256 feeFactor",
            ")"
        )
    );

    function _getOrderHash(Order memory _order) internal pure returns (bytes32 orderHash) {
        orderHash = keccak256(
            abi.encode(
                ORDER_TYPEHASH,
                _order.takerAddr,
                _order.makerAddr,
                _order.takerAssetAddr,
                _order.makerAssetAddr,
                _order.takerAssetAmount,
                _order.makerAssetAmount,
                _order.salt,
                _order.deadline,
                _order.feeFactor
            )
        );
    }

    function _getOrderSignDigest(Order memory _order) internal view returns (bytes32 orderSignDigest) {
        orderSignDigest = keccak256(
            abi.encodePacked(
                EIP191_HEADER,
                EIP712_DOMAIN_SEPARATOR,
                _getOrderHash(_order)
            )
        );
    }

    function _getOrderSignDigestFromHash(bytes32 _orderHash) internal view returns (bytes32 orderSignDigest) {
        orderSignDigest = keccak256(
            abi.encodePacked(
                EIP191_HEADER,
                EIP712_DOMAIN_SEPARATOR,
                _orderHash
            )
        );
    }

    bytes32 public constant FILL_WITH_PERMIT_TYPEHASH = keccak256(
        abi.encodePacked(
            "fillWithPermit(",
            "address makerAddr,",
            "address takerAssetAddr,",
            "address makerAssetAddr,",
            "uint256 takerAssetAmount,",
            "uint256 makerAssetAmount,",
            "address takerAddr,",
            "address receiverAddr,",
            "uint256 salt,",
            "uint256 deadline,",
            "uint256 feeFactor",
            ")"
        )
    );

    function _getTransactionHash(Order memory _order) internal pure returns(bytes32 transactionHash) {
        transactionHash = keccak256(
            abi.encode(
                FILL_WITH_PERMIT_TYPEHASH,
                _order.makerAddr,
                _order.takerAssetAddr,
                _order.makerAssetAddr,
                _order.takerAssetAmount,
                _order.makerAssetAmount,
                _order.takerAddr,
                _order.receiverAddr,
                _order.salt,
                _order.deadline,
                _order.feeFactor
            )
        );
    }

    function _getTransactionSignDigest(Order memory _order) internal view returns (bytes32 transactionSignDigest) {
        transactionSignDigest = keccak256(
            abi.encodePacked(
                EIP191_HEADER,
                EIP712_DOMAIN_SEPARATOR,
                _getTransactionHash(_order)
            )
        );
    }

    function _getTransactionSignDigestFromHash(bytes32 _txHash) internal view returns (bytes32 transactionSignDigest) {
        transactionSignDigest = keccak256(
            abi.encodePacked(
                EIP191_HEADER,
                EIP712_DOMAIN_SEPARATOR,
                _txHash
            )
        );
    }
}

pragma solidity ^0.6.0;

contract BaseLibEIP712 {
    /***********************************|
    |             Constants             |
    |__________________________________*/

    // EIP-191 Header
    string public constant EIP191_HEADER = "\x19\x01";

    // EIP712Domain
    string public constant EIP712_DOMAIN_NAME = "Tokenlon";
    string public constant EIP712_DOMAIN_VERSION = "v5";

    // EIP712Domain Separator
    bytes32 public immutable EIP712_DOMAIN_SEPARATOR = keccak256(
        abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256(bytes(EIP712_DOMAIN_NAME)),
            keccak256(bytes(EIP712_DOMAIN_VERSION)),
            getChainID(),
            address(this)
        )
    );

    /**
        * @dev Return `chainId`
        */
    function getChainID() internal pure returns (uint) {
        uint chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
}

pragma solidity ^0.6.0;

import "../interfaces/IERC1271Wallet.sol";
import "./LibBytes.sol";

interface IWallet {
    /// @dev Verifies that a signature is valid.
    /// @param hash Message hash that is signed.
    /// @param signature Proof of signing.
    /// @return isValid Validity of order signature.
    function isValidSignature(
        bytes32 hash,
        bytes memory signature
    )
        external
        view
        returns (bool isValid);
}

/**
 * @dev Contains logic for signature validation.
 * Signatures from wallet contracts assume ERC-1271 support (https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1271.md)
 * Notes: Methods are strongly inspired by contracts in https://github.com/0xProject/0x-monorepo/blob/development/
 */
contract SignatureValidator {
  using LibBytes for bytes;

  /***********************************|
  |             Variables             |
  |__________________________________*/

  // bytes4(keccak256("isValidSignature(bytes,bytes)"))
  bytes4 constant internal ERC1271_MAGICVALUE = 0x20c13b0b;

  // bytes4(keccak256("isValidSignature(bytes32,bytes)"))
  bytes4 constant internal ERC1271_MAGICVALUE_BYTES32 = 0x1626ba7e;

  // keccak256("isValidWalletSignature(bytes32,address,bytes)")
  bytes4 constant internal ERC1271_FALLBACK_MAGICVALUE_BYTES32 = 0xb0671381;

  // Allowed signature types.
  enum SignatureType {
    Illegal,                     // 0x00, default value
    Invalid,                     // 0x01
    EIP712,                      // 0x02
    EthSign,                     // 0x03
    WalletBytes,                 // 0x04  standard 1271 wallet type
    WalletBytes32,               // 0x05  standard 1271 wallet type
    Wallet,                      // 0x06  0x wallet type for signature compatibility
    NSignatureTypes              // 0x07, number of signature types. Always leave at end.
  }

  /***********************************|
  |        Signature Functions        |
  |__________________________________*/

  /**
   * @dev Verifies that a hash has been signed by the given signer.
   * @param _signerAddress  Address that should have signed the given hash.
   * @param _hash           Hash of the EIP-712 encoded data
   * @param _data           Full EIP-712 data structure that was hashed and signed
   * @param _sig            Proof that the hash has been signed by signer.
   *      For non wallet signatures, _sig is expected to be an array tightly encoded as
   *      (bytes32 r, bytes32 s, uint8 v, uint256 nonce, SignatureType sigType)
   * @return isValid True if the address recovered from the provided signature matches the input signer address.
   */
  function isValidSignature(
    address _signerAddress,
    bytes32 _hash,
    bytes memory _data,
    bytes memory _sig
  )
    public
    view
    returns (bool isValid)
  {
    require(
      _sig.length > 0,
      "SignatureValidator#isValidSignature: length greater than 0 required"
    );

    require(
      _signerAddress != address(0x0),
      "SignatureValidator#isValidSignature: invalid signer"
    );

    // Pop last byte off of signature byte array.
    uint8 signatureTypeRaw = uint8(_sig.popLastByte());

    // Ensure signature is supported
    require(
      signatureTypeRaw < uint8(SignatureType.NSignatureTypes),
      "SignatureValidator#isValidSignature: unsupported signature"
    );

    // Extract signature type
    SignatureType signatureType = SignatureType(signatureTypeRaw);

    // Variables are not scoped in Solidity.
    uint8 v;
    bytes32 r;
    bytes32 s;
    address recovered;

    // Always illegal signature.
    // This is always an implicit option since a signer can create a
    // signature array with invalid type or length. We may as well make
    // it an explicit option. This aids testing and analysis. It is
    // also the initialization value for the enum type.
    if (signatureType == SignatureType.Illegal) {
      revert("SignatureValidator#isValidSignature: illegal signature");


    // Signature using EIP712
    } else if (signatureType == SignatureType.EIP712) {
      require(
        _sig.length == 97,
        "SignatureValidator#isValidSignature: length 97 required"
      );
      r = _sig.readBytes32(0);
      s = _sig.readBytes32(32);
      v = uint8(_sig[64]);
      recovered = ecrecover(_hash, v, r, s);
      isValid = _signerAddress == recovered;
      return isValid;


    // Signed using web3.eth_sign() or Ethers wallet.signMessage()
    } else if (signatureType == SignatureType.EthSign) {
      require(
        _sig.length == 97,
        "SignatureValidator#isValidSignature: length 97 required"
      );
      r = _sig.readBytes32(0);
      s = _sig.readBytes32(32);
      v = uint8(_sig[64]);
      recovered = ecrecover(
        keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)),
        v,
        r,
        s
      );
      isValid = _signerAddress == recovered;
      return isValid;


    // Signature verified by wallet contract with data validation.
    } else if (signatureType == SignatureType.WalletBytes) {
      isValid = ERC1271_MAGICVALUE == IERC1271Wallet(_signerAddress).isValidSignature(_data, _sig);
      return isValid;


    // Signature verified by wallet contract without data validation.
    } else if (signatureType == SignatureType.WalletBytes32) {
      isValid = ERC1271_MAGICVALUE_BYTES32 == IERC1271Wallet(_signerAddress).isValidSignature(_hash, _sig);
      return isValid;


    } else if (signatureType == SignatureType.Wallet) {
      isValid = isValidWalletSignature(
          _hash,
          _signerAddress,
          _sig
      );
      return isValid;
    }

    // Anything else is illegal (We do not return false because
    // the signature may actually be valid, just not in a format
    // that we currently support. In this case returning false
    // may lead the caller to incorrectly believe that the
    // signature was invalid.)
    revert("SignatureValidator#isValidSignature: unsupported signature");
  }

  /// @dev Verifies signature using logic defined by Wallet contract.
  /// @param hash Any 32 byte hash.
  /// @param walletAddress Address that should have signed the given hash
  ///                      and defines its own signature verification method.
  /// @param signature Proof that the hash has been signed by signer.
  /// @return isValid True if signature is valid for given wallet..
  function isValidWalletSignature(
      bytes32 hash,
      address walletAddress,
      bytes memory signature
  )
      internal
      view
      returns (bool isValid)
  {
      bytes memory _calldata = abi.encodeWithSelector(
          IWallet(walletAddress).isValidSignature.selector,
          hash,
          signature
      );
      bytes32 magic_salt = bytes32(bytes4(keccak256("isValidWalletSignature(bytes32,address,bytes)")));
      assembly {
          if iszero(extcodesize(walletAddress)) {
              // Revert with `Error("WALLET_ERROR")`
              mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
              mstore(32, 0x0000002000000000000000000000000000000000000000000000000000000000)
              mstore(64, 0x0000000c57414c4c45545f4552524f5200000000000000000000000000000000)
              mstore(96, 0)
              revert(0, 100)
          }

          let cdStart := add(_calldata, 32)
          let success := staticcall(
              gas(),              // forward all gas
              walletAddress,    // address of Wallet contract
              cdStart,          // pointer to start of input
              mload(_calldata),  // length of input
              cdStart,          // write output over input
              32                // output size is 32 bytes
          )

          if iszero(eq(returndatasize(), 32)) {
              // Revert with `Error("WALLET_ERROR")`
              mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
              mstore(32, 0x0000002000000000000000000000000000000000000000000000000000000000)
              mstore(64, 0x0000000c57414c4c45545f4552524f5200000000000000000000000000000000)
              mstore(96, 0)
              revert(0, 100)
          }

          switch success
          case 0 {
              // Revert with `Error("WALLET_ERROR")`
              mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
              mstore(32, 0x0000002000000000000000000000000000000000000000000000000000000000)
              mstore(64, 0x0000000c57414c4c45545f4552524f5200000000000000000000000000000000)
              mstore(96, 0)
              revert(0, 100)
          }
          case 1 {
              // Signature is valid if call did not revert and returned true
              isValid := eq(
                  and(mload(cdStart), 0xffffffff00000000000000000000000000000000000000000000000000000000),
                  and(magic_salt, 0xffffffff00000000000000000000000000000000000000000000000000000000)
              )
          }
      }
      return isValid;
  }
}

/*
  Copyright 2018 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
  http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
  This is a truncated version of the original LibBytes.sol library from ZeroEx.
*/

pragma solidity ^0.6.0;


library LibBytes {
  using LibBytes for bytes;

  /***********************************|
  |        Pop Bytes Functions        |
  |__________________________________*/

  /**
   * @dev Pops the last byte off of a byte array by modifying its length.
   * @param b Byte array that will be modified.
   * @return result The byte that was popped off.
   */
  function popLastByte(bytes memory b)
    internal
    pure
    returns (bytes1 result)
  {
    require(
      b.length > 0,
      "LibBytes#popLastByte: greater than zero length required"
    );

    // Store last byte.
    result = b[b.length - 1];

    assembly {
      // Decrement length of byte array.
      let newLen := sub(mload(b), 1)
      mstore(b, newLen)
    }
    return result;
  }

  /// @dev Reads an address from a position in a byte array.
  /// @param b Byte array containing an address.
  /// @param index Index in byte array of address.
  /// @return result address from byte array.
  function readAddress(
    bytes memory b,
    uint256 index
  )
    internal
    pure
    returns (address result)
  {
    require(
      b.length >= index + 20,  // 20 is length of address
      "LibBytes#readAddress greater or equal to 20 length required"
    );

    // Add offset to index:
    // 1. Arrays are prefixed by 32-byte length parameter (add 32 to index)
    // 2. Account for size difference between address length and 32-byte storage word (subtract 12 from index)
    index += 20;

    // Read address from array memory
    assembly {
      // 1. Add index to address of bytes array
      // 2. Load 32-byte word from memory
      // 3. Apply 20-byte mask to obtain address
      result := and(mload(add(b, index)), 0xffffffffffffffffffffffffffffffffffffffff)
    }
    return result;
  }

  /***********************************|
  |        Read Bytes Functions       |
  |__________________________________*/

  /**
   * @dev Reads a bytes32 value from a position in a byte array.
   * @param b Byte array containing a bytes32 value.
   * @param index Index in byte array of bytes32 value.
   * @return result bytes32 value from byte array.
   */
  function readBytes32(
    bytes memory b,
    uint256 index
  )
    internal
    pure
    returns (bytes32 result)
  {
    require(
      b.length >= index + 32,
      "LibBytes#readBytes32 greater or equal to 32 length required"
    );

    // Arrays are prefixed by a 256 bit length parameter
    index += 32;

    // Read the bytes32 from array memory
    assembly {
      result := mload(add(b, index))
    }
    return result;
  }

  /// @dev Reads an unpadded bytes4 value from a position in a byte array.
  /// @param b Byte array containing a bytes4 value.
  /// @param index Index in byte array of bytes4 value.
  /// @return result bytes4 value from byte array.
  function readBytes4(
    bytes memory b,
    uint256 index
  )
    internal
    pure
    returns (bytes4 result)
  {
    require(
      b.length >= index + 4,
      "LibBytes#readBytes4 greater or equal to 4 length required"
    );

    // Arrays are prefixed by a 32 byte length field
    index += 32;

    // Read the bytes4 from array memory
    assembly {
      result := mload(add(b, index))
      // Solidity does not require us to clean the trailing bytes.
      // We do it anyway
      result := and(result, 0xFFFFFFFF00000000000000000000000000000000000000000000000000000000)
    }
    return result;
  }

  function readBytes2(
    bytes memory b,
    uint256 index
  )
    internal
    pure
    returns (bytes2 result)
  {
    require(
      b.length >= index + 2,
      "LibBytes#readBytes2 greater or equal to 2 length required"
    );

    // Arrays are prefixed by a 32 byte length field
    index += 32;

    // Read the bytes4 from array memory
    assembly {
      result := mload(add(b, index))
      // Solidity does not require us to clean the trailing bytes.
      // We do it anyway
      result := and(result, 0xFFFF000000000000000000000000000000000000000000000000000000000000)
    }
    return result;
  }
}

pragma solidity 0.6.12;

import "../utils/LibBytes.sol";
import "./MultiSigLibEIP712.sol";

/**
 * @title MultiSig
 * @author dYdX
 *
 * Multi-Signature Wallet.
 * Allows multiple parties to agree on transactions before execution.
 * Adapted from Stefan George's MultiSigWallet contract.
 *
 * Logic Changes:
 *  - Removed the fallback function
 *  - Ensure newOwner is notNull
 *
 * Syntax Changes:
 *  - Update Solidity syntax for 0.5.X: use `emit` keyword (events), use `view` keyword (functions)
 *  - Add braces to all `if` and `for` statements
 *  - Remove named return variables
 *  - Add space before and after comparison operators
 *  - Add ADDRESS_ZERO as a constant
 *  - uint => uint256
 *  - external_call => externalCall
 */
contract MultiSig is MultiSigLibEIP712 {
    using LibBytes for bytes;

    // ============ Events ============

    event Deposit(address indexed depositer, uint256 amount);
    event Confirmation(address indexed sender, uint256 indexed transactionId);
    event Revocation(address indexed sender, uint256 indexed transactionId);
    event Submission(uint256 indexed transactionId);
    event Execution(uint256 indexed transactionId);
    event ExecutionFailure(uint256 indexed transactionId);
    event OwnerAddition(address indexed owner);
    event OwnerRemoval(address indexed owner);
    event RequirementChange(uint256 required);

    // ============ Constants ============

    uint256 constant public MAX_OWNER_COUNT = 50;
    address constant ADDRESS_ZERO = address(0x0);

    // ============ Storage ============

    mapping (uint256 => Transaction) public transactions;
    mapping (uint256 => mapping (address => bool)) public confirmations;
    mapping (address => bool) public isOwner;
    address[] public owners;
    uint256 public required;
    uint256 public transactionCount;

    // ============ Structs ============

    struct Transaction {
        address destination;
        uint256 value;
        bytes data;
        bool executed;
    }

    // ============ Modifiers ============

    modifier onlyWallet() {
        /* solium-disable-next-line error-reason */
        require(msg.sender == address(this));
        _;
    }

    modifier ownerDoesNotExist(
        address owner
    ) {
        /* solium-disable-next-line error-reason */
        require(!isOwner[owner]);
        _;
    }

    modifier ownerExists(
        address owner
    ) {
        /* solium-disable-next-line error-reason */
        require(isOwner[owner]);
        _;
    }

    modifier transactionExists(
        uint256 transactionId
    ) {
        /* solium-disable-next-line error-reason */
        require(transactions[transactionId].destination != ADDRESS_ZERO);
        _;
    }

    modifier confirmed(
        uint256 transactionId,
        address owner
    ) {
        /* solium-disable-next-line error-reason */
        require(confirmations[transactionId][owner]);
        _;
    }

    modifier notConfirmed(
        uint256 transactionId,
        address owner
    ) {
        /* solium-disable-next-line error-reason */
        require(!confirmations[transactionId][owner]);
        _;
    }

    modifier notExecuted(
        uint256 transactionId
    ) {
        /* solium-disable-next-line error-reason */
        require(!transactions[transactionId].executed);
        _;
    }

    modifier notNull(
        address _address
    ) {
        /* solium-disable-next-line error-reason */
        require(_address != ADDRESS_ZERO);
        _;
    }

    modifier validRequirement(
        uint256 ownerCount,
        uint256 _required
    ) {
        /* solium-disable-next-line error-reason */
        require(
            ownerCount <= MAX_OWNER_COUNT
            && _required <= ownerCount
            && _required != 0
            && ownerCount != 0
        );
        _;
    }

    // ========= Fallback function ==========
    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    // ============ Constructor ============

    /**
     * Contract constructor sets initial owners and required number of confirmations.
     *
     * @param  _owners    List of initial owners.
     * @param  _required  Number of required confirmations.
     */
    constructor(
        address[] memory _owners,
        uint256 _required
    )
        public
        validRequirement(_owners.length, _required)
        MultiSigLibEIP712()
    {
        for (uint256 i = 0; i < _owners.length; i++) {
            /* solium-disable-next-line error-reason */
            require(!isOwner[_owners[i]] && _owners[i] != ADDRESS_ZERO);
            isOwner[_owners[i]] = true;
        }
        owners = _owners;
        required = _required;
    }

    // ============ Wallet-Only Functions ============

    /**
     * Allows to add a new owner. Transaction has to be sent by wallet.
     *
     * @param  owner  Address of new owner.
     */
    function addOwner(
        address owner
    )
        public
        onlyWallet
        ownerDoesNotExist(owner)
        notNull(owner)
        validRequirement(owners.length + 1, required)
    {
        isOwner[owner] = true;
        owners.push(owner);
        emit OwnerAddition(owner);
    }

    /**
     * Allows to remove an owner. Transaction has to be sent by wallet.
     *
     * @param  owner  Address of owner.
     */
    function removeOwner(
        address owner
    )
        public
        onlyWallet
        ownerExists(owner)
    {
        isOwner[owner] = false;
        for (uint256 i = 0; i < owners.length - 1; i++) {
            if (owners[i] == owner) {
                owners[i] = owners[owners.length - 1];
                break;
            }
        }
        delete owners[owners.length - 1];
        if (required > owners.length) {
            changeRequirement(owners.length);
        }
        emit OwnerRemoval(owner);
    }

    /**
     * Allows to replace an owner with a new owner. Transaction has to be sent by wallet.
     *
     * @param  owner     Address of owner to be replaced.
     * @param  newOwner  Address of new owner.
     */
    function replaceOwner(
        address owner,
        address newOwner
    )
        public
        onlyWallet
        ownerExists(owner)
        ownerDoesNotExist(newOwner)
        notNull(newOwner)
    {
        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == owner) {
                owners[i] = newOwner;
                break;
            }
        }
        isOwner[owner] = false;
        isOwner[newOwner] = true;
        emit OwnerRemoval(owner);
        emit OwnerAddition(newOwner);
    }

    /**
     * Allows to change the number of required confirmations. Transaction has to be sent by wallet.
     *
     * @param  _required  Number of required confirmations.
     */
    function changeRequirement(
        uint256 _required
    )
        public
        onlyWallet
        validRequirement(owners.length, _required)
    {
        required = _required;
        emit RequirementChange(_required);
    }

    // ============ Owner Functions ============

    /**
     * Allows an owner to submit and confirm a transaction.
     *
     * @param  destination  Transaction target address.
     * @param  value        Transaction ether value.
     * @param  data         Transaction data payload.
     * @return              Transaction ID.
     */
    function submitTransaction(
        address destination,
        uint256 value,
        bytes memory data
    )
        public
        returns (uint256)
    {
        uint256 transactionId = addTransaction(destination, value, data);
        confirmTransaction(transactionId);
        return transactionId;
    }

    /**
     * Allows an owner to submit and confirm a transaction via meta transaction.
     *
     * @param  signer           Signer of the meta transaction.
     * @param  transactionId    Transaction ID of this transaction.
     * @param  destination      Transaction target address.
     * @param  value            Transaction ether value.
     * @param  data             Transaction data payload.
     * @param  sig              Signature.
     * @return                  Transaction ID.
     */
    function submitTransaction(
        address signer,
        uint256 transactionId,
        address destination,
        uint256 value,
        bytes memory data,
        bytes memory sig
    )
        public
        ownerExists(signer)
        returns (uint256)
    {
        // SUBMIT_TRANSACTION_TYPE_HASH = keccak256("submitTransaction(uint256 transactionId,address destination,uint256 value,bytes data)");
        bytes32 EIP712SignDigest = keccak256(
            abi.encodePacked(
                bytes1(0x19),
                bytes1(0x01),
                EIP712_DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        SUBMIT_TRANSACTION_TYPE_HASH,
                        transactionId,
                        destination,
                        value,
                        data
                    )
                )
            )
        );
        validateSignature(signer, EIP712SignDigest, sig);

        uint256 _transactionId = addTransaction(destination, value, data);

        require(transactionId == _transactionId);

        confirmTransactionBySigner(signer, transactionId);
        return transactionId;
    }

    // confirm transaction on behalf of signer, not msg.sender
    function confirmTransactionBySigner(
        address signer,
        uint256 transactionId
    )
        internal
        transactionExists(transactionId)
        notConfirmed(transactionId, signer)
    {
        // Confirm
        confirmations[transactionId][signer] = true;
        emit Confirmation(signer, transactionId);

        // Execute
        executeTransactionBySigner(signer, transactionId);
    }

    // execute transaction on behalf of signer, not msg.sender
    function executeTransactionBySigner(
        address signer,
        uint256 transactionId
    )
        internal
        notExecuted(transactionId)
    {
        if (isConfirmed(transactionId)) {
            Transaction storage txn = transactions[transactionId];
            txn.executed = true;
            if (externalCall(
                txn.destination,
                txn.value,
                txn.data.length,
                txn.data)
            ) {
                emit Execution(transactionId);
            } else {
                emit ExecutionFailure(transactionId);
                txn.executed = false;
            }
        }
    }

    /**
     * Allows an owner to confirm a transaction.
     *
     * @param  transactionId  Transaction ID.
     */
    function confirmTransaction(
        uint256 transactionId
    )
        public
        virtual
        ownerExists(msg.sender)
        transactionExists(transactionId)
        notConfirmed(transactionId, msg.sender)
    {
        confirmations[transactionId][msg.sender] = true;
        emit Confirmation(msg.sender, transactionId);
        executeTransaction(transactionId);
    }

    /**
     * Allows an owner to confirm a transaction via meta transaction.
     *
     * @param  signer           Signer of the meta transaction.
     * @param  transactionId    Transaction ID.
     * @param  sig              Signature.
     */
    function confirmTransaction(
        address signer,
        uint256 transactionId,
        bytes memory sig
    )
        public
        virtual
        ownerExists(signer)
        transactionExists(transactionId)
        notConfirmed(transactionId, signer)
    {
        // CONFIRM_TRANSACTION_TYPE_HASH = keccak256("confirmTransaction(uint256 transactionId)");
        bytes32 EIP712SignDigest = keccak256(
            abi.encodePacked(
                bytes1(0x19),
                bytes1(0x01),
                EIP712_DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        CONFIRM_TRANSACTION_TYPE_HASH,
                        transactionId
                    )
                )
            )
        );
        validateSignature(signer, EIP712SignDigest, sig);

        confirmations[transactionId][signer] = true;
        emit Confirmation(signer, transactionId);
        executeTransactionBySigner(signer, transactionId);
    }

    /**
     * Allows an owner to revoke a confirmation for a transaction.
     *
     * @param  transactionId  Transaction ID.
     */
    function revokeConfirmation(
        uint256 transactionId
    )
        public
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        confirmations[transactionId][msg.sender] = false;
        emit Revocation(msg.sender, transactionId);
    }

    /**
     * Allows an owner to execute a confirmed transaction.
     *
     * @param  transactionId  Transaction ID.
     */
    function executeTransaction(
        uint256 transactionId
    )
        public
        virtual
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        if (isConfirmed(transactionId)) {
            Transaction storage txn = transactions[transactionId];
            txn.executed = true;
            if (externalCall(
                txn.destination,
                txn.value,
                txn.data.length,
                txn.data)
            ) {
                emit Execution(transactionId);
            } else {
                emit ExecutionFailure(transactionId);
                txn.executed = false;
            }
        }
    }

    // ============ Getter Functions ============

    /**
     * Returns the confirmation status of a transaction.
     *
     * @param  transactionId  Transaction ID.
     * @return                Confirmation status.
     */
    function isConfirmed(
        uint256 transactionId
    )
        public
        view
        returns (bool)
    {
        uint256 count = 0;
        for (uint256 i = 0; i < owners.length; i++) {
            if (confirmations[transactionId][owners[i]]) {
                count += 1;
            }
            if (count == required) {
                return true;
            }
        }
    }

    /**
     * Returns number of confirmations of a transaction.
     *
     * @param  transactionId  Transaction ID.
     * @return                Number of confirmations.
     */
    function getConfirmationCount(
        uint256 transactionId
    )
        public
        view
        returns (uint256)
    {
        uint256 count = 0;
        for (uint256 i = 0; i < owners.length; i++) {
            if (confirmations[transactionId][owners[i]]) {
                count += 1;
            }
        }
        return count;
    }

    /**
     * Returns total number of transactions after filers are applied.
     *
     * @param  pending   Include pending transactions.
     * @param  executed  Include executed transactions.
     * @return           Total number of transactions after filters are applied.
     */
    function getTransactionCount(
        bool pending,
        bool executed
    )
        public
        view
        returns (uint256)
    {
        uint256 count = 0;
        for (uint256 i = 0; i < transactionCount; i++) {
            if (
                pending && !transactions[i].executed
                || executed && transactions[i].executed
            ) {
                count += 1;
            }
        }
        return count;
    }

    /**
     * Returns array of owners.
     *
     * @return  Array of owner addresses.
     */
    function getOwners()
        public
        view
        returns (address[] memory)
    {
        return owners;
    }

    /**
     * Returns array with owner addresses, which confirmed transaction.
     *
     * @param  transactionId  Transaction ID.
     * @return                Array of owner addresses.
     */
    function getConfirmations(
        uint256 transactionId
    )
        public
        view
        returns (address[] memory)
    {
        address[] memory confirmationsTemp = new address[](owners.length);
        uint256 count = 0;
        uint256 i;
        for (i = 0; i < owners.length; i++) {
            if (confirmations[transactionId][owners[i]]) {
                confirmationsTemp[count] = owners[i];
                count += 1;
            }
        }
        address[] memory _confirmations = new address[](count);
        for (i = 0; i < count; i++) {
            _confirmations[i] = confirmationsTemp[i];
        }
        return _confirmations;
    }

    /**
     * Returns list of transaction IDs in defined range.
     *
     * @param  from      Index start position of transaction array.
     * @param  to        Index end position of transaction array.
     * @param  pending   Include pending transactions.
     * @param  executed  Include executed transactions.
     * @return           Array of transaction IDs.
     */
    function getTransactionIds(
        uint256 from,
        uint256 to,
        bool pending,
        bool executed
    )
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory transactionIdsTemp = new uint256[](transactionCount);
        uint256 count = 0;
        uint256 i;
        for (i = 0; i < transactionCount; i++) {
            if (
                pending && !transactions[i].executed
                || executed && transactions[i].executed
            ) {
                transactionIdsTemp[count] = i;
                count += 1;
            }
        }
        uint256[] memory _transactionIds = new uint256[](to - from);
        for (i = from; i < to; i++) {
            _transactionIds[i - from] = transactionIdsTemp[i];
        }
        return _transactionIds;
    }

    // ============ Helper Functions ============

    function validateSignature(
        address signer,
        bytes32 digest,
        bytes memory sig
    )
        internal
    {
        require(sig.length == 65);
        uint8 v = uint8(sig[64]);
        bytes32 r = sig.readBytes32(0);
        bytes32 s = sig.readBytes32(32);
        address recovered = ecrecover(digest, v, r, s);
        require(signer == recovered);
    }

    // call has been separated into its own function in order to take advantage
    // of the Solidity's code generator to produce a loop that copies tx.data into memory.
    function externalCall(
        address destination,
        uint256 value,
        uint256 dataLength,
        bytes memory data
    )
        internal
        returns (bool)
    {
        bool result;
        /* solium-disable-next-line security/no-inline-assembly */
        assembly {
            let x := mload(0x40)   // "Allocate" memory for output (0x40 is where "free memory" pointer is stored by convention)
            let d := add(data, 32) // First 32 bytes are the padded length of data, so exclude that
            result := call(
                sub(gas(), 34710),   // 34710 is the value that solidity is currently emitting
                                   // It includes callGas (700) + callVeryLow (3, to pay for SUB) + callValueTransferGas (9000) +
                                   // callNewAccountGas (25000, in case the destination address does not exist and needs creating)
                destination,
                value,
                d,
                dataLength,        // Size of the input (in bytes) - this is what fixes the padding problem
                x,
                0                  // Output is ignored, therefore the output size is zero
            )
        }
        return result;
    }

    /**
     * Adds a new transaction to the transaction mapping, if transaction does not exist yet.
     *
     * @param  destination  Transaction target address.
     * @param  value        Transaction ether value.
     * @param  data         Transaction data payload.
     * @return              Transaction ID.
     */
    function addTransaction(
        address destination,
        uint256 value,
        bytes memory data
    )
        internal
        notNull(destination)
        returns (uint256)
    {
        uint256 transactionId = transactionCount;
        transactions[transactionId] = Transaction({
            destination: destination,
            value: value,
            data: data,
            executed: false
        });
        transactionCount += 1;
        emit Submission(transactionId);
        return transactionId;
    }
}

pragma solidity 0.6.12;

contract MultiSigLibEIP712 {
    /***********************************|
  |             Constants             |
  |__________________________________*/

    // EIP712Domain
    string public constant EIP712_DOMAIN_NAME = "MultiSig";
    string public constant EIP712_DOMAIN_VERSION = "v1";

    // EIP712Domain Separator
    bytes32 public EIP712_DOMAIN_SEPARATOR;

    // SUBMIT_TRANSACTION_TYPE_HASH = keccak256("submitTransaction(uint256 transactionId,address destination,uint256 value,bytes data)");
    bytes32 public constant SUBMIT_TRANSACTION_TYPE_HASH = 0x2c78e27c3bb2592e67e8d37ad1a95bfccd188e77557c22593b1af0b920a08295;

    // CONFIRM_TRANSACTION_TYPE_HASH = keccak256("confirmTransaction(uint256 transactionId)");
    bytes32 public constant CONFIRM_TRANSACTION_TYPE_HASH = 0x3e96bdc38d4133bc81813a187b2d41bc74332643ce7dbe82c7d94ead8366a65f;

    constructor() public {
        EIP712_DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(EIP712_DOMAIN_NAME)),
                keccak256(bytes(EIP712_DOMAIN_VERSION)),
                getChainID(),
                address(this)
            )
        );
    }

    /**
    * @dev Return `chainId`
    */
    function getChainID() internal pure returns (uint) {
        uint chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
}

pragma solidity 0.6.12;

import "./MultiSig.sol";

contract MiningTreasury is MultiSig {
    constructor (
        address[] memory _owners,
        uint256 _required
    )
        public
        MultiSig(_owners, _required)
    {
    }
}

pragma solidity 0.6.12;

import "./MultiSig.sol";

// File: contracts/external/multisig/DelayedMultiSig.sol

/**
 * @title DelayedMultiSig
 * @author dYdX
 *
 * Multi-Signature Wallet with delay in execution.
 * Allows multiple parties to execute a transaction after a time lock has passed.
 * Adapted from Amir Bandeali's MultiSigWalletWithTimeLock contract.

 * Logic Changes:
 *  - Only owners can execute transactions
 *  - Require that each transaction succeeds
 *  - Added function to execute multiple transactions within the same Ethereum transaction
 */
contract DelayedMultiSig is
    MultiSig
{
    // ============ Events ============

    event ConfirmationTimeSet(uint256 indexed transactionId, uint256 confirmationTime);
    event TimeLockChange(uint32 secondsTimeLocked);

    // ============ Storage ============

    uint32 public secondsTimeLocked;
    mapping (uint256 => uint256) public confirmationTimes;

    // ============ Modifiers ============

    modifier notFullyConfirmed(
        uint256 transactionId
    ) {
        require(
            !isConfirmed(transactionId),
            "TX_FULLY_CONFIRMED"
        );
        _;
    }

    modifier fullyConfirmed(
        uint256 transactionId
    ) {
        require(
            isConfirmed(transactionId),
            "TX_NOT_FULLY_CONFIRMED"
        );
        _;
    }

    modifier pastTimeLock(
        uint256 transactionId
    ) virtual {
        require(
            block.timestamp >= confirmationTimes[transactionId] + secondsTimeLocked,
            "TIME_LOCK_INCOMPLETE"
        );
        _;
    }

    // ============ Constructor ============

    /**
     * Contract constructor sets initial owners, required number of confirmations, and time lock.
     *
     * @param  _owners             List of initial owners.
     * @param  _required           Number of required confirmations.
     * @param  _secondsTimeLocked  Duration needed after a transaction is confirmed and before it
     *                             becomes executable, in seconds.
     */
    constructor (
        address[] memory _owners,
        uint256 _required,
        uint32 _secondsTimeLocked
    )
        public
        MultiSig(_owners, _required)
    {
        secondsTimeLocked = _secondsTimeLocked;
    }

    // ============ Wallet-Only Functions ============

    /**
     * Changes the duration of the time lock for transactions.
     *
     * @param  _secondsTimeLocked  Duration needed after a transaction is confirmed and before it
     *                             becomes executable, in seconds.
     */
    function changeTimeLock(
        uint32 _secondsTimeLocked
    )
        public
        onlyWallet
    {
        secondsTimeLocked = _secondsTimeLocked;
        emit TimeLockChange(_secondsTimeLocked);
    }

    // ============ Owner Functions ============

    /**
     * Allows an owner to confirm a transaction.
     * Overrides the function in MultiSig.
     *
     * @param  transactionId  Transaction ID.
     */
    function confirmTransaction(
        uint256 transactionId
    )
        public
        override
        ownerExists(msg.sender)
        transactionExists(transactionId)
        notConfirmed(transactionId, msg.sender)
        notFullyConfirmed(transactionId)
    {
        confirmations[transactionId][msg.sender] = true;
        emit Confirmation(msg.sender, transactionId);
        if (isConfirmed(transactionId)) {
            setConfirmationTime(transactionId, block.timestamp);
        }
    }

    /**
     * Allows an owner to confirm a transaction via meta transaction.
     * Overrides the function in MultiSig.
     *
     * @param  signer           Signer of the meta transaction.
     * @param  transactionId    Transaction ID.
     * @param  sig              Signature.
     */
    function confirmTransaction(
        address signer,
        uint256 transactionId,
        bytes memory sig
    )
        public
        override
        ownerExists(signer)
        transactionExists(transactionId)
        notConfirmed(transactionId, signer)
        notFullyConfirmed(transactionId)
    {
        // CONFIRM_TRANSACTION_TYPE_HASH = keccak256("confirmTransaction(uint256 transactionId)");
        bytes32 EIP712SignDigest = keccak256(
            abi.encodePacked(
                bytes1(0x19),
                bytes1(0x01),
                EIP712_DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        CONFIRM_TRANSACTION_TYPE_HASH,
                        transactionId
                    )
                )
            )
        );
        validateSignature(signer, EIP712SignDigest, sig);

        confirmations[transactionId][signer] = true;
        emit Confirmation(signer, transactionId);
        if (isConfirmed(transactionId)) {
            setConfirmationTime(transactionId, block.timestamp);
        }
    }

    /**
     * Allows an owner to execute a confirmed transaction.
     * Overrides the function in MultiSig.
     *
     * @param  transactionId  Transaction ID.
     */
    function executeTransaction(
        uint256 transactionId
    )
        public
        override
        ownerExists(msg.sender)
        notExecuted(transactionId)
        fullyConfirmed(transactionId)
        pastTimeLock(transactionId)
    {
        Transaction storage txn = transactions[transactionId];
        txn.executed = true;
        bool success = externalCall(
            txn.destination,
            txn.value,
            txn.data.length,
            txn.data
        );
        require(
            success,
            "TX_REVERTED"
        );
        emit Execution(transactionId);
    }

    /**
     * Allows an owner to execute multiple confirmed transactions.
     *
     * @param  transactionIds  List of transaction IDs.
     */
    function executeMultipleTransactions(
        uint256[] memory transactionIds
    )
        public
        ownerExists(msg.sender)
    {
        for (uint256 i = 0; i < transactionIds.length; i++) {
            executeTransaction(transactionIds[i]);
        }
    }

    // ============ Helper Functions ============

    /**
     * Sets the time of when a submission first passed.
     */
    function setConfirmationTime(
        uint256 transactionId,
        uint256 confirmationTime
    )
        internal
    {
        confirmationTimes[transactionId] = confirmationTime;
        emit ConfirmationTimeSet(transactionId, confirmationTime);
    }
}

pragma solidity 0.6.12;

import "./DelayedMultiSig.sol";

// File: contracts/external/multisig/PartiallyDelayedMultiSig.sol

/**
 * @title PartiallyDelayedMultiSig
 * @author dYdX
 *
 * Multi-Signature Wallet with delay in execution except for some function selectors.
 */
contract PartiallyDelayedMultiSig is
    DelayedMultiSig
{
    // ============ Events ============

    event SelectorSet(address destination, bytes4 selector, bool approved);

    // ============ Constants ============

    bytes4 constant internal BYTES_ZERO = bytes4(0x0);

    // ============ Storage ============

    // destination => function selector => can bypass timelock
    mapping (address => mapping (bytes4 => bool)) public instantData;

    // ============ Modifiers ============

    // Overrides old modifier that requires a timelock for every transaction
    modifier pastTimeLock(
        uint256 transactionId
    ) override {
        // if the function selector is not exempt from timelock, then require timelock
        require(
            block.timestamp >= confirmationTimes[transactionId] + secondsTimeLocked
            || txCanBeExecutedInstantly(transactionId),
            "TIME_LOCK_INCOMPLETE"
        );
        _;
    }

    // ============ Constructor ============

    /**
     * Contract constructor sets initial owners, required number of confirmations, and time lock.
     *
     * @param  _owners               List of initial owners.
     * @param  _required             Number of required confirmations.
     * @param  _secondsTimeLocked    Duration needed after a transaction is confirmed and before it
     *                               becomes executable, in seconds.
     * @param  _noDelayDestinations  List of destinations that correspond with the selectors.
     *                               Zero address allows the function selector to be used with any
     *                               address.
     * @param  _noDelaySelectors     All function selectors that do not require a delay to execute.
     *                               Fallback function is 0x00000000.
     */
    constructor (
        address[] memory _owners,
        uint256 _required,
        uint32 _secondsTimeLocked,
        address[] memory _noDelayDestinations,
        bytes4[] memory _noDelaySelectors
    )
        public
        DelayedMultiSig(_owners, _required, _secondsTimeLocked)
    {
        require(
            _noDelayDestinations.length == _noDelaySelectors.length,
            "ADDRESS_AND_SELECTOR_MISMATCH"
        );

        for (uint256 i = 0; i < _noDelaySelectors.length; i++) {
            address destination = _noDelayDestinations[i];
            bytes4 selector = _noDelaySelectors[i];
            instantData[destination][selector] = true;
            emit SelectorSet(destination, selector, true);
        }
    }

    // ============ Wallet-Only Functions ============

    /**
     * Adds or removes functions that can be executed instantly. Transaction must be sent by wallet.
     *
     * @param  destination  Destination address of function. Zero address allows the function to be
     *                      sent to any address.
     * @param  selector     4-byte selector of the function. Fallback function is 0x00000000.
     * @param  approved     True if adding approval, false if removing approval.
     */
    function setSelector(
        address destination,
        bytes4 selector,
        bool approved
    )
        public
        onlyWallet
    {
        instantData[destination][selector] = approved;
        emit SelectorSet(destination, selector, approved);
    }

    // ============ Helper Functions ============

    /**
     * Returns true if transaction can be executed instantly (without timelock).
     */
    function txCanBeExecutedInstantly(
        uint256 transactionId
    )
        internal
        view
        returns (bool)
    {
        // get transaction from storage
        Transaction memory txn = transactions[transactionId];
        address dest = txn.destination;
        bytes memory data = txn.data;

        // fallback function
        if (data.length == 0) {
            return selectorCanBeExecutedInstantly(dest, BYTES_ZERO);
        }

        // invalid function selector
        if (data.length < 4) {
            return false;
        }

        // check first four bytes (function selector)
        bytes32 rawData;
        /* solium-disable-next-line security/no-inline-assembly */
        assembly {
            rawData := mload(add(data, 32))
        }
        bytes4 selector = bytes4(rawData);

        return selectorCanBeExecutedInstantly(dest, selector);
    }

    /**
     * Function selector is in instantData for address dest (or for address zero).
     */
    function selectorCanBeExecutedInstantly(
        address destination,
        bytes4 selector
    )
        internal
        view
        returns (bool)
    {
        return instantData[destination][selector]
            || instantData[ADDRESS_ZERO][selector];
    }
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./LibOrder.sol";
import "../../utils/LibBytes.sol";

contract LibDecoder {
    using LibBytes for bytes;

    function decodeFillOrder(bytes memory data) internal pure returns(LibOrder.Order memory order, uint256 takerFillAmount, bytes memory mmSignature) {
        require(
            data.length > 800,
            "LibDecoder: LENGTH_LESS_800"
        );

        // compare method_id
        // 0x64a3bc15 is fillOrKillOrder's method id.
        require(
            data.readBytes4(0) == 0x64a3bc15,
            "LibDecoder: WRONG_METHOD_ID"
        );
        
        bytes memory dataSlice;
        assembly {
            dataSlice := add(data, 4)
        }
        return abi.decode(dataSlice, (LibOrder.Order, uint256, bytes));

    }

    function decodeMmSignature(bytes memory signature) internal pure returns(uint8 v, bytes32 r, bytes32 s) {
        v = uint8(signature[0]);
        r = signature.readBytes32(1);
        s = signature.readBytes32(33);

        return (v, r, s);
    }

    function decodeUserSignatureWithoutSign(bytes memory signature) internal pure returns(address receiver) {
        require(
            signature.length == 85 || signature.length == 86,
            "LibDecoder: LENGTH_85_REQUIRED"
        );
        receiver = signature.readAddress(65);

        return receiver;
    }

    function decodeUserSignature(bytes memory signature) internal pure returns(uint8 v, bytes32 r, bytes32 s, address receiver) {
        receiver = decodeUserSignatureWithoutSign(signature);

        v = uint8(signature[0]);
        r = signature.readBytes32(1);
        s = signature.readBytes32(33);

        return (v, r, s, receiver);
    }

    function decodeERC20Asset(bytes memory assetData) internal pure returns(address) {
        require(
            assetData.length == 36,
            "LibDecoder: LENGTH_36_REQUIRED"
        );

        return assetData.readAddress(16);
    }
}

/*

  Copyright 2018 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.6.0;

import "./LibEIP712.sol";


contract LibOrder is
    LibEIP712
{
    // Hash for the EIP712 Order Schema
    bytes32 constant internal EIP712_ORDER_SCHEMA_HASH = keccak256(abi.encodePacked(
        "Order(",
        "address makerAddress,",
        "address takerAddress,",
        "address feeRecipientAddress,",
        "address senderAddress,",
        "uint256 makerAssetAmount,",
        "uint256 takerAssetAmount,",
        "uint256 makerFee,",
        "uint256 takerFee,",
        "uint256 expirationTimeSeconds,",
        "uint256 salt,",
        "bytes makerAssetData,",
        "bytes takerAssetData",
        ")"
    ));

    // A valid order remains fillable until it is expired, fully filled, or cancelled.
    // An order's state is unaffected by external factors, like account balances.
    enum OrderStatus {
        INVALID,                     // Default value
        INVALID_MAKER_ASSET_AMOUNT,  // Order does not have a valid maker asset amount
        INVALID_TAKER_ASSET_AMOUNT,  // Order does not have a valid taker asset amount
        FILLABLE,                    // Order is fillable
        EXPIRED,                     // Order has already expired
        FULLY_FILLED,                // Order is fully filled
        CANCELLED                    // Order has been cancelled
    }

    // solhint-disable max-line-length
    struct Order {
        address makerAddress;           // Address that created the order.      
        address takerAddress;           // Address that is allowed to fill the order. If set to 0, any address is allowed to fill the order.          
        address feeRecipientAddress;    // Address that will recieve fees when order is filled.      
        address senderAddress;          // Address that is allowed to call Exchange contract methods that affect this order. If set to 0, any address is allowed to call these methods.
        uint256 makerAssetAmount;       // Amount of makerAsset being offered by maker. Must be greater than 0.        
        uint256 takerAssetAmount;       // Amount of takerAsset being bid on by maker. Must be greater than 0.        
        uint256 makerFee;               // Amount of ZRX paid to feeRecipient by maker when order is filled. If set to 0, no transfer of ZRX from maker to feeRecipient will be attempted.
        uint256 takerFee;               // Amount of ZRX paid to feeRecipient by taker when order is filled. If set to 0, no transfer of ZRX from taker to feeRecipient will be attempted.
        uint256 expirationTimeSeconds;  // Timestamp in seconds at which order expires.          
        uint256 salt;                   // Arbitrary number to facilitate uniqueness of the order's hash.     
        bytes makerAssetData;           // Encoded data that can be decoded by a specified proxy contract when transferring makerAsset. The last byte references the id of this proxy.
        bytes takerAssetData;           // Encoded data that can be decoded by a specified proxy contract when transferring takerAsset. The last byte references the id of this proxy.
    }
    // solhint-enable max-line-length

    struct OrderInfo {
        uint8 orderStatus;                    // Status that describes order's validity and fillability.
        bytes32 orderHash;                    // EIP712 hash of the order (see LibOrder.getOrderHash).
        uint256 orderTakerAssetFilledAmount;  // Amount of order that has already been filled.
    }

    /// @dev Calculates Keccak-256 hash of the order.
    /// @param order The order structure.
    /// @return orderHash Keccak-256 EIP712 hash of the order.
    function getOrderHash(Order memory order)
        internal
        view
        returns (bytes32 orderHash)
    {
        orderHash = hashEIP712Message(hashOrder(order));
        return orderHash;
    }

    /// @dev Calculates EIP712 hash of the order.
    /// @param order The order structure.
    /// @return result EIP712 hash of the order.
    function hashOrder(Order memory order)
        internal
        pure
        returns (bytes32 result)
    {
        bytes32 schemaHash = EIP712_ORDER_SCHEMA_HASH;
        bytes32 makerAssetDataHash = keccak256(order.makerAssetData);
        bytes32 takerAssetDataHash = keccak256(order.takerAssetData);

        // Assembly for more efficiently computing:
        // keccak256(abi.encodePacked(
        //     EIP712_ORDER_SCHEMA_HASH,
        //     bytes32(order.makerAddress),
        //     bytes32(order.takerAddress),
        //     bytes32(order.feeRecipientAddress),
        //     bytes32(order.senderAddress),
        //     order.makerAssetAmount,
        //     order.takerAssetAmount,
        //     order.makerFee,
        //     order.takerFee,
        //     order.expirationTimeSeconds,
        //     order.salt,
        //     keccak256(order.makerAssetData),
        //     keccak256(order.takerAssetData)
        // ));

        assembly {
            // Calculate memory addresses that will be swapped out before hashing
            let pos1 := sub(order, 32)
            let pos2 := add(order, 320)
            let pos3 := add(order, 352)

            // Backup
            let temp1 := mload(pos1)
            let temp2 := mload(pos2)
            let temp3 := mload(pos3)
            
            // Hash in place
            mstore(pos1, schemaHash)
            mstore(pos2, makerAssetDataHash)
            mstore(pos3, takerAssetDataHash)
            result := keccak256(pos1, 416)
            
            // Restore
            mstore(pos1, temp1)
            mstore(pos2, temp2)
            mstore(pos3, temp3)
        }
        return result;
    }
}

/*

  Copyright 2018 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.6.0;


contract LibEIP712 {

    // EIP191 header for EIP712 prefix
    string constant internal EIP191_HEADER = "\x19\x01";

    // EIP712 Domain Name value
    string constant internal EIP712_DOMAIN_NAME = "0x Protocol";

    // EIP712 Domain Version value
    string constant internal EIP712_DOMAIN_VERSION = "2";

    // Hash of the EIP712 Domain Separator Schema
    bytes32 constant internal EIP712_DOMAIN_SEPARATOR_SCHEMA_HASH = keccak256(abi.encodePacked(
        "EIP712Domain(",
        "string name,",
        "string version,",
        "address verifyingContract",
        ")"
    ));

    // Hash of the EIP712 Domain Separator data
    // solhint-disable-next-line var-name-mixedcase
    bytes32 public EIP712_DOMAIN_HASH;

    constructor ()
        public
    {
        EIP712_DOMAIN_HASH = keccak256(abi.encodePacked(
            EIP712_DOMAIN_SEPARATOR_SCHEMA_HASH,
            keccak256(bytes(EIP712_DOMAIN_NAME)),
            keccak256(bytes(EIP712_DOMAIN_VERSION)),
            bytes12(0),
            address(this)
        ));
    }

    /// @dev Calculates EIP712 encoding for a hash struct in this EIP712 Domain.
    /// @param hashStruct The EIP712 hash struct.
    /// @return result EIP712 hash applied to this EIP712 Domain.
    function hashEIP712Message(bytes32 hashStruct)
        internal
        view
        returns (bytes32 result)
    {
        bytes32 eip712DomainHash = EIP712_DOMAIN_HASH;

        // Assembly for more efficient computing:
        // keccak256(abi.encodePacked(
        //     EIP191_HEADER,
        //     EIP712_DOMAIN_HASH,
        //     hashStruct    
        // ));

        assembly {
            // Load free memory pointer
            let memPtr := mload(64)

            mstore(memPtr, 0x1901000000000000000000000000000000000000000000000000000000000000)  // EIP191 header
            mstore(add(memPtr, 2), eip712DomainHash)                                            // EIP712 domain hash
            mstore(add(memPtr, 34), hashStruct)                                                 // Hash of struct

            // Compute hash
            result := keccak256(memPtr, 66)
        }
        return result;
    }
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./pmm/0xLibs/LibOrder.sol";
import "./pmm/0xLibs/LibDecoder.sol";
import "./pmm/0xLibs/LibEncoder.sol";
import "./interfaces/ISpender.sol";
import "./interfaces/IZeroExchange.sol";
import "./interfaces/IWeth.sol";
import "./interfaces/IPMM.sol";
import "./interfaces/IPermanentStorage.sol";
import "./interfaces/IERC1271Wallet.sol";

contract PMM is
    ReentrancyGuard,
    IPMM,
    LibOrder,
    LibDecoder,
    LibEncoder
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;

    // Constants do not have storage slot.
    string public constant version = "5.0.0";
    uint256 private constant MAX_UINT = 2**256 - 1;
    string public constant SOURCE = "0x v2";
    uint256 private constant BPS_MAX = 10000;
    bytes4 constant internal ERC1271_MAGICVALUE_BYTES32 = 0x1626ba7e;  // bytes4(keccak256("isValidSignature(bytes32,bytes)"))
    address public immutable userProxy;
    ISpender public immutable spender;
    IPermanentStorage public immutable permStorage;
    IZeroExchange public immutable zeroExchange;
    address public immutable zxERC20Proxy;

    // Below are the variables which consume storage slots.
    address public operator;

    struct TradeInfo {
        address user;
        address receiver;
        uint16 feeFactor;
        address makerAssetAddr;
        address takerAssetAddr;
        bytes32 transactionHash;
        bytes32 orderHash;
    }

    // events
    event FillOrder(
        string source,
        bytes32 indexed transactionHash,
        bytes32 indexed orderHash,
        address indexed userAddr,
        address takerAssetAddr,
        uint256 takerAssetAmount,
        address makerAddr,
        address makerAssetAddr,
        uint256 makerAssetAmount,
        address receiverAddr,
        uint256 settleAmount,
        uint16 feeFactor
    );


    receive() external payable {}


    /************************************************************
    *          Access control and ownership management          *
    *************************************************************/
    modifier onlyOperator {
        require(operator == msg.sender, "PMM: not operator");
        _;
    }

    modifier onlyUserProxy() {
        require(address(userProxy) == msg.sender, "PMM: not the UserProxy contract");
        _;
    }

    function transferOwnership(address _newOperator) external onlyOperator {
        require(_newOperator != address(0), "AMMWrapper: operator can not be zero address");
        operator = _newOperator;
    }


    /************************************************************
    *              Constructor and init functions               *
    *************************************************************/
    constructor (address _operator, address _userProxy, ISpender _spender, IPermanentStorage _permStorage, IZeroExchange _zeroExchange, address _zxERC20Proxy) public {
        operator = _operator;
        userProxy = _userProxy;
        spender = _spender;
        permStorage = _permStorage;
        zeroExchange = _zeroExchange;
        zxERC20Proxy = _zxERC20Proxy;
        // This constant follows ZX_EXCHANGE address
        EIP712_DOMAIN_HASH = keccak256(
            abi.encodePacked(
                EIP712_DOMAIN_SEPARATOR_SCHEMA_HASH,
                keccak256(bytes(EIP712_DOMAIN_NAME)),
                keccak256(bytes(EIP712_DOMAIN_VERSION)),
                bytes12(0),
                address(_zeroExchange)
            )
        );
    }


    /************************************************************
    *           Management functions for Operator               *
    *************************************************************/
    /**
     * @dev approve spender to transfer tokens from this contract. This is used to collect fee.
     */
    function setAllowance(address[] calldata _tokenList, address _spender) override external onlyOperator {
        for (uint256 i = 0 ; i < _tokenList.length; i++) {
            IERC20(_tokenList[i]).safeApprove(_spender, MAX_UINT);
        }
    }

    function closeAllowance(address[] calldata _tokenList, address _spender) override external onlyOperator {
        for (uint256 i = 0 ; i < _tokenList.length; i++) {
            IERC20(_tokenList[i]).safeApprove(_spender, 0);
        }
    }


    /************************************************************
    *                   External functions                      *
    *************************************************************/
    function fill(
        uint256 userSalt,
        bytes memory data,
        bytes memory userSignature
    )
        override
        public
        payable
        onlyUserProxy
        nonReentrant
        returns (uint256)
    {
        // decode & assert
        (LibOrder.Order memory order,
        TradeInfo memory tradeInfo) = _assertTransaction(userSalt, data, userSignature);

        // Deposit to WETH if taker asset is ETH, else transfer from user
        IWETH weth = IWETH(permStorage.wethAddr());
        if (address(weth) == tradeInfo.takerAssetAddr) {
            require(
                msg.value == order.takerAssetAmount,
                "PMM: insufficient ETH"
            );
            weth.deposit{value: msg.value}();
        } else {
            spender.spendFromUser(tradeInfo.user, tradeInfo.takerAssetAddr, order.takerAssetAmount);
        }

        IERC20(tradeInfo.takerAssetAddr).safeIncreaseAllowance(zxERC20Proxy, order.takerAssetAmount);

        // send tx to 0x
        zeroExchange.executeTransaction(
            userSalt,
            address(this),
            data,
            ""
        );

        // settle token/ETH to user
        uint256 settleAmount = _settle(weth, tradeInfo.receiver, tradeInfo.makerAssetAddr, order.makerAssetAmount, tradeInfo.feeFactor);
        IERC20(tradeInfo.takerAssetAddr).safeApprove(zxERC20Proxy, 0);

        emit FillOrder(
            SOURCE,
            tradeInfo.transactionHash,
            tradeInfo.orderHash,
            tradeInfo.user,
            tradeInfo.takerAssetAddr,
            order.takerAssetAmount,
            order.makerAddress,
            tradeInfo.makerAssetAddr,
            order.makerAssetAmount,
            tradeInfo.receiver,
            settleAmount,
            tradeInfo.feeFactor
        );
        return settleAmount;
    }

    /**
     * @dev internal function of `fill`.
     * It decodes and validates transaction data.
     */
    function _assertTransaction(
        uint256 userSalt,
        bytes memory data,
        bytes memory userSignature
    )
        internal
        view
        returns(
            LibOrder.Order memory order,
            TradeInfo memory tradeInfo
        )
    {
        // decode fillOrder data
        uint256 takerFillAmount;
        bytes memory mmSignature;
        (order, takerFillAmount, mmSignature) = decodeFillOrder(data);

        require(
            order.takerAddress == address(this),
            "PMM: incorrect taker"
        );
        require(
            order.takerAssetAmount == takerFillAmount,
            "PMM: incorrect fill amount"
        );

        // generate transactionHash
        tradeInfo.transactionHash = encodeTransactionHash(
            userSalt,
            address(this),
            data
        );

        tradeInfo.orderHash = getOrderHash(order);
        tradeInfo.feeFactor = uint16(order.salt);
        tradeInfo.receiver = decodeUserSignatureWithoutSign(userSignature);
        tradeInfo.user = _ecrecoverAddress(tradeInfo.transactionHash, userSignature);

        if (tradeInfo.user != order.feeRecipientAddress) {
            require(
                order.feeRecipientAddress.isContract(),
                "PMM: invalid contract address"
            );
            // isValidSignature() should return magic value: bytes4(keccak256("isValidSignature(bytes32,bytes)"))
            require(
                ERC1271_MAGICVALUE_BYTES32 == IERC1271Wallet(order.feeRecipientAddress)
                    .isValidSignature(
                        tradeInfo.transactionHash,
                        userSignature
                    ),
                "PMM: invalid ERC1271 signer"
            );
            tradeInfo.user = order.feeRecipientAddress;
        }

        require(
            tradeInfo.feeFactor < BPS_MAX,
            "PMM: invalid fee factor"
        );

        require(
            tradeInfo.receiver != address(0),
            "PMM: invalid receiver"
        );

        // decode asset
        // just support ERC20
        tradeInfo.makerAssetAddr = decodeERC20Asset(order.makerAssetData);
        tradeInfo.takerAssetAddr = decodeERC20Asset(order.takerAssetData);
        return (
            order,
            tradeInfo
        );        
    }

    // settle
    function _settle(IWETH weth, address receiver, address makerAssetAddr, uint256 makerAssetAmount, uint16 feeFactor) internal returns(uint256) {
        uint256 settleAmount = makerAssetAmount;
        if (feeFactor > 0) {
            // settleAmount = settleAmount * (10000 - feeFactor) / 10000
            settleAmount = settleAmount.mul((BPS_MAX).sub(feeFactor)).div(BPS_MAX);
        }

        if (makerAssetAddr == address(weth)){
            weth.withdraw(settleAmount);
            payable(receiver).transfer(settleAmount);
        } else {
            IERC20(makerAssetAddr).safeTransfer(receiver, settleAmount);
        }

        return settleAmount;
    }

    function _ecrecoverAddress(bytes32 transactionHash, bytes memory signature) internal pure returns (address){
        (uint8 v, bytes32 r, bytes32 s, address receiver) = decodeUserSignature(signature);
        return ecrecover(
            keccak256(
                abi.encodePacked(
                    transactionHash,
                    receiver
                )),
            v, r, s
        );
    }
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./LibEIP712.sol";

contract LibEncoder is
    LibEIP712
{
    // Hash for the EIP712 ZeroEx Transaction Schema
    bytes32 constant internal EIP712_ZEROEX_TRANSACTION_SCHEMA_HASH = keccak256(
        abi.encodePacked(
        "ZeroExTransaction(",
        "uint256 salt,",
        "address signerAddress,",
        "bytes data",
        ")"
    ));

    function encodeTransactionHash(
        uint256 salt,
        address signerAddress,
        bytes memory data
    )
        internal
        view 
        returns (bytes32 result)
    {
        bytes32 schemaHash = EIP712_ZEROEX_TRANSACTION_SCHEMA_HASH;
        bytes32 dataHash = keccak256(data);

        // Assembly for more efficiently computing:
        // keccak256(abi.encodePacked(
        //     EIP712_ZEROEX_TRANSACTION_SCHEMA_HASH,
        //     salt,
        //     bytes32(signerAddress),
        //     keccak256(data)
        // ));

        assembly {
            // Load free memory pointer
            let memPtr := mload(64)

            mstore(memPtr, schemaHash)                                                               // hash of schema
            mstore(add(memPtr, 32), salt)                                                            // salt
            mstore(add(memPtr, 64), and(signerAddress, 0xffffffffffffffffffffffffffffffffffffffff))  // signerAddress
            mstore(add(memPtr, 96), dataHash)                                                        // hash of data

            // Compute hash
            result := keccak256(memPtr, 128)
        }
        result = hashEIP712Message(result);
        return result;
    }
}

/*
  Copyright 2018 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

interface IZeroExchange {
    function executeTransaction(
        uint256 salt,
        address signerAddress,
        bytes calldata data,
        bytes calldata signature
    ) external;
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../pmm/0xLibs/LibOrder.sol";
import "./ISetAllowance.sol";

interface IPMM is ISetAllowance {
    function fill(
        uint256 userSalt,
        bytes memory data,
        bytes memory userSignature
    ) external payable returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.5;

import "../interfaces/IPermanentStorage.sol";
import "../utils/lib_storage/PSStorage.sol";

contract PermanentStorageStub is IPermanentStorage {

    // Supported Curve pools
    address public constant CURVE_COMPOUND_POOL = 0xA2B47E3D5c44877cca798226B7B8118F9BFb7A56;
    address public constant CURVE_USDT_POOL = 0x52EA46506B9CC5Ef470C5bf89f17Dc28bB35D85C;
    address public constant CURVE_Y_POOL = 0x45F783CCE6B7FF23B2ab2D70e416cdb7D6055f51;
    address public constant CURVE_3_POOL = 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;
    address public constant CURVE_sUSD_POOL = 0xA5407eAE9Ba41422680e2e00537571bcC53efBfD;
    address public constant CURVE_BUSD_POOL = 0x79a8C46DeA5aDa233ABaFFD40F3A0A2B1e5A4F27;
    address public constant CURVE_renBTC_POOL = 0x93054188d876f558f4a66B2EF1d97d16eDf0895B;
    address public constant CURVE_sBTC_POOL = 0x7fC77b5c7614E1533320Ea6DDc2Eb61fa00A9714;
    address public constant CURVE_hBTC_POOL = 0x4CA9b3063Ec5866A4B82E437059D2C43d1be596F;
    address public constant CURVE_sETH_POOL = 0xc5424B857f758E906013F3555Dad202e4bdB4567;

    // Curve coins
    address private constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address private constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address private constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address private constant cDAI = 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643;
    address private constant cUSDC = 0x39AA39c021dfbaE8faC545936693aC917d5E7563;
    address private constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address private constant TUSD = 0x0000000000085d4780B73119b644AE5ecd22b376;
    address private constant Y_POOL_yDAI = 0x16de59092dAE5CcF4A1E6439D611fd0653f0Bd01;
    address private constant Y_POOL_yUSDC = 0xd6aD7a6750A7593E092a9B218d66C0A814a3436e;
    address private constant Y_POOL_yUSDT = 0x83f798e925BcD4017Eb265844FDDAbb448f1707D;
    address private constant Y_POOL_yTUSD = 0x73a052500105205d34Daf004eAb301916DA8190f;
    address private constant sUSD = 0x57Ab1ec28D129707052df4dF418D58a2D46d5f51;
    address private constant BUSD = 0x4Fabb145d64652a948d72533023f6E7A623C7C53;
    address private constant BUSD_POOL_yDAI = 0xC2cB1040220768554cf699b0d863A3cd4324ce32;
    address private constant BUSD_POOL_yUSDC = 0x26EA744E5B887E5205727f55dFBE8685e3b21951;
    address private constant BUSD_POOL_yUSDT = 0xE6354ed5bC4b393a5Aad09f21c46E101e692d447;
    address private constant BUSD_POOL_yBUSD = 0x04bC0Ab673d88aE9dbC9DA2380cB6B79C4BCa9aE;
    address private constant renBTC = 0xEB4C2781e4ebA804CE9a9803C67d0893436bB27D;
    address private constant wBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address private constant sBTC = 0xfE18be6b3Bd88A2D2A7f928d00292E7a9963CfC6;
    address private constant hBTC = 0x0316EB71485b0Ab14103307bf65a021042c6d380;
    address private constant sETH = 0x5e74C9036fb86BD7eCdcb084a0673EFc32eA31cb;

    constructor() public {
        // register WETH address
        PSStorage.getStorage().wethAddr = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        // register Compound pool
        // underlying_coins, exchange_underlying
        AMMWrapperStorage.getStorage().curveTokenIndexes[CURVE_COMPOUND_POOL][DAI] = 1;
        AMMWrapperStorage.getStorage().curveTokenIndexes[CURVE_COMPOUND_POOL][USDC] = 2;
        // coins, exchange
        AMMWrapperStorage.getStorage().curveWrappedTokenIndexes[CURVE_COMPOUND_POOL][cDAI] = 1;
        AMMWrapperStorage.getStorage().curveWrappedTokenIndexes[CURVE_COMPOUND_POOL][cUSDC] = 2;
        AMMWrapperStorage.getStorage().curveSupportGetDx[CURVE_COMPOUND_POOL] = true; // support get_dx or get_dx_underlying for quoting

        // register USDT pool
        // underlying_coins, exchange_underlying
        AMMWrapperStorage.getStorage().curveTokenIndexes[CURVE_USDT_POOL][DAI] = 1;
        AMMWrapperStorage.getStorage().curveTokenIndexes[CURVE_USDT_POOL][USDC] = 2;
        AMMWrapperStorage.getStorage().curveTokenIndexes[CURVE_USDT_POOL][USDT] = 3;
        // coins, exchange
        AMMWrapperStorage.getStorage().curveWrappedTokenIndexes[CURVE_USDT_POOL][cDAI] = 1;
        AMMWrapperStorage.getStorage().curveWrappedTokenIndexes[CURVE_USDT_POOL][cUSDC] = 2;
        AMMWrapperStorage.getStorage().curveWrappedTokenIndexes[CURVE_USDT_POOL][USDT] = 3;
        AMMWrapperStorage.getStorage().curveSupportGetDx[CURVE_USDT_POOL] = true;

        // register Y pool
        // underlying_coins, exchange_underlying
        AMMWrapperStorage.getStorage().curveTokenIndexes[CURVE_Y_POOL][DAI] = 1;
        AMMWrapperStorage.getStorage().curveTokenIndexes[CURVE_Y_POOL][USDC] = 2;
        AMMWrapperStorage.getStorage().curveTokenIndexes[CURVE_Y_POOL][USDT] = 3;
        AMMWrapperStorage.getStorage().curveTokenIndexes[CURVE_Y_POOL][TUSD] = 4;
        // coins, exchange
        AMMWrapperStorage.getStorage().curveWrappedTokenIndexes[CURVE_Y_POOL][Y_POOL_yDAI] = 1;
        AMMWrapperStorage.getStorage().curveWrappedTokenIndexes[CURVE_Y_POOL][Y_POOL_yUSDC] = 2;
        AMMWrapperStorage.getStorage().curveWrappedTokenIndexes[CURVE_Y_POOL][Y_POOL_yUSDT] = 3;
        AMMWrapperStorage.getStorage().curveWrappedTokenIndexes[CURVE_Y_POOL][Y_POOL_yTUSD] = 4;
        AMMWrapperStorage.getStorage().curveSupportGetDx[CURVE_Y_POOL] = true;

        // register 3 pool
        // coins, exchange
        AMMWrapperStorage.getStorage().curveWrappedTokenIndexes[CURVE_3_POOL][DAI] = 1;
        AMMWrapperStorage.getStorage().curveWrappedTokenIndexes[CURVE_3_POOL][USDC] = 2;
        AMMWrapperStorage.getStorage().curveWrappedTokenIndexes[CURVE_3_POOL][USDT] = 3;
        AMMWrapperStorage.getStorage().curveSupportGetDx[CURVE_3_POOL] = false; // only support get_dy and get_dy_underlying for exactly the same functionality

        // register sUSD pool
        // coins, exchange
        AMMWrapperStorage.getStorage().curveWrappedTokenIndexes[CURVE_sUSD_POOL][DAI] = 1;
        AMMWrapperStorage.getStorage().curveWrappedTokenIndexes[CURVE_sUSD_POOL][USDC] = 2;
        AMMWrapperStorage.getStorage().curveWrappedTokenIndexes[CURVE_sUSD_POOL][USDT] = 3;
        AMMWrapperStorage.getStorage().curveWrappedTokenIndexes[CURVE_sUSD_POOL][sUSD] = 4;
        AMMWrapperStorage.getStorage().curveSupportGetDx[CURVE_sUSD_POOL] = false;

        // register BUSD pool
        // underlying_coins, exchange_underlying
        AMMWrapperStorage.getStorage().curveTokenIndexes[CURVE_BUSD_POOL][DAI] = 1;
        AMMWrapperStorage.getStorage().curveTokenIndexes[CURVE_BUSD_POOL][USDC] = 2;
        AMMWrapperStorage.getStorage().curveTokenIndexes[CURVE_BUSD_POOL][USDT] = 3;
        AMMWrapperStorage.getStorage().curveTokenIndexes[CURVE_BUSD_POOL][BUSD] = 4;
        // coins, exchange
        AMMWrapperStorage.getStorage().curveWrappedTokenIndexes[CURVE_BUSD_POOL][BUSD_POOL_yDAI] = 1;
        AMMWrapperStorage.getStorage().curveWrappedTokenIndexes[CURVE_BUSD_POOL][BUSD_POOL_yUSDC] = 2;
        AMMWrapperStorage.getStorage().curveWrappedTokenIndexes[CURVE_BUSD_POOL][BUSD_POOL_yUSDT] = 3;
        AMMWrapperStorage.getStorage().curveWrappedTokenIndexes[CURVE_BUSD_POOL][BUSD_POOL_yBUSD] = 4;
        AMMWrapperStorage.getStorage().curveSupportGetDx[CURVE_BUSD_POOL] = true;

        // register renBTC pool
        // coins, exchange
        AMMWrapperStorage.getStorage().curveWrappedTokenIndexes[CURVE_renBTC_POOL][renBTC] = 1; // renBTC
        AMMWrapperStorage.getStorage().curveWrappedTokenIndexes[CURVE_renBTC_POOL][wBTC] = 2; // wBTC
        AMMWrapperStorage.getStorage().curveSupportGetDx[CURVE_renBTC_POOL] = false;

        // register sBTC pool
        // coins, exchange
        AMMWrapperStorage.getStorage().curveWrappedTokenIndexes[CURVE_sBTC_POOL][renBTC] = 1; // renBTC
        AMMWrapperStorage.getStorage().curveWrappedTokenIndexes[CURVE_sBTC_POOL][wBTC] = 2; // wBTC
        AMMWrapperStorage.getStorage().curveWrappedTokenIndexes[CURVE_sBTC_POOL][sBTC] = 3; // sBTC
        AMMWrapperStorage.getStorage().curveSupportGetDx[CURVE_sBTC_POOL] = false;

        // register hBTC pool
        // coins, exchange
        AMMWrapperStorage.getStorage().curveWrappedTokenIndexes[CURVE_hBTC_POOL][hBTC] = 1; // hBTC
        AMMWrapperStorage.getStorage().curveWrappedTokenIndexes[CURVE_hBTC_POOL][wBTC] = 2; // wBTC
        AMMWrapperStorage.getStorage().curveSupportGetDx[CURVE_hBTC_POOL] = false;

        // register sETH pool
        // coins, exchange
        AMMWrapperStorage.getStorage().curveWrappedTokenIndexes[CURVE_sETH_POOL][ETH] = 1; // ETH
        AMMWrapperStorage.getStorage().curveWrappedTokenIndexes[CURVE_sETH_POOL][sETH] = 2; // sETH
        AMMWrapperStorage.getStorage().curveSupportGetDx[CURVE_sETH_POOL] = false;
    }

    /************************************************************
    *                     Getter functions                      *
    *************************************************************/
    function ammWrapperAddr() public view returns (address) {
        return PSStorage.getStorage().ammWrapperAddr;
    }

    function pmmAddr() public view returns (address) {
        return PSStorage.getStorage().pmmAddr;
    }

    function rfqAddr() public view returns (address) {
        return PSStorage.getStorage().rfqAddr;
    }

    function wethAddr() override external view returns (address) {
        return PSStorage.getStorage().wethAddr;
    }

    function getCurvePoolInfo(address _makerAddr, address _takerAssetAddr, address _makerAssetAddr) override external view returns (int128 takerAssetIndex, int128 makerAssetIndex, uint16 swapMethod, bool supportGetDx) {
        // underlying_coins
        int128 i = AMMWrapperStorage.getStorage().curveTokenIndexes[_makerAddr][_takerAssetAddr];
        int128 j = AMMWrapperStorage.getStorage().curveTokenIndexes[_makerAddr][_makerAssetAddr];
        supportGetDx = AMMWrapperStorage.getStorage().curveSupportGetDx[_makerAddr];

        swapMethod = 0;
        if (i != 0 && j != 0) {
            // in underlying_coins list
            takerAssetIndex = i;
            makerAssetIndex = j;
            // exchange_underlying
            swapMethod = 2;
        } else {
            // in coins list
            int128 iWrapped = AMMWrapperStorage.getStorage().curveWrappedTokenIndexes[_makerAddr][_takerAssetAddr];
            int128 jWrapped = AMMWrapperStorage.getStorage().curveWrappedTokenIndexes[_makerAddr][_makerAssetAddr];
            if (iWrapped != 0 && jWrapped != 0) {
                takerAssetIndex = iWrapped;
                makerAssetIndex = jWrapped;
                // exchange
                swapMethod = 1;
            } else {
                revert("PermanentStorage: invalid pair");
            }
        }
        return (takerAssetIndex, makerAssetIndex, swapMethod, supportGetDx);
    }

    function isTransactionSeen(bytes32 _transactionHash) override external view returns (bool) {
        return AMMWrapperStorage.getStorage().transactionSeen[_transactionHash];
    }

    function isAMMTransactionSeen(bytes32 _transactionHash) override external view returns (bool) {
        return AMMWrapperStorage.getStorage().transactionSeen[_transactionHash];
    }

    function isRFQTransactionSeen(bytes32 _transactionHash) override external view returns (bool) {
        return RFQStorage.getStorage().transactionSeen[_transactionHash];
    }

    function isRelayerValid(address _relayer) override external view returns (bool) {
        return AMMWrapperStorage.getStorage().relayerValid[_relayer];
    }


    /************************************************************
    *           Management functions for Operator               *
    *************************************************************/
    /// @dev Update AMMWrapper contract address.
    function upgradeAMMWrapper(address _newAMMWrapper) external {
        PSStorage.getStorage().ammWrapperAddr = _newAMMWrapper;
    }

    /// @dev Update PMM contract address.
    function upgradePMM(address _newPMM) external {
        PSStorage.getStorage().pmmAddr = _newPMM;
    }

    /// @dev Update RFQ contract address.
    function upgradeRFQ(address _newRFQ) external {
        PSStorage.getStorage().rfqAddr = _newRFQ;
    }

    /// @dev Update WETH contract address.
    function upgradeWETH(address _newWETH) external {
        PSStorage.getStorage().wethAddr = _newWETH;
    }


    /************************************************************
    *                   External functions                      *
    *************************************************************/
    function setCurvePoolInfo(address _makerAddr, address[] calldata _underlyingCoins, address[] calldata _coins, bool _supportGetDx) override external {
        int128 underlyingCoinsLength = int128(_underlyingCoins.length);
        for (int128 i = 0 ; i < underlyingCoinsLength; i++) {
            address assetAddr = _underlyingCoins[uint256(i)];
            // underlying coins for original DAI, USDC, TUSD
            AMMWrapperStorage.getStorage().curveTokenIndexes[_makerAddr][assetAddr] = i + 1;
        }

        int128 coinsLength = int128(_coins.length);
        for (int128 i = 0 ; i < coinsLength; i++) {
            address assetAddr = _coins[uint256(i)];
            // wrapped coins for cDAI, cUSDC, yDAI, yUSDC, yTUSD, yBUSD
            AMMWrapperStorage.getStorage().curveWrappedTokenIndexes[_makerAddr][assetAddr] = i + 1;
        }

        AMMWrapperStorage.getStorage().curveSupportGetDx[_makerAddr] = _supportGetDx;
    }

    function setTransactionSeen(bytes32 _transactionHash) override external {
        require(!AMMWrapperStorage.getStorage().transactionSeen[_transactionHash], "PermanentStorage: transaction seen before");
        AMMWrapperStorage.getStorage().transactionSeen[_transactionHash] = true;
    }

    function setAMMTransactionSeen(bytes32 _transactionHash) override external {
        require(!AMMWrapperStorage.getStorage().transactionSeen[_transactionHash], "PermanentStorage: transaction seen before");
        AMMWrapperStorage.getStorage().transactionSeen[_transactionHash] = true;
    }

    function setRFQTransactionSeen(bytes32 _transactionHash) override external {
        require(!RFQStorage.getStorage().transactionSeen[_transactionHash], "PermanentStorage: transaction seen before");
        RFQStorage.getStorage().transactionSeen[_transactionHash] = true;
    }

    function setRelayersValid(address[] calldata _relayers, bool[] calldata _isValids) override external {
        require(_relayers.length == _isValids.length, "PermanentStorage: inputs length mismatch");
        for (uint256 i = 0; i < _relayers.length; i++) {
            AMMWrapperStorage.getStorage().relayerValid[_relayers[i]] = _isValids[i];
        }
    }
}

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

library PSStorage {
    bytes32 private constant STORAGE_SLOT = 0x92dd52b981a2dd69af37d8a3febca29ed6a974aede38ae66e4ef773173aba471;

    struct Storage {
        address ammWrapperAddr;
        address pmmAddr;
        address wethAddr;
        address rfqAddr;
    }

    /// @dev Get the storage bucket for this contract.
    function getStorage() internal pure returns (Storage storage stor) {
        assert(STORAGE_SLOT == bytes32(uint256(keccak256("permanent.storage.storage")) - 1));
        bytes32 slot = STORAGE_SLOT;

        // Dip into assembly to change the slot pointed to by the local
        // variable `stor`.
        // See https://solidity.readthedocs.io/en/v0.6.8/assembly.html?highlight=slot#access-to-external-variables-functions-and-libraries
        assembly { stor_slot := slot }
    }
}

library AMMWrapperStorage {
    bytes32 private constant STORAGE_SLOT = 0xd38d862c9fa97c2fa857a46e08022d272a3579c114ca4f335f1e5fcb692c045e;

    struct Storage {
        mapping(bytes32 => bool) transactionSeen;
        // curve pool => underlying token address => underlying token index
        mapping(address => mapping(address => int128)) curveTokenIndexes;
        mapping(address => bool) relayerValid;
        // 5.1.0 appended storage
        // curve pool => wrapped token address => wrapped token index
        mapping(address => mapping(address => int128)) curveWrappedTokenIndexes;
        mapping(address => bool) curveSupportGetDx;
    }

    /// @dev Get the storage bucket for this contract.
    function getStorage() internal pure returns (Storage storage stor) {
        assert(STORAGE_SLOT == bytes32(uint256(keccak256("permanent.ammwrapper.storage")) - 1));
        bytes32 slot = STORAGE_SLOT;

        // Dip into assembly to change the slot pointed to by the local
        // variable `stor`.
        // See https://solidity.readthedocs.io/en/v0.6.8/assembly.html?highlight=slot#access-to-external-variables-functions-and-libraries
        assembly { stor_slot := slot }
    }
}

library RFQStorage {
    bytes32 private constant STORAGE_SLOT = 0x9174e76494cfb023ddc1eb0effb6c12e107165382bbd0ecfddbc38ea108bbe52;

    struct Storage {
        mapping(bytes32 => bool) transactionSeen;
    }

    /// @dev Get the storage bucket for this contract.
    function getStorage() internal pure returns (Storage storage stor) {
        assert(STORAGE_SLOT == bytes32(uint256(keccak256("permanent.rfq.storage")) - 1));
        bytes32 slot = STORAGE_SLOT;

        // Dip into assembly to change the slot pointed to by the local
        // variable `stor`.
        // See https://solidity.readthedocs.io/en/v0.6.8/assembly.html?highlight=slot#access-to-external-variables-functions-and-libraries
        assembly { stor_slot := slot }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.5;

import "./interfaces/IPermanentStorage.sol";
import "./utils/lib_storage/PSStorage.sol";

contract PermanentStorage is IPermanentStorage {

    // Constants do not have storage slot.
    bytes32 public constant curveTokenIndexStorageId = 0xf4c750cdce673f6c35898d215e519b86e3846b1f0532fb48b84fe9d80f6de2fc; // keccak256("curveTokenIndex")
    bytes32 public constant transactionSeenStorageId = 0x695d523b8578c6379a2121164fd8de334b9c5b6b36dff5408bd4051a6b1704d0;  // keccak256("transactionSeen")
    bytes32 public constant relayerValidStorageId = 0x2c97779b4deaf24e9d46e02ec2699240a957d92782b51165b93878b09dd66f61;  // keccak256("relayerValid")

    // New supported Curve pools
    address public constant CURVE_renBTC_POOL = 0x93054188d876f558f4a66B2EF1d97d16eDf0895B;
    address public constant CURVE_sBTC_POOL = 0x7fC77b5c7614E1533320Ea6DDc2Eb61fa00A9714;
    address public constant CURVE_hBTC_POOL = 0x4CA9b3063Ec5866A4B82E437059D2C43d1be596F;
    address public constant CURVE_sETH_POOL = 0xc5424B857f758E906013F3555Dad202e4bdB4567;

    // Curve coins
    address private constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address private constant renBTC = 0xEB4C2781e4ebA804CE9a9803C67d0893436bB27D;
    address private constant wBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address private constant sBTC = 0xfE18be6b3Bd88A2D2A7f928d00292E7a9963CfC6;
    address private constant hBTC = 0x0316EB71485b0Ab14103307bf65a021042c6d380;
    address private constant sETH = 0x5e74C9036fb86BD7eCdcb084a0673EFc32eA31cb;

    // Below are the variables which consume storage slots.
    address public operator;
    string public version;  // Current version of the contract
    mapping(bytes32 => mapping(address => bool)) private permission;


    // Operator events
    event TransferOwnership(address newOperator);
    event SetPermission(bytes32 storageId, address role, bool enabled);
    event UpgradeAMMWrapper(address newAMMWrapper);
    event UpgradePMM(address newPMM);
    event UpgradeRFQ(address newRFQ);
    event UpgradeWETH(address newWETH);


    /************************************************************
    *          Access control and ownership management          *
    *************************************************************/
    modifier onlyOperator() {
        require(operator == msg.sender, "PermanentStorage: not the operator");
        _;
    }

    modifier validRole(bool _enabled, address _role) {
        if (_enabled) {
            require(
                (_role == operator) || (_role == ammWrapperAddr()) || (_role == pmmAddr() || (_role == rfqAddr())),
                "PermanentStorage: not a valid role"
            );
        }
        _;
    }

    modifier isPermitted(bytes32 _storageId, address _role) {
        require(permission[_storageId][_role], "PermanentStorage: has no permission");
        _;
    }


    function transferOwnership(address _newOperator) external onlyOperator {
        require(_newOperator != address(0), "PermanentStorage: operator can not be zero address");
        operator = _newOperator;

        emit TransferOwnership(_newOperator);
    }

    /// @dev Set permission for entity to write certain storage.
    function setPermission(bytes32 _storageId, address _role, bool _enabled) external onlyOperator validRole(_enabled, _role) {
        permission[_storageId][_role] = _enabled;

        emit SetPermission(_storageId, _role, _enabled);
    }


    /************************************************************
    *              Constructor and init functions               *
    *************************************************************/
    /// @dev Replacing constructor and initialize the contract. This function should only be called once.
    function initialize() external {
        require(
            keccak256(abi.encodePacked(version)) == keccak256(abi.encodePacked("5.1.0")),
            "PermanentStorage: not upgrading from 5.1.0 version"
        );
        // upgrade from 5.1.0 to 5.2.0
        version = "5.2.0";
        // register renBTC pool
        // coins, exchange
        AMMWrapperStorage.getStorage().curveWrappedTokenIndexes[CURVE_renBTC_POOL][renBTC] = 1; // renBTC
        AMMWrapperStorage.getStorage().curveWrappedTokenIndexes[CURVE_renBTC_POOL][wBTC] = 2; // wBTC
        AMMWrapperStorage.getStorage().curveSupportGetDx[CURVE_renBTC_POOL] = false;

        // register sBTC pool
        // coins, exchange
        AMMWrapperStorage.getStorage().curveWrappedTokenIndexes[CURVE_sBTC_POOL][renBTC] = 1; // renBTC
        AMMWrapperStorage.getStorage().curveWrappedTokenIndexes[CURVE_sBTC_POOL][wBTC] = 2; // wBTC
        AMMWrapperStorage.getStorage().curveWrappedTokenIndexes[CURVE_sBTC_POOL][sBTC] = 3; // sBTC
        AMMWrapperStorage.getStorage().curveSupportGetDx[CURVE_sBTC_POOL] = false;

        // register hBTC pool
        // coins, exchange
        AMMWrapperStorage.getStorage().curveWrappedTokenIndexes[CURVE_hBTC_POOL][hBTC] = 1; // hBTC
        AMMWrapperStorage.getStorage().curveWrappedTokenIndexes[CURVE_hBTC_POOL][wBTC] = 2; // wBTC
        AMMWrapperStorage.getStorage().curveSupportGetDx[CURVE_hBTC_POOL] = false;

        // register sETH pool
        // coins, exchange
        AMMWrapperStorage.getStorage().curveWrappedTokenIndexes[CURVE_sETH_POOL][ETH] = 1; // ETH
        AMMWrapperStorage.getStorage().curveWrappedTokenIndexes[CURVE_sETH_POOL][sETH] = 2; // sETH
        AMMWrapperStorage.getStorage().curveSupportGetDx[CURVE_sETH_POOL] = false;
    }


    /************************************************************
    *                     Getter functions                      *
    *************************************************************/
    function hasPermission(bytes32 _storageId, address _role) external view returns (bool) {
        return permission[_storageId][_role];
    }

    function ammWrapperAddr() public view returns (address) {
        return PSStorage.getStorage().ammWrapperAddr;
    }

    function pmmAddr() public view returns (address) {
        return PSStorage.getStorage().pmmAddr;
    }

    function rfqAddr() public view returns (address) {
        return PSStorage.getStorage().rfqAddr;
    }

    function wethAddr() override external view returns (address) {
        return PSStorage.getStorage().wethAddr;
    }

    function getCurvePoolInfo(address _makerAddr, address _takerAssetAddr, address _makerAssetAddr) override external view returns (int128 takerAssetIndex, int128 makerAssetIndex, uint16 swapMethod, bool supportGetDx) {
        // underlying_coins
        int128 i = AMMWrapperStorage.getStorage().curveTokenIndexes[_makerAddr][_takerAssetAddr];
        int128 j = AMMWrapperStorage.getStorage().curveTokenIndexes[_makerAddr][_makerAssetAddr];
        supportGetDx = AMMWrapperStorage.getStorage().curveSupportGetDx[_makerAddr];

        swapMethod = 0;
        if (i != 0 && j != 0) {
            // in underlying_coins list
            takerAssetIndex = i;
            makerAssetIndex = j;
            // exchange_underlying
            swapMethod = 2;
        } else {
            // in coins list
            int128 iWrapped = AMMWrapperStorage.getStorage().curveWrappedTokenIndexes[_makerAddr][_takerAssetAddr];
            int128 jWrapped = AMMWrapperStorage.getStorage().curveWrappedTokenIndexes[_makerAddr][_makerAssetAddr];
            if (iWrapped != 0 && jWrapped != 0) {
                takerAssetIndex = iWrapped;
                makerAssetIndex = jWrapped;
                // exchange
                swapMethod = 1;
            } else {
                revert("PermanentStorage: invalid pair");
            }
        }
        return (takerAssetIndex, makerAssetIndex, swapMethod, supportGetDx);
    }

    /* 
    NOTE: `isTransactionSeen` is replaced by `isAMMTransactionSeen`. It is kept for backward compatability.
    It should be removed from AMM 5.2.1 upward.
    */
    function isTransactionSeen(bytes32 _transactionHash) override external view returns (bool) {
        return AMMWrapperStorage.getStorage().transactionSeen[_transactionHash];
    }

    function isAMMTransactionSeen(bytes32 _transactionHash) override external view returns (bool) {
        return AMMWrapperStorage.getStorage().transactionSeen[_transactionHash];
    }

    function isRFQTransactionSeen(bytes32 _transactionHash) override external view returns (bool) {
        return RFQStorage.getStorage().transactionSeen[_transactionHash];
    }

    function isRelayerValid(address _relayer) override external view returns (bool) {
        return AMMWrapperStorage.getStorage().relayerValid[_relayer];
    }


    /************************************************************
    *           Management functions for Operator               *
    *************************************************************/
    /// @dev Update AMMWrapper contract address.
    function upgradeAMMWrapper(address _newAMMWrapper) external onlyOperator {
        PSStorage.getStorage().ammWrapperAddr = _newAMMWrapper;

        emit UpgradeAMMWrapper(_newAMMWrapper);
    }

    /// @dev Update PMM contract address.
    function upgradePMM(address _newPMM) external onlyOperator {
        PSStorage.getStorage().pmmAddr = _newPMM;

        emit UpgradePMM(_newPMM);
    }

    /// @dev Update RFQ contract address.
    function upgradeRFQ(address _newRFQ) external onlyOperator {
        PSStorage.getStorage().rfqAddr = _newRFQ;

        emit UpgradeRFQ(_newRFQ);
    }

    /// @dev Update WETH contract address.
    function upgradeWETH(address _newWETH) external onlyOperator {
        PSStorage.getStorage().wethAddr = _newWETH;

        emit UpgradeWETH(_newWETH);
    }


    /************************************************************
    *                   External functions                      *
    *************************************************************/
    function setCurvePoolInfo(address _makerAddr, address[] calldata _underlyingCoins, address[] calldata _coins, bool _supportGetDx) override external isPermitted(curveTokenIndexStorageId, msg.sender) {
        int128 underlyingCoinsLength = int128(_underlyingCoins.length);
        for (int128 i = 0 ; i < underlyingCoinsLength; i++) {
            address assetAddr = _underlyingCoins[uint256(i)];
            // underlying coins for original DAI, USDC, TUSD
            AMMWrapperStorage.getStorage().curveTokenIndexes[_makerAddr][assetAddr] = i + 1;  // Start the index from 1
        }

        int128 coinsLength = int128(_coins.length);
        for (int128 i = 0 ; i < coinsLength; i++) {
            address assetAddr = _coins[uint256(i)];
            // wrapped coins for cDAI, cUSDC, yDAI, yUSDC, yTUSD, yBUSD
            AMMWrapperStorage.getStorage().curveWrappedTokenIndexes[_makerAddr][assetAddr] = i + 1;  // Start the index from 1
        }

        AMMWrapperStorage.getStorage().curveSupportGetDx[_makerAddr] = _supportGetDx;
    }

    /* 
    NOTE: `setTransactionSeen` is replaced by `setAMMTransactionSeen`. It is kept for backward compatability.
    It should be removed from AMM 5.2.1 upward.
    */
    function setTransactionSeen(bytes32 _transactionHash) override external isPermitted(transactionSeenStorageId, msg.sender) {
        require(!AMMWrapperStorage.getStorage().transactionSeen[_transactionHash], "PermanentStorage: transaction seen before");
        AMMWrapperStorage.getStorage().transactionSeen[_transactionHash] = true;
    }

    function setAMMTransactionSeen(bytes32 _transactionHash) override external isPermitted(transactionSeenStorageId, msg.sender) {
        require(!AMMWrapperStorage.getStorage().transactionSeen[_transactionHash], "PermanentStorage: transaction seen before");
        AMMWrapperStorage.getStorage().transactionSeen[_transactionHash] = true;
    }

    function setRFQTransactionSeen(bytes32 _transactionHash) override external isPermitted(transactionSeenStorageId, msg.sender) {
        require(!RFQStorage.getStorage().transactionSeen[_transactionHash], "PermanentStorage: transaction seen before");
        RFQStorage.getStorage().transactionSeen[_transactionHash] = true;
    }

    function setRelayersValid(address[] calldata _relayers, bool[] calldata _isValids) override external isPermitted(relayerValidStorageId, msg.sender) {
        require(_relayers.length == _isValids.length, "PermanentStorage: inputs length mismatch");
        for (uint256 i = 0; i < _relayers.length; i++) {
            AMMWrapperStorage.getStorage().relayerValid[_relayers[i]] = _isValids[i];
        }
    }
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./AMMWrapper.sol";
import "./interfaces/ISpender.sol";
import "./interfaces/IUniswapRouterV2.sol";
import "./interfaces/IUniswapV3SwapRouter.sol";
import "./interfaces/IPermanentStorage.sol";
import "./utils/UniswapV3PathLib.sol";

contract AMMWrapperWithPath is AMMWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Path for bytes;

    // Constants do not have storage slot.
    address public constant UNISWAP_V3_ROUTER_ADDRESS = 0xE592427A0AEce92De3Edee1F18E0157C05861564;

    event Swapped(
        TxMetaData,
        Order order
    );

    /************************************************************
    *              Constructor and init functions               *
    *************************************************************/
    constructor (
        address _operator,
        uint256 _subsidyFactor,
        address _userProxy,
        ISpender _spender,
        IPermanentStorage _permStorage,
        IWETH _weth
    ) public AMMWrapper(_operator, _subsidyFactor, _userProxy, _spender, _permStorage, _weth) {}

    /************************************************************
    *                   External functions                      *
    *************************************************************/
    function trade(
        Order memory _order,
        uint256 _feeFactor,
        bytes calldata _sig,
        bytes calldata _makerSpecificData,
        address[] calldata _path
    )
        payable
        external
        nonReentrant
        onlyUserProxy
        returns (uint256) 
    {
        require(_order.deadline >= block.timestamp, "AMMWrapper: expired order");
        TxMetaData memory txMetaData;
        InternalTxData memory internalTxData;

        // These variables are copied straight from function parameters and
        // used to bypass stack too deep error.
        txMetaData.subsidyFactor = uint16(subsidyFactor);
        txMetaData.feeFactor = uint16(_feeFactor);
        internalTxData.makerSpecificData = _makerSpecificData;
        internalTxData.path = _path;
        if (! permStorage.isRelayerValid(tx.origin)) {
            txMetaData.feeFactor = (txMetaData.subsidyFactor > txMetaData.feeFactor) ? txMetaData.subsidyFactor : txMetaData.feeFactor;
            txMetaData.subsidyFactor = 0;
        }

        // Assign trade vairables
        internalTxData.fromEth = (_order.takerAssetAddr == ZERO_ADDRESS || _order.takerAssetAddr == ETH_ADDRESS);
        internalTxData.toEth = (_order.makerAssetAddr == ZERO_ADDRESS || _order.makerAssetAddr == ETH_ADDRESS);
        if(_isCurve(_order.makerAddr)) {
            // PermanetStorage can recognize `ETH_ADDRESS` but not `ZERO_ADDRESS`.
            // Convert it to `ETH_ADDRESS` as passed in `_order.takerAssetAddr` or `_order.makerAssetAddr` might be `ZERO_ADDRESS`.
            internalTxData.takerAssetInternalAddr = internalTxData.fromEth ? ETH_ADDRESS : _order.takerAssetAddr;
            internalTxData.makerAssetInternalAddr = internalTxData.toEth ? ETH_ADDRESS : _order.makerAssetAddr;
        } else {
            internalTxData.takerAssetInternalAddr = internalTxData.fromEth ? address(weth) : _order.takerAssetAddr;
            internalTxData.makerAssetInternalAddr = internalTxData.toEth ? address(weth) : _order.makerAssetAddr;
        }

        txMetaData.transactionHash = _verify(
            _order,
            _sig
        );

        _prepare(_order, internalTxData);

        (txMetaData.source, txMetaData.receivedAmount) = _swapWithPath(
            _order,
            txMetaData,
            internalTxData
        );

        // Settle
        txMetaData.settleAmount = _settle(
            _order,
            txMetaData,
            internalTxData
        );

        emit Swapped(
            txMetaData,
            _order
        );

        return txMetaData.settleAmount;
    }

    /**
     * @dev internal function of `trade`.
     * Used to tell if maker is Curve.
     */
    function _isCurve(address _makerAddr) override internal pure returns (bool) {
        if (
            _makerAddr == UNISWAP_V2_ROUTER_02_ADDRESS ||
            _makerAddr == UNISWAP_V3_ROUTER_ADDRESS ||
            _makerAddr == SUSHISWAP_ROUTER_ADDRESS
        ) return false;
        else return true;
    }

    /**
     * @dev internal function of `trade`.
     * It executes the swap on chosen AMM.
     */
    function _swapWithPath(
        Order memory _order,
        TxMetaData memory _txMetaData,
        InternalTxData memory _internalTxData
    )
        internal
        approveTakerAsset(_internalTxData.takerAssetInternalAddr, _order.makerAddr)
        returns (string memory source, uint256 receivedAmount)
    {
        // Swap
        // minAmount = makerAssetAmount * (10000 - subsidyFactor) / 10000
        uint256 minAmount = _order.makerAssetAmount.mul((BPS_MAX.sub(_txMetaData.subsidyFactor))).div(BPS_MAX);

        if (_order.makerAddr == UNISWAP_V2_ROUTER_02_ADDRESS ||
            _order.makerAddr == SUSHISWAP_ROUTER_ADDRESS) {
            source = (_order.makerAddr == SUSHISWAP_ROUTER_ADDRESS) ? "SushiSwap" : "Uniswap V2";
            // Sushiswap shares the same interface as Uniswap's
            receivedAmount = _tradeUniswapV2TokenToToken(
                _order.makerAddr,
                _internalTxData.takerAssetInternalAddr,
                _internalTxData.makerAssetInternalAddr,
                _order.takerAssetAmount,
                minAmount,
                _order.deadline,
                _internalTxData.path
            );
        } else if (_order.makerAddr == UNISWAP_V3_ROUTER_ADDRESS) {
            source = "Uniswap V3";
            receivedAmount = _tradeUniswapV3TokenToToken(
                _order.makerAddr,
                _internalTxData.takerAssetInternalAddr,
                _internalTxData.makerAssetInternalAddr,
                _order.deadline,
                _order.takerAssetAmount,
                minAmount,
                _internalTxData.makerSpecificData
            );
        } else {
            CurveData memory curveData;
            (
                curveData.fromTokenCurveIndex,
                curveData.toTokenCurveIndex,
                curveData.swapMethod,
            ) = permStorage.getCurvePoolInfo(
                _order.makerAddr,
                _internalTxData.takerAssetInternalAddr,
                _internalTxData.makerAssetInternalAddr
            );
            require(curveData.swapMethod != 0,"AMMWrapper: swap method not registered");
            if (curveData.fromTokenCurveIndex > 0 && curveData.toTokenCurveIndex > 0) {
                source = "Curve";
                // Substract index by 1 because indices stored in `permStorage` starts from 1
                curveData.fromTokenCurveIndex = curveData.fromTokenCurveIndex - 1;
                curveData.toTokenCurveIndex = curveData.toTokenCurveIndex - 1;
                // Curve does not return amount swapped so we need to record balance change instead.
                uint256 balanceBeforeTrade = _getSelfBalance(_internalTxData.makerAssetInternalAddr);
                _tradeCurveTokenToToken(
                    _order.makerAddr,
                    curveData.fromTokenCurveIndex,
                    curveData.toTokenCurveIndex,
                    _order.takerAssetAmount,
                    minAmount,
                    curveData.swapMethod
                );
                uint256 balanceAfterTrade = _getSelfBalance(_internalTxData.makerAssetInternalAddr);
                receivedAmount = balanceAfterTrade.sub(balanceBeforeTrade);
            } else {
                revert("AMMWrapper: unsupported makerAddr");
            }
        }
    }

    function _tradeUniswapV2TokenToToken(
        address _makerAddr,
        address _takerAssetAddr,
        address _makerAssetAddr,
        uint256 _takerAssetAmount,
        uint256 _makerAssetAmount,
        uint256 _deadline,
        address[] memory _path
    )
        internal 
        returns (uint256) 
    {
        IUniswapRouterV2 router = IUniswapRouterV2(_makerAddr);
        if (_path.length == 0) {
            _path = new address[](2);
            _path[0] = _takerAssetAddr;
            _path[1] = _makerAssetAddr;
        } else {
            require(_path.length >= 2, "AMMWrapper: path length must be at least two");
            require(_path[0] == _takerAssetAddr, "AMMWrapper: first element of path must match taker asset");
            require(_path[_path.length - 1] == _makerAssetAddr, "AMMWrapper: last element of path must match maker asset");
        }
        uint256[] memory amounts = router.swapExactTokensForTokens(
            _takerAssetAmount,
            _makerAssetAmount,
            _path,
            address(this),
            _deadline
        );
        return amounts[amounts.length - 1];
    }

    function _validateUniswapV3Path(
        bytes memory _path,
        address _takerAssetAddr,
        address _makerAssetAddr
    ) internal {
        (address tokenA, address tokenB, ) = _path.decodeFirstPool();

        if (_path.hasMultiplePools()) {
            _path = _path.skipToken();
            while (_path.hasMultiplePools()) {
                _path = _path.skipToken();
            }
            (, tokenB, ) = _path.decodeFirstPool();
        }

        require(tokenA == _takerAssetAddr, "AMMWrapper: first element of path must match taker asset");
        require(tokenB == _makerAssetAddr, "AMMWrapper: last element of path must match maker asset");
    }

    function _tradeUniswapV3TokenToToken(
        address _makerAddr,
        address _takerAssetAddr,
        address _makerAssetAddr,
        uint256 _deadline,
        uint256 _takerAssetAmount,
        uint256 _makerAssetAmount,
        bytes memory _makerSpecificData
    )
        internal 
        returns (uint256 amountOut) 
    {
        ISwapRouter router = ISwapRouter(_makerAddr);
        // swapType:
        // 1: exactInputSingle, 2: exactInput
        uint8 swapType = uint8(uint256(_makerSpecificData.readBytes32(0)));

        if (swapType == 1) {
            (, uint24 poolFee) = abi.decode(_makerSpecificData, (uint8, uint24));
            ISwapRouter.ExactInputSingleParams memory exactInputSingleParams;
            exactInputSingleParams.tokenIn = _takerAssetAddr;
            exactInputSingleParams.tokenOut = _makerAssetAddr;
            exactInputSingleParams.fee = poolFee;
            exactInputSingleParams.recipient = address(this);
            exactInputSingleParams.deadline = _deadline;
            exactInputSingleParams.amountIn = _takerAssetAmount;
            exactInputSingleParams.amountOutMinimum = _makerAssetAmount;
            exactInputSingleParams.sqrtPriceLimitX96 = 0;

            amountOut = router.exactInputSingle(exactInputSingleParams);
        } else if (swapType == 2) {
            (, bytes memory path) = abi.decode(_makerSpecificData, (uint8, bytes));
            _validateUniswapV3Path(path, _takerAssetAddr, _makerAssetAddr);
            ISwapRouter.ExactInputParams memory exactInputParams;
            exactInputParams.path = path;
            exactInputParams.recipient = address(this);
            exactInputParams.deadline = _deadline;
            exactInputParams.amountIn = _takerAssetAmount;
            exactInputParams.amountOutMinimum = _makerAssetAmount;

            amountOut = router.exactInput(exactInputParams);
        } else {
            revert("AMMWrapper: unsupported UniswapV3 swap type");
        }
    }
}

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interfaces/ISpender.sol";
import "./interfaces/IUniswapExchange.sol";
import "./interfaces/IUniswapFactory.sol";
import "./interfaces/IUniswapRouterV2.sol";
import "./interfaces/ICurveFi.sol";
import "./interfaces/IAMM.sol";
import "./interfaces/IWeth.sol";
import "./interfaces/IPermanentStorage.sol";
import "./utils/AMMLibEIP712.sol";
import "./utils/SignatureValidator.sol";

contract AMMWrapper is
    IAMM,
    ReentrancyGuard,
    AMMLibEIP712,
    SignatureValidator
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Constants do not have storage slot.
    string public constant version = "5.2.0";
    uint256 internal constant MAX_UINT = 2**256 - 1;
    uint256 internal constant BPS_MAX = 10000;
    address internal constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address internal constant ZERO_ADDRESS = address(0);
    address public immutable userProxy;
    IWETH public immutable weth;
    IPermanentStorage public immutable permStorage;
    address public constant UNISWAP_V2_ROUTER_02_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public constant SUSHISWAP_ROUTER_ADDRESS = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;

    // Below are the variables which consume storage slots.
    address public operator;
    uint256 public subsidyFactor;
    ISpender public spender;

    /* Struct and event declaration */
    // Group the local variables together to prevent
    // Compiler error: Stack too deep, try removing local variables.
    struct TxMetaData {
        string source;
        bytes32 transactionHash;
        uint256 settleAmount;
        uint256 receivedAmount;
        uint16 feeFactor;
        uint16 subsidyFactor;
    }

    struct InternalTxData {
        bool fromEth;
        bool toEth;
        address takerAssetInternalAddr;
        address makerAssetInternalAddr;
        address[] path;
        bytes makerSpecificData;
    }

    struct CurveData {
        int128 fromTokenCurveIndex;
        int128 toTokenCurveIndex;
        uint16 swapMethod;
    }

    // Operator events
    event TransferOwnership(address newOperator);
    event UpgradeSpender(address newSpender);
    event SetSubsidyFactor(uint256 newSubisdyFactor);
    event AllowTransfer(address spender);
    event DisallowTransfer(address spender);
    event DepositETH(uint256 ethBalance);

    event Swapped(
        string source,
        bytes32 indexed transactionHash,
        address indexed userAddr,
        address takerAssetAddr,
        uint256 takerAssetAmount,
        address makerAddr,
        address makerAssetAddr,
        uint256 makerAssetAmount,
        address receiverAddr,
        uint256 settleAmount,
        uint256 receivedAmount,
        uint16 feeFactor,
        uint16 subsidyFactor
    );


    receive() external payable {}


    /************************************************************
    *          Access control and ownership management          *
    *************************************************************/
    modifier onlyOperator() {
        require(operator == msg.sender, "AMMWrapper: not the operator");
        _;
    }

    modifier onlyUserProxy() {
        require(address(userProxy) == msg.sender, "AMMWrapper: not the UserProxy contract");
        _;
    }

    function transferOwnership(address _newOperator) external onlyOperator {
        require(_newOperator != address(0), "AMMWrapper: operator can not be zero address");
        operator = _newOperator;

        emit TransferOwnership(_newOperator);
    }

    /************************************************************
    *                 Internal function modifier                *
    *************************************************************/
    modifier approveTakerAsset(address _takerAssetInternalAddr, address _makerAddr) {
        bool isTakerAssetETH = _isInternalAssetETH(_takerAssetInternalAddr);
        if (! isTakerAssetETH) IERC20(_takerAssetInternalAddr).safeApprove(_makerAddr, MAX_UINT);

        _;

        if (! isTakerAssetETH) IERC20(_takerAssetInternalAddr).safeApprove(_makerAddr, 0);
    }

    /************************************************************
    *              Constructor and init functions               *
    *************************************************************/
    constructor (
        address _operator,
        uint256 _subsidyFactor,
        address _userProxy,
        ISpender _spender,
        IPermanentStorage _permStorage,
        IWETH _weth
    ) public {
        operator = _operator;
        subsidyFactor = _subsidyFactor;
        userProxy = _userProxy;
        spender = _spender;
        permStorage = _permStorage;
        weth = _weth;
    }


    /************************************************************
    *           Management functions for Operator               *
    *************************************************************/
    /**
     * @dev set new Spender
     */
    function upgradeSpender(address _newSpender) external onlyOperator {
        require(_newSpender != address(0), "AMMWrapper: spender can not be zero address");
        spender = ISpender(_newSpender);

        emit UpgradeSpender(_newSpender);
    }

    function setSubsidyFactor(uint256 _subsidyFactor) external onlyOperator {
        subsidyFactor = _subsidyFactor;

        emit SetSubsidyFactor(_subsidyFactor);
    }

    /**
     * @dev approve spender to transfer tokens from this contract. This is used to collect fee.
     */
    function setAllowance(address[] calldata _tokenList, address _spender) override external onlyOperator {
        for (uint256 i = 0 ; i < _tokenList.length; i++) {
            IERC20(_tokenList[i]).safeApprove(_spender, MAX_UINT);

            emit AllowTransfer(_spender);
        }
    }

    function closeAllowance(address[] calldata _tokenList, address _spender) override external onlyOperator {
        for (uint256 i = 0 ; i < _tokenList.length; i++) {
            IERC20(_tokenList[i]).safeApprove(_spender, 0);

            emit DisallowTransfer(_spender);
        }
    }

    /**
     * @dev convert collected ETH to WETH
     */
    function depositETH() external onlyOperator {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            weth.deposit{value: balance}();

            emit DepositETH(balance);
        }
    }


    /************************************************************
    *                   External functions                      *
    *************************************************************/
    function trade(
        address _makerAddr,
        address _takerAssetAddr,
        address _makerAssetAddr,
        uint256 _takerAssetAmount,
        uint256 _makerAssetAmount,
        uint256 _feeFactor,
        address _userAddr,
        address payable _receiverAddr,
        uint256 _salt,
        uint256 _deadline,
        bytes calldata _sig
    )
        override
        payable
        external
        nonReentrant
        onlyUserProxy
        returns (uint256) 
    {
        Order memory order = Order(
            _makerAddr,
            _takerAssetAddr,
            _makerAssetAddr,
            _takerAssetAmount,
            _makerAssetAmount,
            _userAddr,
            _receiverAddr,
            _salt,
            _deadline
        );
        require(order.deadline >= block.timestamp, "AMMWrapper: expired order");
        TxMetaData memory txMetaData;
        InternalTxData memory internalTxData;

        // These variables are copied straight from function parameters and
        // used to bypass stack too deep error.
        txMetaData.subsidyFactor = uint16(subsidyFactor);
        txMetaData.feeFactor = uint16(_feeFactor);
        if (! permStorage.isRelayerValid(tx.origin)) {
            txMetaData.feeFactor = (txMetaData.subsidyFactor > txMetaData.feeFactor) ? txMetaData.subsidyFactor : txMetaData.feeFactor;
            txMetaData.subsidyFactor = 0;
        }

        // Assign trade vairables
        internalTxData.fromEth = (order.takerAssetAddr == ZERO_ADDRESS || order.takerAssetAddr == ETH_ADDRESS);
        internalTxData.toEth = (order.makerAssetAddr == ZERO_ADDRESS || order.makerAssetAddr == ETH_ADDRESS);
        if(_isCurve(order.makerAddr)) {
            // PermanetStorage can recognize `ETH_ADDRESS` but not `ZERO_ADDRESS`.
            // Convert it to `ETH_ADDRESS` as passed in `order.takerAssetAddr` or `order.makerAssetAddr` might be `ZERO_ADDRESS`.
            internalTxData.takerAssetInternalAddr = internalTxData.fromEth ? ETH_ADDRESS : order.takerAssetAddr;
            internalTxData.makerAssetInternalAddr = internalTxData.toEth ? ETH_ADDRESS : order.makerAssetAddr;
        } else {
            internalTxData.takerAssetInternalAddr = internalTxData.fromEth ? address(weth) : order.takerAssetAddr;
            internalTxData.makerAssetInternalAddr = internalTxData.toEth ? address(weth) : order.makerAssetAddr;
        }

        txMetaData.transactionHash = _verify(
            order,
            _sig
        );

        _prepare(order, internalTxData);

        (txMetaData.source, txMetaData.receivedAmount) = _swap(
            order,
            txMetaData,
            internalTxData
        );

        // Settle
        txMetaData.settleAmount = _settle(
            order,
            txMetaData,
            internalTxData
        );

        emit Swapped(
            txMetaData.source,
            txMetaData.transactionHash,
            order.userAddr,
            order.takerAssetAddr,
            order.takerAssetAmount,
            order.makerAddr,
            order.makerAssetAddr,
            order.makerAssetAmount,
            order.receiverAddr,
            txMetaData.settleAmount,
            txMetaData.receivedAmount,
            txMetaData.feeFactor,
            txMetaData.subsidyFactor
        );

        return txMetaData.settleAmount;
    }

    /**
     * @dev internal function of `trade`.
     * Used to tell if maker is Curve.
     */
    function _isCurve(address _makerAddr) virtual internal pure returns (bool) {
        if (
            _makerAddr == UNISWAP_V2_ROUTER_02_ADDRESS ||
            _makerAddr == SUSHISWAP_ROUTER_ADDRESS
        ) return false;
        else return true;
    }

    /**
     * @dev internal function of `trade`.
     * Used to tell if internal asset is ETH.
     */
    function _isInternalAssetETH(address _internalAssetAddr) internal pure returns (bool) {
        if (_internalAssetAddr == ETH_ADDRESS || _internalAssetAddr == ZERO_ADDRESS) return true;
        else return false;
    }

    /**
     * @dev internal function of `trade`.
     * Get this contract's eth balance or token balance.
     */
    function _getSelfBalance(address _makerAssetInternalAddr) internal view returns (uint256) {
        if (_isInternalAssetETH(_makerAssetInternalAddr)) {
            return address(this).balance;
        } else {
            return IERC20(_makerAssetInternalAddr).balanceOf(address(this));
        }
    }

    /**
     * @dev internal function of `trade`.
     * It verifies user signature and store tx hash to prevent replay attack.
     */
    function _verify(
        Order memory _order,
        bytes calldata _sig
    ) internal returns (bytes32 transactionHash) {
        // Verify user signature
        // TRADE_WITH_PERMIT_TYPEHASH = keccak256("tradeWithPermit(address makerAddr,address takerAssetAddr,address makerAssetAddr,uint256 takerAssetAmount,uint256 makerAssetAmount,address userAddr,address receiverAddr,uint256 salt,uint256 deadline)");
        transactionHash = keccak256(
            abi.encode(
                TRADE_WITH_PERMIT_TYPEHASH,
                _order.makerAddr,
                _order.takerAssetAddr,
                _order.makerAssetAddr,
                _order.takerAssetAmount,
                _order.makerAssetAmount,
                _order.userAddr,
                _order.receiverAddr,
                _order.salt,
                _order.deadline
            )
        );
        bytes32 EIP712SignDigest = keccak256(
            abi.encodePacked(
                EIP191_HEADER,
                EIP712_DOMAIN_SEPARATOR,
                transactionHash
            )
        );
        require(isValidSignature(_order.userAddr, EIP712SignDigest, bytes(""), _sig), "AMMWrapper: invalid user signature");
        // Set transaction as seen, PermanentStorage would throw error if transaction already seen.
        permStorage.setAMMTransactionSeen(transactionHash);
    }

    /**
     * @dev internal function of `trade`.
     * It executes the swap on chosen AMM.
     */
    function _prepare(Order memory _order, InternalTxData memory _internalTxData) internal {
        // Transfer asset from user and deposit to weth if needed
        if (_internalTxData.fromEth) {
            require(msg.value > 0, "AMMWrapper: msg.value is zero");
            require(_order.takerAssetAmount == msg.value, "AMMWrapper: msg.value doesn't match");
            // Deposit ETH to WETH if internal asset is WETH instead of ETH
            if (! _isInternalAssetETH(_internalTxData.takerAssetInternalAddr)) {
                weth.deposit{value: msg.value}();
            }
        } else {
            // other ERC20 tokens
            spender.spendFromUser(_order.userAddr, _order.takerAssetAddr, _order.takerAssetAmount);
        }
    }

    /**
     * @dev internal function of `trade`.
     * It executes the swap on chosen AMM.
     */
    function _swap(
        Order memory _order,
        TxMetaData memory _txMetaData,
        InternalTxData memory _internalTxData
    )
        internal
        approveTakerAsset(_internalTxData.takerAssetInternalAddr, _order.makerAddr)
        returns (string memory source, uint256 receivedAmount)
    {
        // Swap
        // minAmount = makerAssetAmount * (10000 - subsidyFactor) / 10000
        uint256 minAmount = _order.makerAssetAmount.mul((BPS_MAX.sub(_txMetaData.subsidyFactor))).div(BPS_MAX);

        if (_order.makerAddr == UNISWAP_V2_ROUTER_02_ADDRESS ||
            _order.makerAddr == SUSHISWAP_ROUTER_ADDRESS) {
            source = (_order.makerAddr == SUSHISWAP_ROUTER_ADDRESS) ? "SushiSwap" : "Uniswap V2";
            // Sushiswap shares the same interface as Uniswap's
            receivedAmount = _tradeUniswapV2TokenToToken(
                _order.makerAddr,
                _internalTxData.takerAssetInternalAddr,
                _internalTxData.makerAssetInternalAddr,
                _order.takerAssetAmount,
                minAmount,
                _order.deadline
            );
        } else {
            CurveData memory curveData;
            (
                curveData.fromTokenCurveIndex,
                curveData.toTokenCurveIndex,
                curveData.swapMethod,
            ) = permStorage.getCurvePoolInfo(
                _order.makerAddr,
                _internalTxData.takerAssetInternalAddr,
                _internalTxData.makerAssetInternalAddr
            );
            require(curveData.swapMethod != 0, "AMMWrapper: swap method not registered");
            if (curveData.fromTokenCurveIndex > 0 && curveData.toTokenCurveIndex > 0) {
                source = "Curve";
                // Substract index by 1 because indices stored in `permStorage` starts from 1
                curveData.fromTokenCurveIndex = curveData.fromTokenCurveIndex - 1;
                curveData.toTokenCurveIndex = curveData.toTokenCurveIndex - 1;
                // Curve does not return amount swapped so we need to record balance change instead.
                uint256 balanceBeforeTrade = _getSelfBalance(_internalTxData.makerAssetInternalAddr);
                _tradeCurveTokenToToken(
                    _order.makerAddr,
                    curveData.fromTokenCurveIndex,
                    curveData.toTokenCurveIndex,
                    _order.takerAssetAmount,
                    minAmount,
                    curveData.swapMethod
                );
                uint256 balanceAfterTrade = _getSelfBalance(_internalTxData.makerAssetInternalAddr);
                receivedAmount = balanceAfterTrade.sub(balanceBeforeTrade);
            } else {
                revert("AMMWrapper: unsupported makerAddr");
            }
        }
    }

    /**
     * @dev internal function of `trade`.
     * It collects fee from the trade or compensates the trade based on the actual amount swapped.
     */
    function _settle(
        Order memory _order,
        TxMetaData memory _txMetaData,
        InternalTxData memory _internalTxData
    )
        internal
        returns (uint256 settleAmount)
    {
        // Convert var type from uint16 to uint256
        uint256 _feeFactor = _txMetaData.feeFactor;
        uint256 _subsidyFactor = _txMetaData.subsidyFactor;

        if (_txMetaData.receivedAmount == _order.makerAssetAmount) {
            settleAmount = _txMetaData.receivedAmount;
        } else if (_txMetaData.receivedAmount > _order.makerAssetAmount) {
            // shouldCollectFee = ((receivedAmount - makerAssetAmount) / receivedAmount) > (feeFactor / 10000)
            bool shouldCollectFee = _txMetaData.receivedAmount.sub(_order.makerAssetAmount).mul(BPS_MAX) > _feeFactor.mul(_txMetaData.receivedAmount);
            if (shouldCollectFee) {
                // settleAmount = receivedAmount * (1 - feeFactor) / 10000
                settleAmount = _txMetaData.receivedAmount.mul(BPS_MAX.sub(_feeFactor)).div(BPS_MAX);
            } else {
                settleAmount = _order.makerAssetAmount;
            }
        } else {
            require(_subsidyFactor > 0, "AMMWrapper: this trade will not be subsidized");

            // If fee factor is smaller than subsidy factor, choose fee factor as actual subsidy factor
            // since we should subsidize less if we charge less.
            uint256 actualSubsidyFactor = (_subsidyFactor < _feeFactor) ? _subsidyFactor : _feeFactor;

            // inSubsidyRange = ((makerAssetAmount - receivedAmount) / receivedAmount) > (actualSubsidyFactor / 10000)
            bool inSubsidyRange = _order.makerAssetAmount.sub(_txMetaData.receivedAmount).mul(BPS_MAX) <= actualSubsidyFactor.mul(_txMetaData.receivedAmount);
            require(inSubsidyRange, "AMMWrapper: amount difference larger than subsidy amount");

            uint256 selfBalance = _getSelfBalance(_internalTxData.makerAssetInternalAddr);
            bool hasEnoughToSubsidize = selfBalance >= _order.makerAssetAmount;
            if (! hasEnoughToSubsidize && _isInternalAssetETH(_internalTxData.makerAssetInternalAddr)) {
                // We treat ETH and WETH the same so we have to convert WETH to ETH if ETH balance is not enough.
                uint256 amountShort = _order.makerAssetAmount.sub(selfBalance);
                if (amountShort <= weth.balanceOf(address(this))) {
                    // Withdraw the amount short from WETH
                    weth.withdraw(amountShort);
                    // Now we have enough
                    hasEnoughToSubsidize = true;
                }
            }
            require(hasEnoughToSubsidize, "AMMWrapper: not enough savings to subsidize");

            settleAmount = _order.makerAssetAmount;
        }

        // Transfer token/ETH to receiver
        if (_internalTxData.toEth) {
            // Withdraw from WETH if internal maker asset is WETH
            if (! _isInternalAssetETH(_internalTxData.makerAssetInternalAddr)) {
                weth.withdraw(settleAmount);
            }
            _order.receiverAddr.transfer(settleAmount);
        } else {
            // other ERC20 tokens
            IERC20(_order.makerAssetAddr).safeTransfer(_order.receiverAddr, settleAmount);
        }
    }

    function _tradeCurveTokenToToken(
        address _makerAddr,
        int128 i,
        int128 j,
        uint256 _takerAssetAmount,
        uint256 _makerAssetAmount,
        uint16 swapMethod
    ) 
        internal
    {
        ICurveFi curve = ICurveFi(_makerAddr);
        if (swapMethod == 1) {
            curve.exchange{value: msg.value}(i, j, _takerAssetAmount, _makerAssetAmount);
        } else if (swapMethod == 2) {
            curve.exchange_underlying{value: msg.value}(i, j, _takerAssetAmount, _makerAssetAmount);
        }
    }

    function _tradeUniswapV2TokenToToken(
        address _makerAddr,
        address _takerAssetAddr,
        address _makerAssetAddr,
        uint256 _takerAssetAmount,
        uint256 _makerAssetAmount,
        uint256 _deadline
    )
        internal 
        returns (uint256) 
    {
        IUniswapRouterV2 router = IUniswapRouterV2(_makerAddr);
        address[] memory path = new address[](2);
        path[0] = _takerAssetAddr;
        path[1] = _makerAssetAddr;
        uint256[] memory amounts = router.swapExactTokensForTokens(
            _takerAssetAmount,
            _makerAssetAmount,
            path,
            address(this),
            _deadline
        );
        return amounts[1];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.8.0;

interface IUniswapRouterV2 {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "./IUniswapV3SwapCallback.sol";

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
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

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

library BytesLib {
    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, "slice_overflow");
        require(_start + _length >= _start, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
                case 0 {
                    // Get a location of some free memory and store it in tempBytes as
                    // Solidity does for memory variables.
                    tempBytes := mload(0x40)

                    // The first word of the slice result is potentially a partial
                    // word read from the original array. To read it, we calculate
                    // the length of that partial word and start copying that many
                    // bytes into the array. The first word we copy will start with
                    // data we don't care about, but the last `lengthmod` bytes will
                    // land at the beginning of the contents of the new array. When
                    // we're done copying, we overwrite the full first word with
                    // the actual length of the slice.
                    let lengthmod := and(_length, 31)

                    // The multiplication in the next line is necessary
                    // because when slicing multiples of 32 bytes (lengthmod == 0)
                    // the following copy loop was copying the origin's length
                    // and then ending prematurely not copying everything it should.
                    let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                    let end := add(mc, _length)

                    for {
                        // The multiplication in the next line has the same exact purpose
                        // as the one above.
                        let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                    } lt(mc, end) {
                        mc := add(mc, 0x20)
                        cc := add(cc, 0x20)
                    } {
                        mstore(mc, mload(cc))
                    }

                    mstore(tempBytes, _length)

                    //update free-memory pointer
                    //allocating the array padded to 32 bytes like the compiler does now
                    mstore(0x40, and(add(mc, 31), not(31)))
                }
                //if we want a zero-length slice let's just return a zero-length array
                default {
                    tempBytes := mload(0x40)
                    //zero out the 32 bytes slice we are about to return
                    //we need to do it because Solidity does not garbage collect
                    mstore(tempBytes, 0)

                    mstore(0x40, add(tempBytes, 0x20))
                }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_start + 20 >= _start, "toAddress_overflow");
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint24(bytes memory _bytes, uint256 _start) internal pure returns (uint24) {
        require(_start + 3 >= _start, "toUint24_overflow");
        require(_bytes.length >= _start + 3, "toUint24_outOfBounds");
        uint24 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x3), _start))
        }

        return tempUint;
    }
}

/// @title Functions for manipulating path data for multihop swaps
library Path {
    using BytesLib for bytes;

    /// @dev The length of the bytes encoded address
    uint256 private constant ADDR_SIZE = 20;
    /// @dev The length of the bytes encoded fee
    uint256 private constant FEE_SIZE = 3;

    /// @dev The offset of a single token address and pool fee
    uint256 private constant NEXT_OFFSET = ADDR_SIZE + FEE_SIZE;
    /// @dev The offset of an encoded pool key
    uint256 private constant POP_OFFSET = NEXT_OFFSET + ADDR_SIZE;
    /// @dev The minimum length of an encoding that contains 2 or more pools
    uint256 private constant MULTIPLE_POOLS_MIN_LENGTH = POP_OFFSET + NEXT_OFFSET;

    /// @notice Returns true iff the path contains two or more pools
    /// @param path The encoded swap path
    /// @return True if path contains two or more pools, otherwise false
    function hasMultiplePools(bytes memory path) internal pure returns (bool) {
        return path.length >= MULTIPLE_POOLS_MIN_LENGTH;
    }

    /// @notice Decodes the first pool in path
    /// @param path The bytes encoded swap path
    /// @return tokenA The first token of the given pool
    /// @return tokenB The second token of the given pool
    /// @return fee The fee level of the pool
    function decodeFirstPool(bytes memory path)
        internal
        pure
        returns (
            address tokenA,
            address tokenB,
            uint24 fee
        )
    {
        tokenA = path.toAddress(0);
        fee = path.toUint24(ADDR_SIZE);
        tokenB = path.toAddress(NEXT_OFFSET);
    }

    /// @notice Skips a token + fee element from the buffer and returns the remainder
    /// @param path The swap path
    /// @return The remaining token + fee elements in the path
    function skipToken(bytes memory path) internal pure returns (bytes memory) {
        return path.slice(NEXT_OFFSET, path.length - NEXT_OFFSET);
    }
}

pragma solidity >=0.5.0 <0.8.0;

interface IUniswapExchange {
    // Address of ERC20 token sold on this exchange
    function tokenAddress() external view returns (address token);
    // Address of Uniswap Factory
    function factoryAddress() external view returns (address factory);
    // Provide Liquidity
    function addLiquidity(uint256 min_liquidity, uint256 max_tokens, uint256 deadline) external payable returns (uint256);
    function removeLiquidity(uint256 amount, uint256 min_eth, uint256 min_tokens, uint256 deadline) external returns (uint256, uint256);
    // Get Prices
    function getEthToTokenInputPrice(uint256 eth_sold) external view returns (uint256 tokens_bought);
    function getEthToTokenOutputPrice(uint256 tokens_bought) external view returns (uint256 eth_sold);
    function getTokenToEthInputPrice(uint256 tokens_sold) external view returns (uint256 eth_bought);
    function getTokenToEthOutputPrice(uint256 eth_bought) external view returns (uint256 tokens_sold);
    // Trade ETH to ERC20
    function ethToTokenSwapInput(uint256 min_tokens, uint256 deadline) external payable returns (uint256 tokens_bought);
    function ethToTokenTransferInput(uint256 min_tokens, uint256 deadline, address recipient) external payable returns (uint256  tokens_bought);
    function ethToTokenSwapOutput(uint256 tokens_bought, uint256 deadline) external payable returns (uint256  eth_sold);
    function ethToTokenTransferOutput(uint256 tokens_bought, uint256 deadline, address recipient) external payable returns (uint256  eth_sold);
    // Trade ERC20 to ETH
    function tokenToEthSwapInput(uint256 tokens_sold, uint256 min_eth, uint256 deadline) external returns (uint256  eth_bought);
    function tokenToEthTransferInput(uint256 tokens_sold, uint256 min_eth, uint256 deadline, address recipient) external returns (uint256  eth_bought);
    function tokenToEthSwapOutput(uint256 eth_bought, uint256 max_tokens, uint256 deadline) external returns (uint256  tokens_sold);
    function tokenToEthTransferOutput(uint256 eth_bought, uint256 max_tokens, uint256 deadline, address recipient) external returns (uint256  tokens_sold);
    // Trade ERC20 to ERC20
    function tokenToTokenSwapInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address token_addr) external returns (uint256  tokens_bought);
    function tokenToTokenTransferInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address recipient, address token_addr) external returns (uint256  tokens_bought);
    function tokenToTokenSwapOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address token_addr) external returns (uint256  tokens_sold);
    function tokenToTokenTransferOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address recipient, address token_addr) external returns (uint256  tokens_sold);
    // Trade ERC20 to Custom Pool
    function tokenToExchangeSwapInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address exchange_addr) external returns (uint256  tokens_bought);
    function tokenToExchangeTransferInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address recipient, address exchange_addr) external returns (uint256  tokens_bought);
    function tokenToExchangeSwapOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address exchange_addr) external returns (uint256  tokens_sold);
    function tokenToExchangeTransferOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address recipient, address exchange_addr) external returns (uint256  tokens_sold);
    // ERC20 comaptibility for liquidity tokens
    function name() external view returns (bytes32);
    function symbol() external view returns (bytes32);
    function decimals() external view returns (uint256);
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 value) external returns (bool);
    function approve(address _spender, uint256 _value) external returns (bool);
    function allowance(address _owner, address _spender) external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    // Never use
    function setup(address token_addr) external;
}

pragma solidity >=0.5.0 <0.8.0;

interface IUniswapFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);
    function allPairsLength() external view returns (uint256);
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    // Create Exchange
    function createExchange(address token) external returns (address exchange);
    // Get Exchange and Token Info
    function getExchange(address token) external view returns (address exchange);
    function getToken(address exchange) external view returns (address token);
    function getTokenWithId(uint256 tokenId) external view returns (address token);
    // Never use
    function initializeFactory(address template) external;
}

pragma solidity >=0.5.0 <0.8.0;

interface ICurveFi {
    function get_virtual_price() external returns (uint256 out);
    function add_liquidity(
        uint256[2] calldata amounts,
        uint256 deadline
    ) external;

    function add_liquidity(
        // sBTC pool
        uint256[3] calldata amounts,
        uint256 min_mint_amount
    ) external;

    function add_liquidity(
        // bUSD pool
        uint256[4] calldata amounts,
        uint256 min_mint_amount
    ) external;

    function get_dx(
        int128 i,
        int128 j,
        uint256 dy
    ) external view returns (uint256 out);

    function get_dx_underlying(
        int128 i,
        int128 j,
        uint256 dy
    ) external view returns (uint256 out);

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256 out);

    function get_dy_underlying(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256 out);

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external payable;

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy,
        uint256 deadline
    ) external payable;

    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external payable;

    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy,
        uint256 deadline
    ) external payable;

    function remove_liquidity(
        uint256 _amount,
        uint256 deadline,
        uint256[2] calldata min_amounts
    ) external;

    function remove_liquidity_imbalance(
        uint256[2] calldata amounts,
        uint256 deadline
    ) external;

    function remove_liquidity_imbalance(
        uint256[3] calldata amounts,
        uint256 max_burn_amount
    ) external;

    function remove_liquidity(uint256 _amount, uint256[3] calldata amounts)
        external;

    function remove_liquidity_imbalance(
        uint256[4] calldata amounts,
        uint256 max_burn_amount
    ) external;

    function remove_liquidity(uint256 _amount, uint256[4] calldata amounts)
        external;

    function commit_new_parameters(
        int128 amplification,
        int128 new_fee,
        int128 new_admin_fee
    ) external;

    function apply_new_parameters() external;

    function revert_new_parameters() external;

    function commit_transfer_ownership(address _owner) external;

    function apply_transfer_ownership() external;

    function revert_transfer_ownership() external;

    function withdraw_admin_fees() external;

    function coins(int128 arg0) external returns (address out);

    function underlying_coins(int128 arg0) external returns (address out);

    function balances(int128 arg0) external returns (uint256 out);

    function A() external returns (int128 out);

    function fee() external returns (int128 out);

    function admin_fee() external returns (int128 out);

    function owner() external returns (address out);

    function admin_actions_deadline() external returns (uint256 out);

    function transfer_ownership_deadline() external returns (uint256 out);

    function future_A() external returns (int128 out);

    function future_fee() external returns (int128 out);

    function future_admin_fee() external returns (int128 out);

    function future_owner() external returns (address out);
}

pragma solidity ^0.6.0;

import "./BaseLibEIP712.sol";

contract AMMLibEIP712 is BaseLibEIP712 {
    /***********************************|
    |             Constants             |
    |__________________________________*/

    struct Order {
        address makerAddr;
        address takerAssetAddr;
        address makerAssetAddr;
        uint256 takerAssetAmount;
        uint256 makerAssetAmount;
        address userAddr;
        address payable receiverAddr;
        uint256 salt;
        uint256 deadline;
    }

    // keccak256("tradeWithPermit(address makerAddr,address takerAssetAddr,address makerAssetAddr,uint256 takerAssetAmount,uint256 makerAssetAmount,address userAddr,address receiverAddr,uint256 salt,uint256 deadline)");
    bytes32 public constant TRADE_WITH_PERMIT_TYPEHASH = keccak256(
        abi.encodePacked(
            "tradeWithPermit(",
            "address makerAddr,",
            "address takerAssetAddr,",
            "address makerAssetAddr,",
            "uint256 takerAssetAmount,",
            "uint256 makerAssetAmount,",
            "address userAddr,",
            "address receiverAddr,",
            "uint256 salt,",
            "uint256 deadline",
            ")"
        )
    );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0 <0.8.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./interfaces/IWeth.sol";
import "./pmm/mmp/Ownable.sol";
import "./pmm/0xLibs/LibDecoder.sol";

interface IIMBTC {
    function burn(uint256 amount, bytes calldata data) external;
}

interface IWBTC {
    function burn(uint256 value) external;
}

contract MarketMakerProxy is 
    Ownable,
    LibDecoder
{
    using SafeERC20 for IERC20;

    string public constant version = "5.0.0";
    uint256 constant MAX_UINT = 2**256 - 1;
    address public SIGNER;

    // auto withdraw weth to eth
    address public WETH_ADDR;
    address public withdrawer;
    mapping (address => bool) public isWithdrawWhitelist;

    modifier onlyWithdrawer() {
        require(
            msg.sender == withdrawer,
            "MarketMakerProxy: only contract withdrawer"
        );
        _;
    }

    constructor () public {
        owner = msg.sender;
        operator = msg.sender;
    }

    receive() external payable {}

    // Manage
    function setSigner(address _signer) public onlyOperator {
        SIGNER = _signer;
    }

    function setConfig(address _weth) public onlyOperator {
        WETH_ADDR = _weth;
    }

    function setWithdrawer(address _withdrawer) public onlyOperator {
        withdrawer = _withdrawer;
    }

    function setAllowance(address[] memory token_addrs, address spender) public onlyOperator {
        for (uint i = 0; i < token_addrs.length; i++) {
            address token = token_addrs[i];
            IERC20(token).safeApprove(spender, MAX_UINT);
        }
    }

    function closeAllowance(address[] memory token_addrs, address spender) public onlyOperator {
        for (uint i = 0; i < token_addrs.length; i++) {
            address token = token_addrs[i];
            IERC20(token).safeApprove(spender, 0);
        }
    }

    function registerWithdrawWhitelist(address _addr, bool _add) public onlyOperator {
        isWithdrawWhitelist[_addr] = _add;
    }

    function withdraw(address token, address payable to, uint256 amount) public onlyWithdrawer {
        require(
            isWithdrawWhitelist[to],
            "MarketMakerProxy: not in withdraw whitelist"
        );
        if(token == WETH_ADDR) {
            IWETH(WETH_ADDR).withdraw(amount);
            to.transfer(amount);
        } else {
            IERC20(token).safeTransfer(to , amount);
        }
    }

    function withdrawETH(address payable to, uint256 amount) public onlyWithdrawer {
        require(
            isWithdrawWhitelist[to],
            "MarketMakerProxy: not in withdraw whitelist"
        );
        to.transfer(amount);
    }


    function isValidSignature(bytes32 orderHash, bytes memory signature) public view returns (bytes32) {
        require(
            SIGNER == _ecrecoverAddress(orderHash, signature),
            "MarketMakerProxy: invalid signature"
        );
        return keccak256("isValidWalletSignature(bytes32,address,bytes)");
    }

    function _ecrecoverAddress(bytes32 orderHash, bytes memory signature) internal pure returns (address) {
        (uint8 v, bytes32 r, bytes32 s) = decodeMmSignature(signature);
        return ecrecover(
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    orderHash
                )),
            v, r, s
        );
    }
}

pragma solidity ^0.6.0;

contract Ownable {
  address public owner;
  address public operator;

  constructor ()
    public
  {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(
      msg.sender == owner,
      "Ownable: only contract owner"
    );
    _;
  }

  modifier onlyOperator() {
    require(
      msg.sender == operator,
      "Ownable: only contract operator"
    );
    _;
  }

  function transferOwnership(address newOwner)
    public
    onlyOwner
  {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

  function setOperator(address newOperator)
    public
    onlyOwner 
  {
    operator = newOperator;
  }
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interfaces/IUniswapExchange.sol";
import "./interfaces/IUniswapFactory.sol";
import "./interfaces/IUniswapRouterV2.sol";
import "./interfaces/ICurveFi.sol";
import "./interfaces/IWeth.sol";
import "./interfaces/IPermanentStorage.sol";
import "./interfaces/IUniswapV3Quoter.sol";
import "./utils/LibBytes.sol";

/// This contract is designed to be called off-chain.
/// At T1, 4 requests would be made in order to get quote, which is for Uniswap v2, v3, Sushiswap and others.
/// For those source without path design, we can find best out amount in this contract.
/// For Uniswap and Sushiswap, best path would be calculated off-chain, we only verify out amount in this contract.

contract AMMQuoter {
    using SafeMath for uint256;
    using LibBytes for bytes;

    /* Constants */
    string public constant version = "5.2.0";
    address private constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address private constant ZERO_ADDRESS = address(0);
    address public constant UNISWAP_V2_ROUTER_02_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public constant UNISWAP_V3_ROUTER_ADDRESS = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address public constant UNISWAP_V3_QUOTER_ADDRESS = 0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6;
    address public constant SUSHISWAP_ROUTER_ADDRESS = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
    address public immutable weth;
    IPermanentStorage public immutable permStorage;

    struct GroupedVars {
        address makerAddr;
        address takerAssetAddr;
        address makerAssetAddr;
        uint256 takerAssetAmount;
        uint256 makerAssetAmount;
        address[] path;
    }

    event CurveTokenAdded(
        address indexed makerAddress,
        address indexed assetAddress,
        int128 index
    );

    constructor (IPermanentStorage _permStorage, address _weth) public {
        permStorage = _permStorage;
        weth = _weth;
    }

    function isETH(address assetAddress) public pure returns (bool) {
        return (assetAddress == ZERO_ADDRESS || assetAddress == ETH_ADDRESS);
    }

    function getMakerOutAmountWithPath(
        address _makerAddr,
        address _takerAssetAddr,
        address _makerAssetAddr,
        uint256 _takerAssetAmount,
        address[] calldata _path,
        bytes memory _makerSpecificData
    )
        public
        returns (uint256 makerAssetAmount)
    {
        GroupedVars memory vars;
        vars.makerAddr = _makerAddr;
        vars.takerAssetAddr = _takerAssetAddr;
        vars.makerAssetAddr = _makerAssetAddr;
        vars.takerAssetAmount = _takerAssetAmount;
        vars.path = _path;
        if (vars.makerAddr == UNISWAP_V2_ROUTER_02_ADDRESS ||
            vars.makerAddr == SUSHISWAP_ROUTER_ADDRESS) {
            IUniswapRouterV2 router = IUniswapRouterV2(vars.makerAddr);
            uint256[] memory amounts = router.getAmountsOut(vars.takerAssetAmount, vars.path);
            makerAssetAmount = amounts[amounts.length-1];
        } else if (vars.makerAddr == UNISWAP_V3_ROUTER_ADDRESS) {
            IUniswapV3Quoter quoter = IUniswapV3Quoter(UNISWAP_V3_QUOTER_ADDRESS);
            // swapType:
            // 1: exactInputSingle, 2: exactInput, 3: exactOuputSingle, 4: exactOutput
            uint8 swapType = uint8(uint256(_makerSpecificData.readBytes32(0)));
            if (swapType == 1) {
                address v3TakerInternalAsset = isETH(vars.takerAssetAddr) ? weth : vars.takerAssetAddr;
                address v3MakerInternalAsset = isETH(vars.makerAssetAddr) ? weth : vars.makerAssetAddr;
                (, uint24 poolFee) = abi.decode(_makerSpecificData, (uint8, uint24));
                makerAssetAmount = quoter.quoteExactInputSingle(v3TakerInternalAsset, v3MakerInternalAsset, poolFee, vars.takerAssetAmount, 0);
            } else if (swapType == 2) {
                (, bytes memory path) = abi.decode(_makerSpecificData, (uint8, bytes));
                makerAssetAmount = quoter.quoteExactInput(path, vars.takerAssetAmount);
            } else {
                revert("AMMQuoter: Invalid UniswapV3 swap type");
            }
        } else {
            address curveTakerIntenalAsset = isETH(vars.takerAssetAddr) ? ETH_ADDRESS : vars.takerAssetAddr;
            address curveMakerIntenalAsset = isETH(vars.makerAssetAddr) ? ETH_ADDRESS : vars.makerAssetAddr;
            (int128 fromTokenCurveIndex, int128 toTokenCurveIndex, uint16 swapMethod,) = permStorage.getCurvePoolInfo(vars.makerAddr, curveTakerIntenalAsset, curveMakerIntenalAsset);
            if (fromTokenCurveIndex > 0 && toTokenCurveIndex > 0) {
                require(swapMethod != 0, "AMMQuoter: swap method not registered");
                // Substract index by 1 because indices stored in `permStorage` starts from 1
                fromTokenCurveIndex = fromTokenCurveIndex - 1;
                toTokenCurveIndex = toTokenCurveIndex - 1;
                ICurveFi curve = ICurveFi(vars.makerAddr);
                if (swapMethod == 1) {
                    makerAssetAmount = curve.get_dy(fromTokenCurveIndex, toTokenCurveIndex, vars.takerAssetAmount).sub(1);
                } else if (swapMethod == 2) {
                    makerAssetAmount = curve.get_dy_underlying(fromTokenCurveIndex, toTokenCurveIndex, vars.takerAssetAmount).sub(1);
                }
            } else {
                revert("AMMQuoter: Unsupported makerAddr");
            }
        }
        return makerAssetAmount;
    }

    function getMakerOutAmount(
        address _makerAddr,
        address _takerAssetAddr,
        address _makerAssetAddr,
        uint256 _takerAssetAmount
    )
        public
        view
        returns (uint256)
    {
        uint256 makerAssetAmount;
        if (_makerAddr == UNISWAP_V2_ROUTER_02_ADDRESS ||
            _makerAddr == SUSHISWAP_ROUTER_ADDRESS) {
            IUniswapRouterV2 router = IUniswapRouterV2(_makerAddr);
            address[] memory path = new address[](2);
            if (isETH(_takerAssetAddr)) {
                path[0] = weth;
                path[1] = _makerAssetAddr;
            } else if (isETH(_makerAssetAddr)) {
                path[0] = _takerAssetAddr;
                path[1] = weth;
            } else {
                path[0] = _takerAssetAddr;
                path[1] = _makerAssetAddr;
            }
            uint256[] memory amounts = router.getAmountsOut(_takerAssetAmount, path);
            makerAssetAmount = amounts[1];
        } else {
            address curveTakerIntenalAsset = isETH(_takerAssetAddr) ? ETH_ADDRESS : _takerAssetAddr;
            address curveMakerIntenalAsset = isETH(_makerAssetAddr) ? ETH_ADDRESS : _makerAssetAddr;
            (int128 fromTokenCurveIndex, int128 toTokenCurveIndex, uint16 swapMethod,) = permStorage.getCurvePoolInfo(_makerAddr, curveTakerIntenalAsset, curveMakerIntenalAsset);
            if (fromTokenCurveIndex > 0 && toTokenCurveIndex > 0) {
                require(swapMethod != 0, "AMMQuoter: swap method not registered");
                // Substract index by 1 because indices stored in `permStorage` starts from 1
                fromTokenCurveIndex = fromTokenCurveIndex - 1;
                toTokenCurveIndex = toTokenCurveIndex - 1;
                ICurveFi curve = ICurveFi(_makerAddr);
                if (swapMethod == 1) {
                    makerAssetAmount = curve.get_dy(fromTokenCurveIndex, toTokenCurveIndex, _takerAssetAmount).sub(1);
                } else if (swapMethod == 2) {
                    makerAssetAmount = curve.get_dy_underlying(fromTokenCurveIndex, toTokenCurveIndex, _takerAssetAmount).sub(1);
                }
            } else {
                revert("AMMQuoter: Unsupported makerAddr");
            }
        }
        return makerAssetAmount;
    }

    /// @dev This function is designed for finding best out amount among AMM makers other than Uniswap and Sushiswap
    function getBestOutAmount(
        address[] calldata _makerAddresses,
        address _takerAssetAddr,
        address _makerAssetAddr,
        uint256 _takerAssetAmount
    )
        external
        view
        returns (address bestMaker, uint256 bestAmount)
    {
        bestAmount = 0;
        uint256 poolLength = _makerAddresses.length;
        for (uint256 i = 0; i < poolLength; i++) {
            address makerAddress = _makerAddresses[i];
            uint256 makerAssetAmount = getMakerOutAmount(makerAddress, _takerAssetAddr, _makerAssetAddr, _takerAssetAmount);
            if (makerAssetAmount > bestAmount) {
                bestAmount = makerAssetAmount;
                bestMaker = makerAddress;
            }
        }
        return (bestMaker, bestAmount);
    }

    function getTakerInAmountWithPath(
        address _makerAddr,
        address _takerAssetAddr,
        address _makerAssetAddr,
        uint256 _makerAssetAmount,
        address[] calldata _path,
        bytes memory _makerSpecificData
    )
        public
        returns (uint256 takerAssetAmount)
    {
        GroupedVars memory vars;
        vars.makerAddr = _makerAddr;
        vars.takerAssetAddr = _takerAssetAddr;
        vars.makerAssetAddr = _makerAssetAddr;
        vars.makerAssetAmount = _makerAssetAmount;
        vars.path = _path;
        if (vars.makerAddr == UNISWAP_V2_ROUTER_02_ADDRESS ||
            vars.makerAddr == SUSHISWAP_ROUTER_ADDRESS) {
            IUniswapRouterV2 router = IUniswapRouterV2(vars.makerAddr);
            uint256[] memory amounts = router.getAmountsIn(vars.makerAssetAmount, _path);
            takerAssetAmount = amounts[0];
        } else if (vars.makerAddr == UNISWAP_V3_ROUTER_ADDRESS) {
            IUniswapV3Quoter quoter = IUniswapV3Quoter(UNISWAP_V3_QUOTER_ADDRESS);
            // swapType:
            // 1: exactInputSingle, 2: exactInput, 3: exactOuputSingle, 4: exactOutput
            uint8 swapType = uint8(uint256(_makerSpecificData.readBytes32(0)));
            if (swapType == 3) {
                address v3TakerInternalAsset = isETH(vars.takerAssetAddr) ? weth : vars.takerAssetAddr;
                address v3MakerInternalAsset = isETH(vars.makerAssetAddr) ? weth : vars.makerAssetAddr;
                (, uint24 poolFee) = abi.decode(_makerSpecificData, (uint8, uint24));
                takerAssetAmount = quoter.quoteExactOutputSingle(v3TakerInternalAsset, v3MakerInternalAsset, poolFee, vars.makerAssetAmount, 0);
            } else if (swapType == 4) {
                (, bytes memory path) = abi.decode(_makerSpecificData, (uint8, bytes));
                takerAssetAmount = quoter.quoteExactOutput(path, vars.makerAssetAmount);
            } else {
                revert("AMMQuoter: Invalid UniswapV3 swap type");
            }
        } else {
            address curveTakerIntenalAsset = isETH(vars.takerAssetAddr) ? ETH_ADDRESS : vars.takerAssetAddr;
            address curveMakerIntenalAsset = isETH(vars.makerAssetAddr) ? ETH_ADDRESS : vars.makerAssetAddr;
            (int128 fromTokenCurveIndex, int128 toTokenCurveIndex, uint16 swapMethod, bool supportGetDx) = permStorage.getCurvePoolInfo(vars.makerAddr, curveTakerIntenalAsset, curveMakerIntenalAsset);
            if (fromTokenCurveIndex > 0 && toTokenCurveIndex > 0) {
                require(swapMethod != 0, "AMMQuoter: swap method not registered");
                // Substract index by 1 because indices stored in `permStorage` starts from 1
                fromTokenCurveIndex = fromTokenCurveIndex - 1;
                toTokenCurveIndex = toTokenCurveIndex - 1;
                ICurveFi curve = ICurveFi(vars.makerAddr);
                if (supportGetDx) {
                    if (swapMethod == 1) {
                        takerAssetAmount = curve.get_dx(fromTokenCurveIndex, toTokenCurveIndex, vars.makerAssetAmount);
                    } else if (swapMethod == 2) {
                        takerAssetAmount = curve.get_dx_underlying(fromTokenCurveIndex, toTokenCurveIndex, vars.makerAssetAmount);
                    }
                } else {
                    if (swapMethod == 1) {
                        // does not support get_dx_underlying, try to get an estimated rate here
                        takerAssetAmount = curve.get_dy(toTokenCurveIndex, fromTokenCurveIndex, vars.makerAssetAmount);
                    } else if (swapMethod == 2) {
                        takerAssetAmount = curve.get_dy_underlying(toTokenCurveIndex, fromTokenCurveIndex, vars.makerAssetAmount);
                    }
                }
            } else {
                revert("AMMQuoter: Unsupported makerAddr");
            }
        }
        return takerAssetAmount;
    }

    function getTakerInAmount(
        address _makerAddr,
        address _takerAssetAddr,
        address _makerAssetAddr,
        uint256 _makerAssetAmount
    )
        public
        view
        returns (uint256)
    {
        uint256 takerAssetAmount;
        if (_makerAddr == UNISWAP_V2_ROUTER_02_ADDRESS ||
            _makerAddr == SUSHISWAP_ROUTER_ADDRESS) {
            IUniswapRouterV2 router = IUniswapRouterV2(_makerAddr);
            address[] memory path = new address[](2);
            if (isETH(_takerAssetAddr)) {
                path[0] = weth;
                path[1] = _makerAssetAddr;
            } else if (isETH(_makerAssetAddr)) {
                path[0] = _takerAssetAddr;
                path[1] = weth;
            } else {
                path[0] = _takerAssetAddr;
                path[1] = _makerAssetAddr;
            }
            uint256[] memory amounts = router.getAmountsIn(_makerAssetAmount, path);
            takerAssetAmount = amounts[0];
        } else {
            address curveTakerIntenalAsset = isETH(_takerAssetAddr) ? ETH_ADDRESS : _takerAssetAddr;
            address curveMakerIntenalAsset = isETH(_makerAssetAddr) ? ETH_ADDRESS : _makerAssetAddr;
            (int128 fromTokenCurveIndex, int128 toTokenCurveIndex, uint16 swapMethod, bool supportGetDx) = permStorage.getCurvePoolInfo(_makerAddr, curveTakerIntenalAsset, curveMakerIntenalAsset);
            if (fromTokenCurveIndex > 0 && toTokenCurveIndex > 0) {
                require(swapMethod != 0, "AMMQuoter: swap method not registered");
                // Substract index by 1 because indices stored in `permStorage` starts from 1
                fromTokenCurveIndex = fromTokenCurveIndex - 1;
                toTokenCurveIndex = toTokenCurveIndex - 1;
                ICurveFi curve = ICurveFi(_makerAddr);
                if (supportGetDx) {
                    if (swapMethod == 1) {
                        takerAssetAmount = curve.get_dx(fromTokenCurveIndex, toTokenCurveIndex, _makerAssetAmount);
                    } else if (swapMethod == 2) {
                        takerAssetAmount = curve.get_dx_underlying(fromTokenCurveIndex, toTokenCurveIndex, _makerAssetAmount);
                    }
                } else {
                    if (swapMethod == 1) {
                        // does not support get_dx_underlying, try to get an estimated rate here
                        takerAssetAmount = curve.get_dy(toTokenCurveIndex, fromTokenCurveIndex, _makerAssetAmount);
                    } else if (swapMethod == 2) {
                        takerAssetAmount = curve.get_dy_underlying(toTokenCurveIndex, fromTokenCurveIndex, _makerAssetAmount);
                    }
                }
            } else {
                revert("AMMQuoter: Unsupported makerAddr");
            }
        }
        return takerAssetAmount;
    }

    /// @dev This function is designed for finding best in amount among AMM makers other than Uniswap and Sushiswap
    function getBestInAmount(
        address[] calldata _makerAddresses,
        address _takerAssetAddr,
        address _makerAssetAddr,
        uint256 _makerAssetAmount
    )
        external
        view
        returns (address bestMaker, uint256 bestAmount)
    {
        bestAmount = 2**256 - 1;
        uint256 poolLength = _makerAddresses.length;
        for (uint256 i = 0; i < poolLength; i++) {
            address makerAddress = _makerAddresses[i];
            uint256 takerAssetAmount = getTakerInAmount(makerAddress, _takerAssetAddr, _makerAssetAddr, _makerAssetAmount);
            if (takerAssetAmount < bestAmount) {
                bestAmount = takerAssetAmount;
                bestMaker = makerAddress;
            }
        }
        return (bestMaker, bestAmount);
    }
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

/// @title Quoter Interface
/// @notice Supports quoting the calculated amounts from exact input or exact output swaps
/// @dev These functions are not marked view because they rely on calling non-view functions and reverting
/// to compute the result. They are also not gas efficient and should not be called on-chain.
interface IUniswapV3Quoter {
    /// @notice Returns the amount out received for a given exact input swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee
    /// @param amountIn The amount of the first token to swap
    /// @return amountOut The amount of the last token that would be received
    function quoteExactInput(bytes memory path, uint256 amountIn) external returns (uint256 amountOut);

    /// @notice Returns the amount out received for a given exact input but for a swap of a single pool
    /// @param tokenIn The token being swapped in
    /// @param tokenOut The token being swapped out
    /// @param fee The fee of the token pool to consider for the pair
    /// @param amountIn The desired input amount
    /// @param sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountOut The amount of `tokenOut` that would be received
    function quoteExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountOut);

    /// @notice Returns the amount in required for a given exact output swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee. Path must be provided in reverse order
    /// @param amountOut The amount of the last token to receive
    /// @return amountIn The amount of first token required to be paid
    function quoteExactOutput(bytes memory path, uint256 amountOut) external returns (uint256 amountIn);

    /// @notice Returns the amount in required to receive the given exact output amount but for a swap of a single pool
    /// @param tokenIn The token being swapped in
    /// @param tokenOut The token being swapped out
    /// @param fee The fee of the token pool to consider for the pair
    /// @param amountOut The desired output amount
    /// @param sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountIn The amount required as the input for the swap in order to receive `amountOut`
    function quoteExactOutputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountOut,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountIn);
}

pragma solidity ^0.6.0;

import "./interfaces/IHasBlackListERC20Token.sol";
import "./interfaces/ISpender.sol";

contract SpenderSimulation {
    ISpender public immutable spender;

    mapping(address => bool) public hasBlackListERC20Tokens;

    modifier checkBlackList(address _tokenAddr, address _user) {
        if (hasBlackListERC20Tokens[_tokenAddr]) {
            IHasBlackListERC20Token hasBlackListERC20Token = IHasBlackListERC20Token(_tokenAddr);
            require(!hasBlackListERC20Token.isBlackListed(_user), "SpenderSimulation: user in token's blacklist");
        }
        _;
    }

    /************************************************************
    *                       Constructor                         *
    *************************************************************/
    constructor (ISpender _spender, address[] memory _hasBlackListERC20Tokens) public {
        spender = _spender;

        for (uint256 i = 0; i < _hasBlackListERC20Tokens.length; i++) {
            hasBlackListERC20Tokens[_hasBlackListERC20Tokens[i]] = true;
        }
    }

    /************************************************************
    *                    Helper functions                       *
    *************************************************************/
    /// @dev Spend tokens on user's behalf but reverts if succeed.
    /// This is only intended to be run off-chain to check if the transfer will succeed.
    /// @param _user The user to spend token from.
    /// @param _tokenAddr The address of the token.
    /// @param _amount Amount to spend.
    function simulate(address _user, address _tokenAddr, uint256 _amount) external checkBlackList(_tokenAddr, _user) {
        spender.spendFromUser(_user, _tokenAddr, _amount);

        // All checks passed: revert with success reason string
        revert("SpenderSimulation: transfer simulation success");
    }
}

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IHasBlackListERC20Token is IERC20 {
    function isBlackListed(address user) external returns (bool);
    function addBlackList(address user) external;
    function removeBlackList(address user) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./upgrade_proxy/TransparentUpgradeableProxy.sol";

contract Tokenlon is TransparentUpgradeableProxy {
    constructor(address _logic, address _admin, bytes memory _data) public payable TransparentUpgradeableProxy(_logic, _admin, _data) {}
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./UpgradeableProxy.sol";

/**
 * @dev This contract implements a proxy that is upgradeable by an admin.
 * 
 * To avoid https://medium.com/nomic-labs-blog/malicious-backdoors-in-ethereum-proxies-62629adf3357[proxy selector
 * clashing], which can potentially be used in an attack, this contract uses the
 * https://blog.openzeppelin.com/the-transparent-proxy-pattern/[transparent proxy pattern]. This pattern implies two
 * things that go hand in hand:
 * 
 * 1. If any account other than the admin calls the proxy, the call will be forwarded to the implementation, even if
 * that call matches one of the admin functions exposed by the proxy itself.
 * 2. If the admin calls the proxy, it can access the admin functions, but its calls will never be forwarded to the
 * implementation. If the admin tries to call a function on the implementation it will fail with an error that says
 * "admin cannot fallback to proxy target".
 * 
 * These properties mean that the admin account can only be used for admin actions like upgrading the proxy or changing
 * the admin, so it's best if it's a dedicated account that is not used for anything else. This will avoid headaches due
 * to sudden errors when trying to call a function from the proxy implementation.
 * 
 * Our recommendation is for the dedicated account to be an instance of the {ProxyAdmin} contract. If set up this way,
 * you should think of the `ProxyAdmin` instance as the real administrative interface of your proxy.
 */
contract TransparentUpgradeableProxy is UpgradeableProxy {
    /**
     * @dev Initializes an upgradeable proxy managed by `_admin`, backed by the implementation at `_logic`, and
     * optionally initialized with `_data` as explained in {UpgradeableProxy-constructor}.
     */
    constructor(address _logic, address _admin, bytes memory _data) public payable UpgradeableProxy(_logic, _data) {
        assert(_ADMIN_SLOT == bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1));
        _setAdmin(_admin);
    }

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 private constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Modifier used internally that will delegate the call to the implementation unless the sender is the admin.
     */
    modifier ifAdmin() {
        if (msg.sender == _admin()) {
            _;
        } else {
            _fallback();
        }
    }

    /**
     * @dev Returns the current admin.
     * 
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyAdmin}.
     * 
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
     */
    function admin() external ifAdmin returns (address) {
        return _admin();
    }

    /**
     * @dev Returns the current implementation.
     * 
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyImplementation}.
     * 
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
     */
    function implementation() external ifAdmin returns (address) {
        return _implementation();
    }

    /**
     * @dev Changes the admin of the proxy.
     * 
     * Emits an {AdminChanged} event.
     * 
     * NOTE: Only the admin can call this function. See {ProxyAdmin-changeProxyAdmin}.
     */
    function changeAdmin(address newAdmin) external ifAdmin {
        require(newAdmin != address(0), "TransparentUpgradeableProxy: new admin is the zero address");
        emit AdminChanged(_admin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev Upgrade the implementation of the proxy.
     * 
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgrade}.
     */
    function upgradeTo(address newImplementation) external ifAdmin {
        _upgradeTo(newImplementation);
    }

    /**
     * @dev Upgrade the implementation of the proxy, and then call a function from the new implementation as specified
     * by `data`, which should be an encoded function call. This is useful to initialize new storage variables in the
     * proxied contract.
     * 
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgradeAndCall}.
     */
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable ifAdmin {
        _upgradeTo(newImplementation);
        // solhint-disable-next-line avoid-low-level-calls
        (bool success,) = newImplementation.delegatecall(data);
        require(success);
    }

    /**
     * @dev Returns the current admin.
     */
    function _admin() internal view returns (address adm) {
        bytes32 slot = _ADMIN_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            adm := sload(slot)
        }
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        bytes32 slot = _ADMIN_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, newAdmin)
        }
    }

    /**
     * @dev Makes sure the admin cannot access the fallback function. See {Proxy-_beforeFallback}.
     */
    function _beforeFallback() internal override virtual {
        require(msg.sender != _admin(), "TransparentUpgradeableProxy: admin cannot fallback to proxy target");
        super._beforeFallback();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";

import "./Proxy.sol";

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 * 
 * Upgradeability is only provided internally through {_upgradeTo}. For an externally upgradeable proxy see
 * {TransparentUpgradeableProxy}.
 */
contract UpgradeableProxy is Proxy {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     * 
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializating the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) public payable {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        _setImplementation(_logic);
        if(_data.length > 0) {
            // solhint-disable-next-line avoid-low-level-calls
            (bool success,) = _logic.delegatecall(_data);
            require(success);
        }
    }

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 private constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal override view returns (address impl) {
        bytes32 slot = _IMPLEMENTATION_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            impl := sload(slot)
        }
    }

    /**
     * @dev Upgrades the proxy to a new implementation.
     * 
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "UpgradeableProxy: new implementation is not a contract");

        bytes32 slot = _IMPLEMENTATION_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, newImplementation)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 * 
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 * 
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     * 
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal virtual view returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     * 
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback () payable external {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive () payable external {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     * 
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 1000
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}