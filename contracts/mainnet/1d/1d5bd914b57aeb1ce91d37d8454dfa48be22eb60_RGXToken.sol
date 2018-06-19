contract Token {
    /* This is a slight change to the ERC20 base standard.
    function totalSupply() constant returns (uint256 supply);
    is replaced with:
    uint256 public totalSupply;
    This automatically creates a getter function for the totalSupply.
    This is moved to the base contract since public getter functions are not
    currently recognised as an implementation of the matching abstract
    function by the compiler.
    */
    /// total amount of tokens
    uint256 public totalSupply;

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) constant returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
        //Default assumes totalSupply can&#39;t be over max (2^256 - 1).
        //If your token leaves out totalSupply and can issue more tokens as time goes on, you need to check if it doesn&#39;t wrap.
        //Replace the if with this one instead.
        //if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        //same as above. Replace this line with the following if you want to protect against wrapping uints.
        //if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

/*

  Contract to implement ERC20 tokens for the crowdfunding of the Rouge Project (RGX tokens).
  They are based on StandardToken from (https://github.com/ConsenSys/Tokens).

  Differences with standard ERC20 tokens :

   - The tokens can be bought by sending ether to the contract address (funding procedure).
     The price is hardcoded: 1 token = 1 finney (0.001 eth).

   - The funding can only occur if the current date is superior to the startFunding parameter timestamp.
     At anytime, the creator can change this token parameter, effectively closing the funding.

   - The owner can also freeze part of his tokens to not be part of the funding procedure.

   - At the creation, a discountMultiplier is saved which can be used later on 
     by other contracts (eg to use the tokens as a voucher).

*/

contract RGXToken is StandardToken {
    
    /* ERC20 */
    string public name;
    string public symbol;
    uint8 public decimals = 0;
    string public version = &#39;v0.9&#39;;
    
    /* RGX */
    address owner; 
    uint public fundingStart;
    uint256 public frozenSupply = 0;
    uint8 public discountMultiplier;
    
    modifier fundingOpen() {
        require(now >= fundingStart);
        _;
    }
    
    modifier onlyBy(address _account) {
        require(msg.sender == _account);
        _;
    }
    
    function () payable fundingOpen() { 

        require(msg.sender != owner);
        
        uint256 _value = msg.value / 1 finney;
        
        require(balances[owner] >= (_value - frozenSupply) && _value > 0); 
        
        balances[owner] -= _value;
        balances[msg.sender] += _value;
        Transfer(owner, msg.sender, _value);
        
    }
    
    function RGXToken (
                       string _name,
                       string _symbol,
                       uint256 _initialAmount,
                       uint _fundingStart,
                       uint8 _discountMultiplier
                       ) {
        name = _name;
        symbol = _symbol;
        owner = msg.sender;
        balances[msg.sender] = _initialAmount;               // Give the creator all initial tokens
        totalSupply = _initialAmount;                        // Update total supply
        fundingStart = _fundingStart;                        // timestamp before no funding can occur
        discountMultiplier = _discountMultiplier;
    }
    
    function isFundingOpen() constant returns (bool yes) {
        return (now >= fundingStart);
    }
    
    function freezeSupply(uint256 _value) onlyBy(owner) {
        require(balances[owner] >= _value);
        frozenSupply = _value;
    }
    
    function timeFundingStart(uint _fundingStart) onlyBy(owner) {
        fundingStart = _fundingStart;
    }

    function withdraw() onlyBy(owner) {
        msg.sender.transfer(this.balance);
    }
    
    function kill() onlyBy(owner) {
        selfdestruct(owner);
    }

}
/*
You should inherit from StandardToken or, for a token like you would want to
deploy in something like Mist, see HumanStandardToken.sol.
(This implements ONLY the standard functions and NOTHING else.
If you deploy this, you won&#39;t have anything useful.)

Implements ERC 20 Token standard: https://github.com/ethereum/EIPs/issues/20
.*/