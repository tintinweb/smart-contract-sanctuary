// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./interfaces/ITokenVesting.sol";
import "./interfaces/ITokenVestingFactory.sol";
import "./interfaces/ITokenVestingRouter.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenVestingRouter is ITokenVestingRouter, Ownable {
    ITokenVestingFactory internal _tokenVestingFactory;
    mapping(address => address) internal _tokenToTokenVesting;
    mapping(uint256 => address) internal _idToToken;
    uint256 internal _nextId = 1;

    constructor(address tokenVestingFactory_) {
        _tokenVestingFactory = ITokenVestingFactory(tokenVestingFactory_);
    }

    function tokenVestingFactory() external view override returns(address) {
        return address(_tokenVestingFactory);
    }

    function setTokenVestingFactory(address tokenVestingFactory_) external override onlyOwner {
        require(tokenVestingFactory_ != address(0));
        _tokenVestingFactory = ITokenVestingFactory(tokenVestingFactory_);
    }

    function createTokenVesting(address token) external override returns(address) {
        require(token != address(0));
        require(_tokenToTokenVesting[token] == address(0));
        address tokenVesting = _tokenVestingFactory.deployTokenVesting(
            token,
            address(this),
            owner()
        );
        _tokenToTokenVesting[token] = tokenVesting;
        _idToToken[_nextId] = token;
        _nextId++;
        return tokenVesting;
    }

    function tokenVestingOf(address token) external view override returns(address) {
        return _tokenToTokenVesting[token];
    }

    function tokenVestingAt(uint256 id) external view override returns(address) {
        require(id > 0);
        return _tokenToTokenVesting[_idToToken[id]];
    }

    function tokenVestingsCount() external view override returns(uint256) {
        return _nextId - 1;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface ITokenVesting {
    function depositAndConfigureVesting(
        uint256[] memory timestamps, 
        uint256[] memory amounts, 
        address investor
    ) external;

    function router() external view returns(address);

    function token() external view returns(address);

    function claim() external;

    function breakExpiredLocksOf(address investor) external;

    function claimableAmountOf(address investor) external view returns(uint256);

    function detailedLocksOf(address investor) external view returns(uint256[] memory, uint256[] memory);

    function lockedAmountOf(address investor) external view returns(uint256);

    function totalDepositsOf(address investor) external view returns(uint256);

    function totalClaimsOf(address investor) external view returns(uint256);

    event ConfiguredVesting(address indexed investor, uint256[] timestamps, uint256[] amounts);

    event Claimed(address indexed investor, uint256 amount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface ITokenVestingFactory {
    function deployTokenVesting(address token, address router, address owner) external returns (address);

    function initialize(address router_) external;
    function router() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface ITokenVestingRouter {
    function createTokenVesting(address token) external returns (address);

    function tokenVestingOf(address token) external view returns (address);

    function tokenVestingAt(uint256 id) external view returns (address);

    function tokenVestingsCount() external view returns (uint256);

    function tokenVestingFactory() external view returns (address);

    function setTokenVestingFactory(address factory) external;
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