// Modified by jjv360 for ProWallet
//
// ----------------------------------------------------------------------------------------------
// Sample fixed supply token contract
// Enjoy. (c) BokkyPooBah 2017. The MIT Licence.
// ----------------------------------------------------------------------------------------------

// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/issues/20
contract ERC20Interface {

    // Get the total token supply
    function totalSupply() constant returns (uint256 totalSupply);

    // Get the account balance of another account with address _owner
    function balanceOf(address _owner) constant returns (uint256 balance);

    // Send _value amount of tokens to address _to
    function transfer(address _to, uint256 _value) returns (bool success);

    // Send _value amount of tokens from address _from to address _to
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

    // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
    // If this function is called again it overwrites the current allowance with _value.
    // this function is required for some DEX functionality
    function approve(address _spender, uint256 _value) returns (bool success);

    // Returns the amount which _spender is still allowed to withdraw from _owner
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    // Triggered when tokens are transferred.
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    // Triggered whenever approve(address _spender, uint256 _value) is called.
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

contract ProWalletToken is ERC20Interface {

    // Variables
    string public constant symbol = "TST";
    string public constant name = "Test";
    uint8 public constant decimals = 18;
    uint256 _totalSupply = 100000000000000000000;

    // Owner of this contract
    address public owner;

    // Balances for each account
    mapping(address => uint256) balances;

    // Owner of account approves the transfer of an amount to another account
    mapping(address => mapping (address => uint256)) allowed;

    // Functions with this modifier can only be executed by the owner
    modifier onlyOwner() {
        if (msg.sender != owner) {
            throw;
        }
        _;
    }

    // Constructor. Sends all the initial tokens to the owner&#39;s account.
    function ProWalletToken() {
        owner = msg.sender;
        balances[owner] = _totalSupply;
    }

    // Returns the count of all tokens in existence
    function totalSupply() constant returns (uint256 totalSupply) {
        totalSupply = _totalSupply;
    }

    // What is the balance of a particular account?
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    // Transfer the balance from owner&#39;s account to another account
    function transfer(address _to, uint256 _amount) returns (bool success) {

        // Check if user hs enough tokens && amount to send is bigger than 0 && no buffer overflow in target account
        if (balances[msg.sender] >= _amount && _amount > 0 && balances[_to] + _amount > balances[_to]) {

            // Success, remove tokens from sender account and add to recipient account
            balances[msg.sender] -= _amount;
            balances[_to] += _amount;

            // Trigger the transfer event
            Transfer(msg.sender, _to, _amount);

            // Return success
            return true;

        } else {

            // Conditions failed
            return false;

        }

    }

    // Send _value amount of tokens from address _from to address _to
    // The transferFrom method is used for a withdraw workflow, allowing contracts to send
    // tokens on your behalf, for example to "deposit" to a contract address and/or to charge
    // fees in sub-currencies; the command should fail unless the _from account has
    // deliberately authorized the sender of the message via some mechanism; we propose
    // these standardized APIs for approval:
    function transferFrom(address _from, address _to, uint256 _amount) returns (bool success) {

        // Check if sender has enough tokens && recipient is allowed to take these tokens from the sender && amount > 0 && no buffer overflow
        if (balances[_from] >= _amount && allowed[_from][msg.sender] >= _amount && _amount > 0 && balances[_to] + _amount > balances[_to]) {

            // Success, update account balances, remove from allowed balance as well
            balances[_from] -= _amount;
            allowed[_from][msg.sender] -= _amount;
            balances[_to] += _amount;

            // Trigger transfer event
            Transfer(_from, _to, _amount);

            // Return success
            return true;

        } else {

            // Conditions failed
            return false;
        }

    }

    // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
    // If this function is called again it overwrites the current allowance with _value.
    function approve(address _spender, uint256 _amount) returns (bool success) {

        // Set the amount that _spender is allowed to take from our account
        allowed[msg.sender][_spender] = _amount;

        // Trigger approval event
        Approval(msg.sender, _spender, _amount);

        // Done
        return true;

    }

    // Returns the amount that _spender is allowed to withdraw from _owner&#39;s account
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

}