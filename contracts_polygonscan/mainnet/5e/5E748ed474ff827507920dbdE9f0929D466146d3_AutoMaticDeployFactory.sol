/**
 *Submitted for verification at polygonscan.com on 2021-07-20
*/

// Sources flattened with hardhat v2.4.1 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// File @openzeppelin/contracts/access/[email protected]

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
    constructor () internal {
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


// File contracts/factory/DeployFactory.sol

interface IFactory {
    function deploy(address param0, address param1, bool param2) external returns (address deployedContract);
}

interface IStrategy {
    function setVault(address) external;
}

contract AutoMaticDeployFactory is Ownable {
    struct Pool {
        address vault;
        address strategy;
        address lp;
        uint flag;
        uint deployed;
        bool isActive;
    }

    address public immutable mati;
    address public immutable strategyFactory;
    address public immutable maximizerFactory;
    address public immutable compounderFactory;

    Pool[] public pools;

    constructor (
        address _mati,
        address _strategyFactory,
        address _maximizerFactory,
        address _compounderFactory
    ) public {
        mati = _mati;
        strategyFactory = _strategyFactory;
        maximizerFactory = _maximizerFactory;
        compounderFactory = _compounderFactory;
    }

    function setStatus(uint _index) external onlyOwner {
        pools[_index].isActive = false;

        mati.delegatecall(abi.encodeWithSignature("setMinter(address, bool)", pools[_index].vault, false));
    }

    function deployPool(address _lp, address _rewardPool, uint _flag) external onlyOwner {
        // flag => 0: Quick Maximizer, 1: LP Compounder, 2: Single Vault
        address strategy;
        address vault;
        if (_flag == 0 || _flag == 1) {
            strategy = IFactory(strategyFactory).deploy(_lp, _rewardPool, _flag == 1 ? true : false);
        }

        if (_flag == 0) {
            vault = IFactory(maximizerFactory).deploy(strategy, address(0), false);
        } else if (_flag == 1) {
            vault = IFactory(compounderFactory).deploy(strategy, address(0), false);
        }

        if (_flag == 0 || _flag == 1) {
            strategy.delegatecall(abi.encodeWithSignature("setVault(address)", vault));
        }

        mati.delegatecall(abi.encodeWithSignature("setMinter(address, bool)", vault, true));

        pools.push(Pool(strategy, vault, _lp, _flag, block.timestamp, true));
    }
}