pragma solidity ^0.4.11;

contract owned { 
    address public owner;
    
    function owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}
contract doftManaged { 
    address public doftManager;
    
    function doftManaged() {
        doftManager = msg.sender;
    }

    modifier onlyDoftManager {
        require(msg.sender == doftManager);
        _;
    }

    function transferDoftManagment(address newDoftManager) onlyDoftManager {
        doftManager = newDoftManager;
	//coins for mining should be transferred after transferring of doftManagment
    }
}

contract ERC20 {
    function totalSupply() constant returns (uint totalSupply);
    function balanceOf(address _owner) constant returns (uint balance);
    function transfer(address _to, uint _value) returns (bool success);
    function transferFrom(address _from, address _to, uint _value) returns (bool success);
    function approve(address _spender, uint _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint remaining);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract BasicToken is ERC20 { 
    uint256 public totalSupply;
    
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

    /// @return total amount of tokens
    function totalSupply() constant returns (uint totalSupply){
        return totalSupply;
    }

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) constant returns (uint balance){
        return balanceOf[_owner];
    }

    /* Internal transfer, only can be called by this contract */
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);                               // Prevent transfer to 0x0 address. Use burn() instead
        require (balanceOf[_from] > _value);                // Check if the sender has enough
        require (balanceOf[_to] + _value > balanceOf[_to]); // Check for overflows

        balanceOf[_from] -= _value;                         // Subtract from the sender
        balanceOf[_to] += _value;                           // Add the same to the recipient
        Transfer(_from, _to, _value);
    }

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint _value) returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint _value) returns (bool success) {
        require (_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint _value) returns (bool success) {
        allowance[msg.sender][_spender] = _value;
	    Approval(msg.sender, _spender, _value);
        return true;
    }
    
    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) constant returns (uint remaining) {
        return allowance[_owner][_spender];
    }
}

contract DoftToken is BasicToken, owned, doftManaged { 
    string public name; 
    string public symbol; 
    uint256 public decimals; 
    uint256 public sellPrice;
    uint256 public buyPrice;
    uint256 public miningStorage;
    string public version; 

    event Mine(address target, uint256 minedAmount);

    function DoftToken() {
        decimals = 18;
        totalSupply = 5000000 * (10 ** decimals);  // Update total supply
        miningStorage = totalSupply / 2;
        name = "Doftcoin";                                   // Set the name for display purposes
        symbol = "DFC";                               // Set the symbol for display purposes

        balanceOf[msg.sender] = totalSupply;              // Give the creator all initial tokens
	version = "1.0";
    }

    /// @notice Create `_mintedAmount` tokens and send it to `_target`
    /// @param _target Address to receive the tokens
    /// @param _mintedAmount the amount of tokens it will receive
    function mintToken(address _target, uint256 _mintedAmount) onlyOwner {
        require (_target != 0x0);

	//ownership will be given to ICO after creation
        balanceOf[_target] += _mintedAmount;
        totalSupply += _mintedAmount;
        Transfer(0, this, _mintedAmount);
        Transfer(this, _target, _mintedAmount);
    }

    /// @notice Buy tokens from contract by sending ether
    function buy() payable {
	    require(buyPrice > 0);
        uint amount = msg.value / buyPrice;               // calculates the amount
        _transfer(this, msg.sender, amount);              // makes the transfers
    }

    /// @notice Sell `_amount` tokens to contract
    /// @param _amount Amount of tokens to be sold
    function sell(uint256 _amount) {
	    require(sellPrice > 0);
        require(this.balance >= _amount * sellPrice);      // checks if the contract has enough ether to buy
        _transfer(msg.sender, this, _amount);              // makes the transfers
        msg.sender.transfer(_amount * sellPrice);          // sends ether to the seller. It&#39;s important to do this last to avoid recursion attacks
    }

    /// @notice Allow users to buy tokens for `_newBuyPrice` eth and sell tokens for `_newSellPrice` eth
    /// @param _newSellPrice Price the users can sell to the contract
    /// @param _newBuyPrice Price users can buy from the contract
    function setPrices(uint256 _newSellPrice, uint256 _newBuyPrice) onlyDoftManager {
        sellPrice = _newSellPrice;
        buyPrice = _newBuyPrice;
    }

    /// @notice Send `_minedAmount` to `_target` as a reward for mining
    /// @param _target The address of the recipient
    /// @param _minedAmount The amount of reward tokens
    function mine(address _target, uint256 _minedAmount) onlyDoftManager {
	require (_minedAmount > 0);
        require (_target != 0x0);
        require (miningStorage - _minedAmount >= 0);
        require (balanceOf[doftManager] >= _minedAmount);                // Check if the sender has enough
        require (balanceOf[_target] + _minedAmount > balanceOf[_target]); // Check for overflows

	    balanceOf[doftManager] -= _minedAmount;
	    balanceOf[_target] += _minedAmount;
	    miningStorage -= _minedAmount;

	    Mine(_target, _minedAmount);
    } 
}