pragma solidity ^0.4.19;

/**
 * ERC 20 token
 * https://github.com/ethereum/EIPs/issues/20
 */
interface Token {

    /// @return total amount of tokens
    /// function totalSupply() public constant returns (uint256 supply);
    /// do not declare totalSupply() here, see https://github.com/OpenZeppelin/zeppelin-solidity/issues/434

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) public constant returns (uint256 balance);

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
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}


/** @title PROVISIONAL SMART CONTRACT for Fluzcoin (FFC) **/

contract Fluzcoin is Token {

    string public constant name = "Fluzcoin";
    string public constant symbol = "FFC";
    uint8 public constant decimals = 18;
    uint256 public constant totalSupply = 3223000000 * 10**18;

    uint public launched = 0; // Time of locking distribution and retiring founder; 0 means not launched
    address public founder = 0xCB7ECAB8EEDd4b53d0F48E421D56fBA262AF57FC; // Founder&#39;s address
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
    
    bool public transfersAreLocked = true;

    function Fluzcoin() public {
        balances[founder] = totalSupply;
        Transfer(0x0, founder, totalSupply);
    }
    
    /**
     * Modifier to check whether transfers are unlocked or the owner is sending
     */
    modifier canTransfer() {
        require(msg.sender == founder || !transfersAreLocked);
        _;
    }
    
    /**
     * Modifier to allow only founder to transfer
     */
    modifier onlyFounder() {
        require(msg.sender == founder);
        _;
    }

    /**
     * Transfer with checking if it&#39;s allowed
     */
    function transfer(address _to, uint256 _value) public canTransfer returns (bool success) {
        if (balances[msg.sender] < _value) {
            return false;
        }
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * Transfer with checking if it&#39;s allowed
     */
    function transferFrom(address _from, address _to, uint256 _value) public canTransfer returns (bool success) {
        if (balances[_from] < _value || allowed[_from][msg.sender] < _value) {
            return false;
        }
        allowed[_from][msg.sender] -= _value;
        balances[_from] -= _value;
        balances[_to] += _value;
        Transfer(_from, _to, _value);
        return true;
    }

    /**
     * Default balanceOf function
     */
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

    /**
     * Default approval function
     */
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * Get user allowance
     */
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    /**
     * Launch and retire the founder 
     */
    function launch() public onlyFounder {
        launched = block.timestamp;
        founder = 0x0;
    }
    
    /**
     * Change transfer locking state
     */
    function changeTransferLock(bool locked) public onlyFounder {
        transfersAreLocked = locked;
    }

    function() public { // no direct purchases
        revert();
    }

}