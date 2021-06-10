/**
 *Submitted for verification at Etherscan.io on 2021-06-09
*/

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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol

// SPDX-License-Identifier: MIT

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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/TokenVesting.sol

pragma solidity 0.8.4;


contract TokenVesting is Ownable {
    struct VestingCategory{
        bool exists;
        uint cliff;
        uint vestignDuration;
    }

    struct Vesting {
        bool exists;
        string category;
        uint startingAmount;
    }

    event VestingCategoryAdded(string name);
    event VestingSet(address user, string categoryName, uint startingAmount);
    event VestingRemoved(address user, string categoryName);

    mapping(string => VestingCategory) public vestingCategoriesByName;
    string[] public vestingCategories;

    mapping(address => Vesting) public usersVesting;

    uint immutable public startDate;

    constructor(uint _vestingStart){
        startDate = _vestingStart;
    }

    function addVestingCategory(string calldata _name, VestingCategory calldata _category) external onlyOwner{
        require(!vestingCategoriesByName[_name].exists, "Vesting category already exists");

        vestingCategories.push(_name);
        vestingCategoriesByName[_name] = _category;
        vestingCategoriesByName[_name].exists = true;

        emit VestingCategoryAdded(_name);
    }

    function setUsersVesting(address[] calldata _users, Vesting[] calldata _vestings) external onlyOwner{
        require(_users.length == _vestings.length, "Users and vestings amounts don't match up");
        for(uint i = 0; i < _users.length; i++){
            address user = _users[i];
            Vesting calldata vesting = _vestings[i];
            require(vestingCategoriesByName[vesting.category].exists, "Vesting category does not exist");

            usersVesting[user] = vesting;
            usersVesting[user].exists = true;

            emit VestingSet(user, vesting.category, vesting.startingAmount);
        }
    }

    function removeUsersVesting(address[] calldata _users) external onlyOwner{
        for(uint i = 0; i < _users.length; i++){
            address user = _users[i];
            Vesting memory vesting = usersVesting[user];
            
            require(vesting.exists, "User is not vesting");

            delete usersVesting[user];

            emit VestingRemoved(user, vesting.category);
        }
    }

}