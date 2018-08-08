pragma solidity 0.4.21;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

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

/**
 * @title Authorizable
 * @dev The Authorizable contract has authorized addresses, and provides basic authorization control
 * functions, this simplifies the implementation of "multiple user permissions".
 */
contract Authorizable is Ownable {
    
    mapping(address => bool) public authorized;
    event AuthorizationSet(address indexed addressAuthorized, bool indexed authorization);

    /**
     * @dev The Authorizable constructor sets the first `authorized` of the contract to the sender
     * account.
     */
    function Authorizable() public {
        authorize(msg.sender);
    }

    /**
     * @dev Throws if called by any account other than the authorized.
     */
    modifier onlyAuthorized() {
        require(authorized[msg.sender]);
        _;
    }

    /**
     * @dev Allows 
     * @param _address The address to change authorization.
     */
    function authorize(address _address) public onlyOwner {
        require(!authorized[_address]);
        emit AuthorizationSet(_address, true);
        authorized[_address] = true;
    }
    /**
     * @dev Disallows
     * @param _address The address to change authorization.
     */
    function deauthorize(address _address) public onlyOwner {
        require(authorized[_address]);
        emit AuthorizationSet(_address, false);
        authorized[_address] = false;
    }
}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title PrivateSaleExchangeRate interface
 */
contract PrivateSaleExchangeRate {
    uint256 public rate;
    uint256 public timestamp;
    event UpdateUsdEthRate(uint _rate);
    function updateUsdEthRate(uint _rate) public;
    function getTokenAmount(uint256 _weiAmount) public view returns (uint256);
}

/**
 * @title Whitelist interface
 */
contract Whitelist {
    mapping(address => bool) whitelisted;
    event AddToWhitelist(address _beneficiary);
    event RemoveFromWhitelist(address _beneficiary);
    function isWhitelisted(address _address) public view returns (bool);
    function addToWhitelist(address _beneficiary) public;
    function removeFromWhitelist(address _beneficiary) public;
}

// -----------------------------------------
// -----------------------------------------
// -----------------------------------------
// Crowdsale
// -----------------------------------------
// -----------------------------------------
// -----------------------------------------

contract Crowdsale {
    using SafeMath for uint256;

    // The token being sold
    ERC20 public token;

    // Address where funds are collected
    address public wallet;

    // How many token units a buyer gets per wei
    PrivateSaleExchangeRate public rate;

    // Amount of wei raised
    uint256 public weiRaised;
    
    // Amount of wei raised (token)
    uint256 public tokenRaised;

    /**
    * Event for token purchase logging
    * @param purchaser who paid for the tokens
    * @param beneficiary who got the tokens
    * @param value weis paid for purchase
    * @param amount amount of tokens purchased
    */
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    /**
    * @param _rate Number of token units a buyer gets per wei
    * @param _wallet Address where collected funds will be forwarded to
    * @param _token Address of the token being sold
    */
    function Crowdsale(PrivateSaleExchangeRate _rate, address _wallet, ERC20 _token) public {
        require(_rate.rate() > 0);
        require(_token != address(0));
        require(_wallet != address(0));

        rate = _rate;
        token = _token;
        wallet = _wallet;
    }

    // -----------------------------------------
    // Crowdsale external interface
    // -----------------------------------------

    /**
    * @dev fallback function ***DO NOT OVERRIDE***
    */
    function () external payable {
        buyTokens(msg.sender);
    }

    /**
    * @dev low level token purchase ***DO NOT OVERRIDE***
    * @param _beneficiary Address performing the token purchase
    */
    function buyTokens(address _beneficiary) public payable {

        uint256 weiAmount = msg.value;
        
         // calculate token amount to be created
        uint256 tokenAmount = _getTokenAmount(weiAmount);
        
        _preValidatePurchase(_beneficiary, weiAmount, tokenAmount);

        // update state
        weiRaised = weiRaised.add(weiAmount);
        tokenRaised = tokenRaised.add(tokenAmount);

        _processPurchase(_beneficiary, tokenAmount);
        emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokenAmount);

        _updatePurchasingState(_beneficiary, weiAmount);

        _forwardFunds();
        _postValidatePurchase(_beneficiary, weiAmount);
    }

    // -----------------------------------------
    // Internal interface (extensible)
    // -----------------------------------------

    /**
    * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use super to concatenate validations.
    * @param _beneficiary Address performing the token purchase
    * @param _weiAmount Value in wei involved in the purchase
    */
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount, uint256 _tokenAmount) internal {
        require(_beneficiary != address(0));
        require(_weiAmount > 0);
        require(_tokenAmount > 0);
    }

    /**
    * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid conditions are not met.
    * @param _beneficiary Address performing the token purchase
    * @param _weiAmount Value in wei involved in the purchase
    */
    function _postValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
        // optional override
    }

    /**
    * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
    * @param _beneficiary Address performing the token purchase
    * @param _tokenAmount Number of tokens to be emitted
    */
    function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
        token.transfer(_beneficiary, _tokenAmount);
    }
    
    /**
    * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
    * @param _beneficiary Address receiving the tokens
    * @param _tokenAmount Number of tokens to be purchased
    */
    function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
        _deliverTokens(_beneficiary, _tokenAmount);
    }

    /**
    * @dev Override for extensions that require an internal state to check for validity (current user contributions, etc.)
    * @param _beneficiary Address receiving the tokens
    * @param _weiAmount Value in wei involved in the purchase
    */
    function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal {
        // optional override
    }

    /**
    * @dev Override to extend the way in which ether is converted to tokens.
    * @param _weiAmount Value in wei to be converted into tokens
    * @return Number of tokens that can be purchased with the specified _weiAmount
    */
    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
        return rate.getTokenAmount(_weiAmount);
    }

    /**
    * @dev Determines how ETH is stored/forwarded on purchases.
    */
    function _forwardFunds() internal {
        wallet.transfer(msg.value);
    }
}

