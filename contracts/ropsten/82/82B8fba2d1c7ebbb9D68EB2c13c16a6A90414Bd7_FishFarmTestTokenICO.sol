pragma solidity ^0.4.21;

//Author    Patrick Lismore 
//Date      05/11/2018
//Desc      Basic ICO for Fish Farm Test - ICO Date Oct 1st 2018 - Jan 1st 2019
//          1 million FFT Tokens 
//          conversionRate determined by contract owner 
//          tokens available right away & ETH sent direct to beneficiary address

/**
 * @title Safe Math
 *
 * @dev Library for safe math operations.
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;

        return c;
    }

    function minus(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);

        return a - b;
    }

    function plus(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);

        return c;
    }
}

/**
 * @dev This is the standard ERC20 Token contract base class.
 */
contract ERC20Token {
    uint256 public totalSupply;
    
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

/**
 * @title Standard Token
 *
 * @dev This is the standard abstract implementation of the ERC20 interface
 */
contract StandardToken is ERC20Token {
    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8 public decimals;
    
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) internal allowed;
    
    /**
     * @dev This constructor assigns the fish farm token name, its symbols and decimals.
     */
    constructor(string _name, string _symbol, uint8 _decimals) internal {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    /**
     * @dev Gets the balance of a supplied address.
     *
     * @param _address The address for which the balance will be checked.
     *
     * @return This function returns the current balance of an address.
     */
    function balanceOf(address _address) public view returns (uint256 balance) {
        return balances[_address];
    }

    /**
     * @dev This validates the amount of tokens that an owner is allowed to a spend.
     *
     * @param _owner The address which owns the funds.
     * @param _spender The third-party address that is allowed to spend the tokens.
     *
     * @return The number of tokens available to `_spender` to be spent.
     */
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    /**
     * @dev This gives permission to a `_spender` to spend the `_value` of a number of tokens on your behalf.
     * For example you place a buy or sell order on to an exchange and in that example, the 
     * `_spender` address is the address of the contract that the exchange created to add your token to their 
     * exchange and you are `msg.sender`.
     *
     * @param _spender address which will spend the funds
     * @param _value The amount of tokens to be spent
     *
     * @return true/false if the approval process was successful or not.
     */
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    /**
     * @dev This transfers `_value` in number of tokens to the `_to` address.
     *
     * @param _to address of the recipient.
     * @param _value number of tokens to be transferred.
     */
    function transfer(address _to, uint256 _value) public returns (bool) {
        executeTransfer(msg.sender, _to, _value);

        return true;
    }

    /**
     * @dev This allows another like an exchange contract to spend tokens on behalf of the `_from` address and send them to the `_to` address.
     *
     * @param _from address which approved you to spend tokens on their behalf.
     * @param _to address where you want to send tokens.
     * @param _value number of tokens to be sent.
     *
     * @return Whether the transfer was successful or not.
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_value <= allowed[_from][msg.sender]);
        
        allowed[_from][msg.sender] = allowed[_from][msg.sender].minus(_value);
        executeTransfer(_from, _to, _value);

        return true;
    }

    /**
     * @dev This is an internal function that this reused by the transfer functions
     */
    function executeTransfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0));
        require(_value != 0 && _value <= balances[_from]);
        
        balances[_from] = balances[_from].minus(_value);
        balances[_to] = balances[_to].plus(_value);

        emit Transfer(_from, _to, _value);
    }
}

/**
 * @title Mintable Token Contract
 *
 * @dev this allows the creation of new FFT tokens
 */
