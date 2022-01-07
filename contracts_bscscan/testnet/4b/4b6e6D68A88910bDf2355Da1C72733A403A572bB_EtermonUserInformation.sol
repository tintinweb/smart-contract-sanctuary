/**
 *Submitted for verification at BscScan.com on 2022-01-07
*/

//SPDX-License-Identifier: MIT
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

// File: contracts/Utils/AccessRole.sol

pragma solidity 0.8.0;

library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }

    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }

    function has(Role storage role, address account)
        internal
        view
        returns (bool)
    {
        require(account != address(0));
        return role.bearer[account];
    }
}

contract AccessRole {
    using Roles for Roles.Role;

    event AccessAdded(address indexed account);
    event AccessRemoved(address indexed account);

    Roles.Role private accesss;

    modifier onlyAccess() {
        require(isAccess(msg.sender));
        _;
    }

    constructor() {
        _addAccess(msg.sender);
    }

    function isAccess(address account) public view returns (bool) {
        return accesss.has(account);
    }

    function addAccess(address account) public onlyAccess {
        _addAccess(account);
    }

    function renounceAccess() public {
        _removeAccess(msg.sender);
    }

    function _addAccess(address account) internal {
        accesss.add(account);
        emit AccessAdded(account);
    }

    function _removeAccess(address account) internal {
        accesss.remove(account);
        emit AccessRemoved(account);
    }
}
// File: contracts/Etermon/EtermonUserInformation.sol

pragma solidity 0.8.0;



contract EtermonUserInformation is Ownable, AccessRole {
    address private managerAddress;
    mapping(bytes => bytes32) private userSeed;
    mapping(bytes => uint256) private userNonce;

    event CreateUser(
        bytes indexed keyHash,
        bool indexed state
    );

    function initialize(address managerAddress_) external onlyOwner{
        managerAddress = managerAddress_;
        _addAccess(managerAddress);
    }

    function createAccount(bytes memory keyHash, bytes32 userSeed_) external onlyAccess{
        if (userSeed[keyHash] == "0x"){
            emit CreateUser(keyHash, false);
        }
        else {
            userSeed[keyHash] = userSeed_;
            userNonce[keyHash] = 0;
            emit CreateUser(keyHash, true);
        }
    }

    function getUserRandomNumber(bytes memory keyHash) external onlyAccess returns (uint256) {
        require(userSeed[keyHash] != "0x");
        uint256 returnValue = uint256(keccak256(abi.encodePacked(keyHash, userSeed[keyHash], managerAddress, userNonce[keyHash])));
        userNonce[keyHash] += 1;
        return returnValue;
    }

    function getUserInformation(bytes memory keyHash) external view onlyAccess returns (bytes32, uint256){
        return (userSeed[keyHash],userNonce[keyHash]);
    }
}