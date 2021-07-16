//SourceUnit: EnumerableSet.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.8;

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
}


//SourceUnit: ITRC20.sol

pragma solidity ^0.5.8;

/**
 * @title TRC20 interface
 */
interface ITRC20 {
    function transfer(address to, uint256 value)
        external
        payable
        returns (bool);

    function approve(address spender, uint256 value)
        external
        payable
        returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external payable returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}


//SourceUnit: OPPO.sol

pragma solidity ^0.5.8;

import "./SafeMath.sol";
import "./Pausable.sol";
import "./EnumerableSet.sol";
import "./ITRC20.sol";
import "./ReentrancyGuard.sol";

/**
 * @title Standard TRC20 token
 *
 * @dev Implementation of the basic standard token.
 *
 * This implementation emits additional Approval events, allowing applications to reconstruct the allowance status for
 * all accounts just by listening to said events. Note that this isn't required by the specification, and other
 * compliant implementations may not do it.
 */
contract OPPO is ITRC20, Pausable, ReentrancyGuard {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    // Stores holders' balance.
    mapping(address => uint256) internal _balances;
    // Stores holders' address for iterating.
    EnumerableSet.AddressSet internal _addressSet;
    // Stores black reward address.
    // Address in it will not receive fomo reward, dividend reward, referer reward.
    EnumerableSet.AddressSet internal _blackRewardAddressSet;
    mapping(address => mapping(address => uint256)) internal _allowed;
    // Stores referer of address.
    // Eg., _refererMap[a1] = a2 means a2 refers a1. If a2 is address(0), it means no one.
    mapping(address => address) internal _refererMap;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Rebase(uint256 mulTimes);
    event RefererSet(address indexed referer, address indexed source);
    event RefererReward(
        address indexed referer,
        address indexed source,
        uint256 value
    );
    event FomoEvent(
        string eventType,
        uint256 fomoEpoch,
        uint256 blockNumber,
        uint256 fomoStartTimestamp,
        uint256 lastfomoEpochEndTimestamp,
        uint256 lastEpochReward,
        address[10] lastRewardAddressArray
    );

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;

    // Fomo epoch.
    uint256 private _fomoEpoch = 0;
    // Whether fomo has started.
    bool private _fomoStartedSign = false;
    // Timestamp at which the current epoch started. Unixtime in second.
    uint256 private _fomoEpochStartTimestamp;
    // Duration of a fomo epoch, in second.
    uint256 private _fomoEpochDuration = 600;
    // Timestamp at which the current epoch will end prossibly. Unixtime in second.
    uint256 private _fomoEpochEndTimestamp;
    // Reward of epoch.
    uint256 private _fomoEpochReward = 0;
    // Transaction with value >= `_fomoTransactionValueFloor` will be fomo tx.
    uint256 private _fomoTransactionValueFloor;
    // Add time per transaction, in second.
    uint256 private _fomoAddTimePerTransaction = 10;
    // Store 10 fomo reward addresses.
    address[10] private _fomoRewardAddressArray;
    // The next position of _fomoRewardAddressArray to store the last reward address.
    uint256 private _fomoRewardAddressArrayPosition;

    // Fomo Reward Pool address.
    address private _rewardPool;
    // Dividend Pool address.
    address private _dividendPool;
    // Referer Pool address.
    address private _refererPool;
    // Team Reward receiver.
    address private _teamRewardReceiver;
    // Team default referer.
    address private _teamDefaultReferer;
    // Reward rate in permillage for big one.
    uint256 private _bigOneRewardRate;
    // Reward rate in permillage for small nine.
    uint256 private _smallNineRewardRate;
    // Reward rate in permillage for team.
    uint256 private _teamRewardRate;
    // Reward rate of transaction value referers will receive totally.
    uint256 private _refererRewardRateOfValue;
    // Reward rate for self with common referer.
    uint256 private _refererRewardRateForSelf;
    // Reward rate in permillage for first class referer.
    uint256 private _referer1RewardRate;
    // Referer receives first class reward only when his balance is not smaller than _referer1RewardBalanceFloor.
    uint256 private _referer1RewardBalanceFloor;
    // Reward rate in permillage for second class referer.
    uint256 private _referer2RewardRate;
    // Referer receives first class reward only when his balance is not smaller than _referer2RewardBalanceFloor.
    uint256 private _referer2RewardBalanceFloor;
    // Reward rate in permillage for third class referer.
    uint256 private _referer3RewardRate;
    // Referer receives first class reward only when his balance is not smaller than _referer3RewardBalanceFloor.
    uint256 private _referer3RewardBalanceFloor;
    // Reward rate in permillage for forth class referer.
    uint256 private _referer4RewardRate;
    // Referer receives first class reward only when his balance is not smaller than _referer4RewardBalanceFloor.
    uint256 private _referer4RewardBalanceFloor;
    // Reward rate in permillage for fifth class referer.
    uint256 private _referer5RewardRate;
    // Referer receives first class reward only when his balance is not smaller than _referer5RewardBalanceFloor.
    uint256 private _referer5RewardBalanceFloor;

    /***********************************|
    |            Constructor            |
    |__________________________________*/

    /**
     * @dev Contract constructor function.
     */
    constructor(
        string memory name,
        string memory symbol,
        address teamDefaultReferer
    ) public {
        _name = name;
        _symbol = symbol;
        _decimals = 6;

        _rewardPool = address(1);
        _dividendPool = address(2);
        _refererPool = address(3);
        _addressSet.add(_rewardPool);
        _addressSet.add(_dividendPool);
        _addressSet.add(_refererPool);
        _blackRewardAddressSet.add(_rewardPool);
        _blackRewardAddressSet.add(_dividendPool);
        _blackRewardAddressSet.add(_refererPool);

        _fomoTransactionValueFloor = 50000 * 10**6;

        // 45%
        _bigOneRewardRate = 450;
        // 2%
        _smallNineRewardRate = 20;
        // 5%
        _teamRewardRate = 50;
        // 2%
        _refererRewardRateOfValue = 20;
        // 0.5%
        _refererRewardRateForSelf = 5;
        // 67%
        _referer1RewardRate = 670;
        _referer1RewardBalanceFloor = 100000 * 10**6;
        // 22%
        _referer2RewardRate = 220;
        _referer2RewardBalanceFloor = 200000 * 10**6;
        // 7%
        _referer3RewardRate = 70;
        _referer3RewardBalanceFloor = 300000 * 10**6;
        // 3%
        _referer4RewardRate = 30;
        _referer4RewardBalanceFloor = 400000 * 10**6;
        // 1%
        _referer5RewardRate = 10;
        _referer5RewardBalanceFloor = 500000 * 10**6;

        SocratesAddress = msg.sender;
        PlatoAddress = msg.sender;
        AristotleAddress = msg.sender;
        _teamRewardReceiver = msg.sender;
        _teamDefaultReferer = teamDefaultReferer;

        // Mint 810 Million tokens to SocratesAddress.
        _mint(SocratesAddress, 81 * 10**7 * 10**6);
        // Mint 190 Million tokens to _refererPool.
        _mint(_refererPool, 19 * 10**7 * 10**6);

        _resetFomoRewardAddressArray();
    }

    /***********************************|
    |               Functions           |
    |__________________________________*/

    /**
     * @dev Fallback function.
     */
    function() external payable {}

    /**
     * @dev Total number of tokens in existence
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Whether `addr` is in reward black list.
     */
    function blackRewardAddressIn(address addr) public view returns (bool) {
        return _blackRewardAddressSet.contains(addr);
    }

    /**
     * @dev Remove an address `addr` from reward black list.
     */

    function blackRewardAddressRemove(address addr) public onlyCLevel {
        _blackRewardAddressSet.remove(addr);
    }

    /**
     * @dev Add an address `addr` into reward black list.
     */
    function blackRewardAddressAdd(address addr) public onlyCLevel {
        _blackRewardAddressSet.add(addr);
    }

    /**
     * @dev Get reward pool address.
     */
    function getRewardPool() public view returns (address) {
        return _rewardPool;
    }

    /**
     * @dev Get dividend pool address.
     */
    function getDividendPool() public view returns (address) {
        return _dividendPool;
    }

    /**
     * @dev Get referer pool address.
     */
    function getRefererPool() public view returns (address) {
        return _refererPool;
    }

    /**
     * @dev Get the big one reward rate in permillage.
     */
    function getBigOneRewardRate() public view returns (uint256) {
        return _bigOneRewardRate;
    }

    /**
     * @dev Set the big one reward rate in permillage.
     */
    function setBigOneRewardRate(uint256 r) public onlyCLevel {
        _bigOneRewardRate = r;
    }

    function getSmallNineRewardRate() public view returns (uint256) {
        return _smallNineRewardRate;
    }

    function setSmallNineRewardRate(uint256 r) public onlyCLevel {
        _smallNineRewardRate = r;
    }

    function getTeamRewardRate() public view returns (uint256) {
        return _teamRewardRate;
    }

    function setTeamRewardRate(uint256 r) public onlyCLevel {
        _teamRewardRate = r;
    }

    function getReferer1RewardRate() public view returns (uint256) {
        return _referer1RewardRate;
    }

    function setReferer1RewardRate(uint256 r) public onlyCLevel {
        _referer1RewardRate = r;
    }

    function getReferer2RewardRate() public view returns (uint256) {
        return _referer2RewardRate;
    }

    function setReferer2RewardRate(uint256 r) public onlyCLevel {
        _referer2RewardRate = r;
    }

    function getReferer3RewardRate() public view returns (uint256) {
        return _referer3RewardRate;
    }

    function setReferer3RewardRate(uint256 r) public onlyCLevel {
        _referer3RewardRate = r;
    }

    function getReferer4RewardRate() public view returns (uint256) {
        return _referer4RewardRate;
    }

    function setReferer4RewardRate(uint256 r) public onlyCLevel {
        _referer4RewardRate = r;
    }

    function getReferer5RewardRate() public view returns (uint256) {
        return _referer5RewardRate;
    }

    function setReferer5RewardRate(uint256 r) public onlyCLevel {
        _referer5RewardRate = r;
    }

    function getReferer1RewardBalanceFloor() public view returns (uint256) {
        return _referer1RewardBalanceFloor;
    }

    function setReferer1RewardBalanceFloor(uint256 r) public onlyCLevel {
        _referer1RewardBalanceFloor = r;
    }

    function getReferer2RewardBalanceFloor() public view returns (uint256) {
        return _referer2RewardBalanceFloor;
    }

    function setReferer2RewardBalanceFloor(uint256 r) public onlyCLevel {
        _referer2RewardBalanceFloor = r;
    }

    function getReferer3RewardBalanceFloor() public view returns (uint256) {
        return _referer3RewardBalanceFloor;
    }

    function setReferer3RewardBalanceFloor(uint256 r) public onlyCLevel {
        _referer3RewardBalanceFloor = r;
    }

    function getReferer4RewardBalanceFloor() public view returns (uint256) {
        return _referer4RewardBalanceFloor;
    }

    function setReferer4RewardBalanceFloor(uint256 r) public onlyCLevel {
        _referer4RewardBalanceFloor = r;
    }

    function getReferer5RewardBalanceFloor() public view returns (uint256) {
        return _referer5RewardBalanceFloor;
    }

    function setReferer5RewardBalanceFloor(uint256 r) public onlyCLevel {
        _referer5RewardBalanceFloor = r;
    }

    function getRefererRewardRateOfValue() public view returns (uint256) {
        return _refererRewardRateOfValue;
    }

    function setRefererRewardRateOfValue(uint256 r) public onlyCLevel {
        _refererRewardRateOfValue = r;
    }

    function getRefererRewardRateForSelf() public view returns (uint256) {
        return _refererRewardRateForSelf;
    }

    function setRefererRewardRateForSelf(uint256 r) public onlyCLevel {
        _refererRewardRateForSelf = r;
    }

    function getTeamRewardReceiver() public view returns (address) {
        return _teamRewardReceiver;
    }

    function setTeamRewardReceiver(address addr) public onlyCLevel {
        _teamRewardReceiver = addr;
    }

    function getTeamDefaultReferer() public view returns (address) {
        return _teamDefaultReferer;
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param owner The address to query the balance of.
     * @return A uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address owner, address spender)
        public
        view
        returns (uint256)
    {
        return _allowed[owner][spender];
    }

    /**
     * @dev Transfer token to a specified address
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function transfer(address to, uint256 value)
        public
        payable
        whenNotPaused
        returns (bool)
    {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferWithoutBurn(address to, uint256 value)
        public
        payable
        onlyCLevel
        whenNotPaused
        returns (bool)
    {
        _transferWithoutBurn(msg.sender, to, value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value)
        public
        payable
        whenNotPaused
        returns (bool)
    {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another.
     * Note that while this function emits an Approval event, this is not required as per the specification,
     * and other compliant implementations may not emit the event.
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public payable whenNotPaused returns (bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when _allowed[msg.sender][spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        whenNotPaused
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowed[msg.sender][spender].add(addedValue)
        );
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when _allowed[msg.sender][spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        whenNotPaused
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowed[msg.sender][spender].sub(subtractedValue)
        );
        return true;
    }

    /**
     * @dev Transfer token for a specified addresses with burn
     * @param from The address to transfer from.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal {
        require(to != address(0));

        // Set default referer as `_teamDefaultReferer`.
        _setReferer(to, _teamDefaultReferer);
        // Add `to` to _addressSet
        _addressSet.add(to);

        // Last epoch ends, i.e. new epoch starts.
        if (_fomoStartedSign && _fomoEpochEndTimestamp <= block.timestamp) {
            address[10] memory tmpArray;
            for (uint256 i = 0; i < 10; i++) {
                uint256 j = (_fomoRewardAddressArrayPosition + 9 - i) % 10;
                tmpArray[i] = _fomoRewardAddressArray[j];
            }
            emit FomoEvent(
                "start",
                _fomoEpoch + 1,
                block.number,
                block.timestamp,
                _fomoEpochEndTimestamp,
                _fomoEpochReward,
                tmpArray
            );
            _fomoEpoch = _fomoEpoch + 1;
            _fomoEpochStartTimestamp = block.timestamp;
            _fomoEpochEndTimestamp = _fomoEpochStartTimestamp.add(
                _fomoEpochDuration
            );
            _fomoEpochReward = 0;
            _resetFomoRewardAddressArray();
        }

        // transfer from `from` to `to` with qty of `value`
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);

        // transfer from `to` to reward pool with qty of `burnQty`
        uint256 _burnRate = getBurnRate();
        uint256 burnQty = value.mul(_burnRate).div(1000);
        _balances[to] = _balances[to].sub(burnQty);
        _balances[_rewardPool] = _balances[_rewardPool].add(burnQty);
        emit Transfer(to, _rewardPool, burnQty);

        // burn from `to` with qty of `burnQty`
        _burn(to, burnQty);

        // distribute reward to referers.
        _distributeRewardToReferers(
            to,
            value.mul(_refererRewardRateOfValue).div(1000)
        );

        // address with common referer and not in black list will get reward.
        if (
            _refererMap[to] != _teamDefaultReferer &&
            _refererMap[to] != address(0) &&
            !_blackRewardAddressSet.contains(to)
        ) {
            uint256 m = value.mul(_refererRewardRateForSelf).div(1000);
            _transferWithoutBurn(_refererPool, to, m);
            emit RefererReward(to, to, m);
        }

        // Cumulate reward
        _fomoEpochReward = _fomoEpochReward.add(burnQty);
        // This is a fomo tx
        if (_fomoStartedSign && value >= _fomoTransactionValueFloor) {
            _fomoEpochEndTimestamp = _fomoEpochEndTimestamp.add(
                _fomoAddTimePerTransaction
            );
            // `to` not in blacklist, added to reward array.
            if (!_blackRewardAddressSet.contains(to)) {
                _fomoRewardAddressArray[_fomoRewardAddressArrayPosition] = to;
                _fomoRewardAddressArrayPosition =
                    (_fomoRewardAddressArrayPosition + 1) %
                    10;
            }
        }
    }

    /**
     * @dev Distribute reward to referers, at most five class.
     * @param source Source address.
     * @param rewardQty Total reward quantity.
     */
    function _distributeRewardToReferers(address source, uint256 rewardQty)
        internal
    {
        // If there is not enough tokens in referer pool, don't distribute.
        if (_balances[_refererPool] < rewardQty) {
            return;
        }

        uint256 value = 0;
        address r = _refererMap[source];
        if (r != address(0)) {
            if (
                _balances[r] >= _referer1RewardBalanceFloor &&
                !_blackRewardAddressSet.contains(r)
            ) {
                value = rewardQty.mul(_referer1RewardRate).div(1000);
                _transferWithoutBurn(_refererPool, r, value);
                emit RefererReward(r, source, value);
            }
        } else {
            return;
        }

        r = _refererMap[r];
        if (r != address(0)) {
            if (
                _balances[r] >= _referer2RewardBalanceFloor &&
                !_blackRewardAddressSet.contains(r)
            ) {
                value = rewardQty.mul(_referer2RewardRate).div(1000);
                _transferWithoutBurn(_refererPool, r, value);
                emit RefererReward(r, source, value);
            }
        } else {
            return;
        }

        r = _refererMap[r];
        if (r != address(0)) {
            if (
                _balances[r] >= _referer3RewardBalanceFloor &&
                !_blackRewardAddressSet.contains(r)
            ) {
                value = rewardQty.mul(_referer3RewardRate).div(1000);
                _transferWithoutBurn(_refererPool, r, value);
                emit RefererReward(r, source, value);
            }
        } else {
            return;
        }

        r = _refererMap[r];
        if (r != address(0)) {
            if (
                _balances[r] >= _referer4RewardBalanceFloor &&
                !_blackRewardAddressSet.contains(r)
            ) {
                value = rewardQty.mul(_referer4RewardRate).div(1000);
                _transferWithoutBurn(_refererPool, r, value);
                emit RefererReward(r, source, value);
            }
        } else {
            return;
        }

        r = _refererMap[r];
        if (r != address(0)) {
            if (
                _balances[r] >= _referer5RewardBalanceFloor &&
                !_blackRewardAddressSet.contains(r)
            ) {
                value = rewardQty.mul(_referer5RewardRate).div(1000);
                _transferWithoutBurn(_refererPool, r, value);
                emit RefererReward(r, source, value);
            }
        }
    }

    /**
     * @dev Transfer token for a specified addresses without burn and reward.
     * @param from The address to transfer from.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function _transferWithoutBurn(
        address from,
        address to,
        uint256 value
    ) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);

        // Add `to` to _addressSet
        _addressSet.add(to);
    }

    /**
     * @dev Internal function that mints an amount of the token and assigns it to
     * an account. This encapsulates the modification of balances such that the
     * proper events are emitted.
     * @param account The account that will receive the created tokens.
     * @param value The amount that will be created.
     */
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);

        // Add `account` to _addressSet
        _addressSet.add(account);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account.
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    /**
     * @dev Approve an address to spend another addresses' tokens.
     * @param owner The address that owns the tokens.
     * @param spender The address that will spend the tokens.
     * @param value The number of tokens that can be spent.
     */
    function _approve(
        address owner,
        address spender,
        uint256 value
    ) internal {
        require(spender != address(0));
        require(owner != address(0));

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account, deducting from the sender's allowance for said account. Uses the
     * internal burn function.
     * Emits an Approval event (reflecting the reduced allowance).
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burnFrom(address account, uint256 value) internal {
        _burn(account, value);
        _approve(account, msg.sender, _allowed[account][msg.sender].sub(value));
    }

    /**
     * @dev Get Burn rate of permillage. Eg., 60 represents 0.06.
     */
    function getBurnRate() public view returns (uint256) {
        if (_totalSupply >= 10**9 * 10**6) {
            return 60;
        } else if (_totalSupply >= 8 * 10**8 * 10**6) {
            return 50;
        } else if (_totalSupply >= 6 * 10**8 * 10**6) {
            return 40;
        } else if (_totalSupply >= 4 * 10**8 * 10**6) {
            return 30;
        } else if (_totalSupply >= 2 * 10**8 * 10**6) {
            return 20;
        } else if (_totalSupply >= 1 * 10**8 * 10**6) {
            return 10;
        } else {
            return 0;
        }
    }

    /**
     * @dev Rebase balance of all holders with multiplier `mulTimes`.
     */
    function rebase(uint256 mulTimes)
        public
        payable
        nonReentrant
        onlyCLevel
        whenPaused
        returns (bool)
    {
        if (mulTimes == 0) {
            return true;
        }

        for (uint256 i = 0; i < _addressSet.length(); i++) {
            address addr = _addressSet.at(i);
            uint256 nv = _balances[addr].mul(mulTimes - 1);
            _mint(addr, nv);
        }

        emit Rebase(mulTimes);

        return true;
    }

    /**
     * @dev Distribute reward.
     * If any address is contained in black reward list, the function will throw error.
     * @param rewardQty Quantity of total reward.
     * @param bigOne represents the last address of current round.
     * @param smallNine represents the nine next-last address of current round.
     */
    function distributeReward(
        uint256 rewardQty,
        address bigOne,
        address[] memory smallNine
    ) public payable nonReentrant onlyCLevel returns (bool) {
        require(
            _balances[_rewardPool] >= rewardQty,
            "Balance in reward pool is not enough."
        );
        require(bigOne != address(0));
        require(
            !_blackRewardAddressSet.contains(bigOne),
            "Address in black list"
        );
        require(smallNine.length <= 9);
        for (uint256 i = 0; i < smallNine.length; i++) {
            require(
                !_blackRewardAddressSet.contains(smallNine[i]),
                "Address in black list"
            );
        }

        uint256 rewardSent = 0;

        // The big one gets `_bigOneRewardRate`.
        uint256 value = rewardQty.mul(_bigOneRewardRate).div(1000);
        _transferWithoutBurn(_rewardPool, bigOne, value);
        rewardSent = rewardSent.add(value);

        // Each of small nine gets `_smallNineRewardRate`.
        value = rewardQty.mul(_smallNineRewardRate).div(1000);
        for (uint256 i = 0; i < smallNine.length; i++) {
            if (smallNine[i] != address(0)) {
                _transferWithoutBurn(_rewardPool, smallNine[i], value);
                rewardSent = rewardSent.add(value);
            }
        }

        // Team gets `_teamRewardRate`.
        value = rewardQty.mul(_teamRewardRate).div(1000);
        _transferWithoutBurn(_rewardPool, _teamRewardReceiver, value);
        rewardSent = rewardSent.add(value);

        // Holders get remaining reward.
        value = rewardQty.sub(rewardSent);
        _transferWithoutBurn(_rewardPool, _dividendPool, value);

        return true;
    }

    /**
     * @dev Distribute dividend to token holders. Holders share equally.
     * If any address is contained in black reward list, the function will throw error.
     */
    function distributeDividend(uint256 dividendQty, address[] memory holders)
        public
        payable
        nonReentrant
        onlyCLevel
        returns (bool)
    {
        require(
            _balances[_dividendPool] >= dividendQty &&
                dividendQty >= holders.length,
            "Balance in dividend pool is not enough"
        );
        require(
            holders.length > 0,
            "There are no holders to distribute dividend"
        );

        uint256 len = holders.length;
        uint256 value = dividendQty.div(len);
        uint256 rewardSent = 0;
        for (uint256 i = 0; i < len - 1; i++) {
            require(
                !_blackRewardAddressSet.contains(holders[i]),
                "Address in black list"
            );
            _transferWithoutBurn(_dividendPool, holders[i], value);
            rewardSent = rewardSent.add(value);
        }
        require(
            !_blackRewardAddressSet.contains(holders[len - 1]),
            "Address in black list"
        );
        _transferWithoutBurn(
            _dividendPool,
            holders[len - 1],
            dividendQty.sub(rewardSent)
        );

        return true;
    }

    /**
     * @dev Set referer for msg.sender. Referer of an address can't be modified when its referer isn't address(0).
     * Address(0) represents there is not referer for the current address.
     * @param referer Referer address.
     */
    function setReferer(address referer) public returns (bool) {
        _setReferer(msg.sender, referer);
        return true;
    }

    /**
     * @dev Internal function for setting referer.
     * @param source Source address.
     * @param referer Referer address.
     */
    function _setReferer(address source, address referer) internal {
        if (
            source != _teamDefaultReferer &&
            source != referer &&
            _refererMap[source] == address(0)
        ) {
            _refererMap[source] = referer;
            emit RefererSet(referer, source);
        }
    }

    /**
     * @dev Get five-class referers of `source`.
     * @param source Source address.
     * @return Address array in which the first element represent the first class referer, and so on.
     */
    function getReferer(address source) public view returns (address[] memory) {
        address[] memory arrs = new address[](5);
        for (uint256 i = 0; i < 5; i++) {
            address r = _refererMap[source];
            if (r != address(0)) {
                arrs[i] = r;
                source = r;
            } else {
                break;
            }
        }
        return arrs;
    }

    /**
     * @dev Get (address, balance) items whose balance >= `value`.
     * @param value The minimal amount.
     * @return Address array.
     * @return Corresponding balance array.
     */
    function getBalances(uint256 value)
        public
        view
        returns (address[] memory, uint256[] memory)
    {
        uint256 nc = 0;
        for (uint256 i = 0; i < _addressSet.length(); i++) {
            address addr = _addressSet.at(i);
            if (_balances[addr] >= value) {
                nc = nc + 1;
            }
        }

        address[] memory addrArray = new address[](nc);
        uint256[] memory valueArray = new uint256[](nc);
        uint256 nc2 = 0;
        for (uint256 i = 0; i < _addressSet.length(); i++) {
            address addr = _addressSet.at(i);
            if (_balances[addr] >= value && nc2 < nc) {
                addrArray[nc2] = addr;
                valueArray[nc2] = _balances[addr];
                nc2 = nc2 + 1;
            }
        }
        return (addrArray, valueArray);
    }

    /**
     * @dev Withdraw TRX from this contract to `to`.
     */
    function withdraw(address to, uint256 value)
        public
        onlyCLevel
        returns (bool)
    {
        require(to != address(0) && value >= 0);
        if (address(uint160(to)).send(value)) {
            emit Transfer(address(this), to, value);
            return true;
        }
        return false;
    }

    /***********************************|
    |            Fomo                   |
    |__________________________________*/

    /**
     * @dev Get info of the current epoch.
     * @return _fomoEpoch
     * @return _fomoEpochStartTimestamp
     * @return _fomoEpochEndTimestamp
     * @return _fomoEpochReward
     * @return _fomoRewardAddressArray
     */
    function getFomoEpochInfo()
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            address[10] memory
        )
    {
        address[10] memory tmpArray;
        for (uint256 i = 0; i < 10; i++) {
            uint256 j = (_fomoRewardAddressArrayPosition + 9 - i) % 10;
            tmpArray[i] = _fomoRewardAddressArray[j];
        }
        return (
            _fomoEpoch,
            _fomoEpochStartTimestamp,
            _fomoEpochEndTimestamp,
            _fomoEpochReward,
            tmpArray
        );
    }

    function getFomoAddTimePerTransaction() public view returns (uint256) {
        return _fomoAddTimePerTransaction;
    }

    function setFomoAddTimePerTransaction(uint256 d)
        public
        onlyCLevel
        returns (bool)
    {
        _fomoAddTimePerTransaction = d;
        return true;
    }

    function getFomoEpochDuration() public view returns (uint256) {
        return _fomoEpochDuration;
    }

    function setFomoEpochDuration(uint256 d) public onlyCLevel returns (bool) {
        _fomoEpochDuration = d;
        return true;
    }

    function getFomoTransactionValueFloor() public view returns (uint256) {
        return _fomoTransactionValueFloor;
    }

    function setFomoTransactionValueFloor(uint256 d)
        public
        onlyCLevel
        returns (bool)
    {
        _fomoTransactionValueFloor = d;
        return true;
    }

    /**
     * @dev Start fomo.
     */
    function fomoStart() public onlyCLevel returns (bool) {
        if (_fomoStartedSign) {
            return true;
        }
        _fomoStartedSign = true;
        _fomoEpochStartTimestamp = block.timestamp;
        _fomoEpochEndTimestamp = _fomoEpochStartTimestamp.add(
            _fomoEpochDuration
        );
        _fomoEpochReward = 0;
        _resetFomoRewardAddressArray();
        emit FomoEvent(
            "start",
            _fomoEpoch,
            block.number,
            _fomoEpochStartTimestamp,
            _fomoEpochEndTimestamp,
            _fomoEpochReward,
            _fomoRewardAddressArray
        );
        return true;
    }

    /**
     * @dev Stop fomo.
     */
    function fomoStop() public onlyCLevel returns (bool) {
        _fomoStartedSign = false;
        _fomoEpochStartTimestamp = 0;
        // 9999-12-31
        _fomoEpochEndTimestamp = 253402214400;
        _fomoEpochReward = 0;
        _resetFomoRewardAddressArray();
        emit FomoEvent(
            "stop",
            _fomoEpoch,
            block.number,
            _fomoEpochStartTimestamp,
            _fomoEpochEndTimestamp,
            _fomoEpochReward,
            _fomoRewardAddressArray
        );
        return true;
    }

    function _resetFomoRewardAddressArray() internal {
        _fomoRewardAddressArrayPosition = 0;
        for (uint256 i = 0; i < _fomoRewardAddressArray.length; i++) {
            _fomoRewardAddressArray[i] = address(0);
        }
    }
}


