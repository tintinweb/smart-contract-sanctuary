/**
 *Submitted for verification at Etherscan.io on 2021-11-25
*/

// Dependency file: @openzeppelin/contracts/utils/Context.sol

// SPDX-License-Identifier: MIT

// pragma solidity ^0.8.0;

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
        return msg.data;
    }
}


// Dependency file: @openzeppelin/contracts/access/Ownable.sol


// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/utils/Context.sol";

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


// Dependency file: contracts/access/OperatorAccess.sol


// pragma solidity >=0.8.0 <1.0.0;

// import "/mnt/c/Users/chickenhat/Desktop/chics/node_modules/@openzeppelin/contracts/access/Ownable.sol";

contract OperatorAccess is Ownable {

    mapping(address => bool) public operators;

    event SetOperator(address account, bool status);

    function setOperator(address _account, bool _status) external onlyOwner {
        operators[_account] = _status;
        emit SetOperator(_account, _status);
    }

    modifier onlyOperator() {
        require(operators[msg.sender], "only operator");
        _;
    }
}

// Dependency file: contracts/interfaces/ICowRegistry.sol


// pragma solidity >=0.8.0 <1.0.0;

interface ICowRegistry {

    enum Gender {
        MALE,
        FEMALE
    }

    struct Creature {
        Gender gender;
        uint8 rarity;
    }

    function set(uint16 _cowId, Creature memory _data) external;

    function setBatch(uint16[] calldata _ids, Creature[] calldata _data) external;

    function get(uint256 _tokenId) external view returns (Creature memory data);
}

// Root file: contracts/storage/CowsRegistry.sol


pragma solidity >=0.8.0 <1.0.0;

// import "contracts/access/OperatorAccess.sol";
// import "contracts/interfaces/ICowRegistry.sol";

contract CowsRegistry is OperatorAccess, ICowRegistry {

    mapping(uint256 => Creature) internal _creature;

    function set(uint16 _cowId, Creature memory _data) external override onlyOperator {
        _creature[_cowId] = _data;
    }

    function setBatch(uint16[] calldata _ids, Creature[] calldata _data) external override onlyOperator {
        uint len = _ids.length;

        require(len == _data.length, "Registry: _creature length not match");

        for (uint i; i < len; i++) {
            _creature[_ids[i]] = _data[i];
        }
    }

    function get(uint256 _tokenId) external override view returns (Creature memory data) {
        data = _creature[_tokenId];
    }
}