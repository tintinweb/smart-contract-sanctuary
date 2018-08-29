pragma solidity 0.4.24;


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
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
    }

    /**
     * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
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
    constructor() public {
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

/** 
 * @title Based on the &#39;final&#39; ERC20 token standard as specified at:
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md 
 */
contract ERC20Interface {
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function name() public view returns (string);
    function symbol() public view returns (string);
    function decimals() public view returns (uint8);
    function totalSupply() public view returns (uint256);
    function balanceOf(address _owner) public view returns (uint256);
    function allowance(address _owner, address _spender) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
    function approve(address _spender, uint256 _value) public returns (bool);
}

/**
 * @title TestToken
 * @dev The TestToken contract provides the token functionality of the IPT Global token
 * and allows the admin to distribute frozen tokens which requires defrosting to become transferable.
 */
contract IPTGlobal is ERC20Interface, Ownable {
    using SafeMath for uint256;
    
    //Name of the token.
    string  internal constant NAME = "IPT Global";
    
    //Symbol of the token.
    string  internal constant SYMBOL = "IPT";     
    
    //Granularity of the token.
    uint8   internal constant DECIMALS = 8;        
    
    //Factor for numerical calculations.
    uint256 internal constant DECIMALFACTOR = 10 ** uint(DECIMALS); 
    
    //Total supply of IPT Global tokens.
    uint256 internal constant TOTAL_SUPPLY = 300000000 * uint256(DECIMALFACTOR);  
    
    //Base unlocking value used to calculate fractional percentage of 0.2 %
    uint8   internal constant unlockingValue = 2;
    
    //Base unlocking numerator used to calculate fractional percentage of 0.2 %
    uint8   internal constant unlockingNumerator = 10;
    
    //Allows admin to call a getter which tracks latest/daily unlocked tokens
    uint256 private unlockedTokensDaily;
    //Allows admin to call a getter which tracks total unlocked tokens
    uint256 private unlockedTokensTotal;
    
    address[] uniqueLockedTokenReceivers; 
    
    //Stores uniqueness of all locked token recipients.
    mapping(address => bool)    internal uniqueLockedTokenReceiver;
    
    //Stores all locked IPT Global token holders.
    mapping(address => bool)    internal isHoldingLockedTokens;
    
    //Stores excluded recipients who will not be effected by token unlocking.
    mapping(address => bool)    internal excludedFromTokenUnlock;
    
    //Stores and tracks locked IPT Global token balances.
    mapping(address => uint256) internal lockedTokenBalance;
    
    //Stores the balance of IPT Global holders (complies with ERC-Standard).
    mapping(address => uint256) internal balances; 
    
    //Stores any allowances given to other IPT Global holders.
    mapping(address => mapping(address => uint256)) internal allowed; 
    
    
    event HoldingLockedTokens(
        address recipient, 
        uint256 lockedTokenBalance,
        bool    isHoldingLockedTokens);
    
    event LockedTokensTransferred(
        address recipient, 
        uint256 lockedTokens,
        uint256 lockedTokenBalance);
        
    event TokensUnlocked(
        address recipient,
        uint256 unlockedTokens,
        uint256 lockedTokenBalance);
        
    event LockedTokenBalanceChanged(
        address recipient, 
        uint256 unlockedTokens,
        uint256 lockedTokenBalance);
        
    event ExcludedFromTokenUnlocks(
        address recipient,
        bool    excludedFromTokenUnlocks);
    
    event CompleteTokenBalanceUnlocked(
        address recipient,
        uint256 lockedTokenBalance,
        bool    isHoldingLockedTokens,
        bool    completeTokenBalanceUnlocked);
    
    
    /**
     * @dev constructor sets initialises and configurates the smart contract.
     * More specifically, it grants the smart contract owner the total supply
     * of IPT Global tokens.
     */
    constructor() public {
        balances[msg.sender] = TOTAL_SUPPLY;
    }

    /**
     * @dev allows owner to transfer tokens which are locked by default.
     * @param _recipient is the addresses which will receive locked tokens.
     * @param _lockedTokens is the amount of locked tokens to distribute.
     * and therefore requires unlocking to be transferable.
     */
    function lockedTokenTransfer(address[] _recipient, uint256[] _lockedTokens) external onlyOwner {
       
        for (uint256 i = 0; i < _recipient.length; i++) {
            if (!uniqueLockedTokenReceiver[_recipient[i]]) {
                uniqueLockedTokenReceiver[_recipient[i]] = true;
                uniqueLockedTokenReceivers.push(_recipient[i]);
                }
                
            isHoldingLockedTokens[_recipient[i]] = true;
            
            lockedTokenBalance[_recipient[i]] = lockedTokenBalance[_recipient[i]].add(_lockedTokens[i]);
            
            transfer(_recipient[i], _lockedTokens[i]);
            
            emit HoldingLockedTokens(_recipient[i], _lockedTokens[i], isHoldingLockedTokens[_recipient[i]]);
            emit LockedTokensTransferred(_recipient[i], _lockedTokens[i], lockedTokenBalance[_recipient[i]]);
        }
    }

    /**
     * @dev allows owner to change the locked balance of a recipient manually.
     * @param _owner is the address of the locked token balance to unlock.
     * @param _unlockedTokens is the amount of locked tokens to unlock.
     */
    function changeLockedBalanceManually(address _owner, uint256 _unlockedTokens) external onlyOwner {
        require(_owner != address(0));
        require(_unlockedTokens <= lockedTokenBalance[_owner]);
        require(isHoldingLockedTokens[_owner]);
        require(!excludedFromTokenUnlock[_owner]);
        
        lockedTokenBalance[_owner] = lockedTokenBalance[_owner].sub(_unlockedTokens);
        emit LockedTokenBalanceChanged(_owner, _unlockedTokens, lockedTokenBalance[_owner]);
        
        unlockedTokensDaily  = unlockedTokensDaily.add(_unlockedTokens);
        unlockedTokensTotal  = unlockedTokensTotal.add(_unlockedTokens);
        
        if (lockedTokenBalance[_owner] == 0) {
           isHoldingLockedTokens[_owner] = false;
           emit CompleteTokenBalanceUnlocked(_owner, lockedTokenBalance[_owner], isHoldingLockedTokens[_owner], true);
        }
    }

    /**
     * @dev allows owner to unlock 0.2% of locked token balances, be careful with implementation of 
     * loops over large arrays, could result in block limit issues.
     * should be called once a day as per specifications.
     */
    function unlockTokens() external onlyOwner {

        for (uint256 i = 0; i < uniqueLockedTokenReceivers.length; i++) {
            if (isHoldingLockedTokens[uniqueLockedTokenReceivers[i]] && 
                !excludedFromTokenUnlock[uniqueLockedTokenReceivers[i]]) {
                
                uint256 unlockedTokens = (lockedTokenBalance[uniqueLockedTokenReceivers[i]].mul(unlockingValue).div(unlockingNumerator)).div(100);
                lockedTokenBalance[uniqueLockedTokenReceivers[i]] = lockedTokenBalance[uniqueLockedTokenReceivers[i]].sub(unlockedTokens);
                uint256 unlockedTokensToday = unlockedTokensToday.add(unlockedTokens);
                
                emit TokensUnlocked(uniqueLockedTokenReceivers[i], unlockedTokens, lockedTokenBalance[uniqueLockedTokenReceivers[i]]);
            }
            if (lockedTokenBalance[uniqueLockedTokenReceivers[i]] == 0) {
                isHoldingLockedTokens[uniqueLockedTokenReceivers[i]] = false;
                
                emit CompleteTokenBalanceUnlocked(uniqueLockedTokenReceivers[i], lockedTokenBalance[uniqueLockedTokenReceivers[i]], isHoldingLockedTokens[uniqueLockedTokenReceivers[i]], true);
            }  
        }    
        unlockedTokensDaily  = unlockedTokensToday;
        unlockedTokensTotal  = unlockedTokensTotal.add(unlockedTokensDaily);
    }
    
    /**
     * @dev allows owner to exclude certain recipients from having their locked token balance unlocked.
     * @param _excludedRecipients is the addresses to add token unlock exclusion for.
     * @return a boolean representing whether the function was executed succesfully.
     */
    function addExclusionFromTokenUnlocks(address[] _excludedRecipients) external onlyOwner returns (bool) {
        for (uint256 i = 0; i < _excludedRecipients.length; i++) {
            excludedFromTokenUnlock[_excludedRecipients[i]] = true;
            emit ExcludedFromTokenUnlocks(_excludedRecipients[i], excludedFromTokenUnlock[_excludedRecipients[i]]);
        }
        return true;
    }
    
    /**
     * @dev allows owner to remove any exclusion from certain recipients, allowing their locked token balance to be unlockable again.
     * @param _excludedRecipients is the addresses to remove unlock token exclusion from.
     * @return a boolean representing whether the function was executed succesfully.
     */
    function removeExclusionFromTokenUnlocks(address[] _excludedRecipients) external onlyOwner returns (bool) {
        for (uint256 i = 0; i < _excludedRecipients.length; i++) {
            excludedFromTokenUnlock[_excludedRecipients[i]] = false;
            emit ExcludedFromTokenUnlocks(_excludedRecipients[i], excludedFromTokenUnlock[_excludedRecipients[i]]);
        }
        return true;
    }
    
    /**
     * @dev allows anyone to check the unlocked and locked token balance of a recipient. 
     * @param _owner is the address of the locked token balance to check.
     * @return a uint256 representing the locked and unlocked token balances.
     */
    function checkTokenBalanceState(address _owner) external view returns(uint256 unlockedBalance, uint256 lockedBalance) {
    return (balanceOf(_owner).sub(lockedTokenBalance[_owner]), lockedTokenBalance[_owner]);
    }
    
    /**
     * @dev allows anyone to check the a list of all locked token recipients. 
     * @return an address array representing the list of recipients.
     */
    function checkUniqueLockedTokenReceivers() external view returns (address[]) {
        return uniqueLockedTokenReceivers;
    }
    
     /**
     * @dev allows checking of the daily and total amount of unlocked tokens. 
     * @return an uint representing the daily and total unlocked value.
     */
    function checkUnlockedTokensData() external view returns (uint256 unlockedDaily, uint256 unlockedTotal) {
        return (unlockedTokensDaily, unlockedTokensTotal);
    }

    /**
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     * @return a boolean representing whether the function was executed succesfully.
     */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        
        if (isHoldingLockedTokens[msg.sender]) {
            require(_value <= balances[msg.sender].sub(lockedTokenBalance[msg.sender]));
        }
        
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
         
    }
    
    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     * @return a boolean representing whether the function was executed succesfully.
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        
        if (isHoldingLockedTokens[_from]) {
            require(_value <= balances[_from].sub(lockedTokenBalance[_from]));
            require(_value <= allowed[_from][msg.sender]);
        }

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     * @return a boolean representing whether the function was executed succesfully.
     */
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    /**
     * @dev balanceOf function gets the balance of the specified address.
     * @param _owner The address to query the balance of.
     * @return An uint256 representing the token balance of the passed address.
     */
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
        
    /**
     * @dev allowance function checks the amount of tokens allowed by an owner for a spender to spend.
     * @param _owner address is the address which owns the spendable funds.
     * @param _spender address is the address which will spend the owned funds.
     * @return A uint256 specifying the amount of tokens which are still available for the spender.
     */
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }
    
    /**
     * @dev totalSupply function returns the total supply of tokens.
     */
    function totalSupply() public view returns (uint256) {
        return TOTAL_SUPPLY;
    }
    
    /** 
     * @dev decimals function returns the decimal units of the token. 
     */
    function decimals() public view returns (uint8) {
        return DECIMALS;
    }
            
    /** 
     * @dev symbol function returns the symbol ticker of the token. 
     */
    function symbol() public view returns (string) {
        return SYMBOL;
    }
    
    /** 
     * @dev name function returns the name of the token. 
     */
    function name() public view returns (string) {
        return NAME;
    }
}