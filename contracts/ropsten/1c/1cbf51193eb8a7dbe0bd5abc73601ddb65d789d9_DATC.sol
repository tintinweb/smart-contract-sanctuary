pragma solidity ^0.4.16;

contract Owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

interface tokenRecipient {
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external;
}

library Addresses {
    function isContract(address _base) internal view returns (bool) {
        uint codeSize;
        assembly { codeSize := extcodesize(_base) }
        return codeSize > 0;
    }
}

library SafeMath {
    function sub(uint _base, uint _value) internal pure returns (uint) {
        assert(_value <= _base);
        return _base - _value;
    }

    function add(uint _base, uint _value) internal pure returns (uint _ret) {
        _ret = _base + _value;
        assert(_ret >= _base);
    }

    function div(uint _base, uint _value) internal pure returns (uint) {
        assert(_value > 0 && (_base % _value) == 0);
        return _base / _value;
    }

    function mul(uint _base, uint _value) internal pure returns (uint _ret) {
        _ret = _base * _value;
        assert(0 == _base || _ret / _base == _value);
    }
}

interface ERC20 {
    function transferFrom(address _from, address _to, uint _value) public returns (bool);

    function approve(address _spender, uint _value) public returns (bool);

    function allowance(address _owner, address _spender) public view returns (uint);

    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

interface ERC223 {
    function transfer(address _to, uint _value, bytes _data) public returns (bool);

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
}

contract ERC223ReceivingContract {
    function tokenFallback(address _from, uint _value, bytes _data) public;
}

contract TokenERC is ERC20, ERC223, Owned {

    using SafeMath for uint;
    using Addresses for address;

    // Public variables of the token
    string public name;
    string public symbol;
    // 18 decimals is the strongly suggested default, avoid changing it
    uint8 public decimals = 18;

    uint256 public totalSupply;

    /* This notifies clients about the amount burnt */
    event Burn(address indexed from, uint256 value);

    // This creates an array with all balances
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public _allowances;

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor(uint256 initialSupply, string tokenName, string tokenSymbol ) public {
        totalSupply = initialSupply.mul(10 ** uint256(decimals));
        // Update total supply with the decimal amount
        balanceOf[msg.sender] = totalSupply;
        // Give the creator all initial tokens
        name = tokenName;
        // Set the name for display purposes
        symbol = tokenSymbol;
        // Set the symbol for display purposes
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value, bytes _data) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(balanceOf[_to].add(_value) > balanceOf[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from].add(balanceOf[_to]);

        if (_to.isContract()) {
            ERC223ReceivingContract _contract = ERC223ReceivingContract(_to);
            _contract.tokenFallback(msg.sender, _value, _data);
        }

        // Subtract from the sender
        balanceOf[_from]= balanceOf[_from].sub(_value);
        // Add the same to the recipient
        balanceOf[_to] = balanceOf[_to].add(_value);

        emit Transfer(_from, _to, _value, _data);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from].add(balanceOf[_to]) == previousBalances);
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public returns (bool) {
        _transfer(msg.sender, _to, _value, &quot;&quot;);
        return true;
    }
    
    function transfer(address _to, uint256 _value, bytes _data) public returns (bool) {
        _transfer(msg.sender, _to, _value, _data);
        return true;
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
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        return transferFrom(_from, _to, _value, &quot;&quot;);
    }

