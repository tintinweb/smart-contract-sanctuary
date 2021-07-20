/**
 *Submitted for verification at BscScan.com on 2021-07-20
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6;
pragma abicoder v2;

interface IFireBirdFactory {
  event PairCreated(address indexed token0, address indexed token1, address pair, uint32 tokenWeight0, uint32 swapFee, uint256);

  function feeTo() external view returns (address);

  function formula() external view returns (address);

  function protocolFee() external view returns (uint256);

  function feeToSetter() external view returns (address);

  function getPair(
    address tokenA,
    address tokenB,
    uint32 tokenWeightA,
    uint32 swapFee
  ) external view returns (address pair);

  function allPairs(uint256) external view returns (address pair);

  function isPair(address) external view returns (bool);

  function allPairsLength() external view returns (uint256);

  function createPair(
    address tokenA,
    address tokenB,
    uint32 tokenWeightA,
    uint32 swapFee
  ) external returns (address pair);

  function getWeightsAndSwapFee(address pair)
    external
    view
    returns (
      uint32 tokenWeight0,
      uint32 tokenWeight1,
      uint32 swapFee
    );

  function setFeeTo(address) external;

  function setFeeToSetter(address) external;

  function setProtocolFee(uint256) external;
}

/*
    Bancor Formula interface
*/
interface IFireBirdFormula {
  function getFactoryReserveAndWeights(
    address factory,
    address pair,
    address tokenA,
    uint8 dexId
  )
    external
    view
    returns (
      address tokenB,
      uint256 reserveA,
      uint256 reserveB,
      uint32 tokenWeightA,
      uint32 tokenWeightB,
      uint32 swapFee
    );

  function getFactoryWeightsAndSwapFee(
    address factory,
    address pair,
    uint8 dexId
  )
    external
    view
    returns (
      uint32 tokenWeight0,
      uint32 tokenWeight1,
      uint32 swapFee
    );

  function getAmountIn(
    uint256 amountOut,
    uint256 reserveIn,
    uint256 reserveOut,
    uint32 tokenWeightIn,
    uint32 tokenWeightOut,
    uint32 swapFee
  ) external view returns (uint256 amountIn);

  function getAmountOut(
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut,
    uint32 tokenWeightIn,
    uint32 tokenWeightOut,
    uint32 swapFee
  ) external view returns (uint256 amountOut);

  function getFactoryAmountsIn(
    address factory,
    address tokenIn,
    address tokenOut,
    uint256 amountOut,
    address[] calldata path,
    uint8[] calldata dexIds
  ) external view returns (uint256[] memory amounts);

  function getFactoryAmountsOut(
    address factory,
    address tokenIn,
    address tokenOut,
    uint256 amountIn,
    address[] calldata path,
    uint8[] calldata dexIds
  ) external view returns (uint256[] memory amounts);

  function ensureConstantValue(
    uint256 reserve0,
    uint256 reserve1,
    uint256 balance0Adjusted,
    uint256 balance1Adjusted,
    uint32 tokenWeight0
  ) external view returns (bool);

  function getReserves(
    address pair,
    address tokenA,
    address tokenB
  ) external view returns (uint256 reserveA, uint256 reserveB);

  function getOtherToken(address pair, address tokenA) external view returns (address tokenB);

  function quote(
    uint256 amountA,
    uint256 reserveA,
    uint256 reserveB
  ) external pure returns (uint256 amountB);

  function sortTokens(address tokenA, address tokenB) external pure returns (address token0, address token1);

  function mintLiquidityFee(
    uint256 totalLiquidity,
    uint112 reserve0,
    uint112 reserve1,
    uint32 tokenWeight0,
    uint32 tokenWeight1,
    uint112 collectedFee0,
    uint112 collectedFee1
  ) external view returns (uint256 amount);
}

