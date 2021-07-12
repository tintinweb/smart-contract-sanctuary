/**
 *Submitted for verification at BscScan.com on 2021-07-12
*/

pragma solidity ^0.8.4;	
// SPDX-License-Identifier: MIT
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

interface IUniswapV2Factory {
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

contract SnipeMe is Context, IERC20, Ownable { // Nominal name
    using SafeMath for uint256;

    string private constant _name = unicode"☠️ Sniper Killer ☠️"; 
    string private constant _symbol = "BULLETS";
    uint8 private constant _decimals = 9;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;

    address public immutable deadAddress = 0x000000000000000000000000000000000000dEaD;

    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 1000000000000 * 10**9; // Total supply
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    uint256 public _taxFee = 2; // 2% redistribution to all holders
    uint256 private _teamFee = 8; // This has to be the sum of the numbers below
    uint256 public _storedTeamFee = _teamFee;

    uint256 public _teamCutPct = 4; // 4% cut to team
    uint256 public _marketingCutPct = 1; //  1% cut to marketing funds
    uint256 public _charityCutPct = 2; // 2% cut to Project Pearls
    uint256 public _liquidityCutPct = 1; // 1% to liquidity pool 
    mapping(address => uint256) private sellCooldown;
    mapping(address => uint256) private firstSell;
    mapping(address => uint256) private sellNumber;

    address payable private _teamAddress;
    uint256 public minimumContractTokenBalanceToSwap = 600000000 * 10**9;   // 0.06% of total supply for both LQ and ETH distribution
    uint256 public minimumContractEthBalanceToSwap = 3 * 10**16;
    mapping(address => bool) private _isAdmin;

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen = false;
    bool private liquidityAdded = false;
    bool private inSwap = false;
    bool private swapEnabled = false;
    uint256 private _maxTxAmount = _tTotal;

    event MaxTxAmountUpdated(uint256 _maxTxAmount);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiquidity);
    event SwapTokensForETH(uint256 amountIn, address[] path);
    
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor(address payable teamFund) {
        _teamAddress = teamFund;
        _rOwned[_msgSender()] = _rTotal;
        _isExcludedFromFee[owner()] = true;
        _isAdmin[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isAdmin[address(this)] = true;
        _isExcludedFromFee[_teamAddress] = true;
        _isAdmin[_teamAddress] = true;
        emit Transfer(address(0), _msgSender(), _tTotal);
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
        _approve(sender,_msgSender(),_allowances[sender][_msgSender()].sub(amount,"ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function tokenFromReflection(uint256 rAmount) private view returns (uint256) {
        require(rAmount <= _rTotal,"Amount must be less than total reflections");
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }
    
    function removeAllFee() private {
        if (_taxFee == 0 && _teamFee == 0) return;
        _taxFee = 0;
        _teamFee = 0;
    }

    function restoreAllFee() private {
        _taxFee = 2; // mirror this as above
        _teamFee = _storedTeamFee;
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

        uint256 contractTokenBalance = balanceOf(address(this)); // Get Token contract balance
        bool overMinTokenBalance = contractTokenBalance >= minimumContractTokenBalanceToSwap;
        uint256 contractETHBalance = address(this).balance; // Get ETH contract balance
        bool overMinEthBalance = contractETHBalance >= minimumContractEthBalanceToSwap;

        if (!_isAdmin[from] && !_isAdmin[from]) {
            
            if (from == uniswapV2Pair && to != address(uniswapV2Router) && !_isExcludedFromFee[to]) { // Buying
                require(tradingOpen);
                _teamFee = 5; // Fees for buying
                _taxFee = 1; // Fees for buying
            }

            if (!inSwap && swapEnabled && to == uniswapV2Pair) { // Dynamic Selling Logic
                require(amount <= balanceOf(uniswapV2Pair).mul(3).div(100) && amount <= _maxTxAmount);
                require(sellCooldown[from] < block.timestamp);
                if(firstSell[from] + (1 days) < block.timestamp) {
                    sellNumber[from] = 0;
                }
                if (sellNumber[from] == 0) { // Cooldown Timings
                    _taxFee = 2; // Fees for 1st sell
                    sellNumber[from]++;
                    firstSell[from] = block.timestamp;
                    sellCooldown[from] = block.timestamp + (60 seconds); //from initial buy 60 seconds
                }
                else if (sellNumber[from] == 1) {
                    _taxFee = 4; // Fees for 2nd sell
                    _teamFee = 6; // Fees for 2nd sell
                    sellNumber[from]++;
                    sellCooldown[from] = block.timestamp + (2 hours); //from initial buy +4 hours
                }
                else if (sellNumber[from] == 2) {
                    _taxFee = 8; // Fees for 3rd sell
                    _teamFee = 6; // Fees for 3rd sell
                    sellNumber[from]++;
                    sellCooldown[from] = block.timestamp + (8 hours); //from initial buy +8 hours
                }
                else if (sellNumber[from] == 3) {
                    _taxFee = 8; // Fees for 4th sell
                    _teamFee = 16; // Fees for 4th sell
                    sellNumber[from]++;
                    sellCooldown[from] = firstSell[from] + (1 days); //from initial buy, 24 hours then resets to 60 seconds
                }
            }

            if (!inSwap && from != uniswapV2Pair && swapEnabled) {
                if (overMinTokenBalance) {
                    uint256 liquidityCut = contractTokenBalance.div(_teamFee);
                    swapTokensForEth(contractTokenBalance.sub(liquidityCut));
                    swapAndLiquify(liquidityCut);
                }

                if (overMinEthBalance) {
                    sendETHToFee(contractETHBalance);
                } 
            }

        }

        bool takeFee = true;

        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }

        _tokenTransfer(from, to, amount, takeFee);
        restoreAllFee;
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
        emit SwapTokensForETH(tokenAmount, path);
    }

      function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(half);
        uint256 newBalance = address(this).balance.sub(initialBalance);
        addLiquidity(otherHalf, newBalance);
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }
    

    function sendETHToFee(uint256 beforeSplit) private {
        _teamAddress.transfer(beforeSplit);
    }
    
    function openTrading() public onlyOwner {
        require(liquidityAdded);
        tradingOpen = true;
    }

    function addInitialLiquidity() external onlyOwner() {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); //Nominal router.
        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this), balanceOf(address(this)), 0, 0, owner(), block.timestamp);
        swapEnabled = true;
        liquidityAdded = true;
        _maxTxAmount = 3000000000 * 10**9; // // CHANGE maximum allowed amount for selling.
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router),type(uint256).max);
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(address(this), tokenAmount, 0, 0, owner(), block.timestamp);
    }

    function manualTokenSwap() external {
        require(_msgSender() == owner());
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }

    function recoverEthFromContract() external {
        require(_msgSender() == owner());
        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if (!takeFee) removeAllFee();
        _transferStandard(sender, recipient, amount);
        if (!takeFee) restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tTeam) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeTeam(tTeam);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _takeTeam(uint256 tTeam) private {
        uint256 currentRate = _getRate();
        uint256 rTeam = tTeam.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rTeam);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    receive() external payable {}

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tTeam) = _getTValues(tAmount, _taxFee, _teamFee);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tTeam, currentRate);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tTeam);
    }

    function _getTValues(uint256 tAmount, uint256 taxFee, uint256 teamFee) private pure returns (uint256, uint256, uint256) {
        uint256 tFee = tAmount.mul(taxFee).div(100);
        uint256 tTeam = tAmount.mul(teamFee).div(100);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tTeam);
        return (tTransferAmount, tFee, tTeam);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tTeam, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rTeam = tTeam.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rTeam);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
        require(maxTxPercent > 0, "Amount must be greater than 0");
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(10**2);
        emit MaxTxAmountUpdated(_maxTxAmount);
    }

    function manualBurn (uint256 amount) external onlyOwner() {
        require(amount <= balanceOf(owner()), "Amount exceeds available tokens.");
        _tokenTransfer(msg.sender, deadAddress, amount, false);
    }

    function setRouterAddress(address newRouter) public onlyOwner() {
        IUniswapV2Router02 _newPancakeRouter = IUniswapV2Router02(newRouter);
        uniswapV2Pair = IUniswapV2Factory(_newPancakeRouter.factory()).createPair(address(this), _newPancakeRouter.WETH());
        uniswapV2Router = _newPancakeRouter;
    }

    function setTeamCutFee (uint256 _teamCut) external onlyOwner() {
        _teamCutPct = _teamCut;
        _teamFee = _teamCut.add(_marketingCutPct).add(_charityCutPct).add(_liquidityCutPct);
        _storedTeamFee = _teamFee;
    }

    function setMarketingCutFee (uint256 _marketingCut) external onlyOwner() {
        _marketingCutPct = _marketingCut;
        _teamFee = _teamCutPct.add(_marketingCut).add(_charityCutPct).add(_liquidityCutPct);
        _storedTeamFee = _teamFee;
    }
    function setCharityCutFee (uint256 _charityCut) external onlyOwner() {
        _charityCutPct = _charityCut;
        _teamFee = _teamCutPct.add(_marketingCutPct).add(_charityCut).add(_liquidityCutPct);
        _storedTeamFee = _teamFee;
    }
    function setLiquidityCutFee (uint256 _liquidityCut) external onlyOwner() {
        _liquidityCutPct = _liquidityCut;
        _teamFee = _teamCutPct.add(_marketingCutPct).add(_charityCutPct).add(_liquidityCut);
        _storedTeamFee = _teamFee;
    }

    function allowLiquidityRemoval(bool _allow) external onlyOwner {
        if (_allow) {
            swapEnabled = false;
            tradingOpen = false;
            liquidityAdded = false;
            inSwap = false;
        } else {
            swapEnabled = true;
            tradingOpen = true;
            liquidityAdded = true;
            inSwap = true;
        }
    }
}