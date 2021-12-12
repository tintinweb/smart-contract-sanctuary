/**
 *Submitted for verification at BscScan.com on 2021-12-11
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

interface IERC20 {
	function totalSupply() external view returns (uint256);
	function balanceOf(address account) external view returns (uint256);
	function transfer(address recipient, uint256 amount) external returns (bool);
	function allowance(address owner, address spender) external view returns (uint256);
	function approve(address spender, uint256 amount) external returns (bool);
	function transferFrom( address sender, address recipient, uint256 amount) external returns (bool);
	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function decimals() external view returns (uint8);
}

abstract contract Context {
  function _msgSender() internal view virtual returns (address) { return msg.sender; }
  function _msgData() internal view virtual returns (bytes calldata) { return msg.data; }
}

contract Ownable is Context {
  address public _owner;
  address public _creator;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  constructor() {
    _transferOwnership(_msgSender());
    _creator = _msgSender();
  }

  function owner() public view virtual returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(owner() == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  function renounceOwnership() public virtual onlyOwner {
    _transferOwnership(address(0));
  }

  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    _transferOwnership(newOwner);
  }

  function _transferOwnership(address newOwner) internal virtual {
    address oldOwner = _owner;
    _owner = newOwner;
    emit OwnershipTransferred(oldOwner, newOwner);
  }
}

interface IFactory {
	event PairCreated(address indexed token0, address indexed token1, address pair, uint256);
	function feeTo() external view returns (address);
	function feeToSetter() external view returns (address);
	function getPair(address tokenA, address tokenB) external view returns (address pair);
	function allPairs(uint256) external view returns (address pair);
	function allPairsLength() external view returns (uint256);
	function createPair(address tokenA, address tokenB) external returns (address pair);
	function setFeeTo(address) external;
	function setFeeToSetter(address) external;
}

interface IRouter {
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
	) external returns (uint256 amountA, uint256 amountB, uint256 liquidity );
	function addLiquidityETH(
		address token,
		uint256 amountTokenDesired,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline
	) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
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
	function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);
	function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

abstract contract ReentrancyGuard {
	uint256 private constant _NOT_ENTERED = 1;
	uint256 private constant _ENTERED = 2;
	uint256 private _status;

	constructor() { _status = _NOT_ENTERED; }

	modifier nonReentrant() {
		require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
		_status = _ENTERED;
    _;
    _status = _NOT_ENTERED;
	}
}

contract ERC20 is 
  Context
  , Ownable
  , IERC20
  , IERC20Metadata
  , ReentrancyGuard
{
  string private _name = "Coin";
  string private _symbol = "COIN";
  uint8 private _decimals = 9;
  uint256 private _totalSupply;

  address DEAD = 0x000000000000000000000000000000000000dEaD;
  address ZERO = address(0);
  // address WRAPPER = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
  address ROUTER = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
  address FACTORY = 0xB7926C0430Afb07AA7DEfDE6DA862aE0Bde767bc;
  address public WRAPPER;
  address public _pair;
  IRouter public _router;

  uint256 _devFee = 3; // percentage
  uint256 _marketingFee = 3; // percentage
  uint256 _charityFee = 5; // percentage
  address _devAddress = 0x39239184Fbf37493ce5081F863A63EE48f34D691; // percentage
  address _marketingAddress = 0x38e820ABA2f376557060a2f62532820559c20C9C; // percentage
  address _charityAddress = 0x003aaD28cEc66469f62ccCddfea27fb0a42992d4; // percentage
  

  mapping(address => uint256) private _balances;
  mapping(address => mapping(address => uint256)) private _allowances;
  mapping(address => bool) public _excludeFee;

  constructor() {
    emit OwnershipTransferred(address(0), _msgSender());
    
    _router = IRouter(ROUTER);
    _pair = IFactory(_router.factory()).createPair(_router.WETH(), address(this));
    WRAPPER = _router.WETH();

    _allowances[address(this)][address(_router)] = ~uint256(0);

    _excludeFee[owner()] = true;
    _excludeFee[address(this)] = true;
    _excludeFee[DEAD] = true;

    _mint(_msgSender(), 1 * 10 ** uint256(_decimals));
  }

  receive() external payable {  }

  function name() public view virtual override returns (string memory) { return _name; }
  function symbol() public view virtual override returns (string memory) { return _symbol; }
  function decimals() public view virtual override returns (uint8) { return _decimals; }
  function totalSupply() public view virtual override returns (uint256) { return _totalSupply; }
  function balanceOf(address account) public view virtual override returns (uint256) { return _balances[account]; }
  function allowance(address owner, address spender) public view virtual override returns (uint256) { return _allowances[owner][spender]; }
  function currentBalance() public view returns(uint256) { return balanceOf(address(this)); }
  function totalFeePercentage() public view returns(uint256) { return _devFee + _marketingFee + _charityFee; }
  function contractBalance() public view returns(uint256) { return address(this).balance; }

  function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
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

    uint256 amountAfterFee = amount;
    if (!_excludeFee[_msgSender()]) {
      amountAfterFee = takeFee(amount);
      distributeFee();
    }

    _balances[recipient] += amountAfterFee;

    emit Transfer(sender, recipient, amount);
  }

  function takeFee (uint256 amount_) private returns(uint256){
    uint256 fee = totalFeePercentage() * amount_ / 100;
    _balances[address(this)] += fee;

    return amount_ - fee;
  }

  // function distributeFee () private nonReentrant {
  //   uint256 swapAmount = _balances[address(this)];
        
  //   address[] memory path = new address[](2);
  //   path[0] = address(this);
  //   path[1] = _router.WETH();

  //   uint256 balanceBefore = address(this).balance;

  //   try _router.swapExactTokensForETH(
  //     swapAmount,
  //     0,
  //     path,
  //     address(this),
  //     block.timestamp
  //   ) {
  //     uint256 amountBNB = address(this).balance - balanceBefore;
  //     uint256 distributeDev = amountBNB * _devFee / totalFeePercentage();
  //     uint256 distributeMarketing = amountBNB * _marketingFee / totalFeePercentage();
  //     uint256 distributeCharity = amountBNB * _charityFee / totalFeePercentage();

  //     (bool sentDev, ) = payable(_devAddress).call{value: distributeDev, gas: 30000}(""); require(sentDev, "Failed to send dev Ether.");
  //     (bool sentMarketing, ) = payable(_marketingAddress).call{value: distributeMarketing, gas: 30000}(""); require(sentMarketing, "Failed to send marketing Ether.");
  //     (bool sentCharity, ) = payable(_charityAddress).call{value: distributeCharity, gas: 30000}(""); require(sentCharity, "Failed to send charity Ether.");

  //   } catch {  }
  // }

  event DistributeFailed(string message);
  function distributeFee () private nonReentrant {
    uint256 swapAmount = _balances[address(this)];
        
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = _router.WETH();

    try _router.swapExactTokensForETH(
      swapAmount,
      0,
      path,
      address(this),
      block.timestamp
    ) {

    } catch Error(string memory e) {
      emit DistributeFailed(string(abi.encodePacked("SwapBack failed with error ", e)));
    } catch {
      emit DistributeFailed("SwapBack failed without an error message from pancakeSwap");
    }
  }

  function _mint(address account, uint256 amount) internal virtual {
    require(account != address(0), "ERC20: mint to the zero address");

    _beforeTokenTransfer(address(0), account, amount);

    _totalSupply += amount;
    _balances[account] += amount;
    emit Transfer(address(0), account, amount);
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
  ) internal virtual {

  }

}