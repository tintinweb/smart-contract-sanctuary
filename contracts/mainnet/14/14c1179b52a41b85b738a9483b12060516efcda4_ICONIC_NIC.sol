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
    *
    * Send `_value` tokens to `_to` from `_from`
    *
    * @param _from Address of the sender
    * @param _to Address of the recipient
    * @param _value the amount to send
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
contract ICONIC_NIC is Ownable, TokenERC20 {
    using SafeMath for uint256;

    mapping (address => bool)    public  frozenAccount;
    mapping (address => uint256) public freezingPeriod; // how many days the account must remain frozen?

    mapping (address => bool) public exchangesAccounts;

    address public bountyManagerAddress; //bounty manager address
    address public bountyManagerDistributionContract = 0x0; // bounty distributor smart contract address

    address public fundAccount; 	// ballast fund address
    bool public isSetFund = false;	// if ballast fund is set

    uint256 public creationDate;

    uint256 public constant frozenDaysForAdvisor       = 186;  
    uint256 public constant frozenDaysForBounty        = 186;
    uint256 public constant frozenDaysForEarlyInvestor = 51;
    uint256 public constant frozenDaysForICO           = 65;   
    uint256 public constant frozenDaysForPartner       = 369;
    uint256 public constant frozenDaysForPreICO        = 51;

    /**
    * allowed for a bounty manager account only
    */
    modifier onlyBountyManager(){
        require((msg.sender == bountyManagerDistributionContract) || (msg.sender == bountyManagerAddress));
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
    */
    function ICONIC_NIC(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) TokenERC20(initialSupply, tokenName, tokenSymbol) public 
    {
        /* solium-disable-next-line */
        creationDate = now;

        // PARTNERS DISTRIBUTION
        _initializeAccount(0x85abeD924205bbE4D32077E596e45B9F40AAF8d9, frozenDaysForPartner, 2115007);
        _initializeAccount(0xf7817F08C2660970014a086a4Ba679636e73E8ef, frozenDaysForPartner, 8745473);
        _initializeAccount(0x2c208677f8BAB9c6A44bBe3554f36d2440C9b6C2, frozenDaysForPartner, 3498189);
        _initializeAccount(0x3689B9a43ab904D70f396B2A27DDac0E5885CF68, frozenDaysForPartner, 26236419);
        _initializeAccount(0x245B058C8c256D011742aF5Faa296198735eE0Ee, frozenDaysForPartner, 211501);
        _initializeAccount(0xeEFA9f8f39aaF1d1Ed160Ac2465e937A8F154182, frozenDaysForPartner, 1749095);

        // EARLY INVESTOR DISTRIBUTION
        _initializeAccount(0x4718bB26bCE82459913aaCA09a006Daa517F1c0E, frozenDaysForEarlyInvestor, 225000);
        _initializeAccount(0x8cC1d930e685c977EFcEf9dc412D3ADbE11B84c1, frozenDaysForEarlyInvestor, 2678100);

        // ADVISOR DISTRIBUTION
        _initializeAccount(0x272c41b76Bad949739839E6BB5Eb9f2B0CDFD95D, frozenDaysForAdvisor, 1057503);
        _initializeAccount(0x3a5cd9E7ccFE4DD5484335F3AF30CCAba95D07C3, frozenDaysForAdvisor, 528752);
        _initializeAccount(0xA10CC5321E834c41137f2150A9b0f2Aa1c5016, frozenDaysForAdvisor, 1057503);
        _initializeAccount(0x59B640c5663E5e79Ce9F68EBbC28454490DbA7B8, frozenDaysForAdvisor, 1057503);
        _initializeAccount(0xdCA69FbfEFf48851ceC91B57610FA60ABc27Af3B, frozenDaysForAdvisor, 3172510);
        _initializeAccount(0x332526F0082d4d385F9Ef393841f44c1bf813D8c, frozenDaysForAdvisor, 3172510);
        _initializeAccount(0xf6B436cBB177777A170819128EbBeF0715101eA2, frozenDaysForAdvisor, 1275000);
        _initializeAccount(0xB76a63Fa7658aD0480986e609b9d5b1f1b6B53b9, frozenDaysForAdvisor, 1487500);
        _initializeAccount(0x2bC240bc0D28725dF790706da7663413ac8Fa5ee, frozenDaysForAdvisor, 2125000);
        _initializeAccount(0x32Aa02961fa15e74D896C45A428E5d1884af2217, frozenDaysForAdvisor, 1057503);
        _initializeAccount(0x5340EC716a00Db16a9C289369e4b30ae897C25d3, frozenDaysForAdvisor, 1586255);
        _initializeAccount(0x39d6FDB4B0f8dfE39EC0b4fE5Dd9B2f66e30f8D1, frozenDaysForAdvisor, 846003);
        _initializeAccount(0xCe438C52D95ee47634f9AeE36de5488D0d5D0FBd, frozenDaysForAdvisor, 250000);

        // BOUNTY DISTRIBUTION
        bountyManagerAddress = 0xA9939938e6BAcC0b748045be80FD9E958898eB79;
        _initializeAccount(bountyManagerAddress, frozenDaysForBounty, 15000000);
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

    /**
    * Only owner function to add Exchange Accounts
    *
    * @param _address Exchange address
    */
    function addExchangeTestAccounts(address _address) onlyOwner public{
        require(_address != 0x0);
        exchangesAccounts[_address] = true;
    }

    /**
    * Only owner function to remove Exchange Accounts
    *
    * @param _address Exchange address
    */
    function removeExchangeTestAccounts(address _address) onlyOwner public{
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

    /**
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
    * Internal call to burn tokens
    * 
    * @param _from the address to burn tokens
    * @param _value the amount of tokens to burn
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
    * @param _from the address of to withdraw tokens
    * @param _value the amount of tokens to burn
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