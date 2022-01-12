/**
 *Submitted for verification at Etherscan.io on 2022-01-12
*/

// Sources flattened with hardhat v2.8.2 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]

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


// File contracts/Stable.sol

pragma solidity ^0.8.0;

contract Stable is Ownable {

    modifier dataExist(string memory _name) {
        require(stableExist(_name), "Stable doesn't exist");
        _;
    }

    struct AddressLocation {
        string street;
        string streetNb;
        string city;
        string zipCode;
        string country;
    }

    struct ContactPerson {
        string lastName;
        string firstName;
        string phoneNumber;
        string emailAddress;
        AddressLocation addressLocation;
    }
    struct StableData {
        AddressLocation addressLocation;
        ContactPerson contactPerson;
    }

    mapping (string => StableData) public stables;
    mapping (string => bool) public stablesExists;
    constructor() {

    }

    function addStable(string memory _name, AddressLocation memory _addressLocation, ContactPerson memory _contactPerson) public onlyOwner {
        require(!stableExist(_name), "Stable already exist");
        stables[_name] = StableData(_addressLocation, _contactPerson);
        stablesExists[_name] = true;
    }

    function updStable(string memory _name, AddressLocation memory _addressLocation, ContactPerson memory _contactPerson) public onlyOwner dataExist(_name) {
        stables[_name] = StableData(_addressLocation, _contactPerson);
    }

    function updStableContactPerson(string memory _name, ContactPerson memory _contactPerson) public onlyOwner dataExist(_name) {
        stables[_name].contactPerson = _contactPerson;
    }

    function updStableAddressLocation(string memory _name, AddressLocation memory _addressLocation) public onlyOwner dataExist(_name) {
        stables[_name].addressLocation = _addressLocation;
    }

    function stableExist(string memory _name) view public returns (bool) {
        return stablesExists[_name];
    }
}


// File contracts/Horse.sol

pragma solidity ^0.8.0;

contract Horse is Ownable {

    modifier dataExist(string memory _id, string memory _stableName) {
        require(horseExist(_id), "Horse doesn't exist");
        require(stableContract.stableExist(_stableName), "Stable doesn't exist");
        _;
    }

    struct HorseData {
        string name;
        string breed;
        string birthDate;
        string sex;
        string[] stables;
    }

    mapping (string => HorseData) public horses;
    mapping (string => bool) public horsesExists;

    Stable stableContract;

    constructor (address _stableContract) {
        stableContract = Stable(_stableContract);
    }
    function addHorse(string memory _id, string memory _name, string memory _breed, string memory _birthDate, string memory _sex, string memory _stableName) public onlyOwner {
        require(!horseExist(_id), "Horse already exist");
        require(stableContract.stableExist(_stableName), "Stable doesn't exist");
        string[] memory lst = new string[](1);
        lst[0] = _stableName;
        horses[_id] = HorseData(_name, _breed, _birthDate, _sex, lst);

        horsesExists[_id] = true;
    }

    function updHorseStable(string memory _id, string memory _stableName) public onlyOwner dataExist(_id, _stableName) {
        horses[_id].stables.push(_stableName);
    }

    function checkActualHorseStable(string memory _id, string memory _stableName) view public dataExist(_id, _stableName) returns (bool) {
        return keccak256(abi.encodePacked(horses[_id].stables[horses[_id].stables.length - 1])) == keccak256(abi.encodePacked(_stableName));
    }

    function horseHistory(string memory _id) view public returns (string[] memory){
        return horses[_id].stables;
    }

    function horseExist(string memory _id) view public returns (bool) {
        return horsesExists[_id];
    }
}