pragma solidity  0.4 .21;

// ----------------------------------------------------------------------------------------------
// Sample fixed supply token contract
// Enjoy. (c) BokkyPooBah 2017. The MIT Licence.
// ----------------------------------------------------------------------------------------------

// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/issues/20
contract Token {
    // Get the total
     //token supply
    function totalSupply() constant returns(uint256 initialSupply);

    // Get the account balance of another account with address _owner
    function balanceOf(address _owner) constant returns(uint256 balance);

    // Send _value amount of tokens to address _to
    function transfer(address _to, uint256 _value) returns(bool success);

    // Send _value amount of tokens from address _from to address _to
    function transferFrom(address _from, address _to, uint256 _value) returns(bool success);

    // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
    // If this function is called again it overwrites the current allowance with _value.
    // this function is required for some DEX functionality
    function approve(address _spender, uint256 _value) returns(bool success);

    // Returns the amount which _spender is still allowed to withdraw from _owner
    function allowance(address _owner, address _spender) constant returns(uint256 remaining);

   

    //Trigger when Tokens Burned
        event Burn(address indexed from, uint256 value);


    // Triggered when tokens are transferred.
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    // Triggered whenever approve(address _spender, uint256 _value) is called.
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract AssetToken is Token {
    string public  symbol;
    string public  name;
    uint8 public  decimals;
    uint256 _totalSupply;
    address public centralAdmin;
        uint256 public soldToken;



    // Owner of this contract
    address public owner;

    // Balances for each account
    mapping(address => uint256) balances;

    // Owner of account approves the transfer of an amount to another account
    mapping(address => mapping(address => uint256)) allowed;

    // Functions with this modifier can only be executed by the owner
   modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }


    // Constructor
    function AssetToken(uint256 totalSupply,string tokenName,uint8 decimalUnits,string tokenSymbol,address centralAdmin) {
           soldToken = 0;

        if(centralAdmin != 0)
            owner = centralAdmin;
        else
        owner = msg.sender;
        balances[owner] = totalSupply;
        symbol = tokenSymbol;
        name = tokenName;
        decimals = decimalUnits;
        _totalSupply = totalSupply ;
    }
  function transferAdminship(address newAdmin) onlyOwner {
        owner = newAdmin;
    }
    function totalSupply() constant returns(uint256 initialSupply) {
        initialSupply = _totalSupply;
    }

    // What is the balance of a particular account?
    function balanceOf(address _owner) constant returns(uint256 balance) {
        return balances[_owner];
    }

     //Mint the Token 
    function mintToken(address target, uint256 mintedAmount) onlyOwner{
        balances[target] += mintedAmount;
        _totalSupply += mintedAmount;
        Transfer(0, this, mintedAmount);
        Transfer(this, target, mintedAmount);
    }

    // Transfer the balance from owner&#39;s account to another account
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
        if (balances[_from] >= _amount && allowed[_from][msg.sender] >= _amount && _amount > 0 &&
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
    //Allow the owner to burn the token from their accounts
function burn(uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);   
        balances[msg.sender] -= _value;            
        _totalSupply -= _value;                      
        Burn(msg.sender, _value);
        return true;
    }
//For calculating the sold tokens
   function transferCrowdsale(address _to, uint256 _value){
        require(balances[msg.sender] > 0);
        require(balances[msg.sender] >= _value);
        require(balances[_to] + _value >= balances[_to]);
        //if(admin)
        balances[msg.sender] -= _value;
        balances[_to] += _value;
         soldToken +=  _value;
        Transfer(msg.sender, _to, _value);
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
 

}