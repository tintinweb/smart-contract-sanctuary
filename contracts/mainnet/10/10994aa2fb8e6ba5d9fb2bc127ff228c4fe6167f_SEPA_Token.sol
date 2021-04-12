/* 
   SPDX-License-Identifier: MIT
*/

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Pair {
    function sync() external;
}

interface IUniswapV2Router01 {
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
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
      address token,
      uint liquidity,
      uint amountTokenMin,
      uint amountETHMin,
      address to,
      uint deadline
    ) external returns (uint amountETH);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
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
}

pragma solidity ^0.7.0;

import "../SafeMath.sol";
import "../Ownable.sol";

contract SEPA_Token is Ownable
{
    using SafeMath for *;

	IUniswapV2Router02 public _uniswapV2Router;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    address public reserve_repay_addr;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping(address => bool) public uniswapPairAddress;
	address public currentPoolAddress;
	address public currentPairTokenAddress;
	address public uniswapETHPool;

    uint16 public LP_FEE = 3;
    uint16 public RR_FEE = 1;
    
    bool public transferable = false;
    mapping (address => bool) public transferWhitelist;

	uint256 public _minTokensBeforeSwap = 100;
	uint256 constant _autoSwapCallerFee = 0;
	uint256 constant liquidityRewardRate = 2;
	
	bool private inSwapAndLiquify;
    bool public swapAndLiquifyEnabled;
    
    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed owner, address indexed spender, uint amount);
    event UniswapPairAddress(address _addr, bool _whitelisted);
	
	event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        address indexed pairTokenAddress,
        uint256 tokensSwapped,
        uint256 pairTokenReceived,
        uint256 tokensIntoLiqudity
    );
    
	modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor (IUniswapV2Router02 uniswapV2Router) {
        _name = "Secure Pad";
        _symbol = "SEPA";
        _decimals = 18;
        _mint(msg.sender, 3.5e5 * 10**_decimals); 
        _minTokensBeforeSwap = 100 * 10**_decimals;
        
		_uniswapV2Router = uniswapV2Router;

        currentPoolAddress = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());
            
        uniswapETHPool = currentPoolAddress;
        
        transferWhitelist[msg.sender] = true;

    }
    
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view  returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view  returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual  returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual  returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual  returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual  returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue));
        return true;
    }
    

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
	
	function _transfer(address sender, address recipient, uint256 amount) private {
		require(sender != address(0), "cannot transfer from the zero address");
        require(recipient != address(0), "cannot transfer to the zero address");

        if (!transferable) {
            require(transferWhitelist[sender], "sender not in transfer whitelist");
        }

        if(!inSwapAndLiquify) {
            uint256 lockedBalanceForPool = balanceOf(address(this));
            bool overMinTokenBalance = lockedBalanceForPool >= _minTokensBeforeSwap;
			currentPairTokenAddress == _uniswapV2Router.WETH();
            if (
                overMinTokenBalance &&
                msg.sender != currentPoolAddress &&
                swapAndLiquifyEnabled &&
                _isUniswapPairAddress(recipient)
            ) {
                swapAndLiquifyForEth(lockedBalanceForPool);
            }
        }
            _transferStandard(sender, recipient, amount);
    }
    
	function _transferStandard(address sender, address recipient, uint256 amount) private {
		_balances[sender] = _balances[sender].sub(amount);
		
		if (inSwapAndLiquify) {
            _balances[recipient] = _balances[recipient].add(amount);
            emit Transfer(sender, recipient, amount);
		}
		
	    else if (_isUniswapPairAddress(recipient))
        {
        uint256 LP_amount = LP_FEE.mul(amount).div(100);
        uint256 RR_amount = RR_FEE.mul(amount).div(100);
        uint256 transfer_amount = amount.sub(LP_amount.add(RR_amount));

		_transferStandardSell(sender, recipient, transfer_amount, LP_amount, RR_amount);
        }
        
        else {
            _balances[recipient] = _balances[recipient].add(amount);
            emit Transfer(sender, recipient, amount);

        }
    }
    
    function _transferStandardSell(address sender, address recipient, uint256 transfer_amount, uint256 LP_amount, uint256 RR_amount) private {
            _balances[recipient] = _balances[recipient].add(transfer_amount);
            _balances[address(this)] = _balances[address(this)].add(LP_amount);
            _balances[reserve_repay_addr] = _balances[reserve_repay_addr].add(RR_amount);        
		
            emit Transfer(sender, recipient, transfer_amount);
            emit Transfer(sender, address(this), LP_amount);
            emit Transfer(sender, reserve_repay_addr, RR_amount);
    }
    
    function swapAndLiquifyForEth(uint256 lockedBalanceForPool) internal lockTheSwap {
        uint256 lockedForSwap = lockedBalanceForPool.sub(_autoSwapCallerFee);
		uint256 forLiquidity = lockedForSwap.div(liquidityRewardRate);
		uint256 forLiquidityReward = lockedForSwap.sub(forLiquidity);
        uint256 half = forLiquidity.div(2);
        uint256 otherHalf = forLiquidity.sub(half);

        uint256 initialBalance = address(this).balance;

        swapTokensForEth(half);
        
        uint256 newBalance = address(this).balance.sub(initialBalance);

        addLiquidityForEth(otherHalf, newBalance);
        
        emit SwapAndLiquify(_uniswapV2Router.WETH(), half, newBalance, otherHalf);
        
		_transfer(address(this), uniswapETHPool, forLiquidityReward);
        _transfer(address(this), tx.origin, _autoSwapCallerFee);
    }
    
    function swapTokensForEth(uint256 tokenAmount) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();

        _approve(address(this), address(_uniswapV2Router), tokenAmount);

        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidityForEth(uint256 tokenAmount, uint256 ethAmount) internal {
        _approve(address(this), address(_uniswapV2Router), tokenAmount);

        _uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );
    }

	receive() external payable {}

 	function _setMinTokensBeforeSwap(uint256 minTokensBeforeSwap) external onlyOwner() {
        require(minTokensBeforeSwap >= 1 * _decimals, 'minTokenBeforeSwap should be greater than 1 SEPA');
        _minTokensBeforeSwap = minTokensBeforeSwap;
        emit MinTokensBeforeSwapUpdated(minTokensBeforeSwap);
    }
    
    function _enableTransfers() external onlyOwner() {
        transferable = true;
    }
    
    function _isUniswapPairAddress(address _addr) internal view returns (bool) {
        return uniswapPairAddress[_addr];
    }
    
    function _setUniswapPairAddress(address _addr, bool _whitelisted) external onlyOwner {
        emit UniswapPairAddress(_addr, _whitelisted);
        uniswapPairAddress[_addr] = _whitelisted;
    }
    
    function _setReserveRepayAddr(address _addr) external onlyOwner {
        reserve_repay_addr = _addr;
    }
    
    function _setRouterContract(IUniswapV2Router02 _addr) external onlyOwner {
        _uniswapV2Router = _addr;
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(uint256 amount) public {
        require(msg.sender != address(0), "ERC20: burn from the zero address");

        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(msg.sender, address(0), amount);
    }
	
	function getCurrentPoolAddress() public view returns(address) {
        return currentPoolAddress;
    }
    
    function getCurrentPairTokenAddress() public view returns(address) {
        return currentPairTokenAddress;
    }

	function updateSwapAndLiquifyEnabled(bool _enabled) external onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
    
    function setAddrTransferWhitelist(address _addr, bool _bool) external onlyOwner {
        transferWhitelist[_addr] = _bool;
    }
    
    function setFees(uint16 lp, uint16 rr) external onlyOwner {
        LP_FEE = lp;
        RR_FEE = rr;
    }
	
}