/**
 *Submitted for verification at BscScan.com on 2021-09-24
*/

pragma solidity ^0.4.18;



// File: contracts/ERC20Basic.sol


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    uint256 totalSupply_;

    /**
    * @dev total number of tokens in existence
    */
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

}

// File: contracts/ERC20.sol

pragma solidity ^0.4.18;



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

// File: contracts/StandardToken.sol

pragma solidity ^0.4.18;




/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;


    /**
    * @dev Transfer tokens from one address to another
    * @param _from address The address which you want to send tokens from
    * @param _to address The address which you want to transfer to
    * @param _value uint256 the amount of tokens to be transferred
    */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
    * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    *
    * Beware that changing an allowance with this method brings the risk that someone may use both the old
    * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
    * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
    * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    * @param _spender The address which will spend the funds.
    * @param _value The amount of tokens to be spent.
    */
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
    * @dev Function to check the amount of tokens that an owner allowed to a spender.
    * @param _owner address The address which owns the funds.
    * @param _spender address The address which will spend the funds.
    * @return A uint256 specifying the amount of tokens still available for the spender.
    */
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    /**
    * @dev Increase the amount of tokens that an owner allowed to a spender.
    *
    * approve should be called when allowed[_spender] == 0. To increment
    * allowed value is better to use this function to avoid 2 calls (and wait until
    * the first transaction is mined)
    * From MonolithDAO Token.sol
    * @param _spender The address which will spend the funds.
    * @param _addedValue The amount of tokens to increase the allowance by.
    */
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
    * @dev Decrease the amount of tokens that an owner allowed to a spender.
    *
    * approve should be called when allowed[_spender] == 0. To decrement
    * allowed value is better to use this function to avoid 2 calls (and wait until
    * the first transaction is mined)
    * From MonolithDAO Token.sol
    * @param _spender The address which will spend the funds.
    * @param _subtractedValue The amount of tokens to decrease the allowance by.
    */
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

// File: contracts/Ownable.sol

pragma solidity ^0.4.18;


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

// // File: contracts/GStarToken.sol

// pragma solidity ^0.4.18;




// contract GStarToken is StandardToken, Ownable {
//     using SafeMath for uint256;

//     string public constant name = "GSTAR Token";
//     string public constant symbol = "GSTAR";
//     uint8 public constant decimals = 18;

//     uint256 public constant INITIAL_SUPPLY = 1600000000 * ((10 ** uint256(decimals)));
//     uint256 public currentTotalSupply = 0;

//     event Burn(address indexed burner, uint256 value);


//     /**
//     * @dev Constructor that gives msg.sender all of existing tokens.
//     */
//     function GStarToken() public {
//         owner = msg.sender;
//         totalSupply_ = INITIAL_SUPPLY;
//         balances[owner] = INITIAL_SUPPLY;
//         currentTotalSupply = INITIAL_SUPPLY;
//         emit Transfer(address(0), owner, INITIAL_SUPPLY);
//     }

//     /**
//     * @dev Burns a specific amount of tokens.
//     * @param value The amount of token to be burned.
//     */
//     function burn(uint256 value) public onlyOwner {
//         require(value <= balances[msg.sender]);

//         address burner = msg.sender;
//         balances[burner] = balances[burner].sub(value);
//         currentTotalSupply = currentTotalSupply.sub(value);
//         emit Burn(burner, value);
//     }
// }

// File: contracts/Crowdsale.sol

pragma solidity ^0.4.18;



/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale,
 * allowing investors to purchase tokens with ether. This contract implements
 * such functionality in its most fundamental form and can be extended to provide additional
 * functionality and/or custom behavior.
 * The external interface represents the basic interface for purchasing tokens, and conform
 * the base architecture for crowdsales. They are *not* intended to be modified / overriden.
 * The internal interface conforms the extensible and modifiable surface of crowdsales. Override
 * the methods to add functionality. Consider using 'super' where appropiate to concatenate
 * behavior.
 */

