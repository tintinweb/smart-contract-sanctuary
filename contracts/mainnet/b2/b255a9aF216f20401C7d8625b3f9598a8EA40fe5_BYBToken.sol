pragma solidity ^0.4.21;

contract Token {

    /// @return total amount of tokens
    function totalSupply() public constant returns (uint supply);

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) public constant returns (uint balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint _value) public returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);

    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint _value) public returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) public constant returns (uint remaining);

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract RegularToken is Token {

    function transfer(address _to, uint _value) public returns (bool) {
        //Default assumes totalSupply can&#39;t be over max (2^256 - 1).
        if (balances[msg.sender] >= _value && balances[_to] + _value >= balances[_to]) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value >= balances[_to]) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            emit Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) public constant returns (uint)  {
        return balances[_owner];
    }

    function approve(address _spender, uint _value) public returns (bool) {
		allowed[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
    }

    function allowance(address _owner, address _spender) public constant returns (uint) {
        return allowed[_owner][_spender];
    }
	
    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowed;
    uint public totalSupply;
}

contract UnboundedRegularToken is RegularToken {

    uint constant MAX_UINT = 2**256 - 1;
    
    /// @dev ERC20 transferFrom, modified such that an allowance of MAX_UINT represents an unlimited amount.
    /// @param _from Address to transfer from.
    /// @param _to Address to transfer to.
    /// @param _value Amount to transfer.
    /// @return Success of transfer.
    function transferFrom(address _from, address _to, uint _value)
        public returns (bool)
    {
        uint allowance = allowed[_from][msg.sender];
        if (balances[_from] >= _value
            && allowance >= _value
            && balances[_to] + _value >= balances[_to]
        ) {
            balances[_to] += _value;
            balances[_from] -= _value;
            if (allowance < MAX_UINT) {
                allowed[_from][msg.sender] -= _value;
            }
            emit Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }
}

contract ApprovalReceiver {
    function receiveApproval(address _from, uint _value, address _tokenContract, bytes _extraData) public;
}
contract TransferReceiver {
    function receiveTransfer(address _from, uint _value, address _tokenContract, bytes _extraData) public;
}

contract BYBToken is UnboundedRegularToken {

    uint public totalSupply = 20*10**10;
    uint8 constant public decimals = 2;
    string constant public name = "Bitin Token";
    string constant public symbol = "BYB";
	address public owner;
	mapping (address => uint) public freezes;

	/* This notifies clients about the amount burnt */
    event Burn(address indexed from, uint value);
	
	/* This notifies clients about the amount frozen */
    event Freeze(address indexed from, uint value);
	
	/* This notifies clients about the amount unfrozen */
    event Unfreeze(address indexed from, uint value);
	
    function BYBToken() public {
        balances[msg.sender] = totalSupply;
		owner = msg.sender;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
	
	function totalSupply() public constant returns (uint){
		return totalSupply;
	}
    
    function burn(uint _value) public returns (bool success) {
		if (balances[msg.sender] >= _value && totalSupply - _value <= totalSupply){
			balances[msg.sender] -= _value; 								// Subtract from the sender
            totalSupply -= _value;
			emit Burn(msg.sender, _value);
			return true;
		}else {
            return false;
        }    
    }
	
	function freeze(uint _value) public returns (bool success) {
		if (balances[msg.sender] >= _value &&
		freezes[msg.sender] + _value >= freezes[msg.sender]){
			balances[msg.sender] -= _value;   				// Subtract from the sender
			freezes[msg.sender] += _value;            		// Updates totalSupply
			emit Freeze(msg.sender, _value);
			return true;
		}else {
            return false;
        }  
    }
	
	function unfreeze(uint _value) public returns (bool success) {
        if (freezes[msg.sender] >= _value &&
		balances[msg.sender] + _value >= balances[msg.sender]){
			freezes[msg.sender] -= _value;
			balances[msg.sender] += _value;
			emit Unfreeze(msg.sender, _value);
			return true;
		}else {
            return false;
        } 
    }
	
	function transferAndCall(address _to, uint _value, bytes _extraData) public returns (bool success) {
		if(transfer(_to,_value)){
			TransferReceiver(_to).receiveTransfer(msg.sender, _value, this, _extraData); 
			return true; 
		}
		else {
            return false;
        } 
    }
	
	function approveAndCall(address _spender, uint _value, bytes _extraData) public returns (bool success) {
		if(approve(_spender,_value)){
			ApprovalReceiver(_spender).receiveApproval(msg.sender, _value, this, _extraData) ;
			return true; 
		}
		else {
            return false;
        }  
    }
	
	// transfer balance to owner
	function withdrawEther(uint amount) public {
		if(msg.sender == owner){
			owner.transfer(amount);
		}
	}
	
	// can accept ether
	function() public payable {
    }
}