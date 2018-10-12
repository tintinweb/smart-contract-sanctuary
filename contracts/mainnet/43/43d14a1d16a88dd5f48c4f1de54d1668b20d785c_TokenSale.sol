pragma solidity 0.4.24;

// File: contracts/lib/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;

  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

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
    require(msg.sender == owner, "only owner is able to call this function");
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

// File: contracts/lib/Pausable.sol

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
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

// File: contracts/lib/SafeMath.sol

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

// File: contracts/lib/ERC20Basic.sol

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

// File: contracts/lib/BasicToken.sol

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
    emit Transfer(msg.sender, _to, _value);
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

// File: contracts/lib/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: contracts/lib/StandardToken.sol

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
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
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

// File: contracts/lib/MintableToken.sol

/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

// File: contracts/lib/Crowdsale.sol

/**
 * @title Crowdsale - modified from zeppelin-solidity library
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive.
 */
contract Crowdsale {
    using SafeMath for uint256;

    // The token being sold
    MintableToken public tokenOnSale;

    // start and end timestamps where investments are allowed (both inclusive)
    uint256 public startTime;
    uint256 public endTime;

    // address where funds are collected
    address public wallet;

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

    function initCrowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) public {
        require(
            startTime == 0 && endTime == 0 && rate == 0 && wallet == address(0),
            "Global variables must be empty when initializing crowdsale!"
        );
        require(_startTime >= now, "_startTime must be more than current time!");
        require(_endTime >= _startTime, "_endTime must be more than _startTime!");
        require(_wallet != address(0), "_wallet parameter must not be empty!");

        startTime = _startTime;
        endTime = _endTime;
        rate = _rate;
        wallet = _wallet;
    }

    // @return true if crowdsale event has ended
    function hasEnded() public view returns (bool) {
        return now > endTime;
    }

    // send ether to the fund collection wallet
    // override to create custom fund forwarding mechanisms
    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }
}

// File: contracts/lib/FinalizableCrowdsale.sol

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

// File: contracts/lib/PausableToken.sol

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

// File: contracts/CompanyToken.sol

/**
 * @title CompanyToken contract - ERC20 compatible token contract with customized token parameters.
 * @author Gustavo Guimaraes - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="d5b2a0a6a1b4a3ba95a6a1b4a7b7b4a6b0fbb6ba">[email&#160;protected]</a>>
 */
contract CompanyToken is PausableToken, MintableToken {
    string public name;
    string public symbol;
    uint8 public decimals;

    /**
     * @dev Contract constructor function
     * @param _name Token name
     * @param _symbol Token symbol - up to 4 characters
     * @param _decimals Decimals for token
     */
    constructor(string _name, string _symbol, uint8 _decimals) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        pause();
    }
}

// File: contracts/Whitelist.sol

/**
 * @title Whitelist - crowdsale whitelist contract
 * @author Gustavo Guimaraes - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="85e2f0f6f1e4f3eac5f6f1e4f7e7e4f6e0abe6ea">[email&#160;protected]</a>>
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

// File: contracts/TokenSaleInterface.sol

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
        uint256 _rate,
        uint256 _starRate,
        address _wallet,
        uint256 _crowdsaleCap,
        bool    _isWeiAccepted
    )
    external;
}

// File: contracts/TokenSale.sol

/**
 * @title Token Sale contract - crowdsale of company tokens.
 * @author Gustavo Guimaraes - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="2740525453465148675453465545465442094448">[email&#160;protected]</a>>
 */
