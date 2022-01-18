//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IDR_Registry.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DR_Registry is IDR_Registry, Ownable {

    mapping (address => bool) registry;
    mapping (address => bool) operators;
    mapping (address => bool) minters;

    mapping (address => bool) public admins;

    modifier onlyAdmin() {
        require(
            msg.sender == owner() ||
            admins [msg.sender]
        );
        _;
    }


    function setApproval(address _owner, bool state) internal {
        registry[_owner] = state;
    }


    function register() external override {
        setApproval(msg.sender, true);
    }

    function withdraw()  external {
        setApproval(msg.sender, false);
    }

    function setMinter(address _owner, bool state) external onlyAdmin {
        minters[_owner] = state;
    }


    function setAdmin(address _user, bool _state) external onlyOwner {
        admins[_user] = _state;
    }

    function setOperator(address _operator, bool _state) external onlyAdmin {
        operators[_operator] = _state;
    }


    function authorised(address _owner,address _operator) external view override returns (bool) {
        if (!operators[_operator]) return false;
        return registry[_owner];
    }

    function isMinter(address _owner) external view override returns (bool) {
        return minters[_owner];
    }

    function isOperator(address _contract) external view returns (bool) {
        return operators[_contract];
    }

    function isRegistered(address _user) external view returns (bool) {
        return registry[_user];
    }

    function isAdmin(address _user) external view override returns (bool) {
        return _user == owner() || admins[_user];
    }


    function isRegistry() external pure override returns (bool) {
        return true;
    }

 }

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IDR_Registry  {

    // This person authorised the contract to trade for them
    function authorised(address _owner,address _operator) external view returns (bool) ;

    function isMinter(address _owner) external view returns (bool) ;

    function isRegistry() external pure returns (bool) ;

    function isAdmin(address _user) external view returns (bool);

    function register() external;
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