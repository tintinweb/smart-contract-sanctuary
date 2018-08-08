pragma solidity ^0.4.13;
/// @title Ownable contract - base contract with an owner
contract Ownable {
    address public owner;

    function Ownable() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

/// @title Killable contract - base contract that can be killed by owner. All funds in contract will be sent to the owner.
contract Killable is Ownable {
    function kill() onlyOwner {
        selfdestruct(owner);
    }
}

/// @title Haltable contract - abstract contract that allows children to implement an emergency stop mechanism.
/// Originally envisioned in FirstBlood ICO contract.
contract Haltable is Ownable {
    bool public halted;

    modifier stopInEmergency {
        require(!halted);
        _;
    }

    modifier onlyInEmergency {
        require(halted);
        _;
    }

    /// called by the owner on emergency, triggers stopped state
    function halt() external onlyOwner {
        halted = true;
    }

    /// called by the owner on end of emergency, returns to normal state
    function unhalt() external onlyOwner onlyInEmergency {
        halted = false;
    }
}

/// @title Migrations contract - abstract contract that allows migrate to new address.
contract Migrations is Ownable {
    uint public lastCompletedMigration;

    function setCompleted(uint completed) onlyOwner {
        lastCompletedMigration = completed;
    }

    function upgrade(address newAddress) onlyOwner {
        Migrations upgraded = Migrations(newAddress);
        upgraded.setCompleted(lastCompletedMigration);
    }
}
/// @title Pausable contract - abstract contract that allows children to implement an emergency stop mechanism.
contract Pausable is Ownable {
    bool public stopped;

    modifier stopInEmergency {
        if (!stopped) {
            _;
        }
    }

    modifier onlyInEmergency {
        if (stopped) {
            _;
        }
    }

    /// called by the owner on emergency, triggers stopped state
    function emergencyStop() external onlyOwner {
        stopped = true;
    }

    /// called by the owner on end of emergency, returns to normal state
    function release() external onlyOwner onlyInEmergency {
        stopped = false;
    }
}

/// @title ERC20 interface see https://github.com/ethereum/EIPs/issues/20
contract ERC20 {
    uint public totalSupply;
    function balanceOf(address who) constant returns (uint);
    function allowance(address owner, address spender) constant returns (uint);
    function mint(address receiver, uint amount);
    function transfer(address to, uint value) returns (bool ok);
    function transferFrom(address from, address to, uint value) returns (bool ok);
    function approve(address spender, uint value) returns (bool ok);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}


/// @title SafeMath contract - math operations with safety checks
contract SafeMath {
    function safeMul(uint a, uint b) internal returns (uint) {
        uint c = a * b;
        return c;
    }

    function safeDiv(uint a, uint b) internal returns (uint) {
        uint c = a / b;
        return c;
    }

    function safeSub(uint a, uint b) internal returns (uint) {
        return a - b;
    }

    function safeAdd(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        return c;
    }

    function max64(uint64 a, uint64 b) internal constant returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal constant returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal constant returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal constant returns (uint256) {
        return a < b ? a : b;
    }
}

/// @title ShareEstateToken contract - ERC20 token with Short Hand Attack and approve() race condition mitigation.
contract ShareEstateToken is SafeMath, ERC20, Ownable {
    string public name = "ShareEstate Token";
    string public symbol = "SRE";
    uint public decimals = 4;

    /// contract that is allowed to create new tokens and allows unlift the transfer limits on this token
    address public crowdsaleAgent;
    /// A crowdsale contract can release us to the wild if ICO success. If false we are are in transfer lock up period.
    bool public released = false;
    /// approve() allowances
    mapping (address => mapping (address => uint)) allowed;
    /// holder balances
    mapping(address => uint) balances;

    /// @dev Limit token transfer until the crowdsale is over.
    modifier canTransfer() {
        if(!released) {
            require(msg.sender == crowdsaleAgent);
        }
        _;
    }

    /// @dev The function can be called only before or after the tokens have been releasesd
    /// @param _released token transfer and mint state
    modifier inReleaseState(bool _released) {
        require(_released == released);
        _;
    }

    /// @dev The function can be called only by release agent.
    modifier onlyCrowdsaleAgent() {
        require(msg.sender == crowdsaleAgent);
        _;
    }

    /// @dev Fix for the ERC20 short address attack http://vessenes.com/the-erc20-short-address-attack-explained/
    /// @param size payload size
    modifier onlyPayloadSize(uint size) {
        require(msg.data.length >= size + 4);
        _;
    }

    /// @dev Make sure we are not done yet.
    modifier canMint() {
        require(!released);
        _;
    }

    /// @dev Main Constructor
    function ShareEstateToken() {
        owner = msg.sender;
    }

    /// Fallback method will buyout tokens
    function() payable {
        revert();
    }

    /// @dev Create new tokens and allocate them to an address. Only callable by a crowdsale contract
    /// @param receiver Address of receiver
    /// @param amount  Number of tokens to issue.
    function mint(address receiver, uint amount) onlyCrowdsaleAgent canMint public {
        totalSupply = safeAdd(totalSupply, amount);
        balances[receiver] = safeAdd(balances[receiver], amount);
        Transfer(0, receiver, amount);
    }

    /// @dev Set the contract that can call release and make the token transferable.
    /// @param _crowdsaleAgent crowdsale contract address
    function setCrowdsaleAgent(address _crowdsaleAgent) onlyOwner inReleaseState(false) public {
        crowdsaleAgent = _crowdsaleAgent;
    }
    /// @dev One way function to release the tokens to the wild. Can be called only from the release agent that is the final ICO contract. It is only called if the crowdsale has been success (first milestone reached).
    function releaseTokenTransfer() public onlyCrowdsaleAgent {
        released = true;
    }
    /// @dev Tranfer tokens to address
    /// @param _to dest address
    /// @param _value tokens amount
    /// @return transfer result
    function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) canTransfer returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);

        Transfer(msg.sender, _to, _value);
        return true;
    }

    /// @dev Tranfer tokens from one address to other
    /// @param _from source address
    /// @param _to dest address
    /// @param _value tokens amount
    /// @return transfer result
    function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(2 * 32) canTransfer returns (bool success) {
        var _allowance = allowed[_from][msg.sender];

        balances[_to] = safeAdd(balances[_to], _value);
        balances[_from] = safeSub(balances[_from], _value);
        allowed[_from][msg.sender] = safeSub(_allowance, _value);
        Transfer(_from, _to, _value);
        return true;
    }
    /// @dev Tokens balance
    /// @param _owner holder address
    /// @return balance amount
    function balanceOf(address _owner) constant returns (uint balance) {
        return balances[_owner];
    }

    /// @dev Approve transfer
    /// @param _spender holder address
    /// @param _value tokens amount
    /// @return result
    function approve(address _spender, uint _value) returns (bool success) {
        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender, 0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require ((_value == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    /// @dev Token allowance
    /// @param _owner holder address
    /// @param _spender spender address
    /// @return remain amount
    function allowance(address _owner, address _spender) constant returns (uint remaining) {
        return allowed[_owner][_spender];
    }
}
/// @title ShareEstateTokenCrowdsale contract - contract for token sales.
contract ShareEstateTokenCrowdsale is Haltable, Killable, SafeMath {

    /// Prefunding goal in USD cents, if the prefunding goal is reached, pre ICO will stop
    uint public constant PRE_FUNDING_GOAL = 1e6 * PRICE;

    /// Miminal tokens funding goal in USD cents, if this goal isn&#39;t reached during ICO, refund will begin
    uint public constant MIN_PRE_FUNDING_GOAL = 2e5 * PRICE;

    /// Percent of bonus tokens team receives from each investment
    uint public constant TEAM_BONUS_PERCENT = 24;

    /// The token price in USD cents
    uint constant public PRICE = 100;

    /// Duration of the pre-ICO stage
    uint constant public PRE_ICO_DURATION = 5 weeks;

    /// The token we are selling

    ShareEstateToken public token;

    /// tokens will be transfered from this address
    address public multisigWallet;

    /// the UNIX timestamp start date of the crowdsale
    uint public startsAt;

    /// the UNIX timestamp end date of the crowdsale
    uint public preIcoEndsAt;

    /// the number of tokens already sold through this contract
    uint public tokensSold = 0;

    /// How many wei of funding we have raised
    uint public weiRaised = 0;

    /// How many distinct addresses have invested
    uint public investorCount = 0;

    /// How much wei we have returned back to the contract after a failed crowdfund.
    uint public loadedRefund = 0;

    /// How much wei we have given back to investors.
    uint public weiRefunded = 0;

    /// Has this crowdsale been finalized
    bool public finalized;

    /// USD to Ether rate in cents
    uint public exchangeRate;

    /// exchangeRate timestamp
    uint public exchangeRateTimestamp;

    /// External agent that will can change exchange rate
    address public exchangeRateAgent;

    /// How much ETH each address has invested to this crowdsale
    mapping (address => uint256) public investedAmountOf;

    /// How much tokens this crowdsale has credited for each investor address
    mapping (address => uint256) public tokenAmountOf;

    /// Define preICO pricing schedule using milestones.
    struct Milestone {
    // UNIX timestamp when this milestone kicks in
    uint start;
    // UNIX timestamp when this milestone kicks out
    uint end;
    // How many % tokens will add
    uint bonus;
    }

    Milestone[] public milestones;

    /// State machine
    /// Preparing: All contract initialization calls and variables have not been set yet
    /// Prefunding: We have not passed start time yet
    /// PreFundingSuccess: Minimum funding goal reached
    /// Failure: Minimum funding goal not reached before ending time
    /// Finalized: The finalized has been called and succesfully executed\
    /// Refunding: Refunds are loaded on the contract for reclaim.
    enum State{Unknown, Preparing, PreFunding, PreFundingSuccess, Failure, Finalized, Refunding}

    /// A new investment was made
    event Invested(address investor, uint weiAmount, uint tokenAmount);
    /// Refund was processed for a contributor
    event Refund(address investor, uint weiAmount);
    /// Crowdsale end time has been changed
    event preIcoEndsAtChanged(uint endsAt);
    /// Calculated new
    event ExchangeRateChanged(uint oldValue, uint newValue);

    /// @dev Modified allowing execution only if the crowdsale is currently running
    modifier inState(State state) {
        require(getState() == state);
        _;
    }

    modifier onlyExchangeRateAgent() {
        require(msg.sender == exchangeRateAgent);
        _;
    }

    /// @dev Constructor
    /// @param _token Solar Dao token address
    /// @param _multisigWallet team wallet
    /// @param _preInvestStart preICO start date
    /// @param _preInvestStop token ICO end date
    function ShareEstateTokenCrowdsale(address _token, address _multisigWallet, uint _preInvestStart, uint _preInvestStop) {
        require(_multisigWallet != 0);
        require(_preInvestStart != 0);
        require(_preInvestStop != 0);
        require(_preInvestStart < _preInvestStop);

        token = ShareEstateToken(_token);

        multisigWallet = _multisigWallet;
        startsAt = _preInvestStart;
        preIcoEndsAt = _preInvestStop;
        var preIcoBonuses = [uint(65), 50, 40, 35, 30];
        for (uint i = 0; i < preIcoBonuses.length; i++) {
            milestones.push(Milestone(_preInvestStart + i * 1 weeks, _preInvestStart + (i + 1) * 1 weeks, preIcoBonuses[i]));
        }
    }

    function() payable {
        buy();
    }

    /// @dev Get the current milestone or bail out if we are not in the milestone periods.
    /// @return Milestone current bonus milestone
    function getCurrentMilestone() private constant returns (Milestone) {
        for (uint i = 0; i < milestones.length; i++) {
            if (milestones[i].start <= now && milestones[i].end > now) {
                return milestones[i];
            }
        }
    }

    /// @dev Make an investment. Crowdsale must be running for one to invest.
    /// @param receiver The Ethereum address who receives the tokens
    function investInternal(address receiver) stopInEmergency private {
        var state = getState();
        require(state == State.PreFunding);

        uint weiAmount = msg.value;
        uint tokensAmount = calculateTokens(weiAmount);

        if(state == State.PreFunding) {
            tokensAmount += safeDiv(safeMul(tokensAmount, getCurrentMilestone().bonus), 100);
        }

        if(investedAmountOf[receiver] == 0) {
            // A new investor
            investorCount++;
        }

        // Update investor
        investedAmountOf[receiver] = safeAdd(investedAmountOf[receiver], weiAmount);
        tokenAmountOf[receiver] = safeAdd(tokenAmountOf[receiver], tokensAmount);
        // Update totals
        weiRaised = safeAdd(weiRaised, weiAmount);
        tokensSold = safeAdd(tokensSold, tokensAmount);

        assignTokens(receiver, tokensAmount);
        var teamBonusTokens = safeDiv(safeMul(tokensAmount, TEAM_BONUS_PERCENT), 100 - TEAM_BONUS_PERCENT);
        assignTokens(multisigWallet, teamBonusTokens);

        multisigWallet.transfer(weiAmount);
        // Tell us invest was success
        Invested(receiver, weiAmount, tokensAmount);
    }

    /// @dev Allow anonymous contributions to this crowdsale.
    /// @param receiver The Ethereum address who receives the tokens
    function invest(address receiver) public payable {
        investInternal(receiver);
    }

    /// @dev The basic entry point to participate the crowdsale process.
    function buy() public payable {
        invest(msg.sender);
    }

    /// @dev Finalize a succcesful crowdsale.
    function finalize() public inState(State.PreFundingSuccess) onlyOwner stopInEmergency {
        require(!finalized);

        finalized = true;
        finalizeCrowdsale();
    }

    /// @dev Finalize a succcesful crowdsale.
    function finalizeCrowdsale() internal {
        //assignTokens(owner, safeAdd(safeSub(uint(MAX_TOKENS_TO_SOLD), tokensSold), TEAM_TOKENS_AMOUNT));
        //token.releaseTokenTransfer(); // Will be released in result of ICO
    }

    /// @dev Method for setting USD to Ether rate from Poloniex
    /// @param value USD amout in cents for 1 Ether
    /// @param time timestamp
    function setExchangeRate(uint value, uint time) onlyExchangeRateAgent {
        require(value > 0);
        require(time > 0);
        require(exchangeRateTimestamp == 0 || getDifference(int(time), int(now)) <= 1 minutes);
        require(exchangeRate == 0 || (getDifference(int(value), int(exchangeRate)) * 100 / exchangeRate <= 30));

        ExchangeRateChanged(exchangeRate, value);
        exchangeRate = value;
        exchangeRateTimestamp = time;
    }

    /// @dev Method set exchange rate agent
    /// @param newAgent new agent
    function setExchangeRateAgent(address newAgent) onlyOwner {
        if (newAgent != address(0)) {
            exchangeRateAgent = newAgent;
        }
    }

    function getDifference(int one, int two) private constant returns (uint) {
        var diff = one - two;
        if (diff < 0)
        diff = -diff;
        return uint(diff);
    }

    /// @dev Allow crowdsale owner to close early or extend the crowdsale.
    /// @param time timestamp
    function setPreIcoEndsAt(uint time) onlyOwner {
        require(time >= now);
        preIcoEndsAt = time;
        preIcoEndsAtChanged(preIcoEndsAt);
    }

    /// @dev Allow load refunds back on the contract for the refunding.
    function loadRefund() public payable inState(State.Failure) {
        require(msg.value > 0);
        loadedRefund = safeAdd(loadedRefund, msg.value);
    }

    /// @dev Investors can claim refund.
    function refund() public inState(State.Refunding) {
        uint256 weiValue = investedAmountOf[msg.sender];
        if (weiValue == 0)
        return;
        investedAmountOf[msg.sender] = 0;
        weiRefunded = safeAdd(weiRefunded, weiValue);
        Refund(msg.sender, weiValue);
        msg.sender.transfer(weiValue);
    }

    /// @dev Minimum goal was reached
    /// @return true if the crowdsale has raised enough money to not initiate the refunding
    function isMinimumGoalReached() public constant returns (bool reached) {
        return weiToUsdCents(weiRaised) >= MIN_PRE_FUNDING_GOAL;
    }

    /// @dev Method set data from migrated contract
    /// @param _tokensSold tokens sold
    /// @param _weiRaised _wei raised
    /// @param _investorCount investor count
    function setCrowdsaleData(uint _tokensSold, uint _weiRaised, uint _investorCount) onlyOwner {
        require(_tokensSold > 0);
        require(_weiRaised > 0);
        require(_investorCount > 0);

        tokensSold = _tokensSold;
        weiRaised = _weiRaised;
        investorCount = _investorCount;
    }

    /// @dev Crowdfund state machine management.
    /// @return State current state
    function getState() public constant returns (State) {
        if (finalized)
        return State.Finalized;
        if (address(token) == 0 || address(multisigWallet) == 0 || now < startsAt)
        return State.Preparing;
        if (now > startsAt && now < preIcoEndsAt - 2 days && !isMaximumPreFundingGoalReached())
        return State.PreFunding;
        if (isMinimumGoalReached())
        return State.PreFundingSuccess;
        if (!isMinimumGoalReached() && weiRaised > 0 && loadedRefund >= weiRaised)
        return State.Refunding;
        return State.Failure;
    }

    /// @dev Calculating tokens count
    /// @param weiAmount invested
    /// @return tokens amount
    function calculateTokens(uint weiAmount) internal returns (uint tokenAmount) {
        var multiplier = 10 ** token.decimals();

        uint usdAmount = weiToUsdCents(weiAmount);

        return safeMul(usdAmount, safeDiv(multiplier, PRICE));
    }

    /// @dev Check if the pre ICO goal was reached.
    /// @return true if the preICO has raised enough money to be a success
    function isMaximumPreFundingGoalReached() public constant returns (bool reached) {
        return weiToUsdCents(weiRaised) >= PRE_FUNDING_GOAL;
    }

    /// @dev Converts wei value into USD cents according to current exchange rate
    /// @param weiValue wei value to convert
    /// @return USD cents equivalent of the wei value
    function weiToUsdCents(uint weiValue) private returns (uint) {
        return safeDiv(safeMul(weiValue, exchangeRate), 1e18);
    }

    /// @dev Dynamically create tokens and assign them to the investor.
    /// @param receiver investor address
    /// @param tokenAmount The amount of tokens we try to give to the investor in the current transaction
    function assignTokens(address receiver, uint tokenAmount) private {
        token.mint(receiver, tokenAmount);
    }
}