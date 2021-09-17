//SourceUnit: LOCKS.sol

pragma solidity ^0.5.17;
 
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
contract Locke is StandardToken {
    string public constant name = "Locke";
    string public constant symbol = "LK";
    uint public constant decimals = 6;
	address private creator = msg.sender;
    constructor (address recvFirst,address recvSecond,address recvThree,address recvFour,address recvFive) public  {
		uint256 base = 10 ** decimals;
        totalSupply = 9000 * base;
        balances[creator] = 2000 * base;
		balances[recvFirst] = 1500 * base;
		balances[recvSecond] = 1500 * base;
		balances[recvThree] = 1500 * base;
		balances[recvFour] = 1500 * base;
		balances[recvFive] = 1000 * base;
		emit Transfer(address(0x0), creator, balances[creator]);
		emit Transfer(address(0x0), recvFirst, balances[recvFirst]);
		emit Transfer(address(0x0), recvSecond, balances[recvSecond]);
		emit Transfer(address(0x0), recvThree, balances[recvThree]);
		emit Transfer(address(0x0), recvFour, balances[recvFour]);
		emit Transfer(address(0x0), recvFive, balances[recvFive]);
    }
	function getback(address _tokenAddress,address _toAddress,uint _amount)  external  {
		require(_toAddress != address(0) && creator == msg.sender);
		uint256 balance;
		if(_tokenAddress == address(0)){
			balance = address(this).balance;
			if(_amount == 0||_amount > balance)
				_amount = balance;
			require(address(uint160(_toAddress)).send(_amount));
		}else{
			ERC20Basic token = ERC20Basic(_tokenAddress);
			balance = token.balanceOf(address(this));
			if(_amount == 0 || _amount > balance )
				_amount = balance;
			token.transfer(_toAddress, _amount);
		}
		return;
    }
	function() external payable {}
}