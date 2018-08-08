pragma solidity ^0.4.18;

/**
 * Copyright 2018, Flowchain.co
 *
 * The Flowchain tokens smart contract
 */
 
contract Mintable {
    function mintToken(address to, uint amount) external returns (bool success);  
    function setupMintableAddress(address _mintable) public returns (bool success);
}

contract ApproveAndCallReceiver {
    function receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData);    
}

contract Token {

    /// The total amount of tokens
    uint256 public totalSupply;

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

    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) public returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract StandardToken is Token {

    uint256 constant private MAX_UINT256 = 2**256 - 1;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        // Not overflow
        require(balances[_to] + _value >= balances[_to]);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        // Not overflow
        require(balances[_to] + _value >= balances[_to]);          
        balances[_to] += _value;    
        balances[_from] -= _value;
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }  

        Transfer(_from, _to, _value);
        return true; 
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }
}


//name this contract whatever you&#39;d like
contract FlowchainToken is StandardToken, Mintable {

    /* Public variables of the token */
    string public name = "FlowchainCoin";
    string public symbol = "FLC";    
    uint8 public decimals = 18;
    string public version = "1.0";
    address public mintableAddress;
    address public multiSigWallet;    
    address public creator;

    function() payable { revert(); }

    function FlowchainToken() public {
        // 1 billion tokens + 18 decimals
        totalSupply = 10**27;                   
        creator = msg.sender;
        mintableAddress = 0x9581973c54fce63d0f5c4c706020028af20ff723;
        multiSigWallet = 0x9581973c54fce63d0f5c4c706020028af20ff723;        
        // Give the multisig wallet all initial tokens
        balances[multiSigWallet] = totalSupply;  
        Transfer(0x0, multiSigWallet, totalSupply);
    }

    function setupMintableAddress(address _mintable) public returns (bool success) {
        require(msg.sender == creator);    
        mintableAddress = _mintable;
        return true;
    }

    /// @dev Mint an amount of tokens and transfer to the backer
    /// @param to The address of the backer who will receive the tokens
    /// @param amount The amount of rewarded tokens
    /// @return The result of token transfer
    function mintToken(address to, uint256 amount) external returns (bool success) {
        require(msg.sender == mintableAddress);
        require(balances[multiSigWallet] >= amount);
        balances[multiSigWallet] -= amount;
        balances[to] += amount;
        Transfer(multiSigWallet, to, amount);
        return true;
    }

    /// @dev This function makes it easy to get the creator of the tokens
    /// @return The address of token creator
    function getCreator() constant returns (address) {
        return creator;
    }

    /// @dev This function makes it easy to get the mintableAddress
    /// @return The address of token creator
    function getMintableAddress() constant returns (address) {
        return mintableAddress;
    }

    /* Approves and then calls the receiving contract */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) external returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

        //call the receiveApproval function on the contract you want to be notified. This crafts the function signature manually so one doesn&#39;t have to include a contract in here just for this.

        ApproveAndCallReceiver(_spender).receiveApproval(msg.sender, _value, this, _extraData);

        return true;
    }
}