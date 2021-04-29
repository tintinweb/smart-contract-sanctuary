/**
 *Submitted for verification at Etherscan.io on 2021-04-29
*/

pragma solidity 0.5.17;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
        newOwner = address(0);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyNewOwner() {
        require(msg.sender != address(0));
        require(msg.sender == newOwner);
        _;
    }
    
    function isOwner(address account) public view returns (bool) {
        if( account == owner ){
            return true;
        }
        else {
            return false;
        }
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        newOwner = _newOwner;
    }

    function acceptOwnership() public onlyNewOwner {
        emit OwnershipTransferred(owner, newOwner);        
        owner = newOwner;
        newOwner = address(0);
    }
}

/**
 * @title Pausable
 * @dev The Pausable can pause and unpause the token transfers.
 */
contract Pausable is Ownable {
    event Paused(address account);
    event Unpaused(address account);

    bool private _paused;

    constructor () internal {
        _paused = false;
    }    

    /**
     * @return true if the contract is paused, false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() public onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() public onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

/**
 * @dev The ERC20 standard as defined in the EIP.
 */
contract Token {
    /**
     * @dev The total amount of tokens.
     */
    uint256 public totalSupply;

    /**
     * @dev Returns the amount of tokens owned by `account`.
     * @param _owner The address from which the balance will be retrieved
     * @return The balance
     */
    function balanceOf(address _owner) public view returns (uint256 balance);

    /**
     * @dev send `_value` token to `_to` from `msg.sender`
     * @param _to The address of the recipient
     * @param _value The amount of token to be transferred
     * @return Whether the transfer was successful or not
     *
     * Emits a {Transfer} event.
     */
    function transfer(address _to, uint256 _value) public returns (bool success);

    /**
     * @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value The amount of token to be transferred
     * @return Whether the transfer was successful or not
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    /**
     * @notice `msg.sender` approves `_addr` to spend `_value` tokens
     * @param _spender The address of the account able to transfer the tokens
     * @param _value The amount of wei to be approved for transfer
     * @return Whether the approval was successful or not
     */
    function approve(address _spender, uint256 _value) public returns (bool success);

    /**
     * @param _owner The address of the account owning tokens
     * @param _spender The address of the account able to transfer the tokens
     * @return Amount of remaining tokens allowed to spent
     */
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
        
        // Ensure not overflow
        require(balances[_to] + _value >= balances[_to]);
        
        balances[msg.sender] -= _value;
        balances[_to] += _value;

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        
        // Ensure not overflow
        require(balances[_to] + _value >= balances[_to]);          

        balances[_from] -= _value;
        balances[_to] += _value;

        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }  

        emit Transfer(_from, _to, _value);
        return true; 
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }
}

contract NatureDollar is StandardToken, Pausable {
    string public constant name = "NatureDollar";
    string public constant symbol = "NTD";
    uint8 public constant decimals = 18;
    uint public totalSupply = 8_000_000e18;

    event Freeze(address indexed account);
    event Unfreeze(address indexed account);

    mapping (address => bool) public frozenAccount;

    modifier notFrozen(address _account) {
        require(!frozenAccount[_account]);
        _;
    }

    constructor() public {
        balances[msg.sender] = totalSupply;  
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function transfer(address to, uint256 value) public notFrozen(msg.sender) whenNotPaused returns (bool) {
        return super.transfer(to, value);
    }   

    function transferFrom(address from, address to, uint256 value) public notFrozen(from) whenNotPaused returns (bool) {
        return super.transferFrom(from, to, value);
    }

    /**
     * @dev Freeze an user
     * @param account The address of the user who will be frozen
     * @return The result of freezing an user
     */
    function freezeAccount(address account) public onlyOwner returns (bool) {
        require(!frozenAccount[account]);
        frozenAccount[account] = true;
        emit Freeze(account);
        return true;
    }

    /**
     * @dev Unfreeze an user
     * @param account The address of the user who will be unfrozen
     * @return The result of unfreezing an user
     */
    function unfreezeAccount(address account) public onlyOwner returns (bool) {
        require(frozenAccount[account]);
        frozenAccount[account] = false;
        emit Unfreeze(account);
        return true;
    }
}