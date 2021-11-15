pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract ETHPool is Ownable {

    using Address for address;

    address public team_;

    // Struct to keep all the info regarding a pool
    struct PoolInfo {
        uint256 poolID;
        uint256 poolAmount;
        uint256 rewards;
        address[] rewardRecipients;
        bool teamDeposited;
    }

    // Pool ID => Pool information
    mapping(uint256 => PoolInfo) internal pools_;
    // Pool ID => Address => Is the address eligible for a reward?
    mapping(uint256 => mapping(address => bool)) internal isRewardRecipient_;
    // Address => Pool ID => User Deposit
    mapping(address => mapping(uint256 => uint256)) internal userDeposit_;
    // Address => Pool ID => User Rewards
    mapping(address => mapping(uint256 => uint256)) internal userRewards_;
    
    //-------------------------------------------------------------------------
    // EVENTS
    //-------------------------------------------------------------------------

    event RewardDeposit(
        uint256 poolID,
        uint256 amount
    );

    event UserDeposit(
        uint256 poolID,
        address user, 
        uint256 amount
    );

    event UserWithdrawl(
        uint256 poolID,
        address user,
        uint256 amount
    );

    //-------------------------------------------------------------------------
    // MODIFIERS
    //-------------------------------------------------------------------------
    modifier onlyTeam {
        require(msg.sender == team_, "Only the Team can call this");
        _;
    }

    //-------------------------------------------------------------------------
    // CONSTRUCTOR
    //-------------------------------------------------------------------------
    constructor(address _team) {
        require(_team != address(0), "Team cannot be 0 address");
        team_ = _team;
    }

    //-------------------------------------------------------------------------
    // VIEW FUNCTIONS
    //-------------------------------------------------------------------------
    function getPoolInfo(uint256 poolId) public view returns(
        uint256 poolID,
        uint256 poolAmount,
        uint256 rewards,
        address[] memory rewardRecipients,
        bool teamDeposited
    ) {
        PoolInfo memory pool = pools_[poolId];
        return (pool.poolID, pool.poolAmount, pool.rewards, pool.rewardRecipients, pool.teamDeposited);
    }

    function getPoolTotal(uint256 poolId) public view returns(uint256) {
        return pools_[poolId].poolAmount + pools_[poolId].rewards;
    }

    function getUserDepositAmount(uint256 poolId, address user) public view returns(uint256) {
        return userDeposit_[user][poolId];
    }

    function getUserRewards(uint256 poolId, address user) public view returns(uint256){
        return userRewards_[user][poolId];
    }

    function getUserEligibility(uint256 poolId, address user) public view returns(bool){
        return isRewardRecipient_[poolId][user];
    }

    //-------------------------------------------------------------------------
    // ONLY TEAM 
    //-------------------------------------------------------------------------
    function depositRewards(uint256 poolID) external payable onlyTeam {
        require(pools_[poolID].teamDeposited == false, "Pool has already been used");
        pools_[poolID].rewards += msg.value;
        pools_[poolID].teamDeposited = true;
        //Add the rewards to each user that is eligible
        for(uint256 i = 0; i < pools_[poolID].rewardRecipients.length; i++){

            address user = pools_[poolID].rewardRecipients[i];
            //Calculate the user's reward
            uint256 rewardPercent = (userDeposit_[user][poolID] * 10**6) / pools_[poolID].poolAmount;
            uint256 userReward = (pools_[poolID].rewards * rewardPercent) / (10**6);
            //Add the reward to the user's total
            userRewards_[user][poolID] += userReward;
        }
        
        emit RewardDeposit(poolID, msg.value);
    }

    function setTeam(address newTeam) external onlyTeam {
        require(newTeam != address(0), "Team cannot be 0 address");
        team_ = newTeam;
    }

    //-------------------------------------------------------------------------
    // EXTERNAL (NON-RESTRICTED)
    //-------------------------------------------------------------------------
    //Makes deposit of ETH for the user
    function depositETH(uint256 poolID) external payable {
        //Adds ETH to the users total
        userDeposit_[address(msg.sender)][poolID] += msg.value;
        //Checks if team has not deposited rewards for this pool
        if(pools_[poolID].teamDeposited == false) {
            //Increment the number of reward recipients if this address has not been seen before.
            if(isRewardRecipient_[poolID][address(msg.sender)] == false){
                pools_[poolID].rewardRecipients.push(address(msg.sender));
                isRewardRecipient_[poolID][address(msg.sender)] = true;
            }
            //Increment the amount inside of the pool that is used to calculate the percentage of ownership
            pools_[poolID].poolAmount += msg.value;
        }
        emit UserDeposit(poolID, address(msg.sender), msg.value);
    }

    function withdrawETH(uint256 poolID, address payable _to) external {
        uint256 withdrawlAmount = userDeposit_[_to][poolID] + userRewards_[_to][poolID];
        if(userRewards_[_to][poolID] != 0) {
            //Decrement amount in the pool
            pools_[poolID].poolAmount -= userDeposit_[_to][poolID];
            pools_[poolID].rewards -= userRewards_[_to][poolID];
        }
        //Since user deposit and/or rewards have been taken out, the mappings are set to zero
        userDeposit_[_to][poolID] = 0;
        userRewards_[_to][poolID] = 0;
        (bool success, ) = _to.call{value:withdrawlAmount}("");
        require(success, "Transfer failed.");
        emit UserWithdrawl(poolID, address(_to), withdrawlAmount);
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
        return msg.data;
    }
}