contract Crowdsale {
    using SafeMath for uint256;

    // The token being sold
    ERC20 public token;

    // Address where funds are collected
    address public wallet;

    // How many token units a buyer gets per wei
    uint256 public rate;

    // Amount of wei raised
    uint256 public weiRaised;

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
    function Crowdsale(uint256 _rate, address _wallet, ERC20 _token) public {
        require(_rate > 0);
        require(_wallet != address(0));
        require(_token != address(0));

        rate = _rate;
        wallet = _wallet;
        token = _token;
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
        _preValidatePurchase(_beneficiary, weiAmount);

        // calculate token amount to be created
        uint256 tokens = _getTokenAmount(weiAmount);

        // update state
        weiRaised = weiRaised.add(weiAmount);

        _processPurchase(_beneficiary, tokens);
        emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);

        _updatePurchasingState(_beneficiary, weiAmount);

        _forwardFunds();
        _postValidatePurchase(_beneficiary, weiAmount);
    }

    // -----------------------------------------
    // Internal interface (extensible)
    // -----------------------------------------

    /**
    * @dev Validation of an incoming purchase. Use require statemens to revert state when conditions are not met. Use super to concatenate validations.
    * @param _beneficiary Address performing the token purchase
    * @param _weiAmount Value in wei involved in the purchase
    */
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
        require(_beneficiary != address(0));
        require(_weiAmount != 0);
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
        return _weiAmount.mul(rate);
    }

    /**
    * @dev Determines how ETH is stored/forwarded on purchases.
    */
    function _forwardFunds() internal {
        wallet.transfer(msg.value);
    }
}

// File: contracts/WhitelistedCrowdsale.sol

pragma solidity ^0.4.18;




/**
 * @title WhitelistedCrowdsale
 * @dev Crowdsale in which only whitelisted users can contribute.
 */
contract WhitelistedCrowdsale is Crowdsale, Ownable {

    mapping(address => bool) public whitelist;

    /**
    * @dev Reverts if beneficiary is not whitelisted. Can be used when extending this contract.
    */
    modifier isWhitelisted(address _beneficiary) {
        require(whitelist[_beneficiary]);
        _;
    }

    /**
    * @dev Adds single address to whitelist.
    * @param _beneficiary Address to be added to the whitelist
    */
    function addToWhitelist(address _beneficiary) external onlyOwner {
        whitelist[_beneficiary] = true;
    }

    /**
    * @dev Adds list of addresses to whitelist. Not overloaded due to limitations with truffle testing.
    * @param _beneficiaries Addresses to be added to the whitelist
    */
    function addManyToWhitelist(address[] _beneficiaries) external onlyOwner {
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            whitelist[_beneficiaries[i]] = true;
        }
    }

    /**
    * @dev Removes single address from whitelist.
    * @param _beneficiary Address to be removed to the whitelist
    */
    function removeFromWhitelist(address _beneficiary) external onlyOwner {
        whitelist[_beneficiary] = false;
    }

    /**
    * @dev Extend parent behavior requiring beneficiary to be in whitelist.
    * @param _beneficiary Token beneficiary
    * @param _weiAmount Amount of wei contributed
    */
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal isWhitelisted(_beneficiary) {
        super._preValidatePurchase(_beneficiary, _weiAmount);
    }

}








// File: contracts/SafeMath.sol

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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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

// File: contracts/GStarCrowdsale.sol

pragma solidity ^0.4.18;






/**
 * @title GStarCrowdsale
 * @dev This contract manages the crowdsale of GStar Tokens.
 * The crowdsale will involve two key timings - Start and ending of funding.
 * The earlier the contribution, the larger the bonuses. (according to the bonus structure)
 * Tokens will be released to the contributors after the crowdsale.
 * There is only one owner at any one time. The owner can stop or start the crowdsale at anytime.
 */
