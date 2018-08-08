pragma solidity ^0.4.8;


// ERC Token Standard #20 Interface 
contract ERC20 {
    // Get the total token supply
    uint public totalSupply;
    // Get the account balance of another account with address _owner
    function balanceOf(address who) constant returns(uint256);
    // Send _value amount of tokens to address _to
    function transfer(address to, uint value) returns(bool ok);
    // Send _value amount of tokens from address _from to address _to
    function transferFrom(address from, address to, uint value) returns(bool ok);
    // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
    // If this function is called again it overwrites the current allowance with _value.
    // this function is required for some DEX functionality
    function approve(address spender, uint value) returns(bool ok);
    // Returns the amount which _spender is still allowed to withdraw from _owner
    function allowance(address owner, address spender) constant returns(uint);
    // Triggered when tokens are transferred.
    event Transfer(address indexed from, address indexed to, uint value);
    // Triggered whenever approve(address _spender, uint256 _value) is called.
    event Approval(address indexed owner, address indexed spender, uint value);

}


contract FuBi is ERC20 {

    // each address in this contract may have tokens, to define balances and store balance of each address we use mapping.
    mapping (address => uint256) balances;   
    // frozen account mapping to store account which are freeze to do anything
    mapping (address => bool) public frozenAccount; //

    //address internal owner = 0x4Bce8E9850254A86a1988E2dA79e41Bc6793640d;  

    // Owner of this contract will be the creater of the contract
    address public owner;
    // name of this contract and investment fund
    string public name = "FuBi";  
    // token symbol
    string public symbol = "Fu";  
    // decimals (for humans)
    uint8 public decimals = 6;    
    // total supply of tokens it includes 6 zeros extra to handle decimal of 6 places.
    uint256 public totalSupply = 20000000000000000;  
    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);
    // events that will notifies clints about the freezing accounts and status
    event FrozenFu(address target, bool frozen);

    mapping(address => mapping(address => uint256)) public allowance;
    
    bool flag = false;

    // modifier to authorize owner
    modifier onlyOwner()
    {
        if (msg.sender != owner) revert();
        _;
    }

    // constructor called during creation of contract
    function FuBi() { 
        owner = msg.sender;       // person who deploy the contract will be the owner of the contract
        balances[owner] = totalSupply; // balance of owner will be equal to 20000 million
        }    

    // implemented function balanceOf of erc20 to know the balnce of any account
    function balanceOf(address _owner) constant returns (uint256 balance)
    {
        return balances[_owner];
    }
    // transfer tokens from one address to another
    function transfer(address _to, uint _value) returns (bool success)
    {
         // Check send token value > 0;
        if(_value <= 0) throw;                                     
        // Check if the sender has enough
        if (balances[msg.sender] < _value) throw;                   
        // Check for overflows
        if (balances[_to] + _value < balances[_to]) throw; 
        // Subtract from the sender
        balances[msg.sender] -= _value;                             
        // Add the same to the recipient, if it&#39;s the contact itself then it signals a sell order of those tokens
        balances[_to] += _value;                                    
        // Notify anyone listening that this transfer took place               
        Transfer(msg.sender, _to, _value);                          
        return true;      
    }
    
    /* Allow another contract to spend some tokens in your behalf */
    function approve(address _spender, uint256 _value)
    returns(bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }
    // Returns the amount which _spender is still allowed to withdraw from _owner
    function allowance(address _owner, address _spender) constant returns(uint256 remaining) {
        return allowance[_owner][_spender];
    }

    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint _value) returns(bool success) {
        if (_to == 0x0) throw; // Prevent transfer to 0x0 address. Use burn() instead
        if (balances[_from] < _value) throw; // Check if the sender has enough
        if (balances[_to] + _value < balances[_to]) throw; // Check for overflows
        if (_value > allowance[_from][msg.sender]) throw; // Check allowance

        balances[_from] -= _value; // Subtract from the sender
        balances[_to] += _value; // Add the same to the recipient
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }

    // create new tokens, called only by owner, new token value supplied will be added to _to address with total supply
    function mint(address _to, uint256 _value) onlyOwner
    {
        if(!flag)
        {
        balances[_to] += _value;
    	totalSupply += _value;
        }
        else
        revert();
    }

   //owner can call this freeze function to freeze some accounts from doing certain functions
    function freeze(address target, bool freeze) onlyOwner
    {
        if(!flag)
        {
        frozenAccount[target] = freeze;
        FrozenFu(target,freeze);  
        }
        else
        revert();
    }
   // transfer the ownership to new address, called only by owner
   function transferOwnership(address to) public onlyOwner {
         owner = to;
         balances[owner]=balances[msg.sender];
         balances[msg.sender]=0;
    }
    // flag function called by ony owner, stopping some function to work for
    function turn_flag_ON() onlyOwner
    {
        flag = true;
    }
    // flag function called by owner, releasing some function to work for
    function turn_flag_OFF() onlyOwner
    {
        flag = false;
    }
    //Drain Any Ether in contract to owner
    function drain() public onlyOwner {
        if (!owner.send(this.balance)) throw;
    }
}