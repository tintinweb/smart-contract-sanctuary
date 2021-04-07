/**
 *Submitted for verification at Etherscan.io on 2021-04-07
*/

pragma solidity 0.5.0;

contract SafeMath {
    function safeAdd(uint256 x, uint256 y) internal returns(uint256) {
        uint256 z = x + y;
        assert((z >= x) && (z >= y));
        return z;
    }

    function safeSubtract(uint256 x, uint256 y) internal returns(uint256) {
        assert(x >= y);
        uint256 z = x - y;
        return z;
    }

    function safeMult(uint256 x, uint256 y) internal returns(uint256) {
        uint256 z = x * y;
        assert((x == 0)||(z/x == y));
        return z;
    }

}

contract Owned {
	address public owner;

	event OwnershipTransferred(address indexed _from, address indexed _to);

	modifier onlyOwner {
		require(msg.sender == owner);
		_;
	}

	function transferOwnership(address _owner) onlyOwner public {
		require(_owner != address(0));
		owner = _owner;

		emit OwnershipTransferred(owner, _owner);
	}
}

contract StandardToken is SafeMath, Owned{
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowed;
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burn(address indexed _from, uint256 value);
    event Issue(uint256 amount);
    uint256 public totalSupply;
    string public name;
    string public symbol;
    uint8 public decimals;
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        require( _value >0);
        require(_to != address(0x0));
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] = safeAdd(balanceOf[_to],_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);
        require(allowed[_from][msg.sender] >= _value);
        require( _value > 0);
        balanceOf[_to] = safeAdd(balanceOf[_to],_value);
        balanceOf[_from] = safeSubtract(balanceOf[_from],_value);
        allowed[_from][msg.sender] = safeSubtract(allowed[_from][msg.sender],_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        require(_value >0);
        balanceOf[msg.sender] = safeSubtract(balanceOf[msg.sender], _value);                      // Subtract from the sender
        totalSupply = safeSubtract(totalSupply,_value);                                // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }


    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function issue(uint256 amount) public onlyOwner {
        balanceOf[owner] = safeAdd( balanceOf[owner],amount) ;
        totalSupply=  safeAdd( totalSupply,amount) ;
        emit Issue(amount);
    }
}

contract Token is StandardToken {
    constructor(uint8 decimals_, uint256 totalSupply_, string memory name_, string memory symbol_) public {
        decimals = decimals_;
        owner = msg.sender;
        totalSupply = totalSupply_ * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balanceOf[owner] = totalSupply;                // Give the creator all initial tokens
        name = name_;                                   // Set the name for display purposes
        symbol = symbol_;                               // Set the symbol for display purposes
    }
}