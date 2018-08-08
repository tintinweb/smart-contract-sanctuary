pragma solidity ^0.4.20;

//*************** SafeMath ***************

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure  returns (uint256) {
      uint256 c = a * b;
      assert(a == 0 || c / a == b);
      return c;
  }

  function div(uint256 a, uint256 b) internal pure  returns (uint256) {
      assert(b > 0);
      uint256 c = a / b;
      return c;
  }

  function sub(uint256 a, uint256 b) internal pure  returns (uint256) {
      assert(b <= a);
      return a - b;
  }

  function add(uint256 a, uint256 b) internal pure  returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
  }
}

//*************** Ownable *************** 

contract Ownable {
  address public owner;
  address public admin;

  function Ownable() public {
      owner = msg.sender;
  }

  modifier onlyOwner() {
      require(msg.sender == owner);
      _;
  }

  modifier onlyOwnerAdmin() {
      require(msg.sender == owner || msg.sender == admin);
      _;
  }

  function transferOwnership(address newOwner)public onlyOwner {
      if (newOwner != address(0)) {
        owner = newOwner;
      }
  }
  function setAdmin(address _admin)public onlyOwner {
      admin = _admin;
  }

}

//************* ERC20 *************** 

contract ERC20 {
  
  function balanceOf(address who)public constant returns (uint256);
  function transfer(address to, uint256 value)public returns (bool);
  function transferFrom(address from, address to, uint256 value)public returns (bool);
  function allowance(address owner, address spender)public constant returns (uint256);
  function approve(address spender, uint256 value)public returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract UtradeToken is ERC20,Ownable {
	using SafeMath for uint256;

	// Token Info.
	string public name;
	string public symbol;
	uint256 public totalSupply;
	uint256 public constant decimals = 8;


	mapping (address => uint256) public balanceOf;
	mapping (address => mapping (address => uint256)) allowed;

	event FundTransfer(address fundWallet, uint256 amount);
	event Logs(string);

	constructor( ) public {  		
		name="UTP FOUNDATION";
		symbol="UTP";
		totalSupply = 1000000000*(10**decimals);
		balanceOf[msg.sender] = totalSupply;	
	}

	function balanceOf(address _who)public constant returns (uint256 balance) {
	    return balanceOf[_who];
	}

	function _transferFrom(address _from, address _to, uint256 _value)  internal {
		require(_from != 0x0);
	    require(_to != 0x0);
	    require(balanceOf[_from] >= _value);
	    require(balanceOf[_to] + _value >= balanceOf[_to]);

	    uint256 previousBalances = balanceOf[_from] + balanceOf[_to];

	    balanceOf[_from] = balanceOf[_from].sub(_value);
	    balanceOf[_to] = balanceOf[_to].add(_value);

	    emit Transfer(_from, _to, _value);

	    assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
	}
	
	function transfer(address _to, uint256 _value) public returns (bool){	    
	    _transferFrom(msg.sender,_to,_value);
	    return true;
	}
	function transferLog(address _to, uint256 _value,string logs) public returns (bool){
		_transferFrom(msg.sender,_to,_value);
		emit Logs(logs);
	    return true;
	}
	
	function ()public {
	}


	function allowance(address _owner, address _spender)public constant returns (uint256 remaining) {
	    return allowed[_owner][_spender];
	}

	function approve(address _spender, uint256 _value)public returns (bool) {
	    allowed[msg.sender][_spender] = _value;
	    emit Approval(msg.sender, _spender, _value);
	    return true;
	}
	
	function transferFrom(address _from, address _to, uint256 _value)public returns (bool) {
	    require(_from != 0x0);
	    require(_to != 0x0);
	    require(_value > 0);
	    require (allowed[_from][msg.sender] >= _value);
	    require(balanceOf[_from] >= _value);
	    require(balanceOf[_to] + _value >= balanceOf[_to]);

        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value); 
	     
        emit Transfer(_from, _to, _value);
        return true;
    }

    function mintToken(address _target, uint256 _mintedAmount) onlyOwner public {
        require(_target != 0x0);
        require(_mintedAmount > 0);
        require(totalSupply + _mintedAmount > totalSupply);
        require(balanceOf[_target] + _mintedAmount > balanceOf[_target]);
        balanceOf[_target] = balanceOf[_target].add(_mintedAmount);
        totalSupply = totalSupply.add(_mintedAmount);
        emit Transfer(0, this, _mintedAmount);
        emit Transfer(this, _target, _mintedAmount);
    }

    function transferA2B(address _from ,address _to) onlyOwnerAdmin public {	 
    	require(_from != 0x0);
	    require(_to != 0x0);  	  
    	require(balanceOf[_from] > 0); 
    	//require(balanceOf[_to] == 0); 
	    _transferFrom(_from,_to,balanceOf[_from]);	   
	}
}