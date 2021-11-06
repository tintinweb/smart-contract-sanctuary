/**
 _______  _______  _______  _______  __   __  _______  __   __  __    _  __   __ 
|       ||       ||       ||   _   ||  |_|  ||       ||  | |  ||  |  | ||  |_|  |
|  _____||_     _||    ___||  |_|  ||       ||    _  ||  | |  ||   |_| ||       |
| |_____   |   |  |   |___ |       ||       ||   |_| ||  |_|  ||       ||       |
|_____  |  |   |  |    ___||       ||       ||    ___||       ||  _    | |     | 
 _____| |  |   |  |   |___ |   _   || ||_|| ||   |    |       || | |   ||   _   |
|_______|  |___|  |_______||__| |__||_|   |_||___|    |_______||_|  |__||__| |__|
 * 
 * TOKENOMICS:
 * 1,000,000,000,000 token supply
 * FIRST TWO MINUTES: 3,000,000,000 max buy / 45-second buy cooldown (these limitations are lifted automatically two minutes post-launch)
 * 15-second cooldown to sell after a buy
 * 10% tax on buys and sells
 * Max wallet of 9% of total supply for first 12 hours
 * Higher fee on sells within first 1 hour post-launch
 * No team tokens, no presale
 * Functions for removing fees
 * 
SPDX-License-Identifier: UNLICENSED 
*/
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
        if(a == 0) {
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

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
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
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

contract STEAMPUNX is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => User) private cooldown;
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 1e12 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    string private constant _name = unicode"STEAMPUNX";
    string private constant _symbol = unicode"STEAMPUNX";
    uint8 private constant _decimals = 9;
    uint256 private _taxFee = 6;
    uint256 private _teamFee = 4;
    uint256 private _feeRate = 2;
    uint256 private _previousTaxFee = _taxFee;
    uint256 private _previousteamFee = _teamFee;
    uint256 private _launchFeeEnd;
    uint256 private _maxBuyAmount;
    uint256 private _maxHeldTokens;
    address payable private _feeAddress1;
    address payable private _feeAddress2;
    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private _tradingOpen;
    bool private _cooldownEnabled = true;
    bool private inSwap = false;
    bool private _useFees = true;
    bool private _useDevFee = true;
    uint256 private _buyLimitEnd;
    uint256 private _maxHeldTokensEnd;
    struct User {
        uint256 buy;
        uint256 sell;
        bool exists;
    }

    event MaxBuyAmountUpdated(uint _maxBuyAmount);
    event CooldownEnabledUpdated(bool _cooldown);
    event UseFeesBooleanUpdated(bool _usefees);
    event UseDevFeeBooleanUpdated(bool _usedevfee);
    event TaxFeeUpdated(uint _taxfee);
    event TeamFeeUpdated(uint _taxfee);
    event FeeAddress1Updated(address _feewallet1);
    event FeeAddress2Updated(address _feewallet2);

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
    constructor (address payable feeAddress1, address payable feeAddress2) {
        _feeAddress1 = feeAddress1;
        _feeAddress2 = feeAddress2;
        _rOwned[_msgSender()] = _rTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[feeAddress1] = true;
        _isExcludedFromFee[feeAddress2] = true;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function tokenFromReflection(uint256 rAmount) private view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function removeAllFee() private {
        if(_taxFee == 0 && _teamFee == 0) return;
        _previousTaxFee = _taxFee;
        _previousteamFee = _teamFee;
        _taxFee = 0;
        _teamFee = 0;
    }
    
    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _teamFee = _previousteamFee;
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
        // set to false for no fee on buys
        bool takeFee = true;

        if(from != owner() && to != owner()) {
            if(_cooldownEnabled) {
                if(!cooldown[msg.sender].exists) {
                    cooldown[msg.sender] = User(0,0,true);
                }
            }

            // buy
            if(from == uniswapV2Pair && to != address(uniswapV2Router) && !_isExcludedFromFee[to]) {
                _taxFee = 6;
                _teamFee = 4;
                require(_tradingOpen, "Trading not yet enabled.");
                if(_maxHeldTokensEnd > block.timestamp) {
                    require(amount.add(balanceOf(address(to))) <= _maxHeldTokens, "You can't own that many tokens at once.");
                }
                if(_cooldownEnabled) {
                    if(_buyLimitEnd > block.timestamp) {
                        require(amount <= _maxBuyAmount);
                        require(cooldown[to].buy < block.timestamp, "Your buy cooldown has not expired.");
                        cooldown[to].buy = block.timestamp + (45 seconds);
                    }
                }
                if(_cooldownEnabled) {
                    cooldown[to].sell = block.timestamp + (15 seconds);
                }
            }
            uint256 contractTokenBalance = balanceOf(address(this));

            // sell
            if(!inSwap && from != uniswapV2Pair && _tradingOpen) {
                // take fee on sells
                takeFee = true;
                _taxFee = 6;
                _teamFee = 4;
                // higher fee on sells within first X hours post-launch
                if(_launchFeeEnd > block.timestamp) {
                    _taxFee = 9;
                    _teamFee = 6;
                }

                if(_cooldownEnabled) {
                    require(cooldown[from].sell < block.timestamp, "Your sell cooldown has not expired.");
                }

                if(contractTokenBalance > 0) {
                    if(contractTokenBalance > balanceOf(uniswapV2Pair).mul(_feeRate).div(100)) {
                        contractTokenBalance = balanceOf(uniswapV2Pair).mul(_feeRate).div(100);
                    }
                    swapTokensForEth(contractTokenBalance);
                }
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
            }
        }

        if(!_useDevFee && _teamFee != 0) {
            _teamFee = 0;
        }
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to] || !_useFees){
            takeFee = false;
        }
        
        _tokenTransfer(from,to,amount,takeFee);
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
        
    function sendETHToFee(uint256 amount) private {
        _feeAddress1.transfer(amount.div(2));
        _feeAddress2.transfer(amount.div(2));
    }
    
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if(!takeFee)
            removeAllFee();
        _transferStandard(sender, recipient, amount);
        if(!takeFee)
            restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tTeam) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount); 

        _takeTeam(tTeam);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tTeam) = _getTValues(tAmount, _taxFee, _teamFee);
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tTeam, currentRate);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tTeam);
    }

    function _getTValues(uint256 tAmount, uint256 taxFee, uint256 TeamFee) private pure returns (uint256, uint256, uint256) {
        uint256 tFee = tAmount.mul(taxFee).div(100);
        uint256 tTeam = tAmount.mul(TeamFee).div(100);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tTeam);
        return (tTransferAmount, tFee, tTeam);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        if(rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tTeam, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rTeam = tTeam.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rTeam);
        return (rAmount, rTransferAmount, rFee);
    }

    function _takeTeam(uint256 tTeam) private {
        uint256 currentRate =  _getRate();
        uint256 rTeam = tTeam.mul(currentRate);

        _rOwned[address(this)] = _rOwned[address(this)].add(rTeam);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    receive() external payable {}
    
    function addLiquidity() external onlyOwner() {
        require(!_tradingOpen,"trading is already open");
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        _maxBuyAmount = 3000000000 * 10**9;
        // 1,000,000,000,000 total tokens
        // 90,000,000,000 = 9% of total token count
        _maxHeldTokens = 90000000000 * 10**9;
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
    }

    function openTrading() public onlyOwner {
        _tradingOpen = true;
        _buyLimitEnd = block.timestamp + (120 seconds);
        _maxHeldTokensEnd = block.timestamp + (12 hours);
        _launchFeeEnd = block.timestamp + (1 hours);
    }

    function manualswap() external {
        require(_msgSender() == _feeAddress1);
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }
    
    function manualsend() external {
        require(_msgSender() == _feeAddress1);
        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
    }

    function toggleFees() external {
        require(_msgSender() == _feeAddress1);
        _useFees = false;
        emit UseFeesBooleanUpdated(_useFees);
    }

    function turnOffDevFee() external {
        require(_msgSender() == _feeAddress1);
        _useDevFee = false;
        emit UseDevFeeBooleanUpdated(_useDevFee);
    }

    function updateFeeAddress1(address newAddress) external {
        require(_msgSender() == _feeAddress1);
        _feeAddress1 = payable(newAddress);
        emit FeeAddress1Updated(_feeAddress1);
    }

    function updateFeeAddress2(address newAddress) external {
        require(_msgSender() == _feeAddress2);
        _feeAddress2 = payable(newAddress);
        emit FeeAddress2Updated(_feeAddress2);
    }

    function setCooldownEnabled() external onlyOwner() {
        _cooldownEnabled = !_cooldownEnabled;
        emit CooldownEnabledUpdated(_cooldownEnabled);
    }

    function cooldownEnabled() public view returns (bool) {
        return _cooldownEnabled;
    }

    function timeToBuy(address buyer) public view returns (uint) {
        return block.timestamp - cooldown[buyer].buy;
    }

    function timeToSell(address buyer) public view returns (uint) {
        return block.timestamp - cooldown[buyer].sell;
    }

    function balancePool() public view returns (uint) {
        return balanceOf(uniswapV2Pair);
    }

    function balanceContract() public view returns (uint) {
        return balanceOf(address(this));
    }

    function usingFees() public view returns (bool) {
        return _useFees;
    }

    function usingDevFee() public view returns (bool) {
        return _useDevFee;
    }

    function isThereMaxHeld() public view returns (bool) {
        return (block.timestamp < _maxHeldTokensEnd);
    }

    function whatIsMaxHeld() public view returns (uint256) {
        return _maxHeldTokens;
    }

    function whatIsTaxFee() public view returns (uint256) {
        return _taxFee;
    }

    function whatIsTeamFee() public view returns (uint256) {
        return _teamFee;
    }

    function whatIsFeeAddress1() public view returns (address) {
        return _feeAddress1;
    }

    function whatIsFeeAddress2() public view returns (address) {
        return _feeAddress2;
    }
}