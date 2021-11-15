// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./core/access/Owned.sol";
import "./core/erc20/IERC20.sol";
import "./core/lifecycle/Initializable.sol";
import "./core/math/SafeMathLib.sol";
import "./pancakeswap/PancakePair.sol";
import "./pancakeswap/PancakeLibrary.sol";
import "./pancakeswap/PancakeTransferHelper.sol";
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
      path[0], msg.sender, PancakeLibrary.pairFor(factory, path[0], path[1]), amountIn
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

      (address token0,) = PancakeLibrary.sortTokens(input, output);

      IUniswapV2Pair pair = IUniswapV2Pair(PancakeLibrary.pairFor(factory, input, output));

      uint amountInput;
      uint amountOutput;

      {
        (uint reserve0, uint reserve1,) = pair.getReserves();
        (uint reserveInput, uint reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
        amountInput = IERC20(input).balanceOf(address(pair)).sub(reserveInput);
        amountOutput = PancakeLibrary.getAmountOut(amountInput, reserveInput, reserveOutput);
      }

      (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));

      address to = i < path.length - 2 ? PancakeLibrary.pairFor(factory, output, path[i + 2]) : _to;

      pair.swap(amount0Out, amount1Out, to, new bytes(0));
    }
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

import '../core/erc20/IERC20.sol';
import '../core/math/SafeMathLib.sol';
import '../uniswapV2/IUniswapV2Factory.sol';
import '../uniswapV2/IUniswapV2Pair.sol';
import './IPancakeCallee.sol';
import './PancakeMath.sol';
import './PancakeUQ112x112.sol';


/**
 * @title Pancake pair
 *
 * @notice Based on https://github.com/pancakeswap/pancake-swap-core/blob/3b214306770e86bc3a64e67c2b5bdb566b4e94a7/contracts/PancakePair.sol
 */
contract PancakePair is IUniswapV2Pair {
  using SafeMathLib for uint;
  using PancakeUQ112x112 for uint224;

  uint public constant override MINIMUM_LIQUIDITY = 10 ** 3;
  bytes32 public constant override PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9; // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

  bytes32 public override DOMAIN_SEPARATOR;

  string public override name = 'Pancake LPs';
  string public override symbol = 'Cake-LP';
  uint8 public override decimals = 18;
  uint public override totalSupply;

  mapping(address => uint) public override balanceOf;
  mapping(address => mapping(address => uint)) public override allowance;
  mapping(address => uint) public override nonces;

  address public override factory;
  address public override token0;
  address public override token1;

  uint public override price0CumulativeLast;
  uint public override price1CumulativeLast;
  uint public override kLast;

  bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

  uint112 private reserve0;
  uint112 private reserve1;
  uint32 private blockTimestampLast;
  uint private unlocked = 1;

  // modifiers

  modifier lock() {
    require(unlocked == 1, 'Pancake: LOCKED');
    unlocked = 0;
    _;
    unlocked = 1;
  }

  // events

  event Mint(
    address indexed sender,
    uint amount0,
    uint amount1
  );

  event Burn(
    address indexed sender,
    uint amount0,
    uint amount1,
    address indexed to
  );

  event Swap(
    address indexed sender,
    uint amount0In,
    uint amount1In,
    uint amount0Out,
    uint amount1Out,
    address indexed to
  );

  event Sync(
    uint112 reserve0,
    uint112 reserve1
  );

  constructor()
    public
  {
    factory = msg.sender;

    uint chainId;

    assembly {
      chainId := chainid()
    }

    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
        keccak256(bytes(name)),
        keccak256(bytes('1')),
        chainId,
        address(this)
      )
    );
  }

  // external functions

  function initialize(
    address _token0,
    address _token1
  )
    external
    override
  {
    require(msg.sender == factory, 'Pancake: FORBIDDEN');
    // sufficient check
    token0 = _token0;
    token1 = _token1;
  }

  function approve(
    address spender,
    uint value
  )
    external
    override
    returns (bool)
  {
    _approve(msg.sender, spender, value);
    return true;
  }

  function transfer(address to, uint value)
    external
    override
    returns (bool)
  {
    _transfer(msg.sender, to, value);
    return true;
  }

  function transferFrom(
    address from,
    address to,
    uint value
  )
    external
    override
    returns (bool)
  {
    if (allowance[from][msg.sender] != uint(- 1)) {
      allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
    }
    _transfer(from, to, value);
    return true;
  }

  function permit(
    address owner,
    address spender,
    uint value,
    uint deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  )
    external
    override
  {
    require(deadline >= block.timestamp, 'Pancake: EXPIRED');
    bytes32 digest = keccak256(
      abi.encodePacked(
        '\x19\x01',
        DOMAIN_SEPARATOR,
        keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
      )
    );
    address recoveredAddress = ecrecover(digest, v, r, s);
    require(recoveredAddress != address(0) && recoveredAddress == owner, 'Pancake: INVALID_SIGNATURE');
    _approve(owner, spender, value);
  }

  function mint(
    address to
  )
    external
    override
    lock
    returns (uint liquidity)
  {
    (uint112 _reserve0, uint112 _reserve1,) = getReserves();
    // gas savings
    uint balance0 = IERC20(token0).balanceOf(address(this));
    uint balance1 = IERC20(token1).balanceOf(address(this));
    uint amount0 = balance0.sub(_reserve0);
    uint amount1 = balance1.sub(_reserve1);

    bool feeOn = _mintFee(_reserve0, _reserve1);
    uint _totalSupply = totalSupply;
    // gas savings, must be defined here since totalSupply can update in _mintFee
    if (_totalSupply == 0) {
      liquidity = PancakeMath.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
      _mint(address(0), MINIMUM_LIQUIDITY);
      // permanently lock the first MINIMUM_LIQUIDITY tokens
    } else {
      liquidity = PancakeMath.min(amount0.mul(_totalSupply) / _reserve0, amount1.mul(_totalSupply) / _reserve1);
    }
    require(liquidity > 0, 'Pancake: INSUFFICIENT_LIQUIDITY_MINTED');
    _mint(to, liquidity);

    _update(balance0, balance1, _reserve0, _reserve1);
    if (feeOn) kLast = uint(reserve0).mul(reserve1);
    // reserve0 and reserve1 are up-to-date
    emit Mint(msg.sender, amount0, amount1);
  }

  function burn(
    address to
  )
    external
    override
    lock
    returns (uint amount0, uint amount1)
  {
    (uint112 _reserve0, uint112 _reserve1,) = getReserves();
    // gas savings
    address _token0 = token0;
    // gas savings
    address _token1 = token1;
    // gas savings
    uint balance0 = IERC20(_token0).balanceOf(address(this));
    uint balance1 = IERC20(_token1).balanceOf(address(this));
    uint liquidity = balanceOf[address(this)];

    bool feeOn = _mintFee(_reserve0, _reserve1);
    uint _totalSupply = totalSupply;
    // gas savings, must be defined here since totalSupply can update in _mintFee
    amount0 = liquidity.mul(balance0) / _totalSupply;
    // using balances ensures pro-rata distribution
    amount1 = liquidity.mul(balance1) / _totalSupply;
    // using balances ensures pro-rata distribution
    require(amount0 > 0 && amount1 > 0, 'Pancake: INSUFFICIENT_LIQUIDITY_BURNED');
    _burn(address(this), liquidity);
    _safeTransfer(_token0, to, amount0);
    _safeTransfer(_token1, to, amount1);
    balance0 = IERC20(_token0).balanceOf(address(this));
    balance1 = IERC20(_token1).balanceOf(address(this));

    _update(balance0, balance1, _reserve0, _reserve1);
    if (feeOn) kLast = uint(reserve0).mul(reserve1);
    // reserve0 and reserve1 are up-to-date
    emit Burn(msg.sender, amount0, amount1, to);
  }

  function swap(
    uint amount0Out,
    uint amount1Out,
    address to,
    bytes calldata data
  )
    external
    override
    lock
  {
    require(amount0Out > 0 || amount1Out > 0, 'Pancake: INSUFFICIENT_OUTPUT_AMOUNT');
    (uint112 _reserve0, uint112 _reserve1,) = getReserves();
    // gas savings
    require(amount0Out < _reserve0 && amount1Out < _reserve1, 'Pancake: INSUFFICIENT_LIQUIDITY');

    uint balance0;
    uint balance1;
    {// scope for _token{0,1}, avoids stack too deep errors
      address _token0 = token0;
      address _token1 = token1;
      require(to != _token0 && to != _token1, 'Pancake: INVALID_TO');
      if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out);
      // optimistically transfer tokens
      if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out);
      // optimistically transfer tokens
      if (data.length > 0) IPancakeCallee(to).pancakeCall(msg.sender, amount0Out, amount1Out, data);
      balance0 = IERC20(_token0).balanceOf(address(this));
      balance1 = IERC20(_token1).balanceOf(address(this));
    }
    uint amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
    uint amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
    require(amount0In > 0 || amount1In > 0, 'Pancake: INSUFFICIENT_INPUT_AMOUNT');
    {// scope for reserve{0,1}Adjusted, avoids stack too deep errors
      uint balance0Adjusted = balance0.mul(1000).sub(amount0In.mul(2));
      uint balance1Adjusted = balance1.mul(1000).sub(amount1In.mul(2));
      require(balance0Adjusted.mul(balance1Adjusted) >= uint(_reserve0).mul(_reserve1).mul(1000 ** 2), 'Pancake: K');
    }

    _update(balance0, balance1, _reserve0, _reserve1);
    emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
  }

  function skim(
    address to
  )
    external
    override
    lock
  {
    address _token0 = token0;
    // gas savings
    address _token1 = token1;
    // gas savings
    _safeTransfer(_token0, to, IERC20(_token0).balanceOf(address(this)).sub(reserve0));
    _safeTransfer(_token1, to, IERC20(_token1).balanceOf(address(this)).sub(reserve1));
  }

  function sync()
    external
    override
    lock
  {
    _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)), reserve0, reserve1);
  }

  // public functions (views)

  function getReserves()
    public
    override
    view
    returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast)
  {
    _reserve0 = reserve0;
    _reserve1 = reserve1;
    _blockTimestampLast = blockTimestampLast;
  }

  // private functions

  function _mint(
    address to,
    uint value
  )
    private
  {
    totalSupply = totalSupply.add(value);
    balanceOf[to] = balanceOf[to].add(value);
    emit Transfer(address(0), to, value);
  }

  function _burn(
    address from,
    uint value
  )
    private
  {
    balanceOf[from] = balanceOf[from].sub(value);
    totalSupply = totalSupply.sub(value);
    emit Transfer(from, address(0), value);
  }

  function _approve(
    address owner,
    address spender,
    uint value
  )
    private
  {
    allowance[owner][spender] = value;
    emit Approval(owner, spender, value);
  }

  function _transfer(
    address from,
    address to,
    uint value
  )
    private
  {
    balanceOf[from] = balanceOf[from].sub(value);
    balanceOf[to] = balanceOf[to].add(value);
    emit Transfer(from, to, value);
  }

  function _safeTransfer(
    address token,
    address to,
    uint value
  )
    private
  {
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), 'Pancake: TRANSFER_FAILED');
  }

  function _update(
    uint balance0,
    uint balance1,
    uint112 _reserve0,
    uint112 _reserve1
  )
    private
  {
    require(balance0 <= uint112(- 1) && balance1 <= uint112(- 1), 'Pancake: OVERFLOW');
    uint32 blockTimestamp = uint32(block.timestamp % 2 ** 32);
    uint32 timeElapsed = blockTimestamp - blockTimestampLast;
    // overflow is desired
    if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
      // * never overflows, and + overflow is desired
      price0CumulativeLast += uint(PancakeUQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
      price1CumulativeLast += uint(PancakeUQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
    }
    reserve0 = uint112(balance0);
    reserve1 = uint112(balance1);
    blockTimestampLast = blockTimestamp;
    emit Sync(reserve0, reserve1);
  }

  function _mintFee(
    uint112 _reserve0,
    uint112 _reserve1
  )
    private
    returns (bool feeOn)
  {
    address feeTo = IUniswapV2Factory(factory).feeTo();
    feeOn = feeTo != address(0);
    uint _kLast = kLast;
    // gas savings
    if (feeOn) {
      if (_kLast != 0) {
        uint rootK = PancakeMath.sqrt(uint(_reserve0).mul(_reserve1));
        uint rootKLast = PancakeMath.sqrt(_kLast);
        if (rootK > rootKLast) {
          uint numerator = totalSupply.mul(rootK.sub(rootKLast));
          uint denominator = rootK.mul(3).add(rootKLast);
          uint liquidity = numerator / denominator;
          if (liquidity > 0) _mint(feeTo, liquidity);
        }
      }
    } else if (_kLast != 0) {
      kLast = 0;
    }
  }
}

// SPDX-License-Identifier: GPL-3.0
/* solhint-disable */
pragma solidity ^0.6.12;

import "../core/math/SafeMathLib.sol";
import "../uniswapV2/IUniswapV2Pair.sol";


/**
 * @title Pancake library
 *
 * @notice Based on https://github.com/pancakeswap/pancake-swap-periphery/blob/d769a6d136b74fde82502ec2f9334acc1afc0732/contracts/libraries/PancakeLibrary.sol
 */
library PancakeLibrary {
  using SafeMathLib for uint;

  bytes32 private constant INIT_CODE_PAIR_HASH = hex'67ff6ba22a1de13d367e0a03399b52c2c9f8fec0dae145427b8f7d7e843026a3';

  // internal functions (pure)

  function sortTokens(
    address tokenA,
    address tokenB
  )
    internal
    pure
    returns (address token0, address token1)
  {
    require(tokenA != tokenB, 'PancakeLibrary: IDENTICAL_ADDRESSES');
    (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    require(token0 != address(0), 'PancakeLibrary: ZERO_ADDRESS');
  }

  function pairFor(
    address factory,
    address tokenA,
    address tokenB
  )
    internal
    pure
    returns (address pair)
  {
    (address token0, address token1) = sortTokens(tokenA, tokenB);
    pair = address(uint(keccak256(abi.encodePacked(
        hex'ff',
        factory,
        keccak256(abi.encodePacked(token0, token1)),
        INIT_CODE_PAIR_HASH
      ))));
  }

  function quote(
    uint amountA,
    uint reserveA,
    uint reserveB
  )
    internal
    pure
    returns (uint amountB)
  {
    require(amountA > 0, 'PancakeLibrary: INSUFFICIENT_AMOUNT');
    require(reserveA > 0 && reserveB > 0, 'PancakeLibrary: INSUFFICIENT_LIQUIDITY');
    amountB = amountA.mul(reserveB) / reserveA;
  }

  function getAmountOut(
    uint amountIn,
    uint reserveIn,
    uint reserveOut
  )
    internal
    pure
    returns (uint amountOut)
  {
    require(amountIn > 0, 'PancakeLibrary: INSUFFICIENT_INPUT_AMOUNT');
    require(reserveIn > 0 && reserveOut > 0, 'PancakeLibrary: INSUFFICIENT_LIQUIDITY');
    uint amountInWithFee = amountIn.mul(998);
    uint numerator = amountInWithFee.mul(reserveOut);
    uint denominator = reserveIn.mul(1000).add(amountInWithFee);
    amountOut = numerator / denominator;
  }

  function getAmountIn(
    uint amountOut,
    uint reserveIn,
    uint reserveOut
  )
    internal
    pure
    returns (uint amountIn)
  {
    require(amountOut > 0, 'PancakeLibrary: INSUFFICIENT_OUTPUT_AMOUNT');
    require(reserveIn > 0 && reserveOut > 0, 'PancakeLibrary: INSUFFICIENT_LIQUIDITY');
    uint numerator = reserveIn.mul(amountOut).mul(1000);
    uint denominator = reserveOut.sub(amountOut).mul(998);
    amountIn = (numerator / denominator).add(1);
  }

  // internal functions (pure)

  function getReserves(
    address factory,
    address tokenA,
    address tokenB
  )
    internal
    view
    returns (uint reserveA, uint reserveB)
  {
    (address token0,) = sortTokens(tokenA, tokenB);
    pairFor(factory, tokenA, tokenB);
    (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
    (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
  }

  function getAmountsOut(
    address factory,
    uint amountIn,
    address[] memory path
  )
    internal
    view
    returns (uint[] memory amounts)
  {
    require(path.length >= 2, 'PancakeLibrary: INVALID_PATH');
    amounts = new uint[](path.length);
    amounts[0] = amountIn;
    for (uint i; i < path.length - 1; i++) {
      (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
      amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
    }
  }

  function getAmountsIn(
    address factory,
    uint amountOut,
    address[] memory path
  )
    internal
    view
    returns (uint[] memory amounts)
  {
    require(path.length >= 2, 'PancakeLibrary: INVALID_PATH');
    amounts = new uint[](path.length);
    amounts[amounts.length - 1] = amountOut;
    for (uint i = path.length - 1; i > 0; i--) {
      (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
      amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
    }
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
pragma solidity ^0.6.12;

/**
 * @title Pancake callee interfaces
 *
 * @notice Based on https://github.com/pancakeswap/pancake-swap-core/blob/3b214306770e86bc3a64e67c2b5bdb566b4e94a7/contracts/interfaces/IPancakeCallee.sol
 */
interface IPancakeCallee {
  // external functions

  function pancakeCall(
    address sender,
    uint amount0,
    uint amount1,
    bytes calldata data
  )
    external;
}

// SPDX-License-Identifier: GPL-3.0
/* solhint-disable */
pragma solidity ^0.6.12;

/**
 * @title Pancake math library
 *
 * @notice Based on https://github.com/pancakeswap/pancake-swap-core/blob/3b214306770e86bc3a64e67c2b5bdb566b4e94a7/contracts/libraries/Math.sol
 */
library PancakeMath {
  // internal functions (pure)

  function min(
    uint x,
    uint y
  )
    internal
    pure
    returns (uint)
  {
    return x < y ? x : y;
  }

  function sqrt(
    uint y
  )
    internal
    pure
    returns (uint z)
  {
    if (y > 3) {
      z = y;
      uint x = y / 2 + 1;
      while (x < z) {
        z = x;
        x = (y / x + x) / 2;
      }
    } else if (y != 0) {
      z = 1;
    }

    return z;
  }
}

// SPDX-License-Identifier: GPL-3.0
/* solhint-disable */
pragma solidity ^0.6.12;

/**
 * @title Pancake UQ112x112 library
 *
 * @notice Based on https://github.com/pancakeswap/pancake-swap-core/blob/3b214306770e86bc3a64e67c2b5bdb566b4e94a7/contracts/libraries/UQ112x112.sol
 */
library PancakeUQ112x112 {
  uint224 internal constant Q112 = 2 ** 112;

  // internal functions (pure)

  function encode(
    uint112 y
  )
    internal
    pure
    returns (uint224)
  {
    return uint224(y) * Q112;
  }

  function uqdiv(
    uint224 x,
    uint112 y
  )
    internal
    pure
    returns (uint224)
  {
    return x / uint224(y);
  }
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

