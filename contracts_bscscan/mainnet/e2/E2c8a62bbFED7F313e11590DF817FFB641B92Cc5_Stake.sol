/**
 *Submitted for verification at BscScan.com on 2021-10-04
*/

pragma solidity 0.6.12;

// SPDX-License-Identifier: BSD-3-Clause

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

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
 * As of v3.0.0, only sets of type `address` (`AddressSet`) and `uint256`
 * (`UintSet`) are supported.
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

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

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
    function _contains(Set storage set, bytes32 value)
        private
        view
        returns (bool)
    {
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
    function _at(Set storage set, uint256 index)
        private
        view
        returns (bytes32)
    {
        require(
            set._values.length > index,
            "EnumerableSet: index out of bounds"
        );
        return set._values[index];
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
    function add(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(uint256(value)));
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
    function at(AddressSet storage set, uint256 index)
        internal
        view
        returns (address)
    {
        return address(uint256(_at(set._inner, index)));
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
    function remove(UintSet storage set, uint256 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value)
        internal
        view
        returns (bool)
    {
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
    function at(UintSet storage set, uint256 index)
        internal
        view
        returns (uint256)
    {
        return uint256(_at(set._inner, index));
    }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

interface Token {
    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);

    function transfer(address, uint256) external returns (bool);
}

contract Stake {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    event RewardsTransferred(address holder, uint256 amount);

    address public operator;

    // deposit token contract address
    address public depositToken;

    // reward token contract address
    address public rewardToken;

    // reward rate in percentage per year
    uint256 public rewardRate;
    uint256 public rewardInterval;

    // Referral fee in percentage
    uint256 public referralFeeRate;

    uint256 public poolLimit;

    uint256 public poolLimitPerUser;

    uint256 public totalClaimedRewards = 0;

    uint256 public totalStaked = 0;

    uint256 public minAmount = 100 ether;

    uint256 public poolOpenTill;

    uint256 public poolExpiryTime;
    
    uint256 public cmnRate;

    uint256 private time = 365 days;

    EnumerableSet.AddressSet private holders;

    mapping(address => uint256) public depositedTokens;
    mapping(address => uint256) public stakingTime;
    mapping(address => uint256) public lastClaimedTime;
    mapping(address => uint256) public totalEarnedTokens;

    // referal
    struct referalStruct {
        address refferAddress;
        uint256 amount;
    }
    mapping(address => referalStruct[]) public referralAddresses; // get my referal
    mapping(address => uint256) public totalReferalAmount; // get my total referal amount
    mapping(address => address) public myReferralAddresses; // get my referal address that i refer
    mapping(address => bool) public alreadyReferral;
    mapping(address => uint256) public rewardRateForUser;
    mapping(address => uint256) public cmnStakePrice;

    constructor(
        address _depositTokens,
        address _rewardToken,
        uint256 _rewardRate,
        uint256 _rewardInterval,
        uint256 _poolOpenTill,
        uint256 _poolLimit,
        uint256 _poolLimitPerUser,
        uint256 _referralFeeRate,
        address _operator
    ) public {
        depositToken = _depositTokens;
        rewardToken = _rewardToken;
        rewardRate = _rewardRate;
        rewardInterval = _rewardInterval;
        poolOpenTill = now.add(_poolOpenTill);
        poolLimit = _poolLimit;
        poolLimitPerUser = _poolLimitPerUser;
        referralFeeRate = _referralFeeRate;
        operator = _operator;
        poolExpiryTime = now.add(_rewardInterval);
    }

    function setPoolOpenTime(uint256 _time) public {
        poolOpenTill = now.add(_time);
    }

    function setRewardRate(uint256 _rate) public {
        rewardRate = _rate;
    }

    function setPoolLimit(uint256 _amount) public {
        poolLimit = _amount;
    }

    function setPoolLimitperUser(uint256 _amount) public {
        poolLimitPerUser = _amount;
    }

    function setReferralFeeRate(uint256 _rate) public {
        referralFeeRate = _rate;
    }

    function setMinAmount(uint256 _amount) public {
        minAmount = _amount;
    }

    function setOperator(address _operator) public {
        require(msg.sender == operator, "Only operator");
        operator = _operator;
    }
    
    function setCMNPrice(uint _rate) public {
        require(msg.sender == operator, "Only operator");
        cmnRate = _rate;
    }

    function updateAccount(address account) private {
        uint256 pendingDivs = getPendingDivs(account);
        if (pendingDivs > 0) {
            require(
                Token(rewardToken).transfer(account, pendingDivs),
                "Could not transfer tokens."
            );
            totalEarnedTokens[account] = totalEarnedTokens[account].add(
                pendingDivs
            );
            totalClaimedRewards = totalClaimedRewards.add(pendingDivs);
            emit RewardsTransferred(account, pendingDivs);
        }
        lastClaimedTime[account] = now;
    }

    function getPendingDivs(address _holder) public view returns (uint256) {
        if (!holders.contains(_holder)) return 0;
        if (depositedTokens[_holder] == 0) return 0;

        // uint256 timeDiff = now.sub(lastClaimedTime[_holder]);
        uint256 timeDiff;
        now <= stakingTime[_holder].add(rewardInterval) ? timeDiff = now.sub(lastClaimedTime[_holder]) : timeDiff = stakingTime[_holder].add(rewardInterval).sub(lastClaimedTime[_holder]);
        uint256 stakedAmount = depositedTokens[_holder];

        uint256 pendingDivs = stakedAmount.mul(cmnStakePrice[_holder])
            .mul(rewardRateForUser[_holder])
            .mul(timeDiff)
            .div(time)
            .div(1e6);

        return pendingDivs;
    }

    function getNumberOfHolders() public view returns (uint256) {
        return holders.length();
    }

    function deposit(uint256 amountToStake) public {
        require(now <= poolExpiryTime, "Pool is expired");
        require(now <= poolOpenTill, "Pool is closed");
        require(amountToStake > 0, "Cannot deposit 0 Tokens");
        require(
            totalStaked.add(amountToStake) <= poolLimit,
            "Pool limit reached"
        );
        require(
            amountToStake >= minAmount,
            "Staking amount is less than min value"
        );
        require(
            Token(depositToken).transferFrom(
                msg.sender,
                address(this),
                amountToStake
            ),
            "Insufficient Token Allowance"
        );

        updateAccount(msg.sender);

        address myReferralAddredd = myReferralAddresses[msg.sender];

        if (
            amountToStake > 0 &&
            myReferralAddredd != address(0) &&
            myReferralAddredd != msg.sender
        ) {
            uint256 referralAmount = amountToStake.mul(cmnRate).mul(referralFeeRate).div(
                1e6
            );
            referralAddresses[myReferralAddredd].push(
                referalStruct({
                    refferAddress: msg.sender,
                    amount: referralAmount
                })
            );

            totalReferalAmount[myReferralAddredd] = totalReferalAmount[
                myReferralAddredd
            ].add(referralAmount);
            require(
                Token(rewardToken).transfer(myReferralAddredd, referralAmount),
                "Could not transfer referral amount"
            );
        }

        depositedTokens[msg.sender] = depositedTokens[msg.sender].add(
            amountToStake
        );

        totalStaked = totalStaked.add(amountToStake);
        cmnStakePrice[msg.sender] = cmnRate;

        if (!holders.contains(msg.sender)) {
            holders.add(msg.sender);
            stakingTime[msg.sender] = now;
            rewardRateForUser[msg.sender] = rewardRate;
        }
    }

    function depositWithReferral(uint256 amountToStake, address referral)
        public
    {
        require(now <= poolExpiryTime, "Pool is expired");
        require(now <= poolOpenTill, "Pool is closed");
        require(amountToStake > 0, "Cannot deposit 0 Tokens");
        require(
            totalStaked.add(amountToStake) <= poolLimit,
            "Pool limit reached"
        );
        require(depositedTokens[msg.sender] == 0, "Invalid Contract Call");
        require(
            amountToStake >= minAmount,
            "Staking amount is less than min value"
        );
        require(
            !alreadyReferral[msg.sender],
            "You can't use refer program multiple times"
        );
        require(
            Token(depositToken).transferFrom(
                msg.sender,
                address(this),
                amountToStake
            ),
            "Insufficient Token Allowance"
        );

        updateAccount(msg.sender);

        if (
            amountToStake > 0 &&
            referral != address(0) &&
            referral != msg.sender
        ) {
            alreadyReferral[msg.sender] = true;
            myReferralAddresses[msg.sender] = referral;
            uint256 referralAmount = amountToStake.mul(cmnRate).mul(referralFeeRate).div(
                1e6
            );
            referralAddresses[referral].push(
                referalStruct({
                    refferAddress: msg.sender,
                    amount: referralAmount
                })
            );
            totalReferalAmount[referral] = totalReferalAmount[referral].add(
                referralAmount
            );
            require(
                Token(rewardToken).transfer(referral, referralAmount),
                "Could not transfer referral amount"
            );
        }

        depositedTokens[msg.sender] = depositedTokens[msg.sender].add(
            amountToStake
        );

        totalStaked = totalStaked.add(amountToStake);
        cmnStakePrice[msg.sender] = cmnRate;

        if (!holders.contains(msg.sender)) {
            holders.add(msg.sender);
            stakingTime[msg.sender] = now;
            rewardRateForUser[msg.sender] = rewardRate;
        }
    }

    function withdraw(uint256 amountToWithdraw) public {
        require(
            depositedTokens[msg.sender] >= amountToWithdraw,
            "Invalid amount to withdraw"
        );

        require(
            now.sub(stakingTime[msg.sender]) > rewardInterval,
            "You recently staked, please wait before withdrawing."
        );

        updateAccount(msg.sender);

        require(
            Token(depositToken).transfer(msg.sender, amountToWithdraw),
            "Could not transfer tokens."
        );

        depositedTokens[msg.sender] = depositedTokens[msg.sender].sub(
            amountToWithdraw
        );

        if (holders.contains(msg.sender) && depositedTokens[msg.sender] == 0) {
            holders.remove(msg.sender);
        }
    }

    function claimDivs() public {
        updateAccount(msg.sender);
    }

    function getStakersList(uint256 startIndex, uint256 endIndex)
        public
        view
        returns (
            address[] memory stakers,
            uint256[] memory stakingTimestamps,
            uint256[] memory lastClaimedTimeStamps,
            uint256[] memory stakedTokens
        )
    {
        require(startIndex < endIndex);

        uint256 length = endIndex.sub(startIndex);
        address[] memory _stakers = new address[](length);
        uint256[] memory _stakingTimestamps = new uint256[](length);
        uint256[] memory _lastClaimedTimeStamps = new uint256[](length);
        uint256[] memory _stakedTokens = new uint256[](length);

        for (uint256 i = startIndex; i < endIndex; i = i.add(1)) {
            address staker = holders.at(i);
            uint256 listIndex = i.sub(startIndex);
            _stakers[listIndex] = staker;
            _stakingTimestamps[listIndex] = stakingTime[staker];
            _lastClaimedTimeStamps[listIndex] = lastClaimedTime[staker];
            _stakedTokens[listIndex] = depositedTokens[staker];
        }

        return (
            _stakers,
            _stakingTimestamps,
            _lastClaimedTimeStamps,
            _stakedTokens
        );
    }

    uint256 private constant stakingAndDaoTokens = 5129e18;

    function getStakingAndDaoAmount() public view returns (uint256) {
        if (totalClaimedRewards >= stakingAndDaoTokens) {
            return 0;
        }
        uint256 remaining = stakingAndDaoTokens.sub(totalClaimedRewards);
        return remaining;
    }

    // function to allow admin to claim *other* ERC20 tokens sent to this contract (by mistake)
    function transferAnyERC20Tokens(
        address _tokenAddr,
        address _to,
        uint256 _amount
    ) public {
        require(msg.sender == operator, "Only operator");
        require(
            _tokenAddr != depositToken,
            "Cannot Transfer Out Deposit Token!"
        );
        Token(_tokenAddr).transfer(_to, _amount);
    }

    function getUserReferalCount(address _address)
        public
        view
        returns (uint256)
    {
        return referralAddresses[_address].length;
    }
}