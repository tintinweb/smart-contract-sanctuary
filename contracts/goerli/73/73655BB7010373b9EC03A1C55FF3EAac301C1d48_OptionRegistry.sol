// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { Ownable } from "../openzeppelin/access/Ownable.sol";
import { Clones } from "../openzeppelin/proxy/Clones.sol";

import { DataTypes } from "../libraries/DataTypes.sol";

import { IOptionToken } from "../interfaces/core/IOptionToken.sol";

/**
 * @author Tesseract Labs
 * @title Option Registry
 */
contract OptionRegistry is Ownable {
    using Clones for address;

    /* ============ Immutables ============ */
    // Address where OptionToken contract logic is stored. Used for deploying the minimal proxies
    address public immutable optionTokenLogic;

    /* ============ State Variables ============ */

    // Mapping of individual option protocol implementations
    mapping(address => bool) public implementations;

    // A mapping of approved assets. Set by owner / governance
    mapping(address => DataTypes.Asset) public assets;

    // A mapping of created option series
    mapping(bytes32 => address) public options;

    // A mapping of option status
    mapping(address => bool) public isOption;

    constructor(address optionLogic) {
        require(optionLogic != address(0x0), "OptionRegistry::zero-addr");
        
        optionTokenLogic = optionLogic;
    }

    /* ============ Events ============ */

    /**
     @notice Emitted when a new option series is created
     @param series Address of the aggregated option contract
     */
    event NewSeries(address indexed series, address underlying, uint64 expiry, uint256 strikePrice, bool isCall);

    /**
     @notice Emitted when a new option protocol implementation is approved
     @param impl Address of the approved implementation
     */
    event NewImplementation(address indexed impl);

    /**
     @notice Emitted when a new option protocol implementation is remove
     @param impl Address of the removed implementation
     */
    event RemoveImplementation(address indexed impl);

    /* ============ Stateful Methods ============ */

    /**
     @notice Create a new option series given by the data
     @param data A struct defining the option details. Check libraries/DataTypes.
     */
    function createSeries(
        DataTypes.Option memory data
    ) external onlyOwner returns (address) {
        // Check if all the implementations are valid
        for (uint256 i = 0; i < data.impls.length; i++) {
            require(implementations[data.impls[i]], "OptionRegistry::impl-not-valid");
        }

        // For call option, both underlying and collateral should be the same
        if (data.isCall) {
            require(data.collateral == data.underlying, "OptionRegistry::asset-eq-coll");
        }

        // Both underlying and collateral should be whitelisted
        require(assets[data.collateral].isActive, "OptionRegistry::coll-not-valid");
        require(assets[data.underlying].isActive, "OptionRegistry::asset-not-valid");

        DataTypes.Asset memory underlyingAsset = assets[data.underlying];

        // Deploy Minimal proxy of the OptionToken and initialize it
        bytes32 salt = keccak256(abi.encode(data.expiry, data.isCall, data.strikePrice, data.collateral, data.underlying));
        address optionToken = optionTokenLogic.cloneDeterministic(salt);

        options[salt] = optionToken;
        isOption[optionToken] = true;

        IOptionToken(optionToken).initialize(underlyingAsset.name, underlyingAsset.symbol, data);

        emit NewSeries(optionToken, data.underlying, data.expiry, data.strikePrice, data.isCall);

        return optionToken;
    }

    /**
     @notice Approve a new option protocol implementation
     @param impl Address of the option protocol implementation
     */
    function addImplementation(address impl) external onlyOwner {
        // Ensure that the implementation is not already approved
        require(!implementations[impl], "OptionRegistry::fail");

        // Approve the implementation
        implementations[impl] = true;

        emit NewImplementation(impl);
    }

    /**
     @notice Remove an already approved option protocol implementation
     @param impl Address of the option protocol implementation
     */
    function removeImplementation(address impl) external onlyOwner {
        // Check if the implementation is approved
        require(implementations[impl], "OptionRegistry::fail");

        // Remove the implementation
        implementations[impl] = false;

        emit RemoveImplementation(impl);
    }

    /**
     * @notice Method to approve an asset
     * @param asset Address of the asset
     * @param name Asset name
     * @param symbol Asset symbol
     */
    function approveAsset(address asset, string memory name, string memory symbol) external onlyOwner {
        require(bytes(name).length != 0, "OptionRegistry::invalid-name");
        require(bytes(symbol).length != 0, "OptionRegistry::invalid-symbol");

        assets[asset] = DataTypes.Asset({
            isActive: true,
            name: name,
            symbol: symbol
        });
    }

    /**
     * @notice Method to remove a token from approved assets
     * @param asset Address of the asset
     */
    function removeAsset(address asset) external onlyOwner {
        require(assets[asset].isActive, "OptionRegistry::not-approved");
        
        DataTypes.Asset storage assetData = assets[asset];
        assetData.isActive = false;
    }

    /**
     @notice Get option address based option specification
     @param data Option Specification. Check DataTypes.Option
     @return optionToken Address of the token
     @return hasDeployed Whether the option has been deployed
     */
    function getOptionAddress(DataTypes.Option memory data) external view returns (address optionToken, bool hasDeployed) {
        bytes32 salt = keccak256(abi.encode(data.expiry, data.isCall, data.strikePrice, data.collateral, data.underlying));
        optionToken = optionTokenLogic.predictDeterministicAddress(salt);
        hasDeployed = isOption[optionToken];
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

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library DataTypes {
    // Asset specification
    struct Asset {
        bool isActive; // Whether the asset is active or not
        string name; // Name of the asset
        string symbol; // Symbol of the asset
    }

    // Option specification with implementations
    struct Option {
        uint64 expiry; // Expiry timestamp of the option
        bool isCall; // Whether the option is call or put
        uint256 strikePrice; // Strike price in 8 decimals
        address collateral; // Address of the collateral
        address underlying; // Address of the underlying
        address[] impls; // Array of valid implementations
    }

    // Option specification
    struct OptionData {
        uint64 expiry; // Expiry timestamp of the option
        bool isCall; // Whether the option is call or put
        uint256 strikePrice; // Strike price in 8 decimals
        address collateral; // Address of the collateral
        address underlying; // Address of the underlying
    }

    enum TokenType {
        ERC20,
        ERC721,
        ERC1155,
        None
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { DataTypes } from "../../libraries/DataTypes.sol";

interface IOptionToken {
    function initialize(
        string memory underlyingName,
        string memory underlyingSymbol,
        DataTypes.Option memory optionData
    ) external;

    function data() external view returns (DataTypes.OptionData memory);
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