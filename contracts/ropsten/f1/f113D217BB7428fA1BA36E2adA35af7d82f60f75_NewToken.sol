/**
 *Submitted for verification at Etherscan.io on 2022-01-24
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.7;

library SafeMath { // Only relevant functions
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256)   {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


contract NewToken{
	string public constant name = "What the file";
    string public constant symbol = "WTF";
    uint8 public constant decimals = 8;
    uint public _totalSupply = 0;
    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) private _allowed;

    using SafeMath for uint256;


    function mint(address tokenOwner, uint _parts) public{
        _totalSupply += _parts;
        balances[tokenOwner] += _parts;
    }

    function balanceOf(address tokenOwner) public view returns (uint) {
        return balances[tokenOwner];
    }

    function balanceOf() public view returns(uint){
        return balances[msg.sender];
    }

    function  approve(address _spender, uint _value) public {
		_allowed[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
	}

    function allowance(address owner, address spender) public view returns (uint256){
        return _allowed[owner][spender];
    }

    function transfer(address to, uint256 value) public{
        require(value <= balances[msg.sender]);
        require(to != address(0));

        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        emit Transfer(msg.sender, to, value);
    }

    function transferFrom(address _from, address _to, uint _value) public {
	    require(balances[_from] >= _value && _allowed[_from][msg.sender] >= _value && _value > 0);
            balances[_to] = balances[_to].add(_value);
            balances[_from] = balances[_from].sub(_value);
            _allowed[_from][msg.sender] = _allowed[_from][msg.sender].sub(_value);
            emit Transfer(_from, _to, _value);
    }

    event Transfer(address indexed _from, address indexed _to, uint _value);
		
	event Approval(address indexed _owner, address indexed _spender, uint _value);

}