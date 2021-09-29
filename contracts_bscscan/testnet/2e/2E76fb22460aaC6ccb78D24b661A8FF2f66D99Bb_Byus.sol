/**
 *Submitted for verification at BscScan.com on 2021-09-28
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.6.12;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
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
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
       
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

   
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

   
}

contract Byus is Context, IBEP20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 1 * 10**12 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    //charity wallet
    address public charityWallet;
    address public filmWallet;
    //####################
    //switches
    bool public charityenabled = true;
    bool public filmenabled = true;
    bool public burnenabled = true;
    bool public rewardenabled = true;

    uint256 public charitypercent = 1;
    uint256 public filmpercent = 7;
    uint256 public burnpercent = 1;
    uint256 public rewardpercent = 1;

    uint256 public prevcharitypercent = charitypercent;
    uint256 public prevfilmpercent = filmpercent;
    uint256 public prevburnpercent = burnpercent;
    uint256 public prevrewardpercent = rewardpercent;

    mapping (address => bool) private _isExcluded;
    address[] private _excluded;

    mapping (address => bool) private _isExcludedFromFee;


    string private constant _name = 'ByUs Token';
    string private constant _symbol = 'BYUS';
    uint8 private constant _decimals = 9;
    
    event Switchburn(bool enabled, uint256 value);
    event Switchreward(bool enabled, uint256 value);
    event Switchcharity(bool enabled, uint256 value);
    event Switchflim(bool enabled, uint256 value);
    event UpdatedCharitywallet(address wallet);
    event UpdatedFilmwallet(address wallet);
    event excludedFromFee(address wallet);
    event includedInFee(address wallet);
    event excluded(address wallet);
    event included(address wallet);
    event burned(address account,uint256 amount);

     
    constructor (address _charitywallet, address _filmwallet) public {
         _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        charityWallet= _charitywallet;
        filmWallet = _filmwallet;
        _rOwned[_msgSender()] = _rTotal;
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() external pure returns (string memory) {
        return _name;
    }

    function symbol() external pure returns (string memory) {
        return _symbol;
    }

    function decimals() external pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function isExcluded(address account) public view returns (bool) {
        return _isExcluded[account];
    }
    
     function isExcludedfromTax(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }
    
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        emit Transfer(_msgSender(),recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
     /**
   * @dev Burn `amount` tokens and decreasing the total supply.
   */
    function burn(uint256 amount) external returns (bool) {
        _burn(_msgSender(), amount);
        return true;
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
        emit excludedFromFee(account);
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
        emit includedInFee(account);
    }

    function totalFees() external view returns (uint256) {
        return _tFeeTotal;
    }
    
    function reflect(uint256 tAmount) external {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }
    
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "BEP20: burn from the zero address");
        require(balanceOf(account) > amount, "BEP20: burn amount exceeds balance");
         uint256 rbamount=amount.mul(_getRate());
         _tTotal=_tTotal.sub(amount);
        _rTotal=_rTotal.sub(rbamount);
        _rOwned[account]=_rOwned[account].sub(rbamount);
        if(_isExcluded[account])
        {
            _tOwned[account]=_tOwned[account].sub(amount);
        }
        emit burned(account,amount);
    }
    
    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        bool takeFee = true;
        //if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]){
            takeFee = false;
        }
        if(!takeFee){
            removeAllTAx();
        }
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
        
        if(!takeFee)
        {
            restoreAllTax();
        }
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);  
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        uint256 rcharityfee=0;
        if(charityenabled)   
        {
             (rcharityfee) = _getCharityValues(tAmount);
            _rOwned[charityWallet]=_rOwned[charityWallet].add(rcharityfee);

        }

        uint256 rfilmfee=0;
        if(filmenabled)   
        {
            (rfilmfee) = _getFilmValues(tAmount);
            _rOwned[filmWallet]=_rOwned[filmWallet].add(rfilmfee);

        }

        uint256 tBurn=0;
        if(burnenabled)
        {
            (tBurn) = _getBurnValues(tAmount);
            _tTotal= _tTotal.sub(tBurn);
        }

        uint256 sub1 = rFee.sub(rcharityfee);
        _reflectFee( sub1.sub(rfilmfee), tFee);
 
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
         _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);  
        uint256 rcharityfee=0;
        if(charityenabled)   
        {
             (rcharityfee) = _getCharityValues(tAmount);
            _rOwned[charityWallet]=_rOwned[charityWallet].add(rcharityfee);

        }

        uint256 rfilmfee=0;
        if(filmenabled)   
        {
            (rfilmfee) = _getFilmValues(tAmount);
            _rOwned[filmWallet]=_rOwned[filmWallet].add(rfilmfee);

        }

        uint256 tBurn=0;
        if(burnenabled)
        {
            (tBurn) = _getBurnValues(tAmount);
            _tTotal= _tTotal.sub(tBurn);
        }
        
        uint256 sub1 = rFee.sub(rcharityfee);
        _reflectFee( sub1.sub(rfilmfee), tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);  
        uint256 rcharityfee=0;
        if(charityenabled)   
        {
             (rcharityfee) = _getCharityValues(tAmount);
            _rOwned[charityWallet]=_rOwned[charityWallet].add(rcharityfee);

        }

        uint256 rfilmfee=0;
        if(filmenabled)   
        {
            (rfilmfee) = _getFilmValues(tAmount);
            _rOwned[filmWallet]=_rOwned[filmWallet].add(rfilmfee);

        }

        uint256 tBurn=0;
        if(burnenabled)
        {
            (tBurn) = _getBurnValues(tAmount);
            _tTotal= _tTotal.sub(tBurn);
        }
        
        uint256 sub1 = rFee.sub(rcharityfee);
        _reflectFee( sub1.sub(rfilmfee), tFee);
         emit Transfer(sender, recipient, tTransferAmount);
    }



    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);  
        uint256 rcharityfee=0;
        if(charityenabled)   
        {
            (rcharityfee) = _getCharityValues(tAmount);
            _rOwned[charityWallet]=_rOwned[charityWallet].add(rcharityfee);

        }
        uint256 rfilmfee=0;
        if(filmenabled)   
        {
            (rfilmfee) = _getFilmValues(tAmount);
            _rOwned[filmWallet]=_rOwned[filmWallet].add(rfilmfee);

        }
        uint256 tBurn=0;
        if(burnenabled)
        {
            (tBurn) = _getBurnValues(tAmount);
            _tTotal= _tTotal.sub(tBurn);
        }
        //check here //
        uint256 sub1 = rFee.sub(rcharityfee);
        _reflectFee( sub1.sub(rfilmfee), tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function _getCharityValues(uint256 tAmount) private view returns ( uint256) {
        uint256 currentRate = _getRate();
        //charity amount
        uint256 tcharityfee = tAmount.div(100).mul(charitypercent); 
        uint256 rcharityfee= tcharityfee.mul(currentRate);
        return (rcharityfee);
    }

    function _getFilmValues(uint256 tAmount) private view returns ( uint256) {
        uint256 currentRate = _getRate();
        //charity amount
        uint256 tfilmfee = tAmount.div(100).mul(filmpercent); 
        uint256 rfilmfee= tfilmfee.mul(currentRate);
        return (rfilmfee);
    }

    function _getBurnValues(uint256 tAmount) private view returns (uint256) {
        //burn amount
        uint256 tBurn = tAmount.div(100).mul(burnpercent);
        return (tBurn);
    }
    
    function _reflectFee(uint256 rFee, uint256 tFee) private {
        if(rewardenabled)
        {
        _rTotal = _rTotal.sub(rFee);
        }
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee) = _getTValues(tAmount);
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount,tFee,currentRate);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256) {
        uint256 totaltax = _getTotalTax();
        uint256 tFee = tAmount.div(100).mul(totaltax);
        uint256 tTransferAmount = tAmount.sub(tFee);
        return (tTransferAmount, tFee);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee);
        return (rAmount, rTransferAmount, rFee);
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
    
    function switchburnupdate(bool _burnenabled,uint256 value) external onlyOwner {
        require(value <= 100, "TaxFee exceed 100");
        burnenabled = _burnenabled;
        burnpercent = value;
        emit Switchburn(burnenabled,value);
    }

    function switchcharityupdate(bool _charityenabled,uint256 value) external onlyOwner {
        require(value <= 100, "TaxFee exceed 100");
        charityenabled = _charityenabled;
        charitypercent = value;
        emit Switchcharity(charityenabled,value);
    }

    function switchfilmupdate(bool _filmenabled,uint256 value) external onlyOwner {
        require(value <= 100, "TaxFee exceed 100");
        filmenabled = _filmenabled;
        filmpercent = value;
        emit Switchflim(_filmenabled, value) ;
    }

    function switchrewardholderupdate(bool _rewardholderenabled,uint256 value) external onlyOwner {
        require(value <= 100, "TaxFee exceed 100");
        rewardenabled = _rewardholderenabled;
        rewardpercent = value;
        emit Switchreward(_rewardholderenabled,value);
    }
    
    function updateCharityWallet(address _charitywallet) external onlyOwner {
        require(_charitywallet != address(0), "new charity Wallet is the zero address");
        charityWallet = _charitywallet;
        emit UpdatedCharitywallet(_charitywallet);
    }

    function updateFilmWallet(address _filmwallet) external onlyOwner {
        require(_filmwallet != address(0), "new film Wallet is the zero address");
        filmWallet = _filmwallet;
        emit UpdatedFilmwallet(_filmwallet);
    }
  
    function _getTotalTax() private view returns(uint256) {
        uint256 totaltax= rewardpercent;
        if(burnenabled)
        totaltax += burnpercent;
        
        if(charityenabled)
        totaltax += charitypercent;

        if(filmenabled)
        totaltax += filmpercent;
        
        return (totaltax);
    }

    function removeAllTAx() private {
        if(charitypercent==0 && burnpercent==0 && rewardpercent==0&&filmpercent==0) return;
       
       prevburnpercent=burnpercent;
       prevcharitypercent=charitypercent;
       prevrewardpercent=rewardpercent;
       prevfilmpercent = filmpercent;

       burnpercent=0;
       charitypercent=0;
       rewardpercent=0;
       filmpercent = 0;
    }
    
    function restoreAllTax() private {
        burnpercent=prevburnpercent;
        charitypercent=prevcharitypercent;
        rewardpercent=prevrewardpercent;
        filmpercent=prevfilmpercent;
    }


 // Exclusion Module

    function excludeAccount(address account) external onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
        emit excluded(account);
    }


    function includeAccount(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is not excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
        emit included(account);
    }


    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) external view returns(uint256) {
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
    
}