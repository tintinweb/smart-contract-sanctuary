pragma solidity 0.4.25;

// File: contracts\lib\Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "only owner is able call this function");
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts\lib\Pausable.sol

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool private _paused;

    constructor () internal {
        _paused = false;
    }

    /**
     * @return true if the contract is paused, false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "must not be paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "must be paused");
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() public onlyOwner whenNotPaused {
        _paused = true;
        emit Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() onlyOwner whenPaused public {
        _paused = false;
        emit Unpause();
    }
}

// File: contracts\lib\SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
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
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: contracts\lib\Crowdsale.sol

/**
 * @title Crowdsale - modified from zeppelin-solidity library
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive.
 */
contract Crowdsale {
    // start and end timestamps where investments are allowed (both inclusive)
    uint256 public startTime;
    uint256 public endTime;

    // how many token units a buyer gets per wei
    uint256 public rate;

    // amount of raised money in wei
    uint256 public weiRaised;


    // event for token purchase logging
    // purchaser who paid for the tokens
    // beneficiary who got the tokens
    // value weis paid for purchase
    // amount amount of tokens purchased
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    function initCrowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate) public {
        require(
            startTime == 0 && endTime == 0 && rate == 0,
            "Global variables must be empty when initializing crowdsale!"
        );
        require(_startTime >= now, "_startTime must be more than current time!");
        require(_endTime >= _startTime, "_endTime must be more than _startTime!");

        startTime = _startTime;
        endTime = _endTime;
        rate = _rate;
    }

    // @return true if crowdsale event has ended
    function hasEnded() public view returns (bool) {
        return now > endTime;
    }
}

// File: contracts\lib\FinalizableCrowdsale.sol

/**
 * @title FinalizableCrowdsale
 * @dev Extension of Crowdsale where an owner can do extra work
 * after finishing.
 */
contract FinalizableCrowdsale is Crowdsale, Ownable {
  using SafeMath for uint256;

  bool public isFinalized = false;

  event Finalized();

  /**
   * @dev Must be called after crowdsale ends, to do some extra finalization
   * work. Calls the contract&#39;s finalization function.
   */
  function finalize() onlyOwner public {
    require(!isFinalized);
    require(hasEnded());

    finalization();
    emit Finalized();

    isFinalized = true;
  }

  /**
   * @dev Can be overridden to add finalization logic. The overriding function
   * should call super.finalization() to ensure the chain of finalization is
   * executed entirely.
   */
  function finalization() internal {
  }
}

// File: contracts\lib\ERC20Plus.sol

/**
 * @title ERC20 interface with additional functions
 * @dev it has added functions that deals to minting, pausing token and token information
 */
contract ERC20Plus {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    // additonal functions
    function mint(address _to, uint256 _amount) public returns (bool);
    function owner() public view returns (address);
    function transferOwnership(address newOwner) public;
    function name() public view returns (string);
    function symbol() public view returns (string);
    function decimals() public view returns (uint8);
    function paused() public view returns (bool);

}

// File: contracts\Whitelist.sol

/**
 * @title Whitelist - crowdsale whitelist contract
 * @author Gustavo Guimaraes - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="d3b4a6a0a7b2a5bc93a0a7b2a1b1b2a0b6fdb0bc">[email&#160;protected]</a>>
 */
contract Whitelist is Ownable {
    mapping(address => bool) public allowedAddresses;

    event WhitelistUpdated(uint256 timestamp, string operation, address indexed member);

    /**
    * @dev Adds single address to whitelist.
    * @param _address Address to be added to the whitelist
    */
    function addToWhitelist(address _address) external onlyOwner {
        allowedAddresses[_address] = true;
        emit WhitelistUpdated(now, "Added", _address);
    }

    /**
     * @dev add various whitelist addresses
     * @param _addresses Array of ethereum addresses
     */
    function addManyToWhitelist(address[] _addresses) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            allowedAddresses[_addresses[i]] = true;
            emit WhitelistUpdated(now, "Added", _addresses[i]);
        }
    }

    /**
     * @dev remove whitelist addresses
     * @param _addresses Array of ethereum addresses
     */
    function removeManyFromWhitelist(address[] _addresses) public onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            allowedAddresses[_addresses[i]] = false;
            emit WhitelistUpdated(now, "Removed", _addresses[i]);
        }
    }
}

// File: contracts\TokenSaleInterface.sol

/**
 * @title TokenSale contract interface
 */
interface TokenSaleInterface {
    function init
    (
        uint256 _startTime,
        uint256 _endTime,
        address _whitelist,
        address _starToken,
        address _companyToken,
        address _tokenOwnerAfterSale,
        uint256 _rate,
        uint256 _starRate,
        address _wallet,
        uint256 _softCap,
        uint256 _crowdsaleCap,
        bool    _isWeiAccepted,
        bool    _isMinting
    )
    external;
}

// File: contracts\FundsSplitterInterface.sol

