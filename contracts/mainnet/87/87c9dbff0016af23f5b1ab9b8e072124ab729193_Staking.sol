/**
 *Submitted for verification at Etherscan.io on 2021-04-14
*/

// File: contracts/library/ERC20.sol

pragma solidity ^0.4.24;

interface ERC20 {

    function totalSupply() public view returns (uint);
    function balanceOf(address owner) public view returns (uint);
    function allowance(address owner, address spender) public view returns (uint);
    function transfer(address to, uint value) public returns (bool);
    function transferFrom(address from, address to, uint value) public returns (bool);
    function approve(address spender, uint value) public returns (bool);

}

// File: contracts/library/Ownable.sol

pragma solidity ^0.4.24;

contract Ownable {

    address public owner;

    modifier onlyOwner {
        require(isOwner(msg.sender));
        _;
    }

    function Ownable() public {
        owner = msg.sender;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }

    function isOwner(address _address) public view returns (bool) {
        return owner == _address;
    }
}

// File: contracts/library/SafeMath.sol

pragma solidity ^0.4.24;

library SafeMath {

    function mul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        assert(b > 0);
        uint c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }

    function max64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint a, uint b) internal pure returns (uint) {
        return a >= b ? a : b;
    }

    function min256(uint a, uint b) internal pure returns (uint) {
        return a < b ? a : b;
    }
}

// File: contracts/library/Pausable.sol

pragma solidity ^0.4.24;


/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

// File: contracts/library/Whitelist.sol

pragma solidity ^0.4.24;



/**
 * @title Whitelist
 * @dev The Whitelist contract has a whitelist of addresses, and provides basic authorization control functions.
 * @dev This simplifies the implementation of "user permissions".
 */
contract Whitelist is Ownable {
  mapping(address => bool) public whitelist;

  event WhitelistedAddressAdded(address addr);
  event WhitelistedAddressRemoved(address addr);

  /**
   * @dev Throws if called by any account that's not whitelisted.
   */
  modifier onlyWhitelisted() {
    require(whitelist[msg.sender]);
    _;
  }

  /**
   * @dev add an address to the whitelist
   * @param addr address
   * @return true if the address was added to the whitelist, false if the address was already in the whitelist
   */
  function addAddressToWhitelist(address addr) onlyOwner public returns(bool success) {
    if (!whitelist[addr]) {
      whitelist[addr] = true;
      emit WhitelistedAddressAdded(addr);
      success = true;
    }
  }

  /**
   * @dev add addresses to the whitelist
   * @param addrs addresses
   * @return true if at least one address was added to the whitelist,
   * false if all addresses were already in the whitelist
   */
  function addAddressesToWhitelist(address[] addrs) onlyOwner public returns(bool success) {
    for (uint256 i = 0; i < addrs.length; i++) {
      if (addAddressToWhitelist(addrs[i])) {
        success = true;
      }
    }
  }

  /**
   * @dev remove an address from the whitelist
   * @param addr address
   * @return true if the address was removed from the whitelist,
   * false if the address wasn't in the whitelist in the first place
   */
  function removeAddressFromWhitelist(address addr) onlyOwner public returns(bool success) {
    if (whitelist[addr]) {
      whitelist[addr] = false;
      emit WhitelistedAddressRemoved(addr);
      success = true;
    }
  }

  /**
   * @dev remove addresses from the whitelist
   * @param addrs addresses
   * @return true if at least one address was removed from the whitelist,
   * false if all addresses weren't in the whitelist in the first place
   */
  function removeAddressesFromWhitelist(address[] addrs) onlyOwner public returns(bool success) {
    for (uint256 i = 0; i < addrs.length; i++) {
      if (removeAddressFromWhitelist(addrs[i])) {
        success = true;
      }
    }
  }

}

// File: contracts/Staking.sol

pragma solidity ^0.4.24;






/**
 * @title Staking and voting contract.
 * @author IoTeX Team
 *
 */
