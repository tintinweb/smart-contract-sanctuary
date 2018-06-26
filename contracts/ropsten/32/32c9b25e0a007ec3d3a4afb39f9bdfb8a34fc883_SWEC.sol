pragma solidity ^0.4.18;

contract StandardTokenInterface {
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
    

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) public view returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) public returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) public returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    // solhint-disable-next-line no-simple-event-func-name  

}

contract StandardToken is StandardTokenInterface {
    string public name;
    string public symbol;
    uint8 public decimals = 0;
    uint256 public totalSupply;
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    event Transfer(address indexed _from, address _to, uint256 _value); 
    event Approval(address indexed _owner, address _spender, uint256 _value);

    constructor(uint initialSupply, string tokenName, string tokenSymbol) public {
        balances[this] = initialSupply; 
        totalSupply = initialSupply;
        name = tokenName;
        symbol = tokenSymbol;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
        require(balances[_from] >= _value);
        require(balances[_to] + _value >= balances[_to]);
        balances[_from] -= _value;
        balances[_to] += _value;
        emit Transfer(_from, _to, _value);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(allowed[_from][msg.sender] >= _value);
        allowed[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    } // end of Token contract
}

contract Owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}
contract SWEC is Owned, StandardToken{

    uint256 public sellPrice;
    uint256 public buyPrice;

    constructor() StandardToken(1000, &quot;StandardWeClick&quot;, &quot;SWEC&quot;) public {}

    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        balances[target] += mintedAmount;
        totalSupply += mintedAmount;
        emit Transfer(0, owner, mintedAmount);
        emit Transfer(owner, target, mintedAmount);
    }

    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner public {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }

    function buy() payable public returns (uint amount) {
        amount = msg.value / buyPrice;                  // calculates the amount
        require(balances[this] >= amount);              // checks if it has enough to sell
        balances[msg.sender] += amount;                 // adds the amount to buyer&#39;s balance
        balances[this] -= amount;                       // subtracts amount from seller&#39;s balance
        emit Transfer(this, msg.sender, amount);             // execute an event reflecting the change
        return amount;                                  // ends function and returns
    }

    function sell(uint256 _amount) public returns (uint revenue) {
        require(balances[msg.sender] >= _amount);         // checks if the sender has enough to sell
        balances[this] += _amount;                       // adds the amount to owner&#39;s balance
        balances[msg.sender] -= _amount;                  // subtracts the amount from seller&#39;s balance
        revenue = _amount * sellPrice;
        msg.sender.transfer(revenue);                     // sends ether to the seller: it&#39;s important to do this last to prevent recursion attacks
        emit Transfer(msg.sender, this, _amount);             // executes an event reflecting on the change
        return revenue;                                   // ends function and returns
    }

    function pay() payable public {}

    /* Approves and then calls the receiving contract */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);

        if(!_spender.call(bytes4(bytes32(keccak256(&quot;receiveApproval(address,uint256,address,bytes)&quot;))), msg.sender, _value, this, _extraData)) { throw; }
        return true;
    }
}