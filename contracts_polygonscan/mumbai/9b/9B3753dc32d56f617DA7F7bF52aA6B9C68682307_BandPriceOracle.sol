pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IPriceOracle} from "./interfaces/IPriceOracle.sol";
import {IStdReference} from "./interfaces/IStdReference.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title BandPriceOracle contract
 * @notice Implements the actions of the BandPriceOracle
 * @dev Exposes a method to set the Band oracle request packet corresponding to a ERC20 asset address
 * as well as a method to query the latest price of an asset from Band's bridge
 * @author Alpha
 */

contract BandPriceOracle is IPriceOracle, Ownable {
  /**
  @notice BandChain's BridgeWithCache interface
  **/
  IStdReference ref;

  /**
  @notice Mapping between asset address and token pair strings
  **/
  mapping(address => string[2]) public tokenToPair;

  /**
   * @notice Contract constructor
   * @dev Initializes a new BandPriceOracle instance.
   * @param _ref Band's StdReference contract
   **/
  constructor(IStdReference _ref) public {
    ref = _ref;
  }

  /**
   * @notice Sets the mapping between an asset address and the corresponding Band's Bridge RequestPacket struct
   * @param _asset The token address the asset
   * @param _pair The symbol pair associated with _asset
   **/
  function setTokenPairMap(address _asset, string[2] memory _pair) public onlyOwner {
    tokenToPair[_asset] = _pair;
  }

  /**
   * @notice Returns the latest price of an asset given the asset's address
   * @dev The function uses `tokenToPair` to get the symbol string pair associated with the input `_asset``
   * It then uses that the pair string as a parameter to Band's StdReference contract's `getReferenceData` method to get * the latest price of the asset.
   * @param _asset The asset address
   **/
  function getAssetPrice(address _asset) external override view returns (uint256) {
    string[2] memory pair = tokenToPair[_asset];

    IStdReference.ReferenceData memory rate = ref.getReferenceData(pair[0], pair[1]);
    return rate.rate;
  }
}

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

interface IStdReference {
    /// A structure returned whenever someone requests for standard reference data.
    struct ReferenceData {
        uint256 rate; // base/quote exchange rate, multiplied by 1e18.
        uint256 lastUpdatedBase; // UNIX epoch of the last time when base price gets updated.
        uint256 lastUpdatedQuote; // UNIX epoch of the last time when quote price gets updated.
    }

    /// Returns the price data for the given base/quote pair. Revert if not available.
    function getReferenceData(string memory _base, string memory _quote)
        external
        view
        returns (ReferenceData memory);

    /// Similar to getReferenceData, but with multiple base/quote pairs at once.
    function getRefenceDataBulk(string[] memory _bases, string[] memory _quotes)
        external
        view
        returns (ReferenceData[] memory);
}

pragma solidity 0.6.11;

/**
 * @title Price oracle interface
 * @notice The interface for the price oracle contract.
 * @author Alpha
 **/

interface IPriceOracle {
  /**
   * @notice Returns the latest price of an asset given the asset's address
   * @param _asset the address of asset to get the price (price per unit with 9 decimals)
   * @return price per unit
   **/
  function getAssetPrice(address _asset) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../GSN/Context.sol";
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
contract Ownable is Context {
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
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}