contract MintableToken is StandardToken {

    /// @dev only address allowed to mint coins
    address public minter;

    /// @dev This determines whether the token is still mintable.
    bool public mintingDisabled = false;
    
    /// @dev The max supply of tokens 
    uint256 public maxTokenSupply = 1000000000000000000000000;
    /**
     * @dev This event is fired when minting is no longer allowed.
     */
    event MintingDisabled();

    /**
     * @dev This allows a function to be executed only if minting is still allowed.
     */
    modifier canMint() {
        require(!mintingDisabled);
        _;
    }

    /**
     * @dev This allows a function to be called only by the minter
     */
    modifier onlyMinter() {
        require(msg.sender == minter);
        _;
    }

    /**
     * @dev This constructor assigns the minter which is allowed to mint and disable minting
     */
    constructor(address _minter) internal {
        minter = _minter;
    }

    /**
    * @dev this creates the new `_value` tokens and sends them to the `_to` address.
    *
    * @param _to address which will receive the freshly minted tokens.
    * @param _value number of tokens that will be created.
    */
    function mint(address _to, uint256 _value) onlyMinter canMint public {
        
        uint256 totalSupplyLocal = totalSupply;
        totalSupplyLocal = totalSupplyLocal.plus(_value);
        require(totalSupplyLocal <= maxTokenSupply, "Cannot exceed max token supply");
        
        
        totalSupply = totalSupply.plus(_value);
        balances[_to] = balances[_to].plus(_value);

        emit Transfer(0x0, _to, _value);
    }

    /**
    * @dev This disable the minting of new FFTT tokens and cannot be reversed.
    *
    * @return it returns if the process was successful.
    */
    function disableMinting() onlyMinter canMint public {
        mintingDisabled = true;
       
        emit MintingDisabled();
    }
}

/**
 * @title HasOwner contract
 *
 * @dev This allows for exclusive access to certain functionality.
 */
contract HasOwner {

    // The current owner.
    address public owner;

    // Conditionally the new owner.
    address public newOwner;

    /**
     * @dev constructor.
     *
     * @param _owner address of the owner.
     */
    constructor(address _owner) public {
        owner = _owner;
    }

    /** 
     * @dev This is an access control modifier that allows the current owner to call the function.
     */
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev This event is fired when the current owner is changed.
     *
     * @param _oldOwner address of the previous owner.
     * @param _newOwner address of the new owner.
     */
    event OwnershipTransfer(address indexed _oldOwner, address indexed _newOwner);

    /**
     * @dev When transfering ownership it is best to do it in a two-step process, as we prepare
     * to transfer by calling `newOwner` and then requiring `newOwner` to acceptOwnership of
     * the transfer. This will prevent accidental lock-out if something goes wrong
     * when passing the `newOwner` address.
     *
     * @param _newOwner address of the proposed new owner.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
 
    /**
     * @dev The `newOwner` finalises the ownership transfer process by accepting ownership.
     */
    function acceptOwnership() public {
        require(msg.sender == newOwner);

        emit OwnershipTransfer(owner, newOwner);

        owner = newOwner;
    }
}

/**
 * @title AbstractFundraiser Contract
 * 
 * @dev base AbstractFundraiser contract
 */
contract AbstractFundraiser {

    /// The ERC20 token contract.
    ERC20Token public token;

    /**
     * @dev This event fires every time a new buyer enters the ICO.
     *
     * @param _address address of the buyer.
     * @param _ethers number of ethers funded.
     * @param _tokens number of tokens purchased.
     */
    event FundsReceived(address indexed _address, uint _ethers, uint _tokens);


    /**
     * @dev This is the initialize method for the FFTT token
     *
     * @param _token address of the token of the ICO
     */
    function initializeFundraiserToken(address _token) internal
    {
        token = ERC20Token(_token);
    }

    /**
     * @dev This default function which is executed when a particpant sends ETH to this ICO contract address.
     */
    function() public payable {
        receiveFunds(msg.sender, msg.value);
    }

    /**
     * @dev this overridable function returns the current conversion rate for the ICO
     */
    function getConversionRate() public view returns (uint256);

    /**
     * @dev this checks whether the ICO is passed `endTime`.
     *
     * @return whether the ICO has ended.
     */
    function hasEnded() public view returns (bool);

    /**
     * @dev This create and sends FFTT tokens to `_address` considering amount funded and `conversionRate`.
     *
     * @param _address address of the receiver of tokens.
     * @param _amount amount of received funds in ether.
     */
    function receiveFunds(address _address, uint256 _amount) internal;
    
    /**
     * @dev This throws an exception if the transaction does not meet the preconditions.
     */
    function validateTransaction() internal view;
    
    /**
     * @dev this overridable function makes and handles tokens to buyers
     */
    function handleTokens(address _address, uint256 _tokens) internal;

    /**
     * @dev this overridable function forwards the funds (if necessary) to a vault or directly to the beneficiary
     */
    function handleFunds(address _address, uint256 _ethers) internal;

}

