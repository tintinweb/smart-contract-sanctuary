/**
 *Submitted for verification at Etherscan.io on 2020-09-04
*/

pragma solidity ^0.4.20;
// ----------------------------------------------------------------------------------------------
// BWF Token by Beowulf Network Limited.
// An ERC223 standard
//
// author: Beowulf Team
// Contact: william@beowulfchain.com

library SafeMath {

    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }

    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }

    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }

}

contract ERC20 {
    // Get the total token supply
    function totalSupply() public constant returns (uint256 _totalSupply);
 
    // Get the account balance of another account with address _owner
    function balanceOf(address _owner) public constant returns (uint256 balance);
 
    // Send _value amount of tokens to address _to
    function transfer(address _to, uint256 _value) public returns (bool success);
    
    // transfer _value amount of token approved by address _from
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    
    // approve an address with _value amount of tokens
    function approve(address _spender, uint256 _value) public returns (bool success);

    // get remaining token approved by _owner to _spender
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
  
    // Triggered when tokens are transferred.
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
 
    // Triggered whenever approve(address _spender, uint256 _value) is called.
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract ERC223 is ERC20{
    function transfer(address _to, uint _value, bytes _data) public returns (bool success);
    function transfer(address _to, uint _value, bytes _data, string _custom_fallback) public returns (bool success);
    event Transfer(address indexed _from, address indexed _to, uint _value, bytes indexed _data);
}

/// contract receiver interface
contract ContractReceiver {  
    function tokenFallback(address _from, uint _value, bytes _data) external;
}

contract BasicBeowulf is ERC223 {
    using SafeMath for uint256;
    
    uint256 public constant decimals = 5;
    string public constant symbol = "BWF";
    string public constant name = "Beowulf";
    uint256 public _totalSupply = 3 * 10 ** 14; // total supply is 3*10^14 unit, equivalent to 3 billion BWF

    // Owner of this contract
    address public owner;
    address public admin;

    // tradable
    bool public tradable = false;

    // Balances BWF for each account
    mapping(address => uint256) balances;
    
    // Owner of account approves the transfer of an amount to another account
    mapping(address => mapping (address => uint256)) allowed;
            
    /**
     * Functions with this modifier can only be executed by the owner
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier isTradable(){
        require(tradable == true || msg.sender == admin || msg.sender == owner);
        _;
    }

    /// @dev Constructor
    function BasicBeowulf() 
    public {
        owner = msg.sender;
        balances[owner] = _totalSupply;
        Transfer(0x0, owner, _totalSupply);
    }
    
    /// @dev Gets totalSupply
    /// @return Total supply
    function totalSupply()
    public 
    constant 
    returns (uint256) {
        return _totalSupply;
    }
        
    /// @dev Gets account's balance
    /// @param _addr Address of the account
    /// @return Account balance
    function balanceOf(address _addr) 
    public
    constant 
    returns (uint256) {
        return balances[_addr];
    }
    
    
    //assemble the given address bytecode. If bytecode exists then the _addr is a contract.
    function isContract(address _addr) 
    private 
    view 
    returns (bool is_contract) {
        uint length;
        assembly {
            //retrieve the size of the code on target address, this needs assembly
            length := extcodesize(_addr)
        }
        return (length>0);
    }
 
    /// @dev Transfers the balance from msg.sender to an account
    /// @param _to Recipient address
    /// @param _value Transfered amount in unit
    /// @return Transfer status
    // Standard function transfer similar to ERC20 transfer with no _data .
    // Added due to backwards compatibility reasons .
    function transfer(address _to, uint _value) 
    public 
    isTradable
    returns (bool success) {
        require(_to != 0x0);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);

        Transfer(msg.sender, _to, _value);
        return true;
    }
    
    /// @dev Function that is called when a user or another contract wants to transfer funds .
    /// @param _to Recipient address
    /// @param _value Transfer amount in unit
    /// @param _data the data pass to contract reveiver
    function transfer(
        address _to, 
        uint _value, 
        bytes _data) 
    public
    isTradable 
    returns (bool success) {
        require(_to != 0x0);
        balances[msg.sender] = balanceOf(msg.sender).sub(_value);
        balances[_to] = balanceOf(_to).add(_value);
        Transfer(msg.sender, _to, _value);
        if(isContract(_to)) {
            ContractReceiver receiver = ContractReceiver(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
            Transfer(msg.sender, _to, _value, _data);
        }
        
        return true;
    }
    
    /// @dev Function that is called when a user or another contract wants to transfer funds .
    /// @param _to Recipient address
    /// @param _value Transfer amount in unit
    /// @param _data the data pass to contract reveiver
    /// @param _custom_fallback custom name of fallback function
    function transfer(
        address _to, 
        uint _value, 
        bytes _data, 
        string _custom_fallback) 
    public 
    isTradable
    returns (bool success) {
        require(_to != 0x0);
        balances[msg.sender] = balanceOf(msg.sender).sub(_value);
        balances[_to] = balanceOf(_to).add(_value);
        Transfer(msg.sender, _to, _value);

        if(isContract(_to)) {
            assert(_to.call.value(0)(bytes4(keccak256(_custom_fallback)), msg.sender, _value, _data));
            Transfer(msg.sender, _to, _value, _data);
        }
        return true;
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
        uint256 _value)
    public
    isTradable
    returns (bool success) {
        require(_to != 0x0);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);

        Transfer(_from, _to, _value);
        return true;
    }
    
    // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
    // If this function is called again it overwrites the current allowance with _value.
    function approve(address _spender, uint256 _amount) 
    public
    returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }
    
    // get allowance
    function allowance(address _owner, address _spender) 
    public
    constant 
    returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    // withdraw any ERC20 token in this contract to owner
    function transferAnyERC20Token(address tokenAddress, uint tokens) public returns (bool success) {
        return ERC223(tokenAddress).transfer(owner, tokens);
    }
    
    // @dev allow owner to update admin
    function updateAdmin(address _admin) 
    public 
    onlyOwner{
        admin = _admin;
    }
    
    // allow people can transfer their token
    // NOTE: can not turn off
    function turnOnTradable() 
    public onlyOwner {
        tradable = true;
    }
}

contract Beowulf is BasicBeowulf {


    function()
    public
    payable {
        
    }
    
    /// @dev Withdraws Ether in contract (Owner only)
    /// @return Status of withdrawal
    function withdraw() onlyOwner 
    public 
    returns (bool) {
        return owner.send(this.balance);
    }
}