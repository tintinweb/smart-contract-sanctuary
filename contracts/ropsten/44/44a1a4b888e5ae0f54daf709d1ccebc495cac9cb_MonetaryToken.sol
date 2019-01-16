pragma solidity ^0.4.25;

/// A Token contract with basic Ethereum functionality
contract Token {

    /// @return total amount of tokens
    function totalSupply() public constant returns (uint256 supply) {}

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) public constant returns (uint256 balance) {}

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) public returns (bool success) {}

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {}

    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) public returns (bool success) {}

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}


// Standardizes the Token contract to work with ERC20 criteria
contract StandardToken is Token {

    function transfer(address _to, uint256 _value) public returns (bool success) {
        //Default assumes totalSupply can&#39;t be over max (2^256 - 1).
        //If your token leaves out totalSupply and can issue more tokens as time goes on, you need to check if it doesn&#39;t wrap.
        //Replace the if with this one instead.
        //if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        //same as above. Replace this line with the following if you want to protect against wrapping uints.
        //if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            emit Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant public returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant public returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => bool) locked_status;
    mapping (address => string) passwords;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
    uint256 public circulatingSupply;
}


//name this contract whatever you&#39;d like
contract MonetaryToken is StandardToken {

    function () {
        //if ether is sent to this address, send it back.
        revert();
    }

    /* Public variables of the token */

    /*
    NOTE:
    The following variables are OPTIONAL vanities. One does not have to include them.
    They allow one to customize the token contract & in no way influences the core functionality.
    Some wallets/interfaces might not even bother to look at this information.
    */
    string public name;                   // fancy name: eg Simon Bucks
    uint8 public decimals;                // How many decimals to show. ie. There could 1000 base units with 3 decimals. Meaning 0.980 SBX = 980 base units. It&#39;s like comparing 1 wei to 1 ether.
    string public symbol;                 // An identifier: eg SBX
    string public version = &#39;H1.0&#39;;       // human 0.1 standard. Just an arbitrary versioning scheme.
    address private owner;                // Whoever created the original contract


    constructor() public {
        totalSupply = 1000000;                        // Update total supply (1000000 for example)
        balances[msg.sender] = totalSupply;           // Give the creator all initial tokens (100000 for example)
        circulatingSupply = 0;                        // Updates when the supply changes
        name = "Monetary Token";                      // Set the name for display purposes
        decimals = 18;                                // Amount of decimals for display purposes
        symbol = "MON";                               // Set the symbol for display purposes
        owner = msg.sender;                           // The creator is the one who owns the contract
        passwords[msg.sender] = &#39;&#39;;
        locked_status[msg.sender] = false;
    }

    /* Approves and then calls the receiving contract */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);

        //call the receiveApproval function on the contract you want to be notified. This crafts the function signature manually so one doesn&#39;t have to include a contract in here just for this.
        //receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData)
        //it is assumed that when does this that the call *should* succeed, otherwise one would use vanilla approve instead.
        if(!_spender.call(bytes4(bytes32(keccak256("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { revert(); }
        return true;
    }


    // Set the password
    function setPassword(string pass){
        passwords[msg.sender] = pass;
    }

    // lock or unlock the contract

    function lockContract(string local_pass) returns (bool success){
        if(compareStrings(passwords[msg.sender], local_pass)){
            locked_status[msg.sender] = true;
            return true;
        }
        else if(!compareStrings(passwords[msg.sender], local_pass)){
            locked_status[msg.sender] = false;
            return false;
        }
    }

    function checkLockStatus(string local_pass, address checkAddress) public view returns (bool){
        return compareStrings(passwords[checkAddress], local_pass);
    }


    // ALL BELOW THIS MAY BE DEPRICATED
    // A global structure of loans that have been opened (ERC721 Addresses)
    // Stored on the "owner" address.
    struct LoanAddresses {
        // A string array of addresses from the ERC721 blockchain
        string[] openLoans;
    }

    // Necessary for making the instance
    mapping(address => LoanAddresses) loanAccounts;

    // Addresses must be stored as strings, because they are on a different blockchain
    function appendString(string appendThis) public returns(uint length) {
        return loanAccounts[owner].openLoans.push(appendThis);
    }

    // The amount of loans that have been given for this ERC20 token
    function getLoanCount() public constant returns(uint length) {
        return loanAccounts[owner].openLoans.length;
    }

    // Makes sure only one instance of an ERC721 token exists on the ERC20 blockchain FOR A GIVEN ADDRESS
    function validLoanAddress(string checkVal) public view returns(bool valid) {
        uint256 i=0;

        for(i; i<getLoanCount(); i++){
            if (compareStrings(loanAccounts[owner].openLoans[i],checkVal)) return false;
        }

        return true;
    }

    function compareStrings(string a, string b) public pure returns (bool){
       if(keccak256(a) == &#39;&#39; || keccak256(b) == &#39;&#39;) return false;
       return keccak256(a) == keccak256(b);
   }
   
   function destruct() public{
       selfdestruct(owner);
   }
}