interface IFireBirdPair {
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);

  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

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

  event PaidProtocolFee(uint112 collectedFee0, uint112 collectedFee1);
  event Mint(address indexed sender, uint256 amount0, uint256 amount1);
  event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
  event Swap(address indexed sender, uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out, address indexed to);
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

  function getCollectedFees() external view returns (uint112 _collectedFee0, uint112 _collectedFee1);

  function getTokenWeights() external view returns (uint32 tokenWeight0, uint32 tokenWeight1);

  function getSwapFee() external view returns (uint32);

  function price0CumulativeLast() external view returns (uint256);

  function price1CumulativeLast() external view returns (uint256);

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

  function initialize(
    address,
    address,
    uint32,
    uint32
  ) external;
}

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
  function safeApprove(
    address token,
    address to,
    uint256 value
  ) internal {
    // bytes4(keccak256(bytes('approve(address,uint256)')));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: APPROVE_FAILED");
  }

  function safeTransfer(
    address token,
    address to,
    uint256 value
  ) internal {
    // bytes4(keccak256(bytes('transfer(address,uint256)')));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FAILED");
  }

  function safeTransferFrom(
    address token,
    address from,
    address to,
    uint256 value
  ) internal {
    // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FROM_FAILED");
  }

  function safeTransferETH(address to, uint256 value) internal {
    (bool success, ) = to.call{value: value}(new bytes(0));
    require(success, "TransferHelper: ETH_TRANSFER_FAILED");
  }
}

interface IERC20 {
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);

  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);

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
}

interface IFireBirdRouter {
  event Exchange(address pair, uint256 amountOut, address output);

  function factory() external view returns (address);

  function formula() external view returns (address);

  function WETH() external view returns (address);

  function addLiquidity(
    address pair,
    address tokenA,
    address tokenB,
    uint256 amountADesired,
    uint256 amountBDesired,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  )
    external
    returns (
      uint256 amountA,
      uint256 amountB,
      uint256 liquidity
    );

  function addLiquidityETH(
    address pair,
    address token,
    uint256 amountTokenDesired,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  )
    external
    payable
    returns (
      uint256 amountToken,
      uint256 amountETH,
      uint256 liquidity
    );

