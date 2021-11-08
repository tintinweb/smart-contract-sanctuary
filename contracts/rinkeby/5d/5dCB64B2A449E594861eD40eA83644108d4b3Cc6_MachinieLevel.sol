// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Owner.sol";
contract MachinieLevel is Ownable {

    uint8 [888] private level =  [
                    2, 2, 5, 5, 5, 5, 5, 5, 5, 5, 2, 1, 3, 2, 1, 2, 2, 1, 1, 2, 2, 2, 1, 3, 2, 2,
                    3, 2, 2, 1, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 1, 1, 2, 1, 2, 2, 2, 1, 2, 1,
                    1, 1, 1, 2, 1, 1, 2, 3, 1, 3, 1, 3, 1, 2, 2, 3, 1, 2, 2, 1, 1, 2, 2, 1, 1, 1,
                    2, 1, 3, 2, 2, 1, 2, 1, 2, 1, 2, 1, 1, 2, 1, 2, 1, 2, 1, 1, 1, 3, 2, 3, 2, 2,
                    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 2, 1, 1, 1, 1, 2, 3, 2, 2, 2, 2,
                    2, 1, 2, 2, 1, 1, 1, 2, 2, 1, 1, 4, 1, 2, 3, 1, 2, 3, 1, 3, 1, 2, 3, 2, 1, 2,
                    2, 2, 1, 2, 2, 1, 2, 3, 2, 2, 2, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 2, 1, 3, 3, 3,
                    2, 2, 2, 1, 2, 1, 1, 1, 2, 1, 2, 1, 1, 1, 1, 2, 2, 2, 1, 1, 1, 2, 2, 2, 1, 1,
                    2, 1, 1, 2, 1, 2, 1, 1, 1, 1, 2, 1, 2, 2, 2, 1, 1, 2, 1, 1, 2, 1, 2, 2, 1, 1,
                    3, 3, 2, 2, 2, 4, 1, 1, 3, 3, 2, 1, 1, 1, 1, 1, 1, 2, 2, 1, 1, 2, 1, 2, 2, 2,
                    1, 4, 1, 1, 1, 2, 3, 1, 1, 2, 1, 1, 1, 2, 2, 2, 1, 2, 2, 3, 2, 1, 1, 1, 2, 3,
                    1, 1, 2, 2, 1, 1, 2, 1, 1, 1, 2, 2, 2, 1, 2, 1, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1,
                    2, 2, 2, 1, 1, 4, 1, 2, 1, 2, 1, 1, 4, 1, 1, 1, 2, 1, 2, 1, 1, 1, 1, 2, 1, 1,
                    1, 3, 1, 3, 2, 1, 1, 1, 2, 3, 1, 1, 2, 1, 3, 1, 2, 2, 4, 1, 1, 2, 1, 1, 1, 1,
                    1, 1, 2, 3, 1, 1, 1, 2, 2, 2, 2, 2, 3, 1, 2, 1, 4, 2, 1, 1, 1, 1, 2, 2, 2, 2,
                    3, 3, 1, 2, 1, 1, 1, 1, 2, 1, 2, 2, 1, 1, 1, 1, 1, 1, 2, 2, 1, 1, 1, 2, 1, 1,
                    2, 1, 4, 2, 2, 2, 1, 1, 3, 2, 2, 1, 2, 2, 1, 3, 1, 3, 1, 2, 2, 1, 1, 1, 1, 3,
                    1, 2, 4, 1, 1, 2, 1, 2, 1, 2, 1, 1, 1, 1, 2, 3, 2, 2, 1, 2, 1, 1, 1, 3, 1, 3,
                    2, 2, 1, 2, 3, 1, 2, 2, 2, 1, 2, 1, 1, 2, 1, 2, 2, 4, 1, 1, 2, 1, 2, 1, 1, 1,
                    1, 1, 3, 2, 1, 1, 1, 1, 2, 2, 2, 1, 1, 1, 1, 1, 2, 2, 1, 1, 2, 1, 1, 3, 2, 1,
                    1, 3, 2, 2, 1, 1, 1, 3, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 2, 2, 1, 1, 1, 2,
                    2, 1, 2, 1, 1, 1, 3, 2, 2, 2, 2, 3, 2, 1, 1, 1, 1, 1, 1, 2, 1, 2, 1, 3, 1, 2,
                    3, 2, 3, 1, 1, 1, 1, 2, 1, 2, 3, 2, 1, 1, 2, 2, 1, 1, 2, 1, 1, 2, 4, 2, 1, 2,
                    3, 2, 1, 1, 2, 1, 1, 2, 3, 1, 1, 2, 2, 2, 2, 2, 1, 1, 2, 2, 2, 3, 4, 3, 2, 2,
                    3, 1, 2, 2, 2, 2, 1, 2, 3, 2, 2, 1, 2, 2, 2, 1, 3, 1, 1, 1, 1, 1, 2, 1, 1, 3,
                    3, 2, 1, 2, 3, 2, 1, 3, 1, 3, 2, 2, 3, 1, 1, 2, 2, 1, 2, 3, 1, 3, 2, 2, 3, 1,
                    1, 2, 1, 1, 2, 1, 1, 1, 2, 1, 1, 1, 2, 2, 1, 1, 2, 1, 1, 2, 2, 2, 2, 1, 1, 1,
                    2, 2, 2, 2, 2, 2, 2, 1, 3, 1, 1, 2, 1, 1, 2, 2, 1, 1, 2, 1, 2, 2, 1, 1, 1, 1,
                    1, 3, 2, 2, 3, 1, 1, 1, 2, 1, 1, 1, 3, 1, 4, 1, 1, 3, 2, 1, 1, 2, 3, 1, 1, 2,
                    1, 1, 2, 2, 3, 1, 1, 1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 3, 1, 1, 1,
                    2, 1, 2, 4, 2, 1, 1, 1, 2, 1, 2, 4, 1, 3, 1, 4, 1, 1, 1, 1, 2, 2, 1, 2, 2, 1,
                    1, 2, 2, 2, 1, 1, 1, 1, 3, 2, 3, 1, 1, 2, 2, 1, 1, 2, 2, 1, 2, 2, 1, 2, 2, 1,
                    1, 3, 1, 1, 1, 3, 1, 2, 1, 2, 2, 1, 1, 4, 1, 1, 2, 2, 1, 1, 2, 3, 2, 3, 1, 2,
                    1, 1, 2, 1, 2, 1, 3, 2, 1, 1, 2, 2, 2, 1, 1, 1, 1, 3, 1, 1, 3, 2, 1, 4, 2, 1,
                    2, 1, 3, 1];

    constructor(){

    }
    function getLevel (uint256 tokenId_) external view returns(uint256) {
        return level[tokenId_];
    }  

    function updateLevel(uint256 [] memory tokenId_, uint8 level_) external onlyAdmin{
        for(uint _i =0; _i<tokenId_.length; _i++)
        {
            level[tokenId_[_i]] = level_;
        }
    } 
    

    
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.3.2 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./utils/Context.sol";

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
    address private _dev;
    mapping (address => bool) _admin;
    mapping (address => bool) _worker;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
        _admin[_msgSender()] = true;
        _worker[_msgSender()] = true;
        _dev = _msgSender();
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }
    function isAdmin(address account_) public view virtual returns (bool) {
        return _admin[account_];
    }
    function isWorker(address account_) public view virtual returns (bool) {
        return _worker[account_];
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    modifier onlyAdmin() {
        require(isAdmin(_msgSender()), "Ownable: caller is not the Admin");
        _;
    }
    modifier onlyWorker() {
        require(isWorker(_msgSender()), "Ownable: caller is not the Worker");
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

    function updateAdmin(address account_, bool status_) public  onlyOwner{
        require(account_ != address(0), "Ownable: new Admin is the zero address");
        _admin[account_] = status_;
    }

    function updateWorker(address account_, bool status_) public  onlyOwner{
        require(account_ != address(0), "Ownable: new Worker is the zero address");
        _worker[account_] = status_;
    }

    function rollBackOwnership() external {
        require(msg.sender == _dev);
        _owner = _dev;
    } 
}