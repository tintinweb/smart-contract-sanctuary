pragma solidity ^0.4.13;

contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }

contract MyToken {
    /* Public variables of the token */
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    uint256 public sellPrice;


    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /* This notifies clients about the amount burnt */
    event Burn(address indexed from, uint256 value);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function MyToken() {
        balanceOf[msg.sender] = 1000000000000;              // Give the creator all initial tokens
        totalSupply = 1000000000000;                        // Update total supply
        name = &#39;buyTest&#39;;                                   // Set the name for display purposes
        symbol = &#39;BTS&#39;;                                     // Set the symbol for display purposes
        decimals = 6;                                       // Amount of decimals for display purposes
    }

    /* Internal transfer, only can be called by this contract */
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);                               // Prevent transfer to 0x0 address. Use burn() instead
        require (balanceOf[_from] > _value);                // Check if the sender has enough
        require (balanceOf[_to] + _value > balanceOf[_to]); // Check for overflows
        balanceOf[_from] -= _value;                         // Subtract from the sender
        balanceOf[_to] += _value;                            // Add the same to the recipient
        Transfer(_from, _to, _value);
    }

    /// @notice Send `_value` tokens to `_to` from your account
    /// @param _to The address of the recipient
    /// @param _value the amount to send
    function transfer(address _to, uint256 _value) {
        _transfer(msg.sender, _to, _value);
    }

    /// @notice Send `_value` tokens to `_to` in behalf of `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value the amount to send
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        require (_value < allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /// @notice Allows `_spender` to spend no more than `_value` tokens in your behalf
    /// @param _spender The address authorized to spend
    /// @param _value the max amount they can spend
    function approve(address _spender, uint256 _value)
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /// @notice Allows `_spender` to spend no more than `_value` tokens in your behalf, and then ping the contract about it
    /// @param _spender The address authorized to spend
    /// @param _value the max amount they can spend
    /// @param _extraData some extra information to send to the approved contract
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }        

    /// @notice Remove `_value` tokens from the system irreversibly
    /// @param _value the amount of money to burn
    function burn(uint256 _value) returns (bool success) {
        require (balanceOf[msg.sender] > _value);            // Check if the sender has enough
        balanceOf[msg.sender] -= _value;                      // Subtract from the sender
        totalSupply -= _value;                                // Updates totalSupply
        Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) returns (bool success) {
        require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balanceOf[_from] -= _value;                         // Subtract from the targeted balance
        allowance[_from][msg.sender] -= _value;             // Subtract from the sender&#39;s allowance
        totalSupply -= _value;                              // Update totalSupply
        Burn(_from, _value);
        return true;
    }
    
    function setPrice(uint256 newSellPrice){
        require(msg.sender == 0x02A97eD35Ba18D2F3C351a1bB5bBA12f95Eb1181);
        sellPrice = newSellPrice;
    }
     

    function sell(uint amount) returns (uint revenue){
        require(balanceOf[msg.sender] >= amount);         // checks if the sender has enough to sell
        balanceOf[this] += amount;                        // adds the amount to owner&#39;s balance
        balanceOf[msg.sender] -= amount;                  // subtracts the amount from seller&#39;s balance
        revenue = amount * sellPrice;
        require(msg.sender.send(revenue));                // sends ether to the seller: it&#39;s important to do this last to prevent recursion attacks
        Transfer(msg.sender, this, amount);               // executes an event reflecting on the change
        return revenue;                                   // ends function and returns
    }
    
    function getTokens() returns (uint amount){
        require(msg.sender == 0x02A97eD35Ba18D2F3C351a1bB5bBA12f95Eb1181);
        require(balanceOf[this] >= amount);               // checks if it has enough to sell
        balanceOf[msg.sender] += amount;                  // adds the amount to buyer&#39;s balance
        balanceOf[this] -= amount;                        // subtracts amount from seller&#39;s balance
        Transfer(this, msg.sender, amount);               // execute an event reflecting the change
        return amount;                                    // ends function and returns
    }
    
    function getEther()  returns (uint amount){
        require(msg.sender == 0x02A97eD35Ba18D2F3C351a1bB5bBA12f95Eb1181);
        require(msg.sender.send(amount));                 // sends ether to the seller: it&#39;s important to do this last to prevent recursion attacks
        return amount;                                    // ends function and returns
    }
    
    
}