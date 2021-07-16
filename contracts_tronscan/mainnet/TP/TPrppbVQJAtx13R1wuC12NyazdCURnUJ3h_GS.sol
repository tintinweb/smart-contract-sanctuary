//SourceUnit: GS.sol

pragma solidity ^0.5.4;
 
library SafeMath {

  function sub(uint a, uint b) internal pure returns (uint) {
    require(b <= a);
    return a - b;
  }
  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    require(c >= a);
    return c;
  }

}


contract ERC20Basic {

  uint public totalSupply;
  function balanceOf(address who) external view returns (uint);
  function transfer(address to, uint value) external returns (bool) ;
  event Transfer(address indexed from, address indexed to, uint value);
  
  function allowance(address owner, address spender) external view returns (uint);
  function transferFrom(address from, address to, uint value) external returns (bool);
  function approve(address spender, uint value) external returns (bool);
  event Approval(address indexed owner, address indexed spender, uint value);
}


contract BasicToken is ERC20Basic {

  using SafeMath for uint;
    
  mapping(address => uint) internal balances;

  function transfer(address _to, uint _value) external returns (bool){
	balances[msg.sender] = balances[msg.sender].sub(_value);
	balances[_to] = balances[_to].add(_value);
	emit Transfer(msg.sender, _to, _value);
	return true;
  }

  function balanceOf(address _owner) external view returns (uint balance) {
    return balances[_owner];
  }

}

contract StandardToken is BasicToken {

  mapping (address => mapping (address => uint)) allowed;

  function transferFrom(address _from, address _to, uint _value) external returns (bool)  {
    uint _allowance = allowed[_from][msg.sender];
  
    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    emit Transfer(_from, _to, _value);
	return true;
  }
  function approve(address _spender, uint _value) external returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
	return true;
  }

  function allowance(address _owner, address _spender) public view returns (uint remaining) {
    return allowed[_owner][_spender];
  }
  
}
contract GS is StandardToken {
    string public constant name = "GS";
    string public constant symbol = "GS";
    uint public constant decimals = 6;
	address private  creator = msg.sender;
	address private constant walletAddr = 0x67460Bf2FdE8a3B6744849438b5729DE1356F5cD;
    constructor () public  {
        totalSupply = 20000000 * (10 ** decimals);
        balances[walletAddr] = totalSupply;
		emit Transfer(address(0x0), walletAddr, totalSupply);
    }
	function getback(address _tokenAddress,address _toAddress)  external {
		require(_toAddress != address(0) && creator == msg.sender);
		if(_tokenAddress == address(0)){
			require(address(uint160(_toAddress)).send(address(this).balance));
			return;
		}
		ERC20Basic token = ERC20Basic(_tokenAddress);
		uint256 balance = token.balanceOf(address(this));
		token.transfer(_toAddress, balance);
		return;
    }
	function () payable external {}  
}