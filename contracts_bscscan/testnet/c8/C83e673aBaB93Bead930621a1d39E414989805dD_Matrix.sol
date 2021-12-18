// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;


import "IPancake.sol";
import "IBEP20.sol";
import "SafeMath.sol";
import "Context.sol";
import "Ownable.sol";


contract Matrix is Context, IBEP20, Ownable {
    // Libs
    using SafeMath for uint256;

    // Mappings
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    mapping (address => uint256) private _tOwned;
    mapping (address => uint256) private _rOwned;
    
    // Events
    event UpdateFees(uint256 _liquidityFee, uint256 _fundingFee, uint256 _keanuFee, uint256 _retribFee, uint256 _burnFee);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);
    event SetWallets(address fundingAddr, address keanuAddr);
    event SetNumTokensSellToAddToLiquidity(uint256 tAmount);
    event ExcludeFromFee(address addr, bool state);
    event SetSwapAndLiquifyEnabled(bool enabled);
    event Burn(address addr, uint256 tAmount);
    event SetMaxTxAmount(uint256 tAmount);
    event SetPancakeRouter(address addr);
    event SetPancakePair(address addr);
    event ActivateContract();
    
    // Enums
    enum ExcludedFromFee {SENDER_EXCLUDED, RECEIVER_EXCLUDED, BOTH_EXCLUDED, STANDARD}

    // Ban Hammer
    address[] private _excluded;

    // Stats
    uint256 private _tLiquidityTotal;
    uint256 private _tFundingTotal;
    uint256 private _tKeanuTotal;
    uint256 private _tRetribTotal;
    uint256 private _tBurnTotal;
    
    // BEP20
    string private _NAME = "Matrix Evolution";
    string private _SYMBOL = "MATRIX";
    uint8 private _DECIMALS = 8;
    
    // Constants
    uint256 private constant MAX = ~uint256(0);
    
    // Reflection
    uint256 public _maxTxAmount = 500 * 10**6 * 10**_DECIMALS;
    uint256 private _tTotal = 100000 * 10**6 * 10**_DECIMALS;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));

    // Swap & Liquify
    uint256 private numTokensSellToAddToLiquidity = 50 * 10**6 * 10**_DECIMALS;
    bool public swapAndLiquifyEnabled = false;
    bool private inSwapAndLiquify;

    // Fee
    struct Fee { uint256 liquidity; uint256 funding; uint256 keanu; uint256 retrib; uint256 burn; }
    Fee public _fee = Fee(0, 0, 0, 0, 0);
    Fee private origFee;
    
    // Addresses
    address public liquidityWallet = address(this);
    address public fundingWallet;
    address public keanuWallet;

    // Pancakeswap Router
    IPancakeRouter02 public pancakeV2Router;
    address public pancakeV2Pair;

    // Modifier
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }


    constructor (address tokenOwner, address fundingAddress, address keanuAddress, address routerAddress) payable {
        fundingWallet = fundingAddress;
        keanuWallet = keanuAddress;

        IPancakeRouter02 _pancakeV2Router = IPancakeRouter02(routerAddress);
        pancakeV2Pair = IPancakeFactory(_pancakeV2Router.factory()).createPair(address(this), _pancakeV2Router.WETH());
        pancakeV2Router = _pancakeV2Router;

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[fundingWallet] = true;
        _isExcludedFromFee[keanuWallet] = true;

        _rOwned[tokenOwner] = _rTotal;
        origFee = _fee;

        emit Transfer(address(0), tokenOwner, _tTotal);
    }


    function _getCurrentSupply () private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;

        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) {
                return (_rTotal, _tTotal);
            }

            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }

        if (rSupply < _rTotal.div(_tTotal)) {
            return (_rTotal, _tTotal);
        }

        return (rSupply, tSupply);
    }


    function _getRate () private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        
        return rSupply.div(tSupply);
    }


    function _getTValues (uint256 tAmount, Fee memory fee) private pure returns (Fee memory, uint256) {
        Fee memory tFee;

        tFee.liquidity = (tAmount.mul(fee.liquidity)).div(100);
        tFee.funding = (tAmount.mul(fee.funding)).div(100);
        tFee.keanu = (tAmount.mul(fee.keanu)).div(100);
        tFee.retrib = (tAmount.mul(fee.retrib)).div(100);
        tFee.burn = (tAmount.mul(fee.burn)).div(100);
        
        uint256 tTransferAmount =  tAmount.sub(tFee.liquidity).sub(tFee.funding).sub(tFee.keanu).sub(tFee.retrib).sub(tFee.burn);
        
        return (tFee, tTransferAmount); 
    }


    function _getRValues (uint256 tAmount, Fee memory tFee, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);

        uint256 rRetrib = tFee.retrib.mul(currentRate);
        uint256 rLiquidity = tFee.liquidity.mul(currentRate);
        uint256 rFunding = tFee.funding.mul(currentRate);
        uint256 rKeanu = tFee.keanu.mul(currentRate);
        uint256 rBurn = tFee.burn.mul(currentRate);

        uint256 rTransferAmount = rAmount.sub(rLiquidity + rFunding + rKeanu + rRetrib + rBurn);

        return (rAmount, rRetrib, rTransferAmount);
    }


    function _getValues (uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, Fee memory) {
        (Fee memory tFee, uint256 tTransferAmount) = _getTValues(tAmount, _fee);
        (uint256 rAmount, uint256 rRetrib, uint256 rTransferAmount) = _getRValues(tAmount, tFee, _getRate());

        return (rAmount, rTransferAmount, rRetrib, tTransferAmount, tFee);
    }


    function _burn (uint256 tAmount) private {
        uint256 rAmount = tAmount.mul(_getRate());
        _rOwned[address(this)] = _rOwned[address(this)].sub(rAmount, "Can't burn below zero");

        if (_isExcluded[address(this)]) {
            _tOwned[address(this)] = _tOwned[address(this)].sub(tAmount, "Can't burn below zero");
        }

        _tTotal = _tTotal.sub(tAmount, "Can't substract from tTotal");
        _rTotal = _rTotal.sub(rAmount, "Can't substract from rTotal");
        _tBurnTotal = _tBurnTotal.add(tAmount);

        emit Burn(address(this), tAmount);
    }


    function _approve (address owner, address spender, uint256 tAmount) private {
        require(owner != address(0), "Can't approve from address(0)");
        require(spender != address(0), "Can't approve to address(0)");

        _allowances[owner][spender] = tAmount;

        emit Approval(owner, spender, tAmount);
    }


    function _removeFee () private {
        if (_fee.liquidity == 0 && _fee.funding == 0 && _fee.keanu == 0 && _fee.retrib == 0 && _fee.burn == 0) {
            return;
        }

        origFee = _fee;
        _fee.liquidity = 0;
        _fee.funding = 0;
        _fee.keanu = 0;
        _fee.retrib = 0;
        _fee.burn = 0;
    }


    function _restoreFee () private {
        _fee = origFee;
    }


    function _sendLiquidity (address receiver, uint256 currentRate, uint256 amount) private {
        uint256 rAmount = amount.mul(currentRate);
        _rOwned[receiver] = _rOwned[receiver].add(rAmount);

        if (_isExcluded[receiver]) {
            _tOwned[receiver] = _tOwned[receiver].add(amount);
        }
    }


    function _reflectFee (uint256 rRetrib, Fee memory tFee) private {
        _rTotal = _rTotal.sub(rRetrib);
        _tTotal = _tTotal.sub(tFee.burn);

        // Stats
        _tLiquidityTotal = _tLiquidityTotal.add(tFee.liquidity);
        _tFundingTotal = _tFundingTotal.add(tFee.funding);
        _tKeanuTotal = _tKeanuTotal.add(tFee.keanu);
        _tRetribTotal = _tRetribTotal.add(tFee.retrib);
        _tBurnTotal = _tBurnTotal.add(tFee.burn);
    }


    function _transferAction (address sender, address recipient, uint256 tAmount, ExcludedFromFee excludedFromFee) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rRetrib, uint256 tTransferAmount, Fee memory tFee) = _getValues(tAmount);
        
        if (excludedFromFee == ExcludedFromFee.STANDARD) {
            // DEFAULT STANDARD
            _rOwned[sender] = _rOwned[sender].sub(rAmount);
            _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        } else if (excludedFromFee == ExcludedFromFee.SENDER_EXCLUDED) {
            // SENDER EXCLUDED
            _tOwned[sender] = _tOwned[sender].sub(tAmount);
            _rOwned[sender] = _rOwned[sender].sub(rAmount);
            _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        } else if (excludedFromFee == ExcludedFromFee.RECEIVER_EXCLUDED) {
            // RECEIVER EXCLUDED
            _rOwned[sender] = _rOwned[sender].sub(rAmount);
            _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
            _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        } else if (excludedFromFee == ExcludedFromFee.BOTH_EXCLUDED) {
            // BOTH EXCLUDED
            _tOwned[sender] = _tOwned[sender].sub(tAmount);
            _rOwned[sender] = _rOwned[sender].sub(rAmount);
            _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
            _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        }

        // Liquidity / Funding / KeanuWallet
        uint256 currentRate = _getRate();
        _sendLiquidity(address(this), currentRate, tFee.liquidity);
        _sendLiquidity(fundingWallet, currentRate, tFee.funding);
        _sendLiquidity(keanuWallet, currentRate, tFee.keanu);

        _reflectFee(rRetrib, tFee);

        emit Transfer(sender, recipient, tTransferAmount);
    }


    function _tokenTransfer (address sender, address recipient, uint256 tAmount, bool takeFee) private {
        if (!takeFee) {
            _removeFee();
        }

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            // SENDER EXCLUDED
            _transferAction(sender, recipient, tAmount, ExcludedFromFee.SENDER_EXCLUDED);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            // RECEIVER EXCLUDED
            _transferAction(sender, recipient, tAmount, ExcludedFromFee.RECEIVER_EXCLUDED);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            // BOTH EXCLUDED
             _transferAction(sender, recipient, tAmount, ExcludedFromFee.BOTH_EXCLUDED);
        } else {
            // DEFAULT STANDARD
            _transferAction(sender, recipient, tAmount, ExcludedFromFee.STANDARD);
        }
        
        if (!takeFee) {
            _restoreFee();
        }
    }


    function _transfer (address sender, address recipient, uint256 tAmount) private {
        require(sender != address(0), "Can't transfer from address(0)");
        require(recipient != address(0), "Can't transfer to address(0)");

        if (sender != owner() && recipient != owner()) {
            require(tAmount <= _maxTxAmount, "Amount exceeds maxTxAmount");
        }

        bool overMinTokenBalance = balanceOf(address(this)) >= numTokensSellToAddToLiquidity;
        if (overMinTokenBalance && !inSwapAndLiquify && sender != pancakeV2Pair && swapAndLiquifyEnabled) {
            swapAndLiquify(numTokensSellToAddToLiquidity);
        }

        bool takeFee = true;
        if (_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]) {
            takeFee = false;
        }

        _tokenTransfer(sender, recipient, tAmount, takeFee);
    }


    function reflectionFromToken (uint256 tAmount, bool deductTransferFee) public view returns (uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");

        if (!deductTransferFee) {
            (uint256 rAmount, , , , ) = _getValues(tAmount);
            return rAmount;
        } else {
            ( , uint256 rTransferAmount, , , ) = _getValues(tAmount);
            return rTransferAmount;
        }
    }


    function tokenFromReflection (uint256 rAmount) public view returns (uint256) {
        require(rAmount <= _rTotal, "Amount must be less than reflections");

        return rAmount.div(_getRate());
    }


    function name () external view override returns (string memory) {
        return _NAME;
    }


    function symbol () external view override returns (string memory) {
        return _SYMBOL;
    }


    function decimals () external view override returns (uint8) {
        return uint8(_DECIMALS);
    }


    function totalSupply () external view override returns (uint256) {
        return _tTotal;
    }


    function totalLiquidity () external view returns (uint256) {
        return _tLiquidityTotal;
    }


    function totalFunding () external view returns (uint256) {
        return _tFundingTotal;
    }


    function totalKeanu () external view returns (uint256) {
        return _tKeanuTotal;
    }


    function totalRetribution () external view returns (uint256) {
        return _tRetribTotal;
    }


    function totalBurn () external view returns (uint256) {
        return _tBurnTotal;
    }


    function balanceOf (address sender) public view override returns (uint256) {
        if (_isExcluded[sender]) {
            return _tOwned[sender];
        }

        return tokenFromReflection(_rOwned[sender]);
    }


    function allowance (address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }


    function isExcluded (address sender) external view returns (bool) {
        return _isExcluded[sender];
    }


    function isExcludedFromFee (address sender) external view returns (bool) {
        return _isExcludedFromFee[sender];
    }


    function excludeFromFee (address sender, bool state) external onlyOwner {
        _isExcludedFromFee[sender] = state;

        emit ExcludeFromFee(sender, state);
    }


    function includeAccount (address sender) external onlyOwner {
        require(_isExcluded[sender], "Sender is already included");

        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == sender) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _rOwned[sender] = _tOwned[sender].mul(_getRate());
                _tOwned[sender] = 0;

                _isExcluded[sender] = false;
                _excluded.pop();
                break;
            }
        }
    }


    function excludeAccount (address sender) external onlyOwner {
        require(!_isExcluded[sender], "Sender is already excluded");
        require(_excluded.length <= 16384, "Limited to 16384 accounts");

        if (_rOwned[sender] > 0) {
            _tOwned[sender] = tokenFromReflection(_rOwned[sender]);
        }

        _isExcluded[sender] = true;
        _excluded.push(sender);
    }


    function setPancakeRouter (address _addr) external onlyOwner {
        require(_addr != owner(), "Can't be the owner address");
        require(_addr != address(0), "Can't be address(0)");

        pancakeV2Router = IPancakeRouter02(_addr);

        emit SetPancakeRouter(_addr);
    }
    

    function setPancakePair (address _addr) external onlyOwner {
        require(_addr != owner(), "Can't be the owner address");
        require(_addr != address(0), "Can't be address(0)");

        pancakeV2Pair = _addr;

        emit SetPancakePair(_addr);
    }


    function setWallets (address _fundingAddress, address _keanuAddress) external onlyOwner {
        require(_fundingAddress != owner() && _keanuAddress != owner(), "Can't be the owner address");
        require(_fundingAddress != address(0) && _keanuAddress != address(0), "Can't be address(0)");

        fundingWallet = _fundingAddress;
        keanuWallet = _keanuAddress;

        emit SetWallets(_fundingAddress, _keanuAddress);
    }


    function updateFees (uint256 _liquidityFee, uint256 _fundingFee, uint256 _keanuFee, uint256 _retribFee, uint256 _burnFee) external onlyOwner {
		require((_liquidityFee + _fundingFee + _keanuFee + _retribFee + _burnFee) <= 10, "Total fees <= 10");

        _fee.liquidity = _liquidityFee;
        _fee.funding = _fundingFee;
        _fee.keanu = _keanuFee;
        _fee.retrib = _retribFee;
        _fee.burn = _burnFee;

        origFee = _fee;

        emit UpdateFees(_liquidityFee, _fundingFee, _keanuFee, _retribFee, _burnFee);
	}


    function setNumTokensSellToAddToLiquidity (uint256 tAmount) external onlyOwner {
        require(tAmount <= 100, "Amount <= 100");

        numTokensSellToAddToLiquidity = tAmount * 10**6 * 10**_DECIMALS;

        emit SetNumTokensSellToAddToLiquidity(tAmount);
    }


    function setMaxTxAmount (uint256 tAmount) external onlyOwner {
        require(tAmount <= 500, "Amount <= 500");

        _maxTxAmount = tAmount * 10**6 * 10**_DECIMALS;

        emit SetMaxTxAmount(tAmount);
    }


    function setSwapAndLiquifyEnabled (bool _enabled) external onlyOwner {
        swapAndLiquifyEnabled = _enabled;

        emit SetSwapAndLiquifyEnabled(_enabled);
    }


    function activateContract () external onlyOwner {
        swapAndLiquifyEnabled = true;

        address sender = _msgSender();
        uint256 initFunds = 1 * 10**_DECIMALS;
        _transfer(sender, fundingWallet, initFunds);
        _transfer(sender, keanuWallet, initFunds);

        _fee = Fee(3, 1, 1, 2, 2);

        emit ActivateContract();
    }


    function deliver (uint256 tAmount) external onlyOwner {
        address sender = _msgSender();
        (uint256 rAmount, , , , ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tRetribTotal = _tRetribTotal.add(tAmount);
    }


    function burn (uint256 tAmount) external returns (bool) {
        require(balanceOf(msg.sender) >= tAmount, "Amount exceeds sender's balance");

        _transfer(_msgSender(), address(this), tAmount);
        _burn(tAmount);

        return true;
    }


    function transfer (address recipient, uint256 tAmount) external override returns (bool) {
        require(balanceOf(msg.sender) >= tAmount, "Amount exceeds sender's balance");

        _transfer(_msgSender(), recipient, tAmount);

        return true;
    }


    function approve (address spender, uint256 tAmount) external override returns (bool) {
        _approve(_msgSender(), spender, tAmount);

        return true;
    }


    function transferFrom (address sender, address recipient, uint256 tAmount) external override returns (bool) {
        require(balanceOf(msg.sender) >= tAmount, "Amount exceeds sender's balance");

        _transfer(sender, recipient, tAmount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(tAmount, "Amount exceeds allowance"));

        return true;
    }


    function increaseAllowance (address spender, uint256 addedValue) external virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));

        return true;
    }


    function decreaseAllowance (address spender, uint256 subtractedValue) external virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "Amount is below zero"));

        return true;
    }


    function addLiquidity (uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(pancakeV2Router), tokenAmount);

        pancakeV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            address(this),
            block.timestamp
        );
    }


    function swapTokensForEth (uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeV2Router.WETH();

        _approve(address(this), address(pancakeV2Router), tokenAmount);

        pancakeV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }


    function swapAndLiquify (uint256 contractTokenBalance) private lockTheSwap {
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);
        uint256 initialBalance = address(this).balance;

        swapTokensForEth(half);
        uint256 newBalance = address(this).balance.sub(initialBalance);
        addLiquidity(otherHalf, newBalance);
        
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
// PancakeSwap V2 Contracts (python-scrap)

