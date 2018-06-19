pragma solidity ^0.4.11;


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

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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
  function transfer(address _to, uint256 _value) returns (bool) {
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
  function balanceOf(address _owner) constant returns (uint256 balance) {
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

  mapping (address => mapping (address => uint256)) allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) returns (bool) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifing the amount of tokens still avaible for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

/**
 * @title PullPayment
 * @dev Base contract supporting async send for pull payments. Inherit from this
 * contract and use asyncSend instead of send.
 */
contract PullPayment {
  using SafeMath for uint256;

  mapping(address => uint256) public payments;
  uint256 public totalPayments;

  /**
  * @dev Called by the payer to store the sent amount as credit to be pulled.
  * @param dest The destination address of the funds.
  * @param amount The amount to transfer.
  */
  function asyncSend(address dest, uint256 amount) internal {
    payments[dest] = payments[dest].add(amount);
    totalPayments = totalPayments.add(amount);
  }

  /**
  * @dev withdraw accumulated balance, called by payee.
  */
  function withdrawPayments() {
    address payee = msg.sender;
    uint256 payment = payments[payee];

    require(payment != 0);
    require(this.balance >= payment);

    totalPayments = totalPayments.sub(payment);
    payments[payee] = 0;

    assert(payee.send(payment));
  }
}

contract TrivialToken is StandardToken, PullPayment {
    //Constants
    uint8 constant DECIMALS = 0;
    uint256 constant MIN_ETH_AMOUNT = 0.005 ether;
    uint256 constant MIN_BID_PERCENTAGE = 10;
    uint256 constant TOTAL_SUPPLY = 1000000;
    uint256 constant TOKENS_PERCENTAGE_FOR_KEY_HOLDER = 25;
    uint256 constant CLEANUP_DELAY = 180 days;
    uint256 constant FREE_PERIOD_DURATION = 60 days;

    //Basic
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    //Accounts
    address public artist;
    address public trivial;

    //Time information
    uint256 public icoDuration;
    uint256 public icoEndTime;
    uint256 public auctionDuration;
    uint256 public auctionEndTime;
    uint256 public freePeriodEndTime;

    //Token information
    uint256 public tokensForArtist;
    uint256 public tokensForTrivial;
    uint256 public tokensForIco;

    //ICO and auction results
    uint256 public amountRaised;
    address public highestBidder;
    uint256 public highestBid;
    bytes32 public auctionWinnerMessageHash;
    uint256 public nextContributorIndexToBeGivenTokens;
    uint256 public tokensDistributedToContributors;

    //Events
    event IcoStarted(uint256 icoEndTime);
    event IcoContributed(address contributor, uint256 amountContributed, uint256 amountRaised);
    event IcoFinished(uint256 amountRaised);
    event IcoCancelled();
    event AuctionStarted(uint256 auctionEndTime);
    event HighestBidChanged(address highestBidder, uint256 highestBid);
    event AuctionFinished(address highestBidder, uint256 highestBid);
    event WinnerProvidedHash();

    //State
    enum State { Created, IcoStarted, IcoFinished, AuctionStarted, AuctionFinished, IcoCancelled }
    State public currentState;

    //Item description
    struct DescriptionHash {
        bytes32 descriptionHash;
        uint256 timestamp;
    }
    DescriptionHash public descriptionHash;
    DescriptionHash[] public descriptionHashHistory;

    //Token contributors and holders
    mapping(address => uint) public contributions;
    address[] public contributors;

    //Modififers
    modifier onlyInState(State expectedState) { require(expectedState == currentState); _; }
    modifier onlyBefore(uint256 _time) { require(now < _time); _; }
    modifier onlyAfter(uint256 _time) { require(now > _time); _; }
    modifier onlyTrivial() { require(msg.sender == trivial); _; }
    modifier onlyArtist() { require(msg.sender == artist); _; }
    modifier onlyAuctionWinner() {
        require(currentState == State.AuctionFinished);
        require(msg.sender == highestBidder);
        _;
    }

    function TrivialToken(
        string _name, string _symbol,
        uint256 _icoDuration, uint256 _auctionDuration,
        address _artist, address _trivial,
        uint256 _tokensForArtist,
        uint256 _tokensForTrivial,
        uint256 _tokensForIco,
        bytes32 _descriptionHash
    ) {
        /*require(
            TOTAL_SUPPLY == SafeMath.add(
                _tokensForArtist,
                SafeMath.add(_tokensForTrivial, _tokensForIco)
            )
        );*/
        require(MIN_BID_PERCENTAGE < 100);
        require(TOKENS_PERCENTAGE_FOR_KEY_HOLDER < 100);

        name = _name;
        symbol = _symbol;
        decimals = DECIMALS;

        icoDuration = _icoDuration;
        auctionDuration = _auctionDuration;
        artist = _artist;
        trivial = _trivial;

        tokensForArtist = _tokensForArtist;
        tokensForTrivial = _tokensForTrivial;
        tokensForIco = _tokensForIco;

        descriptionHash = DescriptionHash(_descriptionHash, now);
        currentState = State.Created;
    }

    /*
        ICO methods
    */
    function startIco()
    onlyInState(State.Created)
    onlyTrivial() {
        icoEndTime = SafeMath.add(now, icoDuration);
        freePeriodEndTime = SafeMath.add(icoEndTime, FREE_PERIOD_DURATION);
        currentState = State.IcoStarted;
        IcoStarted(icoEndTime);
    }

    function contributeInIco() payable
    onlyInState(State.IcoStarted)
    onlyBefore(icoEndTime) {
        require(msg.value > MIN_ETH_AMOUNT);

        if (contributions[msg.sender] == 0) {
            contributors.push(msg.sender);
        }
        contributions[msg.sender] = SafeMath.add(contributions[msg.sender], msg.value);
        amountRaised = SafeMath.add(amountRaised, msg.value);

        IcoContributed(msg.sender, msg.value, amountRaised);
    }

    function distributeTokens(uint256 contributorsNumber)
    onlyInState(State.IcoStarted)
    onlyAfter(icoEndTime) {
        for (uint256 i = 0; i < contributorsNumber && nextContributorIndexToBeGivenTokens < contributors.length; ++i) {
            address currentContributor = contributors[nextContributorIndexToBeGivenTokens++];
            uint256 tokensForContributor = SafeMath.div(
                SafeMath.mul(tokensForIco, contributions[currentContributor]),
                amountRaised  // amountRaised can&#39;t be 0, ICO is cancelled then
            );
            balances[currentContributor] = tokensForContributor;
            tokensDistributedToContributors = SafeMath.add(tokensDistributedToContributors, tokensForContributor);
        }
    }

    function finishIco()
    onlyInState(State.IcoStarted)
    onlyAfter(icoEndTime) {
        if (amountRaised == 0) {
            currentState = State.IcoCancelled;
            return;
        }

        // all contributors must have received their tokens to finish ICO
        require(nextContributorIndexToBeGivenTokens >= contributors.length);

        balances[artist] = SafeMath.add(balances[artist], tokensForArtist);
        balances[trivial] = SafeMath.add(balances[trivial], tokensForTrivial);
        uint256 leftovers = SafeMath.sub(tokensForIco, tokensDistributedToContributors);
        balances[artist] = SafeMath.add(balances[artist], leftovers);

        if (!artist.send(this.balance)) {
            asyncSend(artist, this.balance);
        }
        currentState = State.IcoFinished;
        IcoFinished(amountRaised);
    }

    function checkContribution(address contributor) constant returns (uint) {
        return contributions[contributor];
    }

    /*
        Auction methods
    */
    function canStartAuction() returns (bool) {
        bool isArtist = msg.sender == artist;
        bool isKeyHolder = balances[msg.sender] >= SafeMath.div(
        SafeMath.mul(TOTAL_SUPPLY, TOKENS_PERCENTAGE_FOR_KEY_HOLDER), 100);
        return isArtist || isKeyHolder;
    }

    function startAuction()
    onlyAfter(freePeriodEndTime)
    onlyInState(State.IcoFinished) {
        require(canStartAuction());

        // 100% tokens owner is the only key holder
        if (balances[msg.sender] == TOTAL_SUPPLY) {
            // no auction takes place,
            highestBidder = msg.sender;
            currentState = State.AuctionFinished;
            AuctionFinished(highestBidder, highestBid);
            return;
        }

        auctionEndTime = SafeMath.add(now, auctionDuration);
        currentState = State.AuctionStarted;
        AuctionStarted(auctionEndTime);
    }

    function bidInAuction() payable
    onlyInState(State.AuctionStarted)
    onlyBefore(auctionEndTime) {
        //Must be greater or equal to minimal amount
        require(msg.value >= MIN_ETH_AMOUNT);
        uint256 bid = calculateUserBid();

        //If there was a bid already
        if (highestBid >= MIN_ETH_AMOUNT) {
            //Must be greater or equal to 105% of previous bid
            uint256 minimalOverBid = SafeMath.add(highestBid, SafeMath.div(
                SafeMath.mul(highestBid, MIN_BID_PERCENTAGE), 100
            ));
            require(bid >= minimalOverBid);
            //Return to previous bidder his balance
            //Value to return: current balance - current bid - paymentsInAsyncSend
            uint256 amountToReturn = SafeMath.sub(SafeMath.sub(
                this.balance, msg.value
            ), totalPayments);
            if (!highestBidder.send(amountToReturn)) {
                asyncSend(highestBidder, amountToReturn);
            }
        }

        highestBidder = msg.sender;
        highestBid = bid;
        HighestBidChanged(highestBidder, highestBid);
    }

    function calculateUserBid() private returns (uint256) {
        uint256 bid = msg.value;
        uint256 contribution = balanceOf(msg.sender);
        if (contribution > 0) {
            //Formula: (sentETH * allTokens) / (allTokens - userTokens)
            //User sends 16ETH, has 40 of 200 tokens
            //(16 * 200) / (200 - 40) => 3200 / 160 => 20
            bid = SafeMath.div(
                SafeMath.mul(msg.value, TOTAL_SUPPLY),
                SafeMath.sub(TOTAL_SUPPLY, contribution)
            );
        }
        return bid;
    }

    function finishAuction()
    onlyInState(State.AuctionStarted)
    onlyAfter(auctionEndTime) {
        require(highestBid > 0);  // auction cannot be finished until at least one person bids
        currentState = State.AuctionFinished;
        AuctionFinished(highestBidder, highestBid);
    }

    function withdrawShares(address holder) public
    onlyInState(State.AuctionFinished) {
        uint256 availableTokens = balances[holder];
        require(availableTokens > 0);
        balances[holder] = 0;

        if (holder != highestBidder) {
            holder.transfer(
                SafeMath.div(SafeMath.mul(highestBid, availableTokens), TOTAL_SUPPLY)
            );
        }
    }

    function isKeyHolder(address person) constant returns (bool) {
        return balances[person] >= SafeMath.div(tokensForIco, TOKENS_PERCENTAGE_FOR_KEY_HOLDER); }

    /*
        General methods
    */

    function contributorsCount() constant returns (uint256) { return contributors.length; }

    // Cancel ICO will be redesigned to prevent
    // risk of user funds overtaken

    /*function cancelIco()
    onlyInState(State.IcoStarted)
    onlyTrivial() {
        currentState = State.IcoCancelled;
        IcoCancelled();
    }

    function claimIcoContribution(address contributor) onlyInState(State.IcoCancelled) {
        uint256 contribution = contributions[contributor];
        require(contribution > 0);
        contributions[contributor] = 0;
        contributor.transfer(contribution);
    }*/

    function setDescriptionHash(bytes32 _descriptionHash)
    onlyArtist() {
        descriptionHashHistory.push(descriptionHash);
        descriptionHash = DescriptionHash(_descriptionHash, now);
    }

    function setAuctionWinnerMessageHash(bytes32 _auctionWinnerMessageHash)
    onlyAuctionWinner() {
        auctionWinnerMessageHash = _auctionWinnerMessageHash;
        WinnerProvidedHash();
    }

    function killContract()
    onlyTrivial() {
        require(
            (
                currentState == State.AuctionFinished &&
                now > SafeMath.add(auctionEndTime, CLEANUP_DELAY) // Delay in correct state
            ) ||
            currentState == State.IcoCancelled // No delay in cancelled state
        );
        selfdestruct(trivial);
    }

    // helper function to avoid too many contract calls on frontend side
    function getContractState() constant returns (
        uint256, uint256, uint256, uint256, uint256,
        uint256, uint256, address, uint256, State,
        uint256, uint256, uint256
    ) {
        return (
            icoEndTime, auctionDuration, auctionEndTime,
            tokensForArtist, tokensForTrivial, tokensForIco,
            amountRaised, highestBidder, highestBid, currentState,
            TOKENS_PERCENTAGE_FOR_KEY_HOLDER, MIN_BID_PERCENTAGE,
            freePeriodEndTime
        );
    }

    function transfer(address _to, uint _value)
    onlyInState(State.IcoFinished) returns (bool) {
        return BasicToken.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value)
    onlyInState(State.IcoFinished) returns (bool) {
        return StandardToken.transferFrom(_from, _to, _value);
    }

    function () payable {
        if (currentState == State.IcoStarted) {
            contributeInIco();
        }
        else if (currentState == State.AuctionStarted) {
            bidInAuction();
        }
        else {
            revert();
        }
    }
}