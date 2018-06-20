pragma solidity ^0.4.24;

contract TOPB {
    string public name = &#39;TOPBTC TOKEN&#39;;
    string public symbol = &#39;TOPB&#39;;
    uint8 public decimals = 18;
    uint256 public totalSupply;
	
    mapping (address => uint256) public balanceOf;
	
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
	
    function () payable public {
		assert(false);
    }

    function TOPB() public {
        totalSupply = 200000000 * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
    }

    function _transfer(address _from, address _to, uint256 _value) internal {
		assert(_to != 0x0);
		assert(balanceOf[_from] >= _value);
		assert(balanceOf[_to] + _value > balanceOf[_to]);
		uint256 previousBalances = balanceOf[_from] + balanceOf[_to];
		balanceOf[_from] -= _value;
		balanceOf[_to] += _value;
		emit Transfer(_from, _to, _value);
		assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    function burn(uint256 _value) public returns (bool success) {
        assert(balanceOf[msg.sender] >= _value); 
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        emit Burn(msg.sender, _value);
        return true;
    }
}