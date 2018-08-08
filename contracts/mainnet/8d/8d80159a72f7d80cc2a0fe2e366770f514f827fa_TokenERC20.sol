pragma solidity ^0.4.19;

contract TokenERC20 {
    string public name = "United Vepomzer";
    string public symbol = "Vepomzer";
    uint256 public decimals = 18;
    uint256 public totalSupply = 999999999 * 10 ** decimals;

    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);

    function TokenERC20() public {
        balances[msg.sender] = totalSupply;
    }

    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != address(0));
        require(balances[_from] >= _value);
        require(balances[_to] + _value >= balances[_to]);
        uint previousBalances = balances[_from] + balances[_to];
        balances[_from] -= _value;
        balances[_to] += _value;
        Transfer(_from, _to, _value);
        assert(balances[_from] + balances[_to] == previousBalances);
    }

    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowed[_from][msg.sender]);
        allowed[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }
}