pragma solidity 0.4.19;

// File: zeppelin-solidity/contracts/ownership/Ownable.sol

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

// File: zeppelin-solidity/contracts/math/SafeMath.sol

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

// File: zeppelin-solidity/contracts/token/ERC20Basic.sol

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

// File: zeppelin-solidity/contracts/token/BasicToken.sol

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

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

// File: zeppelin-solidity/contracts/token/ERC20.sol

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

// File: zeppelin-solidity/contracts/token/StandardToken.sol

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
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

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

// File: zeppelin-solidity/contracts/token/MintableToken.sol

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
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

// File: zeppelin-solidity/contracts/lifecycle/Pausable.sol

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

// File: zeppelin-solidity/contracts/token/PausableToken.sol

/**
 * @title Pausable token
 *
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

// File: contracts/ICNQToken.sol

/**
 * @title ICNQ Token contract - ERC20 compatible token contract.
 * @author Gustavo Guimaraes - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="690e1c1a1d081f060e1c0004081b080c1a290e04080005470a0604">[email&#160;protected]</a>>
 */
contract ICNQToken is PausableToken, MintableToken {
    string public constant name = "Iconiq Lab Token";
    string public constant symbol = "ICNQ";
    uint8 public constant decimals = 18;
}

// File: contracts/Whitelist.sol

contract Whitelist is Ownable {
    mapping(address => bool) public allowedAddresses;

    event WhitelistUpdated(uint256 timestamp, string operation, address indexed member);

    function addToWhitelist(address[] _addresses) public onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            allowedAddresses[_addresses[i]] = true;
            WhitelistUpdated(now, "Added", _addresses[i]);
        }
    }

    function removeFromWhitelist(address[] _addresses) public onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            allowedAddresses[_addresses[i]] = false;
            WhitelistUpdated(now, "Removed", _addresses[i]);
        }
    }

    function isWhitelisted(address _address) public view returns (bool) {
        return allowedAddresses[_address];
    }
}

// File: zeppelin-solidity/contracts/crowdsale/Crowdsale.sol

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive.
 */
contract Crowdsale {
  using SafeMath for uint256;

  // The token being sold
  MintableToken public token;

  // start and end timestamps where investments are allowed (both inclusive)
  uint256 public startTime;
  uint256 public endTime;

  // address where funds are collected
  address public wallet;

  // how many token units a buyer gets per wei
  uint256 public rate;

  // amount of raised money in wei
  uint256 public weiRaised;

  /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) public {
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_rate > 0);
    require(_wallet != address(0));

    token = createTokenContract();
    startTime = _startTime;
    endTime = _endTime;
    rate = _rate;
    wallet = _wallet;
  }

  // creates the token to be sold.
  // override this method to have crowdsale of a specific mintable token.
  function createTokenContract() internal returns (MintableToken) {
    return new MintableToken();
  }


  // fallback function can be used to buy tokens
  function () external payable {
    buyTokens(msg.sender);
  }

  // low level token purchase function
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != address(0));
    require(validPurchase());

    uint256 weiAmount = msg.value;

    // calculate token amount to be created
    uint256 tokens = weiAmount.mul(rate);

    // update state
    weiRaised = weiRaised.add(weiAmount);

    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }

  // send ether to the fund collection wallet
  // override to create custom fund forwarding mechanisms
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

  // @return true if the transaction can buy tokens
  function validPurchase() internal view returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

  // @return true if crowdsale event has ended
  function hasEnded() public view returns (bool) {
    return now > endTime;
  }


}

// File: zeppelin-solidity/contracts/crowdsale/FinalizableCrowdsale.sol

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
    Finalized();

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

// File: contracts/ICNQCrowdsale.sol

/**
 * @title ICNQ Crowdsale contract - crowdsale contract for the ICNQ tokens.
 * @author Gustavo Guimaraes - <gustavoguimara<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="5d382e1d3a303c3431733e3230">[email&#160;protected]</a>>
 */
