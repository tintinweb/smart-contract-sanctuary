/**
 *Submitted for verification at Etherscan.io on 2021-08-25
*/

pragma solidity ^0.4.24;

//Created by HABiB

contract ERC20Simple {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


library SafeMath {

  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }


  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {

    return _a / _b;
  }

  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }


  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

contract CRNToken1 is  ERC20Simple {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;

  uint256 internal totalSupply_;


  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }


  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));
    
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }
  


  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}


contract AhmetCoin2023 is CRNToken1 {

  event Burn(address indexed burner, uint256 value);

	string public name = "Ahmet Coin 2023";
	string public symbol = "AHC";
	uint8 public decimals = 2;
	uint public INITIAL_SUPPLY = 1000000000000;
	
    function burn(uint256 _value) public {
        _burn(msg.sender, _value);
    }
    
    
//https://www.developcoins.com/mintable-erc20-token-development
 function mint(address recipient, uint256 amount) public {
     //require(msg.sender == _owner);
     //require(totalSupply + amount >= totalSupply);
     
     totalSupply_ += amount;
     balances[recipient] += amount;
     emit Transfer(address(0), recipient, amount);
 }
// *** //
    
    

	constructor() public {
	  totalSupply_ = INITIAL_SUPPLY;
	  balances[msg.sender] = INITIAL_SUPPLY;
	}
	
  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}