/**
 * @title TimedCrowdsale
 * @dev Crowdsale accepting contributions only within a time frame.
 */
contract TimedCrowdsale is Crowdsale {
    using SafeMath for uint256;

    uint256 public openingTime;
    uint256 public closingTime;

    /**
     * @dev Reverts if not in crowdsale time range. 
    */
    modifier onlyWhileOpen {
        require(now >= openingTime && now <= closingTime);
        _;
    }

    /**
     * @dev Constructor, takes crowdsale opening and closing times.
     * @param _openingTime Crowdsale opening time
     * @param _closingTime Crowdsale closing time
     */
    function TimedCrowdsale(uint256 _openingTime, uint256 _closingTime) public {
        
        require(_closingTime >= now);
         
        require(_closingTime >= _openingTime);
        openingTime = _openingTime;
        closingTime = _closingTime;
    }

    /**
     * @dev Checks whether the period in which the crowdsale is open has already elapsed.
     * @return Whether crowdsale period has elapsed
     */
    function hasClosed() public view returns (bool) {
        return now > closingTime;
    }

    /**
     * @dev Checks whether the period in which the crowdsale is opened.
     * @return Whether crowdsale period has elapsed
     */
    function hasOpening() public view returns (bool) {
        return (now >= openingTime && now <= closingTime);
    }
  
    /**
     * @dev Extend parent behavior requiring to be within contributing period
     * @param _beneficiary Token purchaser
     * @param _weiAmount Amount of wei contributed
     */
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount, uint256 _tokenAmount) internal onlyWhileOpen {
        super._preValidatePurchase(_beneficiary, _weiAmount, _tokenAmount);
    }

}

/**
 * @title AllowanceCrowdsale
 * @dev Extension of Crowdsale where tokens are held by a wallet, which approves an allowance to the crowdsale.
 */
contract AllowanceCrowdsale is Crowdsale {
    using SafeMath for uint256;
    address public tokenWallet;

    /**
    * @dev Constructor, takes token wallet address. 
    * @param _tokenWallet Address holding the tokens, which has approved allowance to the crowdsale
    */
    function AllowanceCrowdsale(address _tokenWallet) public {
        require(_tokenWallet != address(0));
        tokenWallet = _tokenWallet;
    }

    /**
    * @dev Overrides parent behavior by transferring tokens from wallet.
    * @param _beneficiary Token purchaser
    * @param _tokenAmount Amount of tokens purchased
    */
    function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
        token.transferFrom(tokenWallet, _beneficiary, _tokenAmount);
    }
}

/**
 * @title CappedCrowdsale
 * @dev Crowdsale with a limit for total contributions.
 */
