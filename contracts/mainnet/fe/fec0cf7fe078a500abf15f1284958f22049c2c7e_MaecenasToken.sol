library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract IToken {
  function totalSupply() constant returns (uint256 totalSupply);
  function mintTokens(address _to, uint256 _amount) {}
}
contract IMintableToken {
  function mintTokens(address _to, uint256 _amount){}
}
contract IERC20Token {
  function totalSupply() constant returns (uint256 totalSupply);
  function balanceOf(address _owner) constant returns (uint256 balance) {}
  function transfer(address _to, uint256 _value) returns (bool success) {}
  function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}
  function approve(address _spender, uint256 _value) returns (bool success) {}
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract ItokenRecipient {
  function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData);
}

contract Owned {
    address public owner;
    address public newOwner;

    function Owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        assert(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = 0x0;
    }

    event OwnerUpdate(address _prevOwner, address _newOwner);
}
contract ReentrnacyHandlingContract{

    bool locked;

    modifier noReentrancy() {
        require(!locked);
        locked = true;
        _;
        locked = false;
    }
}

contract Lockable is Owned{

  uint256 public lockedUntilBlock;

  event ContractLocked(uint256 _untilBlock, string _reason);

  modifier lockAffected {
      require(block.number > lockedUntilBlock);
      _;
  }

  function lockFromSelf(uint256 _untilBlock, string _reason) internal {
    lockedUntilBlock = _untilBlock;
    ContractLocked(_untilBlock, _reason);
  }


  function lockUntil(uint256 _untilBlock, string _reason) onlyOwner {
    lockedUntilBlock = _untilBlock;
    ContractLocked(_untilBlock, _reason);
  }
}


contract Token is IERC20Token, Owned, Lockable{

  using SafeMath for uint256;

  /* Public variables of the token */
  string public standard;
  string public name;
  string public symbol;
  uint8 public decimals;

  address public crowdsaleContractAddress;

  /* Private variables of the token */
  uint256 supply = 0;
  mapping (address => uint256) balances;
  mapping (address => mapping (address => uint256)) allowances;

  /* Events */
  event Mint(address indexed _to, uint256 _value);

  /* Returns total supply of issued tokens */
  function totalSupply() constant returns (uint256) {
    return supply;
  }

  /* Returns balance of address */
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

  /* Transfers tokens from your address to other */
  function transfer(address _to, uint256 _value) lockAffected returns (bool success) {
    require(_to != 0x0 && _to != address(this));
    balances[msg.sender] = balances[msg.sender].sub(_value); // Deduct senders balance
    balances[_to] = balances[_to].add(_value);               // Add recivers blaance
    Transfer(msg.sender, _to, _value);                       // Raise Transfer event
    return true;
  }

  /* Approve other address to spend tokens on your account */
  function approve(address _spender, uint256 _value) lockAffected returns (bool success) {
    allowances[msg.sender][_spender] = _value;        // Set allowance
    Approval(msg.sender, _spender, _value);           // Raise Approval event
    return true;
  }

  /* Approve and then communicate the approved contract in a single tx */
  function approveAndCall(address _spender, uint256 _value, bytes _extraData) lockAffected returns (bool success) {
    ItokenRecipient spender = ItokenRecipient(_spender);            // Cast spender to tokenRecipient contract
    approve(_spender, _value);                                      // Set approval to contract for _value
    spender.receiveApproval(msg.sender, _value, this, _extraData);  // Raise method on _spender contract
    return true;
  }

  /* A contract attempts to get the coins */
  function transferFrom(address _from, address _to, uint256 _value) lockAffected returns (bool success) {
    require(_to != 0x0 && _to != address(this));
    balances[_from] = balances[_from].sub(_value);                              // Deduct senders balance
    balances[_to] = balances[_to].add(_value);                                  // Add recipient blaance
    allowances[_from][msg.sender] = allowances[_from][msg.sender].sub(_value);  // Deduct allowance for this address
    Transfer(_from, _to, _value);                                               // Raise Transfer event
    return true;
  }

  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowances[_owner][_spender];
  }

  function mintTokens(address _to, uint256 _amount) {
    require(msg.sender == crowdsaleContractAddress);

    supply = supply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(0x0, _to, _amount);
  }

  function salvageTokensFromContract(address _tokenAddress, address _to, uint _amount) onlyOwner{
    IERC20Token(_tokenAddress).transfer(_to, _amount);
  }
}



contract MaecenasToken is Token {

  /* Initializes contract */
  function MaecenasToken() {
    standard = "Maecenas token v1.0";
    name = "Maecenas ART Token";
    symbol = "ART";
    decimals = 18;
    crowdsaleContractAddress = 0x9B60874D7bc4e4fBDd142e0F5a12002e4F7715a6; 
    lockFromSelf(4366494, "Lock before crowdsale starts");
  }
}