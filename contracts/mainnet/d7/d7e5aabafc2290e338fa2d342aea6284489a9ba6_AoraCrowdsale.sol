// solium-disable linebreak-style
pragma solidity ^0.4.24;

/**
 * @title Whitelist
 * @dev Whitelist contract has its own role whitelister and maintains index of whitelisted addresses.
 */
contract Whitelist {

    // who can whitelist
    address public whitelister;

    // Whitelist mapping
    mapping (address => bool) whitelist;

    /**
      * @dev The Whitelist constructor sets the original `whitelister` of the contract to the sender
      * account.
      */
    constructor() public {
        whitelister = msg.sender;
    }

    /**
      * @dev Throws if called by any account other than the whitelister.
      */
    modifier onlyWhitelister() {
        require(msg.sender == whitelister);
        _;
    }

    modifier addressNotZero(address _address) {
        require(_address != address(0));
        _;
    }

    modifier onlyWhitelisted(address _address) {
        require(whitelist[_address]);
        _;
    }

    /** 
    * @dev Only callable by the whitelister. Whitelists the specified address.
    * @notice Only callable by the whitelister. Whitelists the specified address.
    * @param _address Address to be whitelisted. 
    */
    function addToWhitelist(address _address) public onlyWhitelister addressNotZero(_address) {
        emit WhitelistAdd(whitelister, _address);
        whitelist[_address] = true;
    }
    
    /** 
    * @dev Only callable by the whitelister. Whitelists the specified addresses.
    * @notice Only callable by the whitelister. Whitelists the specified addresses.
    * @param _addresses Addresses to be whitelisted. 
    */
    function addAddressesToWhitelist(address[] _addresses) public onlyWhitelister {
        for(uint i = 0; i < _addresses.length; ++i)
            addToWhitelist(_addresses[i]);
    }

    /**
    * @dev Checks if the specified address is whitelisted.
    * @notice Checks if the specified address is whitelisted. 
    * @param _address Address to be whitelisted.
    */
    function isWhitelisted(address _address) public view returns (bool) {
        return whitelist[_address];
    }

    /**
      * @dev Changes the current whitelister. Callable only by the whitelister.
      * @notice Changes the current whitelister. Callable only by the whitelister.
      * @param _newWhitelister Address of new whitelister.
      */
    function changeWhitelister(address _newWhitelister) public onlyWhitelister addressNotZero(_newWhitelister) {
        emit WhitelisterChanged(whitelister, _newWhitelister);
        whitelister = _newWhitelister;
    }

    /** 
    * Event for logging the whitelister change. 
    * @param previousWhitelister Old whitelister.
    * @param newWhitelister New whitelister.
    */
    event WhitelisterChanged(address indexed previousWhitelister, address indexed newWhitelister);
    
    /** 
    * Event for logging when the user is whitelisted.
    * @param whitelister Current whitelister.
    * @param whitelistedAddress User added to whitelist.
    */
    event WhitelistAdd(address indexed whitelister, address indexed whitelistedAddress);
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {

    // Owner&#39;s address
    address public owner;

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
    * @param _newOwner The address to transfer ownership to.
    */
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        emit OwnerChanged(owner, _newOwner);
        owner = _newOwner;
    }

    event OwnerChanged(address indexed previousOwner,address indexed newOwner);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
      // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
      // benefit is lost if &#39;b&#39; is also tested.
      // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0); // Solidity only automatically asserts when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

        return c;
    }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}


