pragma solidity ^0.4.13;

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

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

contract NectarToken is MintableToken {
    string public name = "Nectar";
    string public symbol = "NCT";
    uint8 public decimals = 18;

    bool public transfersEnabled = false;
    event TransfersEnabled();

    // Disable transfers until after the sale
    modifier whenTransfersEnabled() {
        require(transfersEnabled);
        _;
    }

    modifier whenTransfersNotEnabled() {
        require(!transfersEnabled);
        _;
    }

    function enableTransfers() onlyOwner whenTransfersNotEnabled public {
        transfersEnabled = true;
        TransfersEnabled();
    }

    function transfer(address to, uint256 value) public whenTransfersEnabled returns (bool) {
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) public whenTransfersEnabled returns (bool) {
        return super.transferFrom(from, to, value);
    }

    // Approves and then calls the receiving contract
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

        // call the receiveApproval function on the contract you want to be notified. This crafts the function signature manually so one doesn&#39;t have to include a contract in here just for this.
        // receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData)
        // it is assumed that when does this that the call *should* succeed, otherwise one would use vanilla approve instead.

        // solium-disable-next-line security/no-low-level-calls
        require(_spender.call(bytes4(bytes32(keccak256("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData));
        return true;
    }
}

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

contract NectarCrowdsale is Ownable, Pausable {
    using SafeMath for uint256;

    /** Maximum amount to raise in USD based on initial exchange rate */
    uint256 constant maxCapUsd = 50000000;
    /** Minumum amount per purchase in USD based on initial exchange rate*/
    uint256 constant minimumPurchaseUsd = 100;

    /** Tranche parameters */
    uint256 constant tranche1ThresholdUsd = 5000000;
    uint256 constant tranche1Rate = 37604;
    uint256 constant tranche2ThresholdUsd = 10000000;
    uint256 constant tranche2Rate = 36038;
    uint256 constant tranche3ThresholdUsd = 15000000;
    uint256 constant tranche3Rate = 34471;
    uint256 constant tranche4ThresholdUsd = 20000000;
    uint256 constant tranche4Rate = 32904;
    uint256 constant standardTrancheRate= 31337;

    /** The token being sold */
    NectarToken public token;

    /** Start timestamp when token purchases are allowed, inclusive */
    uint256 public startTime;

    /** End timestamp when token purchases are allowed, inclusive */
    uint256 public endTime;

    /** Set value of wei/usd used in cap and minimum purchase calculation */
    uint256 public weiUsdExchangeRate;

    /** Address where funds are collected */
    address public wallet;

    /** Address used to sign purchase authorizations */
    address public purchaseAuthorizer;

    /** Total amount of raised money in wei */
    uint256 public weiRaised;

    /** Cap in USD */
    uint256 public capUsd;

    /** Maximum amount of raised money in wei */
    uint256 public cap;

    /** Minumum amount of wei per purchase */
    uint256 public minimumPurchase;

    /** Have we canceled the sale? */
    bool public isCanceled;

    /** have we finalized the sale? */
    bool public isFinalized;

    /** Record of nonces -> purchases */
    mapping (uint256 => bool) public purchases;

    /**
     * Event triggered on presale minting
     * @param purchaser who paid for the tokens
     * @param amount amount of tokens minted
     */
    event PreSaleMinting(address indexed purchaser, uint256 amount);

    /**
     * Event triggered on token purchase
     * @param purchaser who paid for the tokens
     * @param value wei paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokenPurchase(address indexed purchaser, uint256 value, uint256 amount);

    /** Event triggered on sale cancelation */
    event Canceled();

    /** Event triggered on sale finalization */
    event Finalized();

    /**
     * NectarCrowdsale constructor
     * @param _startTime start timestamp when purchases are allowed, inclusive
     * @param _endTime end timestamp when purchases are allowed, inclusive
     * @param _initialWeiUsdExchangeRate initial rate of wei/usd used in cap and minimum purchase calculation
     * @param _wallet wallet in which to collect the funds
     * @param _purchaseAuthorizer address to verify purchase authorizations from
     */
    function NectarCrowdsale(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _initialWeiUsdExchangeRate,
        address _wallet,
        address _purchaseAuthorizer
    )
        public
    {
        require(_startTime >= now);
        require(_endTime >= _startTime);
        require(_initialWeiUsdExchangeRate > 0);
        require(_wallet != address(0));
        require(_purchaseAuthorizer != address(0));

        token = createTokenContract();
        startTime = _startTime;
        endTime = _endTime;
        weiUsdExchangeRate = _initialWeiUsdExchangeRate;
        wallet = _wallet;
        purchaseAuthorizer = _purchaseAuthorizer;

        capUsd = maxCapUsd;

        // Updates cap and minimumPurchase based on capUsd and weiUsdExchangeRate
        updateCapAndExchangeRate();

        isCanceled = false;
        isFinalized = false;
    }

    /** Disable usage of the fallback function, only accept eth from buyTokens */
    function () external payable {
        revert();
    }

    /** Only allow before the sale period */
    modifier onlyPreSale() {
        require(now < startTime);
        _;
    }

    /**
     * Directly mint tokens and assign to presale buyers
     * @param purchaser Address to assign to
     * @param tokenAmount amount of tokens to mint
     */
    function mintPreSale(address purchaser, uint256 tokenAmount) public onlyOwner onlyPreSale {
        require(purchaser != address(0));
        require(tokenAmount > 0);

        token.mint(purchaser, tokenAmount);
        PreSaleMinting(purchaser, tokenAmount);
    }

    /**
     * Buy tokens once authorized by the frontend
     * @param nonce nonce parameter generated by the frontend
     * @param authorizedAmount maximum purchase amount authorized for this transaction
     * @param sig the signature generated by the frontned
     */
    function buyTokens(uint256 authorizedAmount, uint256 nonce, bytes sig) public payable whenNotPaused {
        require(msg.sender != address(0));
        require(validPurchase(authorizedAmount, nonce, sig));

        uint256 weiAmount = msg.value;

        // calculate token amount to be created
        uint256 rate = currentTranche();
        uint256 tokens = weiAmount.mul(rate);

        // update state
        weiRaised = weiRaised.add(weiAmount);
        purchases[nonce] = true;

        token.mint(msg.sender, tokens);
        TokenPurchase(msg.sender, weiAmount, tokens);

        forwardFunds();
    }

    /** Cancel the sale */
    function cancel() public onlyOwner {
        require(!isCanceled);
        require(!hasEnded());

        Canceled();
        isCanceled = true;
    }

    /** Finalize the sale */
    function finalize() public onlyOwner {
        require(!isFinalized);
        require(hasEnded());

        finalization();
        Finalized();

        isFinalized = true;
    }

    /**
     * Set exchange rate before sale
     * @param _weiUsdExchangeRate rate of wei/usd used in cap and minimum purchase calculation
     */
    function setExchangeRate(uint256 _weiUsdExchangeRate) public onlyOwner onlyPreSale {
        require(_weiUsdExchangeRate > 0);

        weiUsdExchangeRate = _weiUsdExchangeRate;
        updateCapAndExchangeRate();
    }

    /**
     * Set exchange rate before sale
     * @param _capUsd new cap in USD
     */
    function setCapUsd(uint256 _capUsd) public onlyOwner onlyPreSale {
        require(_capUsd <= maxCapUsd);

        capUsd = _capUsd;
        updateCapAndExchangeRate();
    }

    /** Enable token sales once sale is completed */
    function enableTransfers() public onlyOwner {
        require(isFinalized);
        require(hasEnded());

        token.enableTransfers();
    }

    /**
     * Get the rate of tokens/wei in the current tranche
     * @return the current tokens/wei rate
     */
    function currentTranche() public view returns (uint256) {
        uint256 currentFundingUsd = weiRaised.div(weiUsdExchangeRate);
        if (currentFundingUsd <= tranche1ThresholdUsd) {
            return tranche1Rate;
        } else if (currentFundingUsd <= tranche2ThresholdUsd) {
            return tranche2Rate;
        } else if (currentFundingUsd <= tranche3ThresholdUsd) {
            return tranche3Rate;
        } else if (currentFundingUsd <= tranche4ThresholdUsd) {
            return tranche4Rate;
        } else {
            return standardTrancheRate;
        }
    }

    /** @return true if crowdsale event has ended */
    function hasEnded() public view returns (bool) {
        bool afterEnd = now > endTime;
        bool capMet = weiRaised >= cap;
        return afterEnd || capMet || isCanceled;
    }

    /** Get the amount collected in USD, needed for WINGS calculation. */
    function totalCollected() public view returns (uint256) {
        uint256 presale = maxCapUsd.sub(capUsd);
        uint256 crowdsale = weiRaised.div(weiUsdExchangeRate);
        return presale.add(crowdsale);
    }

    /** Creates the token to be sold. */
    function createTokenContract() internal returns (NectarToken) {
        return new NectarToken();
    }

    /** Create the 30% extra token supply at the end of the sale */
    function finalization() internal {
        // Create 30% NCT for company use
        uint256 tokens = token.totalSupply().mul(3).div(10);
        token.mint(wallet, tokens);
    }

    /** Forward ether to the fund collection wallet */
    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }

    /** Update parameters dependant on capUsd and eiUsdEchangeRate */
    function updateCapAndExchangeRate() internal {
        cap = capUsd.mul(weiUsdExchangeRate);
        minimumPurchase = minimumPurchaseUsd.mul(weiUsdExchangeRate);
    }

    /**
     * Is a purchase transaction valid?
     * @return true if the transaction can buy tokens
     */
    function validPurchase(uint256 authorizedAmount, uint256 nonce, bytes sig) internal view returns (bool) {
        // 84 = 20 byte address + 32 byte authorized amount + 32 byte nonce
        bytes memory prefix = "\x19Ethereum Signed Message:\n84";
        bytes32 hash = keccak256(prefix, msg.sender, authorizedAmount, nonce);
        bool validAuthorization = ECRecovery.recover(hash, sig) == purchaseAuthorizer;

        bool validNonce = !purchases[nonce];
        bool withinPeriod = now >= startTime && now <= endTime;
        bool aboveMinimum = msg.value >= minimumPurchase;
        bool belowAuthorized = msg.value <= authorizedAmount;
        bool belowCap = weiRaised.add(msg.value) <= cap;
        return validAuthorization && validNonce && withinPeriod && aboveMinimum && belowAuthorized && belowCap;
    }
}

library ECRecovery {

  /**
   * @dev Recover signer address from a message by using his signature
   * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
   * @param sig bytes signature, the signature is generated using web3.eth.sign()
   */
  function recover(bytes32 hash, bytes sig) public pure returns (address) {
    bytes32 r;
    bytes32 s;
    uint8 v;

    //Check the signature length
    if (sig.length != 65) {
      return (address(0));
    }

    // Divide the signature in r, s and v variables
    assembly {
      r := mload(add(sig, 32))
      s := mload(add(sig, 64))
      v := byte(0, mload(add(sig, 96)))
    }

    // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
    if (v < 27) {
      v += 27;
    }

    // If the version is correct return the signer address
    if (v != 27 && v != 28) {
      return (address(0));
    } else {
      return ecrecover(hash, v, r, s);
    }
  }

}