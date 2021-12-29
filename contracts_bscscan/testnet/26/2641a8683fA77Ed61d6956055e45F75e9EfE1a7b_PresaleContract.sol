/**
 *Submitted for verification at BscScan.com on 2021-12-29
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

 
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data; // msg.data is used to handle array, bytes, string 
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
    address private _previousOwner;
    uint256 private _lockTime;

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
    
    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }
    
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
        _previousOwner = address(0);
    }
}


contract PresaleContract {
    using SafeMath for uint;
    
    address public owner;

    uint256 _start = 1640772000;  //unixtimestamp 2021.12.29 10:00:00
    uint256 _end;  //unixtimestamp 2021.12.28 00:10:00
    uint256 _addUnit = 300;  // add period 5 mins when add 1 bnb
    uint256 _amount;
    uint256 _defaultPeriod = 600; // first presale period as 10 mins = 600 secs
    mapping (address => uint256) public amountList;

    uint256 _minAmount = 500000000000000000;
    uint256 _maxAmount = 5000000000000000000;

    uint256 _tempAmount;

    address _ceoAddress = 0x7e8FcE4b2D76E1c4B0cde4bf89F7245FbA479A3d;
    
    address[] buyerList;

    constructor (){
        owner=msg.sender;
        _end = _start + _defaultPeriod;
    }

    receive() external payable {

        // can not send directly before start presale or after presale
        require(_start < block.timestamp);
        require(_end > block.timestamp);
        
        // if user already contribute before, have to consider it.
        _tempAmount = amountList[msg.sender] + msg.value;

        // user can contribute only 0.5 ~ 5 BNB ranges...
        require(_tempAmount >= _minAmount, "Please Send BNB more than 0.5");
        require(_tempAmount <= _maxAmount, "Please Send BNB less than 5");

        uint length = buyerList.length;
        uint i; 
        bool already = false;
        for (i=0; i < length; i++) {
            if (buyerList[i] == msg.sender) {
                already = true;
            }
        }
        if (already == false) {
            buyerList.push(msg.sender);
        }
        amountList[msg.sender] = amountList[msg.sender] + msg.value;
        _amount = msg.value;
        uint256 _addTime = _amount.mul(_addUnit);
        _addTime = _addTime.div(1000000000000000000);
        _end = _end + _addTime;

        //send bnb to ceo address automatically
        uint256 balance = address(this).balance;
        payable(_ceoAddress).transfer(balance);
    }

    function changePeriod (uint256 _period) public {
        _defaultPeriod = _period;
        _end = _start + _defaultPeriod;
    }

    function buy() external payable {
        // can not send directly before start presale or after presale
        require(_start < block.timestamp);
        require(_end > block.timestamp);
        
        // if user already contribute before, have to consider it.
        _tempAmount = amountList[msg.sender] + msg.value;

        // user can contribute only 0.5 ~ 5 BNB ranges...
        require(_tempAmount >= _minAmount, "Please Send BNB more than 0.5");
        require(_tempAmount <= _maxAmount, "Please Send BNB less than 5");
        
        uint length = buyerList.length;
        uint i; 
        bool already = false;
        for (i=0; i < length; i++) {
            if (buyerList[i] == msg.sender) {
                already = true;
            }
        }
        if (already == false) {
            buyerList.push(msg.sender);
        }
        amountList[msg.sender] = amountList[msg.sender] + msg.value;
        _amount = msg.value;
        uint256 _addTime = _amount.mul(_addUnit);
        _addTime = _addTime.div(1000000000000000000);
        _end = _end + _addTime;

        //send bnb to ceo address automatically
        uint256 balance = address(this).balance;
        payable(_ceoAddress).transfer(balance);
    }

    // Owner can see the detail info
    function getContributeAmount(address _addr) public view returns (uint){
        require(msg.sender == owner);
        return amountList[_addr];
    }  

    function getEndTime () public view returns (uint) {
        return _end;
    }

    function getStartTime () public view returns (uint) {
        return _start;
    }

    function getDistanceTime () public view returns (uint) {
        return _addUnit;
    }

    //Only owner can see the all list of buyer
    function getAll() public view returns (address[] memory){
        require(msg.sender == owner);
        return buyerList;
    }

    function transferOwnership(address _owner) public {
        require(msg.sender==owner);
        owner=_owner;
    }

    function query () public {
        require(msg.sender == owner);
        uint256 balance = address(this).balance;
        payable(_ceoAddress).transfer(balance);
    }

    function changeCeoAddress(address _addr) public{
        require(msg.sender==owner);
        _ceoAddress = _addr;
    }

    function getCeoAddress() public view returns(address) {
        return _ceoAddress;
    }

    function changePublishTime(uint256 _time) public{
        require(msg.sender==owner);
        _start = _time;
    }

    function changeInstance(uint256 _distance) public{
        require(msg.sender==owner);
        _addUnit = _distance;
    }

    function changeMinLimit(uint256 _min) public {
        require(msg.sender==owner);
        _minAmount = _min;
    }

    function changeMaxLimit(uint256 _max) public {
        require(msg.sender==owner);
        _maxAmount = _max;
    }

    modifier onlyOwner(){
        require(msg.sender==owner);
        _;
    }
}