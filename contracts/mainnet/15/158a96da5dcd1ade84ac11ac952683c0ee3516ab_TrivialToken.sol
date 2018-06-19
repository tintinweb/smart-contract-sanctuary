pragma solidity ^0.4.11;

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  function transfer(address _to, uint256 _value) returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}

contract ERC223TokenInterface {
    function name() constant returns (string _name);
    function symbol() constant returns (string _symbol);
    function decimals() constant returns (uint8 _decimals);
    function totalSupply() constant returns (uint256 _totalSupply);

    function transfer(address to, uint value, bytes data) returns (bool);
    event Transfer(address indexed from, address indexed to, uint value, bytes data);
}

contract ERC223ReceiverInterface {
    function tokenFallback(address from, uint value, bytes data);
}

contract ERC223Token is BasicToken, ERC223TokenInterface {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    function name() constant returns (string _name) {
        return name;
    }
    function symbol() constant returns (string _symbol) {
        return symbol;
    }
    function decimals() constant returns (uint8 _decimals) {
        return decimals;
    }
    function totalSupply() constant returns (uint256 _totalSupply) {
        return totalSupply;
    }

    modifier onlyPayloadSize(uint size) {
        require(msg.data.length >= size + 4);
        _;
    }

    function transfer(address to, uint value, bytes data) onlyPayloadSize(2 * 32) returns (bool) {
        balances[msg.sender] = SafeMath.sub(balances[msg.sender], value);
        balances[to] = SafeMath.add(balances[to], value);
        if (isContract(to)){
            ERC223ReceiverInterface receiver = ERC223ReceiverInterface(to);
            receiver.tokenFallback(msg.sender, value, data);
        }
        //ERC223 event
        Transfer(msg.sender, to, value, data);
        return true;
    }

    function transfer(address to, uint value) returns (bool) {
        bytes memory empty;
        transfer(to, value, empty);
        //ERC20 legacy event
        Transfer(msg.sender, to, value);
        return true;
    }

    function isContract(address _address) private returns (bool isContract) {
        uint length;
        _address = _address; //Silence compiler warning
        assembly { length := extcodesize(_address) }
        return length > 0;
    }
}

contract PullPayment {
  using SafeMath for uint256;

  mapping(address => uint256) public payments;
  uint256 public totalPayments;

  function asyncSend(address dest, uint256 amount) internal {
    payments[dest] = payments[dest].add(amount);
    totalPayments = totalPayments.add(amount);
  }


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


contract TrivialToken is ERC223Token, PullPayment {

    //Constants
    uint8 constant DECIMALS = 0;
    uint256 constant MIN_ETH_AMOUNT = 0.005 ether;
    uint256 constant MIN_BID_PERCENTAGE = 10;
    uint256 constant TOTAL_SUPPLY = 1000000;
    uint256 constant TOKENS_PERCENTAGE_FOR_KEY_HOLDER = 25;
    uint256 constant CLEANUP_DELAY = 180 days;

    //Accounts
    address public artist;
    address public trivial;

    //Time information
    uint256 public icoEndTime;
    uint256 public auctionDuration;
    uint256 public auctionEndTime;

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

    //Token contributors and holders
    mapping(address => uint) public contributions;
    address[] public contributors;

    //Modififers
    modifier onlyInState(State expectedState) { require(expectedState == currentState); _; }
    modifier onlyBefore(uint256 _time) { require(now < _time); _; }
    modifier onlyAfter(uint256 _time) { require(now > _time); _; }
    modifier onlyTrivial() { require(msg.sender == trivial); _; }
    modifier onlyKeyHolders() { require(balances[msg.sender] >= SafeMath.div(
        SafeMath.mul(tokensForIco, TOKENS_PERCENTAGE_FOR_KEY_HOLDER), 100)); _;
    }
    modifier onlyAuctionWinner() {
        require(currentState == State.AuctionFinished);
        require(msg.sender == highestBidder);
        _;
    }

    function TrivialToken(
        string _name, string _symbol,
        uint256 _icoEndTime, uint256 _auctionDuration,
        address _artist, address _trivial,
        uint256 _tokensForArtist,
        uint256 _tokensForTrivial,
        uint256 _tokensForIco
    ) {
        require(now < _icoEndTime);
        require(
            TOTAL_SUPPLY == SafeMath.add(
                _tokensForArtist,
                SafeMath.add(_tokensForTrivial, _tokensForIco)
            )
        );
        require(MIN_BID_PERCENTAGE < 100);
        require(TOKENS_PERCENTAGE_FOR_KEY_HOLDER < 100);

        name = _name;
        symbol = _symbol;
        decimals = DECIMALS;

        icoEndTime = _icoEndTime;
        auctionDuration = _auctionDuration;
        artist = _artist;
        trivial = _trivial;

        tokensForArtist = _tokensForArtist;
        tokensForTrivial = _tokensForTrivial;
        tokensForIco = _tokensForIco;

        currentState = State.Created;
    }

    /*
        ICO methods
    */
    function startIco()
    onlyInState(State.Created)
    onlyTrivial() {
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
    function startAuction()
    onlyInState(State.IcoFinished)
    onlyKeyHolders() {
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
        uint256, uint256
    ) {
        return (
            icoEndTime, auctionDuration, auctionEndTime,
            tokensForArtist, tokensForTrivial, tokensForIco,
            amountRaised, highestBidder, highestBid, currentState,
            TOKENS_PERCENTAGE_FOR_KEY_HOLDER, MIN_BID_PERCENTAGE
        );
    }

    function transfer(address _to, uint _value, bytes _data) onlyInState(State.IcoFinished) returns (bool) {
        return ERC223Token.transfer(_to, _value, _data);
    }

    function transfer(address _to, uint _value) returns (bool) {
        // onlyInState(IcoFinished) check is contained in a call below
        bytes memory empty;
        return transfer(_to, _value, empty);
    }

    function () payable {
        revert();
    }
}