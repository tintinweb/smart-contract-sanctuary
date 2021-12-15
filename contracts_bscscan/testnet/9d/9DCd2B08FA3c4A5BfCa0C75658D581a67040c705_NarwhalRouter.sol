// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./Narwhal.sol";
import "./libraries/TransferHelper.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IWETH.sol";


contract NarwhalRouter is Narwhal {
  using TokenInfo for bytes32;
  using TokenInfo for address;
  using TransferHelper for address;
  using SafeMath for uint256;

  modifier ensure(uint256 deadline) {
    require(deadline >= block.timestamp, "NRouter: EXPIRED");
    _;
  }

  constructor(
    address _uniswapFactory,
    address _sushiswapFactory,
    address _weth
  ) Narwhal(_uniswapFactory, _sushiswapFactory, _weth) {}

  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    bytes32[] calldata path,
    address to,
    uint256 deadline
  ) external ensure(deadline) returns (uint256[] memory amounts) {
    amounts = getAmountsOut(path, amountIn);
    require(amounts[amounts.length - 1] >= amountOutMin, "NRouter: MIN_OUT");
    path[0].readToken().safeTransferFrom(
      msg.sender,
      pairFor(path[0], path[1]),
      amounts[0]
    );
    _swap(amounts, path, to);
  }

  function swapTokensForExactTokens(
    uint256 amountOut,
    uint256 amountInMax,
    bytes32[] calldata path,
    address to,
    uint256 deadline
  ) external ensure(deadline) returns (uint256[] memory amounts) {
    amounts = getAmountsIn(path, amountOut);
    require(amounts[0] <= amountInMax, "NRouter: MAX_IN");
    path[0].readToken().safeTransferFrom(
      msg.sender,
      pairFor(path[0], path[1]),
      amounts[0]
    );
    _swap(amounts, path, to);
  }

  function swapExactETHForTokens(
    uint256 amountOutMin,
    bytes32[] calldata path,
    address to,
    uint256 deadline
  ) external payable ensure(deadline) returns (uint256[] memory amounts) {
    require(path[0].readToken() == address(weth), "NRouter: INVALID_PATH");
    amounts = getAmountsOut(path, msg.value);
    require(amounts[amounts.length - 1] >= amountOutMin, "NRouter: MIN_OUT");
    weth.deposit{value: amounts[0]}();
    address(weth).safeTransfer(pairFor(path[0], path[1]), amounts[0]);
    _swap(amounts, path, to);
  }

  function swapTokensForExactETH(
    uint256 amountOut,
    uint256 amountInMax,
    bytes32[] calldata path,
    address to,
    uint256 deadline
  ) external ensure(deadline) returns (uint256[] memory amounts) {
    require(path[path.length - 1].readToken() == address(weth), "NRouter: INVALID_PATH");
    amounts = getAmountsIn(path, amountOut);
    require(amounts[0] <= amountInMax, "NRouter: MAX_IN");
    path[0].readToken().safeTransferFrom(
      msg.sender,
      pairFor(path[0], path[1]),
      amounts[0]
    );
    _swap(amounts, path, address(this));
    weth.withdraw(amounts[amounts.length - 1]);
    TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
  }

  function swapExactTokensForETH(
    uint256 amountIn,
    uint256 amountOutMin,
    bytes32[] calldata path,
    address to,
    uint256 deadline
  ) external ensure(deadline) returns (uint256[] memory amounts) {
    require(path[path.length - 1].readToken() == address(weth), "NRouter: INVALID_PATH");
    amounts = getAmountsOut(path, amountIn);
    require(amounts[amounts.length - 1] >= amountOutMin, "NRouter: MIN_OUT");
    path[0].readToken().safeTransferFrom(
      msg.sender,
      pairFor(path[0], path[1]),
      amounts[0]
    );
    _swap(amounts, path, address(this));
    weth.withdraw(amounts[amounts.length - 1]);
    TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
  }

  function swapETHForExactTokens(
    uint256 amountOut,
    bytes32[] calldata path,
    address to,
    uint256 deadline
  ) external payable ensure(deadline) returns (uint256[] memory amounts) {
    require(path[0].readToken() == address(weth), "NRouter: INVALID_PATH");
    amounts = getAmountsIn(path, amountOut);
    require(amounts[0] <= msg.value, "NRouter: MAX_IN");
    weth.deposit{value: amounts[0]}();
    address(weth).safeTransfer(pairFor(path[0], path[1]), amounts[0]);
    _swap(amounts, path, to);
    // // refund dust eth, if any
    if (msg.value > amounts[0]) TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]);
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
pragma solidity >=0.5.0;