contract AoraCrowdsale is Whitelist, Ownable {
    using SafeMath for uint256;

    // Token being sold
    IERC20 public token;

    // Start of presale timestamp in miliseconds
    uint public startOfPresale;

    // End of presale timestamp in miliseconds
    uint public endOfPresale;

    // Start of crowdsale timestamp in miliseconds
    uint public startOfCrowdsale;

    // End of crowdsale timestamp in miliseconds
    uint public endOfCrowdsale;

    // Maximum number of tokens that can be sold
    uint public cap;

    // Tokens sold so far
    uint public tokensSold = 0;

    // US Dollars raised so far in cents 
    uint public usdRaised = 0;

    // Deployment block of the contract 
    uint public deploymentBlock;

    // Tokens per US Dollar rate, fixed for this crowsale.
    uint public tokensPerUsdRate = 5;

    // Factor that we multiply with to get whole tokens from cents 
    uint constant public centsToWholeTokenFactor = 10 ** 16; 

    /**
    * @param _startOfPresale start of presale timestamp
    * @param _endOfPresale  end of presale timestamp
    * @param _startOfCrowdsale start of crowdsale timestamp
    * @param _endOfCrowdsale end of crowdsale timestamp
    * @param _tokensPerUsdRate how many tokens per US Dollar contributed
    * @param _cap total amount of sellable tokens 
    * @param _token address of the token contract 
    */
    constructor(
        uint _startOfPresale, 
        uint _endOfPresale, 
        uint _startOfCrowdsale, 
        uint _endOfCrowdsale, 
        uint _tokensPerUsdRate, 
        uint _cap,
        IERC20 _token
        ) public addressNotZero(_token) {
        
        startOfPresale = _startOfPresale;
        endOfPresale = _endOfPresale;
        startOfCrowdsale = _startOfCrowdsale;
        endOfCrowdsale = _endOfCrowdsale;

        tokensPerUsdRate = _tokensPerUsdRate; 

        cap = _cap;

        token = _token;

        deploymentBlock = block.number;
    }

    /**
    * @dev Fallback function. Can&#39;t send ether to this contract. 
    */
    function () external payable {
        revert();
    }

    /**
    * @dev signifies weather or not the argument has any value
    * @param usdAmount amount of US Dollars in cents 
    */ 
    modifier hasValue(uint usdAmount) {
        require(usdAmount > 0);
        _;
    }

    /**
    * @dev signifies weather or not crowdsale is over
    */
    modifier crowdsaleNotOver() {
        require(isCrowdsale()); 
        _;
    }

    /** 
    * @dev sets the start of presale
    */
    function setStartOfPresale(uint _startOfPresale) external onlyOwner {
        emit OnStartOfPresaleSet(_startOfPresale, startOfPresale); 
        startOfPresale = _startOfPresale;
    }

    /**
    * @dev sets the end of presale
    * @param _endOfPresale new timestamp value  
    */
    function setEndOfPresale(uint _endOfPresale) external onlyOwner {
        emit OnEndOfPresaleSet(_endOfPresale, endOfPresale); 
        endOfPresale = _endOfPresale;
    }

    /**
    * @dev sets the start of crowdsale
    * @param _startOfCrowdsale new timestamp value
    */
    function setStartOfCrowdsale(uint _startOfCrowdsale) external onlyOwner {
        emit OnStartOfCrowdsaleSet(_startOfCrowdsale, startOfCrowdsale);
        startOfCrowdsale = _startOfCrowdsale;
    }

    /**
    * @dev sets the end of crowdsale
    * @param _endOfCrowdsale new timestamp value
    */
    function setEndOfCrowdsale(uint _endOfCrowdsale) external onlyOwner {
        emit OnEndOfCrowdsaleSet(_endOfCrowdsale, endOfCrowdsale);
        endOfCrowdsale = _endOfCrowdsale;
    }

    /** 
    * @dev sets the cap
    * @param _cap new cap value
    */
    function setCap(uint _cap) external onlyOwner { 
        emit OnCapSet(_cap, cap);
        cap = _cap;
    }

    /**
    * @dev sets the tokensPerUsdRate
    * @param _tokensPerUsdRate new tokens per US Dollar rate
    */
    function setTokensPerUsdRate(uint _tokensPerUsdRate) external onlyOwner {
        emit OnTokensPerUsdRateSet(_tokensPerUsdRate, tokensPerUsdRate);
        tokensPerUsdRate = _tokensPerUsdRate;
    }

    /**
    * @dev returns weather or not the presale is over
    */
    function isPresale() public view returns(bool) {
        return now < endOfPresale;
    }

    /** 
    * @dev returns weather or not the crowdsale is over
    */
    function isCrowdsale() public view returns(bool) {
        return now < endOfCrowdsale;
    }

    /**
    * @dev Creates a contribution for the specified beneficiary.
    *   Callable only by the owner, while the crowdsale is not over. 
    *   Whitelists the beneficiary as well, to optimize gas cost.
    * @param beneficiary address of the beneficiary
    * @param usdAmount contribution value in cents
    */
    function createContribution(address beneficiary, uint usdAmount) public 
    onlyOwner 
    addressNotZero(beneficiary) 
    hasValue(usdAmount)
    crowdsaleNotOver
    {        
        usdRaised = usdRaised.add(usdAmount); // USD amount in cents 

        uint aoraTgeAmount = usdAmount.mul(tokensPerUsdRate).mul(centsToWholeTokenFactor); 

        if(isPresale())
            aoraTgeAmount = aoraTgeAmount.mul(11).div(10); // 10% presale bonus, paid out from crowdsale pool

        uint newTokensSoldAmount = tokensSold.add(aoraTgeAmount);

        require(newTokensSoldAmount <= cap);

        tokensSold = newTokensSoldAmount;

        token.transfer(beneficiary, aoraTgeAmount);

        addToWhitelist(beneficiary);

        emit OnContributionCreated(beneficiary, usdAmount);
    }

    /**
    * @dev Create contributions in bulk, to optimize gas cost.
    * @param beneficiaries addresses of beneficiaries 
    * @param usdAmounts USDollar value of the each contribution in cents.
    */
    function createBulkContributions(address[] beneficiaries, uint[] usdAmounts) external onlyOwner {
        require(beneficiaries.length == usdAmounts.length);
        for (uint i = 0; i < beneficiaries.length; ++i)
            createContribution(beneficiaries[i], usdAmounts[i]);
    }

    /**
    * @dev This method can be used by the owner to extract mistakenly sent tokens
    * or Ether sent to this contract.
    * @param _token address The address of the token contract that you want to
    * recover set to 0 in case you want to extract ether. It can&#39;t be ElpisToken.
    */
    function claimTokens(address _token) public onlyOwner {
        require(_token != address(token));

        if (_token == address(0)) {
            owner.transfer(address(this).balance);
            return;
        }

        IERC20 tokenReference = IERC20(_token);
        uint balance = tokenReference.balanceOf(address(this));
        tokenReference.transfer(owner, balance);
        emit OnClaimTokens(_token, owner, balance);
    }

    /**
    * @param oldValue old value of the field
    * @param newValue new value of the field
    */
    event OnTokensPerUsdRateSet(uint256 oldValue, uint256 newValue);

    /**
    * @param oldValue old value of the field
    * @param newValue new value of the field
    */
    event OnCapSet(uint256 oldValue, uint256 newValue);

    /**
    * @param oldValue old value of the field
    * @param newValue new value of the field
    */
    event OnStartOfPresaleSet(uint256 oldValue, uint256 newValue);

    /**
    * @param oldValue old value of the field
    * @param newValue new value of the field
    */
    event OnEndOfPresaleSet(uint256 oldValue, uint256 newValue);

    /**
    * @param oldValue old value of the field
    * @param newValue new value of the field
    */
    event OnStartOfCrowdsaleSet(uint256 oldValue, uint256 newValue);

    /**
    * @param oldValue old value of the field
    * @param newValue new value of the field
    */
    event OnEndOfCrowdsaleSet(uint256 oldValue, uint256 newValue);

    /**
    * @param token claimed token
    * @param owner who owns the contract
    * @param amount amount of the claimed token
    */
    event OnClaimTokens(address indexed token, address indexed owner, uint256 amount);

    /**
    * @param beneficiary who is the recipient of tokens from the contribution
    * @param weiAmount Amount of wei contributed 
    */
    event OnContributionCreated(address indexed beneficiary, uint256 weiAmount);
}