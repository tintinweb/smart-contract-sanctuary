/**
 *Submitted for verification at Etherscan.io on 2019-07-05
*/

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

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes calldata _extraData) external; }

contract TokenBase {
    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals = 0;
    uint256 public totalSupply;

    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    // This generates a public event on the blockchain that will notify clients
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    /**
     * Constructor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor() public {
        totalSupply = 1;                      // Set the initial total supply
        balanceOf[msg.sender] = totalSupply;  // Send the initial total supply to the creator the contract
        name = "Microcoin";                   // Set the name for display purposes
        symbol = "MCR";                       // Set the symbol for display purposes
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != address(0x0));
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(balanceOf[_to] + _value > balanceOf[_to]);
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
        _transfer(msg.sender, _to, _value);
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
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
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
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
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
    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, address(this), _extraData);
            return true;
        }
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
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balanceOf[_from] -= _value;                         // Subtract from the targeted balance
        allowance[_from][msg.sender] -= _value;             // Subtract from the sender&#39;s allowance
        totalSupply -= _value;                              // Update totalSupply
        emit Burn(_from, _value);
        return true;
    }
}

contract Microcoin is owned, TokenBase {
    uint256 public buyPrice;
    bool public canBuy;

    mapping (address => bool) public isPartner;
    mapping (address => uint256) public partnerMaxMint;

    /* Initializes contract with initial supply tokens to the creator of the contract */
    constructor() TokenBase() public {
        canBuy = false;
        buyPrice = 672920000000000;
    }

    /// @notice Register a new partner. (admins only)
    /// @param partnerAddress The address of the partner
    /// @param maxMint The maximum amount the partner can mint
    function registerPartner(address partnerAddress, uint256 maxMint) onlyOwner public {
        isPartner[partnerAddress] = true;
        partnerMaxMint[partnerAddress] = maxMint;
    }

    /// @notice Edit the maximum amount mintable by a partner. (admins only)
    /// @param partnerAddress The address of the partner
    /// @param maxMint The (new) maximum amount the partner can mint
    function editPartnerMaxMint(address partnerAddress, uint256 maxMint) onlyOwner public {
        partnerMaxMint[partnerAddress] = maxMint;
    }

    /// @notice Remove a partner from the system. (admins only)
    /// @param partnerAddress The address of the partner
    function removePartner(address partnerAddress) onlyOwner public {
        isPartner[partnerAddress] = false;
        partnerMaxMint[partnerAddress] = 0;
    }

    /* Internal mint, can only be called by this contract */
    function _mintToken(address target, uint256 mintedAmount, bool purchased) internal {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        emit Transfer(address(0), address(this), mintedAmount);
        emit Transfer(address(this), target, mintedAmount);
        if (purchased == true) {
            /* To prevent attacks, the equivalent amount of tokens purchased is sent to the creator of the contract. */
            balanceOf[owner] += mintedAmount;
            totalSupply += mintedAmount;
            emit Transfer(address(0), address(this), mintedAmount);
            emit Transfer(address(this), owner, mintedAmount);
        }
    }
    
    /// @notice Create `mintedAmount` tokens and send it to `target` (for partners)
    /// @param target Address to receive the tokens
    /// @param mintedAmount The amount of tokens it will receive
    function mintToken(address target, uint256 mintedAmount) public {
        require(isPartner[msg.sender] == true);
        require(partnerMaxMint[msg.sender] >= mintedAmount);
        _mintToken(target, mintedAmount, true);
    }

    /// @notice Create `mintedAmount` tokens and send it to `target` (admins only)
    /// @param target Address to receive the tokens
    /// @param mintedAmount The amount of tokens it will receive
    /// @param simulatePurchase Whether or not to treat the minted token as purchased
    function adminMintToken(address target, uint256 mintedAmount, bool simulatePurchase) onlyOwner public {
        _mintToken(target, mintedAmount, simulatePurchase);
    }

    /// @notice Allow users to buy tokens for `newBuyPrice` eth
    /// @param newBuyPrice Price users can buy from the contract
    function setPrices(uint256 newBuyPrice) onlyOwner public {
        buyPrice = newBuyPrice;
    }

    /// @notice Toggle buying tokens from the contract
    /// @param newCanBuy Whether or not users can buy tokens from the contract
    function toggleBuy(bool newCanBuy) onlyOwner public {
        canBuy = newCanBuy;
    }

    /// @notice Donate ether to the Microcoin project
    function () payable external {
        if (canBuy == true) {
            uint amount = msg.value / buyPrice;               // calculates the amount
            _mintToken(address(this), amount, true);          // mints tokens
            _transfer(address(this), msg.sender, amount);     // makes the transfers
        }
    }

    /// @notice Withdraw ether from the contract
    function withdrawEther() onlyOwner public {
        msg.sender.transfer(address(this).balance);
    }
}