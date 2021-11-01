// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./Governable.sol";
import "./interface/IRegistry.sol";
import "./interface/IPolicyManager.sol";
import "./interface/ISptFarm.sol";


/**
 * @title ISptFarm
 * @author solace.fi
 * @notice Rewards [**Policyholders**](/docs/protocol/policy-holder) in [**Options**](../OptionFarming) for staking their [**Policies**](./PolicyManager).
 *
 * Over the course of `startTime` to `endTime`, the farm distributes `rewardPerSecond` [**Options**](../OptionFarming) to all farmers split relative to the amount of [**SCP**](../Vault) they have deposited.
 *
 * Users can become [**Capital Providers**](/docs/user-guides/capital-provider/cp-role-guide) by depositing **ETH** into the [`Vault`](../Vault), receiving [**SCP**](../Vault) in the process. [**Capital Providers**](/docs/user-guides/capital-provider/cp-role-guide) can then deposit their [**SCP**](../Vault) via [`depositCp()`](#depositcp) or [`depositCpSigned()`](#depositcpsigned). Alternatively users can bypass the [`Vault`](../Vault) and stake their **ETH** via [`depositEth()`](#depositeth).
 *
 * Users can withdraw their rewards via [`withdrawRewards()`](#withdrawrewards).
 *
 * Users can withdraw their [**SCP**](../Vault) via [`withdrawCp()`](#withdrawcp).
 *
 * Note that transferring in **ETH** will mint you shares, but transferring in **WETH** or [**SCP**](../Vault) will not. These must be deposited via functions in this contract. Misplaced funds cannot be rescued.
 */
