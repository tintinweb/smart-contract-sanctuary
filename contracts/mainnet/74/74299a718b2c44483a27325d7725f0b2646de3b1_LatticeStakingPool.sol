/**
 *Submitted for verification at Etherscan.io on 2021-08-03
*/

// File: @openzeppelin/contracts/utils/math/SafeMath.sol

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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol

pragma solidity ^0.8.0;

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

    constructor() {
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

// File: @openzeppelin/contracts/utils/Address.sol

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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol

pragma solidity ^0.8.0;



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
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
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
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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

// File: LatticeStakingPool.sol

pragma solidity 0.8.6;





contract LatticeStakingPool is ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct StakingPool {
        uint256 maxStakingAmountPerUser;
        uint256 totalAmountStaked;
        address[] usersStaked;
    }
    
    struct Project {
        string name;
        uint256 totalAmountStaked;
        uint256 numberOfPools;
        uint256 startBlock; 
        uint256 endBlock;
    }
    
    struct UserInfo{
        address userAddress;
        uint256 poolId;
        uint256 percentageOfTokensStakedInPool;
        uint256 amountOfTokensStakedInPool;
    }
    
    IERC20 public stakingToken;
    
    address private owner;
    
    Project[] public projects;
    
    /// @notice ProjectID => WhitelistedAddress
    mapping(uint256 => mapping(address => bool)) public projectIdToWhitelistedAddress;
    
    /// @notice ProjectID => WhitelistedArray
    mapping(uint256 => address[]) private projectIdToWhitelistedArray;
    
    /// @notice ProjectID => Pool ID => User Address => amountStaked
    mapping(uint256 => mapping(uint256 => mapping(address => uint256))) public userStakedAmount;
    
    /// @notice ProjectID => Pool ID => User Address => didUserWithdrawFunds
    mapping(uint256 => mapping(uint256 => mapping(address => bool))) public didUserWithdrawFunds;
    
    /// @notice ProjectID => Pool ID => StakingPool
    mapping(uint256 => mapping(uint256 => StakingPool)) public stakingPoolInfo;
    
    /// @notice ProjectName => isProjectNameTaken
    mapping(string=>bool) public isProjectNameTaken;
    
    /// @notice ProjectName => ProjectID
    mapping(string=>uint256) public projectNameToProjectId;
    
    event Deposit(
        address indexed _user, 
        uint256 indexed _projectId, 
        uint256 indexed _poolId, 
        uint256 _amount
    );
    event Withdraw(
        address indexed _user, 
        uint256 indexed _projectId, 
        uint256 indexed _poolId, 
        uint256 _amount
    );
    event PoolAdded(uint256 indexed _projectId, uint256 indexed _poolId);
    event ProjectDisabled(uint256 indexed _projectId);
    event ProjectAdded(uint256 indexed _projectId, string _projectName);
    
    constructor(IERC20 _stakingToken) {
        require(
            address(_stakingToken) != address(0),
            "constructor: _stakingToken must not be zero address"
        );
        
        owner = msg.sender;
        stakingToken = _stakingToken;
    }
    
    function addProject(string memory _name, uint256 _startBlock, uint256 _endBlock) external {
        require(msg.sender == owner, "addNewProject: Caller is not the owner");
        require(bytes(_name).length > 0 , "addNewProject: Project name cannot be empty string.");
        require(
            _startBlock >= block.number, 
            "addNewProject: startBlock is less than the current block number."
        );
        require(
            _startBlock < _endBlock, 
            "addNewProject: startBlock is greater than or equal to the endBlock."
        );
        require(!isProjectNameTaken[_name], "addNewProject: project name already taken.");
        
        Project memory project;
        project.name = _name;  
        project.startBlock = _startBlock;
        project.endBlock = _endBlock;
        project.numberOfPools = 0;        
        project.totalAmountStaked = 0;    
        
        uint256 projectsLength = projects.length;
        projects.push(project);
        projectNameToProjectId[_name] = projectsLength;
        isProjectNameTaken[_name] = true;
        
        emit ProjectAdded(projectsLength, _name);
    }
    
    function addStakingPool(uint256 _projectId, uint256 _maxStakingAmountPerUser) external {
        require(msg.sender == owner, "addStakingPool: Caller is not the owner.");
        require(_projectId < projects.length, "addStakingPool: Invalid project ID.");
    
        StakingPool memory stakingPool;
        stakingPool.maxStakingAmountPerUser = _maxStakingAmountPerUser;
        stakingPool.totalAmountStaked=0;
        
        uint256 numberOfPoolsInProject = projects[_projectId].numberOfPools;
        stakingPoolInfo[_projectId][numberOfPoolsInProject] = stakingPool;
        projects[_projectId].numberOfPools = projects[_projectId].numberOfPools+1;
        
        emit PoolAdded(_projectId,projects[_projectId].numberOfPools);
    }
    
    function disableProject(uint256 _projectId) external {
        require(msg.sender == owner, "disableProject: Caller is not the owner");
        require(_projectId < projects.length, "disableProject: Invalid project ID.");
        
        projects[_projectId].endBlock = block.number;
        
        emit ProjectDisabled(_projectId);
    }
    
    function deposit (uint256 _projectId, uint256 _poolId, uint256 _amount) external nonReentrant {
        require(
            projectIdToWhitelistedAddress[_projectId][msg.sender], 
            "deposit: Address is not whitelisted for this project."
        );
        require(_amount > 0, "deposit: Amount not specified.");
        require(_projectId < projects.length, "deposit: Invalid project ID.");
        require(_poolId < projects[_projectId].numberOfPools, "deposit: Invalid pool ID.");
        require(
            block.number <= projects[_projectId].endBlock, 
            "deposit: Staking no longer permitted for this project."
        );
        require(
            block.number >= projects[_projectId].startBlock, 
            "deposit: Staking is not yet permitted for this project."
        );
        
        uint256 _userStakedAmount = userStakedAmount[_projectId][_poolId][msg.sender];
        if(stakingPoolInfo[_projectId][_poolId].maxStakingAmountPerUser > 0){
            require(
                _userStakedAmount.add(_amount) <= stakingPoolInfo[_projectId][_poolId].maxStakingAmountPerUser, 
                "deposit: Cannot exceed max staking amount per user."
            );
        }
        
        if(userStakedAmount[_projectId][_poolId][msg.sender] == 0){
            stakingPoolInfo[_projectId][_poolId].usersStaked.push(msg.sender);
        }
        
        projects[_projectId].totalAmountStaked 
        = projects[_projectId].totalAmountStaked.add(_amount);
        
        stakingPoolInfo[_projectId][_poolId].totalAmountStaked 
        = stakingPoolInfo[_projectId][_poolId].totalAmountStaked.add(_amount);
        
        userStakedAmount[_projectId][_poolId][msg.sender] 
        = userStakedAmount[_projectId][_poolId][msg.sender].add(_amount);
        
        stakingToken.safeTransferFrom(address(msg.sender), address(this), _amount);
        
        emit Deposit(msg.sender, _projectId, _poolId,  _amount);
    }
    
    function withdraw (uint256  _projectId, uint256 _poolId) external nonReentrant {
        require(
            projectIdToWhitelistedAddress[_projectId][msg.sender], 
            "withdraw: Address is not whitelisted for this project."
        );
        require(_projectId < projects.length, "withdraw: Invalid project ID.");
        require(_poolId < projects[_projectId].numberOfPools, "withdraw: Invalid pool ID.");
        require(block.number > projects[_projectId].endBlock, "withdraw: Not yet permitted.");
        require(
            !didUserWithdrawFunds[_projectId][_poolId][msg.sender], 
            "withdraw: User has already withdrawn funds for this pool."
        );
        
        uint256 _userStakedAmount = userStakedAmount[_projectId][_poolId][msg.sender];
        require(_userStakedAmount > 0, "withdraw: No stake to withdraw.");
        didUserWithdrawFunds[_projectId][_poolId][msg.sender] = true;
        
        stakingToken.safeTransfer(msg.sender, _userStakedAmount);
        
        emit Withdraw(msg.sender, _projectId, _poolId, _userStakedAmount);
    }
    
    function whitelistAddresses( 
        uint256 _projectId, 
        address[] memory _newAddressesToWhitelist
    ) external {
        require(msg.sender == owner, "whitelistAddresses: Caller is not the owner");
        require(_projectId < projects.length, "whitelistAddresses: Invalid project ID.");
        require(
            _newAddressesToWhitelist.length > 0, 
            "whitelistAddresses: Addresses array is empty."
        );
        
        for (uint i=0; i < _newAddressesToWhitelist.length; i++) {
            if(!projectIdToWhitelistedAddress[_projectId][_newAddressesToWhitelist[i]]){
                projectIdToWhitelistedAddress[_projectId][_newAddressesToWhitelist[i]] = true;
                projectIdToWhitelistedArray[_projectId].push(_newAddressesToWhitelist[i]);
            }
        }
    }
    
    function getWhitelistedAddressesForProject(
        uint256 _projectId
    ) external view returns(address[] memory){
        require(msg.sender == owner, "getWhitelistedAddressesForProject: Caller is not the owner");
        
        return projectIdToWhitelistedArray[_projectId];
    }
    
    function isAddressWhitelisted(
        uint256 _projectId,
        address _address
    ) external view returns(bool){
        require(_projectId < projects.length, "isAddressWhitelisted: Invalid project ID.");
        
        return projectIdToWhitelistedAddress[_projectId][_address];
    }
        
    function getTotalStakingInfoForProjectPerPool(
        uint256 _projectId,
        uint256 _poolId,
        uint256 _pageNumber,
        uint256 _pageSize
    )external view returns (UserInfo[] memory){
        require(msg.sender == owner, "getTotalStakingInfoForProjectPerPool: Caller is not the owner.");
        require(
            _projectId < projects.length, 
            "getTotalStakingInfoForProjectPerPool: Invalid project ID."
        );
        require(
            _poolId < projects[_projectId].numberOfPools, 
            "getTotalStakingInfoForProjectPerPool: Invalid pool ID."
        );
        uint256 _usersStakedInPool = stakingPoolInfo[_projectId][_poolId].usersStaked.length;
        require(
            _usersStakedInPool > 0, 
            "getTotalStakingInfoForProjectPerPool: Nobody staked in this pool."
        );
        require(
            _pageSize > 0, 
            "getTotalStakingInfoForProjectPerPool: Invalid page size."
        );
        require(
            _pageNumber > 0, 
            "getTotalStakingInfoForProjectPerPool: Invalid page number."
        );
        uint256 _startIndex = _pageNumber.sub(1).mul(_pageSize);

        if(_pageNumber > 1){
            require(
                _startIndex < _usersStakedInPool,
                "getTotalStakingInfoForProjectPerPool: Specified parameters exceed number of users in the pool."
            );
        }

        uint256 _endIndex = _pageNumber.mul(_pageSize);
        if(_endIndex > _usersStakedInPool){
            _endIndex = _usersStakedInPool;
        }
        
        UserInfo[] memory _result = new UserInfo[](_endIndex.sub(_startIndex));
        uint256 _resultIndex = 0;

        for(uint256 i=_startIndex; i < _endIndex; i++){
            UserInfo memory _userInfo;
            _userInfo.userAddress = stakingPoolInfo[_projectId][_poolId].usersStaked[i];
            _userInfo.poolId = _poolId;
            _userInfo.percentageOfTokensStakedInPool 
            = getPercentageAmountStakedByUserInPool(_projectId,_poolId,_userInfo.userAddress);
            
            _userInfo.amountOfTokensStakedInPool 
            = getAmountStakedByUserInPool(_projectId,_poolId,_userInfo.userAddress);
            
            _result[_resultIndex]=_userInfo;
            _resultIndex = _resultIndex + 1;
        }
        
        return _result;
    }
    
    function numberOfProjects() external view returns (uint256) {
        return projects.length;
    }
    
    function numberOfPools(uint256 _projectId) external view returns (uint256) {
        require(_projectId < projects.length, "numberOfPools: Invalid project ID.");
        return projects[_projectId].numberOfPools;
    }
    
    function getTotalAmountStakedInProject(uint256 _projectId) external view returns (uint256) {
        require(
            _projectId < projects.length, 
            "getTotalAmountStakedInProject: Invalid project ID."
        );
        
        return projects[_projectId].totalAmountStaked;
    }
    
    function getTotalAmountStakedInPool(
        uint256 _projectId,
        uint256 _poolId
    ) external view returns (uint256) {
        require(_projectId < projects.length, "getTotalAmountStakedInPool: Invalid project ID.");
        require(
            _poolId < projects[_projectId].numberOfPools, 
            "getTotalAmountStakedInPool: Invalid pool ID."
        );
        
        return stakingPoolInfo[_projectId][_poolId].totalAmountStaked;
    }
    
    function getAmountStakedByUserInPool(
        uint256 _projectId,
        uint256 _poolId, 
        address _address
    ) public view returns (uint256) {
        require(_projectId < projects.length, "getAmountStakedByUserInPool: Invalid project ID.");
        require(
            _poolId < projects[_projectId].numberOfPools, 
            "getAmountStakedByUserInPool: Invalid pool ID."
        );  
        
        return userStakedAmount[_projectId][_poolId][_address];
    }
    
    function getPercentageAmountStakedByUserInPool(
        uint256 _projectId,
        uint256 _poolId, 
        address _address
    ) public view returns (uint256) {
        require(
            _projectId < projects.length, 
            "getPercentageAmountStakedByUserInPool: Invalid project ID."
        );
        require(
            _poolId < projects[_projectId].numberOfPools, 
            "getPercentageAmountStakedByUserInPool: Invalid pool ID."
        );  
        
        return userStakedAmount[_projectId][_poolId][_address]
               .mul(1e8)
               .div(stakingPoolInfo[_projectId][_poolId]
               .totalAmountStaked);
    }
}