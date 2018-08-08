/*
*	BitsumCash Ethereum Token -  2018
*	https://bitsumcash.org
*	Minimal request 0.001ETH
*	1ETH is equal to 1000000BSCH
*/

pragma solidity ^0.4.4;


contract Token {

    /// @return total amount of tokens
    function totalSupply() constant returns (uint256 supply) {}

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) constant returns (uint256 balance) {}

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) returns (bool success) {}

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}

    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) returns (bool success) {}

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burn(address indexed from, uint256 value);

}

contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success){
		require(balances[msg.sender] >= _value && _value > 0);
		balances[msg.sender] -= _value;
		balances[_to] += _value;
		Transfer(msg.sender, _to, _value);
		return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success){
		require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0);
		balances[_to] += _value;
		balances[_from] -= _value;
		allowed[_from][msg.sender] -= _value;
		Transfer(_from, _to, _value);
		return true;
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
		
		require((_value == 0) || (allowed[msg.sender][_spender] == 0));//To change _value amount first go to zero
		
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
	
	uint256 public totalSupply;

}

contract BitsumCash is StandardToken { 


    string public name;
    uint8 public decimals;
    string public symbol;
    string public version = &#39;BSCH_Token_1.0&#39;; 
    uint256 public unitsOneEthCanBuy;
    uint256 public totalEthInWei;
    address public fundsWallet;
	
	uint256 public toWei = 1000000000000000000;
	uint256 public minimalPaymentInWei = 1000000000000000;//0.001ETH


	function BitsumCash() {
		decimals = 0;
		totalSupply = 17500000;
        balances[msg.sender] = 17500000;
        name = "BitsumCash";
        symbol = "BSCH";
        unitsOneEthCanBuy = 1000000;
        fundsWallet = msg.sender;
    }

    function() payable{
        totalEthInWei = totalEthInWei + msg.value;
        
		//Set minimal payment
		require(msg.value >= minimalPaymentInWei);
		
		uint256 amount = (msg.value * unitsOneEthCanBuy) / toWei;
        require(balances[fundsWallet] >= amount);

        balances[fundsWallet] = balances[fundsWallet] - amount;
        balances[msg.sender] = balances[msg.sender] + amount;

        Transfer(fundsWallet, msg.sender, amount);

        fundsWallet.transfer(msg.value);                               
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { throw; }
        return true;
    }
	
	
    /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        totalSupply -= _value;
        emit Burn(msg.sender, _value);
        return true;
    }

    /**
     * Destroy tokens from other account
     *
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balances[_from] >= _value);
        require(_value <= allowed[_from][msg.sender]);
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        totalSupply -= _value;
        emit Burn(_from, _value);
        return true;
    }
	
}