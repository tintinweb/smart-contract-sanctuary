/**
 *Submitted for verification at BscScan.com on 2021-11-25
*/

// File: contracts/utils/Access.sol

/*

            888      .d88888b.   .d8888b.
            888     d88P" "Y88b d88P  Y88b
            888     888     888 Y88b.
            888     888     888  "Y888b.
            888     888     888     "Y88b.
            888     888     888       "888
            888     Y88b. .d88P Y88b..d88P
            88888888 "Y88888P"   "Y8888P"


*/

pragma solidity ^0.8.0;


contract Access {
    bool private _contractCallable = false;
    bool private _pause = false;
    address private _owner;
    address private _pendingOwner;

    event NewOwner(address indexed owner);
    event NewPendingOwner(address indexed pendingOwner);
    event SetContractCallable(bool indexed able,address indexed owner);

    constructor(){
        _owner = msg.sender;
    }

    // ownership
    modifier onlyOwner() {
        require(owner() == msg.sender, "caller is not the owner");
        _;
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }
    function setPendingOwner(address account) public onlyOwner {
        require(account != address(0),"zero address");
        require(_pendingOwner == address(0), "pendingOwner already exist");
        _pendingOwner = account;
        emit NewPendingOwner(_pendingOwner);
    }
    function becomeOwner() external {
        require(msg.sender == _pendingOwner,"not pending owner");
        _owner = _pendingOwner;
        _pendingOwner = address(0);
        emit NewOwner(_owner);
    }

    // pause
    modifier checkPaused() {
        require(!paused(), "paused");
        _;
    }
    function paused() public view virtual returns (bool) {
        return _pause;
    }
    function setPaused(bool p) external onlyOwner{
        _pause = p;
    }


    // contract call
    modifier checkContractCall() {
        require(contractCallable() || msg.sender == tx.origin, "non contract");
        _;
    }
    function contractCallable() public view virtual returns (bool) {
        return _contractCallable;
    }
    function setContractCallable(bool able) external onlyOwner {
        _contractCallable = able;
        emit SetContractCallable(able,_owner);
    }

}

// File: contracts/interface/iLOS20.sol

pragma solidity ^0.8.0;

interface iLOS20 {
    function balanceOf(address account)external view returns(uint);
    function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);
    function mint(address recipient_, uint amount_) external returns (bool);
    function burnFrom(address account, uint256 amount) external;
    function transfer(address recipient, uint256 amount) external returns (bool);
}

// File: contracts/interface/iLOS721.sol

pragma solidity ^0.8.0;

interface iLOS721 {
    function latestTokenId() external view returns (uint);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function mint(address recipient_) external returns (uint);
    function burn(uint256 tokenId) external;
    function getTokens(address owner) external view returns(uint[] memory);
    function transferFrom(address from,address to,uint256 tokenId) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// File: contracts/interface/iTemplar.sol

pragma solidity ^0.8.0;

interface iTemplar {
    function getTokenInfo(uint id) external view returns(uint energy, uint maxEnergy, uint starPower, uint starCode, uint level, uint state);
    function levelInfo(uint id) external view returns (uint loseRate, uint rewardMultiple);
}

// File: @openzeppelin/contracts/utils/structs/EnumerableSet.sol

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

// File: contracts/Stake721.sol

pragma solidity ^0.8.0;






contract Stake721 is Access {

    iLOS20 public constant LOS20 = iLOS20(0x98b10Ab49eDC263ab14aaCB3Dd1ac345b5BB9B18);
    iLOS721 public constant LOS721 = iLOS721(0x6152E3E4Ba170503e930e3237380b763824bFbA1);
    iTemplar public constant Templar = iTemplar(0x99CDc9d2554380b8E6208a1C6Ba955E8112c457e);

    uint public dailyReward = 3.32e18;

    using EnumerableSet for EnumerableSet.UintSet;
    struct User {
        EnumerableSet.UintSet cards;
        mapping(uint => uint) claimAt;
        uint totalClaim;
    }
    mapping(address => User) users;

    event Stake(address indexed sender, uint indexed tokenId);
    event Claim(address indexed sender, uint indexed tokenID, uint indexed amount);
    event Quit(address indexed sender, uint indexed tokenId);
    event EmergencyQuit(address indexed sender, uint indexed tokenId);

    constructor(){
        setPendingOwner(address(0x0564b35B75F27be4c153Eed9237D26bB08FFeDBC));
    }

    function stake(uint id) internal {
        (,,,uint starCode,, uint state) = Templar.getTokenInfo(id);
        require(starCode >= 100, "open first");
        require(state == 0, "check state");

        require(LOS721.ownerOf(id) == msg.sender,"not owner");
        LOS721.transferFrom(msg.sender, address(this), id);

        users[msg.sender].claimAt[id] = block.timestamp;
        users[msg.sender].cards.add(id);
        emit Stake(msg.sender, id);
    }

    function claim(uint id) internal {

        uint claimAt = users[msg.sender].claimAt[id];
        require(claimAt != 0, "not owner");

        uint reward = calReward(id, msg.sender);
        LOS20.mint(msg.sender, reward);
        users[msg.sender].claimAt[id] = block.timestamp;
        users[msg.sender].totalClaim += reward;
        emit Claim(msg.sender, id, reward);
    }


    function quit(uint id) internal {

        uint claimAt = users[msg.sender].claimAt[id];
        require(claimAt != 0, "not owner");

        LOS721.transferFrom(address(this), msg.sender, id);
        users[msg.sender].claimAt[id] = 0;
        users[msg.sender].cards.remove(id);
        emit Quit(msg.sender, id);
    }

    function calReward(uint id, address owner) public view returns (uint){

        uint claimAt = users[owner].claimAt[id];
        return (block.timestamp - claimAt) * calDailyReward(id) / 1 days;
    }

    // 【1+（卡牌星级-1）/10】*产出倍数*3.32LOS/天
    function calDailyReward(uint id) public view returns (uint){
        (,,,uint starCode, uint level,) = Templar.getTokenInfo(id);
        uint star = starCode / 100;

        (, uint rewardMultiple) = Templar.levelInfo(level);

        return (10 + star - 1) * dailyReward * rewardMultiple / 10;
    }

    function multiStake(uint[] memory idAry) external checkPaused checkContractCall {
        for(uint16 i=0; i<idAry.length; i++) {
            stake(idAry[i]);
        }
    }

    function multiClaim(uint[] memory idAry) external checkPaused checkContractCall {
        for(uint16 i=0; i<idAry.length; i++) {
            claim(idAry[i]);
        }
    }

    function multiQuit(uint[] memory idAry) external checkPaused checkContractCall {
        for(uint16 i=0; i<idAry.length; i++) {
            claim(idAry[i]);
            quit(idAry[i]);
        }
    }

    function emergencyQuit(uint id) external {
        quit(id);
    }

    function setDailyReward(uint amount) external onlyOwner {
        dailyReward = amount;
    }

    function userInfo(address account) external view returns(uint[] memory idAry, uint[] memory rewards, uint[] memory starCodes, uint[] memory levelAry){
        idAry = users[account].cards.values();
        rewards = new uint[](idAry.length);
        starCodes = new uint[](idAry.length);
        levelAry = new uint[](idAry.length);
        for (uint i=0; i<idAry.length; i++) {
            rewards[i] = calReward(idAry[i], account);
            (,,,uint starCode, uint level,) = Templar.getTokenInfo(idAry[i]);
            starCodes[i] = starCode;
            levelAry[i] = level;
        }
        return (idAry,rewards,starCodes,levelAry);
    }
}