contract TokenSale is FinalizableCrowdsale, Pausable {
    uint256 public crowdsaleCap;
    // amount of raised money in STAR
    uint256 public starRaised;
    uint256 public starRate;
    address public initialTokenOwner;
    bool public isWeiAccepted;

    // external contracts
    Whitelist public whitelist;
    StandardToken public starToken;

    event TokenRateChanged(uint256 previousRate, uint256 newRate);
    event TokenStarRateChanged(uint256 previousStarRate, uint256 newStarRate);
    event TokenPurchaseWithStar(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    /**
     * @dev initialization function
     * @param _startTime The timestamp of the beginning of the crowdsale
     * @param _endTime Timestamp when the crowdsale will finish
     * @param _whitelist contract containing the whitelisted addresses
     * @param _starToken STAR token contract address
     * @param _companyToken ERC20 CompanyToken contract address
     * @param _rate The token rate per ETH
     * @param _starRate The token rate per STAR
     * @param _wallet Multisig wallet that will hold the crowdsale funds.
     * @param _crowdsaleCap Cap for the token sale
     * @param _isWeiAccepted Bool for acceptance of ether in token sale
     */
    function init(
        uint256 _startTime,
        uint256 _endTime,
        address _whitelist,
        address _starToken,
        address _companyToken,
        uint256 _rate,
        uint256 _starRate,
        address _wallet,
        uint256 _crowdsaleCap,
        bool    _isWeiAccepted
    )
        external
    {
        require(
            whitelist == address(0) &&
            starToken == address(0) &&
            rate == 0 &&
            starRate == 0 &&
            tokenOnSale == address(0) &&
            crowdsaleCap == 0,
            "Global variables should not have been set before!"
        );

        require(
            _whitelist != address(0) &&
            _starToken != address(0) &&
            !(_rate == 0 && _starRate == 0) &&
            _companyToken != address(0) &&
            _crowdsaleCap != 0,
            "Parameter variables cannot be empty!"
        );

        initCrowdsale(_startTime, _endTime, _rate, _wallet);
        tokenOnSale = CompanyToken(_companyToken);
        whitelist = Whitelist(_whitelist);
        starToken = StandardToken(_starToken);
        starRate = _starRate;
        isWeiAccepted = _isWeiAccepted;
        owner = tx.origin;

        initialTokenOwner = CompanyToken(tokenOnSale).owner();
        uint256 tokenDecimals = CompanyToken(tokenOnSale).decimals();
        crowdsaleCap = _crowdsaleCap.mul(10 ** tokenDecimals);

        require(CompanyToken(tokenOnSale).paused(), "Company token must be paused upon initialization!");
    }

    modifier isWhitelisted(address beneficiary) {
        require(whitelist.allowedAddresses(beneficiary), "Beneficiary not whitelisted!");
        _;
    }

    modifier crowdsaleIsTokenOwner() {
        require(tokenOnSale.owner() == address(this), "The token owner must be contract address!");
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
        require(newRate != 0, "ETH rate must be more than 0");

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
    function setIsWeiAccepted(bool _isWeiAccepted) external onlyOwner {
        require(rate != 0, "When accepting Wei you need to set a conversion rate!");
        isWeiAccepted = _isWeiAccepted;
    }

    /**
     * @dev function that allows token purchases with STAR
     * @param beneficiary Address of the purchaser
     */
    function buyTokens(address beneficiary)
        public
        payable
        whenNotPaused
        isWhitelisted(beneficiary)
        crowdsaleIsTokenOwner
    {
        require(beneficiary != address(0));
        require(validPurchase() && tokenOnSale.totalSupply() < crowdsaleCap);

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

            //remainder logic
            if (tokenOnSale.totalSupply().add(tokens) > crowdsaleCap) {
                tokens = crowdsaleCap.sub(tokenOnSale.totalSupply());

                starAllocationToTokenSale = tokens.div(starRate);
            }

            // update state
            starRaised = starRaised.add(starAllocationToTokenSale);

            tokenOnSale.mint(beneficiary, tokens);
            emit TokenPurchaseWithStar(msg.sender, beneficiary, starAllocationToTokenSale, tokens);

            // forward funds
            starToken.transferFrom(beneficiary, wallet, starAllocationToTokenSale);
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

        //remainder logic
        if (tokenOnSale.totalSupply().add(tokens) > crowdsaleCap) {
            tokens = crowdsaleCap.sub(tokenOnSale.totalSupply());
            weiAmount = tokens.div(rate);

            weiRefund = msg.value.sub(weiAmount);
        }

        // update state
        weiRaised = weiRaised.add(weiAmount);

        tokenOnSale.mint(beneficiary, tokens);
        emit TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

        wallet.transfer(weiAmount);
        if (weiRefund > 0) {
            msg.sender.transfer(weiRefund);
        }
    }

    // override Crowdsale#hasEnded to add cap logic
    // @return true if crowdsale event has ended
    function hasEnded() public view returns (bool) {
        if (tokenOnSale.totalSupply() >= crowdsaleCap) {
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
        if (crowdsaleCap > tokenOnSale.totalSupply()) {
            uint256 remainingTokens = crowdsaleCap.sub(tokenOnSale.totalSupply());

            tokenOnSale.mint(wallet, remainingTokens);
        }

        tokenOnSale.transferOwnership(initialTokenOwner);
        super.finalization();
    }
}