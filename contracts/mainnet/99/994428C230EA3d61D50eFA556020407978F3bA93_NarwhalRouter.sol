// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./libraries/NarwhalLibrary.sol";
import "./libraries/TransferHelper.sol";
import "./interfaces/INarwhalRouter.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IWETH.sol";


contract NarwhalRouter is INarwhalRouter {
  using TransferHelper for address;
  using NarwhalLibrary for bytes32;

  address public immutable override WETH;

  modifier ensure(uint256 deadline) {
    require(deadline >= block.timestamp, "NarwhalRouter: EXPIRED");
    _;
  }

  constructor(address _WETH) {
    WETH = _WETH;
  }

  receive() external payable {
    assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
  }

  // **** SWAP ****
  // requires the initial amount to have already been sent to the first pair
  function _swap(
    uint256[] memory amounts,
    bytes32[] memory path,
    address _to
  ) private {
    for (uint256 i; i < path.length; i++) {
      (bool zeroForOne, address pair) = path[i].unpack();
      uint256 amountOut = amounts[i + 1];
      (uint256 amount0Out, uint256 amount1Out) = zeroForOne ? (uint256(0), amountOut) : (amountOut, uint256(0));
      address to = i < path.length - 1 ? path[i + 1].readPair() : _to;
      IUniswapV2Pair(pair).swap(amount0Out, amount1Out, to, new bytes(0));
    }
  }

  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    bytes32[] calldata path,
    address to,
    uint256 deadline
  ) external override ensure(deadline) returns (uint256[] memory amounts) {
    amounts = NarwhalLibrary.getAmountsOut(amountIn, path);
    require(amounts[amounts.length - 1] >= amountOutMin, "NarwhalRouter: INSUFFICIENT_OUTPUT");
    path[0].tokenIn().safeTransferFrom(
      msg.sender,
      path[0].readPair(),
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
  ) external override ensure(deadline) returns (uint256[] memory amounts) {
    amounts = NarwhalLibrary.getAmountsIn(amountOut, path);
    require(amounts[0] <= amountInMax, "NarwhalRouter: EXCESSIVE_INPUT");
    path[0].tokenIn().safeTransferFrom(
      msg.sender,
      path[0].readPair(),
      amounts[0]
    );
    _swap(amounts, path, to);
  }

  function swapExactETHForTokens(
    uint256 amountOutMin,
    bytes32[] calldata path,
    address to,
    uint256 deadline
  ) external payable override ensure(deadline) returns (uint256[] memory amounts) {
    require(path[0].tokenIn() == WETH, "NarwhalRouter: INVALID_PATH");
    amounts = NarwhalLibrary.getAmountsOut(msg.value, path);
    require(amounts[amounts.length - 1] >= amountOutMin, "NarwhalRouter: INSUFFICIENT_OUTPUT");
    IWETH(WETH).deposit{value: amounts[0]}();
    assert(IWETH(WETH).transfer(path[0].readPair(), amounts[0]));
    _swap(amounts, path, to);
  }

  function swapTokensForExactETH(
    uint256 amountOut,
    uint256 amountInMax,
    bytes32[] calldata path,
    address to,
    uint256 deadline
  ) external override ensure(deadline) returns (uint256[] memory amounts) {
    require(path[path.length - 1].tokenOut() == WETH, "NarwhalRouter: INVALID_PATH");
    amounts = NarwhalLibrary.getAmountsIn(amountOut, path);
    require(amounts[0] <= amountInMax, "NarwhalRouter: EXCESSIVE_INPUT");
    path[0].tokenIn().safeTransferFrom(
      msg.sender,
      path[0].readPair(),
      amounts[0]
    );
    _swap(amounts, path, address(this));
    IWETH(WETH).withdraw(amounts[amounts.length - 1]);
    TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
  }

  function swapExactTokensForETH(
    uint256 amountIn,
    uint256 amountOutMin,
    bytes32[] calldata path,
    address to,
    uint256 deadline
  ) external override ensure(deadline) returns (uint256[] memory amounts) {
    require(path[path.length - 1].tokenOut() == WETH, "NarwhalRouter: INVALID_PATH");
    amounts = NarwhalLibrary.getAmountsOut(amountIn, path);
    require(amounts[amounts.length - 1] >= amountOutMin, "NarwhalRouter: INSUFFICIENT_OUTPUT");
    path[0].tokenIn().safeTransferFrom(
      msg.sender,
      path[0].readPair(),
      amounts[0]
    );
    _swap(amounts, path, address(this));
    IWETH(WETH).withdraw(amounts[amounts.length - 1]);
    TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
  }

  function swapETHForExactTokens(
    uint256 amountOut,
    bytes32[] calldata path,
    address to,
    uint256 deadline
  ) external payable override ensure(deadline) returns (uint256[] memory amounts) {
    require(path[0].tokenIn() == WETH, "NarwhalRouter: INVALID_PATH");
    amounts = NarwhalLibrary.getAmountsIn(amountOut, path);
    require(amounts[0] <= msg.value, "NarwhalRouter: EXCESSIVE_INPUT");
    IWETH(WETH).deposit{value: amounts[0]}();
    assert(IWETH(WETH).transfer(path[0].readPair(), amounts[0]));
    _swap(amounts, path, to);
    if (msg.value > amounts[0]) TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]); // refund dust eth, if any
  }

  function getAmountsOut(uint256 amountIn, bytes32[] memory path)
    public
    view
    override
    returns (uint256[] memory amounts)
  {
    return NarwhalLibrary.getAmountsOut(amountIn, path);
  }

  function getAmountsIn(uint256 amountOut, bytes32[] memory path)
    public
    view
    override
    returns (uint256[] memory amounts)
  {
    return NarwhalLibrary.getAmountsIn(amountOut, path);
  }
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
pragma solidity >=0.6.2;