contract ICNQCrowdsale is FinalizableCrowdsale, Pausable {
    uint256 public presaleEndTime;

    // token supply figures
    uint256 constant public TOTAL_TOKENS_SUPPLY = 20000000e18; // 20M

    uint256 public constant OPTIONAL_POOL = 4650000e18; // 4.65M
    uint256 public constant FINLAB_PRESALE = 2000000e18; // 2M
    uint256 public constant EOS = 2000000e18; // 2M
    uint256 public constant US_INSTITUTIONAL = 1500000e18; // 1.5M
    uint256 public constant PRIVATE_SALE_TOTAL = OPTIONAL_POOL + FINLAB_PRESALE + EOS + US_INSTITUTIONAL; // 10.15M

    // 10.15 of the private sale + 750K for presale
    uint256 constant public PRE_SALE_TOTAL_TOKENS = PRIVATE_SALE_TOTAL + 750000e18;
    // 10.15 of the private sale + 750K for presale + 3M for crowdsale
    uint256 constant public TOTAL_TOKENS_FOR_CROWDSALE = PRE_SALE_TOTAL_TOKENS + 3000000e18;

    uint256 public constant TEAM_ADVISORS_SHARE = 3100000e18; // 3.1M
    uint256 public constant COMPANY_SHARE = 2000000e18; // 2M
    uint256 public constant BOUNTY_CAMPAIGN_SHARE = 1000000e18; // 1M

    address public teamAndAdvisorsAllocation;

    event PrivateInvestorTokenPurchase(address indexed investor, uint256 tokensPurchased);
    event TokenRateChanged(uint256 previousRate, uint256 newRate);

    // external contracts
    Whitelist public whitelist;

    /**
     * @dev Contract constructor function
     * @param _startTime The timestamp of the beginning of the crowdsale
     * @param _presaleEndTime End of presale in timestamp
     * @param _endTime Timestamp when the crowdsale will finish
     * @param _whitelist contract containing the whitelisted addresses
     * @param _rate The token rate per ETH
     * @param _wallet Multisig wallet that will hold the crowdsale funds.
     */
    function ICNQCrowdsale
        (
            uint256 _startTime,
            uint256 _presaleEndTime,
            uint256 _endTime,
            address _whitelist,
            uint256 _rate,
            address _wallet
        )
        public
        FinalizableCrowdsale()
        Crowdsale(_startTime, _endTime, _rate, _wallet)
    {
        require(_whitelist != address(0));

        presaleEndTime = _presaleEndTime;
        whitelist = Whitelist(_whitelist);
        ICNQToken(token).pause();
    }

    modifier whitelisted(address beneficiary) {
        require(whitelist.isWhitelisted(beneficiary));
        _;
    }

    /**
     * @dev Mint tokens for private investors before crowdsale starts
     * @param investorsAddress Purchaser&#39;s address
     * @param tokensPurchased Tokens purchased during pre crowdsale
     */
    function mintTokenForPrivateInvestors(address investorsAddress, uint256 tokensPurchased)
        external
        onlyOwner
    {
        require(now < startTime && investorsAddress != address(0));
        require(token.totalSupply().add(tokensPurchased) <= PRIVATE_SALE_TOTAL);

        token.mint(investorsAddress, tokensPurchased);
        PrivateInvestorTokenPurchase(investorsAddress, tokensPurchased);
    }

    /**
     * @dev change crowdsale rate
     * @param newRate Figure that corresponds to the new rate per token
     */
    function setRate(uint256 newRate) external onlyOwner {
        require(newRate != 0);

        TokenRateChanged(rate, newRate);
        rate = newRate;
    }

    /**
     * @dev Set the address which should receive the vested team tokens share on finalization
     * @param _teamAndAdvisorsAllocation address of team and advisor allocation contract
     */
    function setTeamWalletAddress(address _teamAndAdvisorsAllocation) public onlyOwner {
        // only able to set teamAndAdvisorsAllocation once.
        // TeamAndAdvisorsAllocation contract requires token contract already deployed.
        // token contract is created within crowdsale,
        // thus the TeamAndAdvisorsAllocation must be set up after crowdsale&#39;s deployment
        require(teamAndAdvisorsAllocation == address(0x0) && _teamAndAdvisorsAllocation != address(0x0));

        teamAndAdvisorsAllocation = _teamAndAdvisorsAllocation;
    }

    /**
     * @dev payable function that allow token purchases
     * @param beneficiary Address of the purchaser
     */
    function buyTokens(address beneficiary)
        public
        whenNotPaused
        whitelisted(beneficiary)
        payable
    {
        // minimum of 1 ether for purchase in the public presale and sale
        require(beneficiary != address(0) && msg.value >= 1 ether);
        require(validPurchase() && token.totalSupply() < TOTAL_TOKENS_FOR_CROWDSALE);

        uint256 weiAmount = msg.value;

        // calculate token amount to be created
        uint256 tokens = weiAmount.mul(rate);

        if (now >= startTime && now <= presaleEndTime) {
            uint256 bonus = 50;
            uint256 bonusTokens = tokens.mul(bonus).div(100);

            tokens = tokens.add(bonusTokens);
            require(token.totalSupply().add(tokens) <= PRE_SALE_TOTAL_TOKENS);
        }

        //remainder logic
        if (token.totalSupply().add(tokens) > TOTAL_TOKENS_FOR_CROWDSALE) {
            tokens = TOTAL_TOKENS_FOR_CROWDSALE.sub(token.totalSupply());
            weiAmount = tokens.div(rate);

            // send remainder wei to sender
            uint256 remainderAmount = msg.value.sub(weiAmount);
            msg.sender.transfer(remainderAmount);
        }

        // update state
        weiRaised = weiRaised.add(weiAmount);

        token.mint(beneficiary, tokens);

        TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

        forwardFunds(weiAmount);
    }

    // overriding Crowdsale#hasEnded to add cap logic
    // @return true if crowdsale event has ended
    function hasEnded() public view returns (bool) {
        if (token.totalSupply() == TOTAL_TOKENS_FOR_CROWDSALE) {
            return true;
        }

        return super.hasEnded();
    }

    // send ether to the fund collection wallet
    // override to create custom fund forwarding mechanisms
    function forwardFunds(uint256 weiAmount) internal {
        wallet.transfer(weiAmount);
    }

    /**
     * @dev finalizes crowdsale
     */
    function finalization() internal {
        // This must have been set manually prior to finalize().
        require(teamAndAdvisorsAllocation != address(0));

        token.mint(wallet, COMPANY_SHARE);
        token.mint(wallet, BOUNTY_CAMPAIGN_SHARE); // allocate BOUNTY_CAMPAIGN_SHARE to company wallet as well
        token.mint(teamAndAdvisorsAllocation, TEAM_ADVISORS_SHARE);

        if (TOTAL_TOKENS_SUPPLY > token.totalSupply()) {
            uint256 remainingTokens = TOTAL_TOKENS_SUPPLY.sub(token.totalSupply());
            // burn remaining tokens
            token.mint(address(0), remainingTokens);
        }

        token.finishMinting();
        ICNQToken(token).unpause();
        super.finalization();
    }

    /**
     * @dev Creates ICNQ token contract. This is called on the constructor function of the Crowdsale contract
     */
    function createTokenContract() internal returns (MintableToken) {
        return new ICNQToken();
    }
}