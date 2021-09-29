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

library RocoVestingStorageBase {
    using SafeMath for uint256;
    
    bytes32 constant public ROCOLOCK_STORAGE = keccak256("com.roco.storage.lock");

    //- Master
    struct LockContract {
        uint index;
        IERC20 token;
        uint256 totalamount;
        uint256 starttime;
        uint totalperiod;
        address owner;
    }

    //- Detail
    struct LockContractDetail {
        uint index;
        uint256 periodtime;
        uint256 periodamount;
        uint period;
        bool confirm;
    }

    struct AppStorage {
        //- Lock
        mapping (address => LockContract) LockContractStruct;
        address[] LockContractIndex;
        //- Lock Detail
        mapping (address => LockContractDetail[]) LockContractDetailStruct;
    }

    function rocostorage() internal pure returns(AppStorage storage app) {
        bytes32 rocoposition = ROCOLOCK_STORAGE;
        assembly {
            app.slot := rocoposition
        }
    }

    //- Contract Control
    modifier ContractControl(address _address) {
        if ( rocostorage().LockContractStruct[_address].owner != _address ) 
            revert ("Conract address is not defined!");
        else _;
    }

    //- Create VestingData Control in Code
    modifier CreateLockContractControl(address _address) {
        require(_address != address(0), "Roco Lock Contract Error: Address cannot be Zero.");

        for ( uint i = 0; i < rocostorage().LockContractIndex.length; i++ ) {
            //- Address Control
            if ( rocostorage().LockContractStruct[rocostorage().LockContractIndex[i]].owner == _address  ) revert("The Owner address has already been added!");
        } _;
    }

    //- Contract Count
    function getLockContractCount() internal view returns(uint256) {
        return rocostorage().LockContractIndex.length;
    }
    //- Conract Detail Count
    function getLockContractCountDetail(address _address) internal view returns(uint256) {
        return rocostorage().LockContractDetailStruct[_address].length;
    }

    //- Create New VestingDataMaster / Detail
    function setCreateLockContract(IERC20 _token, uint256 _totalamount, uint _totalperiod, uint256 _starttime, address _owner) internal 
        CreateLockContractControl(_owner) {
        
        //- Master Data Insert (Single Record)
        rocostorage().LockContractStruct[_owner].starttime = _starttime;
        rocostorage().LockContractStruct[_owner].totalperiod = _totalperiod;
        rocostorage().LockContractStruct[_owner].totalamount = _totalamount;
        rocostorage().LockContractStruct[_owner].token = _token;
        rocostorage().LockContractStruct[_owner].owner = _owner;
        rocostorage().LockContractStruct[_owner].index = rocostorage().LockContractIndex.length;
        rocostorage().LockContractIndex.push(_owner);
        
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
            rocostorage().LockContractDetailStruct[_owner].push(LockContractDetail(
                rocostorage().LockContractDetailStruct[_owner].length,
                _periodtime,
                _periodamount,
                r,
                false));
        }
    }
    
    //- Get Data Master
    function getLockContract(address _address) internal view ContractControl(_address) returns(address, uint256, uint256, uint) {
        require(rocostorage().LockContractStruct[_address].owner == _address, "No Lock Token found at Contract address!");
        return(
            rocostorage().LockContractStruct[_address].owner,
            rocostorage().LockContractStruct[_address].starttime,
            rocostorage().LockContractStruct[_address].totalamount,
            rocostorage().LockContractStruct[_address].totalperiod
            );
    }
    
    //- Get Data Detail
    function getLockContractDetail(address _address) internal view ContractControl(_address) returns(uint256[] memory, uint256[] memory, uint[] memory, bool[] memory) {
        uint indexlen = rocostorage().LockContractDetailStruct[_address].length;
        uint256[] memory _periodtime = new uint256[](indexlen); 
        uint256[] memory _periodamount = new uint256[](indexlen);
        uint[] memory _period = new uint[](indexlen); 
        bool[] memory _confirm = new bool[](indexlen); 
        for (uint r = 0; r < indexlen; r++ ) {
            _periodtime[r] = rocostorage().LockContractDetailStruct[_address][r].periodtime;
            _periodamount[r] = rocostorage().LockContractDetailStruct[_address][r].periodamount;
            _period[r] = rocostorage().LockContractDetailStruct[_address][r].period;
            _confirm[r] = rocostorage().LockContractDetailStruct[_address][r].confirm;
        }
        return(_periodtime, _periodamount, _period, _confirm);
    }

    //- Set Token Claim Check
    function getLockContractWithdrawCheck(address _address) internal view ContractControl(_address) returns(uint256, uint){
        uint256 _periodamount = 0;
        uint _claimperiod = 0;
        uint _totalperiod = rocostorage().LockContractStruct[_address].totalperiod;
        for ( uint r = 0; r < _totalperiod; r++ ) {
            if ( rocostorage().LockContractDetailStruct[_address][r].confirm == false ) {
                if ( block.timestamp > rocostorage().LockContractDetailStruct[_address][r].periodtime ) {
                    _periodamount = _periodamount.add(rocostorage().LockContractDetailStruct[_address][r].periodamount);
                    _claimperiod++;
                }
            }         
        }
        return (_periodamount, _claimperiod);
    }

    //- Set Token Claim
    function setLockContractWithdraw(address _address) internal ContractControl(_address) returns (bool, uint256, address){
        uint256 _periodamount = 0;
        uint _claimperiod = 0;
        uint _totalperiod = rocostorage().LockContractStruct[_address].totalperiod;
        address _owneraddress = rocostorage().LockContractStruct[_address].owner;
        
        //- Calculate
        for ( uint r = 0; r < _totalperiod; r++ ) {
            if ( rocostorage().LockContractDetailStruct[_address][r].confirm == false ) {
                if ( block.timestamp > rocostorage().LockContractDetailStruct[_address][r].periodtime ) {
                    _periodamount = _periodamount.add(rocostorage().LockContractDetailStruct[_address][r].periodamount);
                    _claimperiod++;
                    rocostorage().LockContractDetailStruct[_address][r].confirm = true;
                }
            }         
        }
        return (true, _periodamount, _owneraddress);
    }
    
    //- Set Token Claim
    function getLockContractWithdraw(address _address) internal view ContractControl(_address) returns (bool, uint256, address){
        uint256 _periodamount = 0;
        uint _claimperiod = 0;
        uint _totalperiod = rocostorage().LockContractStruct[_address].totalperiod;
        address _owneraddress = rocostorage().LockContractStruct[_address].owner;
        
        //- Calculate
        for ( uint r = 0; r < _totalperiod; r++ ) {
            if ( rocostorage().LockContractDetailStruct[_address][r].confirm == false ) {
                if ( block.timestamp > rocostorage().LockContractDetailStruct[_address][r].periodtime ) {
                    _periodamount = _periodamount.add(rocostorage().LockContractDetailStruct[_address][r].periodamount);
                    _claimperiod++;
                }
            }         
        }
        return (true, (_periodamount), _owneraddress);
    }

}

