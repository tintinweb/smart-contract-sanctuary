/**
 *Submitted for verification at BscScan.com on 2021-12-23
*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
     * by making the `nonReentrant` function external, and making it call a
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

// File: @openzeppelin/contracts/utils/Context.sol


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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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

// File: contracts/3_Ballot.sol


// email "contracts [at] royalprotocol.io" for licensing information

pragma solidity ^0.8.0;




//import "hardhat/console.sol";

contract GroyGovernor is Ownable, ReentrancyGuard {

    /////// Governor

    using SafeERC20 for IERC20;

    // TODO: consider if this should be the default, yet each initiative stores their voting address token?
    address public groyContractAddress;
    uint public minimumVoteLength = 100; // in blocks

    constructor(address _groyTokenAddress) {
        require(_groyTokenAddress != address(0), "GroyGov: GROY address is zero");
        groyContractAddress = _groyTokenAddress;
        _setDefaultVotingEquations();
        _setDefaultRewardEquations();
    }

    /*
        y=m*x+b  [0-10) y=4*x+0
                 [10-100) y=0.6666*x+3
                 [100-1000) y=0.1111*x+88
                 [1000-10000) y=0.0111*x+188
                 [10000-100000) y=0.0011*x+288
                 [100000-inf) y=400
                 */
    function _setDefaultVotingEquations() private {
        votingEquations.rangeStarts.push(0);
        votingEquations.rangeStarts.push(10 ether);
        votingEquations.rangeStarts.push(100 ether);
        votingEquations.rangeStarts.push(1000 ether);
        votingEquations.rangeStarts.push(10000 ether);
        votingEquations.rangeStarts.push(100000 ether);
        votingEquations.slopes.push(4 ether);
        votingEquations.slopes.push(0.666666666666666666 ether);
        votingEquations.slopes.push(0.111111111111111111 ether);
        votingEquations.slopes.push(0.011111111111111111 ether);
        votingEquations.slopes.push(0.001111111111111111 ether);
        votingEquations.slopes.push(0);
        votingEquations.yIntercepts.push(0);
        votingEquations.yIntercepts.push(33.333333333333333333 ether);
        votingEquations.yIntercepts.push(88.888888888888888888 ether);
        votingEquations.yIntercepts.push(188.888888888888888888 ether);
        votingEquations.yIntercepts.push(288.888888888888888888 ether);
        votingEquations.yIntercepts.push(400 ether);
        votingEquations.addIntercept = true;
        _checkEquations(votingEquations.rangeStarts, votingEquations.slopes, votingEquations.yIntercepts);
    }

    /*
        y=m*x+b  [0-10) y=1*x-0
                 [10-100) y=2*x-10
                 [100-1000) y=3*x-110
                 [1000-10000) y=4*x-1110
                 [10000-100000) y=5*x-11110
                 [100000-inf) y=6*x-111110
                 */
    function _setDefaultRewardEquations() private {
        rewardEquations.rangeStarts.push(0);
        rewardEquations.rangeStarts.push(10 ether);
        rewardEquations.rangeStarts.push(100 ether);
        rewardEquations.rangeStarts.push(1000 ether);
        rewardEquations.rangeStarts.push(10000 ether);
        rewardEquations.rangeStarts.push(100000 ether);
        rewardEquations.slopes.push(1 ether);
        rewardEquations.slopes.push(2 ether);
        rewardEquations.slopes.push(3 ether);
        rewardEquations.slopes.push(4 ether);
        rewardEquations.slopes.push(5 ether);
        rewardEquations.slopes.push(6 ether);
        rewardEquations.yIntercepts.push(0);
        rewardEquations.yIntercepts.push(10 ether);
        rewardEquations.yIntercepts.push(110 ether);
        rewardEquations.yIntercepts.push(1110 ether);
        rewardEquations.yIntercepts.push(11110 ether);
        rewardEquations.yIntercepts.push(111110 ether);
        rewardEquations.addIntercept = false;
        _checkEquations(rewardEquations.rangeStarts, rewardEquations.slopes, rewardEquations.yIntercepts);
    }

    function setMinimumVoteLength(uint _minimumVoteLength) external onlyOwner {
        minimumVoteLength = _minimumVoteLength;
    }

    modifier optionExists(uint _optionId, uint _count) {
        require(_optionId < _count, "GroyGov: Option does not exist");
        _;
    }

    function decreaseVote(uint _optionId, uint _groyAmount) external optionExists(_optionId, optionCount) nonReentrant {
        uint initiativeId = optionToInitiativeId[_optionId];
        Initiative storage initiative = initiatives[initiativeId];
        _requireVoteIsActive(initiative);

        UserInitiativeInfo storage user = userInfo[initiativeId][msg.sender];
        require(user.groyStaked >= _groyAmount, "GroyGov: Amount too large");

        _updateInitiative(initiative.endBlock, initiative, ActionType.WITHDRAW, _groyAmount);

        uint256 pending = user.groyStaked * initiative.accRewardPerShare / 1e12 - user.rewardDebt;
        user.groyStaked -= _groyAmount;
        user.rewardDebt = user.groyStaked * initiative.accRewardPerShare / 1e12;

        mapping(address => uint) storage votesOnOptionId = totalOptionVotesPerUser[_optionId];
        votesOnOptionId[msg.sender] = getVotingScaledValue(user.groyStaked);

        Option storage option = options[_optionId];
        option.groyStaked -= _groyAmount;
        option.totalVotes = _calculateTotalOptionVotes(_optionId);

        emit DecreaseVote(msg.sender, _optionId, _groyAmount);

        IERC20(initiative.rewardToken).safeTransfer(msg.sender, pending);
        IERC20(groyContractAddress).safeTransfer(msg.sender, _groyAmount);
    }

    function getInitiativeVotes(uint _initiativeId) public view returns(uint) {
        uint[] memory optionIds = initiativeToOptions[_initiativeId];
        uint initiativeVotes = 0;
        for (uint i=0; i < optionIds.length; i++) {
            Option memory option = options[optionIds[i]];
            initiativeVotes += option.totalVotes;
        }
        return initiativeVotes;
    }

    function getTotalStakedGroy() external view returns(uint _totalStaked) {
        for (uint i = 0; i < initiativeCount; i++) {
            _totalStaked += initiatives[i].groyStaked;
        }
//        return IERC20(groyContractAddress).balanceOf(address(this)); // cannot use this because both GROY staked and GROY as rewards would be reported
    }

    /// @dev get the total votes on a given option by address
    function getOptionVotes(address _voter, uint _optionId) external view optionExists(_optionId, optionCount) returns(uint) {
        mapping(address => uint) storage votesOnOptionId = totalOptionVotesPerUser[_optionId];
        return votesOnOptionId[_voter];
    }

    function increaseVote(uint _optionId, uint _groyAmount) external optionExists(_optionId, optionCount) nonReentrant {
        _registerVoter(_optionId);

        uint initiativeId = optionToInitiativeId[_optionId];
        _requireOneOptionVoting(_optionId, initiativeId);
        Initiative storage initiative = initiatives[initiativeId];
        _requireVoteIsActive(initiative);
        _updateInitiative(initiative.endBlock, initiative, ActionType.DEPOSIT, _groyAmount);

        UserInitiativeInfo storage user = userInfo[initiativeId][msg.sender];
        user.groyStaked += _groyAmount;
        user.rewardDebt = user.groyStaked * initiative.accRewardPerShare / 1e12;

        mapping(address => uint) storage votesOnOptionId = totalOptionVotesPerUser[_optionId];
        votesOnOptionId[msg.sender] = getVotingScaledValue(user.groyStaked);

        Option storage option = options[_optionId];
        option.totalVotes = _calculateTotalOptionVotes(_optionId);
        option.groyStaked += _groyAmount;

        emit IncreaseVote(msg.sender, _optionId, _groyAmount);

        // Cannot hit this code because lateDeposit is not supported, but if it were then we need to pay out before adjusting
//        if (block.number >= initiative.lastRewardBlock && priorAmount > 0) {
//            uint256 pending = priorAmount * initiative.accRewardPerShare / 1e12 - priorReward;
//            IERC20(initiative.rewardToken).safeTransfer(msg.sender, pending);
//        }

        IERC20(groyContractAddress).safeTransferFrom(msg.sender, address(this), _groyAmount);
    }

    function _calculateTotalOptionVotes(uint _optionId) private view returns (uint _totalVotes) {
        mapping(address => uint) storage votesOnOptionId = totalOptionVotesPerUser[_optionId];
        uint initId = optionToInitiativeId[_optionId];
        address[] memory voters = initiativeToVoters[initId];
        //_totalVotes = 0; // needed?
        for (uint i = 0; i < voters.length; i++) {
            address voter = voters[i];
            _totalVotes += votesOnOptionId[voter];
        }
    }

    /// @dev Only allow votes to be cast on _optionId - if any other votes were cast by this user, then revert
    function _requireOneOptionVoting(uint _optionId, uint _initiativeId) internal view {
        uint[] memory optionIds = initiativeToOptions[_initiativeId];
        for (uint i = 0; i < optionIds.length; i++) {
            uint optionId = optionIds[i];
            if (optionId == _optionId) {
                continue; // skip the one we are allowing
            }
            mapping(address => uint) storage votesOnOptionId = totalOptionVotesPerUser[optionId];
            require(votesOnOptionId[msg.sender] == 0, "GroyGov: No multi-option voting"); // this is wrong we need the options per user
        }
    }

    function estimateRewards(uint _initiativeId) external view initiativeExists(_initiativeId, initiativeCount) returns(uint) {
        UserInitiativeInfo memory user = userInfo[_initiativeId][msg.sender];
        uint userRewardCount = getRewardScaledValue(user.groyStaked);
        uint totalRewardCount = _calculateTotalInitiativeRewards(_initiativeId);
        if (totalRewardCount == 0) {
            return 0;
        }

        Initiative memory initiative = initiatives[_initiativeId];
        return (userRewardCount * initiative.rewardAmount) / totalRewardCount;
    }

    function _calculateTotalInitiativeRewards(uint _initiativeId) private view returns (uint _totalRewards) {
        address[] memory voters = initiativeToVoters[_initiativeId];
        for (uint i = 0; i < voters.length; i++) {
            address voter = voters[i];
            UserInitiativeInfo memory user = userInfo[_initiativeId][voter];
            _totalRewards += getRewardScaledValue(user.groyStaked);
        }
    }

    function claimRewards(uint _initiativeId) external initiativeExists(_initiativeId, initiativeCount) nonReentrant {
        UserInitiativeInfo storage user = userInfo[_initiativeId][msg.sender];
        require(user.groyStaked > 0, "GroyGov: No GROY staked");

        Initiative storage initiative = initiatives[_initiativeId];

        _updateInitiative(initiative.endBlock, initiative, ActionType.CLAIM_REWARD, user.groyStaked);

        emit ClaimRewards(msg.sender, _initiativeId);

        uint256 pending = user.groyStaked * initiative.accRewardPerShare / 1e12 - user.rewardDebt;
        user.rewardDebt = user.groyStaked * initiative.accRewardPerShare / 1e12;
        IERC20(initiative.rewardToken).safeTransfer(msg.sender, pending);

        if (block.number > initiative.endBlock) { // pay out GROY if voter claims rewards and the vote has ended
            uint256 amount = user.groyStaked;
            //slither-disable-next-line reentrancy-no-eth
            user.groyStaked = 0;
            IERC20(groyContractAddress).safeTransfer(msg.sender, amount);
        }
    }

    enum ActionType { WITHDRAW, DEPOSIT, CLAIM_REWARD }

    /**
     * @dev Update reward variables of the given pool to be up-to-date.
     */
    function _updateInitiative(uint _endBlock, Initiative storage _initiative, ActionType _actionType, uint _groyAmount) private {
        uint oldTotal = _initiative.groyStaked;
        if (_actionType == ActionType.WITHDRAW) {
            _initiative.groyStaked -= _groyAmount;
        } else if (_actionType == ActionType.DEPOSIT) {
            _initiative.groyStaked += _groyAmount;
        } else if ((_actionType == ActionType.CLAIM_REWARD) && (block.number > _endBlock)) {
            _initiative.groyStaked -= _groyAmount;
        }
        uint256 upperBlock = block.number > _endBlock + 1 ? _endBlock + 1 : block.number;
        //slither-disable-next-line incorrect-equality
        if (block.number <= _initiative.lastRewardBlock || upperBlock == _initiative.lastRewardBlock) {
            return;
        }

        uint256 multiplier = upperBlock - _initiative.lastRewardBlock;
        uint256 reward = multiplier * _initiative.rewardPerBlock;

        _initiative.accRewardPerShare += reward * 1e12 / oldTotal;
        _initiative.lastRewardBlock = upperBlock;
    }

    function _requireVoteIsActive(Initiative memory _initiative) private view {
        require(block.number <= _initiative.endBlock, "GroyGov: Vote has ended");
        require(block.number <= _initiative.lockBlock, "GroyGov: Vote is locked");
        require(block.number >= _initiative.startBlock, "GroyGov: Vote not started");
    }

    function _registerVoter(uint _optionId) private {
        uint initiativeId = optionToInitiativeId[_optionId];
        address[] storage voters = initiativeToVoters[initiativeId];
        if (!_arrayContainsAddress(voters, msg.sender)) {
            voters.push(msg.sender);
        }
        uint[] storage voterInitiatives = voterToInitiatives[msg.sender];
        if (!_arrayContainsInt(voterInitiatives, initiativeId)) {
            voterInitiatives.push(initiativeId);
        }
    }

    function _arrayContainsAddress(address[] memory _array, address _value) internal pure returns(bool) {
        for (uint i=0; i < _array.length; i++) {
            if (_value == _array[i]) {
                return true;
            }
        }
        return false;
    }

    function _arrayContainsInt(uint[] memory _array, uint _value) internal pure returns(bool) {
        for (uint i=0; i < _array.length; i++) {
            if (_value == _array[i]) {
                return true;
            }
        }
        return false;
    }

    bool private creationEnabled = true;

    function enableCreation(bool _value) external onlyOwner {
        creationEnabled = _value;
    }

    /**
     * @notice All voting must be stopped before the address can be changed, or some active votes would lose tokens
     */
    function updateGroyTokenContract(address _groyTokenAddress) external onlyOwner {
        require(_groyTokenAddress != address(0), "GroyGov: GROY address is zero");
        _checkInitiativesFinished();
        groyContractAddress = _groyTokenAddress;
    }

    /**
     * @dev Ensure that initiative create is disabled and that all have finished
     */
    function _checkInitiativesFinished() private view {
        require(!creationEnabled, "GroyGov: Disable creation first");
        require(_initiativesFinished(), "GroyGov: Initiatives must finish");
    }

    /**
     * @dev Returns true if all initiatives have finished (i.e. there are none active) else false
     */
    function _initiativesFinished() private view returns(bool) {
        for (uint i = 0; i <= initiativeCount; i++) {
            Initiative memory initiative = initiatives[i];
            if (initiative.endBlock >= block.number) {
                return false;
            }
        }
        return true;
    }

    /////// Initiatives

    struct Initiative { // Similar to a proposal
        address initiator;
        uint startBlock;
        uint lockBlock;
        uint endBlock;
        string description;
        address rewardToken;
        uint rewardAmount;
        uint groyStaked;
        uint accRewardPerShare;
        uint lastRewardBlock;
        uint rewardPerBlock;
    }

    uint public initiativeCount;

    enum InitiativeState {
        Pending,
        Active,
        Locked,
        Ended
    }

    /// @dev Storage of Initiative ID to Initiative objects (structs)
    mapping (uint => Initiative) public initiatives;

    mapping (address => uint[]) public initiatorToInitiatives;

    mapping (uint => address[]) public initiativeToVoters;
    mapping (address => uint[]) public voterToInitiatives;

    /// @notice Info of each user.
    struct UserInitiativeInfo {
        uint256 groyStaked; // How many tokens the user has voted.
        uint256 rewardDebt; // Reward debt. See explanation below.

        // We do some fancy math here. Basically, any point in time, the amount of tokens
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.groyStaked * pool.accRewardPerShare) - user.rewardDebt
        //
        // Whenever a user increaseVotes or decreaseVotes tokens to a initiative. Here's what happens:
        //   1. The initiative's `accRewardPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    /// @notice Maps the initiative ID to a mapping of voter to user info
    mapping(uint256 => mapping(address => UserInitiativeInfo)) public userInfo;

    function getInitiativesFromInitiator(address _account) external view returns (uint[] memory) {
        return initiatorToInitiatives[_account];
    }

    function getInitiativesInState(InitiativeState _state) external view returns (uint[] memory) {
        uint count = 0;
        for (uint i = 0; i < initiativeCount; i ++) {
            InitiativeState currentState = state(i);
            if (currentState == _state) {
                count++;
            }
        }
        uint[] memory initiativesInState = new uint[](count);
        uint storeCount = 0;
        for (uint i = 0; i < initiativeCount; i ++) {
            InitiativeState currentState = state(i);
            if (currentState == _state) {
                initiativesInState[storeCount] = i;
                storeCount++;
            }
        }
        return initiativesInState;
    }

    function getInitiativesFromVoter(address _account) external view returns (uint[] memory) {
        return voterToInitiatives[_account];
    }

    function getVotersFromInitiative(uint _initiativeId) external view returns (address[] memory) {
        return initiativeToVoters[_initiativeId];
    }

    bool private anyoneCanCreate = false;

    function enableAnyoneCanCreate(bool _value) external onlyOwner {
        anyoneCanCreate = _value;
    }

    /**
     * @dev Throws if called by any account other than the owner, unless anyone can create is true
     */
    modifier onlyOwnerOrAnyone() {
        require(anyoneCanCreate || (owner() == msg.sender), "GroyGov: caller is not the owner");
        _;
    }

    function createInitiative(uint _startBlock, uint _lockBlock, uint _endBlock, address _rewardToken,
            uint _rewardAmount, string memory _description, string[] memory _options)
        external onlyOwnerOrAnyone nonReentrant
    {
        require(creationEnabled, "GroyGov: Creation is disabled");
        require(_startBlock > block.number, "GroyGov: Start is in the past");
        require(_startBlock <= _lockBlock, "GroyGov: Start > lock block");
        require(_lockBlock <= _endBlock, "GroyGov: Lock block > end block");
        require(_endBlock - _startBlock >= minimumVoteLength, "GroyGov: Vote is too short");
//        require(_lockBlock - _startBlock >= minimumVoteLength, "GroyGov: Vote is too short");
        require(_options.length >= 2, "GroyGov: Requires 2+ options");

        uint id = initiativeCount;
        Initiative storage initiative = initiatives[id];
        initiative.initiator = msg.sender;
        initiative.startBlock = _startBlock;
        initiative.lockBlock = _lockBlock;
        initiative.endBlock = _endBlock;
        initiative.description = _description;

        initiative.rewardToken = _rewardToken;
        initiative.rewardAmount = _rewardAmount;
        initiative.lastRewardBlock = block.number > _lockBlock + 1 ? block.number : _lockBlock + 1;
        initiative.rewardPerBlock = _rewardAmount / (_endBlock - _lockBlock);

        uint[] storage initiatorInitiatives = initiatorToInitiatives[msg.sender];
        initiatorInitiatives.push(id);

        initiativeCount++;

        emit InitiativeCreated(
            id,
            msg.sender,
            initiative.startBlock,
            initiative.lockBlock,
            initiative.endBlock,
            initiative.rewardToken,
            initiative.rewardAmount,
            initiative.description
        );

        for (uint i = 0; i < _options.length; i++) {
            _createOption(_options[i], id);
        }

        // The owner must transfer the tokens in before claimReward... we no longer send this on creation:
//        IERC20(initiative.rewardToken).safeTransferFrom(msg.sender, address(this), _rewardAmount);
    }

    event InitiativeCreated(
        uint indexed initiativeId, address indexed initiator,
        uint startBlock, uint lockBlock, uint endBlock,
        address rewardToken, uint rewardAmount,
        string description
    );

    function state(uint _initiativeId) public view returns (InitiativeState) {
        Initiative memory initiative = initiatives[_initiativeId];
        if (block.number < initiative.startBlock) {
            return InitiativeState.Pending;
        } else if (block.number > initiative.endBlock) {
            return InitiativeState.Ended;
        }  else if (block.number < initiative.lockBlock) {
            return InitiativeState.Active;
        } else {
            return InitiativeState.Locked;
        }
    }

    modifier initiativeExists(uint _initiativeId, uint _count) {
        require(_initiativeId < _count, "GroyGov: Missing initiative");
        _;
    }

    /////// Options

    event IncreaseVote(
        address indexed voter,
        uint indexed initiativeId,
        uint votes
    );

    event DecreaseVote(
        address indexed voter,
        uint indexed initiativeId,
        uint votes
    );

    event ClaimRewards(
        address indexed voter,
        uint indexed initiativeId
    );

    struct Option {
        uint totalVotes;
        uint groyStaked;
        string description;
    }

    uint public optionCount;

    /// @dev Storage of Option ID to Initiative objects (structs)
    mapping (uint => Option) public options;

    /// @dev Storage of Option ID to Voter ID/Address to the vote count
    mapping (uint => mapping(address => uint)) public totalOptionVotesPerUser;

    mapping (uint => uint) public optionToInitiativeId;

    /// @dev Initiative to list of Options, getter will require option list index
    mapping (uint => uint[]) public initiativeToOptions;

    function getOptionsFromInitiative(uint _initiativeId) external view returns (uint[] memory) {
        return initiativeToOptions[_initiativeId];
    }

    function getInitiativeFromOption(uint _optionId) external view returns (uint) {
        return optionToInitiativeId[_optionId];
    }

    function withdrawExcess(address _tokenAddress, uint _amount) external onlyOwner {
        IERC20(_tokenAddress).safeTransfer(owner(), _amount);
    }

    /// @dev The first option has an advantage in a tie. Users must select their first option carefully.
    function getWinningOption(uint _initiativeId) external view initiativeExists(_initiativeId, initiativeCount) returns (uint) {
        Initiative memory initiative = initiatives[_initiativeId];
        require(block.number >= initiative.endBlock, "GroyGov: Vote has not ended yet");
        uint[] memory optionIds = initiativeToOptions[_initiativeId];
        uint winOptionId = 0;
        Option memory winOption = options[optionIds[0]];
        Option memory option;
        for (uint i=1; i < optionIds.length; i++) {
            option = options[optionIds[i]];
            if (option.totalVotes > winOption.totalVotes) {
                winOptionId = optionIds[i];
                winOption = option;
            }
        }
        return winOptionId;
    }

    function _createOption(string memory _description, uint _initiativeId) internal {
        uint id = optionCount;
        Option storage option = options[optionCount++];
        option.description = _description;
        optionToInitiativeId[id] = _initiativeId;
        initiativeToOptions[_initiativeId].push(id);
        emit OptionCreated(msg.sender, id, _description);
    }

    event OptionCreated(address indexed initiator, uint indexed optionId, string description);

    ///// Scaling

    struct EquationSeries {
        uint[] rangeStarts; // continuous, we go until next
        uint[] slopes;
        uint[] yIntercepts;
        bool addIntercept;
    }

    EquationSeries public votingEquations;
    EquationSeries public rewardEquations;

    /*
     This function estimates exponential decay and exponential growth
     This is done using a system of equations similar to a taylor series
     x=0
     |          ____
     |      ___/
     |   __/
     | _/
     |/_____________ y=0
     This can be modeled using:
        y=m*x+b  [0-10) y=4*x+0   --> we know we want the next one to connect, so @ x=10, y=40
                 [10-100) y=2*x+20   <-- solving the above but for our new equation y=2*x+b @ x=10 and y=40 thus b=20
                          ^-----+--- y = m2 * x + b2 => set equal at expected intersect (x=10) m2*x + b2 = m1*x + b1 ==> b2 = m1*x + b1 - m2 * x
                                ^--- b2 = 4 * (10) + 0 - 2 * (10) = 20
                 [100-1000) y=1*x+120          <-- b2 = 2 * (100) + 20 - 1 * (100) = 120
                 [1000-10000) y=1/2*x+620      <-- b2 = 1 * (1000) + 120 - 1/2 * (1000) = 620
                 [10000-100000) y=1/4*x+3120   <-- b2 = 1/2 * (10000) + 620 - 1/4 * (10000) = 3120
                 [100000-inf) y=28120          <-- b2 = 1/4 * (100000) + 3120 - 0 * (100000) = 28120

        The above would be fed in as: [0, 10, 100, 1000, 10000, 100000], [4, 2, 1, 0.5, 0.25, 0], [0, 20, 120, 620, 3120]

        If we want just a standard linear relationship, then we use: [0], [1], [0] for y = 1*x + 0 from 0 to inf
     */
    function updateVotingEquations(uint[] memory _rangeStarts, uint[] memory _slopes, uint[] memory _yIntercepts, bool _addIntercept) public onlyOwner {
        _checkEquations(_rangeStarts, _slopes, _yIntercepts);
        _checkInitiativesFinished();
        votingEquations.rangeStarts = _rangeStarts;
        votingEquations.slopes = _slopes;
        votingEquations.yIntercepts = _yIntercepts;
        votingEquations.addIntercept = _addIntercept;
    }

    function updateRewardEquations(uint[] memory _rangeStarts, uint[] memory _slopes, uint[] memory _yIntercepts, bool _addIntercept) public onlyOwner {
        _checkEquations(_rangeStarts, _slopes, _yIntercepts);
        _checkInitiativesFinished();
        rewardEquations.rangeStarts = _rangeStarts;
        rewardEquations.slopes = _slopes;
        rewardEquations.yIntercepts = _yIntercepts;
        rewardEquations.addIntercept = _addIntercept;
    }

    function _checkEquations(uint[] memory _rangeStarts, uint[] memory _slopes, uint[] memory _yIntercepts) private pure {
        require(_rangeStarts.length > 0, "GroyGov: Requires 1+ equation");
        require(_rangeStarts.length == _slopes.length, "GroyGov: Mismatching array sizes");
        require(_rangeStarts.length == _yIntercepts.length, "GroyGov: Mismatching array sizes");
    }

    function getVotingScaledValue(uint _input) public view returns (uint _scaledOutput) {
        _scaledOutput = _scaleValue(votingEquations, _input);
    }

    function getRewardScaledValue(uint _input) public view returns (uint _scaledOutput) {
        _scaledOutput = _scaleValue(rewardEquations, _input);
    }

    /// @dev The slopes are in ether so that they can have decimals, but we must remove that as it is supposed to be a
    /// unitless ratio, this is why we divide by 1 ether below
    function _scaleValue(EquationSeries memory _equations, uint _input) private pure returns (uint _scaledOutput) {
        uint index = 0;
        for (uint i = 0; i < _equations.rangeStarts.length; i++) {
            if (_input < (_equations.rangeStarts[i])) {
                break;
            }
            index = i;
        }
        if (_equations.addIntercept) {
            _scaledOutput = (_equations.slopes[index] * _input) / 1 ether + (_equations.yIntercepts[index]);
        } else {
            _scaledOutput = (_equations.slopes[index] * _input) / 1 ether - (_equations.yIntercepts[index]);
        }
    }
}