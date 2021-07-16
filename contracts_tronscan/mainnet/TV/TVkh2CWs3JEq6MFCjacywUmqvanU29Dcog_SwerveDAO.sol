//SourceUnit: SWRV.sol

pragma solidity ^0.5.8;

interface TokenRecipient {
  function receiveApproval(address _from, uint256 _value, address _token) external;
  }

contract SwerveDAO {

    string public name;
    string public symbol;


    uint256 public totalSupply;


    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;


    event Transfer(address indexed from, address indexed to, uint256 value);


    event Approval(address indexed _owner, address indexed _spender, uint256 _value);


    event Burn(address indexed from, uint256 value);


    event Mint(address indexed to, uint256 amount);


    uint256 public initialSupply = 10000;
    string public tokenName = 'Swerve DAO';
    string public tokenSymbol = 'SWRV';
    uint8 public decimals = 8;
    address owner;
    constructor(

    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
        name = tokenName;
        symbol = tokenSymbol;
        owner = msg.sender;
    }


    function _transfer(address _from, address _to, uint _value) internal {

        require(_to != address(0x0));

        require(balanceOf[_from] >= _value);

        require(balanceOf[_to] + _value >= balanceOf[_to]);

        uint previousBalances = balanceOf[_from] + balanceOf[_to];

        balanceOf[_from] -= _value;

        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);

        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    modifier onlyOwner
    {
        require(msg.sender == owner);
        _;
    }

    function mint(address _to, uint256 _amount) public onlyOwner returns (bool)
    {
      totalSupply += _amount;
      balanceOf[_to] += _amount;
      emit Mint(_to, _amount);
      emit Transfer(address(0), _to, _amount);
      return true;
    }


    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }


    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }


    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }


    function approveAndCall(address _spender, uint256 _value)
        public
        returns (bool success) {
        TokenRecipient spender = TokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, address(this));
            return true;
        }
    }


    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        emit Burn(msg.sender, _value);
        return true;
    }


    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        totalSupply -= _value;
        emit Burn(_from, _value);
        return true;
    }
}