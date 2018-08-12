pragma solidity 0.4.19;


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

/**
 * @title RefundVault
 * @dev This contract is used for storing funds while a crowdsale
 * is in progress. Supports refunding the money if crowdsale fails,
 * and forwarding it if crowdsale is successful.
 */
contract RefundVault is Ownable {
  using SafeMath for uint256;

  enum State { Active, Refunding, Closed }

  mapping (address => uint256) public deposited;
  address public wallet;
  State public state;

  event Closed();
  event RefundsEnabled();
  event Refunded(address indexed beneficiary, uint256 weiAmount);

  function RefundVault(address _wallet) public {
    require(_wallet != address(0));
    wallet = _wallet;
    state = State.Active;
  }

  function deposit(address investor) onlyOwner public payable {
    require(state == State.Active);
    deposited[investor] = deposited[investor].add(msg.value);
  }

  function close() onlyOwner public {
    require(state == State.Active);
    state = State.Closed;
    Closed();
    wallet.transfer(this.balance);
  }

  function enableRefunds() onlyOwner public {
    require(state == State.Active);
    state = State.Refunding;
    RefundsEnabled();
  }

  function refund(address investor) public {
    require(state == State.Refunding);
    uint256 depositedValue = deposited[investor];
    deposited[investor] = 0;
    investor.transfer(depositedValue);
    Refunded(investor, depositedValue);
  }
}


contract PhoneToken is MintableToken {
    using SafeMath for uint256;

    string public name = "Phone";
    string public symbol = "PHO";
    uint8 public decimals = 18;

    /**
     * This struct holds data about token holder dividends
     */
    struct Account {
        /**
         * Last amount of dividends seen at the token holder payout
         */
        uint256 lastDividends;
        /**
         * Amount of wei contract needs to pay to token holder
         */
        uint256 fixedBalance;
        /**
         * Unpayed wei amount due to rounding
         */
        uint256 remainder;
    }

    /**
     * Mapping which holds all token holders data
     */
    mapping(address => Account) internal accounts;

    /**
     * Running total of all dividends distributed
     */
    uint256 internal totalDividends;
    /**
     * Holds an amount of unpayed weis
     */
    uint256 internal reserved;

    /**
     * Raised when payment distribution occurs
     */
    event Distributed(uint256 amount);
    /**
     * Raised when shareholder withdraws his profit
     */
    event Paid(address indexed to, uint256 amount);
    /**
     * Raised when the contract receives Ether
     */
    event FundsReceived(address indexed from, uint256 amount);

    modifier fixBalance(address _owner) {
        Account storage account = accounts[_owner];
        uint256 diff = totalDividends.sub(account.lastDividends);
        if (diff > 0) {
            uint256 numerator = account.remainder.add(balances[_owner].mul(diff));

            account.fixedBalance = account.fixedBalance.add(numerator.div(totalSupply_));
            account.remainder = numerator % totalSupply_;
            account.lastDividends = totalDividends;
        }
        _;
    }

    modifier onlyWhenMintingFinished() {
        require(mintingFinished);
        _;
    }

    function () external payable {
        withdraw(msg.sender, msg.value);
    }

    function deposit() external payable {
        require(msg.value > 0);
        require(msg.value <= this.balance.sub(reserved));

        totalDividends = totalDividends.add(msg.value);
        reserved = reserved.add(msg.value);
        Distributed(msg.value);
    }

    /**
     * Returns unpayed wei for a given address
     */
    function getDividends(address _owner) public view returns (uint256) {
        Account storage account = accounts[_owner];
        uint256 diff = totalDividends.sub(account.lastDividends);
        if (diff > 0) {
            uint256 numerator = account.remainder.add(balances[_owner].mul(diff));
            return account.fixedBalance.add(numerator.div(totalSupply_));
        } else {
            return 0;
        }
    }

    function transfer(address _to, uint256 _value) public
        onlyWhenMintingFinished
        fixBalance(msg.sender)
        fixBalance(_to) returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public
        onlyWhenMintingFinished
        fixBalance(_from)
        fixBalance(_to) returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function payoutToAddress(address[] _holders) external {
        require(_holders.length > 0);
        require(_holders.length <= 100);
        for (uint256 i = 0; i < _holders.length; i++) {
            withdraw(_holders[i], 0);
        }
    }

    /**
     * Token holder must call this to receive dividends
     */
    function withdraw(address _benefeciary, uint256 _toReturn) internal
        onlyWhenMintingFinished
        fixBalance(_benefeciary) returns (bool) {

        uint256 amount = accounts[_benefeciary].fixedBalance;
        reserved = reserved.sub(amount);
        accounts[_benefeciary].fixedBalance = 0;
        uint256 toTransfer = amount.add(_toReturn);
        if (toTransfer > 0) {
            _benefeciary.transfer(toTransfer);
        }
        if (amount > 0) {
            Paid(_benefeciary, amount);
        }
        return true;
    }
}


