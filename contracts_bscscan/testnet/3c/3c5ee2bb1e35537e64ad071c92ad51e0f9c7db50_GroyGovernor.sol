/**
 *Submitted for verification at BscScan.com on 2021-12-21
*/

/** 
 *  SourceUnit: /home/nikc/groy-voting/contracts/GroyGovernor.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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




/** 
 *  SourceUnit: /home/nikc/groy-voting/contracts/GroyGovernor.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [////IMPORTANT]
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
     * ////IMPORTANT: because control is transferred to `recipient`, care must be
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




/** 
 *  SourceUnit: /home/nikc/groy-voting/contracts/GroyGovernor.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
     * ////IMPORTANT: Beware that changing an allowance with this method brings the risk
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




/** 
 *  SourceUnit: /home/nikc/groy-voting/contracts/GroyGovernor.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

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




/** 
 *  SourceUnit: /home/nikc/groy-voting/contracts/GroyGovernor.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

////import "../utils/Context.sol";

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




/** 
 *  SourceUnit: /home/nikc/groy-voting/contracts/GroyGovernor.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

////import "../IERC20.sol";
////import "../../../utils/Address.sol";

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


/** 
 *  SourceUnit: /home/nikc/groy-voting/contracts/GroyGovernor.sol
*/

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING:  CC-BY-NC-4.0
// email "contracts [at] royalprotocol.io" for licensing information

pragma solidity ^0.8.0;

////import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
////import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
////import "@openzeppelin/contracts/access/Ownable.sol";
////import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
//////import "hardhat/console.sol";