contract GStarCrowdsale is WhitelistedCrowdsale {
    using SafeMath for uint256;

    // Start and end timestamps where contributions are allowed (both inclusive)
    // All timestamps are expressed in seconds instead of block number.
    uint256 constant public presaleStartTime = 1632588900; // 8 Jul 2018 1200h
    uint256 constant public startTime = 1632589080; // 22 Jul 2018 1200h
    uint256 constant public endTime = 1632589200; // 18 Aug 2018 1200h

    // Keeps track of contributors tokens
    mapping (address => uint256) public depositedTokens;

    // Minimum amount of ETH contribution during ICO period
    // Minimum of ETH contributed during ICO is 0.1ETH
    uint256 constant public MINIMUM_PRESALE_PURCHASE_AMOUNT_IN_WEI = 0.01 ether;
    uint256 constant public MINIMUM_PURCHASE_AMOUNT_IN_WEI = 0.001 ether;

    // Total tokens raised so far, bonus inclusive
    uint256 public tokensWeiRaised = 0;

    //Funding goal is 76,000 ETH, includes private contributions
    uint256 constant public fundingGoal = 0.5 ether;
    uint256 constant public presaleFundingGoal = 0.2 ether;
    bool public fundingGoalReached = false;
    bool public presaleFundingGoalReached = false;

    //private contributions
    uint256 public privateContribution = 0;

    // Indicates if crowdsale is active
    bool public crowdsaleActive = false;
    bool public isCrowdsaleClosed = false;

    uint256 public tokensReleasedAmount = 0;


    /*==================================================================== */
    /*============================== EVENTS ============================== */
    /*==================================================================== */

    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    event GoalReached(uint256 totalEtherAmountRaised);
    event PresaleGoalReached(uint256 totalEtherAmountRaised);
    event StartCrowdsale();
    event StopCrowdsale();
    event ReleaseTokens(address[] _beneficiaries);
    event Close();

    /**
    * @dev Constructor. Checks validity of the time entered.
    */
    function GStarCrowdsale (
        uint256 _rate,
        address _wallet,
        ERC20 token
        ) public Crowdsale(_rate, _wallet, token) {
    }


    /*==================================================================== */
    /*========================= PUBLIC FUNCTIONS ========================= */
    /*==================================================================== */

    /**
    * @dev Override buyTokens function as tokens should only be delivered when released.
    * @param _beneficiary Address receiving the tokens.
    */
    function buyTokens(address _beneficiary) public payable {

        uint256 weiAmount = msg.value;
        _preValidatePurchase(_beneficiary, weiAmount);

        // calculate token amount to be created
        uint256 tokens = _getTokenAmount(weiAmount);

        // update state
        weiRaised = weiRaised.add(weiAmount);
        
        emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);

        _updatePurchasingState(_beneficiary, weiAmount);

        _forwardFunds();
        _processPurchase(_beneficiary, weiAmount);
    }

    /**
    * @dev Calculates the token amount per ETH contributed based on the time now.
    * @return Rate of amount of GSTAR per Ether as of current time.
    */
    function getRate() public view returns (uint256) {
        //calculate bonus based on timing
        if (block.timestamp <= startTime) { return ((rate / 100) * 120); } // 20 percent bonus on presale period, returns 12000
        if (block.timestamp <= startTime.add(1 days)) {return ((rate / 100) * 108);} // 8 percent bonus on day one, return 10800

        return rate;
    }


    /*==================================================================== */
    /*======================== EXTERNAL FUNCTIONS ======================== */
    /*==================================================================== */

    /**
    * @dev Change the private contribution, in ether, wei units.
    * Private contribution amount will be calculated into funding goal.
    */
    function changePrivateContribution(uint256 etherWeiAmount) external onlyOwner {
        privateContribution = etherWeiAmount;
    }

    /**
    * @dev Allows owner to start/unpause crowdsale.
    */
    function startCrowdsale() external onlyOwner {
        require(!crowdsaleActive);
        require(!isCrowdsaleClosed);

        crowdsaleActive = true;
        emit StartCrowdsale();
    }

    /**
    * @dev Allows owner to stop/pause crowdsale.
    */
    function stopCrowdsale() external onlyOwner {
        require(crowdsaleActive);
        crowdsaleActive = false;
        emit StopCrowdsale();
    }

    /**
    * @dev Release tokens to multiple addresses.
    * @param contributors Addresses to release tokens to
    */
    function releaseTokens(address[] contributors) external onlyOwner {

        for (uint256 j = 0; j < contributors.length; j++) {

            // the amount of tokens to be distributed to contributor
            uint256 tokensAmount = depositedTokens[contributors[j]];

            if (tokensAmount > 0) {
                super._deliverTokens(contributors[j], tokensAmount);

                depositedTokens[contributors[j]] = 0;

                //update state of release
                tokensReleasedAmount = tokensReleasedAmount.add(tokensAmount);
            }
        }
    }

    /**
    * @dev Stops crowdsale and release of tokens. Transfer remainining tokens back to owner.
    */
    function close() external onlyOwner {
        crowdsaleActive = false;
        isCrowdsaleClosed = true;
        
        token.transfer(owner, token.balanceOf(address(this)));
        emit Close();
    }


    /*==================================================================== */
    /*======================== INTERNAL FUNCTIONS ======================== */
    /*==================================================================== */

    /**
    * @dev Overrides _preValidatePurchase function in Crowdsale.
    * Requires purchase is made within crowdsale period.
    * Requires contributor to be the beneficiary.
    * Requires purchase value and address to be non-zero.
    * Requires amount not to exceed funding goal.
    * Requires purchase value to be higher or equal to minimum amount.
    * Requires contributor to be whitelisted.
    */
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
        bool withinPeriod = now >= presaleStartTime && now <= endTime;

        bool atLeastMinimumAmount = false;

        if(block.timestamp <= startTime) {
            // during presale period

            require(_weiAmount.add(weiRaised.add(privateContribution)) <= presaleFundingGoal);
            atLeastMinimumAmount = _weiAmount >= MINIMUM_PRESALE_PURCHASE_AMOUNT_IN_WEI;
            
        } else {
            // during funding period
            atLeastMinimumAmount = _weiAmount >= MINIMUM_PURCHASE_AMOUNT_IN_WEI;
        }

        super._preValidatePurchase(_beneficiary, _weiAmount);
        require(msg.sender == _beneficiary);
        require(_weiAmount.add(weiRaised.add(privateContribution)) <= fundingGoal);
        require(withinPeriod);
        require(atLeastMinimumAmount);
        require(crowdsaleActive);
    }

    /**
    * @dev Overrides _getTokenAmount function in Crowdsale.
    * Calculates token amount, inclusive of bonus, based on ETH contributed.
    * @param _weiAmount Value in wei to be converted into tokens
    * @return Number of tokens that can be purchased with the specified _weiAmount
    */
    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
        return _weiAmount.mul(getRate());
    }

    /**
    * @dev Overrides _updatePurchasingState function from Crowdsale.
    * Updates tokenWeiRaised amount and funding goal status.
    */
    function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal {
        tokensWeiRaised = tokensWeiRaised.add(_getTokenAmount(_weiAmount));
        _updateFundingGoal();
    }

    /**
    * @dev Overrides _processPurchase function from Crowdsale.
    * Adds the tokens purchased to the beneficiary.
    * @param _tokenAmount The token amount in wei before multiplied by the rate.
    */
    function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
        depositedTokens[_beneficiary] = depositedTokens[_beneficiary].add(_getTokenAmount(_tokenAmount));
    }

    /**
    * @dev Updates fundingGoal status.
    */
    function _updateFundingGoal() internal {
        if (weiRaised.add(privateContribution) >= fundingGoal) {
            fundingGoalReached = true;
            emit GoalReached(weiRaised.add(privateContribution));
        }

        if(block.timestamp <= startTime) {
            if(weiRaised.add(privateContribution) >= presaleFundingGoal) {
                
                presaleFundingGoalReached = true;
                emit PresaleGoalReached(weiRaised.add(privateContribution));
            }
        }
    }



}