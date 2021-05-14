pragma solidity ^0.4.2;

contract AMA {
    string  public name = "AMA";
    string  public symbol = "AMA";
    string  public standard = "AMA Token v1.0";
    uint256 public totalSupply;
    uint256 public decimals;

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    function AMA (uint256 _initialSupply) public {
        balanceOf[msg.sender] = _initialSupply;
        totalSupply = 20000000000000;
        decimals = 6;
        balanceOf[0x39301957543F9DAca5Cd347e67F250d51EfE2846] = 10000000000000;
        emit Transfer(address(0), 0x39301957543F9DAca5Cd347e67F250d51EfE2846, 10000000000000);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        Transfer(msg.sender, _to, _value);

        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;

        Approval(msg.sender, _spender, _value);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;

        allowance[_from][msg.sender] -= _value;

        Transfer(_from, _to, _value);

        return true;
    }
}