pragma solidity ^0.4.18;


/**
* @title SafeMath
* @dev Math operations with safety checks that throw on error
*/
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    function Ownable() public {
        owner = msg.sender;
    }

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract TokenERC20 {
    using SafeMath for uint256;

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

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    /**
    * Constructor function
    *
    * Initializes contract with initial supply tokens to the creator of the contract
    */
    function TokenERC20(
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
        require(balanceOf[_to].add(_value) > balanceOf[_to]);

        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from].add(balanceOf[_to]);

        // Subtract from the sender
        balanceOf[_from] = balanceOf[_from].sub(_value);

        // Add the same to the recipient
        balanceOf[_to] = balanceOf[_to].add(_value);

        emit Transfer(_from, _to, _value);
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
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
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
        //allowance[_from][msg.sender] -= _value;
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
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
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
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
/*       ADVANCED TOKEN STARTS HERE       */
/******************************************/
contract CinociCoin is Ownable, TokenERC20 {
    using SafeMath for uint256;

    mapping (address => bool)    public  frozenAccount;
    mapping (address => uint256) public freezingPeriod; // how many days the account must remain frozen?

    mapping (address => bool) public exchangesAccounts;

    address public bountyManagerAddress;
    address public bountyManagerDistributionContract = 0x0;

    address public fundAccount; 	// ballast fund address
    bool public isSetFund = false;	// if ballast fund is set

    uint256 public creationDate;
    uint256 public constant frozenDaysForAdvisor       = 187;  
    uint256 public constant frozenDaysForBounty        = 187;
    uint256 public constant frozenDaysForEarlyInvestor = 52;
    uint256 public constant frozenDaysForICO           = 66;   
    uint256 public constant frozenDaysForPartner       = 370;
    uint256 public constant frozenDaysForPreICO        = 52;
    uint256 public constant frozenDaysforTestExchange  = 0;

    /**
    * allowed for a bounty manager account only
    */
    modifier onlyBountyManager(){
        require((msg.sender == bountyManagerDistributionContract) || (msg.sender == bountyManagerAddress));
        _;
    }

    modifier onlyExchangesAccounts(){
        require(exchangesAccounts[msg.sender]);
        _;
    }

    /**
    * allowed for a fund account only
    */
    modifier onlyFund(){
        require(msg.sender == fundAccount);
        _;
    }

    /* This generates a public event on the blockchain that will notify clients */
    event FrozenFunds(address target, bool frozen);

    /**
    * Initializes contract with initial supply tokens to the creator of the contract
    *
    *
    */
    function CinociCoin(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) TokenERC20(initialSupply, tokenName, tokenSymbol) public 
    {
        /* solium-disable-next-line */
        creationDate = now;

        address advisor = 0x32c5Ec858c52F8635Bd92e44d8797e5d356eBd05;
        address bountyManager = 0xdDa9bcf30AFDC40a5fFa6e1b6f70ef030A3E32f4;
        address earlyInvestor = 0x02FF2bA62440c92D2A02D95Df6fc233eA68c2091;
        address partner = 0x6A45baAEb21D49fD85B309235Ef2920d3A648858;
        address exchange1 = 0x8Bd10d3383504a12FD27A1Fd5c0E7bCeae3C8997;
        address exchange2 = 0xce8b8e7113072C5308cec669375E0Ab364b3435C;

        _initializeAccount(partner, frozenDaysForPartner, 30000000);
        _initializeAccount(advisor, frozenDaysForAdvisor, 20000000);
        _initializeAccount(earlyInvestor, frozenDaysForEarlyInvestor, 10000000);  
        _initializeAccount(exchange1, frozenDaysforTestExchange, 1000);
        _initializeAccount(exchange2, frozenDaysforTestExchange, 1000);
        _initializeAccount(bountyManager, frozenDaysForBounty, 15000000);
        bountyManagerAddress = bountyManager;
    }

    /**
    * Only owner function to set ballast fund account address
    * 
    * @dev it can be set only once
    * @param _address smart contract address of ballast fund
    */
    function setFundAccount(address _address) onlyOwner public{
        require (_address != 0x0);
        require (!isSetFund);
        fundAccount = _address;
        isSetFund = true;    
    }

    function addExchangeAccounts(address _address) onlyOwner public{
        require(_address != 0x0);
        exchangesAccounts[_address] = true;
    }

    function removeExchangeAccounts(address _address) onlyOwner public{
        delete exchangesAccounts[_address];
    }

    /**
    * Initialize accounts when token deploy occurs
    *
    * initialize `_address` account, with balance equal `_value` and frozen for `_frozenDays`
    *
    * @param _address wallet address to initialize
    * @param _frozenDays quantity of days to freeze account
    * @param _value quantity of tokens to send to account
    */
    function _initializeAccount(address _address, uint _frozenDays, uint _value) internal{
        _transfer(msg.sender, _address, _value * 10 ** uint256(decimals));
        freezingPeriod[_address] = _frozenDays;
        _freezeAccount(_address, true);
    }

    /**
    * Check if account freezing period expired
    *
    * `now` has to be greater or equal than `creationDate` + `freezingPeriod[_address]` * `1 day`
    *
    * @param _address account address to check if allowed to transfer tokens
    * @return bool true if is allowed to transfer and false if not
    */
    function _isTransferAllowed( address _address ) view public returns (bool)
    {
        /* solium-disable-next-line */
        if( now >= creationDate + freezingPeriod[_address] * 1 days ){
            return ( true );
        } else {
            return ( false );
        }
    }

    /**
    * Internal function to transfer tokens
    *
    * @param _from account to withdraw tokens
    * @param _to account to receive tokens
    * @param _value quantity of tokens to transfer
    */
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);                                  // Prevent transfer to 0x0 address. Use burn() instead
        require (balanceOf[_from] >= _value);                  // Check if the sender has enough
        require (balanceOf[_to].add(_value) > balanceOf[_to]); // Check for overflows

        // check if the sender is under a freezing period
        if(_isTransferAllowed(_from)){ 
            _setFreezingPeriod(_from, false, 0);
        }

        // check if the recipient is under a freezing period
        if(_isTransferAllowed(_to)){
            _setFreezingPeriod(_to, false, 0);
        }

        require(!frozenAccount[_from]);     // Check if sender is frozen
        require(!frozenAccount[_to]);       // Check if recipient is frozen                
        
        balanceOf[_from] = balanceOf[_from].sub(_value);    // Subtract from the sender
        balanceOf[_to] = balanceOf[_to].add(_value);        // Add the same to the recipient

        emit Transfer(_from, _to, _value);
    }
    
    /**
    * Internal function to deliver tokens for bounty, pre-ICO or ICO with determined freezing periods
    *
    * @param _from account address to withdraw tokens
    * @param _to account address to send tokens
    * @param _value quantity of tokes to send
    * @param _frozenDays quantity of days to freeze account
    */
    function _tokenDelivery(address _from, address _to, uint _value, uint _frozenDays) internal {
        freezingPeriod[_to] = 0;
        _freezeAccount(_to, false);
        _transfer(_from, _to, _value);
        freezingPeriod[_to] = _frozenDays;
        _freezeAccount(_to, true); 
    }
    
    /**
    * Only owner function to deliver tokens for pre-ICO investors
    *
    * @param _to account address who will receive the tokens
    * @param _value quantity of tokens to deliver
    */
    function preICOTokenDelivery(address _to, uint _value) onlyOwner public {
        _tokenDelivery(msg.sender, _to, _value, frozenDaysForPreICO);
    }
    
    /**
    * Only owner function to deliver tokens for ICO investors
    *
    * @param _to account address who will receive tokens
    * @param _value quantity of tokens to deliver
    */
    function ICOTokenDelivery(address _to, uint _value) onlyOwner public {
        _tokenDelivery(msg.sender, _to, _value, frozenDaysForICO);
    }
    
    function setBountyDistributionContract(address _contractAddress) onlyOwner public {
        bountyManagerDistributionContract = _contractAddress;
    }

    /**onlyBounty
    * Only bounty manager distribution contract function to deliver tokens for bounty community
    *
    * @param _to account addres who will receive tokens
    * @param _value quantity of tokens to deliver
    */
    function bountyTransfer(address _to, uint _value) onlyBountyManager public {
        _freezeAccount(bountyManagerAddress, false);
        _tokenDelivery(bountyManagerAddress, _to, _value, frozenDaysForBounty);
        _freezeAccount(bountyManagerAddress, true);
    }

    /**
    * Function to get days to unfreeze some account
    *
    * @param _address account address to get days
    * @return result quantity of days to unfreeze `address`
    */
    function daysToUnfreeze(address _address) public view returns (uint256) {
        require(_address != 0x0);

        /* solium-disable-next-line */
        uint256 _now = now;
        uint256 result = 0;

        if( _now <= creationDate + freezingPeriod[_address] * 1 days ) {
            // still under the freezing period.
            uint256 finalPeriod = (creationDate + freezingPeriod[_address] * 1 days) / 1 days;
            uint256 currePeriod = _now / 1 days;
            result = finalPeriod - currePeriod;
        }

        return result;
    }

    /**
    * @notice `freeze? Prevent | Allow` `target` from sending & receiving tokens
    * @param target Address to be frozen
    * @param freeze either to freeze it or not
    */
    function _freezeAccount(address target, bool freeze) internal {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

    /**
    * Only owner function to call `_freezeAccount` directly
    *
    * @param target account address to freeze
    * @param freeze true to freeze account and false to unfreeze
    */
    function freezeAccount(address target, bool freeze) onlyOwner public {
        _freezeAccount(target, freeze);
    }
    
    /**
    * Internal call to set freezing period for some account
    *
    * @param _target account address to freeze
    * @param _freeze true to freeze account and false to unfreeze
    * @param _days period to keep account frozen
    */
    function _setFreezingPeriod(address _target, bool _freeze, uint256 _days) internal {
        _freezeAccount(_target, _freeze);
        freezingPeriod[_target] = _days;
    }
    
    /**
    * Only owner function to call `_setFreezingPeriod` directly
    *
    * @param _target account address to freeze
    * @param _freeze true to freeze account and false to unfreeze
    * @param _days period to keep account frozen
    */
    function setFreezingPeriod(address _target, bool _freeze, uint256 _days) onlyOwner public {
        _setFreezingPeriod(_target, _freeze, _days);
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
        //allowance[_from][msg.sender] -= _value;
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
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
        // check if the sender is under a freezing period
        if( _isTransferAllowed(msg.sender) )  {
            _setFreezingPeriod(msg.sender, false, 0);
        }
        
        allowance[msg.sender][_spender] = _value;
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
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        // check if the sender is under a freezing period
        if( _isTransferAllowed(msg.sender) ) {
            _setFreezingPeriod(msg.sender, false, 0);
        }

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
        return _burn(msg.sender, _value);
    }

    /**
    *
     */
    function _burn(address _from, uint256 _value) internal returns (bool success) {
        balanceOf[_from] = balanceOf[_from].sub(_value);            // Subtract from the sender
        totalSupply = totalSupply.sub(_value);                      // Updates totalSupply
        emit Burn(_from, _value);
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
        require(balanceOf[_from] >= _value);                                     // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);                         // Check allowance
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value); // Subtract from the sender&#39;s allowance
        return _burn(_from, _value);
    }

    /**
    * Only ballast fund function to burn tokens from account
    *
    * Allows `fundAccount` burn tokens to send equivalent ether for account that claimed it
    * @param _from account address to burn tokens
    * @param _value quantity of tokens to burn
    */
    function redemptionBurn(address _from, uint256 _value) onlyFund public{
        _burn(_from, _value);
    }   
}