  function swapExactTokensForTokens(
    address tokenIn,
    address tokenOut,
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    uint8[] calldata dexIds,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapTokensForExactTokens(
    address tokenIn,
    address tokenOut,
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    uint8[] calldata dexIds,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactETHForTokens(
    address tokenOut,
    uint256 amountOutMin,
    address[] calldata path,
    uint8[] calldata dexIds,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function swapTokensForExactETH(
    address tokenIn,
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    uint8[] calldata dexIds,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactTokensForETH(
    address tokenIn,
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    uint8[] calldata dexIds,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapETHForExactTokens(
    address tokenOut,
    uint256 amountOut,
    address[] calldata path,
    uint8[] calldata dexIds,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    address tokenIn,
    address tokenOut,
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    uint8[] calldata dexIds,
    address to,
    uint256 deadline
  ) external;

  function swapExactETHForTokensSupportingFeeOnTransferTokens(
    address tokenOut,
    uint256 amountOutMin,
    address[] calldata path,
    uint8[] calldata dexIds,
    address to,
    uint256 deadline
  ) external payable;

  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    address tokenIn,
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    uint8[] calldata dexIds,
    address to,
    uint256 deadline
  ) external;

  function createPair(
    address tokenA,
    address tokenB,
    uint256 amountA,
    uint256 amountB,
    uint32 tokenWeightA,
    uint32 swapFee,
    address to
  ) external returns (uint256 liquidity);

  function createPairETH(
    address token,
    uint256 amountToken,
    uint32 tokenWeight,
    uint32 swapFee,
    address to
  ) external payable returns (uint256 liquidity);

  function removeLiquidity(
    address pair,
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountA, uint256 amountB);

  function removeLiquidityETH(
    address pair,
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountToken, uint256 amountETH);

  function removeLiquidityWithPermit(
    address pair,
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

  function removeLiquidityETHWithPermit(
    address pair,
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

  function removeLiquidityETHSupportingFeeOnTransferTokens(
    address pair,
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountETH);

  function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
    address pair,
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
  ) external returns (uint256 amountETH);
}

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)
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

  function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
    require(b > 0, "ds-math-division-by-zero");
    c = a / b;
  }
}

interface IWETH {
  function deposit() external payable;

  function transfer(address to, uint256 value) external returns (bool);

  function withdraw(uint256) external;

  function balanceOf(address account) external view returns (uint256);
}

interface IAggregationExecutor {
  function callBytes(bytes calldata data) external payable; // 0xd9c45357
}

interface IERC20Permit {
  function permit(
    address owner,
    address spender,
    uint256 amount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;
}

library RevertReasonParser {
  function parse(bytes memory data, string memory prefix) internal pure returns (string memory) {
    // https://solidity.readthedocs.io/en/latest/control-structures.html#revert
    // We assume that revert reason is abi-encoded as Error(string)

    // 68 = 4-byte selector 0x08c379a0 + 32 bytes offset + 32 bytes length
    if (data.length >= 68 && data[0] == "\x08" && data[1] == "\xc3" && data[2] == "\x79" && data[3] == "\xa0") {
      string memory reason;
      // solhint-disable no-inline-assembly
      assembly {
        // 68 = 32 bytes data length + 4-byte selector + 32 bytes offset
        reason := add(data, 68)
      }
      /*
                revert reason is padded up to 32 bytes with ABI encoder: Error(string)
                also sometimes there is extra 32 bytes of zeros padded in the end:
                https://github.com/ethereum/solidity/issues/10170
                because of that we can't check for equality and instead check
                that string length + extra 68 bytes is less than overall data length
            */
      require(data.length >= 68 + bytes(reason).length, "Invalid revert reason");
      return string(abi.encodePacked(prefix, "Error(", reason, ")"));
    }
    // 36 = 4-byte selector 0x4e487b71 + 32 bytes integer
    else if (data.length == 36 && data[0] == "\x4e" && data[1] == "\x48" && data[2] == "\x7b" && data[3] == "\x71") {
      uint256 code;
      // solhint-disable no-inline-assembly
      assembly {
        // 36 = 32 bytes data length + 4-byte selector
        code := mload(add(data, 36))
      }
      return string(abi.encodePacked(prefix, "Panic(", _toHex(code), ")"));
    }

    return string(abi.encodePacked(prefix, "Unknown(", _toHex(data), ")"));
  }

  function _toHex(uint256 value) private pure returns (string memory) {
    return _toHex(abi.encodePacked(value));
  }

  function _toHex(bytes memory data) private pure returns (string memory) {
    bytes16 alphabet = 0x30313233343536373839616263646566;
    bytes memory str = new bytes(2 + data.length * 2);
    str[0] = "0";
    str[1] = "x";
    for (uint256 i = 0; i < data.length; i++) {
      str[2 * i + 2] = alphabet[uint8(data[i] >> 4)];
      str[2 * i + 3] = alphabet[uint8(data[i] & 0x0f)];
    }
    return string(str);
  }
}

contract Permitable {
  event Error(string reason);

  function _permit(
    IERC20 token,
    uint256 amount,
    bytes calldata permit
  ) internal {
    if (permit.length == 32 * 7) {
      // solhint-disable-next-line avoid-low-level-calls
      (bool success, bytes memory result) = address(token).call(abi.encodePacked(IERC20Permit.permit.selector, permit));
      if (!success) {
        string memory reason = RevertReasonParser.parse(result, "Permit call failed: ");
        if (token.allowance(msg.sender, address(this)) < amount) {
          revert(reason);
        } else {
          emit Error(reason);
        }
      }
    }
  }
}

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
  constructor() internal {
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

contract FireBirdRouter is IFireBirdRouter, Ownable, Permitable {
  using SafeMath for uint256;
  address public immutable override factory;
  address public immutable override formula;
  address public immutable override WETH;
  address private constant ETH_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

  uint256 private constant _PARTIAL_FILL = 0x01;
  uint256 private constant _REQUIRES_EXTRA_ETH = 0x02;
  uint256 private constant _SHOULD_CLAIM = 0x04;
  uint256 private constant _BURN_FROM_MSG_SENDER = 0x08;
  uint256 private constant _BURN_FROM_TX_ORIGIN = 0x10;

  struct SwapDescription {
    IERC20 srcToken;
    IERC20 dstToken;
    address srcReceiver;
    address dstReceiver;
    uint256 amount;
    uint256 minReturnAmount;
    uint256 flags;
    bytes permit;
  }

  event Swapped(address sender, IERC20 srcToken, IERC20 dstToken, address dstReceiver, uint256 spentAmount, uint256 returnAmount);

  modifier ensure(uint256 deadline) {
    require(deadline >= block.timestamp, "Router: EXPIRED");
    _;
  }

  constructor(
    address _factory,
    address _formula,
    address _WETH
  ) public {
    factory = _factory;
    formula = _formula;
    WETH = _WETH;
  }

  receive() external payable {
    assert(msg.sender == WETH);
    // only accept ETH via fallback from the WETH contract
  }

  // **** ADD LIQUIDITY ****
  function _addLiquidity(
    address pair,
    address tokenA,
    address tokenB,
    uint256 amountADesired,
    uint256 amountBDesired,
    uint256 amountAMin,
    uint256 amountBMin
  ) internal virtual returns (uint256 amountA, uint256 amountB) {
    (uint256 reserveA, uint256 reserveB) = IFireBirdFormula(formula).getReserves(pair, tokenA, tokenB);
    if (reserveA == 0 && reserveB == 0) {
      (amountA, amountB) = (amountADesired, amountBDesired);
    } else {
      uint256 amountBOptimal = IFireBirdFormula(formula).quote(amountADesired, reserveA, reserveB);
      if (amountBOptimal <= amountBDesired) {
        require(amountBOptimal >= amountBMin, "Router: INSUFFICIENT_B_AMOUNT");
        (amountA, amountB) = (amountADesired, amountBOptimal);
      } else {
        uint256 amountAOptimal = IFireBirdFormula(formula).quote(amountBDesired, reserveB, reserveA);
        assert(amountAOptimal <= amountADesired);
        require(amountAOptimal >= amountAMin, "Router: INSUFFICIENT_A_AMOUNT");
        (amountA, amountB) = (amountAOptimal, amountBDesired);
      }
    }
  }

  function _addLiquidityToken(
    address pair,
    address tokenA,
    address tokenB,
    uint256 amountADesired,
    uint256 amountBDesired,
    uint256 amountAMin,
    uint256 amountBMin
  ) internal returns (uint256 amountA, uint256 amountB) {
    (amountA, amountB) = _addLiquidity(pair, tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
    TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
    TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
  }

  function createPair(
    address tokenA,
    address tokenB,
    uint256 amountA,
    uint256 amountB,
    uint32 tokenWeightA,
    uint32 swapFee,
    address to
  ) public virtual override returns (uint256 liquidity) {
    address pair = IFireBirdFactory(factory).createPair(tokenA, tokenB, tokenWeightA, swapFee);
    _addLiquidityToken(pair, tokenA, tokenB, amountA, amountB, 0, 0);
    liquidity = IFireBirdPair(pair).mint(to);
  }

  function addLiquidity(
    address pair,
    address tokenA,
    address tokenB,
    uint256 amountADesired,
    uint256 amountBDesired,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  )
    external
    virtual
    override
    ensure(deadline)
    returns (
      uint256 amountA,
      uint256 amountB,
      uint256 liquidity
    )
  {
    (amountA, amountB) = _addLiquidityToken(pair, tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
    liquidity = IFireBirdPair(pair).mint(to);
  }

  function _addLiquidityETH(
    address pair,
    address token,
    uint256 amountTokenDesired,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to
  )
    internal
    returns (
      uint256 amountToken,
      uint256 amountETH,
      uint256 liquidity
    )
  {
    (amountToken, amountETH) = _addLiquidity(pair, token, WETH, amountTokenDesired, msg.value, amountTokenMin, amountETHMin);
    TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);
    transferETHTo(amountETH, pair);
    liquidity = IFireBirdPair(pair).mint(to);
    // refund dust eth, if any
    if (msg.value > amountETH) TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);
  }

  function createPairETH(
    address token,
    uint256 amountToken,
    uint32 tokenWeight,
    uint32 swapFee,
    address to
  ) public payable virtual override returns (uint256 liquidity) {
    address pair = IFireBirdFactory(factory).createPair(token, WETH, tokenWeight, swapFee);
    (, , liquidity) = _addLiquidityETH(pair, token, amountToken, 0, 0, to);
  }

  function addLiquidityETH(
    address pair,
    address token,
    uint256 amountTokenDesired,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  )
    public
    payable
    virtual
    override
    ensure(deadline)
    returns (
      uint256 amountToken,
      uint256 amountETH,
      uint256 liquidity
    )
  {
    (amountToken, amountETH, liquidity) = _addLiquidityETH(pair, token, amountTokenDesired, amountTokenMin, amountETHMin, to);
  }

  // **** SWAP ****
  // requires the initial amount to have already been sent to the first pair
  function _swap(
    address tokenIn,
    uint256[] memory amounts,
    address[] memory path,
    address _to
  ) internal virtual {
    address input = tokenIn;
    for (uint256 i = 0; i < path.length; i++) {
      IFireBirdPair pairV2 = IFireBirdPair(path[i]);
      address token0 = pairV2.token0();
      uint256 amountOut = amounts[i + 1];
      (uint256 amount0Out, uint256 amount1Out, address output) = input == token0 ? (uint256(0), amountOut, pairV2.token1()) : (amountOut, uint256(0), token0);
      address to = i < path.length - 1 ? path[i + 1] : _to;
      pairV2.swap(amount0Out, amount1Out, to, new bytes(0));
      emit Exchange(address(pairV2), amountOut, output);
      input = output;
    }
  }

  function swapExactTokensForTokens(
    address tokenIn,
    address tokenOut,
    uint256 amountIn,
    uint256 amountOutMin,
    address[] memory path,
    uint8[] memory dexIds,
    address to,
    uint256 deadline
  ) public virtual override ensure(deadline) returns (uint256[] memory amounts) {
    amounts = _validateAmountOut(tokenIn, tokenOut, amountIn, amountOutMin, path, dexIds);

    TransferHelper.safeTransferFrom(tokenIn, msg.sender, path[0], amounts[0]);
    _swap(tokenIn, amounts, path, to);
  }

  function swapTokensForExactTokens(
    address tokenIn,
    address tokenOut,
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    uint8[] calldata dexIds,
    address to,
    uint256 deadline
  ) external virtual override ensure(deadline) returns (uint256[] memory amounts) {
    amounts = _validateAmountIn(tokenIn, tokenOut, amountOut, amountInMax, path, dexIds);

    TransferHelper.safeTransferFrom(tokenIn, msg.sender, path[0], amounts[0]);
    _swap(tokenIn, amounts, path, to);
  }

  function swapExactETHForTokens(
    address tokenOut,
    uint256 amountOutMin,
    address[] calldata path,
    uint8[] calldata dexIds,
    address to,
    uint256 deadline
  ) external payable virtual override ensure(deadline) returns (uint256[] memory amounts) {
    amounts = _validateAmountOut(WETH, tokenOut, msg.value, amountOutMin, path, dexIds);

    transferETHTo(amounts[0], path[0]);
    _swap(WETH, amounts, path, to);
  }

  function swapTokensForExactETH(
    address tokenIn,
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    uint8[] calldata dexIds,
    address to,
    uint256 deadline
  ) external virtual override ensure(deadline) returns (uint256[] memory amounts) {
    amounts = _validateAmountIn(tokenIn, WETH, amountOut, amountInMax, path, dexIds);

    TransferHelper.safeTransferFrom(tokenIn, msg.sender, path[0], amounts[0]);
    _swap(tokenIn, amounts, path, address(this));
    transferAll(ETH_ADDRESS, to, amounts[amounts.length - 1]);
  }

  function swapExactTokensForETH(
    address tokenIn,
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    uint8[] calldata dexIds,
    address to,
    uint256 deadline
  ) external virtual override ensure(deadline) returns (uint256[] memory amounts) {
    amounts = _validateAmountOut(tokenIn, WETH, amountIn, amountOutMin, path, dexIds);

    TransferHelper.safeTransferFrom(tokenIn, msg.sender, path[0], amounts[0]);
    _swap(tokenIn, amounts, path, address(this));
    transferAll(ETH_ADDRESS, to, amounts[amounts.length - 1]);
  }

  function swapETHForExactTokens(
    address tokenOut,
    uint256 amountOut,
    address[] calldata path,
    uint8[] calldata dexIds,
    address to,
    uint256 deadline
  ) external payable virtual override ensure(deadline) returns (uint256[] memory amounts) {
    amounts = _validateAmountIn(WETH, tokenOut, amountOut, msg.value, path, dexIds);

    transferETHTo(amounts[0], path[0]);
    _swap(WETH, amounts, path, to);
    // refund dust eth, if any
    if (msg.value > amounts[0]) TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]);
  }

  // **** SWAP (supporting fee-on-transfer tokens) ****
  // requires the initial amount to have already been sent to the first pair
  function _swapSupportingFeeOnTransferTokens(
    address tokenIn,
    address[] memory path,
    uint8[] memory dexIds,
    address _to
  ) internal virtual {
    for (uint256 i; i < path.length; i++) {
      uint256 amountOutput;
      address currentOutput;
      {
        (address output, uint256 reserveInput, uint256 reserveOutput, uint32 tokenWeightInput, , uint32 swapFee) =
          IFireBirdFormula(formula).getFactoryReserveAndWeights(factory, path[i], tokenIn, dexIds[i]);
        uint256 amountInput = IERC20(tokenIn).balanceOf(path[i]).sub(reserveInput);
        amountOutput = IFireBirdFormula(formula).getAmountOut(amountInput, reserveInput, reserveOutput, tokenWeightInput, 100 - tokenWeightInput, swapFee);
        currentOutput = output;
      }

      IFireBirdPair pair = IFireBirdPair(path[i]);
      (uint256 amount0Out, uint256 amount1Out) = tokenIn == pair.token0() ? (uint256(0), amountOutput) : (amountOutput, uint256(0));
      address to = i < path.length - 1 ? path[i + 1] : _to;
      pair.swap(amount0Out, amount1Out, to, new bytes(0));
      emit Exchange(path[i], amountOutput, currentOutput);
      tokenIn = currentOutput;
    }
  }

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    address tokenIn,
    address tokenOut,
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    uint8[] calldata dexIds,
    address to,
    uint256 deadline
  ) external virtual override ensure(deadline) {
    TransferHelper.safeTransferFrom(tokenIn, msg.sender, path[0], amountIn);
    uint256 balanceBefore = IERC20(tokenOut).balanceOf(to);
    _swapSupportingFeeOnTransferTokens(tokenIn, path, dexIds, to);
    require(IERC20(tokenOut).balanceOf(to).sub(balanceBefore) >= amountOutMin, "Router: INSUFFICIENT_OUTPUT_AMOUNT");
  }

  function swapExactETHForTokensSupportingFeeOnTransferTokens(
    address tokenOut,
    uint256 amountOutMin,
    address[] calldata path,
    uint8[] calldata dexIds,
    address to,
    uint256 deadline
  ) external payable virtual override ensure(deadline) {
    //            require(path[0] == WETH, 'Router: INVALID_PATH');
    uint256 amountIn = msg.value;
    transferETHTo(amountIn, path[0]);
    uint256 balanceBefore = IERC20(tokenOut).balanceOf(to);
    _swapSupportingFeeOnTransferTokens(WETH, path, dexIds, to);
    require(IERC20(tokenOut).balanceOf(to).sub(balanceBefore) >= amountOutMin, "Router: INSUFFICIENT_OUTPUT_AMOUNT");
  }

  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    address tokenIn,
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    uint8[] calldata dexIds,
    address to,
    uint256 deadline
  ) external virtual override ensure(deadline) {
    TransferHelper.safeTransferFrom(tokenIn, msg.sender, path[0], amountIn);
    _swapSupportingFeeOnTransferTokens(tokenIn, path, dexIds, address(this));
    uint256 amountOut = IERC20(WETH).balanceOf(address(this));
    require(amountOut >= amountOutMin, "Router: INSUFFICIENT_OUTPUT_AMOUNT");
    transferAll(ETH_ADDRESS, to, amountOut);
  }

