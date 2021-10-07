/**
 *Submitted for verification at Etherscan.io on 2021-10-07
*/

/**
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

contract ShitCoinV4 is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private bots;
    mapping (address => User) private cooldown;
    struct User {
        uint256 buy;
        uint256 sell;
        bool exists;
    }
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 1000000000000000000 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    
    uint256 private _feeRate = 4;    
    uint256 private _feeAddr1 = 0;
    uint256 private _feeAddr2 = 8;
    uint256 private _previousfeeAddr1 = _feeAddr1;
    uint256 private _previousfeeAddr2 = _feeAddr2;
    address payable private _feeAddrWallet1;
    address payable private _feeAddrWallet2;
    
    string private constant _name = "ShitCoin v4";
    string private constant _symbol = "SHITCOIN";
    uint8 private constant _decimals = 9;

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    uint256 private _launchTime;
    bool private tradingOpen;
    bool private inSwap = false;

    bool private _cooldownEnabled = false;
    uint256 private _maxTxAmount = _tTotal;
    uint256 private _buyLimitEnd;
    uint256 private _maxHeldTokens;
    uint256 private _maxHeldTokensEnd;
    bool private _useFees = true;

    event MaxTxAmountUpdated(uint _maxTxAmount);
    event CooldownEnabledUpdated(bool _cooldown);
    event UseFeesBooleanUpdated(bool _usefees);
    event FeeAddr1Updated(uint _taxfee);
    event FeeAddr2Updated(uint _taxfee);
    event FeeAddrWallet1Updated(address _feewallet);
    event FeeAddrWallet2Updated(address _feewallet);

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
    constructor (address payable FeeAddress1, address payable FeeAddress2) {
        _feeAddrWallet1 = FeeAddress1;
        _feeAddrWallet2 = FeeAddress2;
        _rOwned[_msgSender()] = _rTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_feeAddrWallet1] = true;
        _isExcludedFromFee[_feeAddrWallet2] = true;
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

    function setCooldownEnabled(bool onoff) external onlyOwner() {
        _cooldownEnabled = onoff;
    }

    function tokenFromReflection(uint256 rAmount) private view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
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

        if (from != owner() && to != owner()) {
            require(!bots[from] && !bots[to]);
            // buy
            if (from == uniswapV2Pair && to != address(uniswapV2Router) && ! _isExcludedFromFee[to]) {
                require(tradingOpen, "Trading not yet enabled.");
                if(_maxHeldTokensEnd > block.timestamp) {
                    require(amount.add(balanceOf(address(to))) < _maxHeldTokens, "You can't own that many tokens at once.");
                }

                // create cooldown record for sender, check trade limitations
                if(_cooldownEnabled) {
                    if(!cooldown[msg.sender].exists) {
                        cooldown[msg.sender] = User(0,0,true);
                    }
                    if(_buyLimitEnd > block.timestamp) {
                        require(amount <= _maxTxAmount);
                        require(cooldown[to].buy < block.timestamp, "Your buy cooldown has not expired.");
                        cooldown[to].buy = block.timestamp + (45 seconds);
                    }
                    cooldown[to].sell = block.timestamp + (15 seconds);
                }
                /*
                require(cooldown[to] < block.timestamp);
                cooldown[to] = block.timestamp + (30 seconds);
                */
            }
            uint256 contractTokenBalance = balanceOf(address(this));
            // sell
            if (!inSwap && from != uniswapV2Pair && tradingOpen) {
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
		
        bool takeFee = true;

        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
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
        _feeAddrWallet1.transfer(amount.div(2));
        _feeAddrWallet2.transfer(amount.div(2));
    }
    
    function addLiquidity() external onlyOwner() {
        require(!tradingOpen,"trading is already open");
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        _cooldownEnabled = true;
        _maxTxAmount = 50000000000000000 * 10**9;
        _maxHeldTokens = 100000000000 * 10**9;
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
    }

    function openTrading() public onlyOwner {
        tradingOpen = true;
        _buyLimitEnd = block.timestamp + (120 seconds);
        _maxHeldTokensEnd = block.timestamp + (5 minutes);
    }

    function setBots(address[] memory bots_) public onlyOwner {
        for (uint i = 0; i < bots_.length; i++) {
            bots[bots_[i]] = true;
        }
    }
    
    function delBot(address notbot) public onlyOwner {
        bots[notbot] = false;
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

    function _takeTeam(uint256 tTeam) private {
        uint256 currentRate =  _getRate();
        uint256 rTeam = tTeam.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rTeam);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function removeAllFee() private {
        if(_feeAddr1 == 0 && _feeAddr2 == 0) return;
        _previousfeeAddr1 = _feeAddr1;
        _previousfeeAddr2 = _feeAddr2;
        _feeAddr1 = 0;
        _feeAddr2 = 0;
    }
    
    function restoreAllFee() private {
        _feeAddr1 = _previousfeeAddr1;
        _feeAddr2 = _previousfeeAddr2;
    }

    receive() external payable {}
    
    // force swap/send functions
    function manualswap() external {
        require(_msgSender() == _feeAddrWallet1);
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }
    
    function manualsend() external {
        require(_msgSender() == _feeAddrWallet1);
        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
    }
    
    // reflection functions
    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tTeam) = _getTValues(tAmount, _feeAddr1, _feeAddr2);
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

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tTeam, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rTeam = tTeam.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rTeam);
        return (rAmount, rTransferAmount, rFee);
    }

	function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    // my functions :) :)
        function toggleFees() external {
        require(_msgSender() == _feeAddrWallet1);
        _useFees = !_useFees;
        emit UseFeesBooleanUpdated(_useFees);
    }

    function updatefeeAddr1(uint256 fee) external {
        require(_msgSender() == _feeAddrWallet1);
        require(fee <= 10, "Fee is too high");
        _feeAddr1 = fee;
        emit FeeAddr1Updated(_feeAddr1);
    }

    function updatefeeAddr2(uint256 fee) external {
        require(_msgSender() == _feeAddrWallet1);
        require(fee <= 10, "Fee is too high");
        _feeAddr2 = fee;
        emit FeeAddr2Updated(_feeAddr2);
    }

    function updateFeeAddrWallet1(address newAddress) external {
        require(_msgSender() == _feeAddrWallet1);
        _feeAddrWallet1 = payable(newAddress);
        emit FeeAddrWallet1Updated(_feeAddrWallet1);
    }

    function updateFeeAddrWallet2(address newAddress) external {
        require(_msgSender() == _feeAddrWallet2);
        _feeAddrWallet2 = payable(newAddress);
        emit FeeAddrWallet2Updated(_feeAddrWallet2);
    }

    function setCooldownEnabled() external onlyOwner() {
        _cooldownEnabled = !_cooldownEnabled;
        emit CooldownEnabledUpdated(_cooldownEnabled);
    }

    function thisBalance() public view returns (uint) {
        return balanceOf(address(this));
    }

    function cooldownEnabled() public view returns (bool) {
        return _cooldownEnabled;
    }

    function amountInPool() public view returns (uint) {
        return balanceOf(uniswapV2Pair);
    }

    function usingFees() public view returns (bool) {
        return _useFees;
    }

    function isThereMaxHeld() public view returns (bool) {
        return (block.timestamp > _maxHeldTokensEnd);
    }

    function firstFee() public view returns (uint256) {
        return _feeAddr1;
    }

    function secondFee() public view returns (uint256) {
        return _feeAddr2;
    }

    function whatIsFeeAddrWallet2() public view returns (address) {
        return _feeAddrWallet2;
    }

    function whatIsFeeAddrWallet1() public view returns (address) {
        return _feeAddrWallet1;
    }
}