contract SptFarm is ISptFarm, ReentrancyGuard, Governable {
    using EnumerableSet for EnumerableSet.UintSet;

    /// @notice A unique enumerator that identifies the farm type.
    uint256 internal constant _farmType = 3;
    /// @notice PolicyManager contract.
    IPolicyManager internal _policyManager;
    /// @notice FarmController contract.
    IFarmController internal _controller;
    /// @notice Amount of SOLACE distributed per seconds.
    uint256 internal _rewardPerSecond;
    /// @notice When the farm will start.
    uint256 internal _startTime;
    /// @notice When the farm will end.
    uint256 internal _endTime;
    /// @notice Last time rewards were distributed or farm was updated.
    uint256 internal _lastRewardTime;
    /// @notice Accumulated rewards per share, times 1e12.
    uint256 internal _accRewardPerShare;
    /// @notice Value of policys staked by all farmers.
    uint256 internal _valueStaked;

    // Info of each user.
    struct UserInfo {
        uint256 value;         // Value of user provided policys.
        uint256 rewardDebt;    // Reward debt. See explanation below.
        uint256 unpaidRewards; // Rewards that have not been paid.
        //
        // We do some fancy math here. Basically, any point in time, the amount of reward token
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.value * _accRewardPerShare) - user.rewardDebt + user.unpaidRewards
        //
        // Whenever a user deposits or withdraws policies to a farm. Here's what happens:
        //   1. The farm's `accRewardPerShare` and `lastRewardTime` gets updated.
        //   2. Users pending rewards accumulate in `unpaidRewards`.
        //   3. User's `value` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    /// @notice Information about each farmer.
    /// @dev user address => user info
    mapping(address => UserInfo) internal _userInfo;

    // list of tokens deposited by user
    mapping(address => EnumerableSet.UintSet) internal _userDeposited;

    struct PolicyInfo {
        address depositor;
        uint256 value;
    }

    // policy id => policy info
    mapping(uint256 => PolicyInfo) internal _policyInfo;

    /**
     * @notice Constructs the SptFarm.
     * @param governance_ The address of the [governor](/docs/protocol/governance).
     * @param registry_ Address of the [`Registry`](./Registry) contract.
     * @param startTime_ When farming will begin.
     * @param endTime_ When farming will end.
     */
    constructor(
        address governance_,
        address registry_,
        uint256 startTime_,
        uint256 endTime_
    ) Governable(governance_) {
        require(registry_ != address(0x0), "zero address registry");
        IRegistry registry = IRegistry(registry_);
        address controller_ = registry.farmController();
        require(controller_ != address(0x0), "zero address controller");
        _controller = IFarmController(controller_);
        address policyManager_ = registry.policyManager();
        require(policyManager_ != address(0x0), "zero address policymanager");
        _policyManager = IPolicyManager(policyManager_);
        require(startTime_ <= endTime_, "invalid window");
        _startTime = startTime_;
        _endTime = endTime_;
        _lastRewardTime = Math.max(block.timestamp, startTime_);
    }

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /// @notice A unique enumerator that identifies the farm type.
    function farmType() external pure override returns (uint256 farmType_) {
        return _farmType;
    }

    /// @notice [`PolicyManager`](./PolicyManager) contract.
    function policyManager() external view override returns (address policyManager_) {
        return address(_policyManager);
    }

    /**
     * @notice Returns the count of [**policies**](./PolicyManager) that a user has deposited onto the farm.
     * @param user The user to check count for.
     * @return count The count of deposited [**policies**](./PolicyManager).
     */
    function countDeposited(address user) external view override returns (uint256 count) {
        return _userDeposited[user].length();
    }

    /**
     * @notice Returns the list of [**policies**](./PolicyManager) that a user has deposited onto the farm and their values.
     * @param user The user to list deposited policies.
     * @return policyIDs The list of deposited policies.
     * @return policyValues The values of the policies.
     */
    function listDeposited(address user) external view override returns (uint256[] memory policyIDs, uint256[] memory policyValues) {
        uint256 length = _userDeposited[user].length();
        policyIDs = new uint256[](length);
        policyValues = new uint256[](length);
        for(uint256 i = 0; i < length; ++i) {
            uint256 policyID = _userDeposited[user].at(i);
            policyIDs[i] = policyID;
            policyValues[i] = _policyInfo[policyID].value;
        }
        return (policyIDs, policyValues);
    }

    /**
     * @notice Returns the ID of a [**Policies**](./PolicyManager) that a user has deposited onto a farm and its value.
     * @param user The user to get policyID for.
     * @param index The farm-based index of the policy.
     * @return policyID The ID of the deposited [**policy**](./PolicyManager).
     * @return policyValue The value of the [**policy**](./PolicyManager).
     */
    function getDeposited(address user, uint256 index) external view override returns (uint256 policyID, uint256 policyValue) {
        policyID = _userDeposited[user].at(index);
        policyValue = _policyInfo[policyID].value;
        return (policyID, policyValue);
    }

    /// @notice FarmController contract.
    function farmController() external view override returns (address controller_) {
        return address(_controller);
    }

    /// @notice Amount of SOLACE distributed per second.
    function rewardPerSecond() external view override returns (uint256) {
        return _rewardPerSecond;
    }

    /// @notice When the farm will start.
    function startTime() external view override returns (uint256 timestamp) {
        return _startTime;
    }

    /// @notice When the farm will end.
    function endTime() external view override returns (uint256 timestamp) {
        return _endTime;
    }

    /// @notice Last time rewards were distributed or farm was updated.
    function lastRewardTime() external view override returns (uint256 timestamp) {
        return _lastRewardTime;
    }

    /// @notice Accumulated rewards per share, times 1e12.
    function accRewardPerShare() external view override returns (uint256 acc) {
        return _accRewardPerShare;
    }

    /// @notice The value of [**policies**](./PolicyManager) a user deposited.
    function userStaked(address user) external view override returns (uint256 amount) {
        return _userInfo[user].value;
    }

    /// @notice Value of [**policies**](./PolicyManager) staked by all farmers.
    function valueStaked() external view override returns (uint256 amount) {
        return _valueStaked;
    }

    /// @notice Information about a deposited policy.
    function policyInfo(uint256 policyID) external view override returns (address depositor, uint256 value) {
        PolicyInfo storage policyInfo_ = _policyInfo[policyID];
        return (policyInfo_.depositor, policyInfo_.value);
    }

    /**
     * @notice Calculates the accumulated balance of [**SOLACE**](./SOLACE) for specified user.
     * @param user The user for whom unclaimed rewards will be shown.
     * @return reward Total amount of withdrawable rewards.
     */
    function pendingRewards(address user) external view override returns (uint256 reward) {
        // get farmer information
        UserInfo storage userInfo_ = _userInfo[user];
        // math
        uint256 accRewardPerShare_ = _accRewardPerShare;
        if (block.timestamp > _lastRewardTime && _valueStaked != 0) {
            uint256 tokenReward = getRewardAmountDistributed(_lastRewardTime, block.timestamp);
            accRewardPerShare_ += tokenReward * 1e12 / _valueStaked;
        }
        return userInfo_.value * accRewardPerShare_ / 1e12 - userInfo_.rewardDebt + userInfo_.unpaidRewards;
    }

    /**
     * @notice Calculates the reward amount distributed between two timestamps.
     * @param from The start of the period to measure rewards for.
     * @param to The end of the period to measure rewards for.
     * @return amount The reward amount distributed in the given period.
     */
    function getRewardAmountDistributed(uint256 from, uint256 to) public view override returns (uint256 amount) {
        // validate window
        from = Math.max(from, _startTime);
        to = Math.min(to, _endTime);
        // no reward for negative window
        if (from > to) return 0;
        return (to - from) * _rewardPerSecond;
    }

    /***************************************
    MUTATOR FUNCTIONS
    ***************************************/

    /**
     * @notice Deposit a [**policy**](./PolicyManager).
     * User must `ERC721.approve()` or `ERC721.setApprovalForAll()` first.
     * @param policyID The ID of the policy to deposit.
     */
    function depositPolicy(uint256 policyID) external override {
        // pull policy
        _policyManager.transferFrom(msg.sender, address(this), policyID);
        // accounting
        _deposit(msg.sender, policyID);
    }

    /**
     * @notice Deposit a [**policy**](./PolicyManager) using permit.
     * @param depositor The depositing user.
     * @param policyID The ID of the policy to deposit.
     * @param deadline Time the transaction must go through before.
     * @param v secp256k1 signature
     * @param r secp256k1 signature
     * @param s secp256k1 signature
     */
    function depositPolicySigned(address depositor, uint256 policyID, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external override {
        // permit
        _policyManager.permit(address(this), policyID, deadline, v, r, s);
        // pull policy
        _policyManager.transferFrom(depositor, address(this), policyID);
        // accounting
        _deposit(depositor, policyID);
    }

    /**
     * @notice Deposit multiple [**policies**](./PolicyManager).
     * User must `ERC721.approve()` or `ERC721.setApprovalForAll()` first.
     * @param policyIDs The IDs of the policies to deposit.
     */
    function depositPolicyMulti(uint256[] memory policyIDs) external override {
        for(uint256 i = 0; i < policyIDs.length; i++) {
            uint256 policyID = policyIDs[i];
            // pull policy
            _policyManager.transferFrom(msg.sender, address(this), policyID);
            // accounting
            _deposit(msg.sender, policyID);
        }
    }

    /**
     * @notice Deposit multiple [**policies**](./PolicyManager) using permit.
     * @param depositors The depositing users.
     * @param policyIDs The IDs of the policies to deposit.
     * @param deadlines Times the transactions must go through before.
     * @param vs secp256k1 signatures
     * @param rs secp256k1 signatures
     * @param ss secp256k1 signatures
     */
    function depositPolicySignedMulti(address[] memory depositors, uint256[] memory policyIDs, uint256[] memory deadlines, uint8[] memory vs, bytes32[] memory rs, bytes32[] memory ss) external override {
        require(depositors.length == policyIDs.length && depositors.length == deadlines.length && depositors.length == vs.length && depositors.length == rs.length && depositors.length == ss.length, "length mismatch");
        for(uint256 i = 0; i < policyIDs.length; i++) {
            uint256 policyID = policyIDs[i];
            // permit
            _policyManager.permit(address(this), policyID, deadlines[i], vs[i], rs[i], ss[i]);
            // pull policy
            _policyManager.transferFrom(depositors[i], address(this), policyID);
            // accounting
            _deposit(depositors[i], policyID);
        }
    }

    /**
     * @notice Performs the internal accounting for a deposit.
     * @param depositor The depositing user.
     * @param policyID The ID of the policy to deposit.
     */
    function _deposit(address depositor, uint256 policyID) internal {
        // get policy
        (/* address policyholder */, /* address product */, uint256 coverAmount, uint40 expirationBlock, uint24 price, /* bytes calldata positionDescription */) = _policyManager.getPolicyInfo(policyID);
        require(expirationBlock > block.number, "policy is expired");
        // harvest and update farm
        _harvest(depositor);
        // get farmer information
        UserInfo storage user = _userInfo[depositor];
        // record position
        uint256 policyValue = coverAmount * uint256(price); // a multiple of premium per block
        PolicyInfo memory policyInfo_ = PolicyInfo({
            depositor: depositor,
            value: policyValue
        });
        _policyInfo[policyID] = policyInfo_;
        // accounting
        user.value += policyValue;
        _valueStaked += policyValue;
        user.rewardDebt = user.value * _accRewardPerShare / 1e12;
        _userDeposited[depositor].add(policyID);
        // emit event
        emit PolicyDeposited(depositor, policyID);
    }

    /**
     * @notice Withdraw a [**policy**](./PolicyManager).
     * Can only withdraw policies you deposited.
     * @param policyID The ID of the policy to withdraw.
     */
    function withdrawPolicy(uint256 policyID) external override {
        // harvest and update farm
        _harvest(msg.sender);
        // get farmer information
        UserInfo storage user = _userInfo[msg.sender];
        // get policy info
        PolicyInfo memory policyInfo_ = _policyInfo[policyID];
        // cannot withdraw a policy you didnt deposit
        require(policyInfo_.depositor == msg.sender, "not your policy");
        // accounting
        user.value -= policyInfo_.value;
        _valueStaked -= policyInfo_.value;
        user.rewardDebt = user.value * _accRewardPerShare / 1e12;
        // delete policy info
        delete _policyInfo[policyID];
        // return staked policy
        _userDeposited[msg.sender].remove(policyID);
        _policyManager.safeTransferFrom(address(this), msg.sender, policyID);
        // emit event
        emit PolicyWithdrawn(msg.sender, policyID);
    }

    /**
     * @notice Withdraw multiple [**policies**](./PolicyManager).
     * Can only withdraw policies you deposited.
     * @param policyIDs The IDs of the policies to withdraw.
     */
    function withdrawPolicyMulti(uint256[] memory policyIDs) external override {
        // harvest and update farm
        _harvest(msg.sender);
        // get farmer information
        UserInfo storage user = _userInfo[msg.sender];
        uint256 userValue_ = user.value;
        uint256 valueStaked_ = _valueStaked;
        for(uint256 i = 0; i < policyIDs.length; i++) {
            uint256 policyID = policyIDs[i];
            // get policy info
            PolicyInfo memory policyInfo_ = _policyInfo[policyID];
            // cannot withdraw a policy you didnt deposit
            require(policyInfo_.depositor == msg.sender, "not your policy");
            // accounting
            userValue_ -= policyInfo_.value;
            valueStaked_ -= policyInfo_.value;
            // delete policy info
            delete _policyInfo[policyID];
            // return staked policy
            _userDeposited[msg.sender].remove(policyID);
            _policyManager.safeTransferFrom(address(this), msg.sender, policyID);
            // emit event
            emit PolicyWithdrawn(msg.sender, policyID);
        }
        // accounting
        user.value = userValue_;
        _valueStaked = valueStaked_;
        user.rewardDebt = user.value * _accRewardPerShare / 1e12;
    }

    /**
     * @notice Burns expired policies.
     * @param policyIDs The list of expired policies.
     */
    function updateActivePolicies(uint256[] calldata policyIDs) external override {
        // update farm
        updateFarm();
        // for each policy to burn
        for(uint256 i = 0; i < policyIDs.length; i++) {
            uint256 policyID = policyIDs[i];
            // get policy info
            PolicyInfo memory policyInfo_ = _policyInfo[policyID];
            // if policy is on the farm and policy is expired or burnt
            if(policyInfo_.depositor != address(0x0) && !_policyManager.policyIsActive(policyID)) {
                // get farmer information
                UserInfo storage user = _userInfo[policyInfo_.depositor];
                // accounting
                user.value -= policyInfo_.value;
                _valueStaked -= policyInfo_.value;
                user.rewardDebt = user.value * _accRewardPerShare / 1e12;
                // delete policy info
                delete _policyInfo[policyID];
                // remove staked policy
                _userDeposited[policyInfo_.depositor].remove(policyID);
                // emit event
                emit PolicyWithdrawn(address(0x0), policyID);
            }
        }
        // policymanager needs to do its own accounting
        _policyManager.updateActivePolicies(policyIDs);
    }

    /**
     * @notice Updates farm information to be up to date to the current time.
     */
    function updateFarm() public override {
        // dont update needlessly
        if (block.timestamp <= _lastRewardTime) return;
        if (_valueStaked == 0) {
            _lastRewardTime = Math.min(block.timestamp, _endTime);
            return;
        }
        // update math
        uint256 tokenReward = getRewardAmountDistributed(_lastRewardTime, block.timestamp);
        _accRewardPerShare += tokenReward * 1e12 / _valueStaked;
        _lastRewardTime = Math.min(block.timestamp, _endTime);
    }

    /**
    * @notice Update farm and accumulate a user's rewards.
    * @param user User to process rewards for.
    */
    function _harvest(address user) internal {
        // update farm
        updateFarm();
        // get farmer information
        UserInfo storage userInfo_ = _userInfo[user];
        // accumulate unpaid rewards
        userInfo_.unpaidRewards = userInfo_.value * _accRewardPerShare / 1e12 - userInfo_.rewardDebt + userInfo_.unpaidRewards;
    }

    /***************************************
    OPTIONS MINING FUNCTIONS
    ***************************************/

    /**
     * @notice Converts the senders unpaid rewards into an [`Option`](./OptionsFarming).
     * @return optionID The ID of the newly minted [`Option`](./OptionsFarming).
     */
    function withdrawRewards() external override nonReentrant returns (uint256 optionID) {
        // update farm
        _harvest(msg.sender);
        // get farmer information
        UserInfo storage userInfo_ = _userInfo[msg.sender];
        // math
        userInfo_.rewardDebt = userInfo_.value * _accRewardPerShare / 1e12;
        uint256 unpaidRewards = userInfo_.unpaidRewards;
        userInfo_.unpaidRewards = 0;
        optionID = _controller.createOption(msg.sender, unpaidRewards);
        return optionID;
    }

    /**
     * @notice Withdraw a users rewards without unstaking their policys.
     * Can only be called by [`FarmController`](./FarmController).
     * @param user User to withdraw rewards for.
     * @return rewardAmount The amount of rewards the user earned on this farm.
     */
    function withdrawRewardsForUser(address user) external override nonReentrant returns (uint256 rewardAmount) {
        require(msg.sender == address(_controller), "!farmcontroller");
        // update farm
        _harvest(user);
        // get farmer information
        UserInfo storage userInfo_ = _userInfo[user];
        // math
        userInfo_.rewardDebt = userInfo_.value * _accRewardPerShare / 1e12;
        rewardAmount = userInfo_.unpaidRewards;
        userInfo_.unpaidRewards = 0;
        return rewardAmount;
    }

    /***************************************
    GOVERNANCE FUNCTIONS
    ***************************************/

    /**
     * @notice Sets the amount of [**SOLACE**](./SOLACE) to distribute per second.
     * Only affects future rewards.
     * Can only be called by [`FarmController`](./FarmController).
     * @param rewardPerSecond_ Amount to distribute per second.
     */
    function setRewards(uint256 rewardPerSecond_) external override {
        // can only be called by FarmController contract
        require(msg.sender == address(_controller), "!farmcontroller");
        // update
        updateFarm();
        // accounting
        _rewardPerSecond = rewardPerSecond_;
        emit RewardsSet(rewardPerSecond_);
    }

    /**
     * @notice Sets the farm's end time. Used to extend the duration.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param endTime_ The new end time.
     */
    function setEnd(uint256 endTime_) external override onlyGovernance {
        // accounting
        _endTime = endTime_;
        // update
        updateFarm();
        emit FarmEndSet(endTime_);
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute.
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "./interface/IGovernable.sol";

/**
 * @title Governable
 * @author solace.fi
 * @notice Enforces access control for important functions to [**governor**](/docs/protocol/governance).
 *
 * Many contracts contain functionality that should only be accessible to a privileged user. The most common access control pattern is [OpenZeppelin's `Ownable`](https://docs.openzeppelin.com/contracts/4.x/access-control#ownership-and-ownable). We instead use `Governable` with a few key differences:
   * - Transferring the governance role is a two step process. The current governance must [`setPendingGovernance(pendingGovernance_)`](#setPendingGovernance) then the new governance must [`acceptGovernance()`](#acceptgovernance). This is to safeguard against accidentally setting ownership to the wrong address and locking yourself out of your contract.
 * - `governance` is a constructor argument instead of `msg.sender`. This is especially useful when deploying contracts via a [`SingletonFactory`](./interface/ISingletonFactory).
 * - We use `lockGovernance()` instead of `renounceOwnership()`. `renounceOwnership()` is a prerequisite for the reinitialization bug because it sets `owner = address(0x0)`. We also use the `governanceIsLocked()` flag.
 */
contract Governable is IGovernable {

    /***************************************
    GLOBAL VARIABLES
    ***************************************/

    // Governor.
    address private _governance;

    // governance to take over.
    address private _pendingGovernance;

    bool private _locked;

    /**
     * @notice Constructs the governable contract.
     * @param governance_ The address of the [governor](/docs/protocol/governance).
     */
    constructor(address governance_) {
        require(governance_ != address(0x0), "zero address governance");
        _governance = governance_;
        _pendingGovernance = address(0x0);
        _locked = false;
    }

    /***************************************
    MODIFIERS
    ***************************************/

    // can only be called by governor
    // can only be called while unlocked
    modifier onlyGovernance() {
        require(!_locked, "governance locked");
        require(msg.sender == _governance, "!governance");
        _;
    }

    // can only be called by pending governor
    // can only be called while unlocked
    modifier onlyPendingGovernance() {
        require(!_locked, "governance locked");
        require(msg.sender == _pendingGovernance, "!pending governance");
        _;
    }

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /// @notice Address of the current governor.
    function governance() external view override returns (address) {
        return _governance;
    }

    /// @notice Address of the governor to take over.
    function pendingGovernance() external view override returns (address) {
        return _pendingGovernance;
    }

    /// @notice Returns true if governance is locked.
    function governanceIsLocked() external view override returns (bool) {
        return _locked;
    }

    /***************************************
    MUTATOR FUNCTIONS
    ***************************************/

    /**
     * @notice Initiates transfer of the governance role to a new governor.
     * Transfer is not complete until the new governor accepts the role.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param pendingGovernance_ The new governor.
     */
    function setPendingGovernance(address pendingGovernance_) external override onlyGovernance {
        _pendingGovernance = pendingGovernance_;
        emit GovernancePending(pendingGovernance_);
    }

    /**
     * @notice Accepts the governance role.
     * Can only be called by the pending governor.
     */
    function acceptGovernance() external override onlyPendingGovernance {
        // sanity check against transferring governance to the zero address
        // if someone figures out how to sign transactions from the zero address
        // consider the entirety of ethereum to be rekt
        require(_pendingGovernance != address(0x0), "zero governance");
        address oldGovernance = _governance;
        _governance = _pendingGovernance;
        _pendingGovernance = address(0x0);
        emit GovernanceTransferred(oldGovernance, _governance);
    }

    /**
     * @notice Permanently locks this contract's governance role and any of its functions that require the role.
     * This action cannot be reversed.
     * Before you call it, ask yourself:
     *   - Is the contract self-sustaining?
     *   - Is there a chance you will need governance privileges in the future?
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     */
    function lockGovernance() external override onlyGovernance {
        _locked = true;
        // intentionally not using address(0x0), see re-initialization exploit
        _governance = address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF);
        _pendingGovernance = address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF);
        emit GovernanceTransferred(msg.sender, address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF));
        emit GovernanceLocked();
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

/**
 * @title IRegistry
 * @author solace.fi
 * @notice Tracks the contracts of the Solaverse.
 *
 * [**Governance**](/docs/protocol/governance) can set the contract addresses and anyone can look them up.
 *
 * Note that `Registry` doesn't track all Solace contracts. FarmController is tracked in [`OptionsFarming`](../OptionsFarming), farms are tracked in FarmController, Products are tracked in [`PolicyManager`](../PolicyManager), and the `Registry` is untracked.
 */
interface IRegistry {

    /***************************************
    EVENTS
    ***************************************/

    // Emitted when WETH is set.
    event WethSet(address weth);
    // Emitted when Vault is set.
    event VaultSet(address vault);
    // Emitted when ClaimsEscrow is set.
    event ClaimsEscrowSet(address claimsEscrow);
    // Emitted when Treasury is set.
    event TreasurySet(address treasury);
    // Emitted when PolicyManager is set.
    event PolicyManagerSet(address policyManager);
    // Emitted when RiskManager is set.
    event RiskManagerSet(address riskManager);
    // Emitted when Solace Token is set.
    event SolaceSet(address solace);
    // Emitted when OptionsFarming is set.
    event OptionsFarmingSet(address optionsFarming);
    // Emitted when FarmController is set.
    event FarmControllerSet(address farmController);
    // Emitted when Locker is set.
    event LockerSet(address locker);

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /**
     * @notice Gets the [**WETH**](../WETH9) contract.
     * @return weth_ The address of the [**WETH**](../WETH9) contract.
     */
    function weth() external view returns (address weth_);

    /**
     * @notice Gets the [`Vault`](../Vault) contract.
     * @return vault_ The address of the [`Vault`](../Vault) contract.
     */
    function vault() external view returns (address vault_);

    /**
     * @notice Gets the [`ClaimsEscrow`](../ClaimsEscrow) contract.
     * @return claimsEscrow_ The address of the [`ClaimsEscrow`](../ClaimsEscrow) contract.
     */
    function claimsEscrow() external view returns (address claimsEscrow_);

    /**
     * @notice Gets the [`Treasury`](../Treasury) contract.
     * @return treasury_ The address of the [`Treasury`](../Treasury) contract.
     */
    function treasury() external view returns (address treasury_);

    /**
     * @notice Gets the [`PolicyManager`](../PolicyManager) contract.
     * @return policyManager_ The address of the [`PolicyManager`](../PolicyManager) contract.
     */
    function policyManager() external view returns (address policyManager_);

    /**
     * @notice Gets the [`RiskManager`](../RiskManager) contract.
     * @return riskManager_ The address of the [`RiskManager`](../RiskManager) contract.
     */
    function riskManager() external view returns (address riskManager_);

    /**
     * @notice Gets the [**SOLACE**](../SOLACE) contract.
     * @return solace_ The address of the [**SOLACE**](../SOLACE) contract.
     */
    function solace() external view returns (address solace_);

    /**
     * @notice Gets the [`OptionsFarming`](../OptionsFarming) contract.
     * @return optionsFarming_ The address of the [`OptionsFarming`](../OptionsFarming) contract.
     */
    function optionsFarming() external view returns (address optionsFarming_);

    /**
     * @notice Gets the [`FarmController`](../FarmController) contract.
     * @return farmController_ The address of the [`FarmController`](../FarmController) contract.
     */
    function farmController() external view returns (address farmController_);

    /**
     * @notice Gets the [`Locker`](../Locker) contract.
     * @return locker_ The address of the [`Locker`](../Locker) contract.
     */
    function locker() external view returns (address locker_);

    /***************************************
    GOVERNANCE FUNCTIONS
    ***************************************/

    /**
     * @notice Sets the [**WETH**](../WETH9) contract.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param weth_ The address of the [**WETH**](../WETH9) contract.
     */
    function setWeth(address weth_) external;

    /**
     * @notice Sets the [`Vault`](../Vault) contract.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param vault_ The address of the [`Vault`](../Vault) contract.
     */
    function setVault(address vault_) external;

    /**
     * @notice Sets the [`Claims Escrow`](../ClaimsEscrow) contract.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param claimsEscrow_ The address of the [`Claims Escrow`](../ClaimsEscrow) contract.
     */
    function setClaimsEscrow(address claimsEscrow_) external;

    /**
     * @notice Sets the [`Treasury`](../Treasury) contract.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param treasury_ The address of the [`Treasury`](../Treasury) contract.
     */
    function setTreasury(address treasury_) external;

    /**
     * @notice Sets the [`Policy Manager`](../PolicyManager) contract.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param policyManager_ The address of the [`Policy Manager`](../PolicyManager) contract.
     */
    function setPolicyManager(address policyManager_) external;

    /**
     * @notice Sets the [`Risk Manager`](../RiskManager) contract.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param riskManager_ The address of the [`Risk Manager`](../RiskManager) contract.
     */
    function setRiskManager(address riskManager_) external;

    /**
     * @notice Sets the [**SOLACE**](../SOLACE) contract.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param solace_ The address of the [**SOLACE**](../SOLACE) contract.
     */
    function setSolace(address solace_) external;

    /**
     * @notice Sets the [`OptionsFarming`](../OptionsFarming) contract.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param optionsFarming_ The address of the [`OptionsFarming`](../OptionsFarming) contract.
     */
    function setOptionsFarming(address optionsFarming_) external;

    /**
     * @notice Sets the [`FarmController`](../FarmController) contract.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param farmController_ The address of the [`FarmController`](../FarmController) contract.
     */
    function setFarmController(address farmController_) external;

    /**
     * @notice Sets the [`Locker`](../Locker) contract.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param locker_ The address of the [`Locker`](../Locker) contract.
     */
    function setLocker(address locker_) external;

    /**
     * @notice Sets multiple contracts in one call.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param weth_ The address of the [**WETH**](../WETH9) contract.
     * @param vault_ The address of the [`Vault`](../Vault) contract.
     * @param claimsEscrow_ The address of the [`Claims Escrow`](../ClaimsEscrow) contract.
     * @param treasury_ The address of the [`Treasury`](../Treasury) contract.
     * @param policyManager_ The address of the [`Policy Manager`](../PolicyManager) contract.
     * @param riskManager_ The address of the [`Risk Manager`](../RiskManager) contract.
     * @param solace_ The address of the [**SOLACE**](../SOLACE) contract.
     * @param optionsFarming_ The address of the [`OptionsFarming`](./OptionsFarming) contract.
     * @param farmController_ The address of the [`FarmController`](./FarmController) contract.
     * @param locker_ The address of the [`Locker`](../Locker) contract.
     */
    function setMultiple(
        address weth_,
        address vault_,
        address claimsEscrow_,
        address treasury_,
        address policyManager_,
        address riskManager_,
        address solace_,
        address optionsFarming_,
        address farmController_,
        address locker_
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "./IERC721Enhanced.sol";

/**
 * @title IPolicyManager
 * @author solace.fi
 * @notice The **PolicyManager** manages the creation of new policies and modification of existing policies.
 *
 * Most users will not interact with **PolicyManager** directly. To buy, modify, or cancel policies, users should use the respective [**product**](../products/BaseProduct) for the position they would like to cover. Use **PolicyManager** to view policies.
 *
 * Policies are [**ERC721s**](https://docs.openzeppelin.com/contracts/4.x/api/token/erc721#ERC721).
 */
interface IPolicyManager is IERC721Enhanced {

    /***************************************
    EVENTS
    ***************************************/

    /// @notice Emitted when a policy is created.
    event PolicyCreated(uint256 policyID);
    /// @notice Emitted when a policy is updated.
    event PolicyUpdated(uint256 indexed policyID);
    /// @notice Emitted when a policy is burned.
    event PolicyBurned(uint256 policyID);
    /// @notice Emitted when the policy descriptor is set.
    event PolicyDescriptorSet(address policyDescriptor);
    /// @notice Emitted when a new product is added.
    event ProductAdded(address product);
    /// @notice Emitted when a new product is removed.
    event ProductRemoved(address product);

    /***************************************
    POLICY VIEW FUNCTIONS
    ***************************************/

    /// @notice PolicyInfo struct.
    struct PolicyInfo {
        uint256 coverAmount;
        address product;
        uint40 expirationBlock;
        uint24 price;
        bytes positionDescription;
    }

    /**
     * @notice Information about a policy.
     * @param policyID The policy ID to return info.
     * @return info info in a struct.
     */
    function policyInfo(uint256 policyID) external view returns (PolicyInfo memory info);

    /**
     * @notice Information about a policy.
     * @param policyID The policy ID to return info.
     * @return policyholder The address of the policy holder.
     * @return product The product of the policy.
     * @return coverAmount The amount covered for the policy.
     * @return expirationBlock The expiration block of the policy.
     * @return price The price of the policy.
     * @return positionDescription The description of the covered position(s).
     */
    function getPolicyInfo(uint256 policyID) external view returns (address policyholder, address product, uint256 coverAmount, uint40 expirationBlock, uint24 price, bytes calldata positionDescription);

    /**
     * @notice The holder of the policy.
     * @param policyID The policy ID.
     * @return policyholder The address of the policy holder.
     */
    function getPolicyholder(uint256 policyID) external view returns (address policyholder);

    /**
     * @notice The product used to purchase the policy.
     * @param policyID The policy ID.
     * @return product The product of the policy.
     */
    function getPolicyProduct(uint256 policyID) external view returns (address product);

    /**
     * @notice The expiration block of the policy.
     * @param policyID The policy ID.
     * @return expirationBlock The expiration block of the policy.
     */
    function getPolicyExpirationBlock(uint256 policyID) external view returns (uint40 expirationBlock);

    /**
     * @notice The cover amount of the policy.
     * @param policyID The policy ID.
     * @return coverAmount The cover amount of the policy.
     */
    function getPolicyCoverAmount(uint256 policyID) external view returns (uint256 coverAmount);

    /**
     * @notice The cover price in wei per block per wei multiplied by 1e12.
     * @param policyID The policy ID.
     * @return price The price of the policy.
     */
    function getPolicyPrice(uint256 policyID) external view returns (uint24 price);

    /**
     * @notice The byte encoded description of the covered position(s).
     * Only makes sense in context of the product.
     * @param policyID The policy ID.
     * @return positionDescription The description of the covered position(s).
     */
    function getPositionDescription(uint256 policyID) external view returns (bytes calldata positionDescription);

    /*
     * @notice These functions can be used to check a policys stage in the lifecycle.
     * There are three major lifecycle events:
     *   1 - policy is bought (aka minted)
     *   2 - policy expires
     *   3 - policy is burnt (aka deleted)
     * There are four stages:
     *   A - pre-mint
     *   B - pre-expiration
     *   C - post-expiration
     *   D - post-burn
     * Truth table:
     *               A B C D
     *   exists      0 1 1 0
     *   isActive    0 1 0 0
     *   hasExpired  0 0 1 0

    /**
     * @notice Checks if a policy is active.
     * @param policyID The policy ID.
     * @return status True if the policy is active.
     */
    function policyIsActive(uint256 policyID) external view returns (bool);

    /**
     * @notice Checks whether a given policy is expired.
     * @param policyID The policy ID.
     * @return status True if the policy is expired.
     */
    function policyHasExpired(uint256 policyID) external view returns (bool);

    /// @notice The total number of policies ever created.
    function totalPolicyCount() external view returns (uint256 count);

    /// @notice The address of the [`PolicyDescriptor`](./PolicyDescriptor) contract.
    function policyDescriptor() external view returns (address);

    /***************************************
    POLICY MUTATIVE FUNCTIONS
    ***************************************/

    /**
     * @notice Creates a new policy.
     * Can only be called by **products**.
     * @param policyholder The receiver of new policy token.
     * @param coverAmount The policy coverage amount (in wei).
     * @param expirationBlock The policy expiration block number.
     * @param price The coverage price.
     * @param positionDescription The description of the covered position(s).
     * @return policyID The policy ID.
     */
    function createPolicy(
        address policyholder,
        uint256 coverAmount,
        uint40 expirationBlock,
        uint24 price,
        bytes calldata positionDescription
    ) external returns (uint256 policyID);

    /**
     * @notice Modifies a policy.
     * Can only be called by **products**.
     * @param policyID The policy ID.
     * @param coverAmount The policy coverage amount (in wei).
     * @param expirationBlock The policy expiration block number.
     * @param price The coverage price.
     * @param positionDescription The description of the covered position(s).
     */
    function setPolicyInfo(uint256 policyID, uint256 coverAmount, uint40 expirationBlock, uint24 price, bytes calldata positionDescription) external;

    /**
     * @notice Burns expired or cancelled policies.
     * Can only be called by **products**.
     * @param policyID The ID of the policy to burn.
     */
    function burn(uint256 policyID) external;

    /**
     * @notice Burns expired policies.
     * @param policyIDs The list of expired policies.
     */
    function updateActivePolicies(uint256[] calldata policyIDs) external;

    /***************************************
    PRODUCT VIEW FUNCTIONS
    ***************************************/

    /**
     * @notice Checks is an address is an active product.
     * @param product The product to check.
     * @return status True if the product is active.
     */
    function productIsActive(address product) external view returns (bool status);

    /**
     * @notice Returns the number of products.
     * @return count The number of products.
     */
    function numProducts() external view returns (uint256 count);

    /**
     * @notice Returns the product at the given index.
     * @param productNum The index to query.
     * @return product The address of the product.
     */
    function getProduct(uint256 productNum) external view returns (address product);

    /***************************************
    OTHER VIEW FUNCTIONS
    ***************************************/

    function activeCoverAmount() external view returns (uint256);

    /***************************************
    GOVERNANCE FUNCTIONS
    ***************************************/

    /**
     * @notice Adds a new product.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param product the new product
     */
    function addProduct(address product) external;

    /**
     * @notice Removes a product.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param product the product to remove
     */
    function removeProduct(address product) external;


    /**
     * @notice Set the token descriptor.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param policyDescriptor The new token descriptor address.
     */
    function setPolicyDescriptor(address policyDescriptor) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "./IPolicyManager.sol";
import "./IFarm.sol";


/**
 * @title ISptFarm
 * @author solace.fi
 * @notice Rewards [**Policyholders**](/docs/protocol/policy-holder) in [**Options**](../OptionFarming) for staking their [**Policies**](./PolicyManager).
 *
 * Over the course of `startTime` to `endTime`, the farm distributes `rewardPerSecond` [**Options**](../OptionFarming) to all farmers split relative to the value of the policies they have deposited.
 *
 * Note that you should deposit your policies via [`depositPolicy()`](#depositpolicy) or [`depositPolicySigned()`](#depositpolicysigned). Raw `ERC721.transfer()` will not be recognized.
 */
interface ISptFarm is IFarm {

    /***************************************
    EVENTS
    ***************************************/

    // Emitted when a policy is deposited onto the farm.
    event PolicyDeposited(address indexed user, uint256 policyID);
    // Emitted when a policy is withdrawn from the farm.
    event PolicyWithdrawn(address indexed user, uint256 policyID);
    /// @notice Emitted when rewardPerSecond is changed.
    event RewardsSet(uint256 rewardPerSecond);
    /// @notice Emitted when the end time is changed.
    event FarmEndSet(uint256 endTime);

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /// @notice
    function policyManager() external view returns (address policyManager_);

    /// @notice Last time rewards were distributed or farm was updated.
    function lastRewardTime() external view returns (uint256 timestamp);

    /// @notice Accumulated rewards per share, times 1e12.
    function accRewardPerShare() external view returns (uint256 acc);

    /// @notice Value of policies a user deposited.
    function userStaked(address user) external view returns (uint256 amount);

    /// @notice Value of policies deposited by all farmers.
    function valueStaked() external view returns (uint256 amount);

    /// @notice Information about a deposited policy.
    function policyInfo(uint256 policyID) external view returns (address depositor, uint256 value);

    /**
     * @notice Returns the count of [**policies**](./PolicyManager) that a user has deposited onto the farm.
     * @param user The user to check count for.
     * @return count The count of deposited [**policies**](./PolicyManager).
     */
    function countDeposited(address user) external view returns (uint256 count);

    /**
     * @notice Returns the list of [**policies**](./PolicyManager) that a user has deposited onto the farm and their values.
     * @param user The user to list deposited policies.
     * @return policyIDs The list of deposited policies.
     * @return policyValues The values of the policies.
     */
    function listDeposited(address user) external view returns (uint256[] memory policyIDs, uint256[] memory policyValues);

    /**
     * @notice Returns the ID of a [**Policies**](./PolicyManager) that a user has deposited onto a farm and its value.
     * @param user The user to get policyID for.
     * @param index The farm-based index of the token.
     * @return policyID The ID of the deposited [**policy**](./PolicyManager).
     * @return policyValue The value of the [**policy**](./PolicyManager).
     */
    function getDeposited(address user, uint256 index) external view returns (uint256 policyID, uint256 policyValue);

    /***************************************
    MUTATOR FUNCTIONS
    ***************************************/

    /**
     * @notice Deposit a [**policy**](./PolicyManager).
     * User must `ERC721.approve()` or `ERC721.setApprovalForAll()` first.
     * @param policyID The ID of the policy to deposit.
     */
    function depositPolicy(uint256 policyID) external;

    /**
     * @notice Deposit a [**policy**](./PolicyManager) using permit.
     * @param depositor The depositing user.
     * @param policyID The ID of the policy to deposit.
     * @param deadline Time the transaction must go through before.
     * @param v secp256k1 signature
     * @param r secp256k1 signature
     * @param s secp256k1 signature
     */
    function depositPolicySigned(address depositor, uint256 policyID, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    /**
     * @notice Deposit multiple [**policies**](./PolicyManager).
     * User must `ERC721.approve()` or `ERC721.setApprovalForAll()` first.
     * @param policyIDs The IDs of the policies to deposit.
     */
    function depositPolicyMulti(uint256[] memory policyIDs) external;

    /**
     * @notice Deposit multiple [**policies**](./PolicyManager) using permit.
     * @param depositors The depositing users.
     * @param policyIDs The IDs of the policies to deposit.
     * @param deadlines Times the transactions must go through before.
     * @param vs secp256k1 signatures
     * @param rs secp256k1 signatures
     * @param ss secp256k1 signatures
     */
    function depositPolicySignedMulti(address[] memory depositors, uint256[] memory policyIDs, uint256[] memory deadlines, uint8[] memory vs, bytes32[] memory rs, bytes32[] memory ss) external;

    /**
     * @notice Withdraw a [**policy**](./PolicyManager).
     * Can only withdraw policies you deposited.
     * @param policyID The ID of the policy to withdraw.
     */
    function withdrawPolicy(uint256 policyID) external;

    /**
     * @notice Withdraw multiple [**policies**](./PolicyManager).
     * Can only withdraw policies you deposited.
     * @param policyIDs The IDs of the policies to withdraw.
     */
    function withdrawPolicyMulti(uint256[] memory policyIDs) external;

    /**
     * @notice Burns expired policies.
     * @param policyIDs The list of expired policies.
     */
    function updateActivePolicies(uint256[] calldata policyIDs) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

/**
 * @title IGovernable
 * @author solace.fi
 * @notice Enforces access control for important functions to [**governor**](/docs/protocol/governance).
 *
 * Many contracts contain functionality that should only be accessible to a privileged user. The most common access control pattern is [OpenZeppelin's `Ownable`](https://docs.openzeppelin.com/contracts/4.x/access-control#ownership-and-ownable). We instead use `Governable` with a few key differences:
 * - Transferring the governance role is a two step process. The current governance must [`setPendingGovernance(pendingGovernance_)`](#setPendingGovernance) then the new governance must [`acceptGovernance()`](#acceptgovernance). This is to safeguard against accidentally setting ownership to the wrong address and locking yourself out of your contract.
 * - `governance` is a constructor argument instead of `msg.sender`. This is especially useful when deploying contracts via a [`SingletonFactory`](./ISingletonFactory).
 * - We use `lockGovernance()` instead of `renounceOwnership()`. `renounceOwnership()` is a prerequisite for the reinitialization bug because it sets `owner = address(0x0)`. We also use the `governanceIsLocked()` flag.
 */
interface IGovernable {

    /***************************************
    EVENTS
    ***************************************/

    /// @notice Emitted when pending Governance is set.
    event GovernancePending(address pendingGovernance);
    /// @notice Emitted when Governance is set.
    event GovernanceTransferred(address oldGovernance, address newGovernance);
    /// @notice Emitted when Governance is locked.
    event GovernanceLocked();

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /// @notice Address of the current governor.
    function governance() external view returns (address);

    /// @notice Address of the governor to take over.
    function pendingGovernance() external view returns (address);

    /// @notice Returns true if governance is locked.
    function governanceIsLocked() external view returns (bool);

    /***************************************
    MUTATORS
    ***************************************/

    /**
     * @notice Initiates transfer of the governance role to a new governor.
     * Transfer is not complete until the new governor accepts the role.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param pendingGovernance_ The new governor.
     */
    function setPendingGovernance(address pendingGovernance_) external;

    /**
     * @notice Accepts the governance role.
     * Can only be called by the new governor.
     */
    function acceptGovernance() external;

    /**
     * @notice Permanently locks this contract's governance role and any of its functions that require the role.
     * This action cannot be reversed.
     * Before you call it, ask yourself:
     *   - Is the contract self-sustaining?
     *   - Is there a chance you will need governance privileges in the future?
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     */
    function lockGovernance() external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// code borrowed from OpenZeppelin and @uniswap/v3-periphery
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

/**
 * @title ERC721Enhanced
 * @author solace.fi
 * @notice An extension of `ERC721`.
 *
 * The base is OpenZeppelin's `ERC721Enumerable` which also includes the `Metadata` extension. This extension includes simpler transfers, gasless approvals, and better enumeration.
 */
interface IERC721Enhanced is IERC721Enumerable {

    /***************************************
    SIMPLER TRANSFERS
    ***************************************/

    /**
     * @notice Transfers `tokenID` from `msg.sender` to `to`.
     * @dev This was excluded from the official `ERC721` standard in favor of `transferFrom(address from, address to, uint256 tokenID)`. We elect to include it.
     * @param to The receipient of the token.
     * @param tokenID The token to transfer.
     */
    function transfer(address to, uint256 tokenID) external;

    /**
     * @notice Safely transfers `tokenID` from `msg.sender` to `to`.
     * @dev This was excluded from the official `ERC721` standard in favor of `safeTransferFrom(address from, address to, uint256 tokenID)`. We elect to include it.
     * @param to The receipient of the token.
     * @param tokenID The token to transfer.
     */
    function safeTransfer(address to, uint256 tokenID) external;

    /***************************************
    GASLESS APPROVALS
    ***************************************/

    /**
     * @notice Approve of a specific `tokenID` for spending by `spender` via signature.
     * @param spender The account that is being approved.
     * @param tokenID The ID of the token that is being approved for spending.
     * @param deadline The deadline timestamp by which the call must be mined for the approve to work.
     * @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`.
     * @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`.
     * @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`.
     */
    function permit(
        address spender,
        uint256 tokenID,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @notice Returns the current nonce for `tokenID`. This value must be
     * included whenever a signature is generated for `permit`.
     * Every successful call to `permit` increases ``tokenID``'s nonce by one. This
     * prevents a signature from being used multiple times.
     * @param tokenID ID of the token to request nonce.
     * @return nonce Nonce of the token.
     */
    function nonces(uint256 tokenID) external view returns (uint256 nonce);

    /**
     * @notice The permit typehash used in the `permit` signature.
     * @return typehash The typehash for the `permit`.
     */
    // solhint-disable-next-line func-name-mixedcase
    function PERMIT_TYPEHASH() external view returns (bytes32 typehash);

    /**
     * @notice The domain separator used in the encoding of the signature for `permit`, as defined by `EIP712`.
     * @return seperator The domain seperator for `permit`.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32 seperator);

    /***************************************
    BETTER ENUMERATION
    ***************************************/

    /**
     * @notice Lists all tokens.
     * Order not specified.
     * @dev This function is more useful off chain than on chain.
     * @return tokenIDs The list of token IDs.
     */
    function listTokens() external view returns (uint256[] memory tokenIDs);

    /**
     * @notice Lists the tokens owned by `owner`.
     * Order not specified.
     * @dev This function is more useful off chain than on chain.
     * @return tokenIDs The list of token IDs.
     */
    function listTokensOfOwner(address owner) external view returns (uint256[] memory tokenIDs);

    /**
     * @notice Determines if a token exists or not.
     * @param tokenID The ID of the token to query.
     * @return status True if the token exists, false if it doesn't.
     */
    function exists(uint256 tokenID) external view returns (bool status);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "./IFarmController.sol";


/**
 * @title IFarm
 * @author solace.fi
 * @notice Rewards investors in [**SOLACE**](../SOLACE).
 */
interface IFarm {

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /// @notice [`IFarmController`](../FarmController) contract.
    function farmController() external view returns (address);

    /// @notice A unique enumerator that identifies the farm type.
    function farmType() external view returns (uint256);

    /// @notice Amount of rewards distributed per second.
    function rewardPerSecond() external view returns (uint256);

    /// @notice When the farm will start.
    function startTime() external view returns (uint256);

    /// @notice When the farm will end.
    function endTime() external view returns (uint256);

    /**
     * @notice Calculates the accumulated rewards for specified user.
     * @param user The user for whom unclaimed tokens will be shown.
     * @return reward Total amount of withdrawable rewards.
     */
    function pendingRewards(address user) external view returns (uint256 reward);

    /**
     * @notice Calculates the reward amount distributed between two timestamps.
     * @param from The start of the period to measure rewards for.
     * @param to The end of the period to measure rewards for.
     * @return amount The reward amount distributed in the given period.
     */
    function getRewardAmountDistributed(uint256 from, uint256 to) external view returns (uint256 amount);

    /***************************************
    MUTATOR FUNCTIONS
    ***************************************/

    /**
     * @notice Converts the senders unpaid rewards into an [`Option`](../OptionsFarming).
     * @return optionID The ID of the newly minted [`Option`](../OptionsFarming).
     */
    function withdrawRewards() external returns (uint256 optionID);

    /**
     * @notice Withdraw a users rewards without unstaking their tokens.
     * Can only be called by [`FarmController`](../FarmController).
     * @param user User to withdraw rewards for.
     * @return rewardAmount The amount of rewards the user earned on this farm.
     */
    function withdrawRewardsForUser(address user) external returns (uint256 rewardAmount);

    /**
     * @notice Updates farm information to be up to date to the current time.
     */
    function updateFarm() external;

    /***************************************
    GOVERNANCE FUNCTIONS
    ***************************************/

    /**
     * @notice Sets the amount of rewards to distribute per second.
     * Only affects future rewards.
     * Can only be called by [`FarmController`](../FarmController).
     * @param rewardPerSecond_ Amount to distribute per second.
     */
    function setRewards(uint256 rewardPerSecond_) external;

    /**
     * @notice Sets the farm's end time. Used to extend the duration.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param endTime_ The new end time.
     */
    function setEnd(uint256 endTime_) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;


/**
 * @title IFarmController
 * @author solace.fi
 * @notice Controls the allocation of rewards across multiple farms.
 */
interface IFarmController {

    /***************************************
    EVENTS
    ***************************************/

    /// @notice Emitted when a farm is registered.
    event FarmRegistered(uint256 indexed farmID, address indexed farmAddress);
    /// @notice Emitted when reward per second is changed.
    event RewardsSet(uint256 rewardPerSecond);

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /// @notice Rewards distributed per second across all farms.
    function rewardPerSecond() external view returns (uint256);

    /// @notice Total allocation points across all farms.
    function totalAllocPoints() external view returns (uint256);

    /// @notice The number of farms that have been created.
    function numFarms() external view returns (uint256);

    /// @notice Given a farm ID, return its address.
    /// @dev Indexable 1-numFarms, 0 is null farm.
    function farmAddresses(uint256 farmID) external view returns (address);

    /// @notice Given a farm address, returns its ID.
    /// @dev Returns 0 for not farms and unregistered farms.
    function farmIndices(address farmAddress) external view returns (uint256);

    /// @notice Given a farm ID, how many points the farm was allocated.
    function allocPoints(uint256 farmID) external view returns (uint256);

    /**
     * @notice Calculates the accumulated balance of rewards for the specified user.
     * @param user The user for whom unclaimed rewards will be shown.
     * @return reward Total amount of withdrawable rewards.
     */
    function pendingRewards(address user) external view returns (uint256 reward);

    /***************************************
    MUTATOR FUNCTIONS
    ***************************************/

    /**
     * @notice Updates all farms to be up to date to the current second.
     */
    function massUpdateFarms() external;

    /***************************************
    OPTIONS CREATION FUNCTIONS
    ***************************************/

    /**
     * @notice Withdraw your rewards from all farms and create an [`Option`](../OptionsFarming).
     * @return optionID The ID of the new [`Option`](./OptionsFarming).
     */
    function farmOptionMulti() external returns (uint256 optionID);

    /**
     * @notice Creates an [`Option`](../OptionsFarming) for the given `rewardAmount`.
     * Must be called by a farm.
     * @param recipient The recipient of the option.
     * @param rewardAmount The amount to reward in the Option.
     * @return optionID The ID of the new [`Option`](./OptionsFarming).
     */
    function createOption(address recipient, uint256 rewardAmount) external returns (uint256 optionID);

    /***************************************
    GOVERNANCE FUNCTIONS
    ***************************************/

    /**
     * @notice Registers a farm.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * Cannot register a farm more than once.
     * @param farmAddress The farm's address.
     * @param allocPoints How many points to allocate this farm.
     * @return farmID The farm ID.
     */
    function registerFarm(address farmAddress, uint256 allocPoints) external returns (uint256 farmID);

    /**
     * @notice Sets a farm's allocation points.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param farmID The farm to set allocation points.
     * @param allocPoints_ How many points to allocate this farm.
     */
    function setAllocPoints(uint256 farmID, uint256 allocPoints_) external;

    /**
     * @notice Sets the reward distribution across all farms.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param rewardPerSecond_ Amount of reward to distribute per second.
     */
    function setRewardPerSecond(uint256 rewardPerSecond_) external;
}