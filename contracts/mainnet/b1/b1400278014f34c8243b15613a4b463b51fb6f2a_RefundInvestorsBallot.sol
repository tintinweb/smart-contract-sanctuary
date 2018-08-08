pragma solidity ^0.4.18;

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

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

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

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

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
    Transfer(0x0, _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

contract Ballot {
    using SafeMath for uint256;
    EthearnalRepToken public tokenContract;

    // Date when vote has started
    uint256 public ballotStarted;

    // Registry of votes
    mapping(address => bool) public votesByAddress;

    // Sum of weights of YES votes
    uint256 public yesVoteSum = 0;

    // Sum of weights of NO votes
    uint256 public noVoteSum = 0;

    // Length of `voters`
    uint256 public votersLength = 0;

    uint256 public initialQuorumPercent = 51;

    VotingProxy public proxyVotingContract;

    // Tells if voting process is active
    bool public isVotingActive = false;

    event FinishBallot(uint256 _time);
    event Vote(address indexed sender, bytes vote);
    
    modifier onlyWhenBallotStarted {
        require(ballotStarted != 0);
        _;
    }

    function Ballot(address _tokenContract) {
        tokenContract = EthearnalRepToken(_tokenContract);
        proxyVotingContract = VotingProxy(msg.sender);
        ballotStarted = getTime();
        isVotingActive = true;
    }
    
    function getQuorumPercent() public constant returns (uint256) {
        require(isVotingActive);
        // find number of full weeks alapsed since voting started
        uint256 weeksNumber = getTime().sub(ballotStarted).div(1 weeks);
        if(weeksNumber == 0) {
            return initialQuorumPercent;
        }
        if (initialQuorumPercent < weeksNumber * 10) {
            return 0;
        } else {
            return initialQuorumPercent.sub(weeksNumber * 10);
        }
    }

    function vote(bytes _vote) public onlyWhenBallotStarted {
        require(_vote.length > 0);
        if (isDataYes(_vote)) {
            processVote(true);
        } else if (isDataNo(_vote)) {
            processVote(false);
        }
        Vote(msg.sender, _vote);
    }

    function isDataYes(bytes data) public constant returns (bool) {
        // compare data with "YES" string
        return (
            data.length == 3 &&
            (data[0] == 0x59 || data[0] == 0x79) &&
            (data[1] == 0x45 || data[1] == 0x65) &&
            (data[2] == 0x53 || data[2] == 0x73)
        );
    }

    // TESTED
    function isDataNo(bytes data) public constant returns (bool) {
        // compare data with "NO" string
        return (
            data.length == 2 &&
            (data[0] == 0x4e || data[0] == 0x6e) &&
            (data[1] == 0x4f || data[1] == 0x6f)
        );
    }
    
    function processVote(bool isYes) internal {
        require(isVotingActive);
        require(!votesByAddress[msg.sender]);
        votersLength = votersLength.add(1);
        uint256 voteWeight = tokenContract.balanceOf(msg.sender);
        if (isYes) {
            yesVoteSum = yesVoteSum.add(voteWeight);
        } else {
            noVoteSum = noVoteSum.add(voteWeight);
        }
        require(getTime().sub(tokenContract.lastMovement(msg.sender)) > 7 days);
        uint256 quorumPercent = getQuorumPercent();
        if (quorumPercent == 0) {
            isVotingActive = false;
        } else {
            decide();
        }
        votesByAddress[msg.sender] = true;
    }

    function decide() internal {
        uint256 quorumPercent = getQuorumPercent();
        uint256 quorum = quorumPercent.mul(tokenContract.totalSupply()).div(100);
        uint256 soFarVoted = yesVoteSum.add(noVoteSum);
        if (soFarVoted >= quorum) {
            uint256 percentYes = (100 * yesVoteSum).div(soFarVoted);
            if (percentYes >= initialQuorumPercent) {
                // does not matter if it would be greater than weiRaised
                proxyVotingContract.proxyIncreaseWithdrawalChunk();
                FinishBallot(now);
                isVotingActive = false;
            } else {
                // do nothing, just deactivate voting
                isVotingActive = false;
                FinishBallot(now);
            }
        }
        
    }

    function getTime() internal returns (uint256) {
        // Just returns `now` value
        // This function is redefined in EthearnalRepTokenCrowdsaleMock contract
        // to allow testing contract behaviour at different time moments
        return now;
    }
    
}

contract LockableToken is StandardToken, Ownable {
    bool public isLocked = true;
    mapping (address => uint256) public lastMovement;
    event Burn(address _owner, uint256 _amount);


    function unlock() public onlyOwner {
        isLocked = false;
    }

    function transfer(address _to, uint256 _amount) public returns (bool) {
        require(!isLocked);
        lastMovement[msg.sender] = getTime();
        lastMovement[_to] = getTime();
        return super.transfer(_to, _amount);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(!isLocked);
        lastMovement[_from] = getTime();
        lastMovement[_to] = getTime();
        super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        require(!isLocked);
        super.approve(_spender, _value);
    }

    function burnFrom(address _from, uint256 _value) public  returns (bool) {
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

        totalSupply = totalSupply.sub(_value);
        Burn(_from, _value);
        return true;
    }

    function getTime() internal returns (uint256) {
        // Just returns `now` value
        // This function is redefined in EthearnalRepTokenCrowdsaleMock contract
        // to allow testing contract behaviour at different time moments
        return now;
    }

    function claimTokens(address _token) public onlyOwner {
        if (_token == 0x0) {
            owner.transfer(this.balance);
            return;
        }
    
        ERC20Basic token = ERC20Basic(_token);
        uint256 balance = token.balanceOf(this);
        token.transfer(owner, balance);
    }

}

contract EthearnalRepToken is MintableToken, LockableToken {
    string public constant name = &#39;Ethearnal Rep Token&#39;;
    string public constant symbol = &#39;ERT&#39;;
    uint8 public constant decimals = 18;
}

contract MultiOwnable {
    mapping (address => bool) public ownerRegistry;
    address[] owners;
    address public multiOwnableCreator = 0x0;

    function MultiOwnable() public {
        multiOwnableCreator = msg.sender;
    }

    function setupOwners(address[] _owners) public {
        // Owners are allowed to be set up only one time
        require(multiOwnableCreator == msg.sender);
        require(owners.length == 0);
        for(uint256 idx=0; idx < _owners.length; idx++) {
            require(
                !ownerRegistry[_owners[idx]] &&
                _owners[idx] != 0x0 &&
                _owners[idx] != address(this)
            );
            ownerRegistry[_owners[idx]] = true;
        }
        owners = _owners;
    }

    modifier onlyOwner() {
        require(ownerRegistry[msg.sender] == true);
        _;
    }

    function getOwners() public constant returns (address[]) {
        return owners;
    }
}

contract EthearnalRepTokenCrowdsale is MultiOwnable {
    using SafeMath for uint256;

    /* *********************
     * Variables & Constants
     */

    // Token Contract
    EthearnalRepToken public token;

    // Ethereum rate, how much USD does 1 ether cost
    // The actual value is set by setEtherRateUsd
    uint256 etherRateUsd = 1000;

    // Token price in Usd, 1 token is 1.0 USD, 3 decimals. So, 1000 = $1.000
    uint256 public tokenRateUsd = 1000;

    // Mainsale Start Date February 28, 2018 3:00:00 PM
    uint256 public constant saleStartDate = 1519830000;

    // Mainsale End Date March 31, 2018 11:59:59 PM GMT
    uint256 public constant saleEndDate = 1522540799;

    // How many tokens generate for the team, ratio with 3 decimals digits
    uint256 public constant teamTokenRatio = uint256(1 * 1000) / 3;

    // Crowdsale State
    enum State {
        BeforeMainSale, // pre-sale finisehd, before main sale
        MainSale, // main sale is active
        MainSaleDone, // main sale done, ICO is not finalized
        Finalized // the final state till the end of the world
    }

    // Hard cap for total sale
    uint256 public saleCapUsd = 30 * (10**6);

    // Money raised totally
    uint256 public weiRaised = 0;

    // This event means everything is finished and tokens
    // are allowed to be used by their owners
    bool public isFinalized = false;

    // Wallet to send team tokens
    address public teamTokenWallet = 0x0;

    // money received from each customer
    mapping(address => uint256) public raisedByAddress;

    // whitelisted investors
    mapping(address => bool) public whitelist;
    // how many whitelisted investors
    uint256 public whitelistedInvestorCounter;


    // Extra money each address can spend each hour
    uint256 hourLimitByAddressUsd = 1000;

    // Wallet to store all raised money
    Treasury public treasuryContract = Treasury(0x0);

    /* *******
     * Events
     */
    
    event ChangeReturn(address indexed recipient, uint256 amount);
    event TokenPurchase(address indexed buyer, uint256 weiAmount, uint256 tokenAmount);
    /* **************
     * Public methods
     */

    function EthearnalRepTokenCrowdsale(
        address[] _owners,
        address _treasuryContract,
        address _teamTokenWallet
    ) {
        require(_owners.length > 1);
        require(_treasuryContract != address(0));
        require(_teamTokenWallet != address(0));
        require(Treasury(_treasuryContract).votingProxyContract() != address(0));
        require(Treasury(_treasuryContract).tokenContract() != address(0));
        treasuryContract = Treasury(_treasuryContract);
        teamTokenWallet = _teamTokenWallet;
        setupOwners(_owners);
    }

    function() public payable {
        if (whitelist[msg.sender]) {
            buyForWhitelisted();
        } else {
            buyTokens();
        }
    }

    function setTokenContract(address _token) public onlyOwner {
        require(_token != address(0) && token == address(0));
        require(EthearnalRepToken(_token).owner() == address(this));
        require(EthearnalRepToken(_token).totalSupply() == 0);
        require(EthearnalRepToken(_token).isLocked());
        require(!EthearnalRepToken(_token).mintingFinished());
        token = EthearnalRepToken(_token);
    }

    function buyForWhitelisted() public payable {
        require(token != address(0));
        address whitelistedInvestor = msg.sender;
        require(whitelist[whitelistedInvestor]);
        uint256 weiToBuy = msg.value;
        require(weiToBuy > 0);
        uint256 tokenAmount = getTokenAmountForEther(weiToBuy);
        require(tokenAmount > 0);
        weiRaised = weiRaised.add(weiToBuy);
        raisedByAddress[whitelistedInvestor] = raisedByAddress[whitelistedInvestor].add(weiToBuy);
        forwardFunds(weiToBuy);
        assert(token.mint(whitelistedInvestor, tokenAmount));
        TokenPurchase(whitelistedInvestor, weiToBuy, tokenAmount);
    }

    function buyTokens() public payable {
        require(token != address(0));
        address recipient = msg.sender;
        State state = getCurrentState();
        uint256 weiToBuy = msg.value;
        require(
            (state == State.MainSale) &&
            (weiToBuy > 0)
        );
        weiToBuy = min(weiToBuy, getWeiAllowedFromAddress(recipient));
        require(weiToBuy > 0);
        weiToBuy = min(weiToBuy, convertUsdToEther(saleCapUsd).sub(weiRaised));
        require(weiToBuy > 0);
        uint256 tokenAmount = getTokenAmountForEther(weiToBuy);
        require(tokenAmount > 0);
        uint256 weiToReturn = msg.value.sub(weiToBuy);
        weiRaised = weiRaised.add(weiToBuy);
        raisedByAddress[recipient] = raisedByAddress[recipient].add(weiToBuy);
        if (weiToReturn > 0) {
            recipient.transfer(weiToReturn);
            ChangeReturn(recipient, weiToReturn);
        }
        forwardFunds(weiToBuy);
        require(token.mint(recipient, tokenAmount));
        TokenPurchase(recipient, weiToBuy, tokenAmount);
    }

    // TEST
    function finalizeByAdmin() public onlyOwner {
        finalize();
    }

    /* ****************
     * Internal methods
     */

    function forwardFunds(uint256 _weiToBuy) internal {
        treasuryContract.transfer(_weiToBuy);
    }

    // TESTED
    function convertUsdToEther(uint256 usdAmount) constant internal returns (uint256) {
        return usdAmount.mul(1 ether).div(etherRateUsd);
    }

    // TESTED
    function getTokenRateEther() public constant returns (uint256) {
        // div(1000) because 3 decimals in tokenRateUsd
        return convertUsdToEther(tokenRateUsd).div(1000);
    }

    // TESTED
    function getTokenAmountForEther(uint256 weiAmount) constant internal returns (uint256) {
        return weiAmount
            .div(getTokenRateEther())
            .mul(10 ** uint256(token.decimals()));
    }

    // TESTED
    function isReadyToFinalize() internal returns (bool) {
        return(
            (weiRaised >= convertUsdToEther(saleCapUsd)) ||
            (getCurrentState() == State.MainSaleDone)
        );
    }

    // TESTED
    function min(uint256 a, uint256 b) internal returns (uint256) {
        return (a < b) ? a: b;
    }

    // TESTED
    function max(uint256 a, uint256 b) internal returns (uint256) {
        return (a > b) ? a: b;
    }

    // TESTED
    function ceil(uint a, uint b) internal returns (uint) {
        return ((a.add(b).sub(1)).div(b)).mul(b);
    }

    // TESTED
    function getWeiAllowedFromAddress(address _sender) internal returns (uint256) {
        uint256 secondsElapsed = getTime().sub(saleStartDate);
        uint256 fullHours = ceil(secondsElapsed, 3600).div(3600);
        fullHours = max(1, fullHours);
        uint256 weiLimit = fullHours.mul(convertUsdToEther(hourLimitByAddressUsd));
        return weiLimit.sub(raisedByAddress[_sender]);
    }

    function getTime() internal returns (uint256) {
        // Just returns `now` value
        // This function is redefined in EthearnalRepTokenCrowdsaleMock contract
        // to allow testing contract behaviour at different time moments
        return now;
    }

    // TESTED
    function getCurrentState() internal returns (State) {
        return getStateForTime(getTime());
    }

    // TESTED
    function getStateForTime(uint256 unixTime) internal returns (State) {
        if (isFinalized) {
            // This could be before end date of ICO
            // if hard cap is reached
            return State.Finalized;
        }
        if (unixTime < saleStartDate) {
            return State.BeforeMainSale;
        }
        if (unixTime < saleEndDate) {
            return State.MainSale;
        }
        return State.MainSaleDone;
    }

    // TESTED
    function finalize() private {
        if (!isFinalized) {
            require(isReadyToFinalize());
            isFinalized = true;
            mintTeamTokens();
            token.unlock();
            treasuryContract.setCrowdsaleFinished();
        }
    }

    // TESTED
    function mintTeamTokens() private {
        // div by 1000 because of 3 decimals digits in teamTokenRatio
        uint256 tokenAmount = token.totalSupply().mul(teamTokenRatio).div(1000);
        token.mint(teamTokenWallet, tokenAmount);
    }


    function whitelistInvestor(address _newInvestor) public onlyOwner {
        if(!whitelist[_newInvestor]) {
            whitelist[_newInvestor] = true;
            whitelistedInvestorCounter++;
        }
    }
    function whitelistInvestors(address[] _investors) external onlyOwner {
        require(_investors.length <= 250);
        for(uint8 i=0; i<_investors.length;i++) {
            address newInvestor = _investors[i];
            if(!whitelist[newInvestor]) {
                whitelist[newInvestor] = true;
                whitelistedInvestorCounter++;
            }
        }
    }
    function blacklistInvestor(address _investor) public onlyOwner {
        if(whitelist[_investor]) {
            delete whitelist[_investor];
            if(whitelistedInvestorCounter != 0) {
                whitelistedInvestorCounter--;
            }
        }
    }

    function claimTokens(address _token, address _to) public onlyOwner {
        if (_token == 0x0) {
            _to.transfer(this.balance);
            return;
        }
    
        ERC20Basic token = ERC20Basic(_token);
        uint256 balance = token.balanceOf(this);
        token.transfer(_to, balance);
    }

}

contract RefundInvestorsBallot {

    using SafeMath for uint256;
    EthearnalRepToken public tokenContract;

    // Date when vote has started
    uint256 public ballotStarted;

    // Registry of votes
    mapping(address => bool) public votesByAddress;

    // Sum of weights of YES votes
    uint256 public yesVoteSum = 0;

    // Sum of weights of NO votes
    uint256 public noVoteSum = 0;

    // Length of `voters`
    uint256 public votersLength = 0;

    uint256 public initialQuorumPercent = 51;

    VotingProxy public proxyVotingContract;

    // Tells if voting process is active
    bool public isVotingActive = false;
    uint256 public requiredMajorityPercent = 65;

    event FinishBallot(uint256 _time);
    event Vote(address indexed sender, bytes vote);
    
    modifier onlyWhenBallotStarted {
        require(ballotStarted != 0);
        _;
    }

    function vote(bytes _vote) public onlyWhenBallotStarted {
        require(_vote.length > 0);
        if (isDataYes(_vote)) {
            processVote(true);
        } else if (isDataNo(_vote)) {
            processVote(false);
        }
        Vote(msg.sender, _vote);
    }

    function isDataYes(bytes data) public constant returns (bool) {
        // compare data with "YES" string
        return (
            data.length == 3 &&
            (data[0] == 0x59 || data[0] == 0x79) &&
            (data[1] == 0x45 || data[1] == 0x65) &&
            (data[2] == 0x53 || data[2] == 0x73)
        );
    }

    // TESTED
    function isDataNo(bytes data) public constant returns (bool) {
        // compare data with "NO" string
        return (
            data.length == 2 &&
            (data[0] == 0x4e || data[0] == 0x6e) &&
            (data[1] == 0x4f || data[1] == 0x6f)
        );
    }
    
    function processVote(bool isYes) internal {
        require(isVotingActive);
        require(!votesByAddress[msg.sender]);
        votersLength = votersLength.add(1);
        uint256 voteWeight = tokenContract.balanceOf(msg.sender);
        if (isYes) {
            yesVoteSum = yesVoteSum.add(voteWeight);
        } else {
            noVoteSum = noVoteSum.add(voteWeight);
        }
        require(getTime().sub(tokenContract.lastMovement(msg.sender)) > 7 days);
        uint256 quorumPercent = getQuorumPercent();
        if (quorumPercent == 0) {
            isVotingActive = false;
        } else {
            decide();
        }
        votesByAddress[msg.sender] = true;
    }

    function getTime() internal returns (uint256) {
        // Just returns `now` value
        // This function is redefined in EthearnalRepTokenCrowdsaleMock contract
        // to allow testing contract behaviour at different time moments
        return now;
    }

    function RefundInvestorsBallot(address _tokenContract) {
        tokenContract = EthearnalRepToken(_tokenContract);
        proxyVotingContract = VotingProxy(msg.sender);
        ballotStarted = getTime();
        isVotingActive = true;
    }

    function decide() internal {
        uint256 quorumPercent = getQuorumPercent();
        uint256 quorum = quorumPercent.mul(tokenContract.totalSupply()).div(100);
        uint256 soFarVoted = yesVoteSum.add(noVoteSum);
        if (soFarVoted >= quorum) {
            uint256 percentYes = (100 * yesVoteSum).div(soFarVoted);
            if (percentYes >= requiredMajorityPercent) {
                // does not matter if it would be greater than weiRaised
                proxyVotingContract.proxyEnableRefunds();
                FinishBallot(now);
                isVotingActive = false;
            } else {
                // do nothing, just deactivate voting
                isVotingActive = false;
            }
        }
    }
    
    function getQuorumPercent() public constant returns (uint256) {
        uint256 isMonthPassed = getTime().sub(ballotStarted).div(5 weeks);
        if(isMonthPassed == 1){
            return 0;
        }
        return initialQuorumPercent;
    }
    
}

contract Treasury is MultiOwnable {
    using SafeMath for uint256;

    // Total amount of ether withdrawed
    uint256 public weiWithdrawed = 0;

    // Total amount of ther unlocked
    uint256 public weiUnlocked = 0;

    // Wallet withdraw is locked till end of crowdsale
    bool public isCrowdsaleFinished = false;

    // Withdrawed team funds go to this wallet
    address teamWallet = 0x0;

    // Crowdsale contract address
    EthearnalRepTokenCrowdsale public crowdsaleContract;
    EthearnalRepToken public tokenContract;
    bool public isRefundsEnabled = false;

    // Amount of ether that could be withdrawed each withdraw iteration
    uint256 public withdrawChunk = 0;
    VotingProxy public votingProxyContract;
    uint256 public refundsIssued = 0;
    uint256 public percentLeft = 0;


    event Deposit(uint256 amount);
    event Withdraw(uint256 amount);
    event UnlockWei(uint256 amount);
    event RefundedInvestor(address indexed investor, uint256 amountRefunded, uint256 tokensBurn);

    function Treasury(address _teamWallet) public {
        require(_teamWallet != 0x0);
        // TODO: check address integrity
        teamWallet = _teamWallet;
    }

    // TESTED
    function() public payable {
        require(msg.sender == address(crowdsaleContract));
        Deposit(msg.value);
    }

    function setVotingProxy(address _votingProxyContract) public onlyOwner {
        require(votingProxyContract == address(0x0));
        votingProxyContract = VotingProxy(_votingProxyContract);
    }

    // TESTED
    function setCrowdsaleContract(address _address) public onlyOwner {
        // Could be set only once
        require(crowdsaleContract == address(0x0));
        require(_address != 0x0);
        crowdsaleContract = EthearnalRepTokenCrowdsale(_address); 
    }

    function setTokenContract(address _address) public onlyOwner {
        // Could be set only once
        require(tokenContract == address(0x0));
        require(_address != 0x0);
        tokenContract = EthearnalRepToken(_address);
    }

    // TESTED
    function setCrowdsaleFinished() public {
        require(crowdsaleContract != address(0x0));
        require(msg.sender == address(crowdsaleContract));
        withdrawChunk = getWeiRaised().div(10);
        weiUnlocked = withdrawChunk;
        isCrowdsaleFinished = true;
    }

    // TESTED
    function withdrawTeamFunds() public onlyOwner {
        require(isCrowdsaleFinished);
        require(weiUnlocked > weiWithdrawed);
        uint256 toWithdraw = weiUnlocked.sub(weiWithdrawed);
        weiWithdrawed = weiUnlocked;
        teamWallet.transfer(toWithdraw);
        Withdraw(toWithdraw);
    }

    function getWeiRaised() public constant returns(uint256) {
       return crowdsaleContract.weiRaised();
    }

    function increaseWithdrawalChunk() {
        require(isCrowdsaleFinished);
        require(msg.sender == address(votingProxyContract));
        weiUnlocked = weiUnlocked.add(withdrawChunk);
        UnlockWei(weiUnlocked);
    }

    function getTime() internal returns (uint256) {
        // Just returns `now` value
        // This function is redefined in EthearnalRepTokenCrowdsaleMock contract
        // to allow testing contract behaviour at different time moments
        return now;
    }

    function enableRefunds() public {
        require(msg.sender == address(votingProxyContract));
        isRefundsEnabled = true;
    }
    
    function refundInvestor(uint256 _tokensToBurn) public {
        require(isRefundsEnabled);
        require(address(tokenContract) != address(0x0));
        if (refundsIssued == 0) {
            percentLeft = percentLeftFromTotalRaised().mul(100*1000).div(1 ether);
        }
        uint256 tokenRate = crowdsaleContract.getTokenRateEther();
        uint256 toRefund = tokenRate.mul(_tokensToBurn).div(1 ether);
        
        toRefund = toRefund.mul(percentLeft).div(100*1000);
        require(toRefund > 0);
        tokenContract.burnFrom(msg.sender, _tokensToBurn);
        msg.sender.transfer(toRefund);
        refundsIssued = refundsIssued.add(1);
        RefundedInvestor(msg.sender, toRefund, _tokensToBurn);
    }

    function percentLeftFromTotalRaised() public constant returns(uint256) {
        return percent(this.balance, getWeiRaised(), 18);
    }

    function percent(uint numerator, uint denominator, uint precision) internal constant returns(uint quotient) {
        // caution, check safe-to-multiply here
        uint _numerator  = numerator * 10 ** (precision+1);
        // with rounding of last digit
        uint _quotient =  ((_numerator / denominator) + 5) / 10;
        return ( _quotient);
    }

    function claimTokens(address _token, address _to) public onlyOwner {    
        ERC20Basic token = ERC20Basic(_token);
        uint256 balance = token.balanceOf(this);
        token.transfer(_to, balance);
    }
}

contract VotingProxy is Ownable {
    using SafeMath for uint256;    
    Treasury public treasuryContract;
    EthearnalRepToken public tokenContract;
    Ballot public currentIncreaseWithdrawalTeamBallot;
    RefundInvestorsBallot public currentRefundInvestorsBallot;

    function  VotingProxy(address _treasuryContract, address _tokenContract) {
        treasuryContract = Treasury(_treasuryContract);
        tokenContract = EthearnalRepToken(_tokenContract);
    }

    function startincreaseWithdrawalTeam() onlyOwner {
        require(treasuryContract.isCrowdsaleFinished());
        require(address(currentRefundInvestorsBallot) == 0x0 || currentRefundInvestorsBallot.isVotingActive() == false);
        if(address(currentIncreaseWithdrawalTeamBallot) == 0x0) {
            currentIncreaseWithdrawalTeamBallot =  new Ballot(tokenContract);
        } else {
            require(getDaysPassedSinceLastTeamFundsBallot() > 2);
            currentIncreaseWithdrawalTeamBallot =  new Ballot(tokenContract);
        }
    }

    function startRefundInvestorsBallot() public {
        require(treasuryContract.isCrowdsaleFinished());
        require(address(currentIncreaseWithdrawalTeamBallot) == 0x0 || currentIncreaseWithdrawalTeamBallot.isVotingActive() == false);
        if(address(currentRefundInvestorsBallot) == 0x0) {
            currentRefundInvestorsBallot =  new RefundInvestorsBallot(tokenContract);
        } else {
            require(getDaysPassedSinceLastRefundBallot() > 2);
            currentRefundInvestorsBallot =  new RefundInvestorsBallot(tokenContract);
        }
    }

    function getDaysPassedSinceLastRefundBallot() public constant returns(uint256) {
        return getTime().sub(currentRefundInvestorsBallot.ballotStarted()).div(1 days);
    }

    function getDaysPassedSinceLastTeamFundsBallot() public constant returns(uint256) {
        return getTime().sub(currentIncreaseWithdrawalTeamBallot.ballotStarted()).div(1 days);
    }

    function proxyIncreaseWithdrawalChunk() public {
        require(msg.sender == address(currentIncreaseWithdrawalTeamBallot));
        treasuryContract.increaseWithdrawalChunk();
    }

    function proxyEnableRefunds() public {
        require(msg.sender == address(currentRefundInvestorsBallot));
        treasuryContract.enableRefunds();
    }

    function() {
        revert();
    }

    function getTime() internal returns (uint256) {
        // Just returns `now` value
        // This function is redefined in EthearnalRepTokenCrowdsaleMock contract
        // to allow testing contract behaviour at different time moments
        return now;
    }

    function claimTokens(address _token) public onlyOwner {
        if (_token == 0x0) {
            owner.transfer(this.balance);
            return;
        }
    
        ERC20Basic token = ERC20Basic(_token);
        uint256 balance = token.balanceOf(this);
        token.transfer(owner, balance);
    }

}