//SourceUnit: tts.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

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

contract Ownable {
    address                  public  _owner;
    mapping(address => bool) private _roles;

    constructor () public {
        _owner = _msgSender();
        _roles[_msgSender()] = true;
    }
    
    function owner() public view returns (address) {
        return _owner;
    }
    
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    
    modifier onlyOwner() {
        require(_roles[_msgSender()]);
        _;
    }

    function transferOwner(address nowner) public onlyOwner {
        _roles[_owner] = false;
        _roles[nowner] = true;
        _owner = nowner;
    }

    function setOwnerState(address addr, bool state) public onlyOwner {
        _roles[addr] = state;
    }
}

contract Token is IERC20, Ownable {
    using SafeMath for uint256;
    
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 100000000000 * 10**18;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));

    string private _name = 'The third space';
    string private _symbol = 'TTS';
    uint8 private _decimals = 18;
    
    address private _burnPool = 0x0000000000000000000000000000000000000000;
    
    address public fundAddress;
    address public markAddress;
    address public initAddress;
    
    mapping(address => bool) private _isExcludedFromFee;
    
    uint256 public _taxFee = 5;
    uint256 private _previousTaxFee = _taxFee;
    uint256 public _burnFee = 8;
    uint256 private _previousBurnFee = _burnFee;
    uint256 public _fundFee = 6;
    uint256 private _previousFundFee = _fundFee;

    constructor () public {
        fundAddress = address(0x4165c8ca1debe490d79723183977c855f15eb5903d);
        markAddress = address(0x41b35131c141c622066a9c221afa765fe0fa5a481a);
        initAddress = address(0x41d4796f541bccd9c01c8a85be93bf769bc7dbc17f);
        
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[initAddress] = true;
        
        _rOwned[initAddress] = _rTotal;
        emit Transfer(address(0), initAddress, _tTotal);
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

    function totalSupply() public view override returns (uint256) {
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

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
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

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0));
        require(amount > 0);
        
        if(_isExcludedFromFee[sender]) {
            removeAllFee();
        }
        
        _transferStandard(sender, recipient, amount);
     
        if(_isExcludedFromFee[sender]) {
            restoreAllFee();
        }
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        uint256 currentRate =  _getRate();
        if (recipient == address(0)) {
            _rOwned[sender] = _rOwned[sender].sub(tAmount.mul(currentRate));
            emit Transfer(sender, recipient, tAmount);
            
            _rTotal = _rTotal.sub(tAmount.mul(currentRate));
            _tTotal = _tTotal.sub(tAmount);
            return;
        }
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tBurn, uint256 tFund) = _getValues(tAmount);
        
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);  
        _rOwned[fundAddress] = _rOwned[fundAddress].add(tFund.div(2).mul(currentRate));
        _rOwned[markAddress] = _rOwned[markAddress].add(tFund.div(2).mul(currentRate));
        
        _rTotal = _rTotal.sub(rFee).sub(tBurn.mul(currentRate));
        _tTotal = _tTotal.sub(tBurn);
       
        emit Transfer(sender, recipient, tTransferAmount);
        emit Transfer(sender, _burnPool, tBurn);
        emit Transfer(sender, fundAddress, tFund.div(2));
        emit Transfer(sender, markAddress, tFund.div(2));
    }

    function removeAllFee() private {
        if(_taxFee == 0 && _burnFee == 0 && _fundFee == 0) return;
        _previousTaxFee = _taxFee;
        _previousBurnFee = _burnFee;
        _previousFundFee = _fundFee;
        _taxFee = 0;
        _burnFee = 0;
        _fundFee = 0;
    }
    
    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _burnFee = _previousBurnFee;
        _fundFee = _previousFundFee;
    }
    
    function setExcludedFromFee(address account, bool state) public onlyOwner {
        _isExcludedFromFee[account] = state;
    }

    function withEth(address addr, uint256 amount) public onlyOwner {
        payable(addr).transfer(amount);
    }

    function withErc20(address con, address addr, uint256 amount) public onlyOwner {
        IERC20(con).transfer(addr, amount);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tBurn, uint256 tFund) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tBurn, tFund);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tBurn,  tFund);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256,uint256, uint256) {
        uint256 tFee = tAmount.mul(_taxFee).div(100);
        uint256 tBurn = tAmount.mul(_burnFee).div(100);
        uint256 tFund = tAmount.mul(_fundFee).div(100);
        
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tBurn).sub(tFund);
        return (tTransferAmount, tFee, tBurn, tFund);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tBurn, uint256 tFund) private view returns (uint256, uint256, uint256) {
        uint256 currentRate =  _getRate();
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rBurn = tBurn.mul(currentRate);
        uint256 rFund = tFund.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rBurn).sub(rFund);
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
}