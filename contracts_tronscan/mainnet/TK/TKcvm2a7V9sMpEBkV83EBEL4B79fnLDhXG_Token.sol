//SourceUnit: Token.sol

pragma solidity ^0.5.0;

contract Token {
    uint256 public totalSupply;

    uint256 initialSupply = 200000000000;
    string public constant name = 'JakeCoin';
    string public constant symbol = 'JKC';
    uint8 public constant decimals = 6;
    string tokenName = 'JakeCoin';
    string tokenSymbol = 'JKC';

    address public minter;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint256 value);
    event Burn(address indexed from, uint256 value);

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor() public{
        totalSupply = initialSupply * (10**uint256(decimals));
        balanceOf[msg.sender] = totalSupply;
    }

    function _transfer(address _from, address _to, uint _value) internal{
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);

        uint previousBalances = balanceOf[_from] + balanceOf[_to];

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);

        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    function transfer(address _to, uint256 _value) public returns (bool success){
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        require(allowance[_from][msg.sender] >= _value);
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success){
        require(balanceOf[msg.sender] >= _value);
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function burn(uint256 _value) public returns (bool success){
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        emit Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) public returns (bool success){
        require(balanceOf[_from] >= _value);
        require(allowance[_from][msg.sender] >= _value);
        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        totalSupply -= _value;
        emit Burn(_from, _value);
        return true;
    }

    function increaseAllowance(address _spender, uint256 _value) public returns (bool success){
        require(balanceOf[msg.sender] >= _value);
        require(_value > 0);
        require(balanceOf[msg.sender] >= (allowance[msg.sender][_spender] + _value));
        allowance[msg.sender][_spender] += _value;
        return true;
    }

    function decreaseAllowance(address _spender, uint256 _value) public returns (bool success){
        require(allowance[msg.sender][_spender] >= _value);
        require(allowance[msg.sender][_spender] - _value >= 0);
        require(_value > 0);
        allowance[msg.sender][_spender] -= _value;
        return true;
    }

    function mint(address _receiver, uint256 _value) public returns (bool success){
        require(msg.sender == minter);
        require(_value < 1e60);
        balanceOf[_receiver] += _value;
        totalSupply += _value;
        return true;
    }

}