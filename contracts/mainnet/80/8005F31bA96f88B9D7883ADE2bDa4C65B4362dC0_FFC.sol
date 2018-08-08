pragma solidity ^0.4.11;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function toUINT112(uint256 a) internal pure returns(uint112) {
    assert(uint112(a) == a);
    return uint112(a);
  }

  function toUINT120(uint256 a) internal pure returns(uint120) {
    assert(uint120(a) == a);
    return uint120(a);
  }

  function toUINT128(uint256 a) internal pure returns(uint128) {
    assert(uint128(a) == a);
    return uint128(a);
  }
}

contract Owned {

    address public owner;

    function Owned() public{
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function setOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }
}

// Abstract contract for the full ERC 20 Token standard
// https://github.com/ethereum/EIPs/issues/20

contract Token {
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
    //uint256 public totalSupply;
    function totalSupply()public constant returns (uint256 supply);

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner)public constant returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value)public returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value)public returns (bool success);

    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value)public returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender)public constant returns (uint256 remaining);

}


/// FFC token, ERC20 compliant
contract FFC is Token, Owned {
    using SafeMath for uint256;

    string public constant name    = "Free Fair Chain Token";  //The Token&#39;s name
    uint8 public constant decimals = 18;               //Number of decimals of the smallest unit
    string public constant symbol  = "FFC";            //An identifier    

    // packed to 256bit to save gas usage.
    struct Supplies {
        // uint128&#39;s max value is about 3e38.
        // it&#39;s enough to present amount of tokens
        uint128 total;
    }

    Supplies supplies;

    // Packed to 256bit to save gas usage.    
    struct Account {
        // uint112&#39;s max value is about 5e33.
        // it&#39;s enough to present amount of tokens
        uint112 balance;
        // safe to store timestamp
        uint32 lastMintedTimestamp;
    }

    // Balances for each account
    mapping(address => Account) accounts;

    // Owner of account approves the transfer of an amount to another account
    mapping(address => mapping(address => uint256)) allowed;


	// 
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
	
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    // Constructor
    function FFC() public{
    	supplies.total = 1 * (10 ** 9) * (10 ** 18);
    }

    function totalSupply()public constant returns (uint256 supply){
        return supplies.total;
    }

    // Send back ether sent to me
    function ()public {
        revert();
    }

    // If sealed, transfer is enabled 
    function isSealed()public constant returns (bool) {
        return owner == 0;
    }
    
    function lastMintedTimestamp(address _owner)public constant returns(uint32) {
        return accounts[_owner].lastMintedTimestamp;
    }

    // What is the balance of a particular account?
    function balanceOf(address _owner)public constant returns (uint256 balance) {
        return accounts[_owner].balance;
    }

    // Transfer the balance from owner&#39;s account to another account
    function transfer(address _to, uint256 _amount)public returns (bool success) {
        require(isSealed());
		
        // according to FFC&#39;s total supply, never overflow here
        if ( accounts[msg.sender].balance >= _amount && _amount > 0) {            
            accounts[msg.sender].balance -= uint112(_amount);
            accounts[_to].balance = _amount.add(accounts[_to].balance).toUINT112();
            emit Transfer(msg.sender, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

    // Send _value amount of tokens from address _from to address _to
    // The transferFrom method is used for a withdraw workflow, allowing contracts to send
    // tokens on your behalf, for example to "deposit" to a contract address and/or to charge
    // fees in sub-currencies; the command should fail unless the _from account has
    // deliberately authorized the sender of the message via some mechanism; we propose
    // these standardized APIs for approval:
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    )public returns (bool success) {
        require(isSealed());

        // according to FFC&#39;s total supply, never overflow here
        if (accounts[_from].balance >= _amount
            && allowed[_from][msg.sender] >= _amount
            && _amount > 0) {
            accounts[_from].balance -= uint112(_amount);
            allowed[_from][msg.sender] -= _amount;
            accounts[_to].balance = _amount.add(accounts[_to].balance).toUINT112();
            emit Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

    // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
    // If this function is called again it overwrites the current allowance with _value.
    function approve(address _spender, uint256 _amount)public returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    /* Approves and then calls the receiving contract */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);

        //call the receiveApproval function on the contract you want to be notified. This crafts the function signature manually so one doesn&#39;t have to include a contract in here just for this.
        //receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData)
        //it is assumed that when does this that the call *should* succeed, otherwise one would use vanilla approve instead.
        //if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { revert(); }
        ApprovalReceiver(_spender).receiveApproval(msg.sender, _value, this, _extraData);
        return true;
    }

    function allowance(address _owner, address _spender)public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    function mint0(address _owner, uint256 _amount)public onlyOwner {
    		accounts[_owner].balance = _amount.add(accounts[_owner].balance).toUINT112();

        accounts[_owner].lastMintedTimestamp = uint32(block.timestamp);

        //supplies.total = _amount.add(supplies.total).toUINT128();
        emit Transfer(0, _owner, _amount);
    }
    
    // Mint tokens and assign to some one
    function mint(address _owner, uint256 _amount, uint32 timestamp)public onlyOwner{
        accounts[_owner].balance = _amount.add(accounts[_owner].balance).toUINT112();

        accounts[_owner].lastMintedTimestamp = timestamp;

        supplies.total = _amount.add(supplies.total).toUINT128();
        emit Transfer(0, _owner, _amount);
    }

    // Set owner to zero address, to disable mint, and enable token transfer
    function seal()public onlyOwner {
        setOwner(0);
    }
}

contract ApprovalReceiver {
    function receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData)public;
}