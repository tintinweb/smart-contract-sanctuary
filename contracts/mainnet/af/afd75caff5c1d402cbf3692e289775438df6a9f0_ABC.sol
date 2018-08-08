// Abstract contract for the full ERC 20 Token standard
// https://github.com/ethereum/EIPs/issues/20
pragma solidity ^0.4.18;

contract ABC {

    uint256 constant MAX_UINT256 = 2**256 - 1;

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
    string public version = &#39;ABCv1.0&#39;;       //human 0.1 standard. Just an arbitrary versioning scheme.
    address public owner;
    uint256 public totalSupply;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event FrozenFunds(address indexed _target, bool _frozen);

     function ABC(
        uint256 _initialAmount,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol
        ) public {
        balances[msg.sender] = _initialAmount;               // Give the creator all initial tokens
        totalSupply = _initialAmount;                        // Update total supply
        name = _tokenName;                                   // Set the name for display purposes
        decimals = _decimalUnits;                            // Amount of decimals for display purposes
        symbol = _tokenSymbol;                               // Set the symbol for display purposes
        owner = msg.sender;                                  // Set the first owner
        transfer(msg.sender, _initialAmount);                // Transfer the tokens to the msg.sender
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        //Verifies if the account is frozen
        require(frozenAccount[msg.sender] != true && frozenAccount[_to] != true);
        //Default assumes totalSupply can&#39;t be over max (2^256 - 1).
        //If your token leaves out totalSupply and can issue more tokens as time goes on, you need to check if it doesn&#39;t wrap.
        //Replace the if with this one instead.
        require(balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]);
        //require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        //Verifies if the account is frozen
        require(frozenAccount[_from] != true && frozenAccount[_to] != true);

        //same as above. Replace this line with the following if you want to protect against wrapping uints.
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]);
        uint256 allowance = allowed[_from][msg.sender];
        // require(balances[_from] >= _value && allowance >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) constant public returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        //Verifies if the account is frozen
        require(frozenAccount[_spender] != true);

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /* Approves and then calls the receiving contract */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        //Verifies if the account is frozen
        require(frozenAccount[_spender] != true);

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);

        //call the receiveApproval function on the contract you want to be notified. This crafts the function signature manually so one doesn&#39;t have to include a contract in here just for this.
        //receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData)
        //it is assumed when one does this that the call *should* succeed, otherwise one would use vanilla approve instead.
        require(_spender.call(bytes4(bytes32(keccak256("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData));
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    function issueNew(uint256 _issueQty) public returns (bool success) {
        require(msg.sender == owner);
        balances[owner] += _issueQty;
		totalSupply += _issueQty;
		emit Transfer(msg.sender, owner, _issueQty); 
        return true;
    }
	
	function vanishToken( uint256 _vanishQty ) public returns (bool success) {
        require(msg.sender == owner);
        require(balances[owner] >= _vanishQty);
        balances[owner] -= _vanishQty;
		totalSupply -= _vanishQty;
		emit Transfer(msg.sender, owner, _vanishQty); 
        return true;
    }

	function freezeAccount(address _target, bool _freeze) public returns (bool success) {
        require(msg.sender == owner);
        frozenAccount[_target] = _freeze;
        emit FrozenFunds(_target, _freeze);
        return true;
    }

    function transferOwnership(address _newOwner) public returns (bool success) {
        require(msg.sender == owner);
        owner = _newOwner;
        return true;
    }

    mapping (address => bool) public frozenAccount;
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}