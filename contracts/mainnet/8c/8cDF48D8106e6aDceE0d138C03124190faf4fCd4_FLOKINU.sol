/**
 *Submitted for verification at Etherscan.io on 2021-06-25
*/

/*
Straight out of Kattegat, raised between sheeps, wooden houses covered in bear fur & self made viking ships, 
Flokinu has decided to show himself on the Uniswap meme token scene. Absolutely usesless as the token is, 
he prays to Odin that the ape/degen's community shows themselves once more to prove this could be a possible mooner!

Telegram: t.me/officialflokinu



SPDX-License-Identifier: M̧͖̪̬͚͕̘̻̙̫͎̉̾͑̽͌̓̏̅͌̕͘ĩ̢͎̥̦̼͖̾̀͒̚͠n̺̼̳̩̝̐͒̑̄̕͢͞è̫̦̬͙̌͗͡ş̣̞̤̲̳̭̫̬̦͗́͂̅̉̒̍͑̑̒̈́̏͟͜™͍͙͆̒̏ͅ®̳̻̋̿©͕̅
*/

pragma solidity ^0.8.6;
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

contract Ownable is Context {
    address private _owner;
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
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
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function approve(address to, uint value) external returns (bool);
}

contract FLOKINU is Context, IERC20, Ownable {
    string private constant _name = unicode"Flokinu💨";
    string private constant _symbol = "FLOKINU";
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping(address => uint256)) private _allowances;
    mapping (address => bool) private bots;
    mapping (address => uint) private cooldown;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    IUniswapV2Router02 private uniswapV2Router;
    address[] private _excluded;
    address private c;
    address private bob;
    address private otherguy;
    address private uniswapV2Pair;
    address private WETH;
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 1000000 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    uint256 private _taxFee;
    uint256 private _LiquidityFee;
    uint64 private buyCounter;
    uint8 private constant _decimals = 9;
    uint16 private maxTx;
    bool private tradingOpen;
    bool private inSwap;
    bool private swapEnabled;
    bool private cooldownEnabled;
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
    constructor(address payable _bob, address payable _otherguy) {
        c = address(this);
        bob = _bob;
        otherguy = _otherguy;
        _rOwned[c] = _rTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[c] = true;
        _isExcludedFromFee[bob] = true;
        _isExcludedFromFee[otherguy] = true;
        excludeFromReward(owner());
        excludeFromReward(c);
        excludeFromReward(bob);
        excludeFromReward(otherguy);
        emit Transfer(address(0),c,_tTotal);
    }
    
    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }
    
    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }
    
    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }
    
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender,_msgSender(),_allowances[sender][_msgSender()] - amount);
        return true;
    }

    function tokenFromReflection(uint256 rAmount) private view returns (uint256) {
        require(rAmount <= _rTotal,"Amount must be less than total reflections");
        uint256 currentRate = _getRate();
        return rAmount / currentRate;
    }

    function nofees() private {
        _taxFee = 0;
        _LiquidityFee = 0;
    }
    
    function basefees() private {
        _taxFee = 2;
        _LiquidityFee = 18;
    }
    
    function setBots(address[] memory bots_) public onlyOwner {
        for (uint i = 0; i < bots_.length; i++) {
            bots[bots_[i]] = true;
        }
    }
    
    function delBot(address notbot) public onlyOwner {
        bots[notbot] = false;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!bots[from] && !bots[to]);
        basefees();
        if (from != owner() && to != owner() && tradingOpen) {
            if (cooldownEnabled && !inSwap) {
                if (from != address(this) && to != address(this) && from != address(uniswapV2Router) && to != address(uniswapV2Router)) {
                    require(_msgSender() == address(uniswapV2Router) || _msgSender() == uniswapV2Pair,"ERR: Uniswap only");
                }
            }
            if (from == uniswapV2Pair && to != address(uniswapV2Router) && !_isExcludedFromFee[to] && !inSwap) {
                if (buyCounter < 100)
                    require(amount <= _tTotal * maxTx / 1000);
                if (cooldownEnabled) {
                    require(cooldown[to] < block.timestamp);
                    if (buyCounter < 30)
                        cooldown[to] = block.timestamp + (10 minutes);
                    else
                        cooldown[to] = block.timestamp + (30 seconds);
                }
                if (buyCounter % 50 == 0 && buyCounter != 0)
                    nofees();
                buyCounter++;
            }
            if (to == uniswapV2Pair && from != address(uniswapV2Router) && ! _isExcludedFromFee[from] && !inSwap) {
                require(cooldown[from] < block.timestamp);
                if (swapEnabled) {
                    uint256 contractTokenBalance = balanceOf(c);
                    if (contractTokenBalance > balanceOf(uniswapV2Pair) * 1 / 10000) {
                        swapAndLiquify(contractTokenBalance);
                    }
                }
            }
            if (!inSwap) {
                if (buyCounter == 25)
                    maxTx = 20; // 2%
                if (buyCounter == 50) {
                    maxTx = 50; // 5%
                    cooldownEnabled = false;
                }
                //if (buyCounter == 100)
                //    maxTx = 1000; // 100%
                //don't need to set max to 100% here to disable it since max stops getting checked after the 100th buy
            }
        }
        
        bool takeFee = true;

        if (_isExcludedFromFee[from] || _isExcludedFromFee[to] || inSwap) {
            takeFee = false;
        }

        _tokenTransfer(from, to, amount, takeFee);  
    }
    
    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        swapTokensForEth(contractTokenBalance);
        uint256 balance = c.balance / 2;
        sendETHToFee(balance);
        IWETH(WETH).deposit{value: balance}();
        assert(IWETH(WETH).transfer(uniswapV2Pair, balance));
    }
    
    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = c;
        path[1] = WETH;
        _approve(c, address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, c, block.timestamp);
    }
    
    function sendETHToFee(uint256 ETHamount) private {
        payable(bob).transfer(ETHamount / 2);
        payable(otherguy).transfer(ETHamount / 2);
    }
    
    function openTrading() external onlyOwner() {
        require(!tradingOpen, "trading is already open");
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        WETH = uniswapV2Router.WETH();
        _approve(c, address(uniswapV2Router), ~uint256(0));
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(c, WETH);
        uniswapV2Router.addLiquidityETH{value: c.balance}(c,balanceOf(c),0,0,owner(),block.timestamp);
        maxTx = 10; // 1%
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router),~uint256(0));
        tradingOpen = true;
        swapEnabled = true;
        cooldownEnabled = true;
    }
    
    function manualswap() external {
        require(_msgSender() == bob || _msgSender() == otherguy);
        uint256 contractBalance = balanceOf(c);
        swapTokensForEth(contractBalance);
    }
    
    function manualsend() external {
        require(_msgSender() == bob || _msgSender() == otherguy);
        uint256 contractETHBalance = c.balance;
        sendETHToFee(contractETHBalance);
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if (!takeFee) nofees();
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _tOwned[recipient] = _tOwned[recipient] + tTransferAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender] - tAmount;
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount; 
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender] - tAmount;
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _tOwned[recipient] = _tOwned[recipient] + tTransferAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = tLiquidity * currentRate;
        _rOwned[c] = _rOwned[c] + rLiquidity;
        _tOwned[c] = _tOwned[c] + tLiquidity;
    }
	
	function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal - rFee;
        _tFeeTotal = _tFeeTotal + tFee;
    }

    receive() external payable {}

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount, _taxFee, _LiquidityFee);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity);
    }

    function _getTValues(uint256 tAmount, uint256 taxFee, uint256 LiquidityFee) private pure returns (uint256, uint256, uint256) {
        uint256 tFee = tAmount * taxFee / 100;
        uint256 tLiquidity = tAmount * LiquidityFee / 100;
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

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / tSupply;
    }

    function excludeFromReward(address addr) internal {
        require(addr != address(uniswapV2Router), 'ERR: Can\'t exclude Uniswap router');
        require(!_isExcluded[addr], "Account is already excluded");
        if(_rOwned[addr] > 0) {
            _tOwned[addr] = tokenFromReflection(_rOwned[addr]);
        }
        _isExcluded[addr] = true;
        _excluded.push(addr);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply - _rOwned[_excluded[i]];
            tSupply = tSupply - _tOwned[_excluded[i]];
        }
        if (rSupply < _rTotal / _tTotal) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
	
}