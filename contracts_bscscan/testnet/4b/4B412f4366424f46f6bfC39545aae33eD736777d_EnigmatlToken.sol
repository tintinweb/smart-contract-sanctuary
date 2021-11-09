/**
 *Submitted for verification at BscScan.com on 2021-11-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.4.18;

contract ERC20 {
    // the total token supply
    uint256 public totalSupply;
 
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
    // Trigger when the owner resign and transfer his balance to successor.
    event TransferOfPower(address indexed _from, address indexed _to);
}
interface TokenRecipient {
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external;
}

contract ETLAuth {
    address      public  owner;
    constructor () public {
         owner = msg.sender;
    }
    
    modifier auth {
        require(isAuthorized(msg.sender) == true);
        _;
    }
    
    function isAuthorized(address src) internal view returns (bool) {
        if(src == owner){
            return true;
        } else {
            return false;
        }
    }
}

contract ETLStop is ETLAuth{

    bool public stopped;

    modifier stoppable {
        require(stopped == false);
        _;
    }
    function stop() auth internal {
        stopped = true;
    }
    function start() auth internal {
        stopped = false;
    }
}

contract Freezeable is ETLAuth{

    // internal variables
    mapping(address => bool) _freezeList;

    // events
    event Freezed(address indexed freezedAddr);
    event UnFreezed(address indexed unfreezedAddr);

    // public functions
    function freeze(address addr) auth public returns (bool) {
      require(true != _freezeList[addr]);

      _freezeList[addr] = true;

      emit Freezed(addr);
      return true;
    }

    function unfreeze(address addr) auth public returns (bool) {
      require(true == _freezeList[addr]);

      _freezeList[addr] = false;

      emit UnFreezed(addr);
      return true;
    }

    modifier whenNotFreezed(address addr) {
        require(true != _freezeList[addr]);
        _;
    }

    function isFreezing(address addr) public view returns (bool) {
        if (true == _freezeList[addr]) {
            return true;
        } else {
            return false;
        }
    }
}

contract EnigmatlTokenBase is ERC20, ETLStop, Freezeable{
    // Public variables of the token
    string public name;
    string public symbol;
    uint8  public decimals = 18;
    //address public administrator;
    // 18 decimals is the strongly suggested default, avoid changing it
    // Balances
    mapping (address => uint256) balances;
    // Allowances
    mapping (address => mapping (address => uint256)) allowances;
    //register map
    mapping (address => string)                  public  register_map;
    // ----- Events -----
    event Burn(address indexed from, uint256 value);
    event LogRegister (address indexed user, string key);
    event LogStop   ();
    /**
     * Constructor function
     */
    constructor(uint256 _initialSupply, string _tokenName, string _tokenSymbol, uint8 _decimals) public {
        name = _tokenName;                                   // Set the name for display purposes
        symbol = _tokenSymbol;                               // Set the symbol for display purposes
        decimals = _decimals;
        //owner = msg.sender;
        totalSupply = _initialSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balances[owner] = totalSupply;                // Give the creator all initial tokens
    }
    function balanceOf(address _owner) public view returns(uint256) {
        return balances[_owner];
    }
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowances[_owner][_spender];
    }
    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) whenNotFreezed(_from) internal returns(bool) {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balances[_from] >= _value);
        // Check for overflows
        require(balances[_to] + _value > balances[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balances[_from] + balances[_to];
        // Subtract from the sender
        balances[_from] -= _value;
        // Add the same to the recipient
        balances[_to] += _value;
        emit Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balances[_from] + balances[_to] == previousBalances);
        return true;
    }
    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) stoppable public returns(bool) {
        return _transfer(msg.sender, _to, _value);
    }
    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` in behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) stoppable public returns(bool) {
        require(_value <= allowances[_from][msg.sender]);     // Check allowance
        allowances[_from][msg.sender] -= _value;
        return _transfer(_from, _to, _value);
    }
    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) stoppable public returns(bool) {
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    /**
     * Set allowance for other address and notify
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf, and then ping the contract about it
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) stoppable public returns(bool) {
        if (approve(_spender, _value)) {
            TokenRecipient spender = TokenRecipient(_spender);
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
        return false;
    }
    /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) stoppable public returns(bool)  {
        require(balances[msg.sender] >= _value);   // Check if the sender has enough
        balances[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }
    
    /**
     * Mint tokens
     *
     * generate more tokens
     *
     * @param _value amount of money to mint
     */
    function mint(uint256 _value) auth stoppable public returns(bool){
        require(balances[msg.sender] + _value > balances[msg.sender]);
        require(totalSupply + _value > totalSupply);
        balances[msg.sender] += _value;
        totalSupply += _value;
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
    function burnFrom(address _from, uint256 _value) stoppable public returns(bool) {
        require(balances[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowances[_from][msg.sender]);    // Check allowance
        balances[_from] -= _value;                         // Subtract from the targeted balance
        allowances[_from][msg.sender] -= _value;             // Subtract from the sender's allowance
        totalSupply -= _value;                              // Update totalSupply
        emit Burn(_from, _value);
        return true;
    }
    /**
     * Transfer owner's power to others
     *
     * @param _to the address of the successor
     */
    function transferOfPower(address _to) auth stoppable public returns (bool) {
        require(msg.sender == owner);
        uint value = balances[msg.sender];
        _transfer(msg.sender, _to, value);
        owner = _to;
        emit TransferOfPower(msg.sender, _to);
        return true;
    }
    /**
     * approve should be called when allowances[_spender] == 0. To increment
     * allowances value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     */
    function increaseApproval(address _spender, uint _addedValue) stoppable public returns (bool) {
        // Check for overflows
        require(allowances[msg.sender][_spender] + _addedValue > allowances[msg.sender][_spender]);
        allowances[msg.sender][_spender] += _addedValue;
        emit Approval(msg.sender, _spender, allowances[msg.sender][_spender]);
        return true;
    }
    function decreaseApproval(address _spender, uint _subtractedValue) stoppable public returns (bool) {
        uint oldValue = allowances[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowances[msg.sender][_spender] = 0;
        } else {
            allowances[msg.sender][_spender] = oldValue - _subtractedValue;
        }
        emit Approval(msg.sender, _spender, allowances[msg.sender][_spender]);
        return true;
    }
}
contract EnigmatlToken is EnigmatlTokenBase {
    
    constructor() EnigmatlTokenBase(10000000000, "Enigmatl", "ETL", 18) public {}
    
    function finish() public{
        stop();
        emit LogStop();
    }
    
    function register(string key) public {
        require(bytes(key).length <= 64);
        require(balances[msg.sender] > 0);
        register_map[msg.sender] = key;
        emit LogRegister(msg.sender, key);
    }
}