contract Staking is Pausable, Whitelist {
    using SafeMath for uint256;

    // Events to be emitted
    event BucketCreated(uint256 bucketIndex, bytes12 canName, uint256 amount, uint256 stakeDuration, bool nonDecay, bytes data);
    event BucketUpdated(uint256 bucketIndex, bytes12 canName, uint256 stakeDuration, uint256 stakeStartTime, bool nonDecay, address bucketOwner, bytes data);
    event BucketUnstake(uint256 bucketIndex, bytes12 canName, uint256 amount, bytes data);
    event BucketWithdraw(uint256 bucketIndex, bytes12 canName, uint256 amount, bytes data);
    // TODO add change owner event which is not covered by BucketUpdated event

    // IOTX used for staking
    ERC20 stakingToken;

    // Unit is epoch
    uint256 public constant minStakeDuration = 0;
    uint256 public constant maxStakeDuration = 350;
    uint256 public constant minStakeAmount = 100 * 10 ** 18;
    uint256 public constant unStakeDuration = 3;

    uint256 public constant maxBucketsPerAddr = 500;
    uint256 public constant secondsPerEpoch = 86400;

    // Core data structure to track staking/voting status
    struct Bucket {
        bytes12 canName;            // Candidate name, which maps to public keys by NameRegistration.sol
        uint256 stakedAmount;       // Number of tokens
        uint256 stakeDuration;      // Stake duration, unit: second since epoch
        uint256 stakeStartTime;     // Staking start time, unit: second since epoch
        bool nonDecay;              // Nondecay staking -- staking for N epochs consistently without decaying
        uint256 unstakeStartTime;   // unstake timestamp, unit: second since epoch
        address bucketOwner;        // Owner of this bucket, usually the one who created it but can be someone else
        uint256 createTime;         // bucket firstly create time
        uint256 prev;               // Prev non-zero bucket index
        uint256 next;               // Next non-zero bucket index
    }
    mapping(uint256 => Bucket) public buckets;
    uint256 bucketCount; // number of total buckets. used to track the last used index for the bucket

    // Map from owner address to array of bucket indexes.
    mapping(address => uint256[]) public stakeholders;

    /**
     * @dev Modifier that checks that this given bucket can be updated/deleted by msg.sender
     * @param _address address to transfer tokens from
     * @param _bucketIndex uint256 the index of the bucket
     */
    modifier canTouchBucket(address _address, uint256 _bucketIndex) {
        require(_address != address(0));
        require(buckets[_bucketIndex].bucketOwner == msg.sender, "sender is not the owner.");
        _;
    }

    /**
     * @dev Modifier that check if a duration meets requirement
     * @param _duration uint256 duration to check
     */
    modifier checkStakeDuration(uint256 _duration) {
        require(_duration >= minStakeDuration && _duration <= maxStakeDuration, "The stake duration is too small or large");
        require(_duration % 7 == 0, "The stake duration should be multiple of 7");
        _;
    }

    /**
     * @dev Constructor function
     * @param _stakingTokenAddr address The address of the token contract used for staking
     */
    constructor(address _stakingTokenAddr) public {
        stakingToken = ERC20(_stakingTokenAddr);
        // create one bucket to initialize the double linked list
        buckets[0] = Bucket("", 1, 0, block.timestamp, true, 0, msg.sender, block.timestamp, 0, 0);
        stakeholders[msg.sender].push(0);
        bucketCount = 1;
    }

    function getActiveBucketIdxImpl(uint256 _prevIndex, uint256 _limit) internal returns(uint256 count, uint256[] indexes) {
        require (_limit > 0 && _limit < 5000);
        Bucket memory bucket = buckets[_prevIndex];
        require(bucket.next > 0, "cannot find bucket based on input index.");

        indexes = new uint256[](_limit);
        uint256 i = 0;
        for (i = 0; i < _limit; i++) {
            while (bucket.next > 0 && buckets[bucket.next].unstakeStartTime > 0) { // unstaked.
                bucket = buckets[bucket.next]; // skip
            }
            if (bucket.next == 0) { // no new bucket
                break;
            }
            indexes[i] = bucket.next;
            bucket = buckets[bucket.next];
        }
        return (i, indexes);
    }

    function getActiveBucketIdx(uint256 _prevIndex, uint256 _limit) external view returns(uint256 count, uint256[] indexes) {
        return getActiveBucketIdxImpl(_prevIndex, _limit);
    }

    /**
     * @dev Get active buckets for a range of indexes
     * @param _prevIndex uint256 the starting index. starting from 0, ending at the last. (putting 0,2 will return 1,2.)
     * @param _limit uint256 the number of non zero buckets to fetch after the start index
     * @return (uint256, uint256[], uint256[], uint256[], uint256[], bytes, address[])
     *  count, index array, stakeStartTime array, duration array, decay array, stakedAmount array, concat stakedFor, ownerAddress array
     */
    function getActiveBuckets(uint256 _prevIndex, uint256 _limit) external view returns(uint256 count,
            uint256[] indexes, uint256[] stakeStartTimes, uint256[] stakeDurations, bool[] decays, uint256[] stakedAmounts, bytes12[] canNames, address[] owners) {

        (count, indexes) = getActiveBucketIdxImpl(_prevIndex, _limit);
        stakeStartTimes = new uint256[](count);
        stakeDurations = new uint256[](count);
        decays = new bool[](count);
        stakedAmounts = new uint256[](count);
        canNames = new bytes12[](count);
        owners = new address[](count);

        for (uint256 i = 0; i < count; i++) {
            Bucket memory bucket = buckets[indexes[i]];
            stakeStartTimes[i] = bucket.stakeStartTime;
            stakeDurations[i] = bucket.stakeDuration;
            decays[i] = !bucket.nonDecay;
            stakedAmounts[i] = bucket.stakedAmount;
            canNames[i] = bucket.canName;
            owners[i] = bucket.bucketOwner;

        }

        return (count, indexes, stakeStartTimes, stakeDurations, decays, stakedAmounts, canNames, owners);
    }


    function getActiveBucketCreateTimes(uint256 _prevIndex, uint256 _limit) external view returns(uint256 count,
            uint256[] indexes, uint256[] createTimes) {
        (count, indexes) = getActiveBucketIdxImpl(_prevIndex, _limit);
        createTimes = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            createTimes[i] = buckets[indexes[i]].createTime;
        }
        return (count, indexes, createTimes);
    }

    /**
     * @dev Get bucket indexes from a given address
     * @param _owner address onwer of the buckets
     * @return (uint256[])
     */
    function getBucketIndexesByAddress(address _owner) external view returns(uint256[]) {
        return stakeholders[_owner];
    }

    /**
     * @notice Extend the stake to stakeDuration from current time and/or set nonDecay.
     * @notice MUST trigger BucketUpdated event
     * @param _bucketIndex uint256 the index of the bucket
     * @param _stakeDuration uint256 the desired duration of staking.
     * @param _nonDecay bool if auto restake
     * @param _data bytes optional data to include in the emitted event
     */
    function restake(uint256 _bucketIndex, uint256 _stakeDuration, bool _nonDecay, bytes _data)
            external whenNotPaused canTouchBucket(msg.sender, _bucketIndex) checkStakeDuration(_stakeDuration) {
        require(block.timestamp.add(_stakeDuration * secondsPerEpoch) >=
                buckets[_bucketIndex].stakeStartTime.add(buckets[_bucketIndex].stakeDuration * secondsPerEpoch),
                "current stake duration not finished.");
        if (buckets[_bucketIndex].nonDecay) {
          require(_stakeDuration >= buckets[_bucketIndex].stakeDuration, "cannot reduce the stake duration.");
        }
        buckets[_bucketIndex].stakeDuration = _stakeDuration;
        buckets[_bucketIndex].stakeStartTime = block.timestamp;
        buckets[_bucketIndex].nonDecay = _nonDecay;
        buckets[_bucketIndex].unstakeStartTime = 0;
        emitBucketUpdated(_bucketIndex, _data);
    }

    /*
     * @notice Vote for another candidate with the tokens that are already staked in the given bucket
     * @notice MUST trigger BucketUpdated event
     * @param _bucketIndex uint256 the index of the bucket
     * @param canName bytes the IoTeX address of the candidate the tokens are staked for
     * @param _data bytes optional data to include in the emitted event
     */
    function revote(uint256 _bucketIndex, bytes12 _canName, bytes _data)
            external whenNotPaused canTouchBucket(msg.sender, _bucketIndex) {
        require(buckets[_bucketIndex].unstakeStartTime == 0, "cannot revote during unstaking.");
        buckets[_bucketIndex].canName = _canName;
        emitBucketUpdated(_bucketIndex, _data);
    }

    /*
     * @notice Set the new owner of a given bucket, the sender must be whitelisted to do so to avoid spam
     * @notice MUST trigger BucketUpdated event
     * @param _name bytes12 the name of the candidate the tokens are staked for
     * @param _bucketIndex uint256 optional data to include in the Stake event
     * @param _data bytes optional data to include in the emitted event
     */
    function setBucketOwner(uint256 _bucketIndex, address _newOwner, bytes _data)
            external whenNotPaused onlyWhitelisted canTouchBucket(msg.sender, _bucketIndex) {
        removeBucketIndex(_bucketIndex);
        buckets[_bucketIndex].bucketOwner = _newOwner;
        stakeholders[_newOwner].push(_bucketIndex);
        // TODO split event.
        emitBucketUpdated(_bucketIndex, _data);
    }

    /**
     * @notice Unstake a certain amount of tokens from a given bucket.
     * @notice MUST trigger BucketUnstake event
     * @param _bucketIndex uint256 the index of the bucket
     * @param _data bytes optional data to include in the emitted event
     */
    function unstake(uint256 _bucketIndex, bytes _data)
            external whenNotPaused canTouchBucket(msg.sender, _bucketIndex) {
        require(_bucketIndex > 0, "bucket 0 cannot be unstaked and withdrawn.");
        require(!buckets[_bucketIndex].nonDecay, "Cannot unstake with nonDecay flag. Need to disable non-decay mode first.");
        require(buckets[_bucketIndex].stakeStartTime.add(buckets[_bucketIndex].stakeDuration * secondsPerEpoch) <= block.timestamp,
            "Staking time does not expire yet. Please wait until staking expires.");
        require(buckets[_bucketIndex].unstakeStartTime == 0, "Unstaked already. No need to unstake again.");
        buckets[_bucketIndex].unstakeStartTime = block.timestamp;
        emit BucketUnstake(_bucketIndex, buckets[_bucketIndex].canName, buckets[_bucketIndex].stakedAmount, _data);
    }

    /**
     * @notice this SHOULD return the given amount of tokens to the user, if unstaking is currently not possible the function MUST revert
     * @notice MUST trigger BucketWithdraw event
     * @param _bucketIndex uint256 the index of the bucket
     * @param _data bytes optional data to include in the emitted event
     */
    function withdraw(uint256 _bucketIndex, bytes _data)
            external whenNotPaused canTouchBucket(msg.sender, _bucketIndex) {
        require(buckets[_bucketIndex].unstakeStartTime > 0, "Please unstake first before withdraw.");
        require(
            buckets[_bucketIndex].unstakeStartTime.add(unStakeDuration * secondsPerEpoch) <= block.timestamp,
            "Stakeholder needs to wait for 3 days before withdrawing tokens.");

        // fix double linked list
        uint256 prev = buckets[_bucketIndex].prev;
        uint256 next = buckets[_bucketIndex].next;
        buckets[prev].next = next;
        buckets[next].prev = prev;

        uint256 amount = buckets[_bucketIndex].stakedAmount;
        bytes12 canName = buckets[_bucketIndex].canName;
        address bucketowner = buckets[_bucketIndex].bucketOwner;
        buckets[_bucketIndex].stakedAmount = 0;
        removeBucketIndex(_bucketIndex);
        delete buckets[_bucketIndex];

        require(stakingToken.transfer(bucketowner, amount), "Unable to withdraw stake");
        emit BucketWithdraw(_bucketIndex, canName, amount, _data);
    }

    /**
     * @notice Returns the total of tokens staked from all addresses
     * @return uint256 The number of tokens staked from all addresses
     */
    function totalStaked() public view returns (uint256) {
        return stakingToken.balanceOf(this);
    }

    /**
     * @notice Address of the token being used by the staking interface
     * @return address The address of the ERC20 token used for staking
     */
    function token() public view returns(address) {
        return stakingToken;
    }

    /**
     * @notice Emit BucketUpdated event
     */
    function emitBucketUpdated(uint256 _bucketIndex, bytes _data) internal {
        Bucket memory b = buckets[_bucketIndex];
        emit BucketUpdated(_bucketIndex, b.canName, b.stakeDuration, b.stakeStartTime, b.nonDecay, b.bucketOwner, _data);
    }

    /**
     * @dev  Create a bucket and vote for a given canName.
     * @param _canName bytes The IoTeX address of the candidate the stake is being created for
     * @param _amount uint256 The duration to lock the tokens for
     * @param _stakeDuration bytes the desired duration of the staking
     * @param _nonDecay bool if auto restake
     * @param _data bytes optional data to include in the emitted event
     * @return uint236 the index of new bucket
     */
    function createBucket(bytes12 _canName, uint256 _amount, uint256 _stakeDuration, bool _nonDecay, bytes _data)
            external whenNotPaused checkStakeDuration(_stakeDuration) returns (uint256) {
        require(_amount >= minStakeAmount, "amount should >= 100.");
        require(stakeholders[msg.sender].length <= maxBucketsPerAddr, "One address can have up limited buckets");
        require(stakingToken.transferFrom(msg.sender, this, _amount), "Stake required"); // transfer token to contract
        // add a new bucket to the end of buckets array and fix the double linked list.
        buckets[bucketCount] = Bucket(_canName, _amount, _stakeDuration, block.timestamp, _nonDecay, 0, msg.sender, block.timestamp, buckets[0].prev, 0);
        buckets[buckets[0].prev].next = bucketCount;
        buckets[0].prev = bucketCount;
        stakeholders[msg.sender].push(bucketCount);
        bucketCount++;
        emit BucketCreated(bucketCount-1, _canName, _amount, _stakeDuration, _nonDecay, _data);
        return bucketCount-1;
    }

    /**
     * @dev Remove the bucket index from stakeholders map
     * @param _bucketidx uint256 the bucket index
     */
    function removeBucketIndex(uint256 _bucketidx) internal {
        address owner = buckets[_bucketidx].bucketOwner;
        require(stakeholders[owner].length > 0, "Expect the owner has at least one bucket index");

        uint256 i = 0;
        for (; i < stakeholders[owner].length; i++) {
          if(stakeholders[owner][i] == _bucketidx) {
                break;
          }
        }
        for (; i < stakeholders[owner].length - 1; i++) {
          stakeholders[owner][i] = stakeholders[owner][i + 1];
        }
        stakeholders[owner].length--;
    }
}