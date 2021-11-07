/**
 *Submitted for verification at BscScan.com on 2021-11-06
*/

/**
 * This is a RFI token deployed automatically by Hibiki's automated token creator.
 * Known usually as a Safemoon clone, it's the bread and butter of BSC.
 * This version has tax limits.
 *
 * https://hibiki.finance/
 */

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

interface IRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
	function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
	function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

interface IDexFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract HibikiRFI {

	address public immutable dead = 0x000000000000000000000000000000000000dEaD;
	address public owner;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    address[] private _excluded;
    mapping (address => uint8) private _swaps;

    string private _name;
    string private _symbol;
    uint8 private _decimals = 9;

    uint256 private _tTotal;
    uint256 private _rTotal;
    uint256 private _tFeeTotal;
    uint256 public _taxFee = 1;
    uint256 private _previousTaxFee = _taxFee;
    uint256 public _liquidityFee = 1;
    uint256 private _previousLiquidityFee = _liquidityFee;

    IRouter public immutable router;
    address public immutable pair;
    address private liquidityHolds;
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;

    uint256 public _maxTxAmount = 200000 * 10**5 * 10**9;
    uint256 private numTokensSellToAddToLiquidity = 1000 * 10**6 * 10**9;

    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

	modifier onlyOwner {
		require(msg.sender == owner, "Only the owner can do this.");
		_;
	}

    constructor() {
		owner = msg.sender;
        IRouter _router = IRouter(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        pair = IDexFactory(_router.factory()).createPair(address(this), _router.WETH());
        router = _router;
    }

	function prepare(address creator, string memory n, string memory s, uint8 d, uint256 tokenSupply, uint256 liqTax, uint256 refTax) external onlyOwner {
		owner = creator;
		_name = n;
		_symbol = s;
		_decimals = d;
		_tTotal = tokenSupply * 10 ** d;
    	_rTotal = type(uint256).max - (type(uint256).max % _tTotal);
		_rOwned[creator] = _rTotal;
		_taxFee = refTax;
		_liquidityFee = liqTax;
		liquidityHolds = creator;
        _isExcludedFromFee[creator] = true;
        _isExcludedFromFee[address(this)] = true;

        emit Transfer(address(0), creator, _tTotal);
	}

    function name() public view returns (string memory) {return _name;}
    function getOwner() external view returns (address) {return owner;}
    function symbol() public view returns (string memory) {return _symbol;}
    function decimals() public view returns (uint8) {return _decimals;}
    function totalSupply() public view returns (uint256) {return _tTotal;}

    function balanceOf(address account) public view returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address _owner, address spender) public view returns (uint256) {
        return _allowances[_owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
		require(_allowances[sender][msg.sender] >= amount, "BEP20: transfer amount exceeds allowance");
		_approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
		require(_allowances[msg.sender][spender] >= subtractedValue, "BEP20: decreased allowance below zero");
        _approve(msg.sender, spender, _allowances[msg.sender][spender] - subtractedValue);
        return true;
    }

	function transferOwnership(address newOwner) external onlyOwner {
		owner = newOwner;
	}

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount / currentRate;
    }

    function excludeFromReward(address account) public onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] -= tAmount;
        _rOwned[sender] -= rAmount;
        _tOwned[recipient] += tTransferAmount;
        _rOwned[recipient] += rTransferAmount;
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    receive() external payable {}

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal -= rFee;
        _tFeeTotal += tFee;
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tTransferAmount = tAmount - tFee - tLiquidity;
        return (tTransferAmount, tFee, tLiquidity);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount * currentRate;
        uint256 rFee = tFee * currentRate;
        uint256 rLiquidity = tLiquidity * currentRate;
        uint256 rTransferAmount = rAmount - rFee - rLiquidity;
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / tSupply;
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) {
				return (_rTotal, _tTotal);
			}
            rSupply -= _rOwned[_excluded[i]];
            tSupply -= _tOwned[_excluded[i]];
        }
        if (rSupply < _rTotal / _tTotal) {
			return (_rTotal, _tTotal);
		}
        return (rSupply, tSupply);
    }
    
    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = tLiquidity * currentRate;
        _rOwned[address(this)] += rLiquidity;
        if (_isExcluded[address(this)]) {
            _tOwned[address(this)] += tLiquidity;
		}
    }

	function setFees(uint256 reflect, uint256 liquidity) external onlyOwner {
		require(reflect + liquidity < 34, "Max tax possible is 34%.");
		_taxFee = reflect;
		_liquidityFee = liquidity;
	}

    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount * _taxFee / 100;
    }

    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount * _liquidityFee / 100;
    }

    function removeAllFee() private {
        if(_taxFee == 0 && _liquidityFee == 0) return;

        _previousTaxFee = _taxFee;
        _previousLiquidityFee = _liquidityFee;
        
        _taxFee = 0;
        _liquidityFee = 0;
    }

    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
    }
    
    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(address _owner, address spender, uint256 amount) private {
        require(_owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

	function setMaxTxAmount(uint256 amount) external onlyOwner {
		_maxTxAmount = amount;
	}

	function setTokensSellForLiq(uint256 amount) external onlyOwner {
		numTokensSellToAddToLiquidity = amount;
	}

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "BEP20: Transfer amount must be greater than zero");

        // Limit the amount of tokens that can be transfered at once.
        // Does not apply to burning coins, managing liquidity.
        if (from != owner
            && to != owner
            && to != dead
            && from != liquidityHolds
            && to != liquidityHolds
        ) {
            require(amount <= _maxTxAmount, "Transfer amount exceeds your current maximum transfer amount.");
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        if (contractTokenBalance >= _maxTxAmount) {
            contractTokenBalance = _maxTxAmount;
        }
        
        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            from != pair &&
            swapAndLiquifyEnabled
        ) {
            contractTokenBalance = numTokensSellToAddToLiquidity;
            swapAndLiquify(contractTokenBalance);
        }

        // Indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }

        // transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from, to, amount, takeFee);
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        uint256 half = contractTokenBalance / 2;
        uint256 otherHalf = contractTokenBalance - half;
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(half);
        uint256 currentBalance = address(this).balance;
        uint256 newBalance = currentBalance - initialBalance;
        addLiquidity(otherHalf, newBalance);
        
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokenAmount);

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(router), tokenAmount);

        router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            owner,
            block.timestamp
        );
    }

    function _tokenTransfer(address from, address to, uint256 amount, bool takeFee) private {
        if (!takeFee) {
            removeAllFee();
        }

        // Pick the proper transfer method.
        if (_isExcluded[from] && !_isExcluded[to]) {
            _transferFromExcluded(from, to, amount);
        } else if (!_isExcluded[from] && _isExcluded[to]) {
            _transferToExcluded(from, to, amount);
        } else if (_isExcluded[from] && _isExcluded[to]) {
            _transferBothExcluded(from, to, amount);
        } else {
            _transferStandard(from, to, amount);
        }

        if (!takeFee) {
            restoreAllFee();
        }
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] -= rAmount;
        _rOwned[recipient] += rTransferAmount;
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] -= rAmount;
        _tOwned[recipient] += tTransferAmount;
        _rOwned[recipient] += rTransferAmount;           
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] -= tAmount;
        _rOwned[sender] -= rAmount;
        _rOwned[recipient] += rTransferAmount;
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
}