interface INarwhalRouter {
  function WETH() external view returns (address);

  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    bytes32[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapTokensForExactTokens(
    uint256 amountOut,
    uint256 amountInMax,
    bytes32[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactETHForTokens(
    uint256 amountOutMin,
    bytes32[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function swapTokensForExactETH(
    uint256 amountOut,
    uint256 amountInMax,
    bytes32[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactTokensForETH(
    uint256 amountIn,
    uint256 amountOutMin,
    bytes32[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapETHForExactTokens(
    uint256 amountOut,
    bytes32[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function getAmountsOut(uint256 amountIn, bytes32[] calldata path) external view returns (uint256[] memory amounts);

  function getAmountsIn(uint256 amountOut, bytes32[] calldata path) external view returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;


interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
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

pragma solidity >=0.5.0;


interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "../interfaces/IUniswapV2Pair.sol";
import "./SafeMath.sol";


library NarwhalLibrary {
  using SafeMath for uint256;

  function unpack(bytes32 pairInfo) internal pure returns (bool zeroForOne, address pair) {
    assembly {
      zeroForOne := byte(31, pairInfo)
      pair := shr(8, pairInfo)
    }
  }

  function readPair(bytes32 pairInfo) internal pure returns (address pair) {
    assembly {
      pair := shr(8, pairInfo)
    }
  }

  function tokenIn(bytes32 pairInfo) internal view returns (address token) {
    (bool zeroForOne, address pair) = unpack(pairInfo);
    token = zeroForOne ? IUniswapV2Pair(pair).token0() : IUniswapV2Pair(pair).token1();
  }

  function tokenOut(bytes32 pairInfo) internal view returns (address token) {
    (bool zeroForOne, address pair) = unpack(pairInfo);
    token = zeroForOne ? IUniswapV2Pair(pair).token1() : IUniswapV2Pair(pair).token0();
  }

  function getReserves(bytes32 pairInfo) internal view returns (uint256 reserveIn, uint256 reserveOut) {
    (bool zeroForOne, address pair) = unpack(pairInfo);
    (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(pair).getReserves();
    (reserveIn, reserveOut) = zeroForOne ? (reserve0, reserve1) : (reserve1, reserve0);
  }

  function getAmountOut(bytes32 pairInfo, uint256 amountIn) internal view returns (uint256 amountOut) {
    require(amountIn > 0, "Narwhal: INSUFFICIENT INPUT");
    (uint256 reserveIn, uint256 reserveOut) = getReserves(pairInfo);
    require(reserveIn > 0 && reserveOut > 0, "Narwhal: INSUFFICIENT_LIQUIDITY");
    uint256 amountInWithFee = amountIn.mul(997);
    uint256 numerator = amountInWithFee.mul(reserveOut);
    uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
    amountOut = numerator / denominator;
  }

  function getAmountIn(bytes32 pairInfo, uint256 amountOut)
    internal
    view
    returns (uint256 amountIn)
  {
    require(amountOut > 0, "Narwhal: INSUFFICIENT_OUTPUT");
    (uint256 reserveIn, uint256 reserveOut) = getReserves(pairInfo);
    require(reserveIn > 0 && reserveOut > 0, "Narwhal: INSUFFICIENT_LIQUIDITY");
    uint256 numerator = reserveIn.mul(amountOut).mul(1000);
    uint256 denominator = reserveOut.sub(amountOut).mul(997);
    amountIn = (numerator / denominator).add(1);
  }

  function getAmountsOut(
    uint256 amountIn,
    bytes32[] memory path
  ) internal view returns (uint256[] memory amounts) {
    require(path.length >= 1, "Narwhal: INVALID_PATH");
    amounts = new uint256[](path.length + 1);
    amounts[0] = amountIn;
    for (uint256 i; i < path.length; i++) {
      amounts[i + 1] = getAmountOut(path[i], amounts[i]);
    }
  }

  // performs chained getAmountIn calculations on any number of pairs
  function getAmountsIn(uint256 amountOut, bytes32[] memory path)
    internal
    view
    returns (uint256[] memory amounts)
  {
    require(path.length >= 1, "Narwhal: INVALID_PATH");
    amounts = new uint256[](path.length + 1);
    amounts[amounts.length - 1] = amountOut;
    for (uint256 i = amounts.length - 1; i > 0; i--) {
      amounts[i - 1] = getAmountIn(path[i - 1], amounts[i]);
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

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "none",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 800
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