/**
 * @title This is a basic ico contract
 *
 * @dev An abstract ICO contract that is a base for the ICO. 
 * This implements a generic procedure for handling received funds:
 *
 * 1. It validates the transaciton preconditions
 * 2. It calculates the amount of FFTT tokens based on the set conversion rate.
 * 3. It delegates the handling of the FFTT tokens (mint, transfer or conjure)
 * 4. It delegates the handling of the ETH funds
 * 5. It emits event for received funds
 */
contract BasicFundraiser is HasOwner, AbstractFundraiser {

    using SafeMath for uint256;

    // The number of decimals for the FFT token.
    uint8 constant DECIMALS = 18;

    // Decimal for multiplication purposes.
    uint256 constant DECIMALS_FACTOR = 10 ** uint256(DECIMALS);

    /// The start time of the ICO - Unix timestamp.
    uint256 public startTime;

    /// The end time of the ICO - Unix timestamp.
    uint256 public endTime;

    /// The address where ETH funds collected will be sent.
    address public beneficiary;

    /// The conversion rate with decimals difference adjustment,
    /// When conversion rate is lower than 1 (inversed), the function calculateTokens() should use division
    uint256 public conversionRate;

    /// The total amount of ether raised.
    uint256 public totalRaised;

    /**
     * @dev This event fires when the number of FFT token conversion rate has changed.
     *
     * @param _conversionRate The new number of tokens per 1 ether.
     */
    event ConversionRateChanged(uint _conversionRate);

    /**
     * @dev This is basic ICO initialization method.
     *
     * @param _startTime start time of the fundraiser - Unix timestamp.
     * @param _endTime end time of the fundraiser - Unix timestamp.
     * @param _conversionRate number of FFT tokens create for 1 ETH funded.
     * @param _beneficiary address which will receive the funds gathered by the ICO.
     */
    function initializeBasicFundraiser(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _conversionRate,
        address _beneficiary
    )
        internal
    {
        require(_endTime >= _startTime);
        require(_conversionRate > 0);
        require(_beneficiary != address(0));

        startTime = _startTime;
        endTime = _endTime;
        conversionRate = _conversionRate;
        beneficiary = _beneficiary;
    }

    /**
     * @dev This sets the new conversion rate
     *
     * @param _conversionRate New conversion rate
     */
    function setConversionRate(uint256 _conversionRate) public onlyOwner {
        require(_conversionRate > 0);

        conversionRate = _conversionRate;

        emit ConversionRateChanged(_conversionRate);
    }

    /**
     * @dev This sets the beneficiary of the ICO.
     *
     * @param _beneficiary address of the beneficiary.
     */
    function setBeneficiary(address _beneficiary) public onlyOwner {
        require(_beneficiary != address(0));

        beneficiary = _beneficiary;
    }

    /**
     * @dev This creates and sends FFT tokens to `_address` considering amount funded and `conversionRate`.
     *
     * @param _address address of the receiver of FFT tokens.
     * @param _amount amount of received funds in ether.
     */
    function receiveFunds(address _address, uint256 _amount) internal {
        validateTransaction();

        uint256 tokens = calculateTokens(_amount);
        require(tokens > 0);

        totalRaised = totalRaised.plus(_amount);
        handleTokens(_address, tokens);
        handleFunds(_address, _amount);

        emit FundsReceived(_address, msg.value, tokens);
    }

    /**
     * @dev this overridable function returns the current conversion rate for the ICO
     */
    function getConversionRate() public view returns (uint256) {
        return conversionRate;
    }

    /**
     * @dev this overridable function that calculates the tokens based on the ether amount
     */
    function calculateTokens(uint256 _amount) internal view returns(uint256 tokens) {
        tokens = _amount.mul(getConversionRate());
    }

    /**
     * @dev It throws an exception if the transaction does not meet the preconditions.
     */
    function validateTransaction() internal view {
        require(msg.value != 0);
        require(now >= startTime && now < endTime);
    }

    /**
     * @dev This checks whether the ICO passed `endtime`.
     *
     * @return true if the ICO is passed its deadline.
     */
    function hasEnded() public view returns (bool) {
        return now >= endTime;
    }
}