contract CappedCrowdsale is Crowdsale {
    using SafeMath for uint256;

    uint256 public minWei;
    uint256 public capToken;

    /**
    * @dev Constructor, takes maximum amount of wei accepted in the crowdsale.
    * @param _capToken Max amount of token to be contributed
    */
    function CappedCrowdsale(uint256 _capToken, uint256 _minWei) public {
        require(_minWei > 0);
        require(_capToken > 0);
        minWei = _minWei;
        capToken = _capToken;
    }

    /**
    * @dev Checks whether the cap has been reached. 
    * @return Whether the cap was reached
    */
    function capReached() public view returns (bool) {
        if(tokenRaised >= capToken) return true;
        uint256 minTokens = rate.getTokenAmount(minWei);
        if(capToken - tokenRaised <= minTokens) return true;
        return false;
    }

    /**
    * @dev Extend parent behavior requiring purchase to respect the funding cap.
    * @param _beneficiary Token purchaser
    * @param _weiAmount Amount of wei contributed
    */
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount, uint256 _tokenAmount) internal {
        super._preValidatePurchase(_beneficiary, _weiAmount, _tokenAmount);
        require(_weiAmount >= minWei);
        require(tokenRaised.add(_tokenAmount) <= capToken);
    }
}

/**
 * @title WhitelistedCrowdsale
 * @dev Crowdsale with a limit for total contributions.
 */
contract WhitelistedCrowdsale is Crowdsale {
    using SafeMath for uint256;

    // Only KYC investor allowed to buy the token
    Whitelist public whitelist;

    /**
    * @dev Constructor, takes maximum amount of wei accepted in the crowdsale.
    * @param _whitelist whitelist contract
    */
    function WhitelistedCrowdsale(Whitelist _whitelist) public {
        whitelist = _whitelist;
    }

    function isWhitelisted(address _address) public view returns (bool) {
        return whitelist.isWhitelisted(_address);
    }

    /**
    * @dev Extend parent behavior requiring purchase to respect the funding cap.
    * @param _beneficiary Token purchaser
    * @param _weiAmount Amount of wei contributed
    */
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount, uint256 _tokenAmount) internal {
        super._preValidatePurchase(_beneficiary, _weiAmount, _tokenAmount);
        require(whitelist.isWhitelisted(_beneficiary));
    }
}

/**
 * @title ClaimedCrowdsale
 * @dev Extension of Crowdsale where tokens are held by a wallet, which approves an allowance to the crowdsale.
 */
contract ClaimCrowdsale is Crowdsale, Authorizable {
    using SafeMath for uint256;
    
    uint256 divider;
    event ClaimToken(address indexed claimant, address indexed beneficiary, uint256 claimAmount);
     
    // Claim remain amount of token
    //addressIndices not use index 0 
    address[] public addressIndices;

    // get amount of claim token
    mapping(address => uint256) mapAddressToToken;
    
    //get index of addressIndices if = 0 >> not found
    mapping(address => uint256) mapAddressToIndex;
    
     // Amount of wei waiting for claim (token)
    uint256 public waitingForClaimTokens;

    /**
    * @dev Constructor, takes token wallet address. 
    */
    function ClaimCrowdsale(uint256 _divider) public {
        require(_divider > 0);
        divider = _divider;
        addressIndices.push(address(0));
    }
    
    /**
    * @dev Claim remained token after closed time
    */
    function claim(address _beneficiary) public onlyAuthorized {
       
        require(_beneficiary != address(0));
        require(mapAddressToToken[_beneficiary] > 0);
        
        // remove from list
        uint indexToBeDeleted = mapAddressToIndex[_beneficiary];
        require(indexToBeDeleted != 0);
        
        uint arrayLength = addressIndices.length;
        // if index to be deleted is not the last index, swap position.
        if (indexToBeDeleted < arrayLength-1) {
            // swap 
            addressIndices[indexToBeDeleted] = addressIndices[arrayLength-1];
            mapAddressToIndex[addressIndices[indexToBeDeleted]] = indexToBeDeleted;
        }
         // we can now reduce the array length by 1
        addressIndices.length--;
        mapAddressToIndex[_beneficiary] = 0;
        
        // deliver token
        uint256 _claimAmount = mapAddressToToken[_beneficiary];
        mapAddressToToken[_beneficiary] = 0;
        waitingForClaimTokens = waitingForClaimTokens.sub(_claimAmount);
        emit ClaimToken(msg.sender, _beneficiary, _claimAmount);
        
        _deliverTokens(_beneficiary, _claimAmount);
    }
    
    function checkClaimTokenByIndex(uint index) public view returns (uint256){
        require(index >= 0);
        require(index < addressIndices.length);
        return checkClaimTokenByAddress(addressIndices[index]);
    }
    
    function checkClaimTokenByAddress(address _beneficiary) public view returns (uint256){
        require(_beneficiary != address(0));
        return mapAddressToToken[_beneficiary];
    }
    function countClaimBackers()  public view returns (uint256) {
        return addressIndices.length-1;
    }
    
    function _addToClaimList(address _beneficiary, uint256 _claimAmount) internal {
        require(_beneficiary != address(0));
        require(_claimAmount > 0);
        
        if(mapAddressToToken[_beneficiary] == 0){
            addressIndices.push(_beneficiary);
            mapAddressToIndex[_beneficiary] = addressIndices.length-1;
        }
        waitingForClaimTokens = waitingForClaimTokens.add(_claimAmount);
        mapAddressToToken[_beneficiary] = mapAddressToToken[_beneficiary].add(_claimAmount);
    }

   
    /**
     * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
     * @param _beneficiary Address receiving the tokens
     * @param _tokenAmount Number of tokens to be purchased
     */
    function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
        
        // To protect our private-sale investors who transfered eth via wallet from exchange.
        // Instead of send all tokens amount back, the private-sale contract will send back in small portion of tokens (ppm). 
        // The full amount of tokens will be send later after the investor has confirmed received amount to us.
        uint256 tokenSampleAmount = _tokenAmount.div(divider);

        _addToClaimList(_beneficiary, _tokenAmount.sub(tokenSampleAmount));
        _deliverTokens(_beneficiary, tokenSampleAmount);
    }
}

