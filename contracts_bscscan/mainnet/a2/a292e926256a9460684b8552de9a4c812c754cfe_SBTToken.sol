/**
 *Submitted for verification at BscScan.com on 2021-07-13
*/

/** Small Biz Trasaction Token Main Contract. Implements rewards, burning and contribution to small business startup fund. 
*/

/**
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;


abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        return msg.data;
    }
}

interface IBEP20 {
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

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

library Address {

    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }


    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}


contract Ownable is Context {
    address public _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);



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


    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract SBTToken is Context, IBEP20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcluded;
    mapping (address => bool) private _isStartup;
    address[] private _excluded;
    
    string  private _NAME;
    string  private _SYMBOL;
    uint256   private _DECIMALS;
	address public FeeAddress;
   
    uint256 private _MAX = ~uint256(0);
    uint256 private _DECIMALFACTOR;
    uint256 private _GRANULARITY = 100;
    
    uint256 private _tTotal;
    uint256 private _rTotal;
    
    uint256 private _tFeeTotal;
    uint256 private _tBurnTotal;
    uint256 private _tStartupTotal;
    
    uint256 public     _TAX_FEE;
    uint256 public     _TAXHIGH_FEE;

    uint256 public    _BURN_FEE;
    uint256 public _STARTUP_FEE;

    uint256 private ORIG_TAX_FEE;
    uint256 public     ORIG_TAXHIGH_FEE;

    uint256 private ORIG_BURN_FEE;
    uint256 private ORIG_STARTUP_FEE;

    constructor (string memory _name, string memory _symbol, uint256 _decimals, uint256 _supply, uint256 _txFee, uint256 _txhighFee, uint256 _burnFee,uint256 _startupFee,address _FeeAddress,address tokenOwner) {
		_NAME = _name;
		_SYMBOL = _symbol;
		_DECIMALS = _decimals;
		_DECIMALFACTOR = 10 ** uint256(_DECIMALS);
		_tTotal =_supply * _DECIMALFACTOR;
		_rTotal = (_MAX - (_MAX % _tTotal));
		_TAX_FEE = _txFee* 100; 
        _TAXHIGH_FEE = _txhighFee * 100; 

        _BURN_FEE = _burnFee * 100;
		_STARTUP_FEE = _startupFee* 100;
		
		ORIG_TAX_FEE = _TAX_FEE;
		ORIG_TAXHIGH_FEE = _TAXHIGH_FEE;

		ORIG_BURN_FEE = _BURN_FEE;
		ORIG_STARTUP_FEE = _STARTUP_FEE;
		_isStartup[_FeeAddress] = true;
		FeeAddress = _FeeAddress;
		_owner = tokenOwner;
        _rOwned[tokenOwner] = _rTotal;
		
        emit Transfer(address(0),tokenOwner, _tTotal);
    }

    function name() public view returns (string memory) {
        return _NAME;
    }

    function symbol() public view returns (string memory) {
        return _SYMBOL;
    }

    function decimals() public view returns (uint256) {
        return _DECIMALS;
    }

    function totalSupply() public view override returns (uint256) {
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "TOKEN20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "TOKEN20: decreased allowance below zero"));
        return true;
    }

    function isExcluded(address account) public view returns (bool) {
        return _isExcluded[account];
    }
    
    function isStartup(address account) public view returns (bool) {
        return _isStartup[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }
    
    function totalBurn() public view returns (uint256) {
        return _tBurnTotal;
    }
    
    function totalStartup() public view returns (uint256) {
        return _tStartupTotal;
    }

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,,) = _getValues(tAmount);
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
        require(_isExcluded[account], "Account is already excluded");
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

    function setAsStartupAccount(address account) external onlyOwner() {
        require(!_isStartup[account], "Account is already startup account");
        _isStartup[account] = true;
		FeeAddress = account;
    }

	function burn(uint256 _value) public{
		_burn(msg.sender, _value);
	}
	
	function updateFee(uint256 _txFee, uint256 _txhighFee, uint256 _burnFee,uint256 _startupFee) onlyOwner() public{
        _TAX_FEE = _txFee* 100; 
        _TAXHIGH_FEE = _txhighFee* 100; 

        _BURN_FEE = _burnFee * 100;
		_STARTUP_FEE = _startupFee* 100;
		ORIG_TAX_FEE = _TAX_FEE;
	    ORIG_TAXHIGH_FEE = _TAXHIGH_FEE;

		
		
		ORIG_BURN_FEE = _BURN_FEE;
		ORIG_STARTUP_FEE = _STARTUP_FEE;
	}
	

	function _burn(address _who, uint256 _value) internal {
		require(_value <= _rOwned[_who]);
		_rOwned[_who] = _rOwned[_who].sub(_value);
		_tTotal = _tTotal.sub(_value);
		emit Transfer(_who, address(0), _value);
	}


    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "TOKEN20: approve from the zero address");
        require(spender != address(0), "TOKEN20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "TOKEN20: transfer from the zero address");
        require(recipient != address(0), "TOKEN20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        // Remove fees for transfers to and from startup account or to excluded account
        bool takeFee = true;
        if (_isStartup[sender] || _isStartup[recipient] || _isExcluded[recipient]) {
            takeFee = false;
        }

        if (!takeFee) removeAllFee();
        
        
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

        if (!takeFee) restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tBurn, uint256 tStartup) = _getValues(tAmount);
        uint256 rBurn =  tBurn.mul(currentRate);
        uint256 rStartup = tStartup.mul(currentRate);     
        _standardTransferContent(sender, recipient, rAmount, rTransferAmount);
        _sendToStartup(tStartup, sender);
        _reflectFee(rFee, rBurn, rStartup, tFee, tBurn, tStartup);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function _standardTransferContent(address sender, address recipient, uint256 rAmount, uint256 rTransferAmount) private {
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
    }
    
    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tBurn, uint256 tStartup) = _getValues(tAmount);
        uint256 rBurn =  tBurn.mul(currentRate);
        uint256 rStartup = tStartup.mul(currentRate);
        _excludedFromTransferContent(sender, recipient, tTransferAmount, rAmount, rTransferAmount);        
        _sendToStartup(tStartup, sender);
        _reflectFee(rFee, rBurn, rStartup, tFee, tBurn, tStartup);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function _excludedFromTransferContent(address sender, address recipient, uint256 tTransferAmount, uint256 rAmount, uint256 rTransferAmount) private {
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);    
    }
    

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tBurn, uint256 tStartup) = _getValues(tAmount);
        uint256 rBurn =  tBurn.mul(currentRate);
        uint256 rStartup = tStartup.mul(currentRate);
        _excludedToTransferContent(sender, recipient, tAmount, rAmount, rTransferAmount);
        _sendToStartup(tStartup, sender);
        _reflectFee(rFee, rBurn, rStartup, tFee, tBurn, tStartup);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function _excludedToTransferContent(address sender, address recipient, uint256 tAmount, uint256 rAmount, uint256 rTransferAmount) private {
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);  
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tBurn, uint256 tStartup) = _getValues(tAmount);
        uint256 rBurn =  tBurn.mul(currentRate);
        uint256 rStartup = tStartup.mul(currentRate);    
        _bothTransferContent(sender, recipient, tAmount, rAmount, tTransferAmount, rTransferAmount);  
        _sendToStartup(tStartup, sender);
        _reflectFee(rFee, rBurn, rStartup, tFee, tBurn, tStartup);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function _bothTransferContent(address sender, address recipient, uint256 tAmount, uint256 rAmount, uint256 tTransferAmount, uint256 rTransferAmount) private {
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);  
    }

    function _reflectFee(uint256 rFee, uint256 rBurn, uint256 rStartup, uint256 tFee, uint256 tBurn, uint256 tStartup) private {
        _rTotal = _rTotal.sub(rFee).sub(rBurn).sub(rStartup);
        _tFeeTotal = _tFeeTotal.add(tFee);
        _tBurnTotal = _tBurnTotal.add(tBurn);
        _tStartupTotal = _tStartupTotal.add(tStartup);
        _tTotal = _tTotal.sub(tBurn);
		emit Transfer(address(this), address(0), tBurn);
    }
    

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tFee, uint256 tBurn, uint256 tStartup) = _getTBasics(tAmount, _TAX_FEE, _BURN_FEE, _STARTUP_FEE);
        uint256 tTransferAmount = getTTransferAmount(tAmount, tFee, tBurn, tStartup);
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rFee) = _getRBasics(tAmount, tFee, currentRate);
        uint256 rTransferAmount = _getRTransferAmount(rAmount, rFee, tBurn, tStartup, currentRate);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tBurn, tStartup);
    }
    
    function _getTBasics(uint256 tAmount, uint256 taxFee, uint256 burnFee, uint256 startupFee) private view returns (uint256, uint256, uint256) {
        

//implements high tax for higher transactions based on % of holding


        uint256 tFee = ((tAmount.mul(taxFee)).div(_GRANULARITY)).div(100);

        if(balanceOf(msg.sender)/tAmount>=10)
        tFee = tFee.mul(1);
        else if(balanceOf(msg.sender)/tAmount>=5)
        tFee = tFee.mul(2);
        else if(balanceOf(msg.sender)/tAmount>=3)
        tFee = tFee.mul(3);
        else if(balanceOf(msg.sender)/tAmount>=2)
        tFee = tFee.mul(4);
        else
        tFee = tFee.mul(5);
        


        
        uint256 tBurn = ((tAmount.mul(burnFee)).div(_GRANULARITY)).div(100);
        uint256 tStartup = ((tAmount.mul(startupFee)).div(_GRANULARITY)).div(100);
        return (tFee, tBurn, tStartup);
    }
    
    function getTTransferAmount(uint256 tAmount, uint256 tFee, uint256 tBurn, uint256 tStartup) private pure returns (uint256) {
        return tAmount.sub(tFee).sub(tBurn).sub(tStartup);
    }
    
    function _getRBasics(uint256 tAmount, uint256 tFee, uint256 currentRate) private pure returns (uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        return (rAmount, rFee);
    }
    
    function _getRTransferAmount(uint256 rAmount, uint256 rFee, uint256 tBurn, uint256 tStartup, uint256 currentRate) private pure returns (uint256) {
        uint256 rBurn = tBurn.mul(currentRate);
        uint256 rStartup = tStartup.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rBurn).sub(rStartup);
        return rTransferAmount;
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

    function _sendToStartup(uint256 tStartup, address sender) private {
        uint256 currentRate = _getRate();
        uint256 rStartup = tStartup.mul(currentRate);
        _rOwned[FeeAddress] = _rOwned[FeeAddress].add(rStartup);
        _tOwned[FeeAddress] = _tOwned[FeeAddress].add(tStartup);
        emit Transfer(sender, FeeAddress, tStartup);
    }

    function removeAllFee() private {
        if(_TAX_FEE == 0 && _TAXHIGH_FEE==0 && _BURN_FEE == 0 && _STARTUP_FEE == 0) return;
        
        ORIG_TAX_FEE = _TAX_FEE;
        ORIG_TAXHIGH_FEE = _TAXHIGH_FEE;
        
        ORIG_BURN_FEE = _BURN_FEE;
        ORIG_STARTUP_FEE = _STARTUP_FEE;
        
        _TAX_FEE = 0;
        _TAXHIGH_FEE = 0;
    
        
        _BURN_FEE = 0;
        _STARTUP_FEE = 0;
    }
    
    function restoreAllFee() private {
        _TAX_FEE = ORIG_TAX_FEE;
        _TAXHIGH_FEE = ORIG_TAXHIGH_FEE;


        _BURN_FEE = ORIG_BURN_FEE;
        _STARTUP_FEE = ORIG_STARTUP_FEE;
        
    }
    
    function _getTaxFee() private view returns(uint256) {
        return _TAX_FEE;
    }


        function _getTaxhighFee() private view returns(uint256) {
        return _TAXHIGH_FEE;
    }
    

}