//SourceUnit: Pausable.sol

pragma solidity ^0.5.8;

contract Pausable {
    // The addresses of the accounts (or contracts) that can execute actions within each roles.
    address public SocratesAddress;
    address public PlatoAddress;
    address public AristotleAddress;

    // @dev Keeps track whether the contract is paused. When that is true, most actions are blocked
    bool public paused = false;

    modifier onlySocrates() {
        require(msg.sender == SocratesAddress);
        _;
    }

    modifier onlyPlato() {
        require(msg.sender == PlatoAddress);
        _;
    }

    modifier onlyAristotle() {
        require(msg.sender == AristotleAddress);
        _;
    }

    modifier onlyCLevel() {
        require(
            msg.sender == SocratesAddress ||
                msg.sender == PlatoAddress ||
                msg.sender == AristotleAddress
        );
        _;
    }

    function setSocrates(address _newOwner) external onlySocrates {
        require(_newOwner != address(0));

        SocratesAddress = _newOwner;
    }

    function setPlato(address _newOwner) external onlySocrates {
        require(_newOwner != address(0));

        PlatoAddress = _newOwner;
    }

    function setAristotle(address _newOwner) external onlySocrates {
        require(_newOwner != address(0));

        AristotleAddress = _newOwner;
    }

    /// @dev Modifier to allow actions only when the contract IS NOT paused
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /// @dev Modifier to allow actions only when the contract IS paused
    modifier whenPaused {
        require(paused);
        _;
    }

    /// @dev Called by owner to pause the contract. Used only when
    ///  a bug or exploit is detected and we need to limit damage.
    function pause() external onlyCLevel whenNotPaused {
        paused = true;
    }

    /// @dev Unpauses the smart contract. Can only be called by the CEO, since
    ///  one reason we may pause the contract is when CFO or COO accounts are
    ///  compromised.
    /// @notice This is public rather than external so it can be called by
    ///  derived contracts.
    function unpause() public onlyCLevel whenPaused {
        // can't unpause if contract was upgraded
        paused = false;
    }
}


//SourceUnit: ReentrancyGuard.sol

pragma solidity ^0.5.8;

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
 *
 * _Since v2.5.0:_ this module is now much more gas efficient, given net gas
 * metering changes introduced in the Istanbul hardfork.
 */
contract ReentrancyGuard {
    bool private _notEntered;

    constructor() internal {
        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;
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
        require(_notEntered, "ReentrancyGuard: reentrant call");
        // Any calls to nonReentrant after this point will fail
        _notEntered = false;
        _;
        // By storing the original value once again, a refund is triggered (see
        _notEntered = true;
    }
}


//SourceUnit: SafeMath.sol

pragma solidity ^0.5.0;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath#mul: OVERFLOW");

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath#div: DIVISION_BY_ZERO");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath#sub: UNDERFLOW");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath#add: OVERFLOW");

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath#mod: DIVISION_BY_ZERO");
        return a % b;
    }
}