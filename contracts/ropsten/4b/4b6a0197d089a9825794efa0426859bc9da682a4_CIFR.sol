pragma solidity ^0.4.19;
 
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract Owned {
    address public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

	function transferOwnership(address newOwner) public onlyOwner {
		require(newOwner != address(0));
		emit OwnershipTransferred(owner, newOwner);
    	owner = newOwner;
	}
}

contract CIFR is ERC20Interface, Owned, SafeMath {
	/* Public variables of the token */	
    string public constant symbol = &quot;CIFR&quot;;
    string public constant name = &quot;CIFRCOIN TOKEN&quot;;
    uint8 public constant decimals = 18;
    uint256 public totalSupply_;

	/* This creates an array with all balances */
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) internal allowed;
	
	/* This generates a public event on the blockchain that will notify clients */
	event Transfer(address indexed from, address indexed to, uint256 value);	
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function CIFR() public {
        owner = msg.sender;
        totalSupply_ = 100000000000000000000000000;
        balances[owner] = totalSupply_;
        emit Transfer(address(0), owner, totalSupply_);
    }

    function totalSupply() public view returns (uint256) {
        return totalSupply_  - balances[address(0)];
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
		require(_to != address(0));
		require(balances[msg.sender] >=_value);
        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
		require(_to != address(0));
		require(_value <= balances[_from]);
		require(_value <= allowed[_from][msg.sender]);
		
        balances[_from] = safeSub(balances[_from], _value);
        allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }
	
	/* Allow another contract to spend some tokens in your behalf. 
	Changing an allowance brings the risk of double spending, when both old and new values will be used */
	function approve(address _spender, uint256 _value) public returns (bool) {
    	allowed[msg.sender][_spender] = _value;
    	emit Approval(msg.sender, _spender, _value);		
		return true;
	}	
	
	/* This returns the amount of tokens that an owner allowed to a spender. */
	function allowance(address _owner, address _spender) public view returns (uint256) {
		return allowed[_owner][_spender];
	}

	/* This function is used to increase the amount of tokens allowed to spend by spender.*/
	function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    	require(allowed[msg.sender][_spender] + _addedValue >= allowed[msg.sender][_spender]);
		allowed[msg.sender][_spender] = allowed[msg.sender][_spender] + _addedValue;
    	emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    	return true;
  	}

	/* This function is used to decrease the amount of tokens allowed to spend by spender.*/
	function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
		uint oldValue = allowed[msg.sender][_spender];
		if (_subtractedValue > oldValue) {
			allowed[msg.sender][_spender] = 0;
		} 
		else {
			allowed[msg.sender][_spender] = oldValue - _subtractedValue;
		}
		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
  	}



	function () public payable {} 

	function withdraw() public onlyOwner {
    	msg.sender.transfer(address(this).balance);
	}

	function destroy() onlyOwner public {
		selfdestruct(owner);
	}

    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}