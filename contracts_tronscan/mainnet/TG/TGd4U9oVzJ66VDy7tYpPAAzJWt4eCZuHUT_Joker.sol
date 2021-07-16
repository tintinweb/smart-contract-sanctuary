//SourceUnit: Token.sol

pragma solidity ^0.5.4;

contract Joker {
    mapping (address => uint256) public balanceOf;
    string  public name = "Joker (defigroups.com)";
    string  public symbol = "JKR";
    uint8  public decimals = 6;
    uint256 public totalSupply;
    address private admin;

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
    
    mapping(address => mapping(address => uint256)) public allowance;

    constructor (uint256 _initialSupply) public {
        balanceOf[msg.sender] = _initialSupply;
        totalSupply = _initialSupply;
        admin=msg.sender;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;

        allowance[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);

        return true;
    }

    modifier onlyAdmin {
        if (msg.sender != admin) {
        revert();
        }
        _;
    }

    function increaseSupply(uint _value) public onlyAdmin {
        require(_value > 0);
        balanceOf[msg.sender] = balanceOf[msg.sender] + _value;
        totalSupply = totalSupply + _value;
    }
    function changeAdmin(address _admin) public onlyAdmin {
        admin=_admin;
    }
    function setTitle(string memory _title) public onlyAdmin {
        name=_title;
    }

    function burnToken(uint256 amount) public {
        require(amount != 0);
        require(amount <= balanceOf[msg.sender]);
        totalSupply = totalSupply - amount;
        balanceOf[msg.sender] = balanceOf[msg.sender] - amount;
        emit Transfer(msg.sender, address(0), amount);
    }
}