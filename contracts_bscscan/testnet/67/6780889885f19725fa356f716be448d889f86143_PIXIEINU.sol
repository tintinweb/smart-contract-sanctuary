/**
 *Submitted for verification at BscScan.com on 2021-12-08
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

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
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

contract PIXIEINU is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromReflection;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isBot;

    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 1e12 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    
    string private constant _name = "Pixie Inu";
    string private constant _symbol = "PIXIE";
    
    uint8 private constant _decimals = 9;
    uint256 private _taxFee = 1;
    uint256 private _teamFee = 9;
    uint256 private _previousTaxFee = _taxFee;
    uint256 private _previousteamFee = _teamFee;
    address payable private _feeAddress;
    address payable private _deadAddress = payable(0x000000000000000000000000000000000000dEaD);

    // Uniswap Pair
    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;

    // Burn Related
    address[] private _burnAddressList;
    uint256[] private _burnAmountList;

    bool private initialized = false;
    bool private _noTaxMode = false;
    bool private inSwap = false;
    uint256 private launchTime;
    uint256 private initialLimitDuration;

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
    constructor () {
        _rOwned[_msgSender()] = _rTotal;
        
        _isExcludedFromReflection[address(this)] = true;
        _isExcludedFromReflection[owner()] = true;
        _isExcludedFromReflection[_deadAddress] = true;

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[_deadAddress] = true;

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
        require(_taxFee > 0 && _teamFee > 0);

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
        require(!_isBot[from], "Your address has been marked as a bot, please contact staff to appeal your case.");
        require(initialized, "Contract not yet initialized");
        
        if (block.timestamp == launchTime) _isBot[to] = true;

        if (!_isExcludedFromFee[from] && !_isExcludedFromFee[to] && !_noTaxMode) {
            if (from == uniswapV2Pair && to != address(uniswapV2Router) && initialLimitDuration > block.timestamp) {
                uint walletBalance = balanceOf(address(to));
                require(amount.add(walletBalance) <= _tTotal.mul(2).div(100));
            }

            uint256 contractTokenBalance = balanceOf(address(this));

            if (!inSwap && from != uniswapV2Pair) {
                if (contractTokenBalance > 0) {
                    if (contractTokenBalance > balanceOf(uniswapV2Pair).mul(5).div(100)) {
                        contractTokenBalance = balanceOf(uniswapV2Pair).mul(5).div(100);
                    }
                    
                    swapTokensForEth(contractTokenBalance);
                }

                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
            }
        }

        bool takeFee = true;
        if (_isExcludedFromReflection[from] || _isExcludedFromReflection[to] || _noTaxMode) takeFee = false;
                
        _tokenTransfer(from, to, amount, takeFee);
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
        _feeAddress.transfer(amount);
    }
    
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if (!takeFee)
            removeAllFee();
        _transferStandard(sender, recipient, amount);
        if (!takeFee)
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
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
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
    
    function initContract(address payable feeAddress) external onlyOwner() {
        require(!initialized,"Contract has already been initialized");
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;

        _feeAddress = feeAddress;
        _isExcludedFromReflection[_feeAddress] = true;
        _isExcludedFromFee[_feeAddress] = true;

        initialized = true;
        launchTime = block.timestamp;
        initialLimitDuration = launchTime + (60 minutes);
    }

    function setFeeWallet (address payable feeWalletAddress) external onlyOwner {
        _isExcludedFromReflection[_feeAddress] = false;
        _isExcludedFromFee[_feeAddress] = false;
        _feeAddress = feeWalletAddress;
        _isExcludedFromReflection[_feeAddress] = true;
        _isExcludedFromFee[_feeAddress] = true;
    }

    function excludeFromFee (address payable ad) external onlyOwner {
        _isExcludedFromReflection[ad] = true;
        _isExcludedFromFee[ad] = true;
    }
    
    function includeToFee (address payable ad) external onlyOwner {
        _isExcludedFromReflection[ad] = false;
        _isExcludedFromFee[ad] = false;
    }
    
    function setNoTaxMode(bool onoff) external onlyOwner {
        _noTaxMode = onoff;
    }
    
    function setTeamFee(uint256 team) external onlyOwner {
        require(team <= 9);
        _teamFee = team;
    }
        
    function setTaxFee(uint256 tax) external onlyOwner {
        require(tax <= 1);
        _taxFee = tax;
    }
    
    function setBots(address[] memory bots_) public onlyOwner {
        for (uint i = 0; i < bots_.length; i++) {
            if (bots_[i] != uniswapV2Pair && bots_[i] != address(uniswapV2Router)) {
                _isBot[bots_[i]] = true;
            }
        }
    }
    
    function delBots(address[] memory bots_) public onlyOwner {
        for (uint i = 0; i < bots_.length; i++) {
            _isBot[bots_[i]] = false;
        }
    }
    
    function isBot(address ad) public view returns (bool) {
        return _isBot[ad];
    }

    function isExcludedFromFee(address ad) public view returns(bool) {
        return _isExcludedFromFee[ad];
    }

    function isExcludedFromReflection(address ad) public view returns(bool) {
        return _isExcludedFromReflection[ad];
    }
    
    function unclogFee() external onlyOwner {
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);

        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
    }

    function burn(uint256 _amtToBurn) external {
        transfer(_deadAddress, _amtToBurn);        
        for (uint i = 0; i < _burnAddressList.length; i += 1) {
            address _address = _burnAddressList[i];
            uint256 _previousAmt = _burnAmountList[i];

            require(msg.sender != address(0), "Address invalid");
            
            if (_address == msg.sender) {
                _burnAmountList[i] = _previousAmt.add(_amtToBurn);
                return;
            }
        }

        _burnAddressList.push(msg.sender);
        _burnAmountList.push(_amtToBurn);
    }

    function totalBurned() public view returns (uint256) {
        return balanceOf(_deadAddress);
    }

    function userBurned(address _user) public view returns (uint256) {
        for (uint i = 0; i < _burnAddressList.length; i += 1) {
            address _address = _burnAddressList[i];
            
            if (_address == _user) {
                return _burnAmountList[i];
            }
        }

        return 0;
    }

    function burnedAddressList() public view returns (address[] memory) {
        return _burnAddressList;
    }
    
    function burnedAmountList() public view returns (uint256[] memory) {
        return _burnAmountList;
    }

    receive() external payable {}
}