contract R0001VESTINGLOCK is Context, Ownable {
    using SafeMath for uint256;
    using Address  for address;

    IERC20 immutable public ERC20Roco;
    mapping (address => uint256) public balances;
    string public name;
    
    
    constructor(address _basecontract, string memory _name) {
        require(_basecontract != address(0), "Lock Contract Constructor Error: Address cannot be Zero.");    
        ERC20Roco = IERC20(_basecontract);
        name = _name;
    }
    
    // Lock Contract Operations
    function _LockTokens(uint256 _amount) public onlyOwner {
        balances[msg.sender]+= _amount;
        ERC20Roco.transferFrom(msg.sender, address(this), _amount); 
    }
    
    function getBalance() public view returns(uint256) {
        uint256 balance = balances[owner()];
        return balance;
    }
    
    //- Lock Count
    function _ContractCount() external virtual view returns(uint256) {
        return RocoVestingStorageBase.getLockContractCount();
    }
    
    //- Lock Count Detail
    function _ContractCountDetail(address _address) external view returns(uint256) {
        return RocoVestingStorageBase.getLockContractCountDetail(_address);
    }

    //- Create New Conract Master / Detail 
    function _CreateLockContract(address _owneraddress, uint _totalperiod, uint256 _starttime) external onlyOwner {
        RocoVestingStorageBase.setCreateLockContract(ERC20Roco, balances[msg.sender], _totalperiod, _starttime, _owneraddress);
    }
    
    //- Contract Lock Master
    function _ContractLock(address _address) external view returns(address, uint256, uint256, uint) {
        (address owneraddress, uint256 _starttime, uint256 _totalamount, uint _totalperiod)=RocoVestingStorageBase.getLockContract(_address);
        return (owneraddress, _starttime, _totalamount, _totalperiod);
    }
    
    //- Contract Lock Detail
    function _ContractLockDetail(address _address) external view returns(uint256[] memory, uint256[] memory, uint[] memory, bool[] memory) {
        (uint256[] memory _periodtime, uint256[] memory _periodamount, uint[] memory _period, bool[] memory _confirm)=
        RocoVestingStorageBase.getLockContractDetail(_address);
        return (_periodtime, _periodamount, _period, _confirm);
    }
    
    //- VestingData Claim Check
    function _ContractLockWithdrawCheck(address _address) external view returns(uint256, uint, address) {
        (uint256 _periodamount, uint _claimperiod)=
        RocoVestingStorageBase.getLockContractWithdrawCheck(_address);
        return(_periodamount, _claimperiod, address(this));
    }
    
    //- VestingData Claim Check
    function _ContractLockWithdraw() external {
        (bool _succes, uint256 _periodamount, address _owner)=RocoVestingStorageBase.setLockContractWithdraw(msg.sender);
        if ( _succes ) {
            balances[owner()] -= _periodamount;
            ERC20Roco.transfer(_owner, _periodamount);
        }    
    }
    
}