  function swap(
    IAggregationExecutor caller,
    SwapDescription calldata desc,
    bytes calldata data
  ) external payable returns (uint256 returnAmount, uint256 gasLeft) {
    require(desc.minReturnAmount > 0, "Min return should not be 0");
    require(data.length > 0, "data should be not zero");

    uint256 flags = desc.flags;
    uint256 amount = desc.amount;
    IERC20 srcToken = desc.srcToken;
    IERC20 dstToken = desc.dstToken;

    if (flags & _REQUIRES_EXTRA_ETH != 0) {
      require(msg.value > (isETH(srcToken) ? amount : 0), "Invalid msg.value");
    } else {
      require(msg.value == (isETH(srcToken) ? amount : 0), "Invalid msg.value");
    }

    if (flags & _SHOULD_CLAIM != 0) {
      require(!isETH(srcToken), "Claim token is ETH");
      _permit(srcToken, amount, desc.permit);
      TransferHelper.safeTransferFrom(address(srcToken), msg.sender, desc.srcReceiver, amount);
    }

    address dstReceiver = (desc.dstReceiver == address(0)) ? msg.sender : desc.dstReceiver;
    uint256 initialSrcBalance = (flags & _PARTIAL_FILL != 0) ? getBalance(srcToken, msg.sender) : 0;
    uint256 initialDstBalance = getBalance(dstToken, dstReceiver);

    {
      // solhint-disable-next-line avoid-low-level-calls
      (bool success, bytes memory result) = address(caller).call{value: msg.value}(abi.encodeWithSelector(caller.callBytes.selector, data));
      if (!success) {
        revert(RevertReasonParser.parse(result, "callBytes failed: "));
      }
    }

    uint256 spentAmount = amount;
    returnAmount = getBalance(dstToken, dstReceiver).sub(initialDstBalance);

    if (flags & _PARTIAL_FILL != 0) {
      spentAmount = initialSrcBalance.add(amount).sub(getBalance(srcToken, msg.sender));
      require(returnAmount.mul(amount) >= desc.minReturnAmount.mul(spentAmount), "Return amount is not enough");
    } else {
      require(returnAmount >= desc.minReturnAmount, "Return amount is not enough");
    }

    emit Swapped(msg.sender, srcToken, dstToken, dstReceiver, spentAmount, returnAmount);
    emit Exchange(address(caller), returnAmount, isETH(dstToken) ? WETH : address(dstToken));

    gasLeft = gasleft();
  }