/**
 * 
 * @title   StandardMintableToken
 * 
 * @dev     StandardMintableToken is a MintableToken
 * 
 */
contract StandardMintableToken is MintableToken {
    constructor(address _minter, string _name, string _symbol, uint8 _decimals)
        StandardToken(_name, _symbol, _decimals)
        MintableToken(_minter)
        public
    {
    }
}

/**
 * @title The ICO With Mintable Token
 */
contract MintableTokenFundraiser is BasicFundraiser {
    /**
     * @dev The initialization method that creates a new mintable token.
     *
     * @param _name Token name
     * @param _symbol Token symbol
     * @param _decimals Token decimals
     */
    function initializeMintableTokenFundraiser(string _name, string _symbol, uint8 _decimals) internal {
        token = new StandardMintableToken(
            address(this), // The ICO is the token minter
            _name,
            _symbol,
            _decimals
        );
    }

    /**
     * @dev This mints the specific amount of FFTT tokens
     */
    function handleTokens(address _address, uint256 _tokens) internal {
        MintableToken(token).mint(_address, _tokens);
    }
}

/**
 * @title ICO with individual caps
 *
 * @dev This allows you to set a hard cap on the ICO.
 */
contract IndividualCapsFundraiser is BasicFundraiser {
    uint256 public individualMinCap;
    uint256 public individualMaxCap;
    uint256 public individualMaxCapTokens;


    event IndividualMinCapChanged(uint256 _individualMinCap);
    event IndividualMaxCapTokensChanged(uint256 _individualMaxCapTokens);

    /**
     * @dev The initialization method.
     *
     * @param _individualMinCap The minimum amount of ether contribution per address.
     * @param _individualMaxCap The maximum amount of ether contribution per address.
     */
    function initializeIndividualCapsFundraiser(uint256 _individualMinCap, uint256 _individualMaxCap) internal {
        individualMinCap = _individualMinCap;
        individualMaxCap = _individualMaxCap;
        individualMaxCapTokens = _individualMaxCap * conversionRate;
    }

    function setConversionRate(uint256 _conversionRate) public onlyOwner {
        super.setConversionRate(_conversionRate);

        if (individualMaxCap == 0) {
            return;
        }
        
        individualMaxCapTokens = individualMaxCap * _conversionRate;

        emit IndividualMaxCapTokensChanged(individualMaxCapTokens);
    }

    function setIndividualMinCap(uint256 _individualMinCap) public onlyOwner {
        individualMinCap = _individualMinCap;

        emit IndividualMinCapChanged(individualMinCap);
    }

    function setIndividualMaxCap(uint256 _individualMaxCap) public onlyOwner {
        individualMaxCap = _individualMaxCap;
        individualMaxCapTokens = _individualMaxCap * conversionRate;

        emit IndividualMaxCapTokensChanged(individualMaxCapTokens);
    }

    /**
     * @dev This extends the transaction validation to check if the value this higher than the minumum cap.
     */
    function validateTransaction() internal view {
        super.validateTransaction();
        require(msg.value >= individualMinCap);
    }

    /**
     * @dev This validates the new amount doesn&#39;t surpass maximum contribution cap
     */
    function handleTokens(address _address, uint256 _tokens) internal {
        require(individualMaxCapTokens == 0 || token.balanceOf(_address).plus(_tokens) <= individualMaxCapTokens);

        super.handleTokens(_address, _tokens);
    }
}

