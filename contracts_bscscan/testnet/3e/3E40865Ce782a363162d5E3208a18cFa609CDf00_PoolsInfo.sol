// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./Whitelist.sol";


contract PoolsInfo is WhiteList {
    struct PoolData {
        address factory;
        address pool;
        address stakeToken;
        address implAndTerms;
    }

    PoolData[] public pools;

    event NewPool(uint id, address indexed factory, address pool, address indexed stakeToken, address indexed implAndTerms);

    function getPoolsLength() public view returns (uint) {
        return pools.length;
    }

    function addPool(address factory_, address pool_, address stakeToken_, address implAndTerms_) public {
        require(getWhiteListStatus(msg.sender), "PoolsInfo::addPool: factory is not in whitelist");

        PoolData memory newPool;
        newPool.factory = factory_;
        newPool.pool = pool_;
        newPool.stakeToken = stakeToken_;
        newPool.implAndTerms = implAndTerms_;

        uint id = getPoolsLength();
        emit NewPool(id, factory_, pool_, stakeToken_, implAndTerms_);

        pools.push(newPool);
    }

    function getPools(uint id) public view returns (PoolData memory) {
        return pools[id];
    }

    function getAllPools() public view returns (PoolData[] memory) {
        return pools;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";

contract WhiteList is Ownable {
    mapping (address => bool) public isWhiteListed;

    event AddedWhiteList(address _user);

    event RemovedWhiteList(address _user);

    function addWhiteList(address _user) public onlyOwner {
        isWhiteListed[_user] = true;

        emit AddedWhiteList(_user);
    }

    function removeWhiteList(address _user) public onlyOwner {
        isWhiteListed[_user] = false;

        emit RemovedWhiteList(_user);
    }

    function getWhiteListStatus(address _user) public view returns (bool) {
        return isWhiteListed[_user];
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