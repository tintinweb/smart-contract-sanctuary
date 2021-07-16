//SourceUnit: STT2.sol

pragma solidity ^0.4.13;

contract ERC20 {
  function balanceOf(address who) constant returns (uint);
  function allowance(address owner, address spender) constant returns (uint);

  function transfer(address to, uint value) returns (bool ok);
  function transferFrom(address from, address to, uint value) returns (bool ok);
  function approve(address spender, uint value) returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

//Safe math
contract SafeMath {
  function safeMul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint a, uint b) internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

}

contract StandardToken is ERC20, SafeMath {

  /* Token supply got increased and a new owner received these tokens */
  event Minted(address receiver, uint amount);

  /* Actual balances of token holders */
  mapping(address => uint) balances;

  /* approve() allowances */
  mapping (address => mapping (address => uint)) allowed;

  /* Interface declaration */
  function isToken() public constant returns (bool Yes) {
    return true;
  }

  function transfer(address _to, uint _value) returns (bool success) {
    balances[msg.sender] = safeSub(balances[msg.sender], _value);
    balances[_to] = safeAdd(balances[_to], _value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint _value) returns (bool success) {
    uint _allowance = allowed[_from][msg.sender];

    balances[_to] = safeAdd(balances[_to], _value);
    balances[_from] = safeSub(balances[_from], _value);
    allowed[_from][msg.sender] = safeSub(_allowance, _value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  function balanceOf(address _address) constant returns (uint balance) {
    return balances[_address];
  }

  function approve(address _spender, uint _value) returns (bool success) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

}

contract STT2Token is StandardToken {

    string public name = "Synthestech Token 2";
    string public symbol = "STT2";
    uint public totalSupply = 18000000;
    uint8 public decimals = 0;
    
    //Addresses that are allowed to transfer tokens
    mapping (address => bool) public allowedTransfer;
    
    //Addresses that are freeze to transfer tokens
    mapping (address => bool) public freezedTransfer;
    
	//Technical variables to store states
	bool public TransferAllowed = true;//Token transfers are blocked
	
    //Technical variables to store statistical data
	uint public StatsMinted = 0;//Minted tokens amount
	uint public StatsTotal = 0;//Overall tokens amount

    //Event logs
    event Buy(address indexed sender, uint eth, uint tokens, uint bonus);//Tokens purchased
    event Mint(address indexed from, uint tokens);// This notifies clients about the amount minted
    event Burn(address indexed from, uint tokens);// This notifies clients about the amount burnt
    
    address public owner = 0x0;//Admin actions
    address public minter = 0x0;//Minter tokens
 
    function STT2Token(address _owner, address _minter) payable {
        owner = _owner;
        minter = _minter;
        
        balances[owner] = 0;
        balances[minter] = 0;
        
        allowedTransfer[owner] = true;
        allowedTransfer[minter] = true;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    //Allow or prohibit token transfers
    function setTransferAllowance(bool _allowance) external onlyOwner {
        TransferAllowed = _allowance;
    }
    
    // Send `_amount` of tokens to `_target`
    function mintTokens(address _target, uint _amount) external returns (bool) {
        require(msg.sender == owner || msg.sender == minter);
        require(_amount > 0);//Number of tokens must be greater than 0
        uint amount=_amount;
        require(safeAdd(StatsTotal, amount) <= totalSupply);//The amount of tokens cannot be greater than Total supply
        balances[_target] = safeAdd(balances[_target], amount);
        StatsMinted = safeAdd(StatsMinted, amount);//Update number of tokens minted
        StatsTotal = safeAdd(StatsTotal, amount);//Update total number of tokens
        emit Transfer(0, this, amount);
        emit Transfer(this, _target, amount);
        emit Mint(_target, amount);
        return true;
    }
    
    // Decrease user balance
    function decreaseTokens(address _target, uint _amount) external returns (bool) {
        require(msg.sender == owner || msg.sender == minter);
        require(_amount > 0);//Number of tokens must be greater than 0
        uint amount=_amount;
        balances[_target] = safeSub(balances[_target], amount);
        StatsMinted = safeSub(StatsMinted, amount);//Update number of tokens minted
        StatsTotal = safeSub(StatsTotal, amount);//Update total number of tokens
        emit Transfer(_target, 0, amount);
        emit Burn(_target, amount);
        return true;
    }
    
    // Allow `_target` make token tranfers
    function allowTransfer(address _target, bool _allow) external onlyOwner {
        allowedTransfer[_target] = _allow;
    }
    
    // Allow `_target` make token tranfers
    function freezeTransfer(address _target, bool _freeze) external onlyOwner {
        freezedTransfer[_target] = _freeze;
    }
    
    function transfer(address _to, uint _value) returns (bool success) {
        
		require(!freezedTransfer[msg.sender]);
		
        //Forbid token transfers
        if (!TransferAllowed)
		{
            require(allowedTransfer[msg.sender]);
        }
        
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) returns (bool success) {
        
		require(!freezedTransfer[msg.sender] && !freezedTransfer[_from]);
		
        //Forbid token transfers
        if (!TransferAllowed)
		{
            require(allowedTransfer[msg.sender]);
        }
        
        return super.transferFrom(_from, _to, _value);
    }

    //Change owner
    function changeOwner(address _to) external onlyOwner() {
        balances[_to] = balances[owner];
        balances[owner] = 0;
        owner = _to;
    }

    //Change minter
    function changeMinter(address _to) external onlyOwner() {
        balances[_to] = balances[minter];
        balances[minter] = 0;
        minter = _to;
    }
}