contract GroyGovernor is Ownable, ReentrancyGuard {

    /////// Governor

    using SafeERC20 for IERC20;

    // TODO: consider if this should be the default, yet each initiative stores their voting address token?
    address public groyContractAddress;
    uint public minimumVoteLength = 100; // in blocks

    constructor(address _tokenAddress) {
        require(_tokenAddress != address(0), "Vote token address is zero");
        groyContractAddress = _tokenAddress;
    }

    function setMinimumVoteLength(uint _minimumVoteLength) external onlyOwner {
        minimumVoteLength = _minimumVoteLength;
    }

    function decreaseVote(uint optionId, uint amount) external optionExists(optionId, optionCount) nonReentrant {
        uint initiativeId = optionToInitiativeId[optionId];
        Initiative storage initiative = initiatives[initiativeId];
        _requireVoteIsActive(initiative);

        UserInfo storage user = userInfo[initiativeId][msg.sender];
        require(user.amount >= amount, "Vote removal amount too large");

        _updateInitiative(initiative.endBlock, initiative, ActionType.WITHDRAW, amount);

        uint256 pending = user.amount * initiative.accRewardPerShare / 1e12 - user.rewardDebt;
        user.amount -= amount;
        user.rewardDebt = user.amount * initiative.accRewardPerShare / 1e12;

        Option storage option = options[optionId];
        option.groyStaked -= amount;

        emit DecreaseVote(msg.sender, optionId, amount);

        IERC20(initiative.rewardToken).safeTransfer(msg.sender, pending);
        IERC20(groyContractAddress).safeTransfer(msg.sender, amount);
    }

    function getInitiativeVotes(uint initiativeId) external view returns(uint) {
        uint[] memory optionIds = initiativeToOptions[initiativeId];
        uint initiativeVotes = 0;
        for (uint i=0; i < optionIds.length; i++) {
            Option memory option = options[optionIds[i]];
            initiativeVotes += option.totalVotes;
        }
        return initiativeVotes;
    }

    function getTotalStakedGroy() external view returns(uint) {
        return IERC20(groyContractAddress).balanceOf(address(this));
    }

    /// @dev get the total votes on a given option by address
    function getOptionVotes(address voter, uint optionId) external view optionExists(optionId, optionCount) returns(uint) {
        mapping(address => uint) storage votesOnOptionId = totalOptionVotesPerUser[optionId];
        return votesOnOptionId[voter];
    }

    function increaseVote(uint optionId, uint amount) external optionExists(optionId, optionCount) nonReentrant {
        _registerVoter(optionId);

        uint initiativeId = optionToInitiativeId[optionId];
        Initiative storage initiative = initiatives[initiativeId];
        _requireVoteIsActive(initiative);
        mapping(address => uint) storage votesOnOptionId = totalOptionVotesPerUser[optionId];

        UserInfo storage user = userInfo[initiativeId][msg.sender];

        _updateInitiative(initiative.endBlock, initiative, ActionType.DEPOSIT, amount);

        Option storage option = options[optionId];
        option.totalVotes += amount;
        option.groyStaked += amount;
        votesOnOptionId[msg.sender] += amount;

        uint priorAmount = user.amount;
        user.amount += amount;
        uint priorReward = user.rewardDebt;
        user.rewardDebt = user.amount * initiative.accRewardPerShare / 1e12;

        emit IncreaseVote(msg.sender, optionId, amount);

        // TODO: investigate, can a user submit multiple transactions in a single block here, because we check the amount are we protected?
        if (block.number >= initiative.lastRewardBlock && priorAmount > 0) {
            uint256 pending = priorAmount * initiative.accRewardPerShare / 1e12 - priorReward;
            IERC20(initiative.rewardToken).safeTransfer(msg.sender, pending);
        }

        IERC20(groyContractAddress).safeTransferFrom(msg.sender, address(this), amount);
    }

    function estimateRewards(uint _initiativeId) external view initiativeExists(_initiativeId, initiativeCount) returns(uint) {
        uint[] memory optionIds = initiativeToOptions[_initiativeId];
        uint initiativeVotes = 0;
        for (uint i=0; i < optionIds.length; i++) {
            Option memory option = options[optionIds[i]];
            initiativeVotes += option.totalVotes;
        }
        uint mockReward = initiativeVotes * 4;
        return mockReward;
        // Initiative memory initiative = initiatives[_initiativeId];
        // uint256 upperBlock = initiative.endBlock + 1;
        // PoolInfo storage pool = poolInfo[_initiativeId];

        // uint256 totalBlocks = upperBlock - pool.lastRewardBlock;
        // uint256 reward = totalBlocks * pool.rewardPerBlock;

        // uint accRewardPerShare = pool.accRewardPerShare + reward * 1e12 / pool.groyStaked;
        // console.log("accRewardPerShare: %s", accRewardPerShare);

        // UserInfo storage user = userInfo[_initiativeId][msg.sender];
        // return user.amount * accRewardPerShare;
    }

    function claimRewards(uint initiativeId) external initiativeExists(initiativeId, initiativeCount) nonReentrant {
        UserInfo storage user = userInfo[initiativeId][msg.sender];
        require(user.amount > 0, "Your vote amount is zero");

        Initiative storage initiative = initiatives[initiativeId];

        _updateInitiative(initiative.endBlock, initiative, ActionType.CLAIM_REWARD, user.amount);

        emit ClaimRewards(msg.sender, initiativeId);

        if (block.number >= initiative.lastRewardBlock) {
            uint256 pending = user.amount * initiative.accRewardPerShare / 1e12 - user.rewardDebt;
            user.rewardDebt = user.amount * initiative.accRewardPerShare / 1e12;
            IERC20(initiative.rewardToken).safeTransfer(msg.sender, pending);
        }

        if (block.number > initiative.endBlock) {
            uint256 amount = user.amount;
            //slither-disable-next-line reentrancy-no-eth
            user.amount = 0;
            IERC20(groyContractAddress).safeTransfer(msg.sender, amount);
        }
    }

    enum ActionType { WITHDRAW, DEPOSIT, CLAIM_REWARD }

    /**
     * @dev Update reward variables of the given pool to be up-to-date.
     */
    function _updateInitiative(uint endBlock, Initiative storage initiative, ActionType actionType, uint amount) private {
        uint oldTotal = initiative.groyStaked;
        if (actionType == ActionType.WITHDRAW) {
            initiative.groyStaked -= amount;
        } else if (actionType == ActionType.DEPOSIT) {
            initiative.groyStaked += amount;
        } else if ((actionType == ActionType.CLAIM_REWARD) && (block.number > endBlock)) {
            initiative.groyStaked -= amount;
        }
        uint256 upperBlock = block.number > endBlock + 1 ? endBlock + 1 : block.number;
        //slither-disable-next-line incorrect-equality
        if (block.number <= initiative.lastRewardBlock || upperBlock == initiative.lastRewardBlock) {
            return;
        }

        uint256 multiplier = upperBlock - initiative.lastRewardBlock;
        uint256 reward = multiplier * initiative.rewardPerBlock;

        initiative.accRewardPerShare += reward * 1e12 / oldTotal;
        initiative.lastRewardBlock = upperBlock;
    }

    function _requireVoteIsActive(Initiative memory initiative) private view {
        require(block.number <= initiative.endBlock, "Vote has ended");
        require(block.number <= initiative.lockBlock, "Vote is locked");
        require(block.number >= initiative.startBlock, "Vote has not yet started");
    }

    function _registerVoter(uint optionId) private {
        uint initiativeId = optionToInitiativeId[optionId];
        address[] storage voters = initiativeToVoters[initiativeId];
        if (!_arrayContainsAddress(voters, msg.sender)) {
            voters.push(msg.sender);
        }
        uint[] storage voterInitiatives = voterToInitiatives[msg.sender];
        if (!_arrayContainsInt(voterInitiatives, initiativeId)) {
            voterInitiatives.push(initiativeId);
        }
    }

    function _arrayContainsAddress(address[] memory array, address value) internal pure returns(bool) {
        for (uint i=0; i < array.length; i++) {
            if (value == array[i]) {
                return true;
            }
        }
        return false;
    }

    function _arrayContainsInt(uint[] memory array, uint value) internal pure returns(bool) {
        for (uint i=0; i < array.length; i++) {
            if (value == array[i]) {
                return true;
            }
        }
        return false;
    }

    bool private creationEnabled = true;

    function enableCreation(bool value) external onlyOwner {
        creationEnabled = value;
    }

    /**
     * @notice All voting must be stopped before the address can be changed, or some active votes would lose tokens
     */
    function updateGroyTokenContract(address tokenAddress) external onlyOwner {
        require(tokenAddress != address(0), "Vote token address is zero");
        require(!creationEnabled, "Disable creation first");
        require(_initiativesFinished(), "Initiatives must finish first");
        groyContractAddress = tokenAddress;
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
        uint accRewardPerShare;
        uint lastRewardBlock;
        uint rewardPerBlock;
        uint groyStaked;
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
    struct UserInfo {
        uint256 amount; // How many tokens the user has voted.
        uint256 rewardDebt; // Reward debt. See explanation below.

        // We do some fancy math here. Basically, any point in time, the amount of tokens
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accRewardPerShare) - user.rewardDebt
        //
        // Whenever a user increaseVotes or decreaseVotes tokens to a initiative. Here's what happens:
        //   1. The initiative's `accRewardPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }
    /// @notice Info of each user that votes tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    function getInitiativesFromInitiator(address account) external view returns (uint[] memory) {
        return initiatorToInitiatives[account];
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

    function getInitiativesFromVoter(address account) external view returns (uint[] memory) {
        return voterToInitiatives[account];
    }

    function getVotersFromInitiative(uint initiativeId) external view returns (address[] memory) {
        return initiativeToVoters[initiativeId];
    }

    bool private anyoneCanCreate = false;

    function enableAnyoneCanCreate(bool value) external onlyOwner {
        anyoneCanCreate = value;
    }

    /**
     * @dev Throws if called by any account other than the owner, unless anyone
     */
    modifier onlyOwnerOrAnyone() {
        require(anyoneCanCreate || (owner() == msg.sender), "GroyGovernor: caller is not the owner");
        _;
    }

    function createInitiative(uint startBlock, uint lockBlock, uint endBlock, address rewardToken, uint rewardAmount,
            string memory description, string[] memory _options) external onlyOwnerOrAnyone nonReentrant {
        require(creationEnabled, "GroyGovernor: Creation is disabled");
        require(startBlock > block.number, "GroyGovernor: Start block is in the past");
        require(startBlock <= lockBlock, "GroyGovernor: Start block > lock block");
        require(lockBlock <= endBlock, "GroyGovernor: Lock block > end block");
        require(endBlock - startBlock >= minimumVoteLength, "GroyGovernor: Vote is too short");

        uint id = initiativeCount;
        Initiative storage initiative = initiatives[id];
        initiative.initiator = msg.sender;
        initiative.startBlock = startBlock;
        initiative.lockBlock = lockBlock;
        initiative.endBlock = endBlock;
        initiative.description = description;

        initiative.rewardToken = rewardToken;
        initiative.rewardAmount = rewardAmount;
        initiative.lastRewardBlock = block.number > lockBlock + 1 ? block.number : lockBlock + 1;
        initiative.rewardPerBlock = rewardAmount / (endBlock - lockBlock);

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
            createOption(_options[i], id);
        }

        IERC20(initiative.rewardToken).safeTransferFrom(msg.sender, address(this), rewardAmount);
    }

    event InitiativeCreated(
        uint indexed initiativeId, address indexed initiator,
        uint startBlock, uint lockBlock, uint endBlock,
        address rewardToken, uint rewardAmount,
        string description
    );

    function state(uint initiativeId) public view returns (InitiativeState) {
        Initiative memory initiative = initiatives[initiativeId];
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

    modifier initiativeExists(uint initiativeId, uint count) {
        require(initiativeId < count, "Initiative does not exist");
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

    /// @dev Storage of Option ID to Voter ID/Address to the receipt object for their vote
    // mapping (uint => mapping (address => Receipt)) public receipts;

    mapping (uint => uint) public optionToInitiativeId;

    /// @dev Initiative to list of Options, getter will require option list index
    mapping (uint => uint[]) public initiativeToOptions;

    function getOptionsFromInitiative(uint initiativeId) external view returns (uint[] memory) {
        return initiativeToOptions[initiativeId];
    }

    function getInitiativeFromOption(uint optionId) external view returns (uint) {
        return optionToInitiativeId[optionId];
    }

    function getWinningOption(uint initiativeId) external view returns (uint) {
        Initiative memory initiative = initiatives[initiativeId];
        require(block.number >= initiative.endBlock, "Vote has not ended yet");
        uint[] memory optionIds = initiativeToOptions[initiativeId];
        require(optionIds.length > 0, "Initiative has no option");
        uint winOptionId = 0;
        // TODO: The first option has an advantage in a tie, we have to pick one, right?  Leave it as it guarantees a
        //       winner? Users must select their option order carefully.
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

    function createOption(string memory description, uint initiativeId) public
        onlyOwnerOrAnyone
        initiativeExists(initiativeId, initiativeCount)
    {
        require(creationEnabled, "GroyGovernor: Creation is disabled");
        Initiative memory initiative = initiatives[initiativeId];
        require(block.number < initiative.startBlock, "GroyGovernor: Vote has already started");
        uint id = optionCount;
        Option storage option = options[optionCount++];
        option.description = description;
        optionToInitiativeId[id] = initiativeId;
        initiativeToOptions[initiativeId].push(id);
        emit OptionCreated(msg.sender, id, description);
    }

    event OptionCreated(address indexed initiator, uint indexed optionId, string description);

    modifier optionExists(uint optionId, uint count) {
        require(optionId < count, "Option does not exist");
        _;
    }
}