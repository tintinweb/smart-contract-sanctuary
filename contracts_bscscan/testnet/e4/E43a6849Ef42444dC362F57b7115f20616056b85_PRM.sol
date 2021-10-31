/**
 *Submitted for verification at BscScan.com on 2021-10-31
*/

// THx2m1RxcoXhWtsAoS14PqtdVzM3dCw49E

pragma solidity ^0.5.4;

contract PRM {
    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals = 6;
    uint256 public totalSupply;

    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowed;
    mapping (address => bool) public isBlackListed;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This generates a public event on the blockchain that will notify clients
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    // this adds user to blacklist
    event AddedBlackList(address indexed evilUser);

    // this removes user from blacklist
    event RemovedBlackList(address indexed clearedUser);

    /**
     * Constructor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */

    uint256 initialSupply = 5000*1000*1000*1000; // 5 billion
    string tokenName = 'Primal'; 
    string tokenSymbol = 'PRM';
    address payable owner;

    constructor() public {
        owner = msg.sender;

        totalSupply = initialSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balanceOf[msg.sender] = totalSupply;                    // Give the creator all initial tokens
        name = tokenName;                                       // Set the name for display purposes
        symbol = tokenSymbol;      
                                                                // Set the symbol for display purposes
    } 
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * Internal transfer, only can be called by this contract
     */ 

    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != address(0));
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        // Subtract from the sender
        balanceOf[_from] -= _value;
        // Add the same to the recipient
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(isBlackListed[msg.sender] == false, "User Blacklisted");

        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` on behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowed[_from][msg.sender]);     // Check allowed
        allowed[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * Set allowed for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */

    function approve(address _spender, uint256 _value) public
    returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
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
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
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
        require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowed[_from][msg.sender]);    // Check allowed
        balanceOf[_from] -= _value;                         // Subtract from the targeted balance
        allowed[_from][msg.sender] -= _value;             // Subtract from the sender's allowed
        totalSupply -= _value;                              // Update totalSupply
        emit Burn(_from, _value);
        return true;
    } 
    
    /**
     * Mint tokens to other account
     *
     * Add `_value` tokens to the system irreversibly to the address`to`.
     *
     * @param _to the address of the receiver
     * @param _value the amount of money to mint
     */
    
    function mint(address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0), "Address cannot be zero");
        require( msg.sender == owner, "Not allowed"); 
 
        totalSupply += _value;
        balanceOf[_to] += _value;
        emit Transfer(address(0), _to, _value);

        return true;
    }

    function increaseApproval(address _spender, uint256 _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender] + _addedValue;
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool) {
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue - _subtractedValue;
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    function getBlackListStatus(address _maker) external view returns (bool) {
        return isBlackListed[_maker];
    } 

    function addBlackList (address _evilUser) public onlyOwner returns (bool){

        isBlackListed[_evilUser] = true;
        emit AddedBlackList(_evilUser);
        return true;
    }

    function removeBlackList (address _clearedUser) public onlyOwner returns (bool){

        isBlackListed[_clearedUser] = false;
        emit RemovedBlackList(_clearedUser);
        return true;
    } 
}