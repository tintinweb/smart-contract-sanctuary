/*************************************************************************
 * This contract has been merged with solidify
 * https://github.com/tiesnetwork/solidify
 *************************************************************************/
 
 pragma solidity ^0.4.18;

/*************************************************************************
 * import "./LetsbetToken.sol" : start
 *************************************************************************/

/*************************************************************************
 * import "zeppelin-solidity/contracts/token/ERC20/PausableToken.sol" : start
 *************************************************************************/

/*************************************************************************
 * import "./StandardToken.sol" : start
 *************************************************************************/

/*************************************************************************
 * import "./BasicToken.sol" : start
 *************************************************************************/


/*************************************************************************
 * import "./ERC20Basic.sol" : start
 *************************************************************************/


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
/*************************************************************************
 * import "./ERC20Basic.sol" : end
 *************************************************************************/
/*************************************************************************
 * import "../../math/SafeMath.sol" : start
 *************************************************************************/


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
/*************************************************************************
 * import "../../math/SafeMath.sol" : end
 *************************************************************************/


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
/*************************************************************************
 * import "./BasicToken.sol" : end
 *************************************************************************/
/*************************************************************************
 * import "./ERC20.sol" : start
 *************************************************************************/




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
/*************************************************************************
 * import "./ERC20.sol" : end
 *************************************************************************/


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
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
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
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
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
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}
/*************************************************************************
 * import "./StandardToken.sol" : end
 *************************************************************************/
/*************************************************************************
 * import "../../lifecycle/Pausable.sol" : start
 *************************************************************************/


/*************************************************************************
 * import "../ownership/Ownable.sol" : start
 *************************************************************************/


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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}
/*************************************************************************
 * import "../ownership/Ownable.sol" : end
 *************************************************************************/


/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}
/*************************************************************************
 * import "../../lifecycle/Pausable.sol" : end
 *************************************************************************/


/**
 * @title Pausable token
 * @dev StandardToken modified with pausable transfers.
 **/
contract PausableToken is StandardToken, Pausable {

  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}
/*************************************************************************
 * import "zeppelin-solidity/contracts/token/ERC20/PausableToken.sol" : end
 *************************************************************************/
/*************************************************************************
 * import "zeppelin-solidity/contracts/token/ERC20/BurnableToken.sol" : start
 *************************************************************************/




/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

  /**
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
  function burn(uint256 _value) public {
    require(_value <= balances[msg.sender]);
    // no need to require value <= totalSupply, since that would imply the
    // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    Burn(burner, _value);
  }
}
/*************************************************************************
 * import "zeppelin-solidity/contracts/token/ERC20/BurnableToken.sol" : end
 *************************************************************************/


/**
 * @title LetsbetToken Token
 * @dev ERC20 LetsbetToken Token (XBET)
 */
contract LetsbetToken is PausableToken, BurnableToken {

    string public constant name = "Letsbet Token";
    string public constant symbol = "XBET";
    uint8 public constant decimals = 18;

    uint256 public constant INITIAL_SUPPLY = 100000000 * 10**uint256(decimals); // 100 000 000 (100m)
    uint256 public constant TEAM_TOKENS = 18000000 * 10**uint256(decimals); // 18 000 000 (18m)
    uint256 public constant BOUNTY_TOKENS = 5000000 * 10**uint256(decimals); // 5 000 000 (5m)
    uint256 public constant AUCTION_TOKENS = 77000000 * 10**uint256(decimals); // 77 000 000 (77m)

    event Deployed(uint indexed _totalSupply);

    /**
    * @dev LetsbetToken Constructor
    */
    function LetsbetToken(
        address auctionAddress,
        address walletAddress,
        address bountyAddress)
        public
    {

        require(auctionAddress != 0x0);
        require(walletAddress != 0x0);
        require(bountyAddress != 0x0);
        
        totalSupply_ = INITIAL_SUPPLY;

        balances[auctionAddress] = AUCTION_TOKENS;
        balances[walletAddress] = TEAM_TOKENS;
        balances[bountyAddress] = BOUNTY_TOKENS;

        Transfer(0x0, auctionAddress, balances[auctionAddress]);
        Transfer(0x0, walletAddress, balances[walletAddress]);
        Transfer(0x0, bountyAddress, balances[bountyAddress]);

        Deployed(totalSupply_);
        assert(totalSupply_ == balances[auctionAddress] + balances[walletAddress] + balances[bountyAddress]);
    }
}/*************************************************************************
 * import "./LetsbetToken.sol" : end
 *************************************************************************/

