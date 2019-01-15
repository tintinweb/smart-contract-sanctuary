/**
* The Carmen Token contract bases on the ERC20 standard token contracts
* Founders: Penthora Foundation, Anakatier Group PCL and Kirimanya Holding
*/

pragma solidity ^0.4.25;


library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
}


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


contract Authorizable is owned {

    struct Authoriz{
        uint index;
        address account;
    }
    
    mapping(address => bool) public authorized;
    mapping(address => Authoriz) public authorizs;
    address[] public authorizedAccts;

    modifier onlyAuthorized() {
        if(authorizedAccts.length >0)
        {
            require(authorized[msg.sender] == true || owner == msg.sender);
            _;
        }else{
            require(owner == msg.sender);
            _;
        }
     
    }

    function addAuthorized(address _toAdd) 
        onlyOwner 
        public 
    {
        require(_toAdd != 0);
        require(!isAuthorizedAccount(_toAdd));
        authorized[_toAdd] = true;
        Authoriz storage authoriz = authorizs[_toAdd];
        authoriz.account = _toAdd;
        authoriz.index = authorizedAccts.push(_toAdd) -1;
    }

    function removeAuthorized(address _toRemove) 
        onlyOwner 
        public 
    {
        require(_toRemove != 0);
        require(_toRemove != msg.sender);
        authorized[_toRemove] = false;
    }
    
    function isAuthorizedAccount(address account) 
        public 
        constant 
        returns(bool isIndeed) 
    {
        if(account == owner) return true;
        if(authorizedAccts.length == 0) return false;
        return (authorizedAccts[authorizs[account].index] == account);
    }

}


interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract TokenERC20 {
    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    // 18 decimals is the strongly suggested default, avoid changing it
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
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balanceOf[msg.sender] = totalSupply;                // Give the creator all initial tokens
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
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
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
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
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
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


/******************************************/
/* Carmen Token STARTS HERE               */
/******************************************/

contract CarmenToken is Authorizable, TokenERC20 {

    using SafeMath for uint256;
    
    /// Maximum tokens to be allocated on the sale
    uint256 public tokenSaleHardCap;
    /// Base exchange rate is set to 1 ETH = XCR.
    uint256 public baseRate;

   /// no tokens can be ever issued when this is set to "true"
    bool public tokenSaleClosed = false;

    mapping (address => bool) public frozenAccount;

    /* This generates a public event on the blockchain that will notify clients */
    event FrozenFunds(address target, bool frozen);

    modifier inProgress {
        require(totalSupply < tokenSaleHardCap
            && !tokenSaleClosed);
        _;
    }

    modifier beforeEnd {
        require(!tokenSaleClosed);
        _;
    }

    /* Initializes contract with initial supply tokens to the creator of the contract */
    constructor(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) TokenERC20(initialSupply, tokenName, tokenSymbol) public {
        tokenSaleHardCap = 121000000 * 10**uint256(decimals); // Default Crowsale Hard Cap amount with decimals
        baseRate = 100 * 10**uint256(decimals); // Default base rate XCR :1 eth amount with decimals
    }

    /// @dev This default function allows token to be purchased by directly
    /// sending ether to this smart contract.
    function () public payable {
       purchaseTokens(msg.sender);
    }
    
    /// @dev Issue token based on Ether received.
    /// @param _beneficiary Address that newly issued token will be sent to.
    function purchaseTokens(address _beneficiary) public payable inProgress{
        // only accept a minimum amount of ETH?
        require(msg.value >= 0.01 ether);

        uint _tokens = computeTokenAmount(msg.value); 
        doIssueTokens(_beneficiary, _tokens);
        /// forward the raised funds to the contract creator
        owner.transfer(address(this).balance);
    }
    
    /* Internal transfer, only can be called by this contract */
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);                               // Prevent transfer to 0x0 address. Use burn() instead
        require (balanceOf[_from] >= _value);               // Check if the sender has enough
        require (balanceOf[_to] + _value >= balanceOf[_to]); // Check for overflows
        require(!frozenAccount[_from]);                     // Check if sender is frozen
        require(!frozenAccount[_to]);                       // Check if recipient is frozen
        balanceOf[_from] -= _value;                         // Subtract from the sender
        balanceOf[_to] += _value;                           // Add the same to the recipient
        emit Transfer(_from, _to, _value);
    }

    /// @notice Create `mintedAmount` tokens and send it to `target`
    /// @param target Address to receive the tokens
    /// @param mintedAmount the amount of tokens it will receive
    function mintToken(address target, uint256 mintedAmount) onlyAuthorized public {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        emit Transfer(0, this, mintedAmount);
        emit Transfer(this, target, mintedAmount);
    }

    /// @notice `freeze? Prevent | Allow` `target` from sending & receiving tokens
    /// @param target Address to be frozen
    /// @param freeze either to freeze it or not
    function freezeAccount(address target, bool freeze) onlyAuthorized public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

    /// @notice Allow users to buy tokens for `newRatePrice` eth 
    /// @param newRate Price the users can sell to the contract
    function setRatePrices(uint256 newRate) onlyAuthorized public {
        baseRate = newRate;
    }

    /// @notice Allow users to buy tokens for `newTokenSaleHardCap` XCR 
    /// @param newTokenSaleHardCap Amount of XCR token sale hard cap
    function setTokenSaleHardCap(uint256 newTokenSaleHardCap) onlyAuthorized public {
        tokenSaleHardCap = newTokenSaleHardCap;
    }

    function doIssueTokens(address _beneficiary, uint256 _tokens) internal {
        require(_beneficiary != address(0));
        balanceOf[_beneficiary] += _tokens;
        totalSupply += _tokens;
        emit Transfer(0, this, _tokens);
        emit Transfer(this, _beneficiary, _tokens);
    }

    /// @dev Compute the amount of XCR token that can be purchased.
    /// @param ethAmount Amount of Ether in WEI to purchase XCR.
    /// @return Amount of XCR token to purchase
    function computeTokenAmount(uint256 ethAmount) internal view returns (uint256) {
        uint256 tokens = ethAmount.mul(baseRate) / 10**uint256(decimals);
        return tokens;
    }

    /// @notice collect ether to owner account
    function collect() external onlyAuthorized {
        owner.transfer(address(this).balance);
    }

    /// @notice getBalance ether
    function getBalance() public view onlyAuthorized returns (uint) {
        return address(this).balance;
    }

    /// @dev Closes the sale, issues the team tokens and burns the unsold
    function close() public onlyAuthorized beforeEnd {
        tokenSaleClosed = true;
        /// forward the raised funds to the contract creator
        owner.transfer(address(this).balance);
    }

    /// @dev Open the sale status
    function openSale() public onlyAuthorized{
        tokenSaleClosed = false;
    }

}