// -----------------------------------------
// -----------------------------------------
// -----------------------------------------
// ZMINE
// -----------------------------------------
// -----------------------------------------
// -----------------------------------------

/**
 * @title ZminePrivateSale
 */
contract ZminePrivateSale is ClaimCrowdsale
                                , AllowanceCrowdsale
                                , CappedCrowdsale
                                , TimedCrowdsale
                                , WhitelistedCrowdsale {
    using SafeMath for uint256;
    
    /**
     * @param _rate Number of token units a buyer gets per wei
     * @param _whitelist Allowd address of buyer
     * @param _wallet Address where collected funds will be forwarded to
     * @param _token Address of the token being sold
     */
    function ZminePrivateSale(PrivateSaleExchangeRate _rate
                                , Whitelist _whitelist
                                , uint256 _capToken
                                , uint256 _minWei
                                , uint256 _openingTime
                                , uint256 _closingTime
                                , address _wallet
                                , address _tokenWallet
                                , ERC20 _token
    ) public 
        Crowdsale(_rate, _wallet, _token) 
        ClaimCrowdsale(1000000)
        AllowanceCrowdsale(_tokenWallet) 
        CappedCrowdsale(_capToken, _minWei)
        TimedCrowdsale(_openingTime, _closingTime) 
        WhitelistedCrowdsale(_whitelist)
    {
        
        
        
    }

    function calculateTokenAmount(uint256 _weiAmount)  public view returns (uint256) {
        return rate.getTokenAmount(_weiAmount);
    }
    
     /**
      * @dev Checks the amount of tokens left in the allowance.
      * @return Amount of tokens left in the allowance
      */
    function remainingTokenForSale() public view returns (uint256) {
        uint256 allowanceTokenLeft = (token.allowance(tokenWallet, this)).sub(waitingForClaimTokens);
        uint256 balanceTokenLeft = (token.balanceOf(tokenWallet)).sub(waitingForClaimTokens);
        if(allowanceTokenLeft < balanceTokenLeft) return allowanceTokenLeft;
        return balanceTokenLeft;
    }
    
     /**
     * @dev Extend parent behavior requiring to be within contributing period
     * @param _beneficiary Token purchaser
     * @param _weiAmount Amount of wei contributed
     */
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount, uint256 _tokenAmount) internal {
        super._preValidatePurchase(_beneficiary, _weiAmount, _tokenAmount);
        require(remainingTokenForSale().sub(_tokenAmount) >= 0);
    }
}

// -----------------------------------------
// -----------------------------------------
// -----------------------------------------