library TokenInfo {
  function unpack(bytes32 tokenInfo) internal pure returns (address token, bool useSushiNext) {
    assembly {
      token := shr(8, tokenInfo)
      useSushiNext := byte(31, tokenInfo)
    }
  }

  function pack(address token, bool sushi) internal pure returns (bytes32 tokenInfo) {
    assembly {
      tokenInfo := or(
        shl(8, token),
        sushi
      )
    }
  }

  function readToken(bytes32 tokenInfo) internal pure returns (address token) {
    assembly {
      token := shr(8, tokenInfo)
    }
  }

  function readSushi(bytes32 tokenInfo) internal pure returns (bool useSushiNext) {
    assembly {
      useSushiNext := byte(31, tokenInfo)
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;


library SafeMath {
  function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require((z = x + y) >= x, "ds-math-add-overflow");
  }

  function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require((z = x - y) <= x, "ds-math-sub-underflow");
  }

  function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
  }


  function add(uint256 x, uint256 y, string memory errorMessage) internal pure returns (uint256 z) {
    require((z = x + y) >= x, errorMessage);
  }

  function sub(uint256 x, uint256 y, string memory errorMessage) internal pure returns (uint256 z) {
    require((z = x - y) <= x, errorMessage);
  }

  function mul(uint256 x, uint256 y, string memory errorMessage) internal pure returns (uint256 z) {
    require(y == 0 || (z = x * y) / y == x, errorMessage);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;


interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;


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

interface IUniswapV2Factory {
  event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

  function feeTo() external view returns (address);

  function feeToSetter() external view returns (address);

  function migrator() external view returns (address);

  function getPair(address tokenA, address tokenB) external view returns (address pair);

  function allPairs(uint256) external view returns (address pair);

  function allPairsLength() external view returns (uint256);

  function createPair(address tokenA, address tokenB) external returns (address pair);

  function setFeeTo(address) external;

  function setFeeToSetter(address) external;

  function setMigrator(address) external;
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
pragma solidity 0.7.6;

import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IWETH.sol";
import "./libraries/SafeMath.sol";
import "./libraries/TokenInfo.sol";


contract Narwhal {
  using SafeMath for uint256;
  using TokenInfo for bytes32;

  address public immutable uniswapFactory;
  address public immutable sushiswapFactory;
  IWETH public immutable weth;

/** ========== Constructor ========== */

  constructor(
    address _uniswapFactory,
    address _sushiswapFactory,
    address _weth
  ) {
    uniswapFactory = _uniswapFactory;
    sushiswapFactory = _sushiswapFactory;
    weth = IWETH(_weth);
  }

/** ========== Fallback ========== */

  receive() external payable {
    assert(msg.sender == address(weth)); // only accept ETH via fallback from the WETH contract
  }

/** ========== Swaps ========== */

  // requires the initial amount to have already been sent to the first pair
  function _swap(uint[] memory amounts, bytes32[] memory path, address recipient) internal {
    for (uint i; i < path.length - 1; i++) {
      (bytes32 input, bytes32 output) = (path[i], path[i + 1]);
      uint amountOut = amounts[i + 1];
      (uint amount0Out, uint amount1Out) = (input < output) ? (uint(0), amountOut) : (amountOut, uint(0));
      address to = i < path.length - 2 ? pairFor(output, path[i + 2]) : recipient;
      IUniswapV2Pair(pairFor(input, output)).swap(
        amount0Out, amount1Out, to, new bytes(0)
      );
    }
  }

/** ========== Pair Calculation & Sorting ========== */

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

  function zeroForOne(bytes32 tokenA, bytes32 tokenB) internal pure returns (bool) {
    return tokenA < tokenB;
  }

  // returns sorted token addresses, used to handle return values from pairs sorted in this order
  function sortTokens(bytes32 tokenA, bytes32 tokenB)
    internal
    pure
    returns (bytes32 token0, bytes32 token1)
  {
    require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
    (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    require(token0 != bytes32(0), "UniswapV2Library: ZERO_ADDRESS");
  }

  function calculateUniPair(address token0, address token1 ) internal view returns (address pair) {
    pair = address(
      uint256(
        keccak256(
          abi.encodePacked(
            hex"ff",
            uniswapFactory,
            keccak256(abi.encodePacked(token0, token1)),
            hex"9eb68b7a819f9f79fb5e7fe2963d2903554d4fc0a0e1a5f9ffb0b20f77092809" // init code hash
          )
        )
      )
    );
  }

  function calculateSushiPair(address token0, address token1) internal view returns (address pair) {
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

  // calculates the CREATE2 address for a pair without making any external calls
  function pairFor(
    address tokenA,
    address tokenB,
    bool sushi
  ) internal view returns (address pair) {
    (address token0, address token1) = sortTokens(tokenA, tokenB);
    pair = sushi ? calculateSushiPair(token0, token1) : calculateUniPair(token0, token1);
  }

  // calculates the CREATE2 address for a pair without making any external calls
  function pairFor(bytes32 tokenInfoA, bytes32 tokenInfoB) internal view returns (address pair) {
    (address tokenA, bool sushi) = tokenInfoA.unpack();
    address tokenB = tokenInfoB.readToken();
    (address token0, address token1) = sortTokens(tokenA, tokenB);
    pair = sushi ? calculateSushiPair(token0, token1) : calculateUniPair(token0, token1);
  }

/** ========== Pair Reserves ========== */

  // fetches and sorts the reserves for a pair
  function getReserves(
    bytes32 tokenInfoA,
    bytes32 tokenInfoB
  ) internal view returns (uint256 reserveA, uint256 reserveB) {
    (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(pairFor(tokenInfoA, tokenInfoB)).getReserves();
    (reserveA, reserveB) = tokenInfoA < tokenInfoB
      ? (reserve0, reserve1)
      : (reserve1, reserve0);
  }

/** ========== Swap Amounts ========== */

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
    bytes32[] memory path,
    uint256 amountIn
  ) internal view returns (uint256[] memory amounts) {
    require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
    amounts = new uint[](path.length);
    amounts[0] = amountIn;
    for (uint i; i < path.length - 1; i++) {
      (uint reserveIn, uint reserveOut) = getReserves(path[i], path[i + 1]);
      amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
    }
  }

  // performs chained getAmountIn calculations on any number of pairs
  function getAmountsIn(
    bytes32[] memory path,
    uint256 amountOut
  ) internal view returns (uint256[] memory amounts) {
    require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
    amounts = new uint256[](path.length);
    amounts[amounts.length - 1] = amountOut;
    for (uint256 i = path.length - 1; i > 0; i--) {
      (uint256 reserveIn, uint256 reserveOut) = getReserves(path[i - 1], path[i]);
      amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
    }
  }
}