/// @title Dutch auction contract - distribution of a fixed number of tokens using an auction.
/// The contract code is inspired by the Gnosis and Raiden auction contract. Main difference is that the
/// auction ends if a fixed number of tokens was sold.
contract DutchAuction {
    
	/*
     * Auction for the XBET Token.
     */
    // Wait 7 days after the end of the auction, before anyone can claim tokens
    uint constant public TOKEN_CLAIM_WAITING_PERIOD = 7 days;

    LetsbetToken public token;
    address public ownerAddress;
    address public walletAddress;

    // Starting price in WEI
    uint public startPrice;

    // Divisor constant; e.g. 180000000
    uint public priceDecreaseRate;

    // For calculating elapsed time for price
    uint public startTime;

    uint public endTimeOfBids;

    // When auction was finalized
    uint public finalizedTime;
    uint public startBlock;

    // Keep track of all ETH received in the bids
    uint public receivedWei;

    // Keep track of cumulative ETH funds for which the tokens have been claimed
    uint public fundsClaimed;

    uint public tokenMultiplier;

    // Total number of Rei (XBET * tokenMultiplier) that will be auctioned
    uint public tokensAuctioned;

    // Wei per XBET
    uint public finalPrice;

    // Bidder address => bid value
    mapping (address => uint) public bids;


    Stages public stage;

    /*
     * Enums
     */
    enum Stages {
        AuctionDeployed,
        AuctionSetUp,
        AuctionStarted,
        AuctionEnded,
        TokensDistributed
    }

    /*
     * Modifiers
     */
    modifier atStage(Stages _stage) {
        require(stage == _stage);
        _;
    }

    modifier isOwner() {
        require(msg.sender == ownerAddress);
        _;
    }
	
    /*
     * Events
     */
    event Deployed(
        uint indexed _startPrice,
        uint indexed _priceDecreaseRate
    );
    
	event Setup();
    
	event AuctionStarted(uint indexed _startTime, uint indexed _blockNumber);
    
	event BidSubmission(
        address indexed sender,
        uint amount,
        uint missingFunds,
        uint timestamp
    );
    
	event ClaimedTokens(address indexed _recipient, uint _sentAmount);
    
	event AuctionEnded(uint _finalPrice);
    
	event TokensDistributed();

    /// @dev Contract constructor function sets the starting price, divisor constant and
    /// divisor exponent for calculating the Dutch Auction price.
    /// @param _walletAddress Wallet address to which all contributed ETH will be forwarded.
    /// @param _startPrice High price in WEI at which the auction starts.
    /// @param _priceDecreaseRate Auction price decrease rate.
    /// @param _endTimeOfBids last time bids could be accepted.
    function DutchAuction(
        address _walletAddress,
        uint _startPrice,
        uint _priceDecreaseRate,
        uint _endTimeOfBids) 
    public
    {
        require(_walletAddress != 0x0);
        walletAddress = _walletAddress;

        ownerAddress = msg.sender;
        stage = Stages.AuctionDeployed;
        changeSettings(_startPrice, _priceDecreaseRate,_endTimeOfBids);
        Deployed(_startPrice, _priceDecreaseRate);
    }

    function () public payable atStage(Stages.AuctionStarted) {
        bid();
    }

    /// @notice Set `_tokenAddress` as the token address to be used in the auction.
    /// @dev Setup function sets external contracts addresses.
    /// @param _tokenAddress Token address.
    function setup(address _tokenAddress) public isOwner atStage(Stages.AuctionDeployed) {
        require(_tokenAddress != 0x0);
        token = LetsbetToken(_tokenAddress);

        // Get number of Rei (XBET * tokenMultiplier) to be auctioned from token auction balance
        tokensAuctioned = token.balanceOf(address(this));

        // Set the number of the token multiplier for its decimals
        tokenMultiplier = 10 ** uint(token.decimals());

        stage = Stages.AuctionSetUp;
        Setup();
    }

    /// @dev Changes auction price function parameters before auction is started.
    /// @param _startPrice Updated start price.
    /// @param _priceDecreaseRate Updated price decrease rate.
    function changeSettings(
        uint _startPrice,
        uint _priceDecreaseRate,
        uint _endTimeOfBids
        )
        internal
    {
        require(stage == Stages.AuctionDeployed || stage == Stages.AuctionSetUp);
        require(_startPrice > 0);
        require(_priceDecreaseRate > 0);
        require(_endTimeOfBids > now);
        
        endTimeOfBids = _endTimeOfBids;
        startPrice = _startPrice;
        priceDecreaseRate = _priceDecreaseRate;
    }


    /// @notice Start the auction.
    /// @dev Starts auction and sets startTime.
    function startAuction() public isOwner atStage(Stages.AuctionSetUp) {
        stage = Stages.AuctionStarted;
        startTime = now;
        startBlock = block.number;
        AuctionStarted(startTime, startBlock);
    }

    /// @notice Finalize the auction - sets the final XBET token price and changes the auction
    /// stage after no bids are allowed anymore.
    /// @dev Finalize auction and set the final XBET token price.
    function finalizeAuction() public isOwner atStage(Stages.AuctionStarted) {
        // Missing funds should be 0 at this point
        uint missingFunds = missingFundsToEndAuction();
        require(missingFunds == 0 || now > endTimeOfBids);

        // Calculate the final price = WEI / XBET = WEI / (Rei / tokenMultiplier)
        // Reminder: tokensAuctioned is the number of Rei (XBET * tokenMultiplier) that are auctioned
        finalPrice = tokenMultiplier * receivedWei / tokensAuctioned;

        finalizedTime = now;
        stage = Stages.AuctionEnded;
        AuctionEnded(finalPrice);

        assert(finalPrice > 0);
    }

    /// --------------------------------- Auction Functions ------------------


    /// @notice Send `msg.value` WEI to the auction from the `msg.sender` account.
    /// @dev Allows to send a bid to the auction.
    function bid()
        public
        payable
        atStage(Stages.AuctionStarted)
    {
        require(msg.value > 0);
        assert(bids[msg.sender] + msg.value >= msg.value);

        // Missing funds without the current bid value
        uint missingFunds = missingFundsToEndAuction();

        // We require bid values to be less than the funds missing to end the auction
        // at the current price.
        require(msg.value <= missingFunds);

        bids[msg.sender] += msg.value;
        receivedWei += msg.value;

        // Send bid amount to wallet
        walletAddress.transfer(msg.value);

        BidSubmission(msg.sender, msg.value, missingFunds,block.timestamp);

        assert(receivedWei >= msg.value);
    }

    /// @notice Claim auction tokens for `msg.sender` after the auction has ended.
    /// @dev Claims tokens for `msg.sender` after auction. To be used if tokens can
    /// be claimed by beneficiaries, individually.
    function claimTokens() public atStage(Stages.AuctionEnded) returns (bool) {
        return proxyClaimTokens(msg.sender);
    }

    /// @notice Claim auction tokens for `receiverAddress` after the auction has ended.
    /// @dev Claims tokens for `receiverAddress` after auction has ended.
    /// @param receiverAddress Tokens will be assigned to this address if eligible.
    function proxyClaimTokens(address receiverAddress)
        public
        atStage(Stages.AuctionEnded)
        returns (bool)
    {
        // Waiting period after the end of the auction, before anyone can claim tokens
        // Ensures enough time to check if auction was finalized correctly
        // before users start transacting tokens
        require(now > finalizedTime + TOKEN_CLAIM_WAITING_PERIOD);
        require(receiverAddress != 0x0);

        if (bids[receiverAddress] == 0) {
            return false;
        }

        uint num = (tokenMultiplier * bids[receiverAddress]) / finalPrice;

        // Due to finalPrice floor rounding, the number of assigned tokens may be higher
        // than expected. Therefore, the number of remaining unassigned auction tokens
        // may be smaller than the number of tokens needed for the last claimTokens call
        uint auctionTokensBalance = token.balanceOf(address(this));
        if (num > auctionTokensBalance) {
            num = auctionTokensBalance;
        }

        // Update the total amount of funds for which tokens have been claimed
        fundsClaimed += bids[receiverAddress];

        // Set receiver bid to 0 before assigning tokens
        bids[receiverAddress] = 0;

        require(token.transfer(receiverAddress, num));

        ClaimedTokens(receiverAddress, num);

        // After the last tokens are claimed, we change the auction stage
        // Due to the above logic, rounding errors will not be an issue
        if (fundsClaimed == receivedWei) {
            stage = Stages.TokensDistributed;
            TokensDistributed();
        }

        assert(token.balanceOf(receiverAddress) >= num);
        assert(bids[receiverAddress] == 0);
        return true;
    }

    /// @notice Get the XBET price in WEI during the auction, at the time of
    /// calling this function. Returns `0` if auction has ended.
    /// Returns `startPrice` before auction has started.
    /// @dev Calculates the current XBET token price in WEI.
    /// @return Returns WEI per XBET (tokenMultiplier * Rei).
    function price() public constant returns (uint) {
        if (stage == Stages.AuctionEnded ||
            stage == Stages.TokensDistributed) {
            return finalPrice;
        }
        return calcTokenPrice();
    }

    /// @notice Get the missing funds needed to end the auction,
    /// calculated at the current XBET price in WEI.
    /// @dev The missing funds amount necessary to end the auction at the current XBET price in WEI.
    /// @return Returns the missing funds amount in WEI.
    function missingFundsToEndAuction() constant public returns (uint) {

        uint requiredWei = tokensAuctioned * price() / tokenMultiplier;
        if (requiredWei <= receivedWei) {
            return 0;
        }

        return requiredWei - receivedWei;
    }

    /*
     *  Private functions
     */
    /// @dev Calculates the token price (WEI / XBET) at the current timestamp.
    /// For every new block the price decreases with priceDecreaseRate * numberOfNewBLocks
    /// @return current price
    function calcTokenPrice() constant private returns (uint) {
        uint currentPrice;
        if (stage == Stages.AuctionStarted) {
            currentPrice = startPrice - priceDecreaseRate * (block.number - startBlock);
        }else {
            currentPrice = startPrice;
        }

        return currentPrice;
    }
}