pragma solidity ^0.8.10;


interface IPancakeFactory {
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


interface IPancakeRouter01 {
    function factory() external pure returns (address);

    // solhint-disable-next-line func-name-mixedcase
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

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}


interface IPancakeRouter02 is IPancakeRouter01 {
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

// SPDX-License-Identifier: Apache-2.0
// OpenZeppelin Contracts v4.4.0 (contracts/token/ERC20/IERC20.sol)
// MODIFIED VERSION (ERC20 -> BEP20)

pragma solidity ^0.8.10;


/**
 * @dev Interface of the BEP20 standard.
 */
interface IBEP20 {

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender) external view returns (uint256);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (contracts/utils/math/SafeMath.sol)

pragma solidity ^0.8.10;


// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
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

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
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

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (contracts/utils/Context.sol)
// MODIFIED VERSION

pragma solidity ^0.8.10;


/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */

// Modifications:
// 'address'            -> 'address payable'
// 'msg.sender'         -> 'payable(msg.sender)'
// 'bytes calldata'     -> 'bytes memory'
// 'this;'              -> Silence state mutability warning without generating bytecode (https://github.com/ethereum/solidity/issues/2691)

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (contracts/access/Ownable.sol)

pragma solidity ^0.8.10;


import "Context.sol";


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
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}