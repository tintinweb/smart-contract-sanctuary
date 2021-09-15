/**
 *Submitted for verification at Etherscan.io on 2021-09-15
*/

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

abstract contract Claimable is Context {
  address private _owner;
  address public pendingOwner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  event NewPendingOwner(address indexed owner);

  constructor() {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  function owner() public view virtual returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(_msgSender() == owner(), "Ownable: caller is not the owner");
    _;
  }

  modifier onlyPendingOwner() {
    require(_msgSender() == pendingOwner);
    _;
  }

  function renounceOwnership() public virtual onlyOwner {
    emit OwnershipTransferred(owner(), address(0));
    _owner = address(0);
  }

  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(pendingOwner == address(0));
    pendingOwner = newOwner;
    emit NewPendingOwner(newOwner);
  }

  function cancelTransferOwnership() public onlyOwner {
    require(pendingOwner != address(0));
    delete pendingOwner;
    emit NewPendingOwner(address(0));
  }

  function claimOwnership() public onlyPendingOwner {
    emit OwnershipTransferred(owner(), pendingOwner);
    _owner = pendingOwner;
    delete pendingOwner;
  }
}

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

interface IFujiOracle {
  function getPriceOf(
    address _collateralAsset,
    address _borrowAsset,
    uint8 _decimals
  ) external view returns (uint256);
}

/**
 * @title Errors library
 * @author Fuji
 * @notice Defines the error messages emitted by the different contracts of the Aave protocol
 * @dev Error messages prefix glossary:
 *  - VL = Validation Logic 100 series
 *  - MATH = Math libraries 200 series
 *  - RF = Refinancing 300 series
 *  - VLT = vault 400 series
 *  - SP = Special 900 series
 */
library Errors {
  //Errors
  string public constant VL_INDEX_OVERFLOW = "100"; // index overflows uint128
  string public constant VL_INVALID_MINT_AMOUNT = "101"; //invalid amount to mint
  string public constant VL_INVALID_BURN_AMOUNT = "102"; //invalid amount to burn
  string public constant VL_AMOUNT_ERROR = "103"; //Input value >0, and for ETH msg.value and amount shall match
  string public constant VL_INVALID_WITHDRAW_AMOUNT = "104"; //Withdraw amount exceeds provided collateral, or falls undercollaterized
  string public constant VL_INVALID_BORROW_AMOUNT = "105"; //Borrow amount does not meet collaterization
  string public constant VL_NO_DEBT_TO_PAYBACK = "106"; //Msg sender has no debt amount to be payback
  string public constant VL_MISSING_ERC20_ALLOWANCE = "107"; //Msg sender has not approved ERC20 full amount to transfer
  string public constant VL_USER_NOT_LIQUIDATABLE = "108"; //User debt position is not liquidatable
  string public constant VL_DEBT_LESS_THAN_AMOUNT = "109"; //User debt is less than amount to partial close
  string public constant VL_PROVIDER_ALREADY_ADDED = "110"; // Provider is already added in Provider Array
  string public constant VL_NOT_AUTHORIZED = "111"; //Not authorized
  string public constant VL_INVALID_COLLATERAL = "112"; //There is no Collateral, or Collateral is not in active in vault
  string public constant VL_NO_ERC20_BALANCE = "113"; //User does not have ERC20 balance
  string public constant VL_INPUT_ERROR = "114"; //Check inputs. For ERC1155 batch functions, array sizes should match.
  string public constant VL_ASSET_EXISTS = "115"; //Asset intended to be added already exists in FujiERC1155
  string public constant VL_ZERO_ADDR_1155 = "116"; //ERC1155: balance/transfer for zero address
  string public constant VL_NOT_A_CONTRACT = "117"; //Address is not a contract.
  string public constant VL_INVALID_ASSETID_1155 = "118"; //ERC1155 Asset ID is invalid.
  string public constant VL_NO_ERC1155_BALANCE = "119"; //ERC1155: insufficient balance for transfer.
  string public constant VL_MISSING_ERC1155_APPROVAL = "120"; //ERC1155: transfer caller is not owner nor approved.
  string public constant VL_RECEIVER_REJECT_1155 = "121"; //ERC1155Receiver rejected tokens
  string public constant VL_RECEIVER_CONTRACT_NON_1155 = "122"; //ERC1155: transfer to non ERC1155Receiver implementer
  string public constant VL_OPTIMIZER_FEE_SMALL = "123"; //Fuji OptimizerFee has to be > 1 RAY (1e27)
  string public constant VL_UNDERCOLLATERIZED_ERROR = "124"; // Flashloan-Flashclose cannot be used when User's collateral is worth less than intended debt position to close.
  string public constant VL_MINIMUM_PAYBACK_ERROR = "125"; // Minimum Amount payback should be at least Fuji Optimizerfee accrued interest.
  string public constant VL_HARVESTING_FAILED = "126"; // Harvesting Function failed, check provided _farmProtocolNum or no claimable balance.
  string public constant VL_FLASHLOAN_FAILED = "127"; // Flashloan failed
  string public constant VL_ERC1155_NOT_TRANSFERABLE = "128"; // ERC1155: Not Transferable
  string public constant VL_SWAP_SLIPPAGE_LIMIT_EXCEED = "129"; // ERC1155: Not Transferable
  string public constant VL_ZERO_ADDR = "130"; // Zero Address

  string public constant MATH_DIVISION_BY_ZERO = "201";
  string public constant MATH_ADDITION_OVERFLOW = "202";
  string public constant MATH_MULTIPLICATION_OVERFLOW = "203";

  string public constant RF_INVALID_RATIO_VALUES = "301"; // Ratio Value provided is invalid, _ratioA/_ratioB <= 1, and > 0, or activeProvider borrowBalance = 0

  string public constant VLT_CALLER_MUST_BE_VAULT = "401"; // The caller of this function must be a vault

  string public constant ORACLE_INVALID_LENGTH = "501"; // The assets length and price feeds length doesn't match
  string public constant ORACLE_NONE_PRICE_FEED = "502"; // The price feed is not found
}


contract FujiOracle is IFujiOracle, Claimable {
  // mapping from asset address to its price feed oracle in USD - decimals: 8
  mapping(address => address) public usdPriceFeeds;

  constructor(address[] memory _assets, address[] memory _priceFeeds) Claimable() {
    require(_assets.length == _priceFeeds.length, Errors.ORACLE_INVALID_LENGTH);
    for (uint256 i = 0; i < _assets.length; i++) {
      usdPriceFeeds[_assets[i]] = _priceFeeds[i];
    }
  }

  function setPriceFeed(address _asset, address _priceFeed) public onlyOwner {
    usdPriceFeeds[_asset] = _priceFeed;
  }

  /// @dev Calculates the exchange rate n given decimals (_borrowAsset / _collateralAsset Exchange Rate)
  /// @param _collateralAsset the collateral asset, zero-address for USD
  /// @param _borrowAsset the borrow asset, zero-address for USD
  /// @param _decimals the decimals of the price output
  /// @return price The exchange rate of the given assets pair
  function getPriceOf(
    address _collateralAsset,
    address _borrowAsset,
    uint8 _decimals
  ) external view override returns (uint256 price) {
    price = 10**uint256(_decimals);

    if (_borrowAsset != address(0)) {
      price = price * _getUSDPrice(_borrowAsset);
    } else {
      price = price * (10**8);
    }

    if (_collateralAsset != address(0)) {
      price = price / _getUSDPrice(_collateralAsset);
    } else {
      price = price / (10**8);
    }
  }

  /// @dev Calculates the USD price of asset
  /// @param _asset the asset address
  /// @return price USD price of the give asset
  function _getUSDPrice(address _asset) internal view returns (uint256 price) {
    require(usdPriceFeeds[_asset] != address(0), Errors.ORACLE_NONE_PRICE_FEED);

    (, int256 latestPrice, , , ) = AggregatorV3Interface(usdPriceFeeds[_asset]).latestRoundData();

    price = uint256(latestPrice);
  }
}