pragma solidity ^0.4.12;

//ERC20
contract ERC20 {
     function totalSupply() constant returns (uint256 supply);
     function balanceOf(address _owner) constant returns (uint256 balance);
     function transfer(address _to, uint256 _value) returns (bool success);
     function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
     function approve(address _spender, uint256 _value) returns (bool success);
     function allowance(address _owner, address _spender) constant returns (uint256 remaining);

     event Transfer(address indexed _from, address indexed _to, uint256 _value);
     event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract YUNLAI is ERC20{

    // metadata
    string  public constant name = "YUN LAI COIN";
    string  public constant symbol = "YLC";
    string  public version = "1.0";
    uint256 public constant decimals = 18;
    uint256 public totalSupply = 1500000000000000000000000000;
   

    // contracts
    address public owner;

    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowance;

    // format decimals.
    function formatDecimals(uint256 _value) internal returns (uint256 ) {
        return _value * 10 ** decimals;
    }

    /**
     * @dev Fix for the ERC20 short address attack.
     */
    modifier onlyPayloadSize(uint size) {
      if(msg.data.length < size + 4) {
        revert();
      }
      _;
    }

    modifier isOwner()  {
      require(msg.sender == owner);
      _;
    }

    // constructor
    function YUNLAI()
    {
        owner = msg.sender;
        balances[msg.sender] = totalSupply;
    }

    function totalSupply() constant returns (uint256 supply)
    {
      return totalSupply;
    }

    /* Send coins */
    function transfer(address _to, uint256 _value) onlyPayloadSize(2*32) returns (bool success){
      if ((_to == 0x0) || (_value <= 0) || (balances[msg.sender] < _value)
           || (balances[_to] + _value < balances[_to])) return false;
      balances[msg.sender] -= _value;
      balances[_to] += _value;

      Transfer(msg.sender, _to, _value);
      return true;
    }
   
    function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(2*32) returns (bool success) {
      if ((_to == 0x0) || (_value <= 0) || (balances[_from] < _value)
          || (balances[_to] + _value < balances[_to])
          || (_value > allowance[_from][msg.sender]) ) return false;

      balances[_to] += _value;
      balances[_from] -= _value;
      allowance[_from][msg.sender] -= _value;

      Transfer(_from, _to, _value);
      return true;
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowance[_owner][_spender];
    }

    function () payable {
        revert();
    }
}