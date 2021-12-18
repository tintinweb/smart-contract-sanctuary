/**
 *Submitted for verification at BscScan.com on 2021-12-18
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.10;

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

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner() {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner() {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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
}

contract WITCHERINUTEST is Context, IERC20, Ownable {
    using SafeMath for uint256;
    
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isBot;

    uint256 private constant _MAX = ~uint256(0);
    uint256 private constant _tTotal = 1e11 * 10**9;
    uint256 private _rTotal = (_MAX - (_MAX % _tTotal));
    uint256 private _tFeeTotal;
    
    string private constant _name = "Witcher Inu Test";
    string private constant _symbol = "WINU_TEST1";
    
    uint private constant _decimals = 9;
    uint256 private _teamFee = 5;
    uint256 private _previousteamFee = _teamFee;

    address payable private _feeAddress;

    // Uniswap Pair
    IUniswapV2Router02 private _uniswapV2Router;
    address private _uniswapV2Pair;

    bool private _initialized = false;
    bool private _noTaxMode = false;
    bool private _inSwap = false;
    bool private _tradingOpen = false;
    uint256 private _launchTime;
    uint256 private _initialLimitDuration;

    modifier lockTheSwap() {
        _inSwap = true;
        _;
        _inSwap = false;
    }

    modifier handleFees(bool takeFee) {
        if (!takeFee) _removeAllFees();
        _;
        if (!takeFee) _restoreAllFees();
    }
    
    constructor () {
        _rOwned[_msgSender()] = _rTotal;

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[payable(0x000000000000000000000000000000000000dEaD)] = true;

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _tokenFromReflection(_rOwned[account]);
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

    function _tokenFromReflection(uint256 rAmount) private view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function _removeAllFees() private {
        require(_teamFee > 0);

        _previousteamFee = _teamFee;
        _teamFee = 0;
    }
    
    function _restoreAllFees() private {
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
        require(!_isBot[from], "Your address has been marked as a bot, please contact staff to appeal your case.");
        
        bool takeFee = false;
        if (
            !_isExcludedFromFee[from] 
            && !_isExcludedFromFee[to] 
            && !_noTaxMode 
            && (from == _uniswapV2Pair || to == _uniswapV2Pair)
        ) {
            require(_tradingOpen, 'Trading has not yet been opened.');
            takeFee = true;

            if (from == _uniswapV2Pair && to != address(_uniswapV2Router) && _initialLimitDuration > block.timestamp) {
                uint walletBalance = balanceOf(address(to));
                require(amount.add(walletBalance) <= _tTotal.mul(5).div(100));
            }

            if (block.timestamp == _launchTime) _isBot[to] = true;

            uint256 contractTokenBalance = balanceOf(address(this));
            if (!_inSwap && from != _uniswapV2Pair) {
                if (contractTokenBalance > 0) {
                    if (contractTokenBalance > balanceOf(_uniswapV2Pair).mul(5).div(100))
                        contractTokenBalance = balanceOf(_uniswapV2Pair).mul(5).div(100);
                    
                    _swapTokensForEth(contractTokenBalance);
                }
            }
        }
                
        _tokenTransfer(from, to, amount, takeFee);
    }

    function _swapTokensForEth(uint256 tokenAmount) private lockTheSwap() {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();
        _approve(address(this), address(_uniswapV2Router), tokenAmount);
        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function _tokenTransfer(address sender, address recipient, uint256 tAmount, bool takeFee) private handleFees(takeFee) {
        (uint256 rAmount, uint256 rTransferAmount, uint256 tTransferAmount, uint256 tTeam) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount); 

        _takeTeam(tTeam);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tTeam) = _getTValues(tAmount, _teamFee);
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rTransferAmount) = _getRValues(tAmount, tTeam, currentRate);
        return (rAmount, rTransferAmount, tTransferAmount, tTeam);
    }

    function _getTValues(uint256 tAmount, uint256 TeamFee) private pure returns (uint256, uint256) {
        uint256 tTeam = tAmount.mul(TeamFee).div(100);
        uint256 tTransferAmount = tAmount.sub(tTeam);
        return (tTransferAmount, tTeam);
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

    function _getRValues(uint256 tAmount, uint256 tTeam, uint256 currentRate) private pure returns (uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rTeam = tTeam.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rTeam);
        return (rAmount, rTransferAmount);
    }

    function _takeTeam(uint256 tTeam) private {
        uint256 currentRate =  _getRate();
        uint256 rTeam = tTeam.mul(currentRate);

        _rOwned[address(this)] = _rOwned[address(this)].add(rTeam);
    }
    
    function initContract(address payable feeAddress) external onlyOwner() {
        require(!_initialized,"Contract has already been initialized");
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        _uniswapV2Router = uniswapV2Router;

        _feeAddress = feeAddress;
        _isExcludedFromFee[_feeAddress] = true;

        _initialized = true;
    }

    function openTrading() external onlyOwner() {
        require(_initialized, "Contract must be initialized first");
        _tradingOpen = true;
        _launchTime = block.timestamp;
        _initialLimitDuration = _launchTime + (60 minutes);
    }

    function setFeeWallet(address payable feeWalletAddress) external onlyOwner() {
        _isExcludedFromFee[_feeAddress] = false;

        _feeAddress = feeWalletAddress;
        _isExcludedFromFee[_feeAddress] = true;
    }

    function excludeFromFee(address payable ad) external onlyOwner() {
        _isExcludedFromFee[ad] = true;
    }
    
    function includeToFee(address payable ad) external onlyOwner() {
        _isExcludedFromFee[ad] = false;
    }
    
    function setNoTaxMode(bool onoff) external onlyOwner() {
        _noTaxMode = onoff;
    }
    
    function setTeamFee(uint256 fee) external onlyOwner() {
        require(fee <= 10, "Team fee cannot be larger than 10%");
        _teamFee = fee;
    }
    
    function setBots(address[] memory bots_) public onlyOwner() {
        for (uint i = 0; i < bots_.length; i++) {
            if (bots_[i] != _uniswapV2Pair && bots_[i] != address(_uniswapV2Router)) {
                _isBot[bots_[i]] = true;
            }
        }
    }
    
    function delBots(address[] memory bots_) public onlyOwner() {
        for (uint i = 0; i < bots_.length; i++) {
            _isBot[bots_[i]] = false;
        }
    }
    
    function isBot(address ad) public view returns (bool) {
        return _isBot[ad];
    }

    function isExcludedFromFee(address ad) public view returns (bool) {
        return _isExcludedFromFee[ad];
    }
    
    function swapFeesManual() external onlyOwner() {
        uint256 contractBalance = balanceOf(address(this));
        _swapTokensForEth(contractBalance);
    }
    
    function withdrawFees() external {
        uint256 contractETHBalance = address(this).balance;
        _feeAddress.transfer(contractETHBalance);
    }

    receive() external payable {}
}