/**
 *Submitted for verification at BscScan.com on 2021-09-24
*/

/*
 -----------------------Granville's Coin.sol --------------------------
                
                name     : Granville Coin
                symbol   : G
                decimals : 2
                supply   : 1 000 000 000
------------------------------------------------------------
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


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

library Address {

    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked until some time passes");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

contract Granville  is Context, IERC20, Ownable {
    using Address for address;

    address private constant _burnAddress = 0x000000000000000000000000000000000000dEaD; // address burn
                                            
    //MAPINGS
    //mapping balance and reflected balance of address
    mapping (address => uint256) private _balances;
    mapping (address => uint256) private _reflectBalances;

    //allowances of address to address with amount about this token
    mapping (address => mapping (address => uint256)) private _allowances;

    //mapping who is excluded from what (Fees or recieve Rewards)
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcludedFromReward;
    address[] private _excludedFromReward;

    //PROJECT SETTINGS
    //Name Symbol Decimals
    string private constant _name = 'Granville Coin '; // to be determined
    string private constant _symbol = 'G'; // to be determined
    uint8 private constant _decimals = 2;

    //Supply and Reflected Supply and other options
    uint256 private constant _decimalFactor = 10**uint256(_decimals);
    uint256 private _tokenTotal = 1000000000 * _decimalFactor ; // 19300000000000 per bnb!!
    uint256 private constant MAX = ~uint256(0);
    uint256 private _reflectedTotal = (MAX - (MAX % _tokenTotal));
    uint256 private constant _granularity = 100; // this allows 0.5 percentages for example
    uint256 private _totalTokenFee = 0;

    uint256 public burnFee    = 100 ; // 1%
    uint256 public reflectFee = 200 ; // 2%
    uint256 private _totalBurn;
    bool private _disableFees = false;

    constructor () {
 
        _reflectBalances[_msgSender()] = _reflectedTotal; //
        
        _isExcludedFromFee[owner()] = true;
        
        _isExcludedFromReward[_burnAddress] = true;
        
        
        emit Transfer(address(0), _msgSender(), _tokenTotal);
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint256) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _tokenTotal;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        if (_isExcludedFromReward[account]) return _balances[account];
        return tokenFromReflection(_reflectBalances[account]);
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        return true;
    }

    
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "transfer from the zero address");
        require(recipient != address(0), "transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");


        (burnFee, reflectFee) = getTransferFee(sender, recipient);
        uint256 currentRate = _getRate();
        uint256 burnToken = ((amount*burnFee)/_granularity)/100;
        uint256 reflectToken = ((amount*reflectFee)/_granularity)/100;

        _reflectBalances[sender] -= amount*currentRate;
        _reflectBalances[recipient] += ((amount-burnToken-reflectToken)*currentRate);
        _reflectBalances[_burnAddress]+=burnToken*currentRate;
        if(_isExcludedFromReward[sender]) _balances[sender] -= amount ;
        if(_isExcludedFromReward[recipient]) _balances[recipient] += (amount-burnToken-reflectToken);
        if(_isExcludedFromReward[_burnAddress]) _balances[_burnAddress] += burnToken;
        _reflectedTotal -= reflectToken*currentRate;
        emit Transfer(sender, recipient, amount-burnToken-reflectToken);
        if (burnToken!=uint256(0)) emit Transfer(sender, _burnAddress, burnToken);
    }
    
    
    function setFee(uint256 _burnFee, uint256 _reflectFee)public onlyOwner{
        burnFee=_burnFee;
        reflectFee=_reflectFee;
    }
    
    function getTransferFee(address sender, address recipient) private view returns (uint256, uint256){
        if (_disableFees || _isExcludedFromFee[sender] || _isExcludedFromFee[recipient] ){
            return (uint256(0),uint256(0));
        }
        
        uint256 burnt = balanceOf(_burnAddress);
        
        return (burnFee,reflectFee);
    }


    function tokenFromReflection(uint256 reflectedAmount) public view returns(uint256) {
        require(reflectedAmount <= _reflectedTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return reflectedAmount / currentRate ;
        //return reflectedAmount.div(currentRate);
    }

    function _getRate() private view returns(uint256) {
        (uint256 reflectedSupply, uint256 tokenSupply) = _getCurrentSupply();
        return reflectedSupply / tokenSupply ;
    }

    function _getSupply() public view returns(uint256){
        return _tokenTotal-balanceOf(_burnAddress);
    }


    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 reflectedSupply = _reflectedTotal;
        uint256 tokenSupply = _tokenTotal;      
        for (uint256 i = 0; i < _excludedFromReward.length; i++) {
            if (_reflectBalances[_excludedFromReward[i]] > reflectedSupply || _balances[_excludedFromReward[i]] > tokenSupply) return (_reflectedTotal, _tokenTotal);
            reflectedSupply -= _reflectBalances[_excludedFromReward[i]];
            tokenSupply -= _balances[_excludedFromReward[i]];
        }
        if (reflectedSupply < (_reflectedTotal /_tokenTotal) ) return (_reflectedTotal, _tokenTotal);
        return (reflectedSupply, tokenSupply);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "approve from the zero address");
        require(spender != address(0), "approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }


    function excludeFromFees(address account) public onlyOwner{
        _isExcludedFromFee[account] = true;
    }

    
    function includeInFees(address account) public onlyOwner{
        _isExcludedFromFee[account] = false;
    }

    function excludeFromReward(address account) public onlyOwner {
        require(!_isExcludedFromReward[account], "Account is already excluded");
        if(_reflectBalances[account] > 0) {
            _balances[account] = tokenFromReflection(_reflectBalances[account]);
        }
        _isExcludedFromReward[account] = true;
        _excludedFromReward.push(account);
    }

    function includeInReward(address account) external onlyOwner {
        require(_isExcludedFromReward[account], "Account is not excluded");
        for (uint256 i = 0; i < _excludedFromReward.length; i++) {
            if (_excludedFromReward[i] == account) {
                _excludedFromReward[i] = _excludedFromReward[_excludedFromReward.length - 1];
                _balances[account] = 0;
                _isExcludedFromReward[account] = false;
                _excludedFromReward.pop();
                break;
            }
        }
    }

    function setFeesState(bool _enabled) public onlyOwner {
        _disableFees = _enabled;
    }

    function getFeeInfo() public view returns(uint256,uint256){
        return (getTransferFee(_burnAddress, _burnAddress));
    }

    function isExcludedFromFee(address account) public view returns(bool){
        return _isExcludedFromFee[account];
    }

    function isExcludedFromReward(address account) public view returns(bool){
        return _isExcludedFromReward[account];
    }
}