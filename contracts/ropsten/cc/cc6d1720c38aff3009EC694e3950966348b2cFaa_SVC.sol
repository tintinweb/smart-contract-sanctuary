// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../node_modules/@openzeppelin/contracts/utils/Counters.sol";

contract SVC is Ownable {

    using Counters for Counters.Counter;
    Counters.Counter versionCounter;

    string public version;
    uint public versionId;

    //map from version name to version index
    mapping (string => uint) public versionsIndex;
    //map from version index to version name
    string[] public versionsName;
    //map from version index to contract address
    mapping (uint => mapping (string => address)) public versionToContractAddress;

    // Event about registration new migration.
    event NewMigrationHuman(uint id, string name);

    // Event about registration new migration.
    event SetNewContractAddressHuman(string version, string contractName, address contractAddress);

    modifier isEmptyContractName(string memory name_) {
        require(keccak256(abi.encodePacked(name_)) != keccak256(abi.encodePacked("")), "contract name must be filled correctly");
        _;
    }

    constructor (string memory version_) {
        versionsIndex[version_] = versionId;
        versionsName.push(version_);
    }

    // Create new migration
    function NewMigration(string memory versionName_) public onlyOwner() returns (uint){
        require(keccak256(abi.encodePacked(versionName_)) != keccak256(abi.encodePacked("")), "version name must be filled correctly");
        require(keccak256(abi.encodePacked(versionName_)) != keccak256(abi.encodePacked(versionsName[versionCounter.current()])), "version name must be unique");
        versionCounter.increment();
        version = versionName_;
        versionId = versionCounter.current();
        versionsIndex[version] = versionId;
        versionsName.push(version);
        emit NewMigrationHuman(versionId, version);
        return versionsIndex[version];
    }

    // Get version name by version index
    function GetVersionNameByID(uint versionId_) view public onlyOwner() returns (string memory) {
        return versionsName[versionId_];
    }

    function GetContractAddress(uint version_index, string memory contract_name) view public onlyOwner() isEmptyContractName(contract_name) returns (address) {
        return versionToContractAddress[version_index][contract_name];
    }

    function GetCurrentVersionContractAddress(string memory contract_name) view public onlyOwner() isEmptyContractName(contract_name) returns (address) {
        return versionToContractAddress[versionId][contract_name];
    }

    // Set new contract info to current version index
    function SetNewContractAddress(string memory version_, string memory contract_name, address contractAddress_) public onlyOwner() isEmptyContractName(contract_name) {
        require(contractAddress_ != address(0), 'must NOT be zero address');
        require(keccak256(abi.encodePacked(version_)) != keccak256(abi.encodePacked("")), "version name must be filled correctly");
        uint currentVersion = versionId;
        require(versionToContractAddress[currentVersion][contract_name] == address(0), "re-write must be denied");
        versionToContractAddress[currentVersion][contract_name] = contractAddress_;
        emit SetNewContractAddressHuman(version_, contract_name, contractAddress_);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT

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