  function getBalance(IERC20 token, address account) internal view returns (uint256) {
    if (isETH(token)) {
      return account.balance;
    } else {
      return token.balanceOf(account);
    }
  }

  function _validateAmountOut(
    address tokenIn,
    address tokenOut,
    uint256 amountIn,
    uint256 amountOutMin,
    address[] memory path,
    uint8[] memory dexIds
  ) internal view returns (uint256[] memory amounts) {
    amounts = IFireBirdFormula(formula).getFactoryAmountsOut(factory, tokenIn, tokenOut, amountIn, path, dexIds);
    require(amounts[amounts.length - 1] >= amountOutMin, "Router: INSUFFICIENT_OUTPUT_AMOUNT");
  }

  function _validateAmountIn(
    address tokenIn,
    address tokenOut,
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    uint8[] calldata dexIds
  ) internal view returns (uint256[] memory amounts) {
    amounts = IFireBirdFormula(formula).getFactoryAmountsIn(factory, tokenIn, tokenOut, amountOut, path, dexIds);
    require(amounts[0] <= amountInMax, "Router: EXCESSIVE_INPUT_AMOUNT");
  }

  function transferETHTo(uint256 amount, address to) internal {
    IWETH(WETH).deposit{value: amount}();
    assert(IWETH(WETH).transfer(to, amount));
  }