    function transferFrom(address _from, address _to, uint _value, bytes _data) public returns (bool) {
        require(_value <= _allowances[_from][msg.sender]);
        // Check allowance
        _allowances[_from][msg.sender] = _allowances[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value, _data);
        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public returns (bool) {
        _allowances[msg.sender][_spender] = _value;
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
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool) {
        tokenRecipient spender = tokenRecipient(_spender);
        require(approve(_spender, _value));
        spender.receiveApproval(msg.sender, _value, this, _extraData);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint) {
        if (_allowances[_owner][_spender] < balanceOf[_owner]) {
            return _allowances[_owner][_spender];
        }
        return balanceOf[_owner];
    }

    /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) public returns (bool) {
        require(balanceOf[msg.sender] >= _value);
        // Check if the sender has enough
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        // Subtract from the sender
        totalSupply = totalSupply.sub(_value);
        // Updates totalSupply
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
    function burnFrom(address _from, uint256 _value) public returns (bool) {
        require(balanceOf[_from] >= _value);
        // Check if the targeted balance is enough
        require(_value <= _allowances[_from][msg.sender]);
        // Check allowance
        balanceOf[_from] = balanceOf[_from].sub(_value);
        // Subtract from the targeted balance
        _allowances[_from][msg.sender] = _allowances[_from][msg.sender].sub(_value);
        // Subtract from the sender&#39;s allowance
        totalSupply = totalSupply.sub(_value);
        // Update totalSupply
        emit Burn(_from, _value);
        return true;
    }
}

contract DATC is TokenERC {

    uint256 public sellPrice;
    uint256 public buyPrice;

    mapping(address => bool) public frozenAccount;

    /* This generates a public event on the blockchain that will notify clients */
    event FrozenFunds(address target, bool frozen);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    constructor(uint256 initialSupply, string tokenName, string tokenSymbol) TokenERC(initialSupply, tokenName, tokenSymbol) public {}

    /* Internal transfer, only can be called by this contract */
    function _transfer(address _from, address _to, uint _value, bytes _data) internal {
        require (_to != 0x0);                               // Prevent transfer to 0x0 address. Use burn() instead
        require (balanceOf[_from] >= _value);               // Check if the sender has enough
        require (balanceOf[_to].add(_value) >= balanceOf[_to]); // Check for overflows
        require(!frozenAccount[_from]);                     // Check if sender is frozen
        require(!frozenAccount[_to]);                       // Check if recipient is frozen

        if (_to.isContract()) {
            ERC223ReceivingContract _contract = ERC223ReceivingContract(_to);
            _contract.tokenFallback(msg.sender, _value, _data);
        }

        balanceOf[_from] = balanceOf[_from].sub(_value);                         // Subtract from the sender
        balanceOf[_to] = balanceOf[_to].add(_value);                           // Add the same to the recipient
        emit Transfer(_from, _to, _value, _data);
    }

    /// @notice Create `mintedAmount` tokens and send it to `target`
    /// @param target Address to receive the tokens
    /// @param mintedAmount the amount of tokens it will receive
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        balanceOf[target] = balanceOf[target].add(mintedAmount);
        totalSupply = totalSupply.add(mintedAmount);
        emit Transfer(0, this, mintedAmount, &quot;&quot;);
        emit Transfer(this, target, mintedAmount, &quot;&quot;);
    }

    /// @notice `freeze? Prevent | Allow` `target` from sending & receiving tokens
    /// @param target Address to be frozen
    /// @param freeze either to freeze it or not
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

    /// @notice Allow users to buy tokens for `newBuyPrice` eth and sell tokens for `newSellPrice` eth
    /// @param newSellPrice Price the users can sell to the contract
    /// @param newBuyPrice Price users can buy from the contract
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner public {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }

    /// @notice Buy tokens from contract by sending ether
    function buy() payable public {
        uint amount = msg.value.div(buyPrice);
        // calculates the amount
        _transfer(this, msg.sender, amount, &quot;&quot;);
        // makes the transfers
    }

    /// @notice Sell `amount` tokens to contract
    /// @param amount amount of tokens to be sold
    function sell(uint256 amount) public {
        address myAddress = this;
        require(myAddress.balance >= amount.mul(sellPrice));
        // checks if the contract has enough ether to buy
        _transfer(msg.sender, this, amount, &quot;&quot;);
        // makes the transfers
        msg.sender.transfer(amount.mul(sellPrice));
        // sends ether to the seller. It&#39;s important to do this last to avoid recursion attacks
    }

}