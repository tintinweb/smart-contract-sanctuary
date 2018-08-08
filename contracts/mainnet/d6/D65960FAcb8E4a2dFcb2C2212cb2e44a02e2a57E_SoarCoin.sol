pragma solidity ^ 0.4.8;

contract ERC20 {

    uint public totalSupply;
    
    function totalSupply() constant returns(uint totalSupply);

    function balanceOf(address who) constant returns(uint256);

    function allowance(address owner, address spender) constant returns(uint);

    function transferFrom(address from, address to, uint value) returns(bool ok);

    function approve(address spender, uint value) returns(bool ok);

    function transfer(address to, uint value) returns(bool ok);

    event Transfer(address indexed from, address indexed to, uint value);

    event Approval(address indexed owner, address indexed spender, uint value);

   }
   
  contract SoarCoin is ERC20
  {
      
    // Name of the token
    string public constant name = "Soarcoin";

    // Symbol of token
    string public constant symbol = "Soar";

    uint public decimals = 6;
    uint public totalSupply = 5000000000000000 ; //5 billion includes 6 zero for decimal
    address central_account;
    address owner;
    mapping(address => uint) balances;
    
    mapping(address => mapping(address => uint)) allowed;
    
    // Functions with this modifier can only be executed by the owner
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert();
        }
        _;
    }
    
    modifier onlycentralAccount {
        require(msg.sender == central_account);
        _;
    }
    
    function SoarCoin()
    {
        owner = msg.sender;
        balances[owner] = totalSupply;
    }
    
    
    // erc20 function to return total supply
    function totalSupply() constant returns(uint) {
       return totalSupply;
    }
    
    // erc20 function to return balance of give address
    function balanceOf(address sender) constant returns(uint256 balance) {
        return balances[sender];
    }

    // Transfer the balance from one account to another account
    function transfer(address _to, uint256 _amount) returns(bool success) {
        
        if (balances[msg.sender] >= _amount &&
            _amount > 0 &&
            balances[_to] + _amount > balances[_to]) {
            balances[msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(msg.sender, _to, _amount);
            return true;
        } else {
            return false;
        }
    }
    
    function set_centralAccount(address central_Acccount) onlyOwner
    {
        central_account = central_Acccount;
    }

    // Send _value amount of tokens from address _from to address _to
    // The transferFrom method is used for a withdraw workflow, allowing contracts to send
    // tokens on your behalf, for example to "deposit" to a contract address and/or to charge
    // fees in sub-currencies; the command should fail unless the _from account has
    // deliberately authorized the sender of the message via some mechanism; we propose
    // these standardized APIs for approval:

    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) returns(bool success) {
        if (balances[_from] >= _amount &&
            allowed[_from][msg.sender] >= _amount &&
            _amount > 0 &&
            balances[_to] + _amount > balances[_to]) {
            balances[_from] -= _amount;
            allowed[_from][msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }
    
    // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
    // If this function is called again it overwrites the current allowance with _value.
    function approve(address _spender, uint256 _amount) returns(bool success) {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns(uint256 remaining) {
        return allowed[_owner][_spender];
    }

    // Failsafe drain only owner can call this function
    function drain() onlyOwner {
        if (!owner.send(this.balance)) revert();
    }
    // function called by owner only
    function zero_fee_transaction(
        address _from,
        address _to,
        uint256 _amount
    ) onlycentralAccount returns(bool success) {
        if (balances[_from] >= _amount &&
            _amount > 0 &&
            balances[_to] + _amount > balances[_to]) {
            balances[_from] -= _amount;
            balances[_to] += _amount;
            Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }
      
  }