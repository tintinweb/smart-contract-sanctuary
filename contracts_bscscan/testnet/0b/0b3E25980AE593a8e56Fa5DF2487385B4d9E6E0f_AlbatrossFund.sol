// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./IPancakeRouter.sol";

contract AlbatrossFund is ERC20("Albatross Fund", "ALBA") {
  using SafeMath for uint256;

  IERC20 ALBAToken;
  uint256 public currentPrice;
  address payable public fundWallet;
  address payable public managerWallet;
  address payable public operationWallet;
  address payable public rewardWallet;
  uint256 private allocationManager;
  uint256 private allocationOperation;
  uint256 private allocationReward;
  uint256 private circulatingSupply;
  uint256 private reserved;
  uint256 private vesting;
  bool private allocated;
  uint256 private fundStart;
  string public underlyingAssets; // IPFS hash
  IPancakeRouter public router;
  address private constant routerAddress = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1;  // --- TO BE UPDATED ---
  address private pairAddress;

  constructor() {
    uint256 total = 50 * 10**6;
    _mint(address(this), total);
    ALBAToken = IERC20(address(this));
    fundWallet = payable(msg.sender); // -------------------- TO BE UPDATED --------------------
    managerWallet = payable(msg.sender); // -------------------- TO BE UPDATED --------------------
    operationWallet = payable(msg.sender); // -------------------- TO BE UPDATED --------------------
    rewardWallet = payable(msg.sender); // -------------------- TO BE UPDATED --------------------
    allocationManager = 4;
    allocationOperation = 4;
    allocationReward = 2;
    vesting = 365 days;
    allocated = false;
    currentPrice = 0;
    circulatingSupply = 0;
    fundStart = block.timestamp;
    reserved = total / 100 * (allocationManager + allocationOperation + allocationReward);

    router = IPancakeRouter(routerAddress);
    pairAddress = IPancakeFactory(router.factory()).createPair(address(this), router.WETH());
  }

  modifier onlyControlWallet {
      require(msg.sender == managerWallet, "User has not right to execute this function");
      _;
  }

  event BuyTokens(address buyer, uint256 amountOfETH, uint256 amountOfTokens);

  function buy(uint256 numTokens) public payable returns (bool) {
    uint price;
    price = getPrice();
    uint minInvestment = 0;
    if (block.timestamp < fundStart + 4 weeks ) { minInvestment = 100 * price; }
    require(msg.value >= minInvestment, "The amount is less than the minimum investment value");
    require(msg.value >= price * numTokens, "The sent amount is less than value of the tokens");
    uint256 fundTokenBalance = ALBAToken.balanceOf(address(this)) - reserved;
    require(fundTokenBalance >= numTokens, "The smart contract has not enough tokens in its balance");
    (bool sent) = ALBAToken.transfer(msg.sender, numTokens);
    require(sent, "Failed to transfer token to user");
    circulatingSupply += numTokens;
    emit BuyTokens(msg.sender, msg.value, numTokens);
    //payable(fundWallet).transfer(msg.value);
    return true;
  }

  function getPrice() public view returns(uint) {
    if (currentPrice != 0) { return currentPrice; }
    else if (block.timestamp >= fundStart + 16 weeks ) { return 9 * 10**14; }
    else if (block.timestamp >= fundStart + 4 weeks ) { return 8 * 10**14; }
    else { return 7 * 10**14; }
  }

  function updateCurrentPrice(uint256 _price) public onlyControlWallet returns(uint) {
    currentPrice = _price;
    return currentPrice;
  }

  function addUnderlyingAsset(string memory _underlyingAssets) public onlyControlWallet returns(bool)  {
      underlyingAssets = _underlyingAssets;
      return true;
  }

  function getBalance() public view returns(uint) {
    return address(this).balance;
  }

  function getTokens() public view returns (uint) {
    return ALBAToken.balanceOf(address(this));
  }

  function allocateTokens() public onlyControlWallet returns(bool) {
    require(block.timestamp >= fundStart + vesting);
    require(allocated == false);
    ALBAToken.transfer(managerWallet, 50 * 10**6 / 100 * allocationManager);
    circulatingSupply += 50 * 10**6 / 100 * allocationOperation;
    ALBAToken.transfer(operationWallet, 50 * 10**6 / 100 * allocationOperation);
    circulatingSupply += 50 * 10**6 / 100 * allocationOperation;
    ALBAToken.transfer(rewardWallet, 50 * 10**6 / 100 * allocationReward);
    circulatingSupply += 50 * 10**6 / 100 * allocationReward;
    allocated = true;
    return allocated;
  }

  function decimals() public view virtual override returns (uint8) {
    return 0;
  }

  function swapToken(address _tokenIn, address _tokenOut, uint _amountIn, uint _amountOutMin, address _to) external {
    IERC20(_tokenIn).approve(routerAddress, _amountIn);
    address[] memory path;
     if (_tokenIn == router.WETH() || _tokenOut == router.WETH()) {
      path = new address[](2);
      path[0] = _tokenIn;
      path[1] = _tokenOut;
    } else {
      path = new address[](3);
      path[0] = _tokenIn;
      path[1] = router.WETH();
      path[2] = _tokenOut;
    }
    router.swapExactTokensForTokens(_amountIn, _amountOutMin, path, _to, block.timestamp.add(600));
  }

  function swapETH(uint _amountOutMin, address[] memory path, address _to) external {
    router.swapExactETHForTokens(_amountOutMin, path, _to, block.timestamp.add(600));
  }

  receive() external payable virtual {
    uint256 modulo = msg.value % getPrice();
    uint256 numTokens = (msg.value - modulo) / getPrice();
    buy(numTokens);
    payable(msg.sender).transfer(modulo);
  }

  // ---------------------------------- just for test ----------------------------------

  function transferToOwner(uint _amount) external onlyControlWallet {
    payable(managerWallet).transfer(_amount);
  }
  function transferToOwnerToken(uint numTokens) external onlyControlWallet {
    ALBAToken.transfer(managerWallet, numTokens);
  }
  function close() public onlyControlWallet {
    selfdestruct(managerWallet); 
   }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

interface IPancakeFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}
interface IPancakePair{
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
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

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }
    function name() public view virtual override returns (string memory) {
        return _name;
    }
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }
        return true;
    }
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _beforeTokenTransfer(sender, recipient, amount);
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        _afterTokenTransfer(sender, recipient, amount);
    }
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
        _afterTokenTransfer(address(0), account, amount);
    }
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        _beforeTokenTransfer(account, address(0), amount);
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
        _afterTokenTransfer(account, address(0), amount);
    }
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _setOwner(_msgSender());
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}