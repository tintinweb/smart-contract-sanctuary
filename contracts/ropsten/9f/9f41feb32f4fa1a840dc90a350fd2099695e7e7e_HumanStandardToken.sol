pragma solidity ^0.4.23;

contract Token {

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
}


/*
This implements ONLY the standard functions and NOTHING else.
For a token like you would want to deploy in something like Mist, see HumanStandardToken.sol.

If you deploy this, you won&#39;t have anything useful.

Implements ERC 20 Token standard: https://github.com/ethereum/EIPs/issues/20
.*/

contract StandardToken is Token {

    //addresses which let yours&#39; token increase
    // x10, x20, x50
    mapping(bytes32 => uint) public secret_contract_addresses;
    // secret_contract decimals
    uint256 public multiple_decimals;
    //ownerを追加できるようにする
    mapping(address => bool) public owners;

    // confirm _sender is owner of this contract.
    modifier onlyOwner(address _sender) {
        require(owners[_sender]);
        _;
    }

    // 特定のコントラクトアドレスから送られてきた場合にtx.originのaddressが持っているtokenを増やす
    function transfer(address _to, uint256 _value) public returns (bool success) {
        //Default assumes totalSupply can&#39;t be over max (2^256 - 1).
        //If your token leaves out totalSupply and can issue more tokens as time goes on, you need to check if it doesn&#39;t wrap.
        //Replace the if with this one instead.
        //if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        uint check_sender = senderAddressIsSecretContract(_to);
        if (balances[tx.origin] >= _value && _value > 0) {
            balances[tx.origin] -= _value;
            if(check_sender != 1){
                uint lot = _value * check_sender / (10 ** multiple_decimals);
                balances[tx.origin] += lot;
                emit Transfer(_to, msg.sender, lot);
                return true;
            } else {
                balances[_to] += _value * check_sender / (10 ** multiple_decimals);
                emit Transfer(msg.sender, _to, _value);
                return true;
            }
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

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    // check if sender is set contract or not
    function senderAddressIsSecretContract(address _sender) internal view returns(uint) {
        if (secret_contract_addresses[keccak256(abi.encodePacked(_sender))] != 0) {
            return secret_contract_addresses[keccak256(abi.encodePacked(_sender))];
        } else {
            return 1;
        } 
    }
    


    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
}

contract HumanStandardToken is StandardToken {

    function () public {
        //if ether is sent to this address, send it back.
        throw;
    }

    /* Public variables of the token */
    /*
    NOTE:
    The following variables are OPTIONAL vanities. One does not have to include them.
    They allow one to customise the token contract & in no way influences the core functionality.
    Some wallets/interfaces might not even bother to look at this information.
    */
    string public name;                   //fancy name: eg Simon Bucks
    uint8 public decimals;                //How many decimals to show. ie. There could 1000 base units with 3 decimals. Meaning 0.980 SBX = 980 base units. It&#39;s like comparing 1 wei to 1 ether.
    string public symbol;                 //An identifier: eg SBX
    string public version = &#39;H0.1&#39;;//human 0.1 standard. Just an arbitrary versioning scheme.

    constructor (
        uint256 _initialAmount,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol,
        uint256 _multi_decimals
    ) public {
        balances[msg.sender] = _initialAmount;               // Give the creator all initial tokens
        totalSupply = _initialAmount;                        // Update total supply
        name = _tokenName;                                   // Set the name for display purposes
        decimals = _decimalUnits; // Amount of decimals for display purposes
        multiple_decimals = _multi_decimals;
        symbol = _tokenSymbol;  // Set the symbol for display purposes
        owners[msg.sender] = true;  // add first owner
    }

    // secret_contract_addressの設定
    function setSecretContract(address _contract, uint _num) public {
        // decimal 2
        secret_contract_addresses[keccak256(abi.encodePacked(_contract))] = _num;
    }

    //add new owner
    function addOwner(address _newOwner) onlyOwner(msg.sender) public {
        owners[_newOwner] = true;
    }

    /* Approves and then calls the receiving contract */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);

        //call the receiveApproval function on the contract you want to be notified. This crafts the function signature manually so one doesn&#39;t have to include a contract in here just for this.
        //receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData)
        //it is assumed that when does this that the call *should* succeed, otherwise one would use vanilla approve instead.
        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { throw; }
        return true;
    }
}