  function transferAll(
    address token,
    address to,
    uint256 amount
  ) internal returns (bool) {
    if (amount == 0) {
      return true;
    }

    if (isETH(IERC20(token))) {
      IWETH(WETH).withdraw(amount);
      TransferHelper.safeTransferETH(to, amount);
    } else {
      TransferHelper.safeTransfer(token, to, amount);
    }
    return true;
  }

  function isETH(IERC20 token) internal pure returns (bool) {
    return (address(token) == ETH_ADDRESS);
  }

  // **** REMOVE LIQUIDITY ****
  function _removeLiquidity(
    address pair,
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to
  ) internal returns (uint256 amountA, uint256 amountB) {
    require(IFireBirdFactory(factory).isPair(pair), "Router: Invalid pair");
    IFireBirdPair(pair).transferFrom(msg.sender, pair, liquidity);
    // send liquidity to pair
    (uint256 amount0, uint256 amount1) = IFireBirdPair(pair).burn(to);
    (address token0, ) = IFireBirdFormula(formula).sortTokens(tokenA, tokenB);
    (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
    require(amountA >= amountAMin, "Router: INSUFFICIENT_A_AMOUNT");
    require(amountB >= amountBMin, "Router: INSUFFICIENT_B_AMOUNT");
  }

  function removeLiquidity(
    address pair,
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  ) public virtual override ensure(deadline) returns (uint256 amountA, uint256 amountB) {
    (amountA, amountB) = _removeLiquidity(pair, tokenA, tokenB, liquidity, amountAMin, amountBMin, to);
  }

  function removeLiquidityETH(
    address pair,
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) public virtual override ensure(deadline) returns (uint256 amountToken, uint256 amountETH) {
    (amountToken, amountETH) = _removeLiquidity(pair, token, WETH, liquidity, amountTokenMin, amountETHMin, address(this));
    TransferHelper.safeTransfer(token, to, amountToken);
    transferAll(ETH_ADDRESS, to, amountETH);
  }

  function removeLiquidityWithPermit(
    address pair,
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
  ) external virtual override ensure(deadline) returns (uint256 amountA, uint256 amountB) {
    {
      uint256 value = approveMax ? uint256(-1) : liquidity;
      IFireBirdPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
    }
    (amountA, amountB) = _removeLiquidity(pair, tokenA, tokenB, liquidity, amountAMin, amountBMin, to);
  }

  function removeLiquidityETHWithPermit(
    address pair,
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
  ) external virtual override returns (uint256 amountToken, uint256 amountETH) {
    uint256 value = approveMax ? uint256(-1) : liquidity;
    IFireBirdPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
    (amountToken, amountETH) = removeLiquidityETH(pair, token, liquidity, amountTokenMin, amountETHMin, to, deadline);
  }

  // **** REMOVE LIQUIDITY (supporting fee-on-transfer tokens) ****
  function removeLiquidityETHSupportingFeeOnTransferTokens(
    address pair,
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) public virtual override ensure(deadline) returns (uint256 amountETH) {
    (, amountETH) = removeLiquidity(pair, token, WETH, liquidity, amountTokenMin, amountETHMin, address(this), deadline);
    TransferHelper.safeTransfer(token, to, IERC20(token).balanceOf(address(this)));
    transferAll(ETH_ADDRESS, to, amountETH);
  }

  function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
    address pair,
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
  ) external virtual override returns (uint256 amountETH) {
    uint256 value = approveMax ? uint256(-1) : liquidity;
    IFireBirdPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
    amountETH = removeLiquidityETHSupportingFeeOnTransferTokens(pair, token, liquidity, amountTokenMin, amountETHMin, to, deadline);
  }

  function rescueFunds(address token, uint256 amount) external onlyOwner {
    if (isETH(IERC20(token))) {
      TransferHelper.safeTransferETH(msg.sender, amount);
    } else {
      TransferHelper.safeTransfer(token, msg.sender, amount);
    }
  }
}