contract FundsSplitterInterface {
    function splitFunds() public payable;
    function splitStarFunds() public;
}

// File: contracts\TokenSale.sol

/**
 * @title Token Sale contract - crowdsale of company tokens.
 * @author Gustavo Guimaraes - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="a8cfdddbdcc9dec7e8dbdcc9dacac9dbcd86cbc7">[email&#160;protected]</a>>
 */
contract TokenSale is FinalizableCrowdsale, Pausable {
    uint256 public softCap;
    uint256 public crowdsaleCap;
    uint256 public tokensSold;
    // amount of raised money in STAR
    uint256 public starRaised;
    uint256 public starRate;
    address public tokenOwnerAfterSale;
    bool public isWeiAccepted;
    bool public isMinting;

    // external contracts
    Whitelist public whitelist;
    ERC20Plus public starToken;
    FundsSplitterInterface public wallet;

    // The token being sold
    ERC20Plus public tokenOnSale;

    event TokenRateChanged(uint256 previousRate, uint256 newRate);
    event TokenStarRateChanged(uint256 previousStarRate, uint256 newStarRate);
    event TokenPurchaseWithStar(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    /**
     * @dev initialization function
     * @param _startTime The timestamp of the beginning of the crowdsale
     * @param _endTime Timestamp when the crowdsale will finish
     * @param _whitelist contract containing the whitelisted addresses
     * @param _starToken STAR token contract address
     * @param _companyToken ERC20 contract address that has minting capabilities
     * @param _rate The token rate per ETH
     * @param _starRate The token rate per STAR
     * @param _wallet FundsSplitter wallet that redirects funds to client and Starbase.
     * @param _softCap Soft cap of the token sale
     * @param _crowdsaleCap Cap for the token sale
     * @param _isWeiAccepted Bool for acceptance of ether in token sale
     * @param _isMinting Bool that indicates whether token sale mints ERC20 tokens on sale or simply transfers them
     */
    function init(
        uint256 _startTime,
        uint256 _endTime,
        address _whitelist,
        address _starToken,
        address _companyToken,
        address _tokenOwnerAfterSale,
        uint256 _rate,
        uint256 _starRate,
        address _wallet,
        uint256 _softCap,
        uint256 _crowdsaleCap,
        bool    _isWeiAccepted,
        bool    _isMinting
    )
        external
    {
        require(
            whitelist == address(0) &&
            starToken == address(0) &&
            tokenOwnerAfterSale == address(0) &&
            rate == 0 &&
            starRate == 0 &&
            tokenOnSale == address(0) &&
            softCap == 0 &&
            crowdsaleCap == 0 &&
            wallet == address(0),
            "Global variables should not have been set before!"
        );

        require(
            _whitelist != address(0) &&
            _starToken != address(0) &&
            !(_rate == 0 && _starRate == 0) &&
            _companyToken != address(0) &&
            _softCap != 0 &&
            _crowdsaleCap != 0 &&
            _wallet != 0,
            "Parameter variables cannot be empty!"
        );

        require(_softCap < _crowdsaleCap, "SoftCap should be smaller than crowdsaleCap!");

        if (_isWeiAccepted) {
            require(_rate > 0, "Set a rate for Wei, when it is accepted for purchases!");
        } else {
            require(_rate == 0, "Only set a rate for Wei, when it is accepted for purchases!");
        }

        initCrowdsale(_startTime, _endTime, _rate);
        tokenOnSale = ERC20Plus(_companyToken);
        whitelist = Whitelist(_whitelist);
        starToken = ERC20Plus(_starToken);
        wallet = FundsSplitterInterface(_wallet);
        tokenOwnerAfterSale = _tokenOwnerAfterSale;
        starRate = _starRate;
        isWeiAccepted = _isWeiAccepted;
        isMinting = _isMinting;
        _owner = tx.origin;

        softCap = _softCap.mul(10 ** 18);
        crowdsaleCap = _crowdsaleCap.mul(10 ** 18);

        if (isMinting) {
            require(tokenOwnerAfterSale != address(0), "TokenOwnerAftersale cannot be empty when minting tokens!");
            require(ERC20Plus(tokenOnSale).paused(), "Company token must be paused upon initialization!");
        } else {
            require(tokenOwnerAfterSale == address(0), "TokenOwnerAftersale must be empty when minting tokens!");
        }

        require(ERC20Plus(tokenOnSale).decimals() == 18, "Only sales for tokens with 18 decimals are supported!");
    }

    modifier isWhitelisted(address beneficiary) {
        require(whitelist.allowedAddresses(beneficiary), "Beneficiary not whitelisted!");
        _;
    }

    /**
     * @dev override fallback function. cannot use it
     */
    function () external payable {
        revert("No fallback function defined!");
    }

    /**
     * @dev change crowdsale ETH rate
     * @param newRate Figure that corresponds to the new ETH rate per token
     */
    function setRate(uint256 newRate) external onlyOwner {
        require(isWeiAccepted, "Sale must allow Wei for purchases to set a rate for Wei!");
        require(newRate != 0, "ETH rate must be more than 0!");

        emit TokenRateChanged(rate, newRate);
        rate = newRate;
    }

    /**
     * @dev change crowdsale STAR rate
     * @param newStarRate Figure that corresponds to the new STAR rate per token
     */
    function setStarRate(uint256 newStarRate) external onlyOwner {
        require(newStarRate != 0, "Star rate must be more than 0!");

        emit TokenStarRateChanged(starRate, newStarRate);
        starRate = newStarRate;
    }

    /**
     * @dev allows sale to receive wei or not
     */
    function setIsWeiAccepted(bool _isWeiAccepted, uint256 _rate) external onlyOwner {
        if (_isWeiAccepted) {
            require(_rate > 0, "When accepting Wei, you need to set a conversion rate!");
        } else {
            require(_rate == 0, "When not accepting Wei, you need to set a conversion rate of 0!");
        }

        isWeiAccepted = _isWeiAccepted;
        rate = _rate;
    }

    /**
     * @dev function that allows token purchases with STAR or ETH
     * @param beneficiary Address of the purchaser
     */
    function buyTokens(address beneficiary)
        public
        payable
        whenNotPaused
        isWhitelisted(beneficiary)
    {
        require(beneficiary != address(0));
        require(validPurchase() && tokensSold < crowdsaleCap);
        if (isMinting) {
            require(tokenOnSale.owner() == address(this), "The token owner must be contract address!");
        }

        if (!isWeiAccepted) {
            require(msg.value == 0);
        } else if (msg.value > 0) {
            buyTokensWithWei(beneficiary);
        }

        // beneficiary must allow TokenSale address to transfer star tokens on its behalf
        uint256 starAllocationToTokenSale = starToken.allowance(beneficiary, this);
        if (starAllocationToTokenSale > 0) {
            // calculate token amount to be created
            uint256 tokens = starAllocationToTokenSale.mul(starRate);

            // remainder logic
            if (tokensSold.add(tokens) > crowdsaleCap) {
                tokens = crowdsaleCap.sub(tokensSold);

                starAllocationToTokenSale = tokens.div(starRate);
            }

            // update state
            starRaised = starRaised.add(starAllocationToTokenSale);

            tokensSold = tokensSold.add(tokens);
            sendPurchasedTokens(beneficiary, tokens);
            emit TokenPurchaseWithStar(msg.sender, beneficiary, starAllocationToTokenSale, tokens);

            // forward funds
            starToken.transferFrom(beneficiary, wallet, starAllocationToTokenSale);
            wallet.splitStarFunds();
        }
    }

    /**
     * @dev function that allows token purchases with Wei
     * @param beneficiary Address of the purchaser
     */
    function buyTokensWithWei(address beneficiary)
        internal
    {
        uint256 weiAmount = msg.value;
        uint256 weiRefund = 0;

        // calculate token amount to be created
        uint256 tokens = weiAmount.mul(rate);

        // remainder logic
        if (tokensSold.add(tokens) > crowdsaleCap) {
            tokens = crowdsaleCap.sub(tokensSold);
            weiAmount = tokens.div(rate);

            weiRefund = msg.value.sub(weiAmount);
        }

        // update state
        weiRaised = weiRaised.add(weiAmount);

        tokensSold = tokensSold.add(tokens);
        sendPurchasedTokens(beneficiary, tokens);
        emit TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

        address(wallet).transfer(weiAmount);
        wallet.splitFunds();

        if (weiRefund > 0) {
            msg.sender.transfer(weiRefund);
        }
    }

    // isMinting checker -- it either mints ERC20 token or transfers them
    function sendPurchasedTokens(address _beneficiary, uint256 _tokens) internal {
        isMinting ? tokenOnSale.mint(_beneficiary, _tokens) : tokenOnSale.transfer(_beneficiary, _tokens);
    }

    // check for softCap achievement
    // @return true when softCap is reached
    function hasReachedSoftCap() public view returns (bool) {
        if (tokensSold >= softCap) {
            return true;
        }

        return false;
    }

    // override Crowdsale#hasEnded to add cap logic
    // @return true if crowdsale event has ended
    function hasEnded() public view returns (bool) {
        if (tokensSold >= crowdsaleCap) {
            return true;
        }

        return super.hasEnded();
    }

    /**
     * @dev override Crowdsale#validPurchase
     * @return true if the transaction can buy tokens
     */
    function validPurchase() internal view returns (bool) {
        return now >= startTime && now <= endTime;
    }

    /**
     * @dev finalizes crowdsale
     */
    function finalization() internal {
        uint256 remainingTokens = isMinting ? crowdsaleCap.sub(tokensSold) : tokenOnSale.balanceOf(address(this));

        if (remainingTokens > 0) {
            sendPurchasedTokens(wallet, remainingTokens);
        }

        if (isMinting) tokenOnSale.transferOwnership(tokenOwnerAfterSale);

        super.finalization();
    }
}