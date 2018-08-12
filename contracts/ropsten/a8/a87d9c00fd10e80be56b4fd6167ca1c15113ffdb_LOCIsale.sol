pragma solidity ^0.4.18;

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
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

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

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
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

}




/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

    uint256 _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
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
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  /**
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   */
  function increaseApproval (address _spender, uint _addedValue)
    returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue)
    returns (bool success) {
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
  function Ownable() {
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
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


/**
 * @title Contactable token
 * @dev Basic version of a contactable contract, allowing the owner to provide a string with their
 * contact information.
 */
contract Contactable is Ownable{

    string public contactInformation;

    /**
     * @dev Allows the owner to set a string with their contact information.
     * @param info The contact information to attach to the contract.
     */
    function setContactInformation(string info) onlyOwner public {
         contactInformation = info;
     }
}


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


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract IRefundHandler {
    function handleRefundRequest(address _contributor) external;
}


contract LOCIcoin is StandardToken, Ownable, Contactable {
    string public name = "";
    string public symbol = "";
    uint256 public constant decimals = 18;

    mapping (address => bool) internal allowedOverrideAddresses;

    bool public tokenActive = false;

    modifier onlyIfTokenActiveOrOverride() {
        // owner or any addresses listed in the overrides
        // can perform token transfers while inactive
        require(tokenActive || msg.sender == owner || allowedOverrideAddresses[msg.sender]);
        _;
    }

    modifier onlyIfTokenInactive() {
        require(!tokenActive);
        _;
    }

    modifier onlyIfValidAddress(address _to) {
        // prevent &#39;invalid&#39; addresses for transfer destinations
        require(_to != 0x0);
        // don&#39;t allow transferring to this contract&#39;s address
        require(_to != address(this));
        _;
    }

    event TokenActivated();

    function LOCIcoin(uint256 _totalSupply, string _contactInformation ) public {
        totalSupply = _totalSupply;
        contactInformation = _contactInformation;

        // msg.sender == owner of the contract
        balances[msg.sender] = _totalSupply;
    }

    /// @dev Same ERC20 behavior, but reverts if not yet active.
    /// @param _spender address The address which will spend the funds.
    /// @param _value uint256 The amount of tokens to be spent.
    function approve(address _spender, uint256 _value) public onlyIfTokenActiveOrOverride onlyIfValidAddress(_spender) returns (bool) {
        return super.approve(_spender, _value);
    }

    /// @dev Same ERC20 behavior, but reverts if not yet active.
    /// @param _to address The address to transfer to.
    /// @param _value uint256 The amount to be transferred.
    function transfer(address _to, uint256 _value) public onlyIfTokenActiveOrOverride onlyIfValidAddress(_to) returns (bool) {
        return super.transfer(_to, _value);
    }

    function ownerSetOverride(address _address, bool enable) external onlyOwner {
        allowedOverrideAddresses[_address] = enable;
    }

    function ownerSetVisible(string _name, string _symbol) external onlyOwner onlyIfTokenInactive {        

        // By holding back on setting these, it prevents the token
        // from being a duplicate in ERC token searches if the need to
        // redeploy arises prior to the crowdsale starts.
        // Mainly useful during testnet deployment/testing.
        name = _name;
        symbol = _symbol;
    }

    function ownerActivateToken() external onlyOwner onlyIfTokenInactive {
        require(bytes(symbol).length > 0);

        tokenActive = true;
        TokenActivated();
    }

    function claimRefund(IRefundHandler _refundHandler) external {
        uint256 _balance = balances[msg.sender];

        // Positive token balance required to perform a refund
        require(_balance > 0);

        // this mitigates re-entrancy concerns
        balances[msg.sender] = 0;

        // Attempt to transfer wei back to msg.sender from the
        // crowdsale contract
        // Note: re-entrancy concerns are also addressed within
        // `handleRefundRequest`
        // this will throw an exception if any
        // problems or if refunding isn&#39;t enabled
        _refundHandler.handleRefundRequest(msg.sender);

        // If we&#39;ve gotten here, then the wei transfer above
        // worked (didn&#39;t throw an exception) and it confirmed
        // that `msg.sender` had an ether balance on the contract.
        // Now do token transfer from `msg.sender` back to
        // `owner` completes the refund.
        balances[owner] = balances[owner].add(_balance);
        Transfer(msg.sender, owner, _balance);
    }
}


contract LOCIsale is Ownable, Pausable, IRefundHandler {
    using SafeMath for uint256;

    // this sale contract is creating the LOCIcoin
    // contract, and so will own it
    LOCIcoin internal token;

    // UNIX timestamp (UTC) based start and end, inclusive
    uint256 public start;               /* UTC of timestamp that the sale will start based on the value passed in at the time of construction */
    uint256 public end;                 /* UTC of computed time that the sale will end based on the hours passed in at time of construction */

    bool public isPresale;              /* For LOCI this will be false. We raised pre-ICO offline. */
    bool public isRefunding = false;    /* No plans to refund. */

    uint256 public minFundingGoalWei;   /* we can set this to zero, but we might want to raise at least 20000 Ether */
    uint256 public minContributionWei;  /* individual contribution min. we require at least a 0.1 Ether investment, for example. */
    uint256 public maxContributionWei;  /* individual contribution max. probably don&#39;t want someone to buy more than 60000 Ether */

    uint256 public weiRaised;       /* total of all weiContributions */
    uint256 public weiRaisedAfterDiscounts; /* wei raised after the discount periods end */
    uint256 internal weiForRefund;  /* only applicable if we enable refunding, if we don&#39;t meet our expected raise */

    uint256 public peggedETHUSD;    /* In whole dollars. $300 means use 300 */
    uint256 public hardCap;         /* In wei. Example: 64,000 cap = 64,000,000,000,000,000,000,000 */
    uint256 public reservedTokens;  /* In wei. Example: 54 million tokens, use 54000000 with 18 more zeros. then it would be 54000000 * Math.pow(10,18) */
    uint256 public baseRateInCents; /* $2.50 means use 250 */
    uint256 internal startingTokensAmount; // this will be set once, internally

    mapping (address => uint256) public contributions;

    struct DiscountTranche {
        // this will be a timestamp that is calculated based on
        // the # of hours a tranche rate is to be active for
        uint256 end;
        // should be a % number between 0 and 100
        uint8 discount;
        // should be 1, 2, 3, 4, etc...
        uint8 round;
        // amount raised during tranche in wei
        uint256 roundWeiRaised;
        // amount sold during tranche in wei
        uint256 roundTokensSold;
    }
    DiscountTranche[] internal discountTranches;
    uint8 internal currentDiscountTrancheIndex = 0;
    uint8 internal discountTrancheLength = 0;

    event ContributionReceived(address indexed buyer, bool presale, uint8 rate, uint256 value, uint256 tokens);
    event RefundsEnabled();
    event Refunded(address indexed buyer, uint256 weiAmount);
    event ToppedUp();
    event PegETHUSD(uint256 pegETHUSD);

    function LOCIsale(
        address _token,                /* LOCIcoin contract address */
        uint256 _peggedETHUSD,          /* 300 = 300 USD */
        uint256 _hardCapETHinWei,       /* In wei. Example: 64,000 cap = 64,000,000,000,000,000,000,000 */
        uint256 _reservedTokens,        /* In wei. Example: 54 million tokens, use 54000000 with 18 more zeros. then it would be 54000000 * Math.pow(10,18) */
        bool _isPresale,                /* For LOCI this will be false. Presale offline, and accounted for in reservedTokens */
        uint256 _minFundingGoalWei,     /* If we are looking to raise a minimum amount of wei, put it here */
        uint256 _minContributionWei,    /* For LOCI this will be 0.1 ETH */
        uint256 _maxContributionWei,    /* Advisable to not let a single contributor go over the max alloted, say 63333 * Math.pow(10,18) wei. */
        uint256 _start,                 /* For LOCI this will be Dec 6th 0:00 UTC in seconds */
        uint256 _durationHours,         /* Total length of the sale, in hours */
        uint256 _baseRateInCents,       /* Base rate in cents. $2.50 would be 250 */
        uint256[] _hourBasedDiscounts   /* Single dimensional array of pairs [hours, rateInCents, hours, rateInCents, hours, rateInCents, ... ] */
    ) public {
        require(_token != 0x0);
        // either have NO max contribution or the max must be more than the min
        require(_maxContributionWei == 0 || _maxContributionWei > _minContributionWei);
        // sale must have a duration!
        require(_durationHours > 0);

        token = LOCIcoin(_token);

        peggedETHUSD = _peggedETHUSD;
        hardCap = _hardCapETHinWei;
        reservedTokens = _reservedTokens;

        isPresale = _isPresale;

        start = _start;
        end = start.add(_durationHours.mul(1 hours));

        minFundingGoalWei = _minFundingGoalWei;
        minContributionWei = _minContributionWei;
        maxContributionWei = _maxContributionWei;

        baseRateInCents = _baseRateInCents;

        // this will throw if the # of hours and
        // discount % don&#39;t come in pairs
        uint256 _end = start;

        uint _tranche_round = 0;

        for (uint i = 0; i < _hourBasedDiscounts.length; i += 2) {
            // calculate the timestamp where the discount rate will end
            _end = _end.add(_hourBasedDiscounts[i].mul(1 hours));

            // the calculated tranche end cannot go past the crowdsale end
            require(_end <= end);

            _tranche_round += 1;

            discountTranches.push(DiscountTranche({ end:_end,
                                                    discount:uint8(_hourBasedDiscounts[i + 1]),
                                                    round:uint8(_tranche_round),
                                                    roundWeiRaised:0,
                                                    roundTokensSold:0}));

            discountTrancheLength = uint8(i+1);
        }
    }

    function determineDiscountTranche() internal returns (uint256, uint8, uint8) {
        if (currentDiscountTrancheIndex >= discountTranches.length) {
            return(0, 0, 0);
        }

        DiscountTranche storage _dt = discountTranches[currentDiscountTrancheIndex];
        if (_dt.end < now) {
            // find the next applicable tranche
            while (++currentDiscountTrancheIndex < discountTranches.length) {
                _dt = discountTranches[currentDiscountTrancheIndex];
                if (_dt.end > now) {
                    break;
                }
            }
        }

        // Example: there are 4 rounds, and we want to divide rounds 2-4 equally based on (starting-round1)/(discountTranches.length-1), move to next tranche
        // But don&#39;t move past the last round. Note, the last round should not be capped. That&#39;s why we check for round < # tranches
        if (_dt.round > 1 && _dt.roundTokensSold > 0 && _dt.round < discountTranches.length) {
            uint256 _trancheCountExceptForOne = discountTranches.length-1;
            uint256 _tokensSoldFirstRound = discountTranches[0].roundTokensSold;
            uint256 _allowedTokensThisRound = (startingTokensAmount.sub(_tokensSoldFirstRound)).div(_trancheCountExceptForOne);

            if (_dt.roundTokensSold > _allowedTokensThisRound) {
                currentDiscountTrancheIndex = currentDiscountTrancheIndex + 1;
                _dt = discountTranches[currentDiscountTrancheIndex];
            }
        }

        uint256 _end = 0;
        uint8 _rate = 0;
        uint8 _round = 0;

        // if the index is still valid, then we must have
        // a valid tranche, so return discount rate
        if (currentDiscountTrancheIndex < discountTranches.length) {
            _end = _dt.end;
            _rate = _dt.discount;
            _round = _dt.round;
        } else {
            _end = end;
            _rate = 0;
            _round = discountTrancheLength + 1;
        }

        return (_end, _rate, _round);
    }

    function() public payable whenNotPaused {
        require(!isRefunding);
        require(msg.sender != 0x0);
        require(msg.value >= minContributionWei);
        require(start <= now && end >= now);

        // prevent anything more than maxContributionWei per contributor address
        uint256 _weiContributionAllowed = maxContributionWei > 0 ? maxContributionWei.sub(contributions[msg.sender]) : msg.value;
        if (maxContributionWei > 0) {
            require(_weiContributionAllowed > 0);
        }

        // are limited by the number of tokens remaining
        uint256 _tokensRemaining = token.balanceOf(address(this)).sub( reservedTokens );
        require(_tokensRemaining > 0);

        if (startingTokensAmount == 0) {
            startingTokensAmount = _tokensRemaining; // set this once.
        }

        // limit contribution&#39;s value based on max/previous contributions
        uint256 _weiContribution = msg.value;
        if (_weiContribution > _weiContributionAllowed) {
            _weiContribution = _weiContributionAllowed;
        }

        // limit contribution&#39;s value based on hard cap of hardCap
        if (hardCap > 0 && weiRaised.add(_weiContribution) > hardCap) {
            _weiContribution = hardCap.sub( weiRaised );
        }

        // calculate token amount to be created
        uint256 _tokens = _weiContribution.mul(peggedETHUSD).mul(100).div(baseRateInCents);
        var (, _rate, _round) = determineDiscountTranche();
        if (_rate > 0) {
            _tokens = _weiContribution.mul(peggedETHUSD).mul(100).div(_rate);
        }

        if (_tokens > _tokensRemaining) {
            // there aren&#39;t enough tokens to fill the contribution amount, so recalculate the contribution amount
            _tokens = _tokensRemaining;
            if (_rate > 0) {
                _weiContribution = _tokens.mul(_rate).div(100).div(peggedETHUSD);
            } else {
                _weiContribution = _tokens.mul(baseRateInCents).div(100).div(peggedETHUSD);
            }
        }

        // add the contributed wei to any existing value for the sender
        contributions[msg.sender] = contributions[msg.sender].add(_weiContribution);
        ContributionReceived(msg.sender, isPresale, _rate, _weiContribution, _tokens);

        require(token.transfer(msg.sender, _tokens));

        weiRaised = weiRaised.add(_weiContribution); //total of all weiContributions

        if (discountTrancheLength > 0 && _round > 0 && _round <= discountTrancheLength) {
            discountTranches[_round-1].roundWeiRaised = discountTranches[_round-1].roundWeiRaised.add(_weiContribution);
            discountTranches[_round-1].roundTokensSold = discountTranches[_round-1].roundTokensSold.add(_tokens);
        }
        if (discountTrancheLength > 0 && _round > discountTrancheLength) {
            weiRaisedAfterDiscounts = weiRaisedAfterDiscounts.add(_weiContribution);
        }

        uint256 _weiRefund = msg.value.sub(_weiContribution);
        if (_weiRefund > 0) {
            msg.sender.transfer(_weiRefund);
        }
    }

    // in case we need to return funds to this contract
    function ownerTopUp() external payable {}

    function setReservedTokens( uint256 _reservedTokens ) onlyOwner public {
        reservedTokens = _reservedTokens;        
    }

    function pegETHUSD(uint256 _peggedETHUSD) onlyOwner public {
        peggedETHUSD = _peggedETHUSD;
        PegETHUSD(peggedETHUSD);
    }

    function setHardCap( uint256 _hardCap ) onlyOwner public {
        hardCap = _hardCap;
    }

    function peggedETHUSD() constant onlyOwner public returns(uint256) {
        return peggedETHUSD;
    }

    function hardCapETHInWeiValue() constant onlyOwner public returns(uint256) {
        return hardCap;
    }

    function weiRaisedDuringRound(uint8 round) constant onlyOwner public returns(uint256) {
        require( round > 0 && round <= discountTrancheLength );
        return discountTranches[round-1].roundWeiRaised;
    }

    function tokensRaisedDuringRound(uint8 round) constant onlyOwner public returns(uint256) {
        require( round > 0 && round <= discountTrancheLength );
        return discountTranches[round-1].roundTokensSold;
    }

    function weiRaisedAfterDiscountRounds() constant onlyOwner public returns(uint256) {
        return weiRaisedAfterDiscounts;
    }

    function totalWeiRaised() constant onlyOwner public returns(uint256) {
        return weiRaised;
    }

    function setStartingTokensAmount(uint256 _startingTokensAmount) onlyOwner public {
        startingTokensAmount = _startingTokensAmount;
    }

    function ownerEnableRefunds() external onlyOwner {
        // a little protection against human error;
        // sale must be ended OR it must be paused
        require(paused || now > end);
        require(!isRefunding);

        weiForRefund = this.balance;
        isRefunding = true;
        RefundsEnabled();
    }

    function ownerTransferWei(address _beneficiary, uint256 _value) external onlyOwner {
        require(_beneficiary != 0x0);
        require(_beneficiary != address(token));
        // we cannot withdraw if we didn&#39;t reach the minimum funding goal
        require(minFundingGoalWei == 0 || weiRaised >= minFundingGoalWei);

        // if zero requested, send the entire amount, otherwise the amount requested
        uint256 _amount = _value > 0 ? _value : this.balance;

        _beneficiary.transfer(_amount);
    }

    function ownerRecoverTokens(address _beneficiary) external onlyOwner {
        require(_beneficiary != 0x0);
        require(_beneficiary != address(token));
        require(paused || now > end);

        uint256 _tokensRemaining = token.balanceOf(address(this));
        if (_tokensRemaining > 0) {
            token.transfer(_beneficiary, _tokensRemaining);
        }
    }

    function handleRefundRequest(address _contributor) external {
        // Note that this method can only ever called by
        // the token contract&#39;s `claimRefund()` method;
        // everything that happens in here will only
        // succeed if `claimRefund()` works as well.

        require(isRefunding);
        // this can only be called by the token contract;
        // it is the entry point for the refund flow
        require(msg.sender == address(token));

        uint256 _wei = contributions[_contributor];

        // if this is zero, then `_contributor` didn&#39;t
        // contribute or they&#39;ve already been refunded
        require(_wei > 0);

        // prorata the amount if necessary
        if (weiRaised > weiForRefund) {
            uint256 _n  = weiForRefund.mul(_wei).div(weiRaised);
            require(_n < _wei);
            _wei = _n;
        }

        // zero out their contribution, so they cannot
        // claim another refund; it&#39;s important (for
        // avoiding re-entrancy attacks) that this zeroing
        // happens before the transfer below
        contributions[_contributor] = 0;

        // give them their ether back; throws on failure
        _contributor.transfer(_wei);

        Refunded(_contributor, _wei);
    }
}