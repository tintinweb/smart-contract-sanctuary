// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import './interfaces/IERC20.sol';
import './interfaces/IUniswap.sol';
import './interfaces/IWETH.sol';
import './libraries/MistXLibrary.sol';
import './libraries/SafeERC20.sol';
import './libraries/TransferHelper.sol';


/// @author Nathan Worsley (https://github.com/CodeForcer)
/// @title MistX Gasless Router
contract MistXRouter {
  /***********************
  + Global Settings      +
  ***********************/

  using SafeERC20 for IERC20;

  // The percentage we tip to the miners
  uint256 public bribePercent;

  // Owner of the contract and reciever of tips
  address public owner;

  // Managers are permissioned for critical functionality
  mapping (address => bool) public managers;

  address public immutable WETH;
  address public immutable factory;

  receive() external payable {}
  fallback() external payable {}

  constructor(
    address _WETH,
    address _factory
  ) {
    WETH = _WETH;
    factory = _factory;
    bribePercent = 99;

    owner = msg.sender;
    managers[msg.sender] = true;
  }

  /***********************
  + Structures           +
  ***********************/

  struct Swap {
    uint256 amount0;
    uint256 amount1;
    address[] path;
    address to;
    uint256 deadline;
  }

  /***********************
  + Swap wrappers        +
  ***********************/

  function swapExactETHForTokens(
    Swap calldata _swap,
    uint256 _bribe
  ) external payable {
    deposit(_bribe);

    require(_swap.path[0] == WETH, 'MistXRouter: INVALID_PATH');
    uint amountIn = msg.value - _bribe;
    IWETH(WETH).deposit{value: amountIn}();
    assert(IWETH(WETH).transfer(MistXLibrary.pairFor(factory, _swap.path[0], _swap.path[1]), amountIn));
    uint balanceBefore = IERC20(_swap.path[_swap.path.length - 1]).balanceOf(_swap.to);
    _swapSupportingFeeOnTransferTokens(_swap.path, _swap.to);
    require(
      IERC20(_swap.path[_swap.path.length - 1]).balanceOf(_swap.to) - balanceBefore >= _swap.amount1,
      'MistXRouter: INSUFFICIENT_OUTPUT_AMOUNT'
    );
  }

  function swapETHForExactTokens(
    Swap calldata _swap,
    uint256 _bribe
  ) external payable {
    deposit(_bribe);

    require(_swap.path[0] == WETH, 'UniswapV2Router: INVALID_PATH');
    uint[] memory amounts = MistXLibrary.getAmountsIn(factory, _swap.amount1, _swap.path);
    require(amounts[0] <= msg.value - _bribe, 'UniswapV2Router: EXCESSIVE_INPUT_AMOUNT');
    IWETH(WETH).deposit{value: amounts[0]}();
    assert(IWETH(WETH).transfer(MistXLibrary.pairFor(factory, _swap.path[0], _swap.path[1]), amounts[0]));
    _swapPath(amounts, _swap.path, _swap.to);

    // refund dust eth, if any
    if (msg.value - _bribe > amounts[0]) {
      (bool success, ) = msg.sender.call{value: msg.value - _bribe - amounts[0]}(new bytes(0));
      require(success, 'safeTransferETH: ETH transfer failed');
    }
  }

  function swapExactTokensForTokens(
    Swap calldata _swap,
    uint256 _bribe
  ) external payable {
    deposit(_bribe);

    TransferHelper.safeTransferFrom(
      _swap.path[0], msg.sender, MistXLibrary.pairFor(factory, _swap.path[0], _swap.path[1]), _swap.amount0
    );
    uint balanceBefore = IERC20(_swap.path[_swap.path.length - 1]).balanceOf(_swap.to);
    _swapSupportingFeeOnTransferTokens(_swap.path, _swap.to);
    require(
      IERC20(_swap.path[_swap.path.length - 1]).balanceOf(_swap.to) - balanceBefore >= _swap.amount1,
      'MistXRouter: INSUFFICIENT_OUTPUT_AMOUNT'
    );
  }

  function swapTokensForExactTokens(
    Swap calldata _swap,
    uint256 _bribe
  ) external payable {
    deposit(_bribe);

    uint[] memory amounts = MistXLibrary.getAmountsIn(factory, _swap.amount0, _swap.path);
    require(amounts[0] <= _swap.amount1, 'MistXRouter: EXCESSIVE_INPUT_AMOUNT');
    TransferHelper.safeTransferFrom(
      _swap.path[0], msg.sender, MistXLibrary.pairFor(factory, _swap.path[0], _swap.path[1]), amounts[0]
    );
    _swapPath(amounts, _swap.path, _swap.to);
  }

  function swapTokensForExactETH(
    Swap calldata _swap,
    uint256 _bribe
  ) external payable {
    require(_swap.path[_swap.path.length - 1] == WETH, 'MistXRouter: INVALID_PATH');
    uint[] memory amounts = MistXLibrary.getAmountsIn(factory, _swap.amount0, _swap.path);
    require(amounts[0] <= _swap.amount1, 'MistXRouter: EXCESSIVE_INPUT_AMOUNT');
    TransferHelper.safeTransferFrom(
        _swap.path[0], msg.sender, MistXLibrary.pairFor(factory, _swap.path[0], _swap.path[1]), amounts[0]
    );
    _swapPath(amounts, _swap.path, address(this));
    IWETH(WETH).withdraw(amounts[amounts.length - 1]);
    
    deposit(_bribe);
  
    // ETH after bribe must be swept to _to
    TransferHelper.safeTransferETH(_swap.to, amounts[amounts.length - 1]);
  }

  function swapExactTokensForETH(
    Swap calldata _swap,
    uint256 _bribe
  ) external payable {
    require(_swap.path[_swap.path.length - 1] == WETH, 'MistXRouter: INVALID_PATH');
    TransferHelper.safeTransferFrom(
      _swap.path[0], msg.sender, MistXLibrary.pairFor(factory, _swap.path[0], _swap.path[1]), _swap.amount0
    );
    _swapSupportingFeeOnTransferTokens(_swap.path, address(this));
    uint amountOut = IERC20(WETH).balanceOf(address(this));
    require(amountOut >= _swap.amount1, 'MistXRouter: INSUFFICIENT_OUTPUT_AMOUNT');
    IWETH(WETH).withdraw(amountOut);

    deposit(_bribe);
  
    // ETH after bribe must be swept to _to
    TransferHelper.safeTransferETH(_swap.to, amountOut - _bribe);
  }

  /***********************
  + Support functions    +
  ***********************/

  function deposit(uint256 value) public payable {
    require(value > 0, "Don't be stingy");
    uint256 bribe = (value * bribePercent) / 100;
    block.coinbase.transfer(bribe);
    payable(owner).transfer(value - bribe);
  }

  function _swapSupportingFeeOnTransferTokens(
    address[] memory path,
    address _to
  ) internal virtual {
    for (uint i; i < path.length - 1; i++) {
      (address input, address output) = (path[i], path[i + 1]);
      (address token0,) = MistXLibrary.sortTokens(input, output);
      IUniswapV2Pair pair = IUniswapV2Pair(MistXLibrary.pairFor(factory, input, output));
      uint amountInput;
      uint amountOutput;
      {
        (uint reserve0, uint reserve1,) = pair.getReserves();
        (uint reserveInput, uint reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
        amountInput = IERC20(input).balanceOf(address(pair)) - reserveInput;
        amountOutput = MistXLibrary.getAmountOut(amountInput, reserveInput, reserveOutput);
      }
      (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
      address to = i < path.length - 2 ? MistXLibrary.pairFor(factory, output, path[i + 2]) : _to;
      pair.swap(amount0Out, amount1Out, to, new bytes(0));
    }
  }

  function _swapPath(
    uint[] memory amounts,
    address[] memory path,
    address _to
  ) internal virtual {
    for (uint i; i < path.length - 1; i++) {
      (address input, address output) = (path[i], path[i + 1]);
      (address token0,) = MistXLibrary.sortTokens(input, output);
      uint amountOut = amounts[i + 1];
      (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
      address to = i < path.length - 2 ? MistXLibrary.pairFor(factory, output, path[i + 2]) : _to;
      IUniswapV2Pair(MistXLibrary.pairFor(factory, input, output)).swap(
        amount0Out, amount1Out, to, new bytes(0)
      );
    }
  }

  /***********************
  + Administration       +
  ***********************/

  event OwnershipChanged(
    address indexed oldOwner,
    address indexed newOwner
  );

  modifier onlyOwner() {
    require(msg.sender == owner, "Only the owner can call this");
    _;
  }

  modifier onlyManager() {
    require(managers[msg.sender] == true, "Only managers can call this");
    _;
  }

  function addManager(
    address _manager
  ) external onlyOwner {
    managers[_manager] = true;
  }

  function removeManager(
    address _manager
  ) external onlyOwner {
    managers[_manager] = false;
  }

  function changeOwner(
    address _owner
  ) public onlyOwner {
    emit OwnershipChanged(owner, _owner);
    owner = _owner;
  }

  function changeBribe(
    uint256 _bribePercent
  ) public onlyManager {
    if (_bribePercent > 100) {
      revert("Split must be a valid percentage");
    }
    bribePercent = _bribePercent;
  }

  function rescueStuckETH(
    uint256 _amount,
    address _to
  ) external onlyManager {
    payable(_to).transfer(_amount);
  }

  function rescueStuckToken(
    address _tokenContract,
    uint256 _value,
    address _to
  ) external onlyManager {
    IERC20(_tokenContract).safeTransfer(_to, _value);
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface IERC20 {
  event Approval(address indexed owner, address indexed spender, uint value);
  event Transfer(address indexed from, address indexed to, uint value);

  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function decimals() external view returns (uint8);
  function totalSupply() external view returns (uint);
  function balanceOf(address owner) external view returns (uint);
  function allowance(address owner, address spender) external view returns (uint);

  function approve(address spender, uint value) external returns (bool);
  function transfer(address to, uint value) external returns (bool);
  function transferFrom(address from, address to, uint value) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface IUniswapRouter {
  function WETH() external view returns (address);

  function addLiquidity(
    address tokenA,
    address tokenB,
    uint256 amountADesired,
    uint256 amountBDesired,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  ) external returns (
    uint256 amountA,
    uint256 amountB,
    uint256 liquidity
  );

  function addLiquidityETH(
    address token,
    uint256 amountTokenDesired,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) external payable returns (
    uint256 amountToken,
    uint256 amountETH,
    uint256 liquidity
  );

  function factory() external view returns (address);

  function getAmountIn(
    uint256 amountOut,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountIn);

  function getAmountOut(
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountOut);

  function getAmountsIn(
    uint256 amountOut,
    address[] memory path
  ) external view returns (uint256[] memory amounts);

  function getAmountsOut(
    uint256 amountIn,
    address[] memory path
  ) external view returns (uint256[] memory amounts);

  function quote(
    uint256 amountA,
    uint256 reserveA,
    uint256 reserveB
  ) external pure returns (uint256 amountB);

  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountA, uint256 amountB);

  function removeLiquidityETH(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountToken, uint256 amountETH);

  function removeLiquidityETHWithPermit(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountToken, uint256 amountETH);

  function removeLiquidityWithPermit(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountA, uint256 amountB);

  function swapETHForExactTokens(
    uint256 amountOut,
    address[] memory path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function swapExactETHForTokens(
    uint256 amountOutMin,
    address[] memory path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function swapExactTokensForETH(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] memory path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] memory path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapTokensForExactETH(
    uint256 amountOut,
    uint256 amountInMax,
    address[] memory path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapTokensForExactTokens(
    uint256 amountOut,
    uint256 amountInMax,
    address[] memory path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external;

  function swapExactETHForTokensSupportingFeeOnTransferTokens(
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external payable;

  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external;

  receive() external payable;
}

interface IUniswapV2Pair {
  event Approval(address indexed owner, address indexed spender, uint value);
  event Transfer(address indexed from, address indexed to, uint value);

  function name() external pure returns (string memory);
  function symbol() external pure returns (string memory);
  function decimals() external pure returns (uint8);
  function totalSupply() external view returns (uint);
  function balanceOf(address owner) external view returns (uint);
  function allowance(address owner, address spender) external view returns (uint);

  function approve(address spender, uint value) external returns (bool);
  function transfer(address to, uint value) external returns (bool);
  function transferFrom(address from, address to, uint value) external returns (bool);

  function DOMAIN_SEPARATOR() external view returns (bytes32);
  function PERMIT_TYPEHASH() external pure returns (bytes32);
  function nonces(address owner) external view returns (uint);

  function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

  event Mint(address indexed sender, uint amount0, uint amount1);
  event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
  event Swap(
    address indexed sender,
    uint amount0In,
    uint amount1In,
    uint amount0Out,
    uint amount1Out,
    address indexed to
  );

  event Sync(uint112 reserve0, uint112 reserve1);

  function MINIMUM_LIQUIDITY() external pure returns (uint);
  function factory() external view returns (address);
  function token0() external view returns (address);
  function token1() external view returns (address);
  function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
  function price0CumulativeLast() external view returns (uint);
  function price1CumulativeLast() external view returns (uint);
  function kLast() external view returns (uint);

  function mint(address to) external returns (uint liquidity);
  function burn(address to) external returns (uint amount0, uint amount1);
  function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
  function skim(address to) external;
  function sync() external;

  function initialize(address, address) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface IWETH {
  function deposit() external payable;
  function transfer(address to, uint value) external returns (bool);
  function withdraw(uint) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import '../interfaces/IUniswap.sol';

library MistXLibrary {
  // returns sorted token addresses, used to handle return values from pairs sorted in this order
  function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
    require(tokenA != tokenB, 'MistXLibrary: IDENTICAL_ADDRESSES');
    (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    require(token0 != address(0), 'MistXLibrary: ZERO_ADDRESS');
  }

  // calculates the CREATE2 address for a pair without making any external calls
  function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
    (address token0, address token1) = sortTokens(tokenA, tokenB);
    uint hashed = uint(keccak256(abi.encodePacked(
      hex'ff',
      factory,
      keccak256(abi.encodePacked(token0, token1)),
      hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
    )));
    pair = address(uint160(hashed));
  }

  // fetches and sorts the reserves for a pair
  function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
    (address token0,) = sortTokens(tokenA, tokenB);
    (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
    (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
  }

  // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
  function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
    require(amountA > 0, 'MistXLibrary: INSUFFICIENT_AMOUNT');
    require(reserveA > 0 && reserveB > 0, 'MistXLibrary: INSUFFICIENT_LIQUIDITY');
    amountB = amountA * (reserveB) / reserveA;
  }

  // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
  function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
    require(amountIn > 0, 'MistXLibrary: INSUFFICIENT_INPUT_AMOUNT');
    require(reserveIn > 0 && reserveOut > 0, 'MistXLibrary: INSUFFICIENT_LIQUIDITY');
    uint amountInWithFee = amountIn * 997;
    uint numerator = amountInWithFee * reserveOut;
    uint denominator = reserveIn * 1000 + amountInWithFee;
    amountOut = numerator / denominator;
  }

  // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
  function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
    require(amountOut > 0, 'MistXLibrary: INSUFFICIENT_OUTPUT_AMOUNT');
    require(reserveIn > 0 && reserveOut > 0, 'MistXLibrary: INSUFFICIENT_LIQUIDITY');
    uint numerator = reserveIn * amountOut * 1000;
    uint denominator = (reserveOut - amountOut) * 997;
    amountIn = (numerator / denominator) + 1;
  }

  // performs chained getAmountOut calculations on any number of pairs
  function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
    require(path.length >= 2, 'MistXLibrary: INVALID_PATH');
    amounts = new uint[](path.length);
    amounts[0] = amountIn;
    for (uint i; i < path.length - 1; i++) {
      (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
      amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
    }
  }

  // performs chained getAmountIn calculations on any number of pairs
  function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
    require(path.length >= 2, 'MistXLibrary: INVALID_PATH');
    amounts = new uint[](path.length);
    amounts[amounts.length - 1] = amountOut;
    for (uint i = path.length - 1; i > 0; i--) {
      (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
      amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
    }
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "../interfaces/IERC20.sol";
import "./Address.sol";

library SafeERC20 {
  using Address for address;

  function safeTransfer(IERC20 token, address to, uint256 value) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
  }

  function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
  }

  function safeApprove(IERC20 token, address spender, uint256 value) internal {
    require((value == 0) || (token.allowance(address(this), spender) == 0),
      "SafeERC20: approve from non-zero to non-zero allowance"
    );
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
  }

  function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
    uint256 newAllowance = token.allowance(address(this), spender) + value;
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
  }

  function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
    uint256 newAllowance = token.allowance(address(this), spender) - value;
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
  }

  function _callOptionalReturn(IERC20 token, bytes memory data) private {
    bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
    if (returndata.length > 0) {
      require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
  function safeApprove(
    address token,
    address to,
    uint256 value
  ) internal {
    // bytes4(keccak256(bytes('approve(address,uint256)')));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
    require(
      success && (data.length == 0 || abi.decode(data, (bool))),
      'TransferHelper::safeApprove: approve failed'
    );
  }

  function safeTransfer(
    address token,
    address to,
    uint256 value
  ) internal {
    // bytes4(keccak256(bytes('transfer(address,uint256)')));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
    require(
      success && (data.length == 0 || abi.decode(data, (bool))),
      'TransferHelper::safeTransfer: transfer failed'
    );
  }

  function safeTransferFrom(
    address token,
    address from,
    address to,
    uint256 value
  ) internal {
    // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
    require(
      success && (data.length == 0 || abi.decode(data, (bool))),
      'TransferHelper::transferFrom: transferFrom failed'
    );
  }

  function safeTransferETH(address to, uint256 value) internal {
    (bool success, ) = to.call{value: value}(new bytes(0));
    require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

library Address {
    function isContract(address account) internal view returns (bool) {
      // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
      // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
      // for accounts without code, i.e. `keccak256('')`
      bytes32 codehash;
      bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
      assembly { codehash := extcodehash(account) }
      return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
      require(address(this).balance >= amount, "Address: insufficient balance");

      (bool success, ) = recipient.call{ value: amount }("");
      require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
      return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
      return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
      require(address(this).balance >= value, "Address: insufficient balance for call");
      return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
      require(isContract(target), "Address: call to non-contract");

      (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
      if (success) {
        return returndata;
      } else {
        if (returndata.length > 0) {
          assembly {
            let returndata_size := mload(returndata)
            revert(add(32, returndata), returndata_size)
          }
        } else {
          revert(errorMessage);
        }
      }
    }
}

