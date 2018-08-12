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
contract TestToken is ERC20Interface, Ownable {
    using SafeMath for uint256;
    
    //Name of the token.
    string  internal constant NAME = "Test Token";
    
    //Symbol of the token.
    string  internal constant SYMBOL = "TEST";     
    
    //Granularity of the token.
    uint8   internal constant DECIMALS = 8;        
    
    //Factor for numerical calculations.
    uint256 internal constant DECIMALFACTOR = 10 ** uint(DECIMALS); 
    
    //Total supply of IPT Global tokens.
    uint256 internal constant TOTAL_SUPPLY = 300000000 * uint256(DECIMALFACTOR);  
    
    //Base defrosting value used to calculate fractional percentage of 0.2 %
    uint8 internal constant standardDefrostingValue = 2;
    
    //Base defrosting numerator used to calculate fractional percentage of 0.2 %
    uint8 internal constant standardDefrostingNumerator = 10;

    
    //Stores all frozen TEST Global token holders.
    mapping(address => bool)    public frostbite;
    
    //Stores received frozen IPT Global tokens in an accumulated fashion. 
    mapping(address => uint256) public frozenTokensReceived;
    
    //Stores and tracks frozen IPT Global token balances.
    mapping(address => uint256) public frozenBalance;
    
    //Stores custom frozen IPT Global token defrosting % rates. 
    mapping(address => uint8) public customDefrostingRate;
    
    //Stores the balance of IPT Global holders (complies with ERC-Standard).
    mapping(address => uint256) internal balances; 
    
    //Stores any allowances given to other IPT Global holders.
    mapping(address => mapping(address => uint256)) internal allowed; 
    
    
    //Event which allows for logging of frostbite granting activities.
    event FrostbiteGranted(
        address recipient, 
        uint256 frozenAmount, 
        uint256 defrostingRate);
    
    //Event which allows for logging of frostbite terminating activities.
    event FrostBiteTerminated(
        address recipient,
        uint256 frozenBalance);
    
    //Event which allows for logging of frozen token transfer activities.
    event FrozenTokensTransferred(
        address owner, 
        address recipient, 
        uint256 frozenAmount, 
        uint256 defrostingRate);
    
    //Event which allows for logging of custom frozen token defrosting activities.   
    event CustomTokenDefrosting(
        address owner,
        uint256 percentage,
        uint256 defrostedAmount);
        
    //Event which allows for logging of calculated frozen token defrosting activities.   
    event CalculatedTokenDefrosting(
        address owner,
        uint256 defrostedAmount);
    
    //Event which allows for logging of complete recipient recovery activities.
    event RecipientRecovered(
        address recipient,
        uint256 customDefrostingRate,
        uint256 frozenBalance,
        bool frostbite);
     
    //Event which allows for logging of recipient balance recovery activities.   
    event FrozenBalanceDefrosted(
        address recipient,
        uint256 frozenBalance,
        bool frostbite);
    
    //Event which allows for logging of defrostingrate-adjusting activities.
    event DefrostingRateChanged(
        address recipient,
        uint256 defrostingRate);
        
    //Event which allows for logging of frozenBalance-adjusting activities.
    event FrozenBalanceChanged(
        address recipient, 
        uint256 defrostedAmount);
    
    
    /**
     * @dev constructor sets initialises and configurates the smart contract.
     * More specifically, it grants the smart contract owner the total supply
     * of IPT Global tokens.
     */
    constructor() public {
        balances[msg.sender] = TOTAL_SUPPLY;
    }


    /**
     * @dev frozenTokenTransfer function allows the owner of the smart contract to Transfer
     * frozen tokens (untransferable till melted) to a particular recipient.
     * @param _recipient the address which will receive the frozen tokens.
     * @param _frozenAmount the value which will be sent to the _recipient.
     * @param _customDefrostingRate the rate at which the tokens will be melted.
     * @return a boolean representing whether the function was executed succesfully.
     */
    function frozenTokenTransfer(address _recipient, uint256 _frozenAmount, uint8 _customDefrostingRate) external onlyOwner returns (bool) {
        require(_recipient != address(0));
        require(_frozenAmount <= balances[msg.sender]);
        
        frozenTokensReceived[_recipient] = _frozenAmount;
               frozenBalance[_recipient] = _frozenAmount;
        customDefrostingRate[_recipient] = _customDefrostingRate;
                   frostbite[_recipient] = true;

        balances[msg.sender] = balances[msg.sender].sub(_frozenAmount);
        balances[_recipient] = balances[_recipient].add(_frozenAmount);
        
        emit FrozenTokensTransferred(msg.sender, _recipient, _frozenAmount, customDefrostingRate[_recipient]);
        return true;
    }
    
    /**
     * @dev changeCustomDefrostingRate function allows the owner of the smart contract to change individual custom defrosting rates.
     * @param _recipient the address whose defrostingRate will be adjusted.
     * @param _newCustomDefrostingRate the new defrosting rate which will be placed on the recipient.
     * @return a boolean representing whether the function was executed succesfully.
     */
    function changeCustomDefrostingRate(address _recipient, uint8 _newCustomDefrostingRate) external onlyOwner returns (bool) {
        require(_recipient != address(0));
        require(frostbite[_recipient]);
        
        customDefrostingRate[_recipient] = _newCustomDefrostingRate;
        
        emit DefrostingRateChanged(_recipient, _newCustomDefrostingRate);
        return true;
    }
    
    /**
     * @dev changeFrozenBalance function allows the owner of the smart contract to change individual particular frozen balances.
     * @param _recipient the address whose defrostingRate will be adjusted.
     * @param _defrostedAmount the defrosted/subtracted amount of an existing particular frozen balance..
     * @return a boolean representing whether the function was executed succesfully.
     */
    function changeFrozenBalance(address _recipient, uint256 _defrostedAmount) external onlyOwner returns (bool) {
        require(_recipient != address(0));
        require(_defrostedAmount <= frozenBalance[_recipient]);
        require(frostbite[_recipient]);
        
        frozenBalance[_recipient] = frozenBalance[_recipient].sub(_defrostedAmount);
        
        emit FrozenBalanceChanged(_recipient, _defrostedAmount);
        return true;
    }
    
    /**
     * @dev removeFrozenTokenConfigurations function allows the owner of the smart contract to remove all 
     * frostbites, frozenbalances and defrosting rates of an array of recipient addresses < 50.
     * @param _recipients the address(es) which will be recovered.
     * @return a boolean representing whether the function was executed succesfully.
     */
    function removeFrozenTokenConfigurations(address[] _recipients) external onlyOwner returns (bool) {
        
        for (uint256 i = 0; i < _recipients.length; i++) {
            if (frostbite[_recipients[i]]) {
                customDefrostingRate[_recipients[i]] = 0;
                       frozenBalance[_recipients[i]] = 0;
                           frostbite[_recipients[i]] = false;
                
                emit RecipientRecovered(_recipients[i], customDefrostingRate[_recipients[i]], frozenBalance[_recipients[i]], false);
            }
        }
        return true;
    }
    
    /**
     * @dev standardTokenDefrosting function allows the owner of the smart contract to defrost
     * frozen tokens based on a base defrosting Rate of 0.2 % (from multiple recipients at once if desired) of particular recipient addresses < 50.
     * @param _recipients the address(es) which will receive defrosting of frozen tokens.
     * @return a boolean representing whether the function was executed succesfully.
     */
    function standardTokenDefrosting(address[] _recipients) external onlyOwner returns (bool) {
        
        for (uint256 i = 0; i < _recipients.length; i++) {
            if (frostbite[_recipients[i]]) {
                uint256 defrostedAmount = (frozenTokensReceived[_recipients[i]].mul(standardDefrostingValue).div(standardDefrostingNumerator)).div(100);
                
                frozenBalance[_recipients[i]] = frozenBalance[_recipients[i]].sub(defrostedAmount);
                
                emit CalculatedTokenDefrosting(msg.sender, defrostedAmount);
            }
            if (frozenBalance[_recipients[i]] == 0) {
                         frostbite[_recipients[i]] = false;
                         
                emit FrozenBalanceDefrosted(_recipients[i], frozenBalance[_recipients[i]], false);
            }
        }
        return true;
    }
    
    /**
     * @dev customTokenDefrosting function allows the owner of the smart contract to defrost
     * frozen tokens based on custom defrosting Rates (from multiple recipients at once if desired) of particular recipient addresses < 50.
     * @param _recipients the address(es) which will receive defrosting of frozen tokens.
     * @return a boolean representing whether the function was executed succesfully.
     */
    function customTokenDefrosting(address[] _recipients) external onlyOwner returns (bool) {
        
        for (uint256 i = 0; i < _recipients.length; i++) {
            if (frostbite[_recipients[i]]) {
                uint256 defrostedAmount = (frozenTokensReceived[_recipients[i]].mul(customDefrostingRate[_recipients[i]])).div(100);
                
                frozenBalance[_recipients[i]] = frozenBalance[_recipients[i]].sub(defrostedAmount);
               
                emit CustomTokenDefrosting(msg.sender, customDefrostingRate[_recipients[i]], defrostedAmount);
            }
            if (frozenBalance[_recipients[i]] == 0) {
                         frostbite[_recipients[i]] = false;
                         
                    emit FrozenBalanceDefrosted(_recipients[i], frozenBalance[_recipients[i]], false);
            }
        }
        return true;
    }
    
    /**
     * @dev Transfer token for a specified address
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     * @return a boolean representing whether the function was executed succesfully.
     */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        
        if (frostbite[msg.sender]) {
            require(_value <= balances[msg.sender].sub(frozenBalance[msg.sender]));
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
        
        if (frostbite[_from]) {
            require(_value <= balances[_from].sub(frozenBalance[_from]));
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