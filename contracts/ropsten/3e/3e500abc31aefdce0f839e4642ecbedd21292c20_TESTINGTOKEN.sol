/**
 *Submitted for verification at Etherscan.io on 2022-01-25
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

//Use 0.8.3

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

interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function createPair(address tokenA, address tokenB) external returns (address pair);
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



contract TESTINGTOKEN is IERC20, Context {
    using SafeMath for uint256;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromReflection;
    address[] private _excludedFromReflection;
   
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 100_000_000 * 10**9;
    uint256 public rTotal = (MAX - (MAX % _tTotal));
    uint256 public tFeeTotal;

    string private _name = 'TOKEN';
    string private _symbol = 'TOKEN';
    uint8 private _decimals = 9;
    
    uint256 public reflectionFee = 100;
    uint256 public burnFee = 50;
    uint256 public ProjectFunds = 600;
    uint256 public Dev1 = 225;
    uint256 public Dev2 = 225;

    
    uint256 private _previousReflectionFee = 0;
    uint256 private _previousBurnFee = 0;
    uint256 private _previousProjectFunds = 0;
    uint256 private _previousDev1 = 0;
    uint256 private _previousDev2 = 0;
    
    address private burnAddress = address(0);
    address private ProjectFundsDAO;
    address private Dev1Addy;
    address private Dev2Addy;
    
    address[] private _excludedFromFees;

    IUniswapV2Router02 public uniswapRouter;
    address public ethPair;
    
    event newDaoAddress(address indexed newDAO);

    constructor () {
        _rOwned[_msgSender()] = rTotal;

        uniswapRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        IUniswapV2Factory factory = IUniswapV2Factory(uniswapRouter.factory());
        ethPair = factory.createPair(address(this),uniswapRouter.WETH());

        // Initialize Fee Addresses
        ProjectFundsDAO = payable(0xCBAb3C08F8A218daB69Ea8990Fe6d6c2D20984c9);
        Dev1Addy = payable(0xfe80EBfa6Ce52675Ab7489e985C6B6E1775a088E);
        Dev2Addy = payable(0x110d016C30c8e612bACAC749Dbd6B68b7eAB4d98);

        // Burn Address not excluded
        excludeAccountFromReflection(ethPair);
        excludeAccountFromReflection(address(this));
        excludeAccountFromReflection(ProjectFundsDAO);
        excludeAccountFromReflection(Dev1Addy);
        excludeAccountFromReflection(Dev2Addy);

        excludeFromFees(burnAddress);
        excludeFromFees(ProjectFundsDAO);
        excludeFromFees(Dev1Addy);
        excludeFromFees(Dev2Addy);
        
        emit Transfer(address(0), _msgSender(), _tTotal);
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

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override   returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override    returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual  returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual   returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function isExcludedFromReflection(address account) public view returns (bool) {
        return _isExcludedFromReflection[account];
    }

    function totalFees() public view returns (uint256) {
        return tFeeTotal;
    }

    function reflect(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcludedFromReflection[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount, "ERC20: Amount higher than sender balance");
        rTotal = rTotal - rAmount;
        tFeeTotal = tFeeTotal + (tAmount);
    }

    function burn(uint256 burnAmount) external {
        removeAllFee();
        if(isExcludedFromReflection(_msgSender())) {
            _transferBothExcluded(_msgSender(), burnAddress, burnAmount);
        } else {
            _transferToExcluded(_msgSender(), burnAddress, burnAmount);
        }
        restoreAllFee();
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
        require(rAmount <= rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function excludeAccountFromReflection(address account) private {
        require(!_isExcludedFromReflection[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcludedFromReflection[account] = true;
        _excludedFromReflection.push(account);
    }

    function includeAccount(address account) private {
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
        if(recipientExcludedFromFees || (sender == ProjectFundsDAO)){
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
        _rOwned[sender] = _rOwned[sender].sub(rAmount, "ERC20: Amount higher than sender balance");
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;       
        if(tFeeAmount > 0) {
            _handleFees(tAmount, currentRate);
        }
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 tTransferAmount, uint256 tFeeAmount, uint256 currentRate) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount, "ERC20: Amount higher than sender balance");
        _tOwned[recipient] = _tOwned[recipient] + tTransferAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;           
        if(tFeeAmount > 0) {
            _handleFees(tAmount, currentRate);
        }

        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 tTransferAmount, uint256 tFeeAmount, uint256 currentRate) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount, "ERC20: Amount higher than sender balance");
        _rOwned[sender] = _rOwned[sender].sub(rAmount, "ERC20: Amount higher than sender balance");
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;   
        if(tFeeAmount > 0) {
            _handleFees(tAmount, currentRate);
        }
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 tTransferAmount, uint256 tFeeAmount, uint256 currentRate) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount, "ERC20: Amount higher than sender balance");
        _rOwned[sender] = _rOwned[sender].sub(rAmount, "ERC20: Amount higher than sender balance");
        _tOwned[recipient] = _tOwned[recipient] + tTransferAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
        if(tFeeAmount > 0) {
            _handleFees(tAmount, currentRate);
        }
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function _handleFees(uint256 tAmount, uint256 currentRate) private {
        uint256 tReflection = tAmount * reflectionFee / 10000;
        uint256 rReflection = tReflection * currentRate;
        rTotal = rTotal - rReflection;
        tFeeTotal = tFeeTotal + tReflection;
        
        uint256 tBurn = tAmount * burnFee / 10000;
        uint256 rBurn = tBurn * currentRate;
        _rOwned[burnAddress] = _rOwned[burnAddress] + rBurn;
        _tOwned[burnAddress] = _tOwned[burnAddress] + tBurn;
        
        uint256 tProjectFunds = tAmount * ProjectFunds / 10000;
        uint256 rProjectFunds = tProjectFunds * currentRate;
        _rOwned[ProjectFundsDAO] = _rOwned[ProjectFundsDAO] + rProjectFunds;
        _tOwned[ProjectFundsDAO] = _tOwned[ProjectFundsDAO] + tProjectFunds;

        uint256 tDev1 = tAmount * Dev1 / 10000;
        uint256 rDev1 = tDev1 * currentRate;
        _rOwned[Dev1Addy] = _rOwned[Dev1Addy] + rDev1;
        _tOwned[Dev1Addy] = _tOwned[Dev1Addy] + tDev1;

        uint256 tDev2 = tAmount * Dev2 / 10000;
        uint256 rDev2 = tDev2 * currentRate;
        _rOwned[Dev2Addy] = _rOwned[Dev1Addy] + rDev2;
        _tOwned[Dev2Addy] = _tOwned[Dev1Addy] + tDev2;
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFeeAmount) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 currentRate) = _getRValues(tAmount, tFeeAmount);
        return (rAmount, rTransferAmount, tTransferAmount, tFeeAmount, currentRate);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256) {
        uint256 totalFee = reflectionFee + burnFee + ProjectFunds + Dev1 + Dev2;
        uint256 tFees = tAmount * totalFee / 10000;
        uint256 tTransferAmount = tAmount - tFees;
        return (tTransferAmount, tFees);
    }

    function _getRValues(uint256 tAmount, uint256 tFees) private view returns (uint256, uint256, uint256) {
        uint256 currentRate = _getRate();
        uint256 rAmount = tAmount * currentRate;
        uint256 rFees = tFees * currentRate;
        uint256 rTransferAmount = rAmount - rFees;
        return (rAmount, rTransferAmount, currentRate);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excludedFromReflection.length; i++) {
            if (_rOwned[_excludedFromReflection[i]] > rSupply || _tOwned[_excludedFromReflection[i]] > tSupply) return (rTotal, _tTotal);
            rSupply = rSupply - _rOwned[_excludedFromReflection[i]];
            tSupply = tSupply - _tOwned[_excludedFromReflection[i]];
        }
        if (rSupply < rTotal.div(_tTotal)) return (rTotal, _tTotal);
        return (rSupply, tSupply);
    }
    
    
    function isExcludedFromFees(address user) public view returns (bool) {
        for(uint256 i = 0; i < _excludedFromFees.length; i++){
            if(_excludedFromFees[i] == user) {
                return true;
            }
        }
        return false;
    }
    
    function excludeFromFees(address newUser) private {
        require(!isExcludedFromFees(newUser), "Account is already excluded from fees.");
        _excludedFromFees.push(newUser);
    }
    
    function removeFromExcludeFromFees(address account) private {
        require(isExcludedFromFees(account), "Account isn't excluded");
        for (uint256 i = 0; i < _excludedFromFees.length; i++) {
            if (_excludedFromFees[i] == account) {
                _excludedFromFees[i] = _excludedFromFees[_excludedFromFees.length - 1];
                _excludedFromFees.pop();
                break;
            }
        }
    }

    function removeAllFee() private {
        if(burnFee == 0 && reflectionFee == 0 && ProjectFunds ==0) return;
        
        _previousBurnFee = burnFee;
        _previousReflectionFee = reflectionFee;
        _previousProjectFunds = ProjectFunds;
        
        burnFee = 0;
        reflectionFee = 0;
        ProjectFunds = 0;
    }
    
    function restoreAllFee() private {
        burnFee = _previousBurnFee;
        reflectionFee = _previousReflectionFee;
        ProjectFunds = _previousProjectFunds;
    }

    function changeProjectFundsAddress(address newAddress) external {
        require(msg.sender == ProjectFundsDAO , "Only current ProjectFundsDAO can change the address");
        excludeAccountFromReflection(newAddress);
        excludeFromFees(newAddress);
        removeAllFee();
        _transferBothExcluded(ProjectFundsDAO, newAddress, balanceOf(ProjectFundsDAO));
        restoreAllFee();

        includeAccount(ProjectFundsDAO);
        removeFromExcludeFromFees(ProjectFundsDAO);


        ProjectFundsDAO = newAddress;
        emit newDaoAddress(newAddress);
    }

}