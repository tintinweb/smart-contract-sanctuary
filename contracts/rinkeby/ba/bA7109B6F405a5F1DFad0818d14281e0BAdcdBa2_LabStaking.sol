// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./StakingBonusManager.sol";

contract LabStaking is
  Initializable,
  IERC721ReceiverUpgradeable,
  AccessControlEnumerableUpgradeable,
  PausableUpgradeable
{
  
  using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
  bytes32 public constant TRANSFERRER_ROLE = keccak256("TRANSFERRER_ROLE");

  struct Stake {
    address owner;
    uint256 lastClaimedPeriod;
    uint256 stakedAtPeriod;
  }

  struct StakePeriod {
    uint256 start;
    uint256 totalStaked;
  }

  // tokenId => Stake
  mapping(uint256 => Stake) private _stakes;
  // user address => tokenIds staked
  mapping(address => EnumerableSetUpgradeable.UintSet) private _userStakes;

  // period number => StakePeriod
  mapping(uint256 => StakePeriod) private _stakePeriods;

  uint256 private _lastPopulatedPeriod;

  IERC721 private _nft;
  uint256 private _maxPeriodRewards;
  uint256 private _periodLength;
  uint256 private _stakingLockPeriods;

  mapping(address => uint256) private _balances;

  
  // for the halving mechanism
  uint256 private _halvingInPeriods;
  uint256 private _halvingReduction;
  uint256 private _nextHalving;

  StakingBonusManager private _stakingBonusManager;

  event Staked(uint256 tokenId, address owner, uint256 period);
  event UnStaked(uint256 tokenId, address owner, uint256 period);
  event RewardsCollected(
    uint256 tokenId,
    address owner,
    uint256 periods,
    uint256 amount
  );

  function initialize(
    IERC721 nft_,
    uint256 maxPeriodRewards_,
    uint256 periodLength_,
    uint256 stakingLockPeriods_,
    uint256 halvingInPeriods_,
    uint256 halvingReduction_,
    StakingBonusManager stakingBonusManager_
  ) external initializer {
    AccessControlEnumerableUpgradeable.__AccessControlEnumerable_init();
    PausableUpgradeable.__Pausable_init();
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(PAUSER_ROLE, msg.sender);
    _setupRole(TRANSFERRER_ROLE, msg.sender);
    _nft = nft_;
    _maxPeriodRewards = maxPeriodRewards_;
    _periodLength = periodLength_;
    _stakingLockPeriods = stakingLockPeriods_;
    _stakePeriods[0] = StakePeriod(block.timestamp, 0);
    _lastPopulatedPeriod = 0;
    _halvingInPeriods = halvingInPeriods_;
    _halvingReduction = halvingReduction_;
    _nextHalving = halvingInPeriods_;
    _stakingBonusManager = stakingBonusManager_;
  }

  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes calldata data
  ) external whenNotPaused returns (bytes4) {
    operator;
    data;
    require(msg.sender == address(_nft), "nft address not supported");
    require(from == tx.origin, "no contracts allowed");
    uint256 currPeriod = currentPeriod();
    _stakes[tokenId] = Stake(from, currPeriod, currPeriod);
    _userStakes[from].add(tokenId);
    if (_stakePeriods[currPeriod].start == 0) {
      // the first time an NFT is staked on this period
      _stakePeriods[currPeriod] = StakePeriod(
        _stakePeriods[_lastPopulatedPeriod].start +
          ((currPeriod - _lastPopulatedPeriod) * _periodLength),
        _stakePeriods[_lastPopulatedPeriod].totalStaked + 1
      );
      _lastPopulatedPeriod = currPeriod;
    } else {
      _stakePeriods[currPeriod].totalStaked++;
    }
    emit Staked(tokenId, from, currPeriod);
    return IERC721ReceiverUpgradeable.onERC721Received.selector;
  }

  function collectRewardsBatch(
    uint256[] calldata tokenIds,
    uint256[] calldata periods
  ) external whenNotPaused returns (uint256) {
    uint256 rewards = 0;
    for (uint256 i = 0; i < tokenIds.length; i++) {
      rewards += _collectRewards(tokenIds[i], periods[i]);
    }
    return rewards;
  }

  function _collectRewards(uint256 tokenId, uint256 periods)
    internal
    returns (uint256)
  {
    require(_stakes[tokenId].owner == msg.sender, "tokenId non owner");

    uint256 currPeriod = currentPeriod();
    uint256 tokenLastClaimedPeriod = _stakes[tokenId].lastClaimedPeriod;
    uint256 nextClaimedPeriod = tokenLastClaimedPeriod + periods;
    require(nextClaimedPeriod < currPeriod, "trying to claim too many periods");
    _calculateHalving(nextClaimedPeriod);
    StakePeriod storage lastClaimed = _stakePeriods[
      tokenLastClaimedPeriod
    ];
    uint256 lastTotalStaked = lastClaimed.totalStaked;
    uint256 rewards = 0;

    for (
      uint256 i = tokenLastClaimedPeriod + 1;
      i <= nextClaimedPeriod;
      i++
    ) {
      StakePeriod storage period = _stakePeriods[i];
      if (period.start == 0) {
        if (i == nextClaimedPeriod) {
          // last one that will be processed as part of this tx
          // It is empty and this will be the lastClaimedPeriod, so we need this
          // period to be actually populated.
          _stakePeriods[i] = StakePeriod(
            lastClaimed.start +
              ((nextClaimedPeriod - tokenLastClaimedPeriod) *
                _periodLength),
            lastTotalStaked
          );
          _lastPopulatedPeriod = i;
        }
        rewards += (_maxPeriodRewards / lastTotalStaked);
      } else {
        lastTotalStaked = period.totalStaked;
        rewards += (_maxPeriodRewards / lastTotalStaked);
      }
    }
    rewards = _stakingBonusManager.applyAllBonuses(rewards, currPeriod, tokenLastClaimedPeriod, msg.sender);
    _balances[msg.sender] += rewards;
    _stakes[tokenId].lastClaimedPeriod = nextClaimedPeriod;
    emit RewardsCollected(tokenId, msg.sender, periods, rewards);
    return rewards;
  }

  function _calculateHalving(uint256 period) internal {
    if (period >= _nextHalving) {
      uint256 reduction = (_maxPeriodRewards * _halvingReduction) / 100;
      _maxPeriodRewards = _maxPeriodRewards - reduction;
      _nextHalving = _nextHalving + _halvingInPeriods;
    }
  }

  

  function collectAllRewardsBatch(uint256[] calldata tokenIds)
    external
    whenNotPaused
  {
    uint256 currPeriod = currentPeriod();
    for (uint256 i = 0; i < tokenIds.length; i++) {
      _collectRewards(
        tokenIds[i],
        currPeriod - _stakes[tokenIds[i]].lastClaimedPeriod - 1
      );
    }
  }

  // currPeriod is a param to avoid calling currentPeriod() in loop
  function _collectAllRewards(uint256 tokenId, uint256 currPeriod) internal {
    _collectRewards(
      tokenId,
      currPeriod - _stakes[tokenId].lastClaimedPeriod - 1
    );
  }

  function pendingRewards(uint256 tokenId) public view returns (uint256) {
    uint256 currPeriod = currentPeriod();
    StakePeriod storage lastClaimed = _stakePeriods[
      _stakes[tokenId].lastClaimedPeriod
    ];
    uint256 lastTotalStaked = lastClaimed.totalStaked;
    if (lastTotalStaked == 0) {
      return 0;
    }
    if (currPeriod == _stakes[tokenId].lastClaimedPeriod) {
      return 0;
    }
    if (_stakes[tokenId].owner == address(0)) {
      return 0;
    }
    uint256 periods = currPeriod - _stakes[tokenId].lastClaimedPeriod - 1;
    uint256 nextClaimedPeriod = _stakes[tokenId].lastClaimedPeriod + periods;

    uint256 rewards = 0;

    for (
      uint256 i = _stakes[tokenId].lastClaimedPeriod + 1;
      i <= nextClaimedPeriod;
      i++
    ) {
      StakePeriod storage period = _stakePeriods[i];
      if (period.start == 0) {
        rewards += (_maxPeriodRewards / lastTotalStaked);
      } else {
        lastTotalStaked = period.totalStaked;
        rewards += (_maxPeriodRewards / lastTotalStaked);
      }
    }
    rewards = _stakingBonusManager.applyAllBonuses(rewards, currPeriod, _stakes[tokenId].lastClaimedPeriod, msg.sender);
    return rewards;
  }

  function unstakeBatch(uint256[] calldata tokenIds) external whenNotPaused {
    for (uint256 i = 0; i < tokenIds.length; i++) {
      _unstake(tokenIds[i]);
    }
  }

  function _unstake(uint256 tokenId) internal {
    uint256 currPeriod = currentPeriod();
    require(_stakes[tokenId].owner == msg.sender, "tokenId non owner");
    require(
      _stakes[tokenId].stakedAtPeriod + _stakingLockPeriods <= currPeriod,
      "locking period not met"
    );
    require(
      _stakes[tokenId].lastClaimedPeriod == currPeriod - 1,
      "pending rewards"
    );

    // giving back what is yours
    _nft.transferFrom(address(this), _stakes[tokenId].owner, tokenId);

    // clearing state vars
    _stakes[tokenId].owner = address(0);
    // changing total staked. checking if current period exists
    if (_stakePeriods[currPeriod].start == 0) {
      // period does not exist. Creating it
      _stakePeriods[currPeriod] = StakePeriod(
        _stakePeriods[_lastPopulatedPeriod].start +
          ((currPeriod - _lastPopulatedPeriod) * _periodLength),
        _stakePeriods[_lastPopulatedPeriod].totalStaked - 1
      );
      _lastPopulatedPeriod = currPeriod;
    } else {
      // period exists. Modifying it
      _stakePeriods[currPeriod].totalStaked--;
    }
    _userStakes[msg.sender].remove(tokenId);
    emit UnStaked(tokenId, msg.sender, currPeriod);
  }

  function exitBatch(uint256[] calldata tokenIds) external whenNotPaused {
    for (uint256 i = 0; i < tokenIds.length; i++) {
      _exit(tokenIds[i]);
    }
  }

  function _exit(uint256 tokenId) public {
    uint256 currPeriod = currentPeriod();
    _collectAllRewards(tokenId, currPeriod);
    _unstake(tokenId);
  }

  function transferTreasury(
    uint256 amount,
    address from_,
    address to
  ) public {
    require(
      hasRole(TRANSFERRER_ROLE, msg.sender),
      "must have transferrer role"
    );
    uint256 senderBalance = _balances[from_];
    require(senderBalance >= amount, "transfer amount exceeds balance");
    _balances[from_] = senderBalance - amount;
    _balances[to] += amount;
  }

  

  function setMaxPeriodRewards(uint256 maxPeriodRewards_) public {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "must have admin role");
    _maxPeriodRewards = maxPeriodRewards_;
  }

  function setStakingLockPeriods(uint256 stakingLockPeriods_) public {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "must have admin role");
    _stakingLockPeriods = stakingLockPeriods_;
  }

  function setHalvingInPeriods(uint256 halvingInPeriods_) public {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "must have admin role");
    _halvingInPeriods = halvingInPeriods_;
  }

  function setHalvingReduction(uint256 halvingReduction_) public {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "must have admin role");
    _halvingReduction = halvingReduction_;
  }

  function setNextHalving(uint256 nextHalving_) public {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "must have admin role");
    _nextHalving = nextHalving_;
  }

  function pause() public virtual {
    require(hasRole(PAUSER_ROLE, msg.sender), "must have pauser role");
    _pause();
  }

  function unpause() public virtual {
    require(hasRole(PAUSER_ROLE, msg.sender), "must have pauser role");
    _unpause();
  }

  function currentPeriod() public view returns (uint256) {
    return (block.timestamp - _stakePeriods[0].start) / _periodLength;
  }

  function secondsLeftToClaim(uint256 tokenId) public view returns (uint256) {
    uint256 nextPeriodToClaim = _stakes[tokenId].lastClaimedPeriod + 1;
    (
      uint256 nextPeriodStartTimestamp,
      uint256 nextPeriodEndTimestamp
    ) = periodTimestamp(nextPeriodToClaim);
    nextPeriodStartTimestamp;
    if (nextPeriodEndTimestamp <= block.timestamp) {
      return 0;
    }
    return nextPeriodEndTimestamp - block.timestamp;
  }

  // returns (periodStartTimestamp, periodEndTimestamp)
  function periodTimestamp(uint256 period)
    public
    view
    returns (uint256, uint256)
  {
    uint256 periodStart = _stakePeriods[0].start + (period * _periodLength);
    return (periodStart, periodStart + _periodLength);
  }

  function totalStaked() public view returns (uint256) {
    return _stakePeriods[_lastPopulatedPeriod].totalStaked;
  }

  function stakes(uint256 tokenId) public view returns (Stake memory) {
    return _stakes[tokenId];
  }

  function userStakesLength(address user) public view returns (uint256) {
    return _userStakes[user].length();
  }

  function userStake(address user, uint256 index)
    public
    view
    returns (uint256)
  {
    return _userStakes[user].at(index);
  }

  function stakePeriods(uint256 periodNumber)
    public
    view
    returns (StakePeriod memory)
  {
    return _stakePeriods[periodNumber];
  }

  function lastClaimedPeriod(uint256 tokenId) public view returns (uint256) {
    return _stakes[tokenId].lastClaimedPeriod;
  }

  function stakedAtPeriod(uint256 tokenId) public view returns (uint256) {
    return _stakes[tokenId].stakedAtPeriod;
  }

  function balanceOf(address user) public view returns (uint256) {
    return _balances[user];
  }

  function lastPopulatedPeriod() public view returns (uint256) {
    return _lastPopulatedPeriod;
  }

  function stakingLockPeriods() public view returns (uint256) {
    return _stakingLockPeriods;
  }

  function maxPeriodRewards() public view returns (uint256) {
    return _maxPeriodRewards;
  }

  function halvingInPeriods() public view returns (uint256) {
    return _halvingInPeriods;
  }

  function halvingReduction() public view returns (uint256) {
    return _halvingReduction;
  }

  function nextHalving() public view returns (uint256) {
    return _nextHalving;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

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
library EnumerableSetUpgradeable {
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "../utils/structs/EnumerableSetUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerableUpgradeable is Initializable, IAccessControlEnumerableUpgradeable, AccessControlUpgradeable {
    function __AccessControlEnumerable_init() internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
        __AccessControlEnumerable_init_unchained();
    }

    function __AccessControlEnumerable_init_unchained() internal onlyInitializing {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    mapping(bytes32 => EnumerableSetUpgradeable.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract StakingBonusManager is Initializable, AccessControlEnumerableUpgradeable {

  using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
  using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

  // partner contract address => % bonus when collecting rewards
  mapping(address => uint256) private _partners;
  // just to iterate over it
  EnumerableSetUpgradeable.AddressSet private _partnersSet;

  // 0xPandemic badges contract address => % bonus when collecting rewards
  mapping(address => uint256) private _badges;
  // just to iterate over it
  EnumerableSetUpgradeable.AddressSet private _badgesSet;

  // % bonus for claiming only _earlyClaimBonusPeriods periods
  // to incentivize claiming often
  uint256 private _earlyClaimBonus;
  uint256 private _earlyClaimBonusPeriods;

   function initialize(
    uint256 earlyClaimBonus_,
    uint256 earlyClaimBonusPeriods_
   ) external initializer {
         AccessControlEnumerableUpgradeable.__AccessControlEnumerable_init();
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

    _earlyClaimBonusPeriods = earlyClaimBonusPeriods_;
    _earlyClaimBonus = earlyClaimBonus_;
   }

  function applyAllBonuses(uint256 rewards, uint256 currentPeriod, uint256 tokenLastClaimedPeriod, address claimingAddress) public view returns (uint256) {
    uint256 partnershipsRewards = _calculatePartnershipsRewardsBonus(claimingAddress, rewards);
    uint256 badgesRewards =  _calculateBadgesRewardsBonus(claimingAddress, rewards);
    uint256 earlyClaimRewards = _calculateEarlyClaimRewardBonus(rewards, currentPeriod, tokenLastClaimedPeriod);
    return rewards + partnershipsRewards + earlyClaimRewards + badgesRewards;
  }

  function hasEarlyClaimBonus(uint256 currentPeriod, uint256 tokenLastClaimedPeriod) public view returns (bool) {
    if (currentPeriod == tokenLastClaimedPeriod) {
      return true;
    }
    uint256 periodsLeft = currentPeriod - tokenLastClaimedPeriod - 1;
    return periodsLeft <= _earlyClaimBonusPeriods;
  }

  function partnerShipRewardBonus(address claimingAddress)
    public
    view
    returns (uint256, address)
  {
    uint256 length = _partnersSet.length();
    uint256 rewardMultiplier = 0;
    address selectedPartnerAddress = address(0);
    for (uint256 i = 0; i < length; i++) {
      address partnerAddress = _partnersSet.at(i);
      if (IERC721(partnerAddress).balanceOf(claimingAddress) > 0) {
        uint256 multiplier = _partners[partnerAddress];
        if (multiplier > rewardMultiplier) {
          rewardMultiplier = multiplier;
          selectedPartnerAddress = partnerAddress;
        }
      }
    }
    return (rewardMultiplier, selectedPartnerAddress);
  }

  function badgesRewardBonus(address claimingAddress)
    public
    view
    returns (uint256, address)
  {
    uint256 length = _badgesSet.length();
    uint256 rewardMultiplier = 0;
    address selectedBadgeAddress = address(0);
    for (uint256 i = 0; i < length; i++) {
      address badgeAddress = _badgesSet.at(i);
      if (IERC721(badgeAddress).balanceOf(claimingAddress) > 0) {
        uint256 multiplier = _badges[badgeAddress];
        if (multiplier > rewardMultiplier) {
          rewardMultiplier = multiplier;
          selectedBadgeAddress = badgeAddress;
        }
      }
    }
    return (rewardMultiplier, selectedBadgeAddress);
  }

function _calculatePartnershipsRewardsBonus(
    address claimingAddress,
    uint256 rewards
  ) internal view returns (uint256) {
    (uint256 multiplier, address partner_) = partnerShipRewardBonus(
      claimingAddress
    );
    partner_;
    return (rewards * multiplier) / 100;
  }

  function _calculateBadgesRewardsBonus(
    address claimingAddress,
    uint256 rewards
  ) internal view returns (uint256) {
    (uint256 multiplier, address badge_) = badgesRewardBonus(
      claimingAddress
    );
    badge_;
    return (rewards * multiplier) / 100;
  }

  function _calculateEarlyClaimRewardBonus(uint256 reward, uint256 currentPeriod, uint256 tokenLastClaimedPeriod)
    internal
    view
    returns (uint256)
  {
    if (hasEarlyClaimBonus(currentPeriod, tokenLastClaimedPeriod)) {
      return (reward * _earlyClaimBonus) / 100;
    }
    return 0;
  }

  
function addPartner(address partner_, uint256 bonus) public {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "must have admin role");
    _partners[partner_] = bonus;
    _partnersSet.add(partner_);
  }

  function removePartner(address partner_) public {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "must have admin role");
    _partners[partner_] = 0;
    _partnersSet.remove(partner_);
  }

  function addBadge(address badge_, uint256 bonus) public {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "must have admin role");
    _badges[badge_] = bonus;
    _badgesSet.add(badge_);
  }

  function removeBadge(address badge_) public {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "must have admin role");
    _badges[badge_] = 0;
    _badgesSet.remove(badge_);
  }

  function setEarlyClaimBonus(uint256 earlyClaimBonus_) public {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "must have admin role");
    _earlyClaimBonus = earlyClaimBonus_;
  }

  function setEarlyClaimBonusPeriods(uint256 earlyClaimBonusPeriods_) public {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "must have admin role");
    _earlyClaimBonusPeriods = earlyClaimBonusPeriods_;
  }


  function earlyClaimBonus() public view returns (uint256) {
    return _earlyClaimBonus;
  }

  function earlyClaimBonusPeriods() public view returns (uint256) {
    return _earlyClaimBonusPeriods;
  }

  function partnersLength() public view returns (uint256) {
    return _partnersSet.length();
  }

  function partner(uint256 index) public view returns (address) {
    return _partnersSet.at(index);
  }

  function badgesLength() public view returns (uint256) {
    return _badgesSet.length();
  }

  function badge(uint256 index) public view returns (address) {
    return _badgesSet.at(index);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerableUpgradeable is IAccessControlUpgradeable {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
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
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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
interface IERC165Upgradeable {
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