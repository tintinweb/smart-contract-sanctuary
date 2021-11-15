// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./core/access/Owned.sol";
import "./core/erc20/IERC20.sol";
import "./core/lifecycle/Initializable.sol";
import "./core/math/SafeMathLib.sol";
import "./pancakeswap/PancakeTransferHelper.sol";
import "./uniswapV2/IUniswapV2Factory.sol";
import "./uniswapV2/IUniswapV2Pair.sol";
import "./uniswapV2/IUniswapV2Router02.sol";


/**
 * @title Metahero swap router
 *
 * @author Stanisław Głogowski <[email protected]>
 */
contract MetaheroSwapRouter is Owned, Initializable {
  using SafeMathLib for uint256;

  address public token;
  address public factory;
  address public native;

  mapping (address => bool) private supportedTokens;

  // events

  /**
   * @dev Emitted when the contract is initialized
   * @param token token address
   * @param factory factory address
   * @param native native address
   */
  event Initialized(
    address token,
    address factory,
    address native
  );

  /**
   * @dev Emitted when supported token is added
   * @param token token address
   */
  event SupportedTokenAdded(
    address token
  );

  /**
   * @dev Emitted when supported token is removed
   * @param token token address
   */
  event SupportedTokenRemoved(
    address token
  );

  /**
   * @dev Public constructor
   */
  constructor ()
    public
    Owned()
    Initializable()
  {
    //
  }

  // external functions

  /**
   * @dev Initializes the contract
   * @param token_ token address
   * @param router_ router address
   */
  function initialize(
    address token_,
    address router_
  )
    external
    onlyInitializer
  {
    require(
      token_ != address(0),
      "MetaheroSwapRouter#1" // token is the zero address
    );

    require(
      router_ != address(0),
      "MetaheroSwapRouter#2" // router is the zero address
    );

    IUniswapV2Router02 router = IUniswapV2Router02(router_);

    token = token_;
    factory = router.factory();
    native = router.WETH();

    emit Initialized(
      token_,
      factory,
      native
    );
  }

  /**
   * @dev Adds supported token
   * @param token_ token address
   */
  function addSupportedToken(
    address token_
  )
    external
    onlyOwner
  {
    _addSupportedToken(token_);
  }

  /**
   * @dev Adds supported tokens
   * @param tokens tokens array
   */
  function addSupportedTokens(
    address[] calldata tokens
  )
    external
    onlyOwner
  {
    uint len = tokens.length;

    require(
      len != 0,
      "MetaheroSwapRouter#3" // tokens list is empty
    );

    for (uint index; index < len; index++) {
      _addSupportedToken(tokens[index]);
    }
  }

  /**
   * @dev Removes supported tokens
   * @param token_ token address
   */
  function removeSupportedToken(
    address token_
  )
    external
    onlyOwner
  {
    _removeSupportedToken(token_);
  }

  /**
   * @dev Removes supported tokens
   * @param tokens tokens array
   */
  function removeSupportedTokens(
    address[] calldata tokens
  )
    external
    onlyOwner
  {
    uint len = tokens.length;

    require(
      len != 0,
      "MetaheroSwapRouter#4" // tokens list is empty
    );

    for (uint index; index < len; index++) {
      _removeSupportedToken(tokens[index]);
    }
  }

  function swapSupportedTokens(
    address supportedToken,
    uint256 amountIn,
    uint256 amountOutMin
  )
    external
  {
    require(
      supportedTokens[supportedToken],
      "MetaheroSwapRouter#5" // token is not supported
    );

    address[] memory path = new address[](3);

    path[0] = supportedToken;
    path[1] = native;
    path[2] = token;

    _swapExactTokensForTokensSupportingFeeOnTransferTokens(
      amountIn,
      amountOutMin,
      path,
      msg.sender
    );
  }

  // private functions

  function _addSupportedToken(
    address token_
  )
    private
  {
    require(
      token_ != address(0),
      "MetaheroSwapRouter#6" // token is the zero address
    );

    require(
      !supportedTokens[token_],
      "MetaheroSwapRouter#7" // token already supported
    );

    supportedTokens[token_] = true;

    emit SupportedTokenAdded(
      token_
    );
  }

  function _removeSupportedToken(
    address token_
  )
    private
  {
    require(
      supportedTokens[token_],
      "MetaheroSwapRouter#8" // token is not supported
    );

    supportedTokens[token_] = false;

    emit SupportedTokenRemoved(
      token_
    );
  }

  function _swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint amountIn,
    uint amountOutMin,
    address[] memory path,
    address to
  )
    private
  {
    PancakeTransferHelper.safeTransferFrom(
      path[0], msg.sender, _pairFor(path[0], path[1]), amountIn
    );

    uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);

    _swapSupportingFeeOnTransferTokens(path, to);

    require(
      IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
      "MetaheroSwapRouter#9"
    );
  }

  function _swapSupportingFeeOnTransferTokens(
    address[] memory path,
    address _to
  )
    private
  {
    for (uint i; i < path.length - 1; i++) {
      (address input, address output) = (path[i], path[i + 1]);

      (address token0,) = _sortTokens(input, output);

      IUniswapV2Pair pair = IUniswapV2Pair(_pairFor(input, output));

      uint amountInput;
      uint amountOutput;

      {
        (uint reserve0, uint reserve1,) = pair.getReserves();
        (uint reserveInput, uint reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
        amountInput = IERC20(input).balanceOf(address(pair)).sub(reserveInput);
        amountOutput = _getAmountOut(amountInput, reserveInput, reserveOutput);
      }

      (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));

      address to = i < path.length - 2 ? _pairFor(output, path[i + 2]) : _to;

      pair.swap(amount0Out, amount1Out, to, new bytes(0));
    }
  }

  // private functions (views)

  function _pairFor(
    address tokenA,
    address tokenB
  )
    private
    view
    returns (address)
  {
    (address token0, address token1) = _sortTokens(tokenA, tokenB);

    return IUniswapV2Factory(factory).getPair(token0, token1);
  }

  // private functions (pure)

  function _sortTokens(
    address tokenA,
    address tokenB
  )
    private
    pure
    returns (address, address)
  {
    return tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
  }

  function _getAmountOut(
    uint amountIn,
    uint reserveIn,
    uint reserveOut
  )
    private
    pure
    returns (uint)
  {
    require(
      amountIn > 0,
      "MetaheroSwapRouter#10" // insufficient input amount
    );

    require(
      reserveIn > 0 &&
      reserveOut > 0,
      "MetaheroSwapRouter#11" // insufficient liquidity
    );

    uint amountInWithFee = amountIn.mul(998);
    uint numerator = amountInWithFee.mul(reserveOut);
    uint denominator = reserveIn.mul(1000).add(amountInWithFee);

    return numerator / denominator;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/**
 * @title Owned
 *
 * @author Stanisław Głogowski <[email protected]>
 */
contract Owned {
  /**
   * @return owner address
   */
  address public owner;

  // modifiers

  /**
   * @dev Throws if msg.sender is not the owner
   */
  modifier onlyOwner() {
    require(
      msg.sender == owner,
      "Owned#1" // msg.sender is not the owner
    );

    _;
  }

  // events

  /**
   * @dev Emitted when the owner is updated
   * @param owner new owner address
   */
  event OwnerUpdated(
    address owner
  );

  /**
   * @dev Internal constructor
   */
  constructor()
    internal
  {
    owner = msg.sender;
  }

  // external functions

  /**
   * @notice Sets a new owner
   * @param owner_ owner address
   */
  function setOwner(
    address owner_
  )
    external
    onlyOwner
  {
    _setOwner(owner_);
  }

  // internal functions

  function _setOwner(
    address owner_
  )
    internal
  {
    require(
      owner_ != address(0),
      "Owned#2" // owner is the zero address
    );

    require(
      owner_ != owner,
      "Owned#3" // does not update the owner
    );

    owner = owner_;

    emit OwnerUpdated(
      owner_
    );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/**
 * @title ERC20 token interface
 *
 * @notice See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 */
interface IERC20 {
  // events

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  // external functions

  function approve(
    address spender,
    uint256 value
  )
    external
    returns (bool);

  function transfer(
    address to,
    uint256 value
  )
    external
    returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    external
    returns (bool);

  // external functions (views)

  function totalSupply()
    external
    view
    returns (uint256);

  function balanceOf(
    address owner
  )
    external
    view
    returns (uint256);

  function allowance(
    address owner,
    address spender
  )
    external
    view
    returns (uint256);

  // external functions (pure)

  function name()
    external
    pure
    returns (string memory);

  function symbol()
    external
    pure
    returns (string memory);

  function decimals()
    external
    pure
    returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/**
 * @title Initializable
 *
 * @author Stanisław Głogowski <[email protected]>
 */
contract Initializable {
  address private initializer;

  // modifiers

  /**
   * @dev Throws if msg.sender is not the initializer
   */
  modifier onlyInitializer() {
    require(
      initializer != address(0),
      "Initializable#1" // already initialized
    );

    require(
      msg.sender == initializer,
      "Initializable#2" // msg.sender is not the initializer
    );

    /// @dev removes initializer
    initializer = address(0);

    _;
  }

  /**
   * @dev Internal constructor
   */
  constructor()
    internal
  {
    initializer = msg.sender;
  }

  // external functions (views)

  /**
   * @notice Checks if contract is initialized
   * @return true when contract is initialized
   */
  function initialized()
    external
    view
    returns (bool)
  {
    return initializer == address(0);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/**
 * @title Safe math library
 *
 * @notice Based on https://github.com/OpenZeppelin/openzeppelin-contracts/blob/5fe8f4e93bd1d4f5cc9a6899d7f24f5ffe4c14aa/contracts/math/SafeMath.sol
 */
library SafeMathLib {
  // internal functions (pure)

  /**
   * @notice Calcs a + b
   */
  function add(
    uint256 a,
    uint256 b
  )
    internal
    pure
    returns (uint256)
  {
    uint256 c = a + b;

    require(
      c >= a,
      "SafeMathLib#1"
    );

    return c;
  }

  /**
   * @notice Calcs a - b
   */
  function sub(
    uint256 a,
    uint256 b
  )
    internal
    pure
    returns (uint256)
  {
    require(
      b <= a,
      "SafeMathLib#2"
    );

    return a - b;
  }

  /**
   * @notice Calcs a x b
   */
  function mul(
    uint256 a,
    uint256 b
  )
    internal
    pure
    returns (uint256 result)
  {
    if (a != 0 && b != 0) {
      result = a * b;

      require(
        result / a == b,
        "SafeMathLib#3"
      );
    }

    return result;
  }

  /**
   * @notice Calcs a / b
   */
  function div(
    uint256 a,
    uint256 b
  )
    internal
    pure
    returns (uint256)
  {
    require(
      b != 0,
      "SafeMathLib#4"
    );

    return a / b;
  }
}

// SPDX-License-Identifier: GPL-3.0
/* solhint-disable */
pragma solidity ^0.6.12;

/**
 * @title Pancake transfer helper library
 *
 * @notice Based on https://github.com/pancakeswap/pancake-swap-lib/blob/0c16ece6edc575dc92076245badd62cddead47b3/contracts/utils/TransferHelper.sol
 */
library PancakeTransferHelper {
  // internal functions

  function safeApprove(
    address token,
    address to,
    uint256 value
  )
    internal
  {
    // bytes4(keccak256(bytes('approve(address,uint256)')));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
  }

  function safeTransfer(
    address token,
    address to,
    uint256 value
  )
    internal
  {
    // bytes4(keccak256(bytes('transfer(address,uint256)')));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
  }

  function safeTransferFrom(
    address token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
  }

  function safeTransferBNB(
    address to,
    uint256 value
  )
    internal
  {
    (bool success,) = to.call{value : value}(new bytes(0));
    require(success, 'TransferHelper: BNB_TRANSFER_FAILED');
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.12;

/**
 * @title Uniswap v2 factory interface
 *
 * @notice Based on https://github.com/Uniswap/uniswap-v2-core/blob/4dd59067c76dea4a0e8e4bfdda41877a6b16dedc/contracts/interfaces/IUniswapV2Factory.sol
 */
interface IUniswapV2Factory {
  // events

  event PairCreated(
    address indexed token0,
    address indexed token1,
    address pair,
    uint256
  );

  // external functions

  function createPair(
    address tokenA,
    address tokenB
  )
    external
    returns (address);

  function setFeeTo(
    address
  )
    external;

  function setFeeToSetter(
    address
  )
    external;

  // external functions (views)

  function feeTo()
    external
    view
    returns (address);

  function feeToSetter()
    external
    view
    returns (address);

  function getPair(
    address tokenA,
    address tokenB
  )
    external
    view
    returns (address);

  function allPairs(
    uint256
  )
    external
    view
    returns (address);

  function allPairsLength()
    external
    view
    returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
/* solhint-disable func-name-mixedcase */
pragma solidity ^0.6.12;

import "../core/erc20/IERC20.sol";


/**
 * @title Uniswap V2 pair interface
 *
 * @notice Based on https://github.com/Uniswap/uniswap-v2-core/blob/4dd59067c76dea4a0e8e4bfdda41877a6b16dedc/contracts/interfaces/IUniswapV2Pair.sol
 */
interface IUniswapV2Pair is IERC20 {
  // events

  event Mint(
    address indexed sender,
    uint256 amount0,
    uint256 amount1
  );

  event Burn(
    address indexed sender,
    uint256 amount0,
    uint256 amount1,
    address indexed to
  );

  event Swap(
    address indexed sender,
    uint256 amount0In,
    uint256 amount1In,
    uint256 amount0Out,
    uint256 amount1Out,
    address indexed to
  );

  event Sync(
    uint112 reserve0,
    uint112 reserve1
  );

  // external functions

  function initialize(
    address,
    address
  )
    external;

  function mint(
    address to
  )
    external
    returns (uint256);

  function burn(
    address to
  )
    external
    returns (uint256, uint256);

  function swap(
    uint256 amount0Out,
    uint256 amount1Out,
    address to,
    bytes calldata data
  )
    external;

  function skim(
    address to
  )
    external;

  function sync()
    external;

  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  )
    external;

  // external functions (views)

  function DOMAIN_SEPARATOR()
    external
    view
    returns (bytes32);

  function nonces(
    address owner
  )
    external
    view
    returns (uint256);

  function factory()
    external
    view
    returns (address);

  function token0()
    external
    view
    returns (address);

  function token1()
    external
    view
    returns (address);

  function getReserves()
    external
    view
    returns (uint112, uint112, uint32);

  function price0CumulativeLast()
    external
    view
    returns (uint256);

  function price1CumulativeLast()
    external
    view
    returns (uint256);

  function kLast()
    external
    view
    returns (uint256);

  // external functions (pure)

  function PERMIT_TYPEHASH()
    external
    pure
    returns (bytes32);

  function MINIMUM_LIQUIDITY()
    external
    pure
    returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.12;

import "./IUniswapV2Router01.sol";


/**
 * @title Uniswap V2 router02 interface
 *
 * @notice Based on https://github.com/Uniswap/uniswap-v2-periphery/blob/dda62473e2da448bc9cb8f4514dadda4aeede5f4/contracts/interfaces/IUniswapV2Router02.sol
 */
interface IUniswapV2Router02 is IUniswapV2Router01 {
  // external functions

  function swapExactETHForTokensSupportingFeeOnTransferTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  )
    external
    payable;

  function removeLiquidityETHSupportingFeeOnTransferTokens(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  )
    external
    returns (uint256);

  function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
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
  )
    external
    returns (uint256);

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  )
    external;

  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  )
    external;
}

// SPDX-License-Identifier: GPL-3.0
/* solhint-disable func-name-mixedcase */
pragma solidity ^0.6.12;

/**
 * @title Uniswap V2 router01 interface
 *
 * @notice Based on https://github.com/Uniswap/uniswap-v2-periphery/blob/dda62473e2da448bc9cb8f4514dadda4aeede5f4/contracts/interfaces/IUniswapV2Router01.sol
 */
interface IUniswapV2Router01 {
  // external functions

  function addLiquidityETH(
    address token,
    uint256 amountTokenDesired,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  )
    external
    payable
    returns (uint256, uint256, uint256);

  function swapExactETHForTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  )
    external
    payable
    returns (uint256[] memory);

  function addLiquidity(
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
    returns (uint256, uint256, uint256);

  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  )
    external
    returns (uint256, uint256);

  function removeLiquidityETH(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  )
    external
    returns (uint256, uint256);

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
  )
    external
    returns (uint256, uint256);

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
  )
    external
    returns (uint256, uint256);

  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  )
    external
    returns (uint256[] memory);

  function swapTokensForExactTokens(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to,
    uint256 deadline
  )
    external
    returns (uint256[] memory);

  function swapTokensForExactETH(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to,
    uint256 deadline
  )
    external
    returns (uint256[] memory);

  function swapExactTokensForETH(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  )
    external
    returns (uint256[] memory);

  function swapETHForExactTokens(
    uint256 amountOut,
    address[] calldata path,
    address to,
    uint256 deadline
  )
    external
    payable
    returns (uint256[] memory);

  // external functions (views)

  function getAmountsOut(
    uint256 amountIn,
    address[] calldata path
  )
    external
    view
    returns (uint256[] memory);

  function getAmountsIn(
    uint256 amountOut,
    address[] calldata path
  )
    external
    view
    returns (uint256[] memory);

  // external functions (pure)

  function quote(
    uint256 amountA,
    uint256 reserveA,
    uint256 reserveB
  )
    external
    pure
    returns (uint256);

  function getAmountOut(
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut
  )
    external
    pure
    returns (uint256);

  function getAmountIn(
    uint256 amountOut,
    uint256 reserveIn,
    uint256 reserveOut
  )
    external
    pure
    returns (uint256);

  function factory()
    external
    pure
    returns (address);

  function WETH()
    external
    pure
    returns (address);
}