/**
 * @title GasPriceLimitFundraiser
 *
 * @dev This ICO allows to set gas price limit for the participants in the ICO
 */
contract GasPriceLimitFundraiser is HasOwner, BasicFundraiser {
    uint256 public gasPriceLimit;

    event GasPriceLimitChanged(uint256 gasPriceLimit);

    /**
     * @dev This function puts the initial gas limit
     */
    function initializeGasPriceLimitFundraiser(uint256 _gasPriceLimit) internal {
        gasPriceLimit = _gasPriceLimit;
    }

    /**
     * @dev This function allows the owner to change the gas limit any time during the ICO
     */
    function changeGasPriceLimit(uint256 _gasPriceLimit) onlyOwner() public {
        gasPriceLimit = _gasPriceLimit;

        emit GasPriceLimitChanged(_gasPriceLimit);
    }

    /**
     * @dev This transaction is valid if the gas price limit is lifted-off or the transaction meets the requirement
     */
    function validateTransaction() internal view {
        require(gasPriceLimit == 0 || tx.gasprice <= gasPriceLimit);

        return super.validateTransaction();
    }
}

/**
 * @title This forward Funds to Beneficiary of the ICO
 *
 * @dev This contract forwards the funds received to the beneficiary.
 */
contract ForwardFundsFundraiser is BasicFundraiser {
    /**
     * @dev this forwards funds directly to beneficiary
     */
    function handleFunds(address, uint256 _ethers) internal {
        // Forward the funds directly to the beneficiary
        beneficiary.transfer(_ethers);
    }
}

/**
 * @title   This is the FishFarmTestToken 
 * 
 * @dev     FishFarmTestToken is a MintableToken, mint with each incoming eth
 *          Name    :   The Fish Farm Test Token
 *          Symbol  :   FFTT
 *          Decimals:   18
 */
 
contract FishFarmTestToken is MintableToken {
  constructor(address _minter)
    StandardToken(
      "The Fish Farm Token",   // Token name
      "FFTT", // Token symbol
      18  // Token decimals
    )
    
    MintableToken(_minter) public { }
}

/**
 * @title   FishFarmTestTokenICO
 * 
 * @dev     Creates the FishFarmTestToken, sets the start and end date of the ICO, sets the initial conversionRate & sets the 
 *          Beneficiary address
 * 
 *          Start date      :Monday 05th Oct 2018
 *          End date        :Tues 1st Jan 2019 14:01 UTC
 * 
 *          Beneficiary     :0x75E5E03eDB609f5f4b9A0C2FFf5D07Cfd5182b12 at time of deployment
 *          conversionRate  :200000 at time of deployment
 */

contract FishFarmTestTokenICO is MintableTokenFundraiser, IndividualCapsFundraiser, ForwardFundsFundraiser, GasPriceLimitFundraiser {
  

  constructor()
    HasOwner(msg.sender)
    public
  {
    token = new FishFarmTestToken(
      
      address(this)  // The ICO is the minter
    );

    initializeBasicFundraiser(
      1541426707, // Start Date = Monday 2018 23:44:19
      1543319386, // End date = Tues 1st Jan 2019 14:01 UTC
      200, // Conversion rate = 200 FFTT for 1 ether
      0x90A29a1C71611B80568342824A94D52800A1Aa84     // Beneficiary
    );

    initializeIndividualCapsFundraiser(
      (0.0001 ether), // Minimum contribution
      (0 ether)  // Maximum individual cap
    );

    initializeGasPriceLimitFundraiser(
        0 // Gas price limit in wei
    );
    
  }
  
}