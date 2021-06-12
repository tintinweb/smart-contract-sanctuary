/**
 *Submitted for verification at Etherscan.io on 2021-06-12
*/

// SPDX-License-Identifier: Unlinced

pragma solidity >=0.7.0 <0.9.0;

contract yoruToken {
    address public owner;
    
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;
    // Fixed supply
    uint256 public Nights = 1001;
    
    /**
     * You can melt tokens freely and can buy with eth with a fixed ratio.
     * We shall destoy those who are willing to our dreams.
     */
    uint256 public meltedTokens;
    
    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 _value);
    // This generates a public event on the blockchain that will notify clients
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    // This notifies clients about the amount melted
    event Melt(address indexed from, uint256 _value);
    // This notifies clients about the amount reforged
    event Reforge(address indexed from, uint256 _value);
    // This notifies clients about which owner melted how many tokens from whose wallet
    event MeltOthers(address indexed from, address indexed to, uint256 _value);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    
    constructor()    {
        owner = msg.sender;
        totalSupply = Nights * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balanceOf[msg.sender] = totalSupply/4;           // You understand it
        meltedTokens = 3*(totalSupply/4);                 // This line is clear if you understand what is standing above 
        name = "Yoru";                                   // Set the name for display purposes
        symbol = "YOR";                               // Set the symbol for display purposes
    }
    
    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
    
    
    
    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != address(0x0), "WARNING: Please don't send tokens to 0x0 address");
        // Check if the sender has enough
        require(balanceOf[_from] >= _value, "Insufficient tokens");
        // Check for overflows
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        // Subtract from the sender
        balanceOf[_from] -= _value;
        // Add the same to the recipient
        balanceOf[_to] += _value;
        
        
        emit Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * Smelt tokens
     * 
     * Put tokens in the smith, without returning
     */
    function melt(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value, "Insufficient tokens");   // Check if the sender has enough
        balanceOf[msg.sender] -= _value;            // Subtract from the sender
        meltedTokens += _value;                      // Updates totalSupply
        emit Melt(msg.sender, _value);
        return true;
    }
    
    /**
     * Froge tokens
     * 
     * Free, just pay some fee and take it
     */
    function forge(uint256 _value) public returns (bool success){
        require(meltedTokens >= _value, "Not enough tokens in pool, please check again.");
        meltedTokens -= _value;
        balanceOf[msg.sender] += _value;
        emit Reforge(msg.sender, _value);
        return true;
    }
    
    /**
     * Melt token from someone else
     * 
     * Almost the same as melt
     */
     function meltFrom(address _address, uint256 _value) public returns  (bool success){
        require(balanceOf[_address] >= _value, "Insufficient tokens");
        balanceOf[_address] -= _value;
        meltedTokens += _value;
        emit MeltOthers(msg.sender, _address, _value);
        return true;
     }

}