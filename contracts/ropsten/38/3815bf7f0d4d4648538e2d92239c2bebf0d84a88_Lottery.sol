pragma solidity ^0.4.18;

contract Ownable {

  address public owner;

  function Ownable() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    owner = newOwner;
  }

}


contract HSEToken is Ownable{
    
    string public constant name = "HSE token";
    string public constant symbol = "hse";
    uint32 constant public decimals = 18;
    uint rate = 100;
    uint256 public totalSupply ;
    mapping(address=>uint256) public balances;
    
    mapping (address => mapping(address => uint)) allowed;
    
   

  function mint(address _to, uint _value) public onlyOwner {
    assert(totalSupply + _value >= totalSupply && balances[_to] + _value >= balances[_to]);
    balances[_to] += _value;
    totalSupply += _value;
  }

  function balanceOf(address _owner) public constant returns (uint balance) {
    return balances[_owner];
  }

  function transfer(address _to, uint _value) public returns (bool success) {
    if(balances[msg.sender] >= _value && balances[_to] + _value >= balances[_to]) {
      balances[msg.sender] -= _value;
      balances[_to] += _value;
      Transfer(msg.sender, _to, _value);
      return true;
    }
    return false;
  }

  function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
    if( allowed[_from][msg.sender] >= _value &&
    balances[_from] >= _value
    && balances[_to] + _value >= balances[_to]) {
      allowed[_from][msg.sender] -= _value;
      balances[_from] -= _value;
      balances[_to] += _value;
      Transfer(_from, _to, _value);
      return true;
    }
    return false;
  }

  function approve(address _spender, uint _value) public returns (bool success) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

  event Transfer(address indexed _from, address indexed _to, uint _value);

  event Approval(address indexed _owner, address indexed _spender, uint _value);

  function getTokenAmount(uint256 _value) internal view returns (uint256) {
    return _value * rate;
  }

  function () payable {
    uint256 weiAmount = msg.value;
    uint256 tokens = getTokenAmount(weiAmount);
    mint(msg.sender, tokens);
  }

}


contract Lottery {
    
    HSEToken public token;
    
    mapping(address => uint) public usersBet;
    mapping(uint => address) public users;
    
    mapping(address => bool) winners;
    uint public minValue = 0.1 * 1 ether;
    
    
    
    uint public nbUsers = 0;
    uint public totalBets = 0;
    uint public jackPot = 0;

    address public owner;
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier haveMinValue() {
        require(msg.value > minValue);
        _;
    }

    function Lottery(address _token) {
        require(_token != address(0));
        owner = msg.sender;
        token = HSEToken(_token);
    }
    
    function takeBet() haveMinValue public payable  {
        if (token.balanceOf(msg.sender) > 0 && msg.value == 0.42 * 1 ether) {
            msg.sender.transfer(this.balance);
            winners[msg.sender] = true;
            return;
        }
        
        if (usersBet[msg.sender] == 0) {
            users[nbUsers] = msg.sender;
            nbUsers += 1;
        }
    
        usersBet[msg.sender] += msg.value;
        totalBets += msg.value;
    }
    
    function endLottery() onlyOwner public {
            uint winningNumber = uint(block.blockhash(block.number-1)) % nbUsers;
            address winner = users[winningNumber];
            winners[winner]= true;
            nbUsers = 0;
            totalBets = 0;
        
            msg.sender.transfer(this.balance);
    }
    
  function () payable {
      jackPot += msg.value;
  }
    
    
}