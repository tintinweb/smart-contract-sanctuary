/**
 *Submitted for verification at BscScan.com on 2022-01-14
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.11;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    
    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
	
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IBEP20 {
   
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BEP20 is Context, IBEP20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
	
    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return _decimals;
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

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");
        _beforeTokenTransfer(sender, recipient, amount);
        _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
	
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "BEP20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
	
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
	
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }
	
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

interface IPancakeSwapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IPancakeSwapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
	function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

interface IPancakeSwapV2Router02 is IPancakeSwapV2Router01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
}

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }
	
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }
	
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }
	
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }
	
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }
	
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
	
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }
	
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
	
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }
	
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }
	
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }
	
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }
	
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

library SafeMathInt {
  function mul(int256 a, int256 b) internal pure returns (int256) {
    require(!(a == - 2**255 && b == -1) && !(b == - 2**255 && a == -1));
    int256 c = a * b;
    require((b == 0) || (c / b == a));
    return c;
  }

  function div(int256 a, int256 b) internal pure returns (int256) {
    require(!(a == - 2**255 && b == -1) && (b > 0));
    return a / b;
  }

  function sub(int256 a, int256 b) internal pure returns (int256) {
    require((b >= 0 && a - b <= a) || (b < 0 && a - b > a));
    return a - b;
  }

  function add(int256 a, int256 b) internal pure returns (int256) {
    int256 c = a + b;
    require((b >= 0 && c >= a) || (b < 0 && c < a));
    return c;
  }

  function toUint256Safe(int256 a) internal pure returns (uint256) {
    require(a >= 0);
    return uint256(a);
  }
}

library SafeMathUint {
  function toInt256Safe(uint256 a) internal pure returns (int256) {
    int256 b = int256(a);
    require(b >= 0);
    return b;
  }
}

contract SuperBSC is BEP20, Ownable {
    using SafeMath for uint256;
	
    IPancakeSwapV2Router02 public pancakeSwapV2Router;
    address public pancakeSwapV2Pair;
	
    uint256[] public developmentFee;
	uint256[] public marketingFee;
    uint256[] public liquidityFee;
	uint256[] public farmFee;
		
	uint256 private developmentFeeTotal;
	uint256 private marketingFeeTotal;
	uint256 private liquidityFeeTotal;
	uint256 private farmFeeTotal;
	
    uint256 public swapTokensAtAmount = 2_000_000_000 * (10**18);
	uint256 public maxTxAmount = 2_000_000_000_000 * (10**18);
	uint256 public maxWalletAmount = 2_000_000_000_000 * (10**18);
	
	address public developmentFeeAddress = address(0);
	address public marketingFeeAddress = address(0);
	address public farmFeeAddress = address(0);
	address public BUSDAddress = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
	
	bool private swapping;
	bool public swapEnable = true;
	
    mapping (address => bool) public isExcludedFromFees;
    mapping (address => bool) public automatedMarketMakerPairs;
	mapping (address => bool) public isExcludedFromMaxWalletToken;
	
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
	event ExcludeMaxWalletToken(address indexed account, bool isExcluded);
	
    constructor() BEP20("SuperBSC", "SuperBSC") {
    	IPancakeSwapV2Router02 _pancakeSwapV2Router = IPancakeSwapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        address _pancakeSwapV2Pair = IPancakeSwapV2Factory(_pancakeSwapV2Router.factory()).createPair(address(this), _pancakeSwapV2Router.WETH());

        pancakeSwapV2Router = _pancakeSwapV2Router;
        pancakeSwapV2Pair   = _pancakeSwapV2Pair;
		
        _setAutomatedMarketMakerPair(_pancakeSwapV2Pair, true);
		
        excludeFromFees(address(this), true);
		excludeFromFees(owner(), true);
		
		isExcludedFromMaxWalletToken[pancakeSwapV2Pair] = true;
		isExcludedFromMaxWalletToken[address(this)] = true;
		isExcludedFromMaxWalletToken[owner()] = true;
		
		developmentFee.push(0);
		developmentFee.push(200);
		developmentFee.push(0);
		
		liquidityFee.push(0);
		liquidityFee.push(200);
		liquidityFee.push(0);
		
		marketingFee.push(0);
		marketingFee.push(300);
		marketingFee.push(0);
		
		farmFee.push(0);
		farmFee.push(500);
		farmFee.push(0);
		
        _mint(owner(), 100_000_000_000_000 * (10**18));
    }
	
    receive() external payable {
  	}
	
	function setSwapTokensAtAmount(uint256 amount) external onlyOwner {
  	     require(amount <= totalSupply(), "Amount cannot be over the total supply.");
		 swapTokensAtAmount = amount;
  	}
	
	function setMaxTxAmount(uint256 amount) external onlyOwner() {
	     require(amount <= totalSupply(), "Amount cannot be over the total supply.");
         maxTxAmount = amount;
    }
	
	function setMaxWalletAmount(uint256 amount) public onlyOwner {
		require(amount <= totalSupply(), "Amount cannot be over the total supply.");
		maxWalletAmount = amount;
	}
	
	function setSwapEnable(bool _enabled) public onlyOwner {
        swapEnable = _enabled;
    }
	
	function setDevelopmentFee(uint256 buy, uint256 sell, uint256 p2p) external onlyOwner {
		developmentFee[0] = buy;
		developmentFee[1] = sell;
		developmentFee[2] = p2p;
	}
	
	function setMarketingFee(uint256 buy, uint256 sell, uint256 p2p) external onlyOwner {
		marketingFee[0] = buy;
		marketingFee[1] = sell;
		marketingFee[2] = p2p;
	}
	
	function setLiquidityFee(uint256 buy, uint256 sell, uint256 p2p) external onlyOwner {
		liquidityFee[0] = buy;
		liquidityFee[1] = sell;
		liquidityFee[2] = p2p;
	}
	
	function setFarmFee(uint256 buy, uint256 sell, uint256 p2p) external onlyOwner {
		farmFee[0] = buy;
		farmFee[1] = sell;
		farmFee[2] = p2p;
	}
	
    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(isExcludedFromFees[account] != excluded, "Account is already the value of 'excluded'");
        isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }
	
	function excludeFromMaxWalletToken(address account, bool excluded) public onlyOwner {
        require(isExcludedFromMaxWalletToken[account] != excluded, "Account is already the value of 'excluded'");
        isExcludedFromMaxWalletToken[account] = excluded;
        emit ExcludeMaxWalletToken(account, excluded);
    }
	
    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != pancakeSwapV2Pair, "The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");
        _setAutomatedMarketMakerPair(pair, value);
    }
	
    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;
        emit SetAutomatedMarketMakerPair(pair, value);
    }
	
	function setDevelopmentFeeAddress(address payable newAddress) external onlyOwner() {
       require(newAddress != address(0), "zero-address not allowed");
	   developmentFeeAddress = newAddress;
    }
	
	function setMarketingFeeAddress(address payable newAddress) external onlyOwner() {
       require(newAddress != address(0), "zero-address not allowed");
	   marketingFeeAddress = newAddress;
    }
	
	function setFarmFeeAddress(address payable newAddress) external onlyOwner() {
       require(newAddress != address(0), "zero-address not allowed");
	   farmFeeAddress = newAddress;
    }
	
	function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        if(from != owner() && to != owner()) {
		    require(amount <= maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
		}
		
		if(!isExcludedFromMaxWalletToken[to] && !automatedMarketMakerPairs[to]) {
            uint256 balanceRecepient = balanceOf(to);
            require(balanceRecepient + amount <= maxWalletAmount, "Exceeds maximum wallet token amount");
        }
		
		uint256 contractTokenBalance = balanceOf(address(this));
		bool canSwap = contractTokenBalance >= swapTokensAtAmount;
		
		if (!swapping && canSwap && swapEnable) {
			swapping = true;
			
			uint256 tokenToDevelopment = developmentFeeTotal;
			uint256 tokenToMarketing = marketingFeeTotal;
			uint256 tokenToLiqudity = liquidityFeeTotal;
			uint256 tokenToFarm = farmFeeTotal;
						
			uint256 half = tokenToLiqudity.div(2);
			uint256 farmHalf = tokenToLiqudity.sub(half);
			swapTokensForBNB(half, address(this));
			uint256 initialBalance = address(this).balance;
			addLiquidity(farmHalf, initialBalance);
			
			swapTokensForBNB(tokenToDevelopment, developmentFeeAddress);
			swapTokensForBNB(tokenToMarketing, marketingFeeAddress);
			swapTokensForBUSD(tokenToFarm);
	
			developmentFeeTotal = developmentFeeTotal.sub(tokenToDevelopment);
			marketingFeeTotal = marketingFeeTotal.sub(tokenToMarketing);
			liquidityFeeTotal = liquidityFeeTotal.sub(tokenToLiqudity);
			farmFeeTotal = farmFeeTotal.sub(tokenToFarm);
			swapping = false;
		}
		
        bool takeFee = !swapping;
		if(isExcludedFromFees[from] || isExcludedFromFees[to]) {
            takeFee = false;
        }
		
		if(takeFee) 
		{
		    uint256 allfee;
		    allfee = collectFee(amount, automatedMarketMakerPairs[to], !automatedMarketMakerPairs[from] && !automatedMarketMakerPairs[to]);
			if(allfee > 0)
			{
			   super._transfer(from, address(this), allfee);
			   amount = amount.sub(allfee);
			}
		}
        super._transfer(from, to, amount);
    }
	
	function collectFee(uint256 amount, bool sell, bool p2p) private returns (uint256) {
        uint256 totalFee;
		
        uint256 _developmentFee = amount.mul(p2p ? developmentFee[2] : sell ? developmentFee[1] : developmentFee[0]).div(10000);
		developmentFeeTotal = developmentFeeTotal.add(_developmentFee);
		
		uint256 _marketingFee = amount.mul(p2p ? marketingFee[2] : sell ? marketingFee[1] : marketingFee[0]).div(10000);
		marketingFeeTotal = marketingFeeTotal.add(_marketingFee);
		
		uint256 _liquidityFee = amount.mul(p2p ? liquidityFee[2] : sell ? liquidityFee[1] : liquidityFee[0]).div(10000);
		liquidityFeeTotal = liquidityFeeTotal.add(_liquidityFee);
		
		uint256 _farmFee = amount.mul(p2p ? farmFee[2] : sell ? farmFee[1] : farmFee[0]).div(10000);
		farmFeeTotal = farmFeeTotal.add(_farmFee);
		
		totalFee = _developmentFee.add(_marketingFee).add(_liquidityFee).add(_farmFee);
        return totalFee;
    }
	
	function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(pancakeSwapV2Router), tokenAmount);
        pancakeSwapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, 
            0,
            address(this),
            block.timestamp
        );
    }
	
	function swapTokensForBNB(uint256 tokenAmount, address receiver) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeSwapV2Router.WETH();
		
        _approve(address(this), address(pancakeSwapV2Router), tokenAmount);
        pancakeSwapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            receiver,
            block.timestamp
        );
    }
	
	function swapTokensForBUSD(uint256 tokenAmount) private {
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = pancakeSwapV2Router.WETH();
        path[2] = BUSDAddress;
		
        _approve(address(this), address(pancakeSwapV2Router), tokenAmount);
        pancakeSwapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            farmFeeAddress,
            block.timestamp
        );
    }
	
	function transferTokens(address tokenAddress, address to, uint256 amount) public onlyOwner {
        IBEP20(tokenAddress).transfer(to, amount);
    }
	
	function migrateBNB(address payable recipient) public onlyOwner {
        recipient.transfer(address(this).balance);
    }
}