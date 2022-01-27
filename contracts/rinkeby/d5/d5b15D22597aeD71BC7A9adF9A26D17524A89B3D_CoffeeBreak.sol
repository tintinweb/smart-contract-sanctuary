// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.2;

import "./cb_game.sol";
import "./cb_teamManager.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CoffeeBreak is Game, TeamManager, Ownable {

    struct capcha {
        string question;
        bytes32 answer;
        address author;
        bool solved;
    }
    mapping (uint => mapping (uint => capcha)) capchas;
    string public alex = "no";

    constructor(){
    }

    function pressButton(string memory _answer, string memory _newQuestion, string memory _newAnswer) public {
        uint _teamId = getTeamByAddress(msg.sender);
        require(buttonReady(), "Button not ready.");
        require(whosTurn(0,_teamId) == msg.sender, "Not your turn");
        require(teamAlive(_teamId) == true, "Your team already lost.");

        // require(teams[_teamId].capchas(round)[solved] == false, "Capcha already solved.");
        // require(teams[_teamId].capchas[round - 1].answer == keccak256(abi.encodePacked(_answer)), "Wrong answer. Ask for help if you need to.");

    }

    function start() public onlyOwner {
        alex = "yes";
        // require(started == false, "Already started!");
        // started = true;
        // startTime = block.timestamp;
        // deadline = startTime + interval;
        // for (uint i; i > numTeams(); i++){
        //     capchas[i][0] = capcha({
        //         question : "Type 'go' to start.",
        //         answer : keccak256(abi.encodePacked("go")),
        //         author : 0x0000000000000000000000000000000000000000,
        //         solved : false
        //     });
        // }
        // round++;
        // super.start();
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.2;

import "./cb_team.sol";

contract TeamManager {
    
    uint minMembers = 1; 
    uint maxMembers = 36; 
    uint maxTeams = 6;

    Team[] teams;

    constructor(){
    }

// Team Management

    function createTeam(address[] memory _members, string memory _name) public {
        require(teams.length < maxTeams, "we have maximum teams");
        require(_members.length >= minMembers, "not enough members");
        require(_members.length <= maxMembers, "too many members");
        teams.push(new Team(_members, _name));
    }

    function nominateMember(uint _teamId, address _newAddress) public { 
        teams[_teamId].nominateMember(_newAddress);
    }

    function approveMember(uint _teamId, address _newAddress) public {
        teams[_teamId].approveMember(_newAddress, true);
    }

    function mergeFullyApproved(uint _teamId, address _newAddress) public {
        require(teams[_teamId].numMembers() + 1 <= maxMembers, "Team has maximum members.");
        teams[_teamId].mergeFullyApproved(_newAddress);
    }

// View functions

    function teamMembers(uint _teamId) public view returns (address[] memory){
        return teams[_teamId].getMembers();
    }

    function teamNominees(uint _teamId) public view returns (address[] memory){
        return teams[_teamId].getNominees();
    }

    function numTeams() public view returns (uint) {
        return teams.length;
    }

    function teamName(uint _teamId) public view returns (string memory) {
        return teams[_teamId].name();
    }

    function teamAlive(uint _teamId) public view returns (bool) {
        return teams[_teamId].alive();
    }

    function getTurn(uint _teamId) public view returns (uint) {
        return teams[_teamId].turn(0);
    }

    function whosTurn(uint _offsetIndex, uint _teamId) public view returns (address) {
        uint _turn = teams[_teamId].turn(_offsetIndex);
        return teams[_teamId].members(_turn);
    }

    function getTeamByAddress(address _address) public view returns (uint) {
        require(inAnyTeam(_address), "not in a team");
        uint result;
        for (uint t = 0;t<teams.length;t++){
            if (inTeam(_address,t))
                result = t;
        }
        return result;
    }

    function inTeam(address _address, uint _teamId) public view returns (bool) {
        return teams[_teamId].inTeam(_address);
    }

    function inAnyTeam(address _address) public view returns (bool) {
        bool result = false;
        for (uint t = 0;t<teams.length;t++){
            if (inTeam(_address,t))
                result = true;
        }
        return result;
    }

// Internal

    function rotateTurn(uint _teamId) internal {
        teams[_teamId].rotateTurn();
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.2;


contract Game  {

    bool public started;
    uint public startTime;
    uint public round; 
    uint public minRounds; // min rounds to claim prize
    uint public deadline; // deadline timestamp
    uint public interval;
    uint public gracePeriod; // 15 min
    uint intervalDecay; // percent rate decay
    uint decayRandom; // percent randomness to be added to the decay rate

    constructor(){
        started = false;
        round = 0;
        deadline = 0;

        minRounds = 5;
        interval = 120; // seconds
        gracePeriod = 60; // seconds
        intervalDecay = 5; // percent
        decayRandom = 0;
    }

    // function start() public virtual {
    // }

// View Functions

    function buttonReady() public view returns (bool) {
        return (block.timestamp >= deadline && block.timestamp <= deadline + gracePeriod);
    }

// Private

    function nextRound() internal {
        round++;
        uint _random = uint(keccak256(abi.encodePacked(blockhash(block.number), block.timestamp, msg.sender))) % decayRandom; // fix later -- refer to amxx's contract
        interval = interval * (100 - intervalDecay + _random) / 100;
        deadline += interval;
    }

}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract Team {
    using EnumerableSet for EnumerableSet.AddressSet;
    
    uint _turn;
    string public name;
    address[] public members; 
    bool public alive;

    EnumerableSet.AddressSet private nominees;
    mapping (address => mapping (address => bool)) nomineeApprovals;

    constructor(address[] memory _members, string memory _name) {
        members = _members;
        name = _name;
        _turn = 0;
        alive = true;
    }
    
// TEAM MANAGEMENT

    function nominateMember(address _newAddress) public { 
        nominees.add(_newAddress);
        nomineeApprovals[msg.sender][_newAddress] = true;
    }

    function approveMember(address _newAddress, bool _approved) public {
        nomineeApprovals[_newAddress][msg.sender] = _approved;
    }

    function mergeFullyApproved(address _newAddress) public {
        bool allApproved = true;
        for (uint i = 0;i < members.length;i++){
            if (nomineeApprovals[_newAddress][members[i]] == false)
                allApproved = false;
        }
        require(allApproved, "Not approved by all");
        nominees.remove(_newAddress);
        members.push(_newAddress);
    }

// View Functions

    function inTeam(address _address) public view returns (bool) {
        for (uint m = 0; m < members.length; m++){
            if (members[m] == _address)
                return true;
        }
        return false;
    }

    function numMembers() public view returns (uint){
        return members.length;
    }

    function numNominees() public view returns (uint){
        return nominees.length();
    }

    function getNominees() public view returns (address[] memory){
        return nominees.values();
    }

    function getMembers() public view returns (address[] memory){
        return members;
    }

    function turn(uint _offsetIndex) public view returns (uint){
        // offset of 0 will return current turn
        return (_turn + _offsetIndex) % members.length;
    }

    function rotateTurn() public {
        _turn++ % members.length;
    }
}

// SPDX-License-Identifier: MIT
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