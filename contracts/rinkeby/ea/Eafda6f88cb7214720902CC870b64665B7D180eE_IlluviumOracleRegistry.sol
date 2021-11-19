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

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/OracleRegistry.sol";

/**
 * @title Oracle Registry
 *
 * @notice To make pair oracles more convenient to use, a more generic Oracle Registry
 *        interface is introduced: it stores the addresses of pair price oracles and allows
 *        searching/querying for them
 */

contract IlluviumOracleRegistry is OracleRegistry, Ownable {
    event OracleRegistered(address indexed token0, address indexed token1, address indexed oracle);
    event OracleRemoved(address indexed token0, address indexed token1);

    /// @dev token0 => token1 => oracle
    mapping(address => mapping(address => address)) private oracles;

    /**
     * @notice register oracle for token pair (token0, token1)
     * @param token0 first token address
     * @param token1 second token address
     * @param oracle oracle address for token pair
     */
    function registerOracle(
        address token0,
        address token1,
        address oracle
    ) external onlyOwner {
        require(oracle != address(0), "oracle cannot be zero");
        require(token0 != token1, "invalid tokens");
        oracles[token0][token1] = oracle;
        oracles[token1][token0] = oracle;

        emit OracleRegistered(token0, token1, oracle);
    }

    /**
     * @notice remove oracle for token pair (token0, token1)
     * @param token0 first token address
     * @param token1 second token address
     */
    function removeOracle(address token0, address token1) external onlyOwner {
        require(oracles[token0][token1] != address(0), "oracle not exist");
        delete oracles[token0][token1];
        delete oracles[token1][token0];

        emit OracleRemoved(token0, token1);
    }

    /**
     * @notice Searches for the Pair Price Oracle for A/B (sell/buy) token pair
     *
     * @param tokenA token A (token to sell) address
     * @param tokenB token B (token to buy) address
     * @return pairOracle pair price oracle address for A/B token pair
     */
    function getOracle(address tokenA, address tokenB) external view override returns (address) {
        return oracles[tokenA][tokenB];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/**
 * @title Oracle Registry interface
 *
 * @notice To make pair oracles more convenient to use, a more generic Oracle Registry
 *        interface is introduced: it stores the addresses of pair price oracles and allows
 *        searching/querying for them
 */

interface OracleRegistry {
    /**
     * @notice Searches for the Pair Price Oracle for A/B (sell/buy) token pair
     *
     * @param tokenA token A (token to sell) address
     * @param tokenB token B (token to buy) address
     * @return pairOracle pair price oracle address for A/B token pair
     */
    function getOracle(address tokenA, address tokenB) external view returns (address pairOracle);
}