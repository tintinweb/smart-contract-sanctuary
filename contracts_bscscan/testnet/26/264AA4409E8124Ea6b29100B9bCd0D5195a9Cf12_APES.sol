// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ____  ____  _____ ____
// /  _ \/  __\/  __// ___\
// | / \||  \/||  \  |    \
// | |-|||  __/|  /_ \___ |
// \_/ \|\_/   \____\\____/
// -===== TEAM APES =====-

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Ownable {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _setOwner(msg.sender);
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IPancakeFactory {
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
interface IPancakePair {
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

interface IPancakeRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);
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
}
interface IWETH {
    function deposit() external payable;
    function withdraw(uint wad) external;
}

contract APES is IERC20, Ownable {
  using SafeMath for uint256;

  mapping(address => uint256) private _balances;
  mapping(address => mapping(address => uint256)) private _allowances;
  uint256 private _totalSupply = 1 * 10**11 * 10**9;
  string private _name = "APES";
  string private _symbol = unicode"🦍";

  IPancakeRouter private router;
  address private constant routerAddress = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;  // --- TEST ---
  // address private constant routerAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
  address public liquidityPool;
  address public crowdfundingWallet;

  uint256 public taxFee = 2;
  uint256 public liquidityFee = 4;
  uint256 public burnFee = 2;
  uint256 public crowdfundingFee = 2;

  uint256 public toLiquidity;
  address private apesAddress;
  bool public swapAndLiquifyEnabled;
  uint256 public airdropCount;
  address[] public airdropUsers;
  uint256 public soldTokens;
  bool private teamAllocated;

  mapping (address => bool) private isExcludedFromFee;
  mapping(address => uint256) public airdropBalances;

  event SwapAndLiquify(uint256 tokensSwapped, uint256 wethReceived, uint256 tokensIntoLiqudity);
  event BuyTokens(address buyer, uint256 amountOfETH, uint256 amountOfTokens);

  constructor() {
      apesAddress = address(this);
      router = IPancakeRouter(routerAddress);
      liquidityPool = IPancakeFactory(router.factory()).createPair(apesAddress, router.WETH());

      swapAndLiquifyEnabled = false;
      teamAllocated = false;
      soldTokens = 0;
      airdropCount = 0;
      toLiquidity = 0;

      isExcludedFromFee[address(this)] = true;
      isExcludedFromFee[owner()] = true;
      isExcludedFromFee[routerAddress] = true;
      isExcludedFromFee[liquidityPool] = true;
      isExcludedFromFee[crowdfundingWallet] = true;

      _balances[address(this)] += _totalSupply;
      emit Transfer(address(0), address(this), _totalSupply);
  }

  function name() public view returns (string memory) {
      return _name;
  }

  function symbol() public view returns (string memory) {
      return _symbol;
  }

  function decimals() public pure returns (uint8) {
      return 9;
  }

  function totalSupply() public view virtual override returns (uint256) {
      return _totalSupply;
  }

  function balanceOf(address account) public view virtual override returns (uint256) {
      return _balances[account];
  }

  function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
      _transfer(msg.sender, recipient, amount);
      return true;
  }

  function allowance(address owner, address spender) public view virtual override returns (uint256) {
      return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount) public virtual override returns (bool) {
      _approve(msg.sender, spender, amount);
      return true;
  }

  function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
      _transfer(sender, recipient, amount);
      uint256 currentAllowance = _allowances[sender][msg.sender];
      require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
      unchecked {
          _approve(sender, msg.sender, currentAllowance - amount);
      }
      return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
      _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
      return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
      uint256 currentAllowance = _allowances[msg.sender][spender];
      require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
      unchecked {
          _approve(msg.sender, spender, currentAllowance - subtractedValue);
      }
      return true;
  }

  function _transfer(address sender, address recipient, uint256 amount ) internal virtual {

      require(sender != address(0), "ERC20: transfer from the zero address");
      require(recipient != address(0), "ERC20: transfer to the zero address");

      uint256 senderBalance = _balances[sender];
      require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");

      if ( amount < 1 * 10**9 || isExcludedFromFee[sender] ) {
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
      }
      else {
        uint256 tFee = (amount / 100) * taxFee;
        uint256 lFee = (amount / 100) * liquidityFee;
        uint256 bFee = (amount / 100) * burnFee;
        uint256 cFee = (amount / 100) * crowdfundingFee;

        uint256 totalTransfer = amount - tFee - lFee - bFee - cFee;
        _balances[sender] -= amount;
        _balances[owner()] += tFee; // tax
        _balances[apesAddress] += lFee; // liquidity
        _totalSupply -= bFee; // burn
        _balances[crowdfundingWallet] += lFee; // crowdfunding

        toLiquidity += lFee;

        _balances[recipient] += totalTransfer;

        emit Transfer(sender, owner(), tFee);
        emit Transfer(sender, apesAddress, lFee);
        emit Transfer(sender, address(0), bFee);
        emit Transfer(sender, crowdfundingWallet, cFee);
        emit Transfer(sender, recipient, totalTransfer);
      }

      if (sender != liquidityPool && toLiquidity > 1000 * 10**9 && swapAndLiquifyEnabled) {
          swapAndLiquify(toLiquidity);
      }

  }

  function _approve(address owner, address spender, uint256 amount) internal virtual {
      require(owner != address(0), "ERC20: approve from the zero address");
      require(spender != address(0), "ERC20: approve to the zero address");
      _allowances[owner][spender] = amount;
      emit Approval(owner, spender, amount);
  }

  function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
      swapAndLiquifyEnabled = _enabled;
  }

  function swapAndLiquify(uint256 _toLiquidity) private {
      uint256 half = _toLiquidity.div(2);
      uint256 otherHalf = _toLiquidity.sub(half);

      _approve(address(this), routerAddress, half);
      address[] memory path;
      path[0] = address(this);
      path[1] = router.WETH();
      router.swapExactTokensForTokens(half, 0, path, address(this), block.timestamp.add(300));

      uint256 wethBalance = IERC20(router.WETH()).balanceOf(address(this));

      _approve(address(this), routerAddress, otherHalf);
      IERC20(router.WETH()).approve(routerAddress, wethBalance);

      router.addLiquidity(apesAddress, router.WETH(), otherHalf, wethBalance, 0, 0, owner(), block.timestamp.add(300));
      emit SwapAndLiquify(half, wethBalance, otherHalf);
  }

  function excludeFromFee(address account) public onlyOwner {
    isExcludedFromFee[account] = true;
  }

  function includeInFee(address account) public onlyOwner {
    isExcludedFromFee[account] = false;
  }

  function getPrice() public view returns(uint) {
    address[] memory path;
    path[0] = router.WETH();
    path[1] = address(this);
    uint256[] memory amount = router.getAmountsIn(1 * 10**9, path);
    return amount[0];
  }

  function allocateTokens() public onlyOwner {
    require(teamAllocated == false, "Already allocated.");
    uint256 tAmount = ( _totalSupply / 100 ) * 5;
    (bool sent) = IERC20(address(this)).transfer(payable(owner()), tAmount);
    teamAllocated = sent;
  }

  function airdrop(address[] memory recipients) external onlyOwner returns (bool) {
    require(airdropCount < 1001, "Exceeds limit.");
    for (uint256 i = 0; i < recipients.length; i++) {
      address user = recipients[i];
      bool existing = airdropBalances[user] > 0;
      require(existing == false, "User already participated the airdrop.");
      airdropBalances[user] = 1000 * 10**9;
      airdropUsers.push(user);
      airdropCount++;
      IERC20(apesAddress).transfer(recipients[i], 1000 * 10**9);
    }
    return true;
  }

  function buy(uint256 numTokens) public payable {
    uint price = getPrice();
    require(msg.value >= price * numTokens, "The sent amount is less than value of the tokens");
    require(IERC20(apesAddress).balanceOf(address(this)) >= numTokens, "No more token to fulfill this request.");
    (bool sent) = IERC20(apesAddress).transfer(msg.sender, numTokens);
    require(sent, "Failed to transfer token to user");
    emit BuyTokens(msg.sender, msg.value, numTokens);
    soldTokens += numTokens;
  }

  function addLiquidity(uint256 tokenAmount, uint256 ethAmount) external onlyOwner returns (uint amountToken, uint amountETH, uint liquidity) {
      IERC20(apesAddress).approve(routerAddress, tokenAmount);
      (amountToken, amountETH, liquidity) = router.addLiquidityETH{value: ethAmount}(apesAddress, tokenAmount, 0, 0, address(this), block.timestamp.add(300));
  }

  function wrapETH(uint _amount) external onlyOwner {
    IWETH(payable(router.WETH())).deposit{value: _amount}();
  }

  function unwrapETH(uint _amount) external onlyOwner {
    IWETH(payable(router.WETH())).withdraw(_amount);
  }

  function changeCrowdfundingWallet(address _wallet) external onlyOwner {
    crowdfundingWallet = _wallet;
  }

  function getBalance() public view returns(uint) {
    return address(this).balance;
  }

  function getTokens(address _token) public view returns (uint) {
    return IERC20(_token).balanceOf(address(this));
  }

  receive() external payable virtual {
    uint256 modulo = msg.value % getPrice();
    uint256 numTokens = (msg.value - modulo) / getPrice();
    buy(numTokens);
    payable(msg.sender).transfer(modulo);
  }

}