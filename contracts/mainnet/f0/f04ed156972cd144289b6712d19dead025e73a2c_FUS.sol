pragma solidity ^0.4.18;

contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}


contract FUS is owned {
    string public name = &#39;FusChain&#39;;
    string public symbol = &#39;FUS&#39;;
    uint8 public decimals = 18;
    // 10000w  100000000 * 1000000000000000000
    uint public totalSupply = 100000000000000000000000000;

    mapping (address => uint) public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;

    event Transfer(address indexed from, address indexed to, uint value);

    function FUS() public {
        balanceOf[msg.sender] = totalSupply;
    }

    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    function transfer(address _to, uint _value) public {
        _transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);  
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    function () payable public {
        uint etherAmount = msg.value;
        owner.transfer(etherAmount);
    }
}