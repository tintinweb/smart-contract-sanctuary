// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
    constructor () {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IStandardOracle.sol";
import "./interfaces/ITokenWrapper.sol";
import "./lib/ConversionLib.sol";
import "./lib/LowGasFixedPoint.sol";


interface IConvertControllerEvents {
  event NewController(address newController);
  event NewDefaultOracle(address newOracle);
  event NewOracleOverride(address token, address oracle);
  event NewTokenConverter(address token, address converter);
}


contract ConvertControllerStorage is Ownable {
  address public controller;

  IStandardOracle public defaultOracle;

  /**
   * @dev Mapping of wrapped tokens to their underlying tokens.
   * If the token is a wrapper of a wrapper, this should reference the base asset.
   */
  mapping(address => address) public getUnderlyingToken;

  mapping(address => address) public getOracleOverride;

  mapping(address => address) public getConverter;

  /**
   * @dev Set `key` in `map` to `value`.
   * If `key` already has a value, asserts that caller is owner.
   * If `key` does not have a value, asserts that caller is owner or controller.
   */
  function set(
    mapping(address => address) storage map,
    address key,
    address value
  ) internal {
    if (map[key] != address(0)) {
      require(msg.sender == owner(), "Only owner can update");
    } else {
      require(
        msg.sender == owner() || msg.sender == controller,
        "Only owner or controller can set"
      );
    }
    map[key] = value;
  }

  /**
   * @dev Return the oracle to use for `token`.
   * If `token` has an oracle override, use that; otherwise, use `defaultOracle`.
   */
  function oracleFor(address token) public view returns (IStandardOracle oracle) {
    oracle = IStandardOracle(getOracleOverride[token]);
    if (address(oracle) == address(0)) oracle = defaultOracle;
  }

  /**
   * @dev Returns the address of the underlying token for `token` if one is recorded,
   * otherwise returns the same address.
   */
  function underlyingOrSame(address token) public view returns (address underlying) {
    underlying = getUnderlyingToken[token];
    if (underlying == address(0)) underlying = token;
  }

  function toWrappedAmount(address wrappedToken, uint256 underlyingAmount) public view returns (uint256 wrappedAmount) {
    address wrapper = getConverter[wrappedToken];
    wrappedAmount = (wrapper == address(0))
      ? underlyingAmount
      : ITokenWrapper(wrapper).toWrappedAmount(underlyingAmount);
  }

  function toUnderlyingAmount(address wrappedToken, uint256 wrappedAmount) public view returns (uint256 underlyingAmount) {
    address wrapper = getConverter[wrappedToken];
    underlyingAmount = (wrapper == address(0))
      ? wrappedAmount
      : ITokenWrapper(wrapper).toUnderlyingAmount(wrappedAmount);
  }

  function updatePrice(address token) public returns (bool didUpdate) {
    address underlying = underlyingOrSame(token);
    IStandardOracle oracle = oracleFor(underlying);
    didUpdate = oracle.updatePrice(underlying);
  }

  function updatePrices(address[] calldata tokens) public returns (bool[] memory didUpdate) {
    uint256 len = tokens.length;
    didUpdate = new bool[](len);
    for (uint256 i = 0; i < len; i++) didUpdate[i] = updatePrice(tokens[i]);
  }
}


contract ConvertControllerOwned is Ownable, ConvertControllerStorage, IConvertControllerEvents {
  constructor(
    IStandardOracle defaultOracle_,
    address controller_
  ) public Ownable() {
    defaultOracle = defaultOracle_;
    emit NewDefaultOracle(address(defaultOracle_));
    controller = controller_;
    emit NewController(controller_);
  }

  function setDefaultOracle(IStandardOracle defaultOracle_) external onlyOwner {
    defaultOracle = defaultOracle_;
    emit NewDefaultOracle(address(defaultOracle_));
  }

  /**
   * @dev Sets the oracle override for `token`.
   *
   * If the token already has an override, this function must be called by {owner}.
   * If the token does not have an override, this function can be called by either
   * {owner} or {controller}.
   *
   * @param token Address of the token to set an override for
   * @param oracle Oracle to use for `token`
   */
  function setOracleOverride(address token, address oracle) external {
    set(
      getOracleOverride,
      token,
      oracle
    );
    emit NewOracleOverride(token, oracle);
  }

  function setTokenConverter(address token, address converter) external {
    set(
      getConverter,
      token,
      converter
    );
    emit NewTokenConverter(token, address(converter));
  }

  function setController(address newController) external onlyOwner {
    controller = newController;
    emit NewController(newController);
  }

  function setUnderlyingToken(address wrapped, address underlying) external {
    set(
      getUnderlyingToken,
      wrapped,
      underlying
    );
  }
}


contract ConvertControllerView is ConvertControllerStorage {
 
  function getConverters(address[] calldata tokens)
    external
    view
    returns (ITokenWrapper[] memory converters)
  {
    uint256 len = tokens.length;
    converters = new ITokenWrapper[](len);
    for (uint256 i = 0; i < len; i++) {
      converters[i] = ITokenWrapper(getConverter[tokens[i]]);
    }
  }

  function computeAverageTokensForEth(
    address token,
    uint256 wethAmount,
    uint256 minTimeElapsed,
    uint256 maxTimeElapsed
  ) public view returns (uint256 tokenAmount) {
    address underlying = underlyingOrSame(token);
    IStandardOracle oracle = oracleFor(underlying);
    uint256 underlyingAmount = oracle.computeAverageTokensForEth(
      underlying,
      wethAmount,
      minTimeElapsed,
      maxTimeElapsed
    );
    tokenAmount = toWrappedAmount(token, underlyingAmount);
  }

  function computeAverageTokensForEth(
    address[] calldata tokens,
    uint256[] calldata wethAmounts,
    uint256 minTimeElapsed,
    uint256 maxTimeElapsed
  ) external view returns (uint256[] memory tokenAmounts) {
    uint256 len = tokens.length;
    require(wethAmounts.length == len, "ERR_ARR_LEN");
    tokenAmounts = new uint256[](len);
    for (uint256 i = 0; i < len; i++) {
      tokenAmounts[i] = computeAverageTokensForEth(
        tokens[i],
        wethAmounts[i],
        minTimeElapsed,
        maxTimeElapsed
      );
    }
  }

  function computeAverageEthForTokens(
    address token,
    uint256 tokenAmount,
    uint256 minTimeElapsed,
    uint256 maxTimeElapsed
  ) public view returns (uint256 wethAmount) {
    address underlying = underlyingOrSame(token);
    uint256 underlyingAmount = toUnderlyingAmount(token, tokenAmount);
    IStandardOracle oracle = oracleFor(underlying);
    wethAmount = oracle.computeAverageEthForTokens(
      underlying,
      underlyingAmount,
      minTimeElapsed,
      maxTimeElapsed
    );
  }

  function computeAverageEthForTokens(
    address[] calldata tokens,
    uint256[] calldata tokenAmounts,
    uint256 minTimeElapsed,
    uint256 maxTimeElapsed
  ) external view returns (uint256[] memory wethAmounts) {
    uint256 len = tokens.length;
    require(tokenAmounts.length == len, "ERR_ARR_LEN");
    wethAmounts = new uint256[](len);
    for (uint256 i = 0; i < len; i++) {
      wethAmounts[i] = computeAverageEthForTokens(
        tokens[i],
        tokenAmounts[i],
        minTimeElapsed,
        maxTimeElapsed
      );
    }
  }

  function computeAverageTokensForTokens(
    address tokenIn,
    address tokenOut,
    uint256 tokenAmountIn,
    uint256 minTimeElapsed,
    uint256 maxTimeElapsed
  ) public view returns (uint256 tokenAmountOut) {
    uint256 wethAmount = computeAverageEthForTokens(tokenIn, tokenAmountIn, minTimeElapsed, maxTimeElapsed);
    tokenAmountOut = computeAverageTokensForEth(tokenOut, wethAmount, minTimeElapsed, maxTimeElapsed);
  }

  function computeAverageTokensForTokens(
    address[] calldata tokensIn,
    address[] calldata tokensOut,
    uint256[] calldata tokenAmountsIn,
    uint256 minTimeElapsed,
    uint256 maxTimeElapsed
  ) external view returns (uint256[] memory tokenAmountsOut) {
    uint256 len = tokensIn.length;
    require(tokensOut.length == len && tokenAmountsIn.length == len, "ERR_ARR_LEN");
    tokenAmountsOut = new uint256[](len);
    for (uint256 i = 0; i < len; i++) {
      tokenAmountsOut[i] = computeAverageTokensForTokens(
        tokensIn[i],
        tokensOut[i],
        tokenAmountsIn[i],
        minTimeElapsed,
        maxTimeElapsed
      );
    }
  }
}


contract ConvertController is ConvertControllerOwned, ConvertControllerView {
  constructor(
    IStandardOracle defaultOracle_,
    address controller_
  ) public ConvertControllerOwned(defaultOracle_, controller_) {}
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0;


interface IStandardOracle {
/* ==========  Mutative Functions  ========== */

  function updatePrice(address token) external returns (bool);

  function updatePrices(address[] calldata tokens) external returns (bool[] memory);

/* ==========  Value Queries: Singular  ========== */

  function computeAverageEthForTokens(
    address token,
    uint256 tokenAmount,
    uint256 minTimeElapsed,
    uint256 maxTimeElapsed
  ) external view returns (uint144);

  function computeAverageTokensForEth(
    address token,
    uint256 wethAmount,
    uint256 minTimeElapsed,
    uint256 maxTimeElapsed
  ) external view returns (uint144);

/* ==========  Value Queries: Multiple  ========== */

  function computeAverageEthForTokens(
    address[] calldata tokens,
    uint256[] calldata tokenAmounts,
    uint256 minTimeElapsed,
    uint256 maxTimeElapsed
  ) external view returns (uint144[] memory);

  function computeAverageTokensForEth(
    address[] calldata tokens,
    uint256[] calldata wethAmounts,
    uint256 minTimeElapsed,
    uint256 maxTimeElapsed
  ) external view returns (uint144[] memory);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0;


interface ITokenWrapper {
  /**
   * @dev Return the immediately liquidatable value of `wrappedAmount`
   * of the wrapped asset in terms of the underlying asset.
   */
  function toUnderlyingAmount(uint256 wrappedAmount) external view returns (uint256 underlyingAmount);
  
  /**
   * @dev Return the amount of the wrapped asset that can be minted with `underlyingAmount` of the underlying asset.
   */
  function toWrappedAmount(uint256 underlyingAmount) external view returns (uint256 wrappedAmount);

  /**
   * @dev Mint the wrapped asset using the entire balance of the contract in the underlying asset.
   * Note: Should only be called by contracts following a transfer of the underlying asset.
   * @param recipient Account to receive the wrapped tokens
   */
  function wrap(address recipient) external;

  /**
   * @dev Redeem the underlying asset using the entire balance of the contract
   * in the wrapped asset.
   * Note: Should only be called by contracts following a transfer of the wrapped asset.
   * @param recipient Account to receive the wrapped tokens
   */
  function unwrap(address recipient) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.7.6;

import "./LowGasFixedPoint.sol";

library ConversionLib {
  using LowGasFixedPoint for uint224;
  using LowGasFixedPoint for uint112;

  function toFraction(uint256 underlyingAmount, uint256 wrappedAmount) internal pure returns (uint224) {
    return safeCast112(underlyingAmount).fraction(safeCast112(wrappedAmount));
  }

  function toUnderlyingAmount(uint224 fp, uint256 wrappedAmount) internal pure returns (uint256) {
    return fp.mulDecode(wrappedAmount);
  }

  function toWrappedAmount(uint224 fp, uint256 underlyingAmount) internal pure returns (uint256) {
    return fp.reciprocal().mulDecode(underlyingAmount);
  }

  function safeCast112(uint256 x) internal pure returns (uint112 y) {
    require((y = uint112(x)) == x, "UINT112 OVERFLOW");
  }
}

pragma solidity >=0.4.0;

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
library LowGasFixedPoint {
  // uq112x112
  // range: [0, 2**112 - 1]
  // resolution: 1 / 2**112

  // uq144x112
  // range: [0, 2**144 - 1]
  // resolution: 1 / 2**112

  uint8 internal constant RESOLUTION = 112;
  uint internal constant Q112 = uint(1) << RESOLUTION;
  uint internal constant Q224 = Q112 << RESOLUTION;

  // encode a uint112 as a UQ112x112
  function encode(uint112 x) internal pure returns (uint224) {
    return uint224(x) << RESOLUTION;
  }

  // encodes a uint144 as a UQ144x112
  function encode144(uint144 x) internal pure returns (uint256) {
    return uint256(x) << RESOLUTION;
  }

  // divide a UQ112x112 by a uint112, returning a UQ112x112
  function div(uint224 self, uint112 x) internal pure returns (uint224) {
    require(x != 0, "FixedPoint: DIV_BY_ZERO");
    return self / uint224(x);
  }

  // multiply a UQ112x112 by a uint, returning a UQ144x112
  // reverts on overflow
  function mul(uint224 self, uint y) internal pure returns (uint256) {
    uint z;
    require(y == 0 || (z = uint(self) * y) / y == uint(self), "FixedPoint: MULTIPLICATION_OVERFLOW");
    return z;
  }

  // returns a UQ112x112 which represents the ratio of the numerator to the denominator
  // equivalent to encode(numerator).div(denominator)
  function fraction(uint112 numerator, uint112 denominator) internal pure returns (uint224) {
    require(denominator > 0, "FixedPoint: DIV_BY_ZERO");
    return (uint224(numerator) << RESOLUTION) / denominator;
  }

  // decode a UQ112x112 into a uint112 by truncating after the radix point
  function decode(uint224 self) internal pure returns (uint112) {
    return uint112(self >> RESOLUTION);
  }

  // decode a UQ144x112 into a uint144 by truncating after the radix point
  function decode144(uint256 self) internal pure returns (uint144) {
    return uint144(self >> RESOLUTION);
  }

  function mulDecode(uint224 self, uint y) internal pure returns (uint144) {
    uint z;
    require(y == 0 || (z = uint(self) * y) / y == uint(self), "FixedPoint: MULTIPLICATION_OVERFLOW");
    return uint144(z >> RESOLUTION);
  }

  // take the reciprocal of a UQ112x112
  function reciprocal(uint224 self) internal pure returns (uint224) {
    require(self != 0, "FixedPoint: ZERO_RECIPROCAL");
    return uint224(Q224 / self);
  }
}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "none",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "remappings": [],
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