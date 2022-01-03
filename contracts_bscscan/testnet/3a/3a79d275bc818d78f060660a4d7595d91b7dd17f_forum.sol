/**
 *Submitted for verification at BscScan.com on 2022-01-02
*/

/**
 *Submitted for verification at BscScan.com on 2021-11-12
*/

/**
 *Submitted for verification at BscScan.com on 2021-11-10
*/

/*
1% RFI
1.5% Auto LP
2% Marketing
2.2% tech team
0.3% dev

tax 
7% buys
14% sells
21% sells over 0.5% supply
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

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

interface IUniswapV2Pair {
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

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

abstract contract IERC20Extented is IERC20 {
    function decimals() external view virtual returns (uint8);
    function name() external view virtual returns (string memory);
    function symbol() external view virtual returns (string memory);
}

contract forum is Context, IERC20, IERC20Extented, Ownable {
    using SafeMath for uint256;
    
    string private constant _name = "forum";
    string private constant _symbol = "forum";
    uint8 private constant _decimals = 18;
    
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;

    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    
    mapping (address => bool) private _isExcluded;
    address[] private _excluded;
    mapping (address => bool) private _isBlackListedBot;
    // address[] private _blackListedBots;
    
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 77777777777 * 10**18;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
        

    uint256 private _botBlocks;
    uint256 private _firstBlock;

    // fees wrt to tax percentage
    uint256 public _rfiFee = 10; // divided by 1000
    uint256 private _previousRfiFee = _rfiFee;
    uint256 public _liquidityFee = 15; // divided by 1000
    uint256 private _previousLiquidityFee = _liquidityFee;
    uint256 public _marketingFee = 20; // divided by 1000
    uint256 private _previousMarketingFee = _marketingFee;
    uint256 public _teamFee = 22; // divided by 1000
    uint256 private _previousTeamFee = _teamFee;
    uint256 public _devFee = 3; // divided by 1000s
    uint256 private _previousDevFee = _devFee;

    
    uint256 private _marketingPercent = 44;
    uint256 private _teamPercent = 49;
    uint256 private _devPercent = 7;

    struct FeeBreakdown {
        uint256 tRfi;
        uint256 tLiquidity;
        uint256 tMarketing;
        uint256 tTeam;
        uint256 tDev;
        uint256 tAmount;
    }

    mapping(address => bool) private bots;
    address payable private _marketingAddress = payable(0x5c57CE95F023bcF5B92d713Ae13E94e27948C2F9);
    address payable private _teamAddress = payable(0x647CB2d7C340Bab050c89BF3F9c12F9a53428a50);
    address payable private _devAddress = payable(0x2B16bCE6628BdaA81f09D9F9946eF64fDC5182d1);
    address private presaleRouter;
    address private presaleAddress;
    IUniswapV2Router02 private uniswapV2Router;
    address public uniswapV2Pair;
    uint256 private _maxTxAmount;

    bool private tradingOpen = false;
    bool private inSwap = false;
    bool private presale = true;

    address public bridge;

    event EndedPresale(bool presale);
    event PercentsUpdated(uint256 _marketingPercent, uint256 _teamPercent, uint256 _devPercent);
    event FeesUpdated(uint256 _rfiFee, uint256 _marketingFee, uint256 _liquidityFee, uint256 _teamFee, uint256 _devFee);

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
    constructor() {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);//ropstenn 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); //bsc test 0xD99D1c33F9fC3444f8101754aBC46c52416550D1);//bsc main net 0x10ED43C718714eb63d5aA57B78B54704E256024E);
        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router),type(uint256).max);

        _rOwned[_msgSender()] = _rTotal;
        
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() override external pure returns (string memory) {
        return _name;
    }

    function symbol() override external pure returns (string memory) {
        return _symbol;
    }

    function decimals() override external pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() external pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
            return tokenFromReflection(_rOwned[account]);
    }

    function isBot(address account) public view returns (bool) {
        return bots[account];
    }
    
    function setBridge(address _bridge) external onlyOwner {
        bridge = _bridge;
    }
    
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender,_msgSender(),_allowances[sender][_msgSender()].sub(amount,"ERC20: transfer amount exceeds allowance"));
        return true;
    }
    
    function isExcluded(address account) public view returns (bool) {
            return _isExcluded[account];
        }

    function setExcludeFromFee(address account, bool excluded) external onlyOwner() {
        _isExcludedFromFee[account] = excluded;
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
        return rAmount.div(currentRate);
    }
    
    function excludeAccount(address account) external onlyOwner() {
            require(!_isExcluded[account], "Account is already excluded");
            if(_rOwned[account] > 0) {
                _tOwned[account] = tokenFromReflection(_rOwned[account]);
            }
            _isExcluded[account] = true;
            _excluded.push(account);
        }

        function includeAccount(address account) external onlyOwner() {
            require(_isExcluded[account], "Account is not excluded");
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

    function removeAllFee() private {
        if (_marketingFee == 0 && _liquidityFee == 0 && _teamFee == 0 && _devFee == 0 && _rfiFee == 0) return;
        _previousMarketingFee = _marketingFee;
        _previousLiquidityFee = _liquidityFee;
        _previousTeamFee = _teamFee;
        _previousDevFee = _devFee;
        _previousRfiFee = _rfiFee;
        
        _marketingFee = 0;
        _liquidityFee = 0;
        _teamFee = 0;
        _devFee = 0;
        _rfiFee = 0;
    }

    function setBotFee() private {
        _previousMarketingFee = _marketingFee;
        _previousLiquidityFee = _liquidityFee;
        _previousTeamFee = _teamFee;
        _previousDevFee = _devFee;
        _previousRfiFee = _rfiFee;
        
        _marketingFee = 180;
        _liquidityFee = 180;
        _teamFee = 18;
        _devFee = 18;
        _rfiFee = 180;
    }
    
    function setBuyFees() private {
        _previousMarketingFee = _marketingFee;
        _previousLiquidityFee = _liquidityFee;
        _previousTeamFee = _teamFee;
        _previousDevFee = _devFee;
        _previousRfiFee = _rfiFee;
        
        _marketingFee = 20;
        _liquidityFee = 15;
        _teamFee = 22;
        _devFee = 3;
        _rfiFee = 10;
    }
    
    function setSellFees() private {
        _previousMarketingFee = _marketingFee;
        _previousLiquidityFee = _liquidityFee;
        _previousTeamFee = _teamFee;
        _previousDevFee = _devFee;
        _previousRfiFee = _rfiFee;
        
        _marketingFee = 40;
        _liquidityFee = 30;
        _teamFee = 44;
        _devFee = 6;
        _rfiFee = 20;
    }
    
    function setOverSellFees() private {
        _previousMarketingFee = _marketingFee;
        _previousLiquidityFee = _liquidityFee;
        _previousTeamFee = _teamFee;
        _previousDevFee = _devFee;
        _previousRfiFee = _rfiFee;
        
        _marketingFee = 60;
        _liquidityFee = 45;
        _teamFee = 66;
        _devFee = 9;
        _rfiFee = 30;
    }

    function restoreAllFee() private {
        _marketingFee = _previousMarketingFee;
        _liquidityFee = _previousLiquidityFee;
        _teamFee = _previousTeamFee;
        _devFee = _previousDevFee;
        _rfiFee = _previousRfiFee;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

   
    
    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        bool takeFee = true;

        if (from != owner() && to != owner() && !presale && from != address(this) && to != address(this) && from != bridge && to != bridge) {
            require(tradingOpen);
            if (from == uniswapV2Pair && to != address(uniswapV2Router)) {//buys

                if (block.timestamp <= _firstBlock.add(_botBlocks) && from != presaleRouter && from != presaleAddress) {
                    bots[to] = true;
                }
                
                setBuyFees();
            }
            
            if (!inSwap && from != uniswapV2Pair) { //sells, transfers
                require(!bots[from] && !bots[to]);

                if (amount >= _tTotal.div(200)) {
                    setOverSellFees();
                }else {
                    setSellFees();
                }

                uint256 contractTokenBalance = balanceOf(address(this));

                if (contractTokenBalance > 0) {

                    swapAndLiquify(contractTokenBalance);
                
                }
                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
                    
            }
        }

        if (_isExcludedFromFee[from] || _isExcludedFromFee[to] || presale || from == bridge || to == bridge) {
            takeFee = false;
        }

        else if (bots[from] || bots[to]) {
            setBotFee();
            takeFee = true;
        }

        if (presale) {
            require(from == owner() || from == presaleRouter || from == presaleAddress);
        }
        
        _tokenTransfer(from, to, amount, takeFee);
        restoreAllFee();
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }
    
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
              address(this),
              tokenAmount,
              0, // slippage is unavoidable
              0, // slippage is unavoidable
              address(this),
              block.timestamp
          );
    }
  
    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        uint256 autoLPamount = _liquidityFee.mul(contractTokenBalance).div(_marketingFee.add(_teamFee).add(_devFee).add(_liquidityFee));

        // split the contract balance into halves
        uint256 half =  autoLPamount.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        // capture the contract's current BNB balance.
        // this is so that we can capture exactly the amount of BNB that the
        // swap creates, and not make the liquidity event include any BNB that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for BNB
        swapTokensForEth(otherHalf); // <- this breaks the BNB -> HATE swap when swap+liquify is triggered

        // how much BNB did we just swap into?
        uint256 newBalance = ((address(this).balance.sub(initialBalance)).mul(half)).div(otherHalf);

        // add liquidity to pancakeswap
        addLiquidity(half, newBalance);
    }

    function sendETHToFee(uint256 amount) private {
        _marketingAddress.transfer(amount.mul(_marketingPercent).div(100));
        _teamAddress.transfer(amount.mul(_teamPercent).div(100));
        _devAddress.transfer(amount.mul(_devPercent).div(100));
    }

    function openTrading(uint256 botBlocks) private {
        _firstBlock = block.timestamp;
        _botBlocks = botBlocks;
        tradingOpen = true;
    }

    function manualswap() external {
        require(_msgSender() == _marketingAddress);
        uint256 contractBalance = balanceOf(address(this));
        if (contractBalance > 0) {
            swapTokensForEth(contractBalance);
        }
    }

    function manualsend() external {
        require(_msgSender() == _marketingAddress);
        uint256 contractETHBalance = address(this).balance;
        if (contractETHBalance > 0) {
            sendETHToFee(contractETHBalance);
        }
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if (!takeFee) { 
                removeAllFee();
        }
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
        // _transferStandard(sender, recipient, amount);
        restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
            (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tTax) = _getValues(tAmount);
            _rOwned[sender] = _rOwned[sender].sub(rAmount);
            _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
            _takeTeam(tTax);
            _reflectFee(rFee, tFee);
            emit Transfer(sender, recipient, tTransferAmount);
            emit Transfer(sender,address(this),tTax);
        }

        function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
            (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tTax) = _getValues(tAmount);
            _rOwned[sender] = _rOwned[sender].sub(rAmount);
            _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
            _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
            _takeTeam(tTax);
            _reflectFee(rFee, tFee);
            emit Transfer(sender, recipient, tTransferAmount);
            emit Transfer(sender,address(this),tTax);
        }

        function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
            (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tTax) = _getValues(tAmount);
            _tOwned[sender] = _tOwned[sender].sub(tAmount);
            _rOwned[sender] = _rOwned[sender].sub(rAmount);
            _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
            _takeTeam(tTax);
            _reflectFee(rFee, tFee);
            emit Transfer(sender, recipient, tTransferAmount);
            emit Transfer(sender,address(this),tTax);
        }

        function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
            (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tTax) = _getValues(tAmount);
            _tOwned[sender] = _tOwned[sender].sub(tAmount);
            _rOwned[sender] = _rOwned[sender].sub(rAmount);
            _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
            _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
            _takeTeam(tTax);
            _reflectFee(rFee, tFee);
            emit Transfer(sender, recipient, tTransferAmount);
            emit Transfer(sender,address(this),tTax);
        }
        
        function _takeTeam(uint256 tTax) private {
            uint256 currentRate =  _getRate();
            uint256 rTax = tTax.mul(currentRate);
            _rOwned[address(this)] = _rOwned[address(this)].add(rTax);
            if(_isExcluded[address(this)])
                _tOwned[address(this)] = _tOwned[address(this)].add(tTax);
        }
        
        function _reflectFee(uint256 rFee, uint256 tFee) private {
            _rTotal = _rTotal.sub(rFee);
            _tFeeTotal = _tFeeTotal.add(tFee);
        }
        
  
    
    receive() external payable {}
    
    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        uint256 taxFee = _marketingFee.add(_liquidityFee).add(_teamFee).add(_devFee);
        (uint256 tTransferAmount, uint256 tRfi, uint256 tTax) = _getTValues(tAmount, _rfiFee, taxFee);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rRfi) = _getRValues(tAmount, tRfi, tTax, currentRate);
        return (rAmount, rTransferAmount, rRfi, tTransferAmount, tRfi, tTax);
    }

        function _getTValues(uint256 tAmount, uint256 rfiFee, uint256 taxFee) private pure returns (uint256, uint256, uint256) {
            uint256 tRfi = tAmount.mul(rfiFee).div(1000);
            uint256 tTax = tAmount.mul(taxFee).div(1000);
            uint256 tTransferAmount = tAmount.sub(tRfi).sub(tTax);
            return (tTransferAmount, tRfi, tTax);
        }


        function _getRValues(uint256 tAmount, uint256 tRfi, uint256 tTax, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
            uint256 rAmount = tAmount.mul(currentRate);
            uint256 rRfi = tRfi.mul(currentRate);
            uint256 rTax = tTax.mul(currentRate);
            uint256 rTransferAmount = rAmount.sub(rRfi).sub(rTax);
            return (rAmount, rTransferAmount, rRfi);
        }

        function _getRate() private view returns(uint256) {
            (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
            return rSupply.div(tSupply);
        }

        function _getCurrentSupply() private view returns(uint256, uint256) {
            uint256 rSupply = _rTotal;
            uint256 tSupply = _tTotal;
            for (uint256 i = 0; i < _excluded.length; i++) {
                if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
                rSupply = rSupply.sub(_rOwned[_excluded[i]]);
                tSupply = tSupply.sub(_tOwned[_excluded[i]]);
            }
            if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
            return (rSupply, tSupply);
        }

    function excludeFromFee(address account) public onlyOwner() {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) external onlyOwner() {
        _isExcludedFromFee[account] = false;
    }
    
    function removeBot(address account) external onlyOwner() {
        bots[account] = false;
    }

    function addBot(address account) external onlyOwner() {
        bots[account] = true;
    }
    

    function setTaxes(uint256 marketingFee, uint256 liquidityFee, uint256 teamFee, uint256 devFee, uint256 rfiFee) external onlyOwner() {
        uint256 totalFee = marketingFee.add(liquidityFee).add(teamFee).add(devFee).add(rfiFee);
        require(totalFee.div(10) < 30, "Sum of fees must be less than 30");

        _marketingFee = marketingFee;
        _liquidityFee = liquidityFee;
        _teamFee = teamFee;
        _devFee = devFee;
        _rfiFee = rfiFee;
        
        _previousMarketingFee = _marketingFee;
        _previousLiquidityFee = _liquidityFee;
        _previousTeamFee = _teamFee;
        _previousDevFee = _devFee;
        _previousRfiFee = _rfiFee;
        
        uint256 totalBNBfees = _marketingFee.add(_teamFee).add(_devFee);
        
        _marketingPercent = (_marketingFee.mul(100)).div(totalBNBfees);
        _teamPercent = (_teamFee.mul(100)).div(totalBNBfees);
        _devPercent = (_devFee.mul(100)).div(totalBNBfees);
        
        emit FeesUpdated(_rfiFee, _marketingFee, _liquidityFee, _teamFee, _devFee);
    }



    function setPresaleRouterAndAddress(address router, address wallet) external onlyOwner() {
        presaleRouter = router;
        presaleAddress = wallet;
        excludeFromFee(presaleRouter);
        excludeFromFee(presaleAddress);
    }

    function endPresale(uint256 botBlocks) external onlyOwner() {
        require(presale == true, "presale already ended");
        presale = false;
        openTrading(botBlocks);
        emit EndedPresale(presale);
    }
    
    function updateDevAddress(address payable devAddress) external onlyOwner() {
        _devAddress = devAddress;
    }
    
    function updateMarketingAddress(address payable marketingAddress) external onlyOwner() {
        _marketingAddress = marketingAddress;
    }
    
    function updateTeamAddress(address payable teamAddress) external onlyOwner() {
        _teamAddress = teamAddress;
    }
    
   
}