contract MinerOneCrowdsale is Ownable {
    using SafeMath for uint256;
    // Wallet where all ether will be
    address public constant WALLET = 0x7bBaAe6eC155e49DbeB92f9BA16113a30DB4FabB ;
    // Wallet for team tokens
    address public constant TEAM_WALLET = 0x7bBaAe6eC155e49DbeB92f9BA16113a30DB4FabB ;
    // Wallet for research and development tokens
    address public constant RESEARCH_AND_DEVELOPMENT_WALLET = 0x7bBaAe6eC155e49DbeB92f9BA16113a30DB4FabB ;
    // Wallet for bounty tokens
    address public constant BOUNTY_WALLET = 0x7bBaAe6eC155e49DbeB92f9BA16113a30DB4FabB ;

    uint256 public constant UINT256_MAX = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    uint256 public constant ICO_TOKENS = 750000000e18;
    uint8 public constant ICO_TOKENS_PERCENT = 75;
    uint8 public constant TEAM_TOKENS_PERCENT = 10;
    uint8 public constant RESEARCH_AND_DEVELOPMENT_TOKENS_PERCENT = 10;
    uint8 public constant BOUNTY_TOKENS_PERCENT = 5;
    uint256 public constant SOFT_CAP = 6000000e18;
    uint256 public constant START_TIME = 1534089600; // 2018/08/12 16:00 UTC +0
    uint256 public constant RATE = 5000; // 1000 tokens costs 1 ether
    uint256 public constant LARGE_PURCHASE = 10000e18;
    uint256 public constant LARGE_PURCHASE_BONUS = 35;
    uint256 public constant TOKEN_DESK_BONUS = 15;
    uint256 public constant MIN_TOKEN_AMOUNT = 500e18;

    Phase[] internal phases;

    struct Phase {
        uint256 till;
        uint8 discount;
    }

    // The token being sold
    PhoneToken public token;
    // amount of raised money in wei
    uint256 public weiRaised;
    // refund vault used to hold funds while crowdsale is running
    RefundVault public vault;
    uint256 public currentPhase = 0;
    bool public isFinalized = false;
    address private tokenMinter;
    address private tokenDeskProxy;
    uint256 public icoEndTime = 1534780800; // 2018/08/20 16:00 UTC +0

    /**
    * event for token purchase logging
    * @param purchaser who paid for the tokens
    * @param beneficiary who got the tokens
    * @param value weis paid for purchase
    * @param amount amount of tokens purchased
    */
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    event Finalized();
    /**
    * When there no tokens left to mint and token minter tries to manually mint tokens
    * this event is raised to signal how many tokens we have to charge back to purchaser
    */
    event ManualTokenMintRequiresRefund(address indexed purchaser, uint256 value);

    function MinerOneCrowdsale(address _token) public {
        phases.push(Phase({ till: 1534176000, discount: 35 })); // 2018/08/13 16:00 UTC +0
        phases.push(Phase({ till: 1534262400, discount: 30 })); // 2018/08/14 16:00 UTC +0
        phases.push(Phase({ till: 1534348800, discount: 25 })); // 2018/08/15 16:00 UTC +0
        phases.push(Phase({ till: 1534435200, discount: 20 })); // 2018/08/16 16:00 UTC +0
        phases.push(Phase({ till: 1534521600, discount: 15 })); // 2018/08/17 16:00 UTC +0
        phases.push(Phase({ till: 1534608000, discount: 10 })); // 2018/08/18 16:00 UTC +0
        phases.push(Phase({ till: 1534694400, discount: 5  })); // 2018/08/19 16:00 UTC +0
        phases.push(Phase({ till: UINT256_MAX, discount:0 }));  // unlimited

        token = PhoneToken(_token);
        vault = new RefundVault(WALLET);
        tokenMinter = msg.sender;
    }

    modifier onlyTokenMinterOrOwner() {
        require(msg.sender == tokenMinter || msg.sender == owner);
        _;
    }

    // fallback function can be used to buy tokens or claim refund
    function () external payable {
        if (!isFinalized) {
            buyTokens(msg.sender, msg.sender);
        } else {
            claimRefund();
        }
    }

    function mintTokens(address[] _receivers, uint256[] _amounts) external onlyTokenMinterOrOwner {
        require(_receivers.length > 0 && _receivers.length <= 100);
        require(_receivers.length == _amounts.length);
        require(!isFinalized);
        for (uint256 i = 0; i < _receivers.length; i++) {
            address receiver = _receivers[i];
            uint256 amount = _amounts[i];

            require(receiver != address(0));
            require(amount > 0);

            uint256 excess = appendContribution(receiver, amount);

            if (excess > 0) {
                ManualTokenMintRequiresRefund(receiver, excess);
            }
        }
    }

    // low level token purchase function
    function buyTokens(address sender, address beneficiary) public payable {
        require(beneficiary != address(0));
        require(sender != address(0));
        require(validPurchase());

        uint256 weiReceived = msg.value;
        uint256 nowTime = getNow();
        // this loop moves phases and insures correct stage according to date
        while (currentPhase < phases.length && phases[currentPhase].till < nowTime) {
            currentPhase = currentPhase.add(1);
        }

        // calculate token amount to be created
        uint256 tokens = calculateTokens(weiReceived);

        if (tokens < MIN_TOKEN_AMOUNT) revert();

        uint256 excess = appendContribution(beneficiary, tokens);
        uint256 refund = (excess > 0 ? excess.mul(weiReceived).div(tokens) : 0);

        weiReceived = weiReceived.sub(refund);
        weiRaised = weiRaised.add(weiReceived);

        if (refund > 0) {
            sender.transfer(refund);
        }

        TokenPurchase(sender, beneficiary, weiReceived, tokens.sub(excess));

        if (goalReached()) {
            WALLET.transfer(weiReceived);
        } else {
            vault.deposit.value(weiReceived)(sender);
        }
    }

    // if crowdsale is unsuccessful, investors can claim refunds here
    function claimRefund() public {
        require(isFinalized);
        require(!goalReached());

        vault.refund(msg.sender);
    }

    /**
    * @dev Must be called after crowdsale ends, to do some extra finalization
    * work. Calls the contract&#39;s finalization function.
    */
    function finalize() public onlyOwner {
        require(!isFinalized);
        require(hasEnded());

        if (goalReached()) {
            vault.close();

            uint256 totalSupply = token.totalSupply();

            uint256 teamTokens = uint256(TEAM_TOKENS_PERCENT).mul(totalSupply).div(ICO_TOKENS_PERCENT);
            token.mint(TEAM_WALLET, teamTokens);
            uint256 rdTokens = uint256(RESEARCH_AND_DEVELOPMENT_TOKENS_PERCENT).mul(totalSupply).div(ICO_TOKENS_PERCENT);
            token.mint(RESEARCH_AND_DEVELOPMENT_WALLET, rdTokens);
            uint256 bountyTokens = uint256(BOUNTY_TOKENS_PERCENT).mul(totalSupply).div(ICO_TOKENS_PERCENT);
            token.mint(BOUNTY_WALLET, bountyTokens);

            token.finishMinting();
            token.transferOwnership(token);
        } else {
            vault.enableRefunds();
        }

        Finalized();

        isFinalized = true;
    }

    // @return true if crowdsale event has ended
    function hasEnded() public view returns (bool) {
        return getNow() > icoEndTime || token.totalSupply() == ICO_TOKENS;
    }

    function goalReached() public view returns (bool) {
        return token.totalSupply() >= SOFT_CAP;
    }

    function setTokenMinter(address _tokenMinter) public onlyOwner {
        require(_tokenMinter != address(0));
        tokenMinter = _tokenMinter;
    }

    function setTokenDeskProxy(address _tokekDeskProxy) public onlyOwner {
        require(_tokekDeskProxy != address(0));
        tokenDeskProxy = _tokekDeskProxy;
    }

    function setIcoEndTime(uint256 _endTime) public onlyOwner {
        require(_endTime > icoEndTime);
        icoEndTime = _endTime;
    }

    function getNow() internal view returns (uint256) {
        return now;
    }

    function calculateTokens(uint256 _weiAmount) internal view returns (uint256) {
        uint256 tokens = _weiAmount.mul(RATE).mul(100).div(uint256(100).sub(phases[currentPhase].discount));

        uint256 bonus = 0;
        if (currentPhase > 0) {
            bonus = bonus.add(tokens >= LARGE_PURCHASE ? LARGE_PURCHASE_BONUS : 0);
            bonus = bonus.add(msg.sender == tokenDeskProxy ? TOKEN_DESK_BONUS : 0);
        }
        return tokens.add(tokens.mul(bonus).div(100));
    }

    function appendContribution(address _beneficiary, uint256 _tokens) internal returns (uint256) {
        uint256 excess = 0;
        uint256 tokensToMint = 0;
        uint256 totalSupply = token.totalSupply();

        if (totalSupply.add(_tokens) < ICO_TOKENS) {
            tokensToMint = _tokens;
        } else {
            tokensToMint = ICO_TOKENS.sub(totalSupply);
            excess = _tokens.sub(tokensToMint);
        }
        if (tokensToMint > 0) {
            token.mint(_beneficiary, tokensToMint);
        }
        return excess;
    }

    // @return true if the transaction can buy tokens
    function validPurchase() internal view returns (bool) {
        bool withinPeriod = getNow() >= START_TIME && getNow() <= icoEndTime;
        bool nonZeroPurchase = msg.value != 0;
        bool canMint = token.totalSupply() < ICO_TOKENS;
        bool validPhase = (currentPhase < phases.length);
        return withinPeriod && nonZeroPurchase && canMint && validPhase;
    }
}