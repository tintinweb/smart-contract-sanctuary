// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "../libraries/TransferHelper.sol";
import "../libraries/SymbolHelper.sol";
import "../interfaces/IERC20Metadata.sol";
import "../interfaces/IERC20.sol";


abstract contract AbstractErc20Adapter {
  using SymbolHelper for address;
  using TransferHelper for address;

/* ========== Storage ========== */

  address public underlying;
  address public token;

/* ========== Initializer ========== */

  function initialize(address _underlying, address _token) public virtual {
    require(underlying == address(0) && token == address(0), "initialized");
    require(_underlying != address(0) && _token != address(0), "bad address");
    underlying = _underlying;
    token = _token;
    _approve();
  }

/* ========== Internal Queries ========== */

  function _protocolName() internal view virtual returns (string memory);

/* ========== Metadata ========== */

  function name() external view virtual returns (string memory) {
    return string(abi.encodePacked(
      bytes(_protocolName()),
      " ",
      bytes(underlying.getSymbol()),
      " Adapter"
    ));
  }

  function availableLiquidity() public view virtual returns (uint256);

/* ========== Conversion Queries ========== */

  function toUnderlyingAmount(uint256 tokenAmount) external view virtual returns (uint256);

  function toWrappedAmount(uint256 underlyingAmount) external view virtual returns (uint256);

/* ========== Performance Queries ========== */

  function getAPR() public view virtual returns (uint256);

  function getHypotheticalAPR(int256 _deposit) external view virtual returns (uint256);

  function getRevenueBreakdown()
    external
    view
    virtual
    returns (
      address[] memory assets,
      uint256[] memory aprs
    )
  {
    assets = new address[](1);
    aprs = new uint256[](1);
    assets[0] = underlying;
    aprs[0] = getAPR();
  }

/* ========== Caller Balance Queries ========== */

  function balanceWrapped() public view virtual returns (uint256) {
    return IERC20(token).balanceOf(msg.sender);
  }

  function balanceUnderlying() external view virtual returns (uint256);

/* ========== Token Actions ========== */

  function deposit(uint256 amountUnderlying) external virtual returns (uint256 amountMinted) {
    require(amountUnderlying > 0, "deposit 0");
    underlying.safeTransferFrom(msg.sender, address(this), amountUnderlying);
    amountMinted = _mint(amountUnderlying);
    token.safeTransfer(msg.sender, amountMinted);
  }

  function withdraw(uint256 amountToken) public virtual returns (uint256 amountReceived) {
    require(amountToken > 0, "withdraw 0");
    token.safeTransferFrom(msg.sender, address(this), amountToken);
    amountReceived = _burn(amountToken);
    underlying.safeTransfer(msg.sender, amountReceived);
  }

  function withdrawAll() public virtual returns (uint256 amountReceived) {
    return withdraw(balanceWrapped());
  }

  function withdrawUnderlying(uint256 amountUnderlying) external virtual returns (uint256 amountBurned) {
    require(amountUnderlying > 0, "withdraw 0");
    amountBurned = _burnUnderlying(amountUnderlying);
    underlying.safeTransfer(msg.sender, amountUnderlying);
  }

  function withdrawUnderlyingUpTo(uint256 amountUnderlying) external virtual returns (uint256 amountReceived) {
    require(amountUnderlying > 0, "withdraw 0");
    uint256 amountAvailable = availableLiquidity();
    amountReceived = amountAvailable < amountUnderlying ? amountAvailable : amountUnderlying;
    _burnUnderlying(amountReceived);
    underlying.safeTransfer(msg.sender, amountReceived);
  }

/* ========== Internal Actions ========== */

  function _approve() internal virtual;

  /**
   * @dev Deposit `amountUnderlying` into the wrapper and return the amount of wrapped tokens received.
   * Note:
   * - Called after the underlying token is transferred.
   * - Should not transfer minted token to caller.
   */
  function _mint(uint256 amountUnderlying) internal virtual returns (uint256 amountMinted);

  /**
   * @dev Burn `amountToken` of `token` and return the amount of `underlying` received.
   * Note:
   * - Called after the wrapper token is transferred.
   * - Should not transfer underlying token to caller.
   */
  function _burn(uint256 amountToken) internal virtual returns (uint256 amountReceived);

  /**
   * @dev Redeem `amountUnderlying` of the underlying token and return the amount of wrapper tokens burned.
   * Note:
   * - Should transfer the wrapper token from the caller.
   * - Should not transfer underlying token to caller.
   */
  function _burnUnderlying(uint256 amountUnderlying) internal virtual returns (uint256 amountBurned);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "../libraries/TransferHelper.sol";
import "../interfaces/IERC20Metadata.sol";
import "../interfaces/IERC20.sol";
import "./AbstractErc20Adapter.sol";


abstract contract AbstractEtherAdapter is AbstractErc20Adapter {
  using TransferHelper for address;

/* ========== Metadata ========== */

  function name() external view virtual override returns (string memory) {
    return string(abi.encodePacked(
      bytes(_protocolName()),
      " ETH Adapter"
    ));
  }

/* ========== Fallback ========== */

  fallback() external payable { return; }

  receive() external payable { return; }

/* ========== Token Actions ========== */

  function deposit(uint256 amountUnderlying)
    external
    virtual
    override
    returns (uint256 amountMinted)
  {
    underlying.safeTransferFrom(msg.sender, address(this), amountUnderlying);
    _afterReceiveWETH(amountUnderlying);
    amountMinted = _mint(amountUnderlying);
    token.safeTransfer(msg.sender, amountMinted);
  }

  function depositETH() external virtual payable returns (uint256 amountMinted) {
    _afterReceiveETH(msg.value);
    amountMinted = _mint(msg.value);
    token.safeTransfer(msg.sender, amountMinted);
  }

  function withdraw(uint256 amountToken) public virtual override returns (uint256 amountReceived) {
    token.safeTransferFrom(msg.sender, address(this), amountToken);
    amountReceived = _burn(amountToken);
    _beforeSendWETH(amountReceived);
    underlying.safeTransfer(msg.sender, amountReceived);
  }

  function withdrawAsETH(uint256 amountToken) public virtual returns (uint256 amountReceived) {
    token.safeTransferFrom(msg.sender, address(this), amountToken);
    amountReceived = _burn(amountToken);
    _beforeSendETH(amountReceived);
    address(msg.sender).safeTransferETH(amountReceived);
  }

  function withdrawAllAsETH() public virtual returns (uint256 amountReceived) {
    return withdrawAsETH(balanceWrapped());
  }

  function withdrawUnderlying(uint256 amountUnderlying) external virtual override returns (uint256 amountBurned) {
    amountBurned = _burnUnderlying(amountUnderlying);
    _beforeSendWETH(amountUnderlying);
    underlying.safeTransfer(msg.sender, amountUnderlying);
  }

  function withdrawUnderlyingAsETH(uint256 amountUnderlying) external virtual returns (uint256 amountBurned) {
    amountBurned = _burnUnderlying(amountUnderlying);
    _beforeSendETH(amountUnderlying);
    address(msg.sender).safeTransferETH(amountUnderlying);
  }

  function withdrawUnderlyingUpTo(uint256 amountUnderlying) external virtual override returns (uint256 amountReceived) {
    require(amountUnderlying > 0, "withdraw 0");
    uint256 amountAvailable = availableLiquidity();
    amountReceived = amountAvailable < amountUnderlying ? amountAvailable : amountUnderlying;
    _burnUnderlying(amountReceived);
    _beforeSendWETH(amountReceived);
    underlying.safeTransfer(msg.sender, amountReceived);
  }

/* ========== Internal Ether Handlers ========== */
  
  // Convert to WETH if contract takes WETH
  function _afterReceiveETH(uint256 amount) internal virtual;

  // Convert to WETH if contract takes ETH
  function _afterReceiveWETH(uint256 amount) internal virtual;

  // Convert to ETH if contract returns WETH
  function _beforeSendETH(uint256 amount) internal virtual;

  // Convert to WETH if contract returns ETH
  function _beforeSendWETH(uint256 amount) internal virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "../AbstractErc20Adapter.sol";
import "../../interfaces/CompoundInterfaces.sol";
import "../../interfaces/IERC20.sol";
import "../../interfaces/IWETH.sol";
import "../../libraries/LowGasSafeMath.sol";
import "../../libraries/TransferHelper.sol";
import "../../libraries/MinimalSignedMath.sol";
import { CTokenParams } from "../../libraries/CTokenParams.sol";


contract CrErc20Adapter is AbstractErc20Adapter() {
  using MinimalSignedMath for uint256;
  using LowGasSafeMath for uint256;
  using TransferHelper for address;

/* ========== Internal Queries ========== */

  function _protocolName() internal view virtual override returns (string memory) {
    return "Cream";
  }

/* ========== Metadata ========== */

  function availableLiquidity() public view override returns (uint256) {
    return IERC20(underlying).balanceOf(token);
  }

/* ========== Conversion Queries ========== */

  function toUnderlyingAmount(uint256 tokenAmount) public view override returns (uint256) {
    return (
      tokenAmount
      .mul(CTokenParams.currentExchangeRate(token))
      / uint256(1e18)
    );
  }

  function toWrappedAmount(uint256 underlyingAmount) public view override returns (uint256) {
    return underlyingAmount
      .mul(1e18)
      / CTokenParams.currentExchangeRate(token);
  }

/* ========== Performance Queries ========== */

  function getAPR() public view virtual override returns (uint256) {
    return ICToken(token).supplyRatePerBlock().mul(2102400);
  }

  function getHypotheticalAPR(int256 liquidityDelta) external view virtual override returns (uint256) {
    ICToken cToken = ICToken(token);
    (
      address model,
      uint256 cashPrior,
      uint256 borrowsPrior,
      uint256 reservesPrior,
      uint256 reserveFactorMantissa
    ) = CTokenParams.getInterestRateParameters(address(cToken));
    return IInterestRateModel(model).getSupplyRate(
      cashPrior.add(liquidityDelta),
      borrowsPrior,
      reservesPrior,
      reserveFactorMantissa
    ).mul(2102400);
  }

/* ========== Caller Balance Queries ========== */

  function balanceUnderlying() external view virtual override returns (uint256) {
    return toUnderlyingAmount(ICToken(token).balanceOf(msg.sender));
  }

/* ========== Internal Actions ========== */

  function _approve() internal virtual override {
    underlying.safeApproveMax(token);
  }

  function _mint(uint256 amountUnderlying) internal virtual override returns (uint256 amountMinted) {
    address _token = token;
    require(ICToken(_token).mint(amountUnderlying) == 0, "CrErc20: Mint failed");
    amountMinted = IERC20(_token).balanceOf(address(this));
  }

  function _burn(uint256 amountToken) internal virtual override returns (uint256 amountReceived) {
    require(ICToken(token).redeem(amountToken) == 0, "CrErc20: Burn failed");
    amountReceived = IERC20(underlying).balanceOf(address(this));
  }

  function _burnUnderlying(uint256 amountUnderlying) internal virtual override returns (uint256 amountBurned) {
    amountBurned = toWrappedAmount(amountUnderlying);
    token.safeTransferFrom(msg.sender, address(this), amountBurned);
    require(ICToken(token).redeemUnderlying(amountUnderlying) == 0, "CrErc20: Burn failed");
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "../AbstractEtherAdapter.sol";
import "../../interfaces/CompoundInterfaces.sol";
import "../../interfaces/IERC20.sol";
import "../../interfaces/IWETH.sol";
import "../../libraries/LowGasSafeMath.sol";
import "../../libraries/TransferHelper.sol";
import "../../libraries/MinimalSignedMath.sol";
import { CTokenParams } from "../../libraries/CTokenParams.sol";


contract CrEtherAdapter is AbstractEtherAdapter() {
  using MinimalSignedMath for uint256;
  using LowGasSafeMath for uint256;
  using TransferHelper for address;

/* ========== Internal Queries ========== */

  function _protocolName() internal view virtual override returns (string memory) {
    return "Cream";
  }

/* ========== Metadata ========== */

  function availableLiquidity() public view override returns (uint256) {
    return address(token).balance;
  }

/* ========== Conversion Queries ========== */

  function toUnderlyingAmount(uint256 tokenAmount) public view override returns (uint256) {
    return (
      tokenAmount
      .mul(CTokenParams.currentExchangeRate(token))
      / uint256(1e18)
    );
  }

  function toWrappedAmount(uint256 underlyingAmount) public view override returns (uint256) {
    return underlyingAmount
      .mul(1e18)
      / CTokenParams.currentExchangeRate(token);
  }

/* ========== Performance Queries ========== */

  function getAPR() public view virtual override returns (uint256) {
    return ICToken(token).supplyRatePerBlock().mul(2102400);
  }

  function getHypotheticalAPR(int256 liquidityDelta) external view virtual override returns (uint256) {
    ICToken cToken = ICToken(token);
    (
      address model,
      uint256 cashPrior,
      uint256 borrowsPrior,
      uint256 reservesPrior,
      uint256 reserveFactorMantissa
    ) = CTokenParams.getInterestRateParameters(address(cToken));
    return IInterestRateModel(model).getSupplyRate(
      cashPrior.add(liquidityDelta),
      borrowsPrior,
      reservesPrior,
      reserveFactorMantissa
    ).mul(2102400);
  }

/* ========== Caller Balance Queries ========== */

  function balanceUnderlying() external view virtual override returns (uint256) {
    return toUnderlyingAmount(ICToken(token).balanceOf(msg.sender));
  }

/* ========== Internal Ether Handlers ========== */
  
  // Convert to WETH if contract takes WETH
  function _afterReceiveETH(uint256 amount) internal virtual override {}

  // Convert to WETH if contract takes ETH
  function _afterReceiveWETH(uint256 amount) internal virtual override {
    IWETH(underlying).withdraw(amount);
  }

  // Convert to ETH if contract returns WETH
  function _beforeSendETH(uint256 amount) internal virtual override {}

  // Convert to WETH if contract returns ETH
  function _beforeSendWETH(uint256 amount) internal virtual override {
    IWETH(underlying).deposit{value: amount}();
  }

/* ========== Internal Actions ========== */

  function _approve() internal virtual override {}

  function _mint(uint256 amountUnderlying) internal virtual override returns (uint256 amountMinted) {
    address _token = token;
    ICToken(_token).mint{value: amountUnderlying}();
    amountMinted = IERC20(_token).balanceOf(address(this));
  }

  function _burn(uint256 amountToken) internal virtual override returns (uint256 amountReceived) {
    require(ICToken(token).redeem(amountToken) == 0, "CEther: Burn failed");
    amountReceived = address(this).balance;
  }

  function _burnUnderlying(uint256 amountUnderlying) internal virtual override returns (uint256 amountBurned) {
    amountBurned = toWrappedAmount(amountUnderlying);
    token.safeTransferFrom(msg.sender, address(this), amountBurned);
    require(ICToken(token).redeemUnderlying(amountUnderlying) == 0, "CEther: Burn failed");
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;
pragma abicoder v2;


interface ICToken {
  function comptroller() external view returns (address);
  function underlying() external view returns (address);
  function name() external view returns (string memory);
  function totalSupply() external view returns (uint256);

  function supplyRatePerBlock() external view returns (uint256);
  function borrowRatePerBlock() external view returns (uint256);

  function getCash() external view returns (uint256);
  function totalBorrows() external view returns (uint256);
  function totalReserves() external view returns (uint256);
  function reserveFactorMantissa() external view returns (uint256);
  function exchangeRateCurrent() external returns (uint256);
  function exchangeRateStored() external view returns (uint256);
  function accrualBlockNumber() external view returns (uint256);
  function borrowBalanceStored(address account) external view returns (uint);
  function interestRateModel() external view returns (IInterestRateModel);

  function balanceOf(address account) external view returns (uint256);
  function balanceOfUnderlying(address owner) external returns (uint);

  function mint(uint256 mintAmount) external returns (uint256);
  function mint() external payable;
  function redeem(uint256 tokenAmount) external returns (uint256);
  function redeemUnderlying(uint256 underlyingAmount) external returns (uint256);
  function borrow(uint borrowAmount) external returns (uint);

  // Used to check if a cream market is for an SLP token
  function sushi() external view returns (address);
}


interface IInterestRateModel {
  function getBorrowRate(
    uint cash,
    uint borrows,
    uint reserves
  ) external view returns (uint);

  function getSupplyRate(
    uint256 cash,
    uint256 borrows,
    uint256 reserves,
    uint256 reserveFactorMantissa
  ) external view returns (uint);
}


interface IComptroller {
  function admin() external view returns (address);
  function _setMintPaused(address cToken, bool state) external returns (bool);

  function getAllMarkets() external view returns (ICToken[] memory);
  function mintGuardianPaused(address cToken) external view returns (bool);
  function compSpeeds(address cToken) external view returns (uint256);
  function oracle() external view returns (IPriceOracle);
  function compAccrued(address) external view returns (uint);
  function markets(address cToken) external view returns (
    bool isListed,
    uint collateralFactorMantissa,
    bool isComped
  );
  function claimComp(address[] memory holders, address[] memory cTokens, bool borrowers, bool suppliers) external;
  function refreshCompSpeeds() external;
}


interface IPriceOracle {
  function getUnderlyingPrice(address cToken) external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;


interface IAdapterRegistry {
/* ========== Events ========== */

  event ProtocolAdapterAdded(uint256 protocolId, address protocolAdapter);

  event ProtocolAdapterRemoved(uint256 protocolId);

  event TokenAdapterAdded(address adapter, uint256 protocolId, address underlying, address wrapper);

  event TokenAdapterRemoved(address adapter, uint256 protocolId, address underlying, address wrapper);

  event TokenSupportAdded(address underlying);

  event TokenSupportRemoved(address underlying);

  event VaultFactoryAdded(address factory);

  event VaultFactoryRemoved(address factory);

  event VaultAdded(address underlying, address vault);

  event VaultRemoved(address underlying, address vault);

/* ========== Structs ========== */

  struct TokenAdapter {
    address adapter;
    uint96 protocolId;
  }

/* ========== Storage ========== */

  function protocolsCount() external view returns (uint256);

  function protocolAdapters(uint256 id) external view returns (address protocolAdapter);

  function protocolAdapterIds(address protocolAdapter) external view returns (uint256 id);

  function vaultsByUnderlying(address underlying) external view returns (address vault);

  function approvedVaultFactories(address factory) external view returns (bool approved);

/* ========== Vault Factory Management ========== */

  function addVaultFactory(address _factory) external;

  function removeVaultFactory(address _factory) external;

/* ========== Vault Management ========== */

  function addVault(address vault) external;

  function removeVault(address vault) external;

/* ========== Protocol Adapter Management ========== */

  function addProtocolAdapter(address protocolAdapter) external returns (uint256 id);

  function removeProtocolAdapter(address protocolAdapter) external;

/* ========== Token Adapter Management ========== */

  function addTokenAdapter(address adapter) external;

  function addTokenAdapters(address[] calldata adapters) external;

  function removeTokenAdapter(address adapter) external;

/* ========== Vault Queries ========== */

  function getVaultsList() external view returns (address[] memory);

  function haveVaultFor(address underlying) external view returns (bool);

/* ========== Protocol Queries ========== */

  function getProtocolAdaptersAndIds() external view returns (address[] memory adapters, uint256[] memory ids);

  function getProtocolMetadata(uint256 id) external view returns (address protocolAdapter, string memory name);

  function getProtocolForTokenAdapter(address adapter) external view returns (address protocolAdapter);

/* ========== Supported Token Queries ========== */

  function isSupported(address underlying) external view returns (bool);

  function getSupportedTokens() external view returns (address[] memory list);

/* ========== Token Adapter Queries ========== */

  function isApprovedAdapter(address adapter) external view returns (bool);

  function getAdaptersList(address underlying) external view returns (address[] memory list);

  function getAdapterForWrapperToken(address wrapperToken) external view returns (address);

  function getAdaptersCount(address underlying) external view returns (uint256);

  function getAdaptersSortedByAPR(address underlying)
    external
    view
    returns (address[] memory adapters, uint256[] memory aprs);

  function getAdaptersSortedByAPRWithDeposit(
    address underlying,
    uint256 deposit,
    address excludingAdapter
  )
    external
    view
    returns (address[] memory adapters, uint256[] memory aprs);

  function getAdapterWithHighestAPR(address underlying) external view returns (address adapter, uint256 apr);

  function getAdapterWithHighestAPRForDeposit(
    address underlying,
    uint256 deposit,
    address excludingAdapter
  ) external view returns (address adapter, uint256 apr);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;


interface IERC20 {
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  function totalSupply() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
  function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;


interface IERC20Metadata {
  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function decimals() external view returns (uint8);
}


interface IERC20MetadataBytes32 {
  function name() external view returns (bytes32);
  function symbol() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;


interface IErc20Adapter {
/* ========== Metadata ========== */

  function underlying() external view returns (address);

  function token() external view returns (address);

  function name() external view returns (string memory);

  function availableLiquidity() external view returns (uint256);

/* ========== Conversion ========== */

  function toUnderlyingAmount(uint256 tokenAmount) external view returns (uint256);

  function toWrappedAmount(uint256 underlyingAmount) external view returns (uint256);

/* ========== Performance Queries ========== */

  function getAPR() external view returns (uint256);

  function getHypotheticalAPR(int256 liquidityDelta) external view returns (uint256);

  function getRevenueBreakdown()
    external
    view
    returns (
      address[] memory assets,
      uint256[] memory aprs
    );

/* ========== Caller Balance Queries ========== */

  function balanceWrapped() external view returns (uint256);

  function balanceUnderlying() external view returns (uint256);

/* ========== Interactions ========== */

  function deposit(uint256 amountUnderlying) external returns (uint256 amountMinted);

  function withdraw(uint256 amountToken) external returns (uint256 amountReceived);

  function withdrawAll() external returns (uint256 amountReceived);

  function withdrawUnderlying(uint256 amountUnderlying) external returns (uint256 amountBurned);

  function withdrawUnderlyingUpTo(uint256 amountUnderlying) external returns (uint256 amountReceived);
}

interface IEtherAdapter is IErc20Adapter {
  function depositETH() external payable returns (uint256 amountMinted);

  function withdrawAsETH(uint256 amountToken) external returns (uint256 amountReceived);

  function withdrawAllAsETH() external returns (uint256 amountReceived);

  function withdrawUnderlyingAsETH(uint256 amountUnderlying) external returns (uint256 amountBurned); 
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;


interface IWETH {
  function deposit() external payable;
  function withdraw(uint) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0;

import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "../libraries/LowGasSafeMath.sol";
import "../interfaces/ITokenAdapter.sol";


library ArrayHelper {
  using EnumerableSet for EnumerableSet.AddressSet;
  using LowGasSafeMath for uint256;

/* ========== Type Cast ========== */

  /**
   * @dev Cast an enumerable address set as an address array.
   * The enumerable set library stores the values as a bytes32 array, this function
   * casts it as an address array with a pointer assignment.
   */
  function toArray(EnumerableSet.AddressSet storage set) internal view returns (address[] memory arr) {
    bytes32[] memory bytes32Arr = set._inner._values;
    assembly { arr := bytes32Arr }
  }

  /**
   * @dev Cast an array of IErc20Adapter to an array of address using a pointer assignment.
   * Note: The resulting array is the same as the original, so all changes to one will be
   * reflected in the other.
   */
  function toAddressArray(IErc20Adapter[] memory _arr) internal pure returns (address[] memory arr) {
    assembly { arr := _arr }
  }

/* ========== Math ========== */

  /**
   * @dev Computes the sum of a uint256 array.
   */
  function sum(uint256[] memory arr) internal pure returns (uint256 _sum) {
    uint256 len = arr.length;
    for (uint256 i; i < len; i++) _sum = _sum.add(arr[i]);
  }

/* ========== Removal ========== */

  /**
   * @dev Remove the element at `index` from an array and decrement its length.
   * If `index` is the last index in the array, pops it from the array.
   * Otherwise, stores the last element in the array at `index` and then pops the last element.
   */
  function mremove(uint256[] memory arr, uint256 index) internal pure {
    uint256 len = arr.length;
    if (index != len - 1) {
      uint256 last = arr[len - 1];
      arr[index] = last;
    }
    assembly { mstore(arr, sub(len, 1)) }
  }

  /**
   * @dev Remove the element at `index` from an array and decrement its length.
   * If `index` is the last index in the array, pops it from the array.
   * Otherwise, stores the last element in the array at `index` and then pops the last element.
   */
  function mremove(address[] memory arr, uint256 index) internal pure {
    uint256 len = arr.length;
    if (index != len - 1) {
      address last = arr[len - 1];
      arr[index] = last;
    }
    assembly { mstore(arr, sub(len, 1)) }
  }

  /**
   * @dev Remove the element at `index` from an array and decrement its length.
   * If `index` is the last index in the array, pops it from the array.
   * Otherwise, stores the last element in the array at `index` and then pops the last element.
   */
  function mremove(IErc20Adapter[] memory arr, uint256 index) internal pure {
    uint256 len = arr.length;
    if (index != len - 1) {
      IErc20Adapter last = arr[len - 1];
      arr[index] = last;
    }
    assembly { mstore(arr, sub(len, 1)) }
  }

  /**
   * @dev Remove the element at `index` from an array and decrement its length.
   * If `index` is the last index in the array, pops it from the array.
   * Otherwise, stores the last element in the array at `index` and then pops the last element.
   */
  function remove(bytes32[] storage arr, uint256 index) internal {
    uint256 len = arr.length;
    if (index == len - 1) {
      arr.pop();
      return;
    }
    bytes32 last = arr[len - 1];
    arr[index] = last;
    arr.pop();
  }

  /**
   * @dev Remove the element at `index` from an array and decrement its length.
   * If `index` is the last index in the array, pops it from the array.
   * Otherwise, stores the last element in the array at `index` and then pops the last element.
   */
  function remove(address[] storage arr, uint256 index) internal {
    uint256 len = arr.length;
    if (index == len - 1) {
      arr.pop();
      return;
    }
    address last = arr[len - 1];
    arr[index] = last;
    arr.pop();
  }

/* ========== Search ========== */

  /**
   * @dev Find the index of an address in an array.
   * If the address is not found, revert.
   */
  function indexOf(address[] memory arr, address find) internal pure returns (uint256) {
    uint256 len = arr.length;
    for (uint256 i; i < len; i++) if (arr[i] == find) return i;
    revert("element not found");
  }

  /**
   * @dev Determine whether an element is included in an array.
   */
  function includes(address[] memory arr, address find) internal pure returns (bool) {
    uint256 len = arr.length;
    for (uint256 i; i < len; i++) if (arr[i] == find) return true;
    return false;
  }

/* ========== Sorting ========== */

  /**
   * @dev Given an array of tokens and scores, sort by scores in descending order.
   * Maintains the relationship between elements of each array at the same index.
   */
  function sortByDescendingScore(
    address[] memory addresses,
    uint256[] memory scores
  ) internal pure {
    uint256 len = addresses.length;
    for (uint256 i = 0; i < len; i++) {
      uint256 score = scores[i];
      address _address = addresses[i];
      uint256 j = i - 1;
      while (int(j) >= 0 && scores[j] < score) {
        scores[j + 1] = scores[j];
        addresses[j + 1] = addresses[j];
        j--;
      }
      scores[j + 1] = score;
      addresses[j + 1] = _address;
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "../interfaces/CompoundInterfaces.sol";
import "./LowGasSafeMath.sol";
import "./MinimalSignedMath.sol";


library CTokenParams {
  using LowGasSafeMath for uint256;
  using MinimalSignedMath for uint256;

  uint256 internal constant EXP_SCALE = 1e18;
  uint256 internal constant HALF_EXP_SCALE = 5e17;

  function getInterestRateParameters(address token) internal view returns (
    address model,
    uint256 cashPrior,
    uint256 borrowsPrior,
    uint256 reservesPrior,
    uint256 reserveFactorMantissa
  ) {
    ICToken cToken = ICToken(token);
    model = address(cToken.interestRateModel());

    cashPrior = cToken.getCash();
    borrowsPrior = cToken.totalBorrows();
    reservesPrior = cToken.totalReserves();
    uint256 accrualBlockNumber = cToken.accrualBlockNumber();
    uint256 blockDelta = block.number - accrualBlockNumber;
    reserveFactorMantissa = cToken.reserveFactorMantissa();
    if (blockDelta > 0) {
      uint256 borrowRateMantissa = getBorrowRate(address(model), cashPrior, borrowsPrior, reservesPrior);
      uint256 interestAccumulated = mulScalarTruncate(borrowRateMantissa.mul(blockDelta), borrowsPrior);
      borrowsPrior = borrowsPrior.add(interestAccumulated);
      reservesPrior = mulScalarTruncate(reserveFactorMantissa, interestAccumulated).add(reservesPrior);
    }
  }

  function currentExchangeRate(address token) internal view returns (uint256 exchangeRate) {
    ICToken cToken = ICToken(token);
    uint256 blockDelta = block.number - cToken.accrualBlockNumber();
    if (blockDelta == 0) {
      return cToken.exchangeRateStored();
    }

    IInterestRateModel model = cToken.interestRateModel();

    uint256 cashPrior = cToken.getCash();
    uint256 borrowsPrior = cToken.totalBorrows();
    uint256 reservesPrior = cToken.totalReserves();
    uint256 reserveFactorMantissa = cToken.reserveFactorMantissa();
    if (blockDelta > 0) {
      uint256 borrowRateMantissa = getBorrowRate(address(model), cashPrior, borrowsPrior, reservesPrior);
      uint256 interestAccumulated = mulScalarTruncate(borrowRateMantissa.mul(blockDelta), borrowsPrior);
      borrowsPrior = borrowsPrior.add(interestAccumulated);
      reservesPrior = mulScalarTruncate(reserveFactorMantissa, interestAccumulated).add(reservesPrior);
    }

    return cashPrior.add(borrowsPrior).sub(reservesPrior).mul(1e18) / ICToken(token).totalSupply();
  }
  

  function truncate(uint256 x) internal pure returns (uint256) {
    return x / EXP_SCALE;
  }

  function mulScalarTruncate(uint256 x, uint256 y) internal pure returns (uint256) {
    return truncate(x.mul(y));
  }

  function mulScalarTruncateAddUInt(uint256 x, uint256 y, uint256 z) internal pure returns (uint256) {
    return mulScalarTruncate(x, y).add(z);
  }

  function getBorrowRate(
    address model,
    uint256 cash,
    uint256 borrows,
    uint256 reserves
  ) internal view returns (uint256 borrowRateMantissa) {
    (bool success, bytes memory retData) = model.staticcall(
      abi.encodeWithSelector(
        IInterestRateModel.getBorrowRate.selector,
        cash,
        borrows,
        reserves
      )
    );
    if (!success) revert(abi.decode(retData, (string)));
    assembly {
      switch lt(mload(retData), 64)
      case 0 {borrowRateMantissa := mload(add(retData, 64))}
      default {borrowRateMantissa := mload(add(retData, 32))}
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

/*
The MIT License (MIT)
Copyright (c) 2018 Murray Software, LLC.
Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:
The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

/**
 * EIP 1167 Proxy Deployment
 * Originally from https://github.com/optionality/clone-factory/
 */
library CloneLibrary {
  function getCreateCode(address target) internal pure returns (bytes memory createCode) {
    // Reserve 55 bytes for the deploy code + 17 bytes as a buffer to prevent overwriting
    // other memory in the final mstore
    createCode = new bytes(72);
    assembly {
      let clone := add(createCode, 32)
      mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
      mstore(add(clone, 0x14), shl(96, target))
      mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
      mstore(createCode, 55)
    }
  }

  function createClone(address target) internal returns (address result) {
    bytes memory createCode = getCreateCode(target);
    assembly { result := create(0, add(createCode, 32), 55) }
  }

  function createClone(address target, bytes32 salt) internal returns (address result) {
    bytes memory createCode = getCreateCode(target);
    assembly { result := create2(0, add(createCode, 32), 55, salt) }
  }

  function isClone(address target, address query) internal view returns (bool result) {
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000)
      mstore(add(clone, 0xa), shl(96, target))
      mstore(add(clone, 0x1e), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)

      let other := add(clone, 0x40)
      extcodecopy(query, other, 0, 0x2d)
      result := and(
        eq(mload(clone), mload(other)),
        eq(mload(add(clone, 0xd)), mload(add(other, 0xd)))
      )
    }
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.0;

/************************************************************************************************
Originally from https://github.com/Uniswap/uniswap-v3-core/blob/main/contracts/libraries/LowGasSafeMath.sol

This source code has been modified from the original, which was copied from the github repository
at commit hash b83fcf497e895ae59b97c9d04e997023f69b5e97.

Subject to the GPL-2.0 license
*************************************************************************************************/


/// @title Optimized overflow and underflow safe math operations
/// @notice Contains methods for doing math operations that revert on overflow or underflow for minimal gas cost
library LowGasSafeMath {
  /// @notice Returns x + y, reverts if sum overflows uint256
  /// @param x The augend
  /// @param y The addend
  /// @return z The sum of x and y
  function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require((z = x + y) >= x);
  }

  /// @notice Returns x + y, reverts if sum overflows uint256
  /// @param x The augend
  /// @param y The addend
  /// @return z The sum of x and y
  function add(uint256 x, uint256 y, string memory errorMessage) internal pure returns (uint256 z) {
    require((z = x + y) >= x, errorMessage);
  }

  /// @notice Returns x - y, reverts if underflows
  /// @param x The minuend
  /// @param y The subtrahend
  /// @return z The difference of x and y
  function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require(y <= x);
    z = x - y;
  }

  /// @notice Returns x - y, reverts if underflows
  /// @param x The minuend
  /// @param y The subtrahend
  /// @return z The difference of x and y
  function sub(uint256 x, uint256 y, string memory errorMessage) internal pure returns (uint256 z) {
    require(y <= x, errorMessage);
    z = x - y;
  }

  /// @notice Returns x * y, reverts if overflows
  /// @param x The multiplicand
  /// @param y The multiplier
  /// @return z The product of x and y
  function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
    if (x == 0) return 0;
    z = x * y;
    require(z / x == y);
  }

  /// @notice Returns x * y, reverts if overflows
  /// @param x The multiplicand
  /// @param y The multiplier
  /// @return z The product of x and y
  function mul(uint256 x, uint256 y, string memory errorMessage) internal pure returns (uint256 z) {
    if (x == 0) return 0;
    z = x * y;
    require(z / x == y, errorMessage);
  }

  /// @notice Returns ceil(x / y)
  /// @param x The numerator
  /// @param y The denominator
  /// @return z The quotient of x and y
  function divCeil(uint256 x, uint256 y) internal pure returns (uint256 z) {
    z = x % y == 0 ? x / y : (x/y) + 1;
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;


library MinimalSignedMath {
  function add(int256 a, int256 b) internal pure returns (int256) {
    int256 c = a + b;
    require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

    return c;
  }

  function sub(int256 a, int256 b) internal pure returns (int256) {
    int256 c = a - b;
    require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

    return c;
  }

  function add(uint256 a, int256 b) internal pure returns (uint256) {
    require(a < 2**255);
    int256 _a = int256(a);
    int256 c = _a + b;
    require((b >= 0 && c >= _a) || (b < 0 && c < _a));
    if (c < 0) return 0;
    return uint256(c);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "../interfaces/IERC20Metadata.sol";


library SymbolHelper {

  /**
   * @dev Returns the index of the lowest bit set in `self`.
   * Note: Requires that `self != 0`
   */
  function lowestBitSet(uint256 self) internal pure returns (uint256 _z) {
    require (self > 0, "Bits::lowestBitSet: Value 0 has no bits set");
    uint256 _magic = 0x00818283848586878898a8b8c8d8e8f929395969799a9b9d9e9faaeb6bedeeff;
    uint256 val = (self & -self) * _magic >> 248;
    uint256 _y = val >> 5;
    _z = (
      _y < 4
        ? _y < 2
          ? _y == 0
            ? 0x753a6d1b65325d0c552a4d1345224105391a310b29122104190a110309020100
            : 0xc976c13bb96e881cb166a933a55e490d9d56952b8d4e801485467d2362422606
          : _y == 2
            ? 0xe39ed557db96902cd38ed14fad815115c786af479b7e83247363534337271707
            : 0xf7cae577eec2a03cf3bad76fb589591debb2dd67e0aa9834bea6925f6a4a2e0e
        : _y < 6
          ? _y == 4
            ? 0xc8c0b887b0a8a4489c948c7f847c6125746c645c544c444038302820181008ff
            : 0xf6e4ed9ff2d6b458eadcdf97bd91692de2d4da8fd2d0ac50c6ae9a8272523616
          : _y == 6
            ? 0xf5ecf1b3e9debc68e1d9cfabc5997135bfb7a7a3938b7b606b5b4b3f2f1f0ffe
            : 0xf8f9cbfae6cc78fbefe7cdc3a1793dfcf4f0e8bbd8cec470b6a28a7a5a3e1efd
    );
    _z >>= (val & 0x1f) << 3;
    return _z & 0xff;
  }

  function getSymbol(address token) internal view returns (string memory) {
    (bool success, bytes memory data) = token.staticcall(abi.encodeWithSignature("symbol()"));
    if (!success) return "UNKNOWN";
    if (data.length != 32) return abi.decode(data, (string));
    uint256 symbol = abi.decode(data, (uint256));
    if (symbol == 0) return "UNKNOWN";
    uint256 emptyBits = 255 - lowestBitSet(symbol);
    uint256 size = (emptyBits / 8) + (emptyBits % 8 > 0 ? 1 : 0);
    assembly { mstore(data, size) }
    return string(data);
  }

  function getName(address token) internal view returns (string memory) {
    (bool success, bytes memory data) = token.staticcall(abi.encodeWithSignature("name()"));
    if (!success) return "UNKNOWN";
    if (data.length != 32) return abi.decode(data, (string));
    uint256 symbol = abi.decode(data, (uint256));
    if (symbol == 0) return "UNKNOWN";
    uint256 emptyBits = 255 - lowestBitSet(symbol);
    uint256 size = (emptyBits / 8) + (emptyBits % 8 > 0 ? 1 : 0);
    assembly { mstore(data, size) }
    return string(data);
  }

  function getPrefixedSymbol(string memory prefix, address token) internal view returns (string memory prefixedSymbol) {
    prefixedSymbol = string(abi.encodePacked(
      prefix,
      getSymbol(token)
    ));
  }

  function getPrefixedName(string memory prefix, address token) internal view returns (string memory prefixedName) {
    prefixedName = string(abi.encodePacked(
      prefix,
      getName(token)
    ));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

/************************************************************************************************
Originally from https://github.com/Uniswap/uniswap-lib/blob/master/contracts/libraries/TransferHelper.sol

This source code has been modified from the original, which was copied from the github repository
at commit hash cfedb1f55864dcf8cc0831fdd8ec18eb045b7fd1.

Subject to the MIT license
*************************************************************************************************/


library TransferHelper {
  function safeApproveMax(address token, address to) internal {
    safeApprove(token, to, type(uint256).max);
  }

  function safeUnapprove(address token, address to) internal {
    safeApprove(token, to, 0);
  }

  function safeApprove(address token, address to, uint value) internal {
    // bytes4(keccak256(bytes("approve(address,uint256)")));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "TH:SA");
  }

  function safeTransfer(address token, address to, uint value) internal {
    // bytes4(keccak256(bytes("transfer(address,uint256)")));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "TH:ST");
  }

  function safeTransferFrom(address token, address from, address to, uint value) internal {
    // bytes4(keccak256(bytes("transferFrom(address,address,uint256)")));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "TH:STF");
  }

  function safeTransferETH(address to, uint256 value) internal {
    (bool success, ) = to.call{value: value}("");
    require(success, "TH:STE");
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;
pragma abicoder v2;

import "../interfaces/IAdapterRegistry.sol";
import "../libraries/CloneLibrary.sol";
import "../libraries/ArrayHelper.sol";


abstract contract AbstractProtocolAdapter {
  using ArrayHelper for address[];

/* ========== Events ========== */

  event MarketFrozen(address token);

  event MarketUnfrozen(address token);

  event AdapterFrozen(address adapter);

  event AdapterUnfrozen(address adapter);

/* ========== Constants ========== */

  /**
   * @dev WETH address used for deciding whether to deploy an ERC20 or Ether adapter.
   */
  address public constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

  /**
   * @dev Global registry of adapters.
   */
  IAdapterRegistry public immutable registry;

/* ========== Storage ========== */

  /**
   * @dev List of adapters which have been deployed and then frozen.
   */
  address[] public frozenAdapters;

  /**
   * @dev List of tokens which have been frozen and which do not have an adapter.
   */
  address[] public frozenTokens;

  /**
   * @dev Number of tokens which have been mapped by the adapter.
   */
  uint256 public totalMapped;

/* ========== Constructor ========== */

  constructor(IAdapterRegistry _registry) {
    registry = _registry;
  }

/* ========== Public Actions ========== */

  /**
   * @dev Map up to `max` tokens, starting at `totalMapped`.
   */
  function map(uint256 max) external virtual {
    address[] memory tokens = getUnmappedUpTo(max);
    uint256 len = tokens.length;
    address[] memory adapters = new address[](len);
    uint256 skipped;
    for (uint256 i; i < len; i++) {
      address token = tokens[i];
      if (isTokenMarketFrozen(token)) {
        skipped++;
        frozenTokens.push(token);
        emit MarketFrozen(token);
        continue;
      }
      address adapter = deployAdapter(token);
      adapters[i - skipped] = adapter;
    }
    totalMapped += len;
    assembly { if gt(skipped, 0) { mstore(adapters, sub(len, skipped)) } }
    registry.addTokenAdapters(adapters);
  }

  /**
   * @dev Unfreeze adapter at `index` in `frozenAdapters`.
   * Market for the adapter must not be frozen by the protocol.
   */
  function unfreezeAdapter(uint256 index) external virtual {
    address adapter = frozenAdapters[index];
    require(!isAdapterMarketFrozen(adapter), "Market still frozen");
    frozenAdapters.remove(index);
    registry.addTokenAdapter(adapter);
    emit AdapterUnfrozen(adapter);
  }

  /**
   * @dev Unfreeze token at `index` in `frozenTokens` and create a new adapter for it.
   * Market for the token must not be frozen by the protocol.
   */
  function unfreezeToken(uint256 index) external virtual {
    address token = frozenTokens[index];
    require(!isTokenMarketFrozen(token), "Market still frozen");
    frozenTokens.remove(index);
    address adapter = deployAdapter(token);
    registry.addTokenAdapter(adapter);
    emit MarketUnfrozen(token);
  }

  /**
   * @dev Freeze `adapter` - add it to `frozenAdapters` and remove it from the registry.
   * Does not verify adapter exists or has been registered by this contract because the
   * registry handles that.
   */
  function freezeAdapter(address adapter) external virtual {
    require(isAdapterMarketFrozen(adapter), "Market not frozen");
    frozenAdapters.push(adapter);
    registry.removeTokenAdapter(adapter);
    emit AdapterFrozen(adapter);
  }

/* ========== Internal Actions ========== */

  /**
   * @dev Deploys an adapter for `token`, which will either be an underlying token
   * or a wrapper token, whichever is returned by `getUnmapped`.
   */
  function deployAdapter(address token) internal virtual returns (address);

/* ========== Public Queries ========== */

  /**
   * @dev Name of the protocol the adapter is for.
   */
  function protocol() external view virtual returns (string memory);

  /**
   * @dev Get the list of tokens which have not already been mapped by the adapter.
   * Tokens may be underlying tokens or wrapper tokens for a lending market.
   */
  function getUnmapped() public view virtual returns (address[] memory tokens);

  /**
   * @dev Get up to `max` tokens which have not already been mapped by the adapter.
   * Tokens may be underlying tokens or wrapper tokens for a lending market.
   */
  function getUnmappedUpTo(uint256 max) public view virtual returns (address[] memory tokens) {
    tokens = getUnmapped();
    if (tokens.length > max) {
      assembly { mstore(tokens, max) }
    }
  }

  function getFrozenAdapters() external view returns (address[] memory tokens) {
    tokens = frozenAdapters;
  }

  function getFrozenTokens() external view returns (address[] memory tokens) {
    tokens = frozenTokens;
  }

/* ========== Internal Queries ========== */

  /**
   * @dev Check whether the market for an adapter is frozen.
   */
  function isAdapterMarketFrozen(address adapter) internal view virtual returns (bool);

  /**
   * @dev Check whether the market for a token is frozen.
   */
  function isTokenMarketFrozen(address token) internal view virtual returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;
pragma abicoder v2;

import "../interfaces/CompoundInterfaces.sol";
import "../adapters/cream/CrErc20Adapter.sol";
import "../adapters/cream/CrEtherAdapter.sol";
import "./AbstractProtocolAdapter.sol";


contract CreamProtocolAdapter is AbstractProtocolAdapter {
  using CloneLibrary for address;

/* ========== Constants ========== */

  IComptroller public constant comptroller = IComptroller(0x3d5BC3c8d13dcB8bF317092d84783c2697AE9258);
  address public immutable erc20AdapterImplementation;
  address public immutable etherAdapterImplementation;

/* ========== Constructor ========== */

  constructor(IAdapterRegistry _registry) AbstractProtocolAdapter(_registry) {
    erc20AdapterImplementation = address(new CrErc20Adapter());
    etherAdapterImplementation = address(new CrEtherAdapter());
  }

/* ========== Internal Actions ========== */

  function deployAdapter(address cToken) internal virtual override returns (address adapter) {
    address underlying;
    // The call to underlying will use all the gas sent if it fails,
    // so we specify a maximum of 25k gas. The contract will only use ~2k
    // but this protects against all likely changes to the gas schedule.
    try ICToken(cToken).underlying{gas: 25000}() returns (address _underlying) {
      underlying = _underlying;
      if (underlying == address(0)) {
        underlying = weth;
      }
    } catch {
      underlying = weth;
    }
    if (underlying == weth) {
      adapter = CloneLibrary.createClone(etherAdapterImplementation);
    } else {
      adapter = CloneLibrary.createClone(erc20AdapterImplementation);
    }
    CrErc20Adapter(adapter).initialize(underlying, address(cToken));
  }

/* ========== Public Queries ========== */

  function protocol() external pure virtual override returns (string memory) {
    return "Cream";
  }

  function getUnmapped() public view virtual override returns (address[] memory cTokens) {
    cTokens = toAddressArray(comptroller.getAllMarkets());
    uint256 len = cTokens.length;
    uint256 prevLen = totalMapped;
    if (len == prevLen) {
      assembly { mstore(cTokens, 0) }
    } else {
      assembly {
        cTokens := add(cTokens, mul(prevLen, 32))
        mstore(cTokens, sub(len, prevLen))
      }
    }
  }

  function toAddressArray(ICToken[] memory cTokens) internal pure returns (address[] memory arr) {
    assembly { arr := cTokens }
  }

/* ========== Internal Queries ========== */

  function isAdapterMarketFrozen(address adapter) internal view virtual override returns (bool) {
    return comptroller.mintGuardianPaused(IErc20Adapter(adapter).token());
  }

  function isTokenMarketFrozen(address cToken) internal view virtual override returns (bool) {
    // Return true if market is paused in comptroller
    bool isFrozen = comptroller.mintGuardianPaused(cToken);
    if (isFrozen) return true;
    // Return true if market is for an SLP token, which the adapter can not handle.
    // The call to `sushi()` will use all the gas sent if it fails, so we specify a
    // maximum of 25k gas to ensure it will not use all the gas in the transaction, but
    // can still be executed with any foreseeable changes to the gas schedule.
    try ICToken(cToken).sushi{gas:25000}() returns (address) {
      return true;
    } catch {
      // Return true is supply is 0.
      return IERC20(cToken).totalSupply() == 0;
    }
  }
}

