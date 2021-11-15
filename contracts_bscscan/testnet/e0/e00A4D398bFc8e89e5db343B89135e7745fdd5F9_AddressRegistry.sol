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

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IAddressRegistry} from "./interfaces/IAddressRegistry.sol";

contract AddressRegistry is IAddressRegistry, Ownable {
    address private coreAddr;
    address private uniswapRouterAddr;
    address private stakingAddr;
    address private immutable MATE;

    event CoreAddressUpdated(address prevAddr, address newAddr);
    event StakingAddressUpdated(address prevAddr, address newAddr);
    event UniswapRouterAddressUpdated(address prevAddr, address newAddr);

    constructor(address _tokenAddr, address _uniswapRouterAddr) {
        MATE = _tokenAddr;
        uniswapRouterAddr = _uniswapRouterAddr;
    }

    function getUniswapRouterAddr() external view override returns (address) {
        return uniswapRouterAddr;
    }

    function setUniswapRouterAddr(address _newAddr) external onlyOwner {
        require(_newAddr != address(0), "Invalid address");

        emit UniswapRouterAddressUpdated(uniswapRouterAddr, _newAddr);
        uniswapRouterAddr = _newAddr;
    }

    function getCoreAddr() external view override returns (address) {
        return coreAddr;
    }

    function setCoreAddr(address _newAddr) external onlyOwner {
        require(_newAddr != address(0), "Invalid address");

        emit CoreAddressUpdated(coreAddr, _newAddr);
        coreAddr = _newAddr;
    }

    function getStakingAddr() external view override returns (address) {
        return stakingAddr;
    }

    function setStakingAddr(address _newAddr) external onlyOwner {
        require(_newAddr != address(0), "Invalid address");

        emit StakingAddressUpdated(stakingAddr, _newAddr);
        stakingAddr = _newAddr;
    }

    function getTokenAddr() external view override returns (address) {
        return MATE;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IAddressRegistry {
    function getCoreAddr() external view returns (address);

    function getStakingAddr() external view returns (address);

    function getTokenAddr() external view returns (address);

    function getUniswapRouterAddr() external view returns (address);
}

