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

pragma solidity ^0.7.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./libraries/TransferHelper.sol";
import "./libraries/LowGasSafeMath.sol";
import "./libraries/UniswapV2Library.sol";
import "./libraries/PairsLibrary.sol";
import "./interfaces/IContractRegistry.sol";
import "./interfaces/IOracle.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IDNDX.sol";


contract ExitFeeSeller is Ownable() {
  using TransferHelper for address;
  using LowGasSafeMath for uint256;

/* ==========  Constants  ========== */

  uint256 public constant minTwapAge = 30 minutes;
  uint256 public constant maxTwapAge = 2 days;
  IOracle public constant oracle = IOracle(0xFa5a44D3Ba93D666Bf29C8804a36e725ecAc659A);
  address public constant treasury = 0x78a3eF33cF033381FEB43ba4212f2Af5A5A0a2EA;
  IWETH public constant weth = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
  IDNDX public constant dndx = IDNDX(0x262cd9ADCE436B6827C01291B84f1871FB8b95A3);

/* ==========  Storage  ========== */

  uint16 public twapDiscountBips = 500; // 5%
  uint16 public ethToTreasuryBips = 4000; // 40%

/* ==========  Structs  ========== */

  struct UniswapParams {
    address tokenIn;
    uint256 amountIn;
    address pair;
    bool zeroForOne;
    uint256 amountOut;
  }

/* ==========  Fallbacks  ========== */

  fallback() external payable { return; }
  receive() external payable { return; }

/* ==========  Constructor  ========== */

  constructor() {
    weth.approve(address(dndx), type(uint256).max);
  }

/* ==========  Token Transfer  ========== */

  /**
   * @dev Transfers full balance held by the owner of each provided token
   * to the seller contract.
   *
   * Because the seller will have to be enabled through a proposal and will
   * take several days to go into effect, it will not be possible to know the
   * precise balance to transfer ahead of time; instead, infinite approval will
   * be given and this function will be called to execute the transfers.
   */
  function takeTokensFromOwner(address[] memory tokens) external {
    uint256 len = tokens.length;
    address _owner = owner();
    for (uint256 i = 0; i < len; i++) {
      address token = tokens[i];
      uint256 ownerBalance = IERC20(token).balanceOf(_owner);
      if (ownerBalance > 0) {
        token.safeTransferFrom(_owner, address(this), ownerBalance);
      }
    }
  }

/* ==========  Owner Controls  ========== */

  /**
   * @dev Sets the maximum discount on the TWAP that the seller will accept
   * for a trade in basis points, e.g. 500 means the token must be sold
   * for >=95% of the TWAP.
   */
  function setTWAPDiscountBips(uint16 _twapDiscountBips) external onlyOwner {
    require(_twapDiscountBips <= 1000, "Can not set discount >= 10%");
    twapDiscountBips = _twapDiscountBips;
  }

  /**
   * @dev Sets the portion of revenue that are received by the treasury in basis
   * points, e.g. 4000 means the treasury gets 40% of revenue and dndx gets 60%.
   */
  function setEthToTreasuryBips(uint16 _ethToTreasuryBips) external onlyOwner {
    require(_ethToTreasuryBips <= 10000, "Can not set bips over 100%");
    ethToTreasuryBips = _ethToTreasuryBips;
  }

  /**
   * @dev Return tokens to the owner. Can be used if there is a desired change
   * in the revenue distribution mechanism.
   */
  function returnTokens(address[] memory tokens) external onlyOwner {
    uint256 len = tokens.length;
    address _owner = owner();
    for (uint256 i = 0; i < len; i++) {
      address token = tokens[i];
      if (token == address(0)) {
        uint256 bal = address(this).balance;
        if (bal > 0) _owner.safeTransferETH(bal);
      } else {
        uint256 bal = IERC20(token).balanceOf(address(this));
        if (bal > 0) token.safeTransfer(_owner, bal);
      }
    }
  }

/* ==========  Queries  ========== */

  function getBestPair(address token, uint256 amount) public view returns (address pair, uint256 amountOut) {
    bool zeroForOne = token < address(weth);
    (address token0, address token1) = zeroForOne ? (token, address(weth)) : (address(weth), token);
    uint256 amountUni;
    uint256 amountSushi;
    address uniPair = PairsLibrary.calculateUniPair(token0, token1);
    address sushiPair = PairsLibrary.calculateSushiPair(token0, token1);
    {
      (uint256 reserve0, uint256 reserve1) = PairsLibrary.tryGetReserves(uniPair);
      if (reserve0 > 0 && reserve1 > 0) {
        (uint256 reserveIn, uint256 reserveOut) = zeroForOne ? (reserve0, reserve1) : (reserve1, reserve0);
        amountUni = UniswapV2Library.getAmountOut(amount, reserveIn, reserveOut);
      }
    }
    {
      (uint256 reserve0, uint256 reserve1) = PairsLibrary.tryGetReserves(sushiPair);
      if (reserve0 > 0 && reserve1 > 0) {
        (uint256 reserveIn, uint256 reserveOut) = zeroForOne ? (reserve0, reserve1) : (reserve1, reserve0);
        amountSushi = UniswapV2Library.getAmountOut(amount, reserveIn, reserveOut);
      }
    }
    return amountUni >= amountSushi ? (uniPair, amountUni) : (sushiPair, amountSushi);
  }

  function getMinimumAmountOut(address token, uint256 amountIn) public view returns (uint256) {
    uint256 averageAmountOut = oracle.computeAverageEthForTokens(token, amountIn, minTwapAge, maxTwapAge);
    return averageAmountOut.sub(mulBips(averageAmountOut, twapDiscountBips));
  }

/* ==========  Swaps  ========== */

  function execute(address token, address pair, uint256 amountIn, uint256 amountOut) internal {
    token.safeTransfer(pair, amountIn);
    (uint256 amount0Out, uint256 amount1Out) = token < address(weth) ? (uint256(0), amountOut) : (amountOut, uint256(0));
    IUniswapV2Pair(pair).swap(amount0Out, amount1Out, address(this), new bytes(0));
  }

  function sellTokenForETH(address token) external {
    sellTokenForETH(token, IERC20(token).balanceOf(address(this)));
  }

  function sellTokenForETH(address token, uint256 amountIn) public {
    require(token != address(weth), "Can not sell WETH");
    uint256 minimumAmountOut = getMinimumAmountOut(token, amountIn);
    (address pair, uint256 amountOut) = getBestPair(token, amountIn);
    require(amountOut >= minimumAmountOut, "Insufficient output");
    execute(token, pair, amountIn, amountOut);
  }

/* ==========  Distribution  ========== */

  function distributeETH() external {
    uint256 bal = address(this).balance;
    if (bal > 0) weth.deposit{value: bal}();
    bal = weth.balanceOf(address(this));
    if (bal > 0) {
      uint256 ethToTreasury = mulBips(bal, ethToTreasuryBips);
      address(weth).safeTransfer(treasury, ethToTreasury);
      dndx.distribute(bal - ethToTreasury);
    }
  }

/* ==========  Utils  ========== */

  function mulBips(uint256 a, uint256 bips) internal pure returns (uint256) {
    return a.mul(bips) / uint256(10000);
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;


interface IContractRegistry {
  function addressOf(bytes32 contractName) external view returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;


interface IDNDX {
	function withdrawableDividendsOf(address account) external view returns (uint256);

	function withdrawnDividendsOf(address account) external view returns (uint256);

	function cumulativeDividendsOf(address account) external view returns (uint256);

	event DividendsDistributed(address indexed by, uint256 dividendsDistributed);

	event DividendsWithdrawn(address indexed by, uint256 fundsWithdrawn);

  function distribute(uint256) external;

  function distribute() external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;
pragma abicoder v2;


interface IOracle {
  struct PriceObservation {
    uint32 timestamp;
    uint224 priceCumulativeLast;
    uint224 ethPriceCumulativeLast;
  }

  function updatePrice(address token) external returns (bool);

  function updatePrices(address[] calldata tokens) external returns (bool[] memory);

  function getPriceObservationsInRange(
    address token,
    uint256 timeFrom,
    uint256 timeTo
  ) external view returns (PriceObservation[] memory prices);

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
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.0;

interface IUniswapV2Pair {
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);

  function name() external pure returns (string memory);

  function symbol() external pure returns (string memory);

  function decimals() external pure returns (uint8);

  function totalSupply() external view returns (uint256);

  function balanceOf(address owner) external view returns (uint256);

  function allowance(address owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 value) external returns (bool);

  function transfer(address to, uint256 value) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool);

  function DOMAIN_SEPARATOR() external view returns (bytes32);

  function PERMIT_TYPEHASH() external pure returns (bytes32);

  function nonces(address owner) external view returns (uint256);

  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  event Mint(address indexed sender, uint256 amount0, uint256 amount1);
  event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
  event Swap(
    address indexed sender,
    uint256 amount0In,
    uint256 amount1In,
    uint256 amount0Out,
    uint256 amount1Out,
    address indexed to
  );
  event Sync(uint112 reserve0, uint112 reserve1);

  function MINIMUM_LIQUIDITY() external pure returns (uint256);

  function factory() external view returns (address);

  function token0() external view returns (address);

  function token1() external view returns (address);

  function getReserves()
    external
    view
    returns (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockTimestampLast
    );

  function price0CumulativeLast() external view returns (uint256);

  function price1CumulativeLast() external view returns (uint256);

  function kLast() external view returns (uint256);

  function mint(address to) external returns (uint256 liquidity);

  function burn(address to) external returns (uint256 amount0, uint256 amount1);

  function swap(
    uint256 amount0Out,
    uint256 amount1Out,
    address to,
    bytes calldata data
  ) external;

  function skim(address to) external;

  function sync() external;

  function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
  event Deposit(address indexed dst, uint wad);

  event Withdrawal(address indexed src, uint wad);

  function deposit() external payable;

  function withdraw(uint256) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.0;

/************************************************************************************************
Originally from https://github.com/Uniswap/uniswap-v3-core/blob/main/contracts/libraries/LowGasSafeMath.sol

This source code has been modified from the original, which was copied from the github repository
at commit hash b83fcf497e895ae59b97c9d04e997023f69b5e97.

Subject to the GPL-2.0-or-later license
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
  function add(
    uint256 x,
    uint256 y,
    string memory errorMessage
  ) internal pure returns (uint256 z) {
    require((z = x + y) >= x, errorMessage);
  }

  /// @notice Returns x - y, reverts if underflows
  /// @param x The minuend
  /// @param y The subtrahend
  /// @return z The difference of x and y
  function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require((z = x - y) <= x);
  }

  /// @notice Returns x - y, reverts if underflows
  /// @param x The minuend
  /// @param y The subtrahend
  /// @return z The difference of x and y
  function sub(
    uint256 x,
    uint256 y,
    string memory errorMessage
  ) internal pure returns (uint256 z) {
    require((z = x - y) <= x, errorMessage);
  }

  /// @notice Returns x * y, reverts if overflows
  /// @param x The multiplicand
  /// @param y The multiplier
  /// @return z The product of x and y
  function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require(x == 0 || (z = x * y) / x == y);
  }

  /// @notice Returns x * y, reverts if overflows
  /// @param x The multiplicand
  /// @param y The multiplier
  /// @return z The product of x and y
  function mul(
    uint256 x,
    uint256 y,
    string memory errorMessage
  ) internal pure returns (uint256 z) {
    require(x == 0 || (z = x * y) / x == y, errorMessage);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./LowGasSafeMath.sol";
import "../interfaces/IUniswapV2Pair.sol";


library PairsLibrary {
  using LowGasSafeMath for uint256;
  address internal constant uniswapFactory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
  address internal constant sushiswapFactory = 0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac;

  // returns sorted token addresses, used to handle return values from pairs sorted in this order
  function sortTokens(address tokenA, address tokenB)
    internal
    pure
    returns (address token0, address token1)
  {
    require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
    (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
  }

  function calculateUniPair(address token0, address token1 ) internal pure returns (address pair) {
    pair = address(
      uint256(
        keccak256(
          abi.encodePacked(
            hex"ff",
            uniswapFactory,
            keccak256(abi.encodePacked(token0, token1)),
            hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f" // init code hash
          )
        )
      )
    );
  }

  function calculateSushiPair(address token0, address token1) internal pure returns (address pair) {
    pair = address(
      uint256(
        keccak256(
          abi.encodePacked(
            hex"ff",
            sushiswapFactory,
            keccak256(abi.encodePacked(token0, token1)),
            hex"e18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303" // init code hash
          )
        )
      )
    );
  }

  function tryGetReserves(address pair) internal view returns (uint112 reserve0, uint112 reserve1) {
    (bool success, bytes memory retData) = pair.staticcall(abi.encodeWithSelector(IUniswapV2Pair.getReserves.selector));
    if (success) {
      (reserve0, reserve1, ) = abi.decode(retData, (uint112, uint112, uint32));
    }
  }

  // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
  function getAmountOut(
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut
  ) internal pure returns (uint256 amountOut) {
    require(amountIn > 0, "PairsLibrary: INSUFFICIENT_INPUT_AMOUNT");
    require(
      reserveIn > 0 && reserveOut > 0,
      "PairsLibrary: INSUFFICIENT_LIQUIDITY"
    );
    uint256 amountInWithFee = amountIn.mul(997);
    uint256 numerator = amountInWithFee.mul(reserveOut);
    uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
    amountOut = numerator / denominator;
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
/************************************************************************************************
Originally from https://github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/libraries/TransferHelper.sol

This source code has been modified from the original, which was copied from the github repository
at commit hash 6a31c618fc3180a6ee945b869d1ce4449f253ee6.

Subject to the GPL-2.0-or-later license
*************************************************************************************************/


library TransferHelper {
  function safeApprove(address token, address to, uint value) internal {
    // bytes4(keccak256(bytes("approve(address,uint256)")));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: APPROVE_FAILED");
  }

  function safeTransferFrom(
    address token,
    address from,
    address to,
    uint256 value
  ) internal {
    (bool success, bytes memory data) =
      token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "STF");
  }

  function safeTransfer(
    address token,
    address to,
    uint256 value
  ) internal {
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "ST");
  }

  function safeTransferETH(address to, uint256 value) internal {
    (bool success, ) = to.call{value: value}(new bytes(0));
    require(success, "STE");
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./LowGasSafeMath.sol";
import "../interfaces/IUniswapV2Pair.sol";


library UniswapV2Library {
  using LowGasSafeMath for uint256;

  // returns sorted token addresses, used to handle return values from pairs sorted in this order
  function sortTokens(address tokenA, address tokenB)
    internal
    pure
    returns (address token0, address token1)
  {
    require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
    (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
  }

  function calculatePair(
    address factory,
    address token0,
    address token1
  ) internal pure returns (address pair) {
    pair = address(
      uint256(
        keccak256(
          abi.encodePacked(
            hex"ff",
            factory,
            keccak256(abi.encodePacked(token0, token1)),
            hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f" // init code hash
          )
        )
      )
    );
  }

  // calculates the CREATE2 address for a pair without making any external calls
  function pairFor(
    address factory,
    address tokenA,
    address tokenB
  ) internal pure returns (address pair) {
    (address token0, address token1) = sortTokens(tokenA, tokenB);
    pair = address(
      uint256(
        keccak256(
          abi.encodePacked(
            hex"ff",
            factory,
            keccak256(abi.encodePacked(token0, token1)),
            hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f" // init code hash
          )
        )
      )
    );
  }

  // fetches and sorts the reserves for a pair
  function getReserves(
    address factory,
    address tokenA,
    address tokenB
  ) internal view returns (uint256 reserveA, uint256 reserveB) {
    (address token0, ) = sortTokens(tokenA, tokenB);
    (uint256 reserve0, uint256 reserve1, ) =
      IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
    (reserveA, reserveB) = tokenA == token0
      ? (reserve0, reserve1)
      : (reserve1, reserve0);
  }

  // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
  function quote(
    uint256 amountA,
    uint256 reserveA,
    uint256 reserveB
  ) internal pure returns (uint256 amountB) {
    require(amountA > 0, "UniswapV2Library: INSUFFICIENT_AMOUNT");
    require(
      reserveA > 0 && reserveB > 0,
      "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
    );
    amountB = amountA.mul(reserveB) / reserveA;
  }

  // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
  function getAmountOut(
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut
  ) internal pure returns (uint256 amountOut) {
    require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
    require(
      reserveIn > 0 && reserveOut > 0,
      "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
    );
    uint256 amountInWithFee = amountIn.mul(997);
    uint256 numerator = amountInWithFee.mul(reserveOut);
    uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
    amountOut = numerator / denominator;
  }

  // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
  function getAmountIn(
    uint256 amountOut,
    uint256 reserveIn,
    uint256 reserveOut
  ) internal pure returns (uint256 amountIn) {
    require(amountOut > 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
    require(
      reserveIn > 0 && reserveOut > 0,
      "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
    );
    uint256 numerator = reserveIn.mul(amountOut).mul(1000);
    uint256 denominator = reserveOut.sub(amountOut).mul(997);
    amountIn = (numerator / denominator).add(1);
  }

  // performs chained getAmountOut calculations on any number of pairs
  function getAmountsOut(
    address factory,
    uint256 amountIn,
    address[] memory path
  ) internal view returns (uint256[] memory amounts) {
    require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
    amounts = new uint256[](path.length);
    amounts[0] = amountIn;
    for (uint256 i; i < path.length - 1; i++) {
      (uint256 reserveIn, uint256 reserveOut) =
        getReserves(factory, path[i], path[i + 1]);
      amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
    }
  }

  // performs chained getAmountIn calculations on any number of pairs
  function getAmountsIn(
    address factory,
    uint256 amountOut,
    address[] memory path
  ) internal view returns (uint256[] memory amounts) {
    require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
    amounts = new uint256[](path.length);
    amounts[amounts.length - 1] = amountOut;
    for (uint256 i = path.length - 1; i > 0; i--) {
      (uint256 reserveIn, uint256 reserveOut) =
        getReserves(factory, path[i - 1], path[i]);
      amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
    }
  }
}