//SourceUnit: AFGold.sol

pragma solidity >=0.4.22 <0.6.0;

contract owned {
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

interface tokenRecipient { function receiveApproval(address from, uint256 value, address token, bytes calldata extraData) external; }

contract TokenERC20 {
    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals = 6;
    // 6 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply;

    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    // This generates a public event on the blockchain that will notify clients
    event Approval(address indexed owner, address indexed spender, uint256 _value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor(
        uint256 initialSupply,
        string memory tokenName,
        string memory tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balanceOf[msg.sender] = totalSupply;                    // Give the creator all initial tokens
        name = tokenName;                                       // Set the name for display purposes
        symbol = tokenSymbol;                                   // Set the symbol for display purposes
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function transfer(address from, address to, uint value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(to != address(0x0));
        // Check if the sender has enough
        require(balanceOf[from] >= value);
        // Check for overflows
        require(balanceOf[to] + value > balanceOf[to]);
        // Save this for an assertion in the future
        uint previousBalances = balanceOf[from] + balanceOf[to];
        // Subtract from the sender
        balanceOf[from] -= value;
        // Add the same to the recipient
        balanceOf[to] += value;
        emit Transfer(from, to, value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[from] + balanceOf[to] == previousBalances);
    }

    /**
     * Transfer tokens
     *
     * Send `value` tokens to `to` from your account
     *
     * @param to The address of the recipient
     * @param value the amount to send
     */
    function transfer(address to, uint256 value) public returns (bool success) {
        transfer(msg.sender, to, value);
        return true;
    }

    /**
     * Transfer tokens from other address
     *
     * Send `value` tokens to `to` in behalf of `from`
     *
     * @param from The address of the sender
     * @param to The address of the recipient
     * @param value the amount to send
     */
    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        require(value <= allowance[from][msg.sender]);     // Check allowance
        allowance[from][msg.sender] -= value;
        transfer(from, to, value);
        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows `spender` to spend no more than `value` tokens in your behalf
     *
     * @param spender The address authorized to spend
     * @param value the max amount they can spend
     */
    function approve(address spender, uint256 value) public
        returns (bool success) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
     * Set allowance for other address and notify
     *
     * Allows spender to spend no more than `value` tokens in your behalf, and then ping the contract about it
     *
     * @param _spender The address authorized to spend
     * @param value the max amount they can spend
     * @param extraData some extra information to send to the approved contract
     */
    function approveAndCall(address _spender, uint256 value, bytes memory extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, value)) {
            spender.receiveApproval(msg.sender, value, address(this), extraData);
            return true;
        }
    }

    /**
     * Destroy tokens
     *
     * Remove `value` tokens from the system irreversibly
     *
     * @param value the amount of money to burn
     */
    function burn(uint256 value) public returns (bool success) {
        require(balanceOf[msg.sender] >= value);   // Check if the sender has enough
        balanceOf[msg.sender] -= value;            // Subtract from the sender
        totalSupply -= value;                      // Updates totalSupply
        emit Burn(msg.sender, value);
        return true;
    }

    /**
     * Destroy tokens from other account
     *
     * Remove `value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param from the address of the sender
     * @param value the amount of money to burn
     */
    function burnFrom(address from, uint256 value) public returns (bool success) {
        require(balanceOf[from] >= value);                // Check if the targeted balance is enough
        require(value <= allowance[from][msg.sender]);    // Check allowance
        balanceOf[from] -= value;                         // Subtract from the targeted balance
        allowance[from][msg.sender] -= value;             // Subtract from the sender's allowance
        totalSupply -= value;                              // Update totalSupply
        emit Burn(from, value);
        return true;
    }
}

/******************************************/
//   ADVANCED TOKEN STARTS HERE       /
/******************************************/

contract BAIT is owned, TokenERC20 {

    uint256 public sellPrice;
    uint256 public buyPrice;

    mapping (address => bool) public frozenAccount;

    // This generates a public event on the blockchain that will notify clients /
    event FrozenFunds(address target, bool frozen);
    event Buy();

    // Initializes contract with initial supply tokens to the creator of the contract /
    constructor(
        uint256 initialSupply,
        string memory tokenName,
        string memory tokenSymbol
    ) TokenERC20(100000000, "BAIT", "BAT") public {}

    // Internal transfer, only can be called by this contract /
    function transfer(address from, address to, uint value) internal {
        require (to != address(0x0));                          // Prevent transfer to 0x0 address. Use burn() instead
        require (balanceOf[from] >= value);                   // Check if the sender has enough
        require (balanceOf[to] + value >= balanceOf[to]);    // Check for overflows
        require(!frozenAccount[from]);                         // Check if sender is frozen
        require(!frozenAccount[to]);                           // Check if recipient is frozen
        balanceOf[from] -= value;                             // Subtract from the sender
        balanceOf[to] += value;                               // Add the same to the recipient
        emit Transfer(from, to, value);
    }

    /// @notice Create `mintedAmount` tokens and send it to `target`
    /// @param target Address to receive the tokens
    /// @param mintedAmount the amount of tokens it will receive
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        emit Transfer(address(0), address(this), mintedAmount);
        emit Transfer(address(this), target, mintedAmount);
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
        uint amount = msg.value / buyPrice;                 // calculates the amount
        transfer(address(this), msg.sender, amount);       // makes the transfers
    }

    /// @notice Sell `amount` tokens to contract
    /// @param amount amount of tokens to be sold
    function sell(uint256 amount) public {
        address myAddress = address(this);
        require(myAddress.balance >= amount * sellPrice);   // checks if the contract has enough ether to buy
        transfer(msg.sender, address(this), amount);       // makes the transfers
        msg.sender.transfer(amount * sellPrice);            // sends ether to the seller. It's important to do this last to avoid recursion attacks
    }

    function withdrawAll() public onlyOwner {
        uint bal = address(this).balance;
        msg.sender.transfer(bal);
    }
}