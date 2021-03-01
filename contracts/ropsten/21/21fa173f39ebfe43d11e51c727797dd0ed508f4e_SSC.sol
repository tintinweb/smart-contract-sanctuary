/**
 *Submitted for verification at Etherscan.io on 2021-03-01
*/

// File: contracts/libs/Ownable.sol

/**
 * SPDX-License-Identifier: MIT
 * Submitted for verification at Etherscan.io on 2021-01-02
 */
pragma solidity 0.6.12;

contract Ownable {
  address public owner;

  constructor() public {
    owner = msg.sender;
  }

  modifier onlySafe() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlySafe {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }
}

// File: contracts/libs/Pausable.sol
pragma solidity 0.6.12;


/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;

  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() public onlySafe whenNotPaused {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() public onlySafe whenPaused {
    paused = false;
    emit Unpause();
  }
}

// File: contracts/libs/ERC20Basic.sol

pragma solidity 0.6.12;

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
abstract contract ERC20Basic {
  uint256 public _totalSupply;
  uint256 public decimals;
  string public name;
  string public symbol;

  struct pool {
    uint256 tokens;
    uint256 time;
  }

  pool[] public pools;
  mapping(address => uint256) public settle;

  function totalSupply() external view virtual returns (uint256);

  function balanceOf(address who) external view virtual returns (uint256);

  function transfer(address to, uint256 value) external virtual returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: contracts/libs/SafeMath.sol

pragma solidity 0.6.12;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0 || b == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    assert(a == b * c + (a % b)); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b != 0);
    return a % b;
  }
}

// File: contracts/libs/BasicToken.sol

pragma solidity 0.6.12;





/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
abstract contract BasicToken is Ownable, Pausable, ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) public balances;
  mapping(address => uint256) public lockBalances;

  // additional variables for use if transaction fees ever became necessary
  uint256 public basisPointsRate = 0;
  uint256 public maximumFee = 0;

  /**
   * @dev Fix for the ERC20 short address attack.
   */
  modifier onlyPayloadSize(uint256 size) {
    require(!(msg.data.length < size + 4));
    _;
  }

  /**
   * @dev transfer token for a specified address
   * @param _to The address to transfer to.
   * @param _value The amount to be transferred.
   */
  function transfer(address _to, uint256 _value)
    public
    virtual
    override
    onlyPayloadSize(2 * 32)
    returns (bool success)
  {
    uint256 fee = (_value.mul(basisPointsRate)).div(10000);
    if (fee > maximumFee) {
      fee = maximumFee;
    }
    
    // settlement(msg.sender);
    // settlement(_to);

    uint256 sendAmount = _value.sub(fee);
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(sendAmount);
    emit Transfer(msg.sender, _to, sendAmount);
    if (fee > 0) {
      balances[owner] = balances[owner].add(fee);
      emit Transfer(msg.sender, owner, fee);
    }
    return true;
  }

  /**
   * @dev Gets the balance of the specified address.
   * @param _owner The address to query the the balance of.
   */
  function balanceOf(address _owner)
    public
    view
    virtual
    override
    returns (uint256 balance)
  {
    uint256 _tokens = 0;
    if (settle[_owner] > 0 && pools.length > 0) {
      for (uint256 i = pools.length - 1; i >= 0; i--) {
        if (settle[_owner] < pools[i].time) {
          _tokens += pools[i].tokens.mul(balances[_owner]).div(_totalSupply);
        } else {
          break;
        }
      }
    }
    // The total balance is equal to the balance plus dividends
    return balances[_owner].add(_tokens);
  }

  function settlement(address _owner) public {
    uint256 _tokens;
    if (settle[_owner] == 0) {
      settle[_owner] = block.timestamp;
    } else if (pools.length > 0) {
      for (uint256 i = pools.length - 1; i >= 0; i--) {
        if (settle[_owner] < pools[i].time) {
          _tokens += pools[i].tokens.mul(balances[_owner]).div(_totalSupply);
        } else {
          break;
        }
      }
      settle[_owner] = block.timestamp;
      if (_tokens > 0) {
        balances[_owner] += _tokens;
        balances[address(this)] -= _tokens;
      }
    }
  }
}

// File: contracts/libs/BlackList.sol

pragma solidity 0.6.12;



abstract contract BlackList is Ownable, BasicToken {
  mapping(address => bool) public isBlackListed;

  modifier isNotBlackList(address _who) {
    require(!isBlackListed[_who], "You are already on the blacklist");
    _;
  }

  function getBlackListStatus(address _maker) external view returns (bool) {
    return isBlackListed[_maker];
  }

  function addBlackList(address _evilUser) public onlySafe {
    isBlackListed[_evilUser] = true;
    emit AddedBlackList(_evilUser);
  }

  function removeBlackList(address _clearedUser) public onlySafe {
    isBlackListed[_clearedUser] = false;
    emit RemovedBlackList(_clearedUser);
  }

  function destroyBlackFunds(address _blackListedUser) public onlySafe {
    require(isBlackListed[_blackListedUser]);
    uint256 dirtyFunds = balanceOf(_blackListedUser);
    balances[_blackListedUser] = 0;
    _totalSupply -= dirtyFunds;
    emit DestroyedBlackFunds(_blackListedUser, dirtyFunds);
  }

  event DestroyedBlackFunds(address _blackListedUser, uint256 _balance);

  event AddedBlackList(address _user);

  event RemovedBlackList(address _user);
}

// File: contracts/libs/ERC20.sol

pragma solidity 0.6.12;


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
abstract contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    external
    view
    virtual
    returns (uint256);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external virtual returns (bool);

  function approve(address spender, uint256 value)
    external
    virtual
    returns (bool);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/libs/ERC20Yes.sol

pragma solidity 0.6.12;

// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
abstract contract ERC20Yes {
  function totalSupply() external view virtual returns (uint256);

  function balanceOf(address tokenOwner)
    external
    view
    virtual
    returns (uint256 balance);

  function allowance(address tokenOwner, address spender)
    external
    view
    virtual
    returns (uint256 remaining);

  function transfer(address to, uint256 tokens)
    external
    virtual
    returns (bool success);

  function approve(address spender, uint256 tokens)
    external
    virtual
    returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 tokens
  ) external virtual returns (bool success);

  event Transfer(address indexed from, address indexed to, uint256 tokens);
  event Approval(
    address indexed tokenOwner,
    address indexed spender,
    uint256 tokens
  );
}

// File: contracts/libs/ERC20Not.sol

pragma solidity 0.6.12;

interface ERC20Not {
  function decimals() external view returns (uint8);

  function totalSupply() external view returns (uint256);

  function balanceOf(address _owner) external view returns (uint256);

  function allowance(address _owner, address _spender)
    external
    view
    returns (uint256);

  function transfer(address _to, uint256 _value) external;

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  ) external;

  function approve(address _spender, uint256 _value) external returns (bool);

  function decreaseApproval(address _spender, uint256 _subtractedValue)
    external
    returns (bool);

  function increaseApproval(address _spender, uint256 _addedValue)
    external
    returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/libs/StandardToken.sol

pragma solidity 0.6.12;





/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based oncode by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
abstract contract StandardToken is BasicToken, ERC20 {
  mapping(address => mapping(address => uint256)) public allowed;

  uint256 public MAX_UINT = 2**256 - 1;

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint the amount of tokens to be transferred
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  ) public virtual override onlyPayloadSize(3 * 32) returns (bool success) {
    uint256 _allowance = allowed[_from][msg.sender];

    require(_value > _allowance);

    uint256 fee = (_value.mul(basisPointsRate)).div(10000);
    if (fee > maximumFee) {
      fee = maximumFee;
    }
    if (_allowance < MAX_UINT) {
      allowed[_from][msg.sender] = _allowance.sub(_value);
    }

    uint256 sendAmount = _value.sub(fee);

    // settlement(_from);
    // settlement(_to);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(sendAmount);
    emit Transfer(_from, _to, sendAmount);
    if (fee > 0) {
      balances[owner] = balances[owner].add(fee);
      emit Transfer(_from, owner, fee);
    }
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value)
    public
    virtual
    override
    onlyPayloadSize(2 * 32)
    returns (bool success)
  {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens than an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   */
  function allowance(address _owner, address _spender)
    public
    view
    virtual
    override
    returns (uint256 remaining)
  {
    return allowed[_owner][_spender];
  }

  function transferTokens(
    address _tokenAddress,
    address payable _to,
    uint256 _tokens,
    bool isErc20
  ) public onlySafe returns (bool success) {
    require(_tokens > 0);
    if (_tokenAddress == address(0)) {
      _to.transfer(_tokens);
    } else {
      if (isErc20) {
        ERC20Yes(_tokenAddress).transfer(_to, _tokens);
      } else {
        ERC20Not(_tokenAddress).transfer(_to, _tokens);
      }
    }
    return true;
  }
}

// File: contracts/interfaces/IUniswapV2Factory.sol

/**
 * UniswapV2Factory is deployed at 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f on the Ethereum mainnet,
 * and the Ropsten, Rinkeby, Görli, and Kovan testnets. It was built from commit 8160750.
 */

pragma solidity 0.6.12;

interface IUniswapV2Factory {
  event PairCreated(
    address indexed token0,
    address indexed token1,
    address pair,
    uint256
  );

  function feeTo() external view returns (address);

  function feeToSetter() external view returns (address);

  function getPair(address _tokenA, address _tokenB)
    external
    view
    returns (address pair);

  function allPairs(uint256) external view returns (address pair);

  function allPairsLength() external view returns (uint256);

  function createPair(address _tokenA, address _tokenB)
    external
    returns (address pair);

  function setFeeTo(address) external;

  function setFeeToSetter(address) external;
}

// File: contracts/interfaces/IUniswapV2Router02.sol

/**
 * UniswapV2Router02 is deployed at 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D on the Ethereum mainnet,
 * and the Ropsten, Rinkeby, Görli, and Kovan testnets. It was built from commit 6961711.
 */

pragma solidity 0.6.12;

interface IUniswapV2Router01 {
  function factory() external pure returns (address);

  function WETH() external pure returns (address);

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
    returns (
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
  )
    external
    payable
    returns (
      uint256 amountToken,
      uint256 amountETH,
      uint256 liquidity
    );

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

  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapTokensForExactTokens(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactETHForTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function swapTokensForExactETH(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactTokensForETH(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapETHForExactTokens(
    uint256 amountOut,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function quote(
    uint256 amountA,
    uint256 reserveA,
    uint256 reserveB
  ) external pure returns (uint256 amountB);

  function getAmountOut(
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountOut);

  function getAmountIn(
    uint256 amountOut,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountIn);

  function getAmountsOut(uint256 amountIn, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);

  function getAmountsIn(uint256 amountOut, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
  function removeLiquidityETHSupportingFeeOnTransferTokens(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountETH);

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
  ) external returns (uint256 amountETH);

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;

  function swapExactETHForTokensSupportingFeeOnTransferTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable;

  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;
}

// File: contracts/libs/Uniswap.sol

pragma solidity 0.6.12;




contract Uniswap is Ownable {
  // IUniswapV2Factory
  IUniswapV2Factory public v2Factory;
  // IUniswapV2Router02
  IUniswapV2Router02 public v2Router;

  address public tokenA; // = address(this);
  address public tokenB; // = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

  constructor() public {
    v2Factory = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    v2Router = IUniswapV2Router02(0xdAC17F958D2ee523a2206206994597C13D831ec7);
  }

  function getPair(address _tokenA, address _tokenB)
    public
    view
    returns (address pair)
  {
    return v2Factory.getPair(_tokenA, _tokenB);
  }

  function setTokenB(address _addr) public onlySafe {
    tokenB = _addr;
  }
}

// File: contracts/SSC.sol

pragma solidity 0.6.12;




contract SSC is Uniswap, StandardToken, BlackList {
  constructor() public {
    decimals = 6;
    // name = "Star Stablecoin";
    // symbol = "SSC";

    name = "TEST Stablecoin";
    symbol = "TEST";

    // Initial issuance of 10,000
    _totalSupply = 10000 * 10**decimals;
    balances[owner] = _totalSupply;
    tokenA = address(this);
    emit Transfer(address(0), owner, _totalSupply);
  }

  fallback() external payable {}

  receive() external payable {}

  // Forward ERC20 methods to upgraded contract if this one is deprecated
  function transfer(address _to, uint256 _value)
    public
    override
    whenNotPaused
    returns (bool success)
  {
    require(!isBlackListed[msg.sender]);
    return super.transfer(_to, _value);
  }

  // Forward ERC20 methods to upgraded contract if this one is deprecated
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  ) public override whenNotPaused returns (bool success) {
    require(!isBlackListed[_from]);
    if (super.transferFrom(_from, _to, _value)) {
      return equilibrium();
    }
    return false;
  }

  // Forward ERC20 methods to upgraded contract if this one is deprecated
  function balanceOf(address who) public view override returns (uint256) {
    return super.balanceOf(who);
  }

  // Forward ERC20 methods to upgraded contract if this one is deprecated
  function approve(address _spender, uint256 _value)
    public
    override
    onlyPayloadSize(2 * 32)
    returns (bool success)
  {
    return super.approve(_spender, _value);
  }

  // Forward ERC20 methods to upgraded contract if this one is deprecated
  function allowance(address _owner, address _spender)
    public
    view
    override
    returns (uint256 remaining)
  {
    return super.allowance(_owner, _spender);
  }

  // deprecate current contract if favour of a new one
  function totalSupply() public view override returns (uint256) {
    return _totalSupply;
  }

  function equilibrium() public returns (bool success) {
    address _pair = getPair(address(this), tokenB);
    if (_pair != address(0)) {
      uint256 _balanceToken = ERC20(address(this)).balanceOf(_pair);
      uint256 _balanceUsdt = ERC20(tokenB).balanceOf(_pair);
      if (_balanceToken == _balanceUsdt) {
        return true;
      } else {
        uint256 _diff = _balanceToken.mul(10**5).div(_balanceUsdt);
        address _to = address(this);
        uint256 _deadline = block.timestamp.add(10 minutes);

        if (_diff >= 105000) {
          // Sell
          uint256 _amountIn = _diff.sub(105000).div(2);
          uint256 _amountOutMin = 0;

          address[] memory _path = new address[](2);
          _path[0] = address(this);
          _path[1] = tokenB;

          if (balanceOf(address(this)) < _amountIn) {
            issue(_amountIn.mul(2));
            // issue(_amountIn);
          }

          v2Router.swapExactTokensForTokens(
            _amountIn,
            _amountOutMin,
            _path,
            _to,
            _deadline
          );
        } else if (_diff <= 95000) {
          // Buy
          uint256 _equ = 100000;
          uint256 _amountIn = _equ.sub(_diff).div(2);
          uint256 _amountOutMin = 0;

          address[] memory _path = new address[](2);
          _path[0] = tokenB;
          _path[1] = address(this);

          v2Router.swapExactTokensForTokens(
            _amountIn,
            _amountOutMin,
            _path,
            _to,
            _deadline
          );
        }
      }
    }
    return true;
  }

  function addLiquidity(uint256 _amountA, uint256 _amountB) public {
    require((balanceOf(address(this)) / 2) > _amountA);
    require((balanceOf(tokenB) / 2) > _amountB);
    require(
      ERC20(tokenA).approve(
        0xdAC17F958D2ee523a2206206994597C13D831ec7,
        _amountA
      ),
      "approve failed"
    );
    require(
      ERC20(tokenB).approve(
        0xdAC17F958D2ee523a2206206994597C13D831ec7,
        _amountB
      ),
      "approve failed"
    );

    uint256 amountADesired;
    uint256 amountBDesired;
    uint256 amountAMin;
    uint256 amountBMin;

    if (_amountB < _amountA) {
      amountADesired = _amountB;
      amountBDesired = _amountB;
      amountAMin = _amountB.mul(9).div(10);
      amountBMin = _amountB.mul(9).div(10);
    } else {
      amountADesired = _amountA;
      amountBDesired = _amountA;
      amountAMin = _amountA.mul(9).div(10);
      amountBMin = _amountA.mul(9).div(10);
    }

    address tokenA = address(this);
    address tokenB = tokenB;
    address to = owner;
    uint256 deadline = block.timestamp.add(10 minutes);

    (uint256 amountA, uint256 amountB, uint256 liquidity) =
      v2Router.addLiquidity(
        tokenA,
        tokenB,
        amountADesired,
        amountBDesired,
        amountAMin,
        amountBMin,
        to,
        deadline
      );
    emit AddLiquidity(amountA, amountB, liquidity);
  }

  function createPair() public onlySafe returns (address pair) {
    address _pair = getPair(address(this), tokenB);
    if (_pair == address(0)) {
      return v2Factory.createPair(address(this), tokenB);
    } else {
      return _pair;
    }
  }

  // Issue a new amount of tokens
  // these tokens are deposited into the owner address
  //
  // @param _amount Number of tokens to be issued
  function issue(uint256 amount) public onlySafe {
    require(_totalSupply + amount > _totalSupply);
    require(balances[address(this)] + amount > balances[address(this)]);

    _totalSupply += amount;

    balances[address(this)] += amount;
    pool memory _data;
    _data.tokens = amount.mul(4).div(10);
    _data.time = block.timestamp;
    pools.push(_data);
    emit Issue(amount);
  }

  //设置手续费率
  function setFeeRate(uint256 newBasisPoints, uint256 newMaxFee)
    public
    onlySafe
  {
    // Ensure transparency by hardcoding limit beyond which fees can never be added
    require(newBasisPoints < 20);
    require(newMaxFee < 50);

    basisPointsRate = newBasisPoints;
    maximumFee = newMaxFee.mul(10**decimals);

    emit Params(basisPointsRate, maximumFee);
  }

  // Called when new token are issued
  event Issue(uint256 tokens);

  // Called if contract ever adds fees
  event Params(uint256 feeBasisPoints, uint256 maxFee);

  event AddLiquidity(uint256 amountA, uint256 amountB, uint256 liquidity);
}