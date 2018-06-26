pragma solidity ^0.4.2;

contract ERC20Interface {

    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    // Triggered when tokens are transferred.
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    // Triggered whenever approve(address _spender, uint256 _value) is called.
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

contract Owner {
    //For storing the owner address
    address public owner;

    //Constructor for assign a address for owner property(It will be address who deploy the contract) 
    function Owner() {
        owner = msg.sender;
    }

    //This is modifier (a special function) which will execute before the function execution on which it applied 
    modifier onlyOwner() {
        if(msg.sender != owner) throw;
        //This statement replace with the code of fucntion on which modifier is applied
        _;
    }
    //Here is the example of modifier this function code replace _; statement of modifier 
    function transferOwnership(address new_owner) onlyOwner {
        owner = new_owner;
    }
}

contract RemiCoin is ERC20Interface,Owner {

    //Common information about coin
    string  public name;
    string  public symbol;
    uint8   public decimals;
    uint256 public totalSupply;
    
    //Balance property which should be always associate with an address
    mapping(address => uint256) balances;
    //frozenAccount property which should be associate with an address
    mapping (address => bool) public frozenAccount;
    // Owner of account approves the transfer of an amount to another account
    mapping(address => mapping (address => uint256)) allowed;
    
    //These generates a public event on the blockchain that will notify clients
    event FrozenFunds(address target, bool frozen);
    
    //Construtor for initial supply (The address who deployed the contract will get it) and important information
    function RemiCoin(uint256 initial_supply, string _name, string _symbol, uint8 _decimal) {
        balances[msg.sender]  = initial_supply;
        name                  = _name;
        symbol                = _symbol;
        decimals              = _decimal;
        totalSupply           = initial_supply;
    }

    // What is the balance of a particular account?
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    //Function for transer the coin from one address to another
    function transfer(address to, uint value) returns (bool success) {

        //checking account is freeze or not
        if (frozenAccount[msg.sender]) return false;

        //checking the sender should have enough coins
        if(balances[msg.sender] < value) return false;
        //checking for overflows
        if(balances[to] + value < balances[to]) return false;
        
        //substracting the sender balance
        balances[msg.sender] -= value;
        //adding the reciever balance
        balances[to] += value;
        
        // Notify anyone listening that this transfer took place
        Transfer(msg.sender, to, value);

        return true;
    }


    //Function for transer the coin from one address to another
    function transferFrom(address from, address to, uint value) returns (bool success) {

        //checking account is freeze or not
        if (frozenAccount[msg.sender]) return false;

        //checking the from should have enough coins
        if(balances[from] < value) return false;

        //checking for allowance
        if( allowed[from][msg.sender] >= value ) return false;

        //checking for overflows
        if(balances[to] + value < balances[to]) return false;
        
        balances[from] -= value;
        allowed[from][msg.sender] -= value;
        balances[to] += value;
        
        // Notify anyone listening that this transfer took place
        Transfer(from, to, value);

        return true;
    }

    //
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    //
    function approve(address _spender, uint256 _amount) returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }
    
    //
    function mintToken(address target, uint256 mintedAmount) onlyOwner{
        balances[target] += mintedAmount;
        totalSupply += mintedAmount;
        
        Transfer(0,owner,mintedAmount);
        Transfer(owner,target,mintedAmount);
    }

    //
    function freezeAccount(address target, bool freeze) onlyOwner {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

    //
    function changeName(string _name) onlyOwner {
        name = _name;
    }

    //
    function changeSymbol(string _symbol) onlyOwner {
        symbol = _symbol;
    }

    //
    function changeDecimals(uint8 _decimals) onlyOwner {
        decimals = _decimals;
    }
}