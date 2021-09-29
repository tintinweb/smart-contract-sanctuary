/**
 *Submitted for verification at BscScan.com on 2021-09-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

//- IERC20 Interface
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

//- SafeMath Library
library SafeMath {  
    //- Mode Try
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }    
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }    
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }   
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }
    
    //- Mode Standart
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SM: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SM: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory SafeMathError) internal pure returns (uint256) {
        require(b <= a, SafeMathError);
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SM: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SM: division by zero");
    }
    function div(uint256 a, uint256 b, string memory SafeMathError) internal pure returns (uint256) {
        require(b > 0, SafeMathError);
        uint256 c = a / b;
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SM: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory SafeMathError) internal pure returns (uint256) {
        require(b != 0, SafeMathError);
        return a % b;
    }
}

//- Address Library
library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    } 
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }
    function functionCall(address target, bytes memory data, string memory AddressError) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, AddressError);
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory AddressError) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, AddressError);
    }
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    function functionStaticCall(address target, bytes memory data, string memory AddressError) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, AddressError);
    }
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
    function functionDelegateCall(address target, bytes memory data, string memory AddressError) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, AddressError);
    }
    function _verifyCallResult(bool success, bytes memory returndata, string memory AddressError) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                 assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(AddressError);
            }
        }
    }
}

//- Context Library
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        this; 
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private  _lockTime;    
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
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = time;
        emit OwnershipTransferred(_owner, address(0));
    }
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock.");
        require(block.timestamp > _lockTime , "Contract is locked.");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

library RocoStorageBase {
    using SafeMath for uint256;
    
    bytes32 constant public ROCO_STORAGE = keccak256("com.roco.storage.roco");

    //- Master Vesting
    struct VestingData {
        uint index;
        address walletaddress;
        uint256 totalamount;
        uint256 starttime;
        uint totalperiod;
    }

    //- Detail Vesting
    struct VestingDataDetail {
        uint index;
        uint256 periodtime;
        uint256 periodamount;
        uint period;
        bool confirm;
        address walletaddress;
    }

    struct AppStorage {
        //- Vesting Data
        mapping (address => VestingData) VestingStruct;
        address[] VestingIndex;
        //- Vesting Data Detail
        mapping (address => VestingDataDetail[]) VestingDetailStruct;
    }

    function rocostorage() internal pure returns(AppStorage storage app) {
        bytes32 rocoposition = ROCO_STORAGE;
        assembly {
            app.slot := rocoposition
        }
    }

    //- Vesting Wallet Control
    modifier WalletControl(address _address) {
        if ( rocostorage().VestingStruct[_address].walletaddress != _address ) 
            revert ("Wallet address is not defined!");
        else _;
    }

    //- Create VestingData Control in Code
    modifier CreateVestingDataControl(address _address) {
        require(_address != address(0), "Roco VestingData Error: Address cannot be Zero.");

        for ( uint i = 0; i < rocostorage().VestingIndex.length; i++ ) {
            //- Address Control
            if ( rocostorage().VestingStruct[rocostorage().VestingIndex[i]].walletaddress == _address  ) revert("The wallet address has already been added!");        
        } _;
    }

    //- Vesting Count
    function getVestingCount() internal view returns(uint256) {
        return rocostorage().VestingIndex.length;
    }
    //- Vesting Detail Count
    
    function getVestingCountDetail(address _address) internal view returns(uint256) {
        return rocostorage().VestingDetailStruct[_address].length;
    }

    //- Create New VestingDataMaster / Detail
    function setCreateVestingWallet(address _address, uint256 _totalamount, uint _totalperiod, uint256 _starttime) internal 
        CreateVestingDataControl(_address) {
        
        //- Master Data Insert (Single Record)
        rocostorage().VestingStruct[_address].starttime = _starttime;
        rocostorage().VestingStruct[_address].totalperiod = _totalperiod;
        rocostorage().VestingStruct[_address].totalamount = _totalamount;
        rocostorage().VestingStruct[_address].walletaddress = _address;
        rocostorage().VestingStruct[_address].index = rocostorage().VestingIndex.length;
        rocostorage().VestingIndex.push(_address);
        
        //- Detail Data Insert (Multi Record)
        uint amount = _totalamount.div(_totalperiod);
        uint amountrem = _totalamount;
        uint256 _periodtime = _starttime;
        uint256 _periodamount;
        for ( uint r = 0; r < _totalperiod; r++ ) {            
            amountrem = amountrem.sub(amount);
            if ( r == 0)
                _periodtime = _periodtime; 
                else
                _periodtime = _periodtime + 30 days; 
            if ( r == _totalperiod-1 && amountrem > 0 ) 
                _periodamount = amount.add(amountrem);          
                else 
                _periodamount = amount;
            rocostorage().VestingDetailStruct[_address].push(VestingDataDetail(
                rocostorage().VestingDetailStruct[_address].length,
                _periodtime,
                _periodamount,
                r,
                false,
                _address));
        }
    }
    
    //- Get VestingDataMaster
    function getVestingWallet(address _address) internal view returns(uint, uint256, uint256, uint) {
        require(rocostorage().VestingStruct[_address].walletaddress == _address, "No vesting data found at Wallet address!");
        return(
            rocostorage().VestingStruct[_address].index,
            rocostorage().VestingStruct[_address].totalamount,
            rocostorage().VestingStruct[_address].starttime,
            rocostorage().VestingStruct[_address].totalperiod);
    }
    
    //- Get VestingDataDetail
    function getVestingWalletDetail(address _address) internal view returns(uint256[] memory, uint256[] memory, uint[] memory, bool[] memory) {
        uint indexlen = rocostorage().VestingDetailStruct[_address].length;
        uint256[] memory _periodtime = new uint256[](indexlen); 
        uint256[] memory _periodamount = new uint256[](indexlen);
        uint[] memory _period = new uint[](indexlen); 
        bool[] memory _confirm = new bool[](indexlen); 
        for (uint r = 0; r < indexlen; r++ ) {
            _periodtime[r] = rocostorage().VestingDetailStruct[_address][r].periodtime;
            _periodamount[r] = rocostorage().VestingDetailStruct[_address][r].periodamount;
            _period[r] = rocostorage().VestingDetailStruct[_address][r].period;
            _confirm[r] = rocostorage().VestingDetailStruct[_address][r].confirm;
        }
        return(_periodtime, _periodamount, _period, _confirm);
    }

    //- Set VestingData Claim Check
    function getVestingDataClaimCheck(address _address) internal view WalletControl(_address) returns(uint256, uint){
        uint256 _periodamount = 0;
        uint _claimperiod = 0;
        uint _totalperiod = rocostorage().VestingStruct[_address].totalperiod;
        for ( uint r = 0; r < _totalperiod; r++ ) {
            if ( rocostorage().VestingDetailStruct[_address][r].confirm == false ) {
                if ( block.timestamp > rocostorage().VestingDetailStruct[_address][r].periodtime ) {
                    _periodamount = _periodamount.add(rocostorage().VestingDetailStruct[_address][r].periodamount);
                    _claimperiod++;
                }
            }         
        }
        return (_periodamount, _claimperiod);
    }

    //- Set VestingData Claim
    function setVestingDataClaim(address _address) internal WalletControl(_address) returns (bool, uint256){
        uint256 _periodamount = 0;
        uint _claimperiod = 0;
        uint _totalperiod = rocostorage().VestingStruct[_address].totalperiod;
        for ( uint r = 0; r < _totalperiod; r++ ) {
            if ( rocostorage().VestingDetailStruct[_address][r].confirm == false ) {
                if ( block.timestamp > rocostorage().VestingDetailStruct[_address][r].periodtime ) {
                    _periodamount = _periodamount.add(rocostorage().VestingDetailStruct[_address][r].periodamount);
                    _claimperiod++;
                    rocostorage().VestingDetailStruct[_address][r].confirm = true;
                }
            }         
        }
        return (true, _periodamount);
    }
}

contract R0001 is IERC20, Context, Ownable {
    using SafeMath for uint256;
    using Address  for address;

     //- Contract Event
    event CreateVestingWalletEvent(address WalletAddress, uint256 totalamount, uint256 starttime, uint totalperiod, uint currentperiod);

    mapping (address => uint256) private _rOwned; //- Reflection Own.
    mapping (address => uint256) private _tOwned; //- Total Own.
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcluded;
    address[] private _excluded;

    uint8   private constant _decimals = 8;
    string  private constant _name   = 'R0001';
    string  private constant _symbol = 'R0001';

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 100000000 * 10 ** uint256(_decimals); //- Total Supply
    uint256 private _rTotal = (MAX - (MAX % _tTotal));              //- Reflection Supply

    //- Roco Fee 's
    uint256 private _tRocoFeeTotal;                 //- Total Roco Fee
    uint256 private constant _MaxRocoFee = 100;     //- Maximum Roco Fee Value
    uint256 private _RocoFee = 0;                   //- Current Roco Fee
    uint256 private _RocoFeePrevious  = _RocoFee;   //- Previous Roco Fee

    constructor () {
        _rOwned[_msgSender()] = _rTotal;
        emit Transfer(address(0), _msgSender(), _tTotal);        
    }

    //- Modifier's

    //- Roco maximum fee control
    modifier MaximumFeeControl(uint _Fee) {
        if ( _Fee > _MaxRocoFee ) { 
            revert("Roco Fee won't be greater than 1%"); 
        } else _;
    }
    
    //- Get Name
    function name() public pure returns (string memory) {
        return _name;
    }

    //- Get Symbol
    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    //- Get Decimals
    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    //- Get TotalSupply
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

    function approve(address spender, uint256 amount) public onlyOwner override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ROCO Err: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ROCO Err: decreased allowance below zero"));
        return true;
    }

    function isExcluded(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    //- Total Fee 
    function totalRocoFee() public view returns (uint256) {
        return _tRocoFeeTotal;
    }

    //- Change Roco Fee
    function setRocoFee(uint _newRocoFee) public MaximumFeeControl(_newRocoFee) onlyOwner {
        _RocoFee=_newRocoFee;
    } 

    //- Get Roco Fee Value
    function getRocoFeeValue() public view returns(uint) {
        return _RocoFee;
    }

    function reflect(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tRocoFeeTotal = _tRocoFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply!");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections!");
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

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "Roco Err: approve from the zero address");
        require(spender != address(0), "Roco Err: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "Roco Err: transfer from the zero address");
        require(recipient != address(0), "Roco Err: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
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
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);       
        _CalcFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);           
        _CalcFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
        _CalcFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        
        _CalcFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    //- Roco Calc Fee (reflect)
    function _CalcFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tRocoFeeTotal = _tRocoFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee) = _getTValues(tAmount);
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, currentRate);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256) {
        uint256 tRocoFee = ((tAmount.mul(_RocoFee).div(100)).div(10**2));
        uint256 tTransferAmount = tAmount.sub(tRocoFee);
        return (tTransferAmount, tRocoFee);
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

    // Vesting Data Operations
    
    //- Vesting Count
    function _VestingCount() external onlyOwner virtual view returns(uint256) {
        return RocoStorageBase.getVestingCount();
    }
    
    //- Vesting Count Detail
    function _VestingCountDetail(address _address) external onlyOwner view returns(uint256) {
        return RocoStorageBase.getVestingCountDetail(_address);
    }

    //- Create New VestingDataMaster / Detail 
    function _CreateVestingWallet(address _address, uint256 _totalamount, uint _totalperiod, uint256 _starttime) external onlyOwner {
        RocoStorageBase.setCreateVestingWallet(_address, _totalamount, _totalperiod, _starttime);
        emit CreateVestingWalletEvent(_address, _totalamount, _totalperiod, _starttime, 0);
    }
    
    //- Vesting Data Master
    function _VestingWallet(address _address) external onlyOwner view returns(uint, uint256, uint256, uint) {
        (uint _index, uint256 _totalamount, uint256 _starttime, uint _totalperiod)=RocoStorageBase.getVestingWallet(_address);
        return (_index, _totalamount, _starttime, _totalperiod);
    }
    
    //- Vesting Data Detail
    function _VestingWalletDetail(address _address) external onlyOwner view returns(uint256[] memory, uint256[] memory, uint[] memory, bool[] memory) {
        (uint256[] memory _periodtime, uint256[] memory _periodamount, uint[] memory _period, bool[] memory _confirm)=
        RocoStorageBase.getVestingWalletDetail(_address);
        return (_periodtime, _periodamount, _period, _confirm);
    }
    
    //- VestingData Claim Check
    function _VestingDataClaimCheck(address _address) external onlyOwner view returns(uint256, uint, address) {
        (uint256 _periodamount, uint _claimperiod)=
        RocoStorageBase.getVestingDataClaimCheck(_address);
        return(_periodamount, _claimperiod, address(this));
    }
    
    //- VestingData Claim Check
    function _VestingDataClaim(address _address) external onlyOwner {
        (bool _succes, uint256 _periodamount)=RocoStorageBase.setVestingDataClaim(_address);
        if ( _succes ) {
            transfer(_address, _periodamount);
        }    
    }
}