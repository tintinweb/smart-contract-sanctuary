/**
 *Submitted for verification at Etherscan.io on 2021-11-08
*/

// SPDX-License-Identifier: MIT
//Use 0.8.3


pragma solidity >=0.8.0 <0.9.0;

library SafeMath {

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }


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

    
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function WETH() external pure returns (address);

}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function createPair(address tokenA, address tokenB) external returns (address pair);


}

contract REFLECT is IERC20, Context {
    using SafeMath for uint256;
    //using Address for address;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromReflection;
    address[] private _excludedFromReflection;
   
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 10**12 * 10**9;
    uint256 public _rTotal = (MAX - (MAX % _tTotal));
    uint256 public _tFeeTotal;

    string private _name = 'ZackCoin';
    string private _symbol = 'ZkCn';
    uint8 private _decimals = 9;
    
    uint256 public _reflectionFee = 1; // 1% fee
    uint256 public _burnFee = 1;
    uint256 public _donationFee = 1;
    uint256 public _devFee = 1;
    
    uint256 private _previousReflectionFee = 0;
    uint256 private _previousBurnFee = 0;
    uint256 private _previousDonationFee = 0;
    uint256 private _previousDevFee = 0;
    
    address public _burnAddress = 0x4bB48A8C1D8eFeE68213F0Aa877DdDa3f32B493d;
    address public _tgeAddress;
    address public _holdingAddress = 0xa3ad767D3832109D7ca7e1baF0be95D29dB328E8;
    address public _donationAddress = 0x271eec17Efe6D377ec2026460E42A11D868ed249;
    address public _devAddress = 0xe15F35B04f416489CEB4F735C96EeBC2F07d0850;
    
    address[] private _excludedFromFees;
    address[] private _investorList;
    //address[] private _ffList;
    
    address public _admin;
    bool public _tgeComplete = false;
    
    //bool public _blockFF = true;
    bool public _blockInvestors = true;
    //bool public _tradingPaused = false;
    
    IUniswapV2Router02 public immutable _uniswapRouter;
    address public _ethPair;

    constructor () public {
        _rOwned[_holdingAddress] = _rTotal;
        _admin = _msgSender();
        
        
        _uniswapRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        
        
        emit Transfer(address(0), _holdingAddress, _tTotal);
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

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcludedFromReflection[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override postTGE()  returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override postTGE()  returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override postTGE()  returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual postTGE()  returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual postTGE()  returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function isExcludedFromReflection(address account) public view returns (bool) {
        return _isExcludedFromReflection[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function reflect(uint256 tAmount) public postTGE()  {
        address sender = _msgSender();
        require(!_isExcludedFromReflection[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _rTotal = _rTotal - rAmount;
        _tFeeTotal = _tFeeTotal + (tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function excludeAccountFromReflection(address account) public onlyAdmin() {
        require(!_isExcludedFromReflection[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcludedFromReflection[account] = true;
        _excludedFromReflection.push(account);
    }

    function includeAccount(address account) external onlyAdmin() {
        require(_isExcludedFromReflection[account], "Account is already excluded");
        for (uint256 i = 0; i < _excludedFromReflection.length; i++) {
            if (_excludedFromReflection[i] == account) {
                _excludedFromReflection[i] = _excludedFromReflection[_excludedFromReflection.length - 1];
                _tOwned[account] = 0;
                _isExcludedFromReflection[account] = false;
                _excludedFromReflection.pop();
                break;
            }
        }
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        
        bool recipientExcludedFromFees = isExcludedFromFees(recipient);
        if(recipientExcludedFromFees){
            removeAllFee();
        }
        
        if (_isExcludedFromReflection[sender] && !_isExcludedFromReflection[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcludedFromReflection[sender] && _isExcludedFromReflection[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcludedFromReflection[sender] && !_isExcludedFromReflection[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcludedFromReflection[sender] && _isExcludedFromReflection[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }

        if(recipientExcludedFromFees) {
            restoreAllFee();
        }
        
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 tTransferAmount, uint256 tFeeAmount, uint256 currentRate) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;       
        if(tFeeAmount > 0) {
            _handleFees(tAmount, currentRate);
        }
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 tTransferAmount, uint256 tFeeAmount, uint256 currentRate) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _tOwned[recipient] = _tOwned[recipient] + tTransferAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;           
        if(tFeeAmount > 0) {
            _handleFees(tAmount, currentRate);
        }

        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 tTransferAmount, uint256 tFeeAmount, uint256 currentRate) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender] - tAmount;
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;   
        if(tFeeAmount > 0) {
            _handleFees(tAmount, currentRate);
        }
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 tTransferAmount, uint256 tFeeAmount, uint256 currentRate) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender] - tAmount;
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _tOwned[recipient] = _tOwned[recipient] + tTransferAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
        if(tFeeAmount > 0) {
            _handleFees(tAmount, currentRate);
        }
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function _handleFees(uint256 tAmount, uint256 currentRate) private {
        //Reflection
        uint256 tReflection = tAmount / 100 * _reflectionFee;
        uint256 rReflection = tReflection * currentRate;
        _rTotal = _rTotal - rReflection;
        _tFeeTotal = _tFeeTotal + tReflection;
        
        //Burn
        uint256 tBurn = tAmount / 100 * _burnFee;
        uint256 rBurn = tBurn * currentRate;
        _rOwned[_burnAddress] = _rOwned[_burnAddress] + rBurn;
        _tOwned[_burnAddress] = _tOwned[_burnAddress] + tBurn;
        
        //_donationFee
        uint256 tDonation = tAmount / 100 * _donationFee;
        uint256 rDonation = tDonation * currentRate;
        _rOwned[_donationAddress] = _rOwned[_donationAddress] + rDonation;
        _tOwned[_donationAddress] = _tOwned[_donationAddress] + tDonation;
        
        //devFee
        uint256 tDev = tAmount / 100 * _devFee;
        uint256 rDev = tDev * currentRate;
        _rOwned[_devAddress] = _rOwned[_devAddress] + rDev;
        _tOwned[_devAddress] = _tOwned[_devAddress] + tDev;
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFeeAmount) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 currentRate) = _getRValues(tAmount, tFeeAmount);
        return (rAmount, rTransferAmount, tTransferAmount, tFeeAmount, currentRate);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256) {
        uint256 totalFees = _reflectionFee + _burnFee + _donationFee + _devFee;
        //uint256 tReflection = tAmount.div(100).mul(_reflectionFee);
        //uint256 tBurn = tAmount.div(100).mul(_burnFee);
        uint256 tFees = tAmount / 100 * totalFees;
        uint256 tTransferAmount = tAmount - tFees;
        return (tTransferAmount, tFees);
    }

    function _getRValues(uint256 tAmount, uint256 tFees) private view returns (uint256, uint256, uint256) {
        uint256 currentRate = _getRate();
        uint256 rAmount = tAmount * currentRate;
        //uint256 rReflection = tReflection.mul(currentRate);
        //uint256 rBurn = tBurn.mul(currentRate);
        uint256 rFees = tFees * currentRate;
        uint256 rTransferAmount = rAmount - rFees;
        return (rAmount, rTransferAmount, currentRate);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excludedFromReflection.length; i++) {
            if (_rOwned[_excludedFromReflection[i]] > rSupply || _tOwned[_excludedFromReflection[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply - _rOwned[_excludedFromReflection[i]];
            tSupply = tSupply - _tOwned[_excludedFromReflection[i]];
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
    
    function handleInvestment(address investor, uint256 tokens, bool inInvestorList, bool inFFList) public returns(bool){
        require(_tgeAddress == _msgSender(), "Only the TGE contract can initiate investments");
        require(!_tgeComplete, "TGE is already over");
        removeAllFee();
        //_transfer(_holdingAddress,investor,tokens);
        _transferFromExcluded(_holdingAddress, investor, tokens);
        restoreAllFee();
        if(inInvestorList) {
            _investorList.push(investor);
        }
        
        if(inFFList) {
            _investorList.push(investor);
        }
        
        return true;
    }
    
    
    function isExcludedFromFees(address user) public view returns (bool) {
        for(uint256 i = 0; i < _excludedFromFees.length; i++){
            if(_excludedFromFees[i] == user) {
                return true;
            }
        }
        return false;
    }
    
    function excludeFromFees(address newUser) public onlyAdmin(){
        require(!isExcludedFromFees(newUser), "Account is already excluded from fees.");
        _excludedFromFees.push(newUser);
    }
    
    function removeFromExcludeFromFees(address account) external onlyAdmin() {
        require(isExcludedFromFees(account), "Account isn't excluded");
        for (uint256 i = 0; i < _excludedFromFees.length; i++) {
            if (_excludedFromFees[i] == account) {
                _excludedFromFees[i] = _excludedFromFees[_excludedFromFees.length - 1];
                _excludedFromFees.pop();
                break;
            }
        }
    }
    
    function isInvestor(address accountToCheck) public view returns(bool) {
        for(uint256 i = 0; i < _investorList.length; i ++){
            if(_investorList[i] == accountToCheck){
                return true;
            }
        }
        return false;
    }
    

    
    function unblockInvestors() public onlyAdmin() {
        _blockInvestors = false;
    }
    
    function removeAllFee() private {
        if(_burnFee == 0 && _reflectionFee == 0 && _donationFee ==0) return;
        
        _previousBurnFee = _burnFee;
        _previousReflectionFee = _reflectionFee;
        _previousDonationFee = _donationFee;
        _previousDevFee = _devFee;
        
        _burnFee = 0;
        _reflectionFee = 0;
        _donationFee = 0;
        _devFee = 0;
    }
    
    function restoreAllFee() private {
        _burnFee = _previousBurnFee;
        _reflectionFee = _previousReflectionFee;
        _donationFee = _previousDonationFee;
        _devFee = _previousDevFee;
    }
    

    
    function setTGEAddress(address newTGE) public onlyAdmin() {
        _tgeAddress = newTGE;
    }
    
    modifier onlyAdmin() {
        require(_admin == _msgSender(), "Caller is not the admin");
        _;
    }
    
    modifier postTGE() {
        require(_tgeComplete, "The TGE is not complete");
        _;
    }
    
    
    
    
    
    function completeTGE(uint256 tokenAmount) public payable onlyAdmin() {
        require(!_tgeComplete, "TGE is already over");
        
        removeAllFee();
        
        //Burn anything over 70% of the total supply after TGE
        uint256 totalSupply = tokenFromReflection(_rTotal);
        uint256 targetAmount = totalSupply / 10 * 7;
        
        if(balanceOf(_holdingAddress) > targetAmount) {
            _transferStandard(_holdingAddress, _burnAddress, balanceOf(_holdingAddress) - targetAmount);
        }
        
        _tgeComplete = true;
        
        
        //createPair
        IUniswapV2Factory factory = IUniswapV2Factory(_uniswapRouter.factory());
        _ethPair = factory.createPair(address(this),_uniswapRouter.WETH());
        excludeAccountFromReflection(_ethPair);
        
        //Transfer to this contract to be ready to add liquidity
        _transferStandard(_holdingAddress, address(this), tokenAmount);
        
        _approve(address(this), address(_uniswapRouter), tokenAmount);
        _uniswapRouter.addLiquidityETH{value: msg.value}(address(this),tokenAmount,0,0,_msgSender(),block.timestamp);
        
        
        restoreAllFee();
        
    }
    
    function changeAdmin(address newAdmin) public onlyAdmin() {
        _admin = newAdmin;
    }
    
}