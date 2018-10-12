pragma solidity ^0.4.20;

// File: contracts/ERC20Token.sol

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal  pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal  pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure  returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Owned {

    address public owner;
    address newOwner;

    modifier only(address _allowed) {
        require(msg.sender == _allowed);
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function transferOwnership(address _newOwner) only(owner) public {
        newOwner = _newOwner;
    }

    function acceptOwnership() only(newOwner) public {
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    event OwnershipTransferred(address indexed _from, address indexed _to);

}

contract ERC20 is Owned {
    using SafeMath for uint;

    uint public totalSupply;
    bool public isStarted = false;
    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowed;

    modifier isStartedOnly() {
        require(isStarted);
        _;
    }

    modifier isNotStartedOnly() {
        require(!isStarted);
        _;
    }

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

    function transfer(address _to, uint _value) isStartedOnly public returns (bool success) {
        require(_to != address(0));
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value) isStartedOnly public returns (bool success) {
        require(_to != address(0));
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint balance) {
        return balances[_owner];
    }

    function approve_fixed(address _spender, uint _currentValue, uint _value) isStartedOnly public returns (bool success) {
        if(allowed[msg.sender][_spender] == _currentValue){
            allowed[msg.sender][_spender] = _value;
            emit Approval(msg.sender, _spender, _value);
            return true;
        } else {
            return false;
        }
    }

    function approve(address _spender, uint _value) isStartedOnly public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint remaining) {
        return allowed[_owner][_spender];
    }

}

contract Token is ERC20 {
    using SafeMath for uint;

    string public name;
    string public symbol;
    uint8 public decimals;

    constructor(string _name, string _symbol, uint8 _decimals) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    function start() public only(owner) isNotStartedOnly {
        isStarted = true;
    }

    //================= Crowdsale Only =================
    function mint(address _to, uint _amount) public only(owner) isNotStartedOnly returns(bool) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }

    function multimint(address[] dests, uint[] values) public only(owner) isNotStartedOnly returns (uint) {
        uint i = 0;
        while (i < dests.length) {
           mint(dests[i], values[i]);
           i += 1;
        }
        return(i);
    }
}

contract TokenWithoutStart is Owned {
    using SafeMath for uint;

    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowed;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint public totalSupply;

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

    constructor(string _name, string _symbol, uint8 _decimals) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    function transfer(address _to, uint _value) public returns (bool success) {
        require(_to != address(0));
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
        require(_to != address(0));
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint balance) {
        return balances[_owner];
    }

    function approve_fixed(address _spender, uint _currentValue, uint _value) public returns (bool success) {
        if(allowed[msg.sender][_spender] == _currentValue){
            allowed[msg.sender][_spender] = _value;
            emit Approval(msg.sender, _spender, _value);
            return true;
        } else {
            return false;
        }
    }

    function approve(address _spender, uint _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint remaining) {
        return allowed[_owner][_spender];
    }

    function mint(address _to, uint _amount) public only(owner) returns(bool) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }

    function multimint(address[] dests, uint[] values) public only(owner) returns (uint) {
        uint i = 0;
        while (i < dests.length) {
           mint(dests[i], values[i]);
           i += 1;
        }
        return(i);
    }

}

// File: contracts/AgileSet.sol

// REMEMER TO UNCOMMENT TIME CHECKS!!!!!
contract AgileICO {

    using SafeMath for uint;

    address public operator; // ICO operator
    address public juryOperator; // Jury.Online operator
    address public projectWallet; // Wallet where project funds are sent
    address public arbitrationAddress; // address of contract that handles arbitration
    address public juryOnlineWallet; // Wallet for Jury.Online commission

    bool public requireTokens; // if true, token balance needed before accept offer

    uint public promisedTokens;
    uint public etherAllowance;
    uint public jotAllowance;
    uint public commissionOnInvestmentJot; // commission paid in ETH when operator accepts offer
    uint public commissionOnInvestmentEth; // commission paid in JOT when operator accepts offer
    uint public percentForFuture; // percent of investment offer that is not sent to Cycle and kept for future
    uint public rate = 1; // amount of token for each wei in investment offer
    address public currentCycleAddress; // address of current AgileCycle contract
    uint public currentCycleNumber; // indicates current cycle

    uint public currentFundingRound; // indicates current funding round (should be removed)
    uint public minimumInvestment;

    uint public lastRateChange; // used to prevent changing rates more than once a day

    Token public token; // proxy or real token
    // Offer struct stores information about all offers and deals
    // a deal is an accepted offer
    struct Offer {
        uint etherAmount; // etherAmount of investment offer
        uint tokenAmount; // tokenAmount of investment offer
        bool accepted; // true if offer has been accepted
        uint numberOfDeals; // indicates number of deals an investor has
    }
    // below mapping maps an investor address to a deal number to the details
    // of that deal (etherAmount, tokenAmount, accepted, numberOfDeals)
    mapping(address => mapping(uint => Offer)) public offers;

    address[] public cycles; // stores the addresses of cycles

    // Stores the amount stored for future cycles
    struct FutureDeal {
        uint etherAmount; // etherAmount for future
        uint tokenAmount; // tokenAmount for future
    }
    // below mapping maps investor address to a futureDeal, that is, an amount
    // which will be used in future cycles.
    mapping(address => FutureDeal) public futureDeals;

    address[] public investorList; // list of investor

    // FundingRound struct stores information about each FundingRound
    struct FundingRound {
        uint startTime;
        uint endTime;
        uint rate;
        bool hasWhitelist;
    }
    FundingRound[] public roundPrices;  // stores list of funding rounds
    mapping(uint => mapping(address => bool)) public whitelist; // stores whitelists (if any) for funding round

    bool public saveMe;

    modifier only(address _sender) {
        require(msg.sender == _sender);
        _;
    }

    constructor(
            address _operator,
            uint _commissionOnInvestmentJot,
            uint _commissionOnInvestmentEth,
            uint _percentForFuture,
            address _projectWallet,
            address _arbitrationAddress,
	    address _tokenAddress,
            address _juryOperator,
            address _juryOnlineWallet,
	    uint _minimumInvestment
        ) public {
        percentForFuture = _percentForFuture;
        operator = _operator;
        commissionOnInvestmentJot = _commissionOnInvestmentJot;
        commissionOnInvestmentEth = _commissionOnInvestmentEth;
        percentForFuture = _percentForFuture;
        projectWallet = _projectWallet;
        arbitrationAddress = _arbitrationAddress;
	token = Token(_tokenAddress);
        juryOperator = _juryOperator;
        juryOnlineWallet = _juryOnlineWallet;
	minimumInvestment = _minimumInvestment;
    }

    // PUBLIC ------------------------------------------------------------------
    // payable function recieves ETH and creates an &#39;offer&#39;
    // wont succeed with 2300 stipend for send, must add more gas
    function () public payable {
        // INVESTOR SENDS OFFER BY SENDING ETH TO CONTRACT
        require(msg.value > minimumInvestment);
    	for (uint i = 0; i < roundPrices.length; i++ ) {
		if (now > roundPrices[i].startTime && now < roundPrices[i].endTime) {
			rate = roundPrices[i].rate;
			if (roundPrices[i].hasWhitelist == true) {
				require(whitelist[i][msg.sender] == true);
			}
		}
	}
	/*
	if (roundPrices.length > 0) {
                if (roundPrices[currentFundingRound].hasWhitelist == true) {
                    require(whitelist[currentFundingRound][msg.sender] == true);
                }
    	}
        */
        uint dealNumber = offers[msg.sender][0].numberOfDeals;
        // uint dealNumber = 0;
	offers[msg.sender][dealNumber].etherAmount = msg.value;
        offers[msg.sender][dealNumber].tokenAmount = msg.value*rate;
        offers[msg.sender][0].numberOfDeals += 1;
    }
    // Investor can withdraw offer if it has not been accepted
    function withdrawOffer(uint _offerNumber) public {
        // INVESTOR CAN WITHDRAW OFFER
        require(offers[msg.sender][_offerNumber].accepted == false);
        require(msg.sender.send(offers[msg.sender][_offerNumber].etherAmount));
        offers[msg.sender][_offerNumber].etherAmount = 0;
    }
    // Calles by Jury.Online to retrieve commission
    function withdrawEther() public {
        if (msg.sender == juryOperator) {
            require(juryOnlineWallet.send(etherAllowance));
            //require(jotter.call.value(jotAllowance)(abi.encodeWithSignature("swapMe()")));
            etherAllowance = 0;
            jotAllowance = 0;
        }
    }
    // -------------------------------------------------------------------------
    // ICO OPERATOR ------------------------------------------------------------
    // operator can acept offer, it keeps certain amount in futureDeals, and sends
    // rest to Cycle contract by calling offerAccepted() in Cycle
    function setToken(address _tokenAddress) public only(operator) {
    	require(token == 0x0000000000000000000000000000000000000000);
	    token = Token(_tokenAddress);
    }
    function acceptOffer(address _investor, uint _offerNumber) public only(operator) {
        require(offers[_investor][_offerNumber].etherAmount > 0);
        require(offers[_investor][_offerNumber].accepted != true);

        AgileCycle cycle = AgileCycle(currentCycleAddress);

	    require(cycle.sealTimestamp() > 0);

        offers[_investor][_offerNumber].accepted = true;
        uint _etherAmount = offers[_investor][_offerNumber].etherAmount;
        uint _tokenAmount = offers[_investor][_offerNumber].tokenAmount;

        require(token.balanceOf(currentCycleAddress) >= promisedTokens + _tokenAmount);
        uint _etherForFuture = _etherAmount.mul(percentForFuture).div(100);
        uint _tokenForFuture =  _tokenAmount.mul(percentForFuture).div(100);

        if (_offerNumber == 0) {
            futureDeals[_investor].etherAmount += _etherForFuture;
            futureDeals[_investor].tokenAmount += _tokenForFuture;
        } else {
            futureDeals[_investor] = FutureDeal(_etherForFuture,_tokenForFuture);
        }

        _etherAmount = _etherAmount.sub(_etherForFuture);
        _tokenAmount = _tokenAmount.sub(_tokenForFuture);

        if (commissionOnInvestmentEth > 0 || commissionOnInvestmentJot > 0) {
            uint etherCommission = _etherAmount.mul(commissionOnInvestmentEth).div(100);
            uint jotCommission = _etherAmount.mul(commissionOnInvestmentJot).div(100);
	        _etherAmount = _etherAmount.sub(etherCommission).sub(jotCommission);
            offers[_investor][_offerNumber].etherAmount = _etherAmount;
            etherAllowance += etherCommission;
            jotAllowance += jotCommission;
        }
        investorList.push(_investor);
        cycle.offerAccepted.value(_etherAmount)(_investor, _tokenAmount);
    }
    // after deploying Cycle, operator adds cycle address
    function addCycleAddress(address _cycleAddress) public only(operator) {
        cycles.push(_cycleAddress);
    }
    // Sets the active cycle. If not first one, previous one has to be finished.
    function setNextCycle() public only(operator) {
        require(cycles.length > 0);
        if (currentCycleNumber > 0) {
            AgileCycle cycle = AgileCycle(currentCycleAddress);
            uint finishedTimeStamp = cycle.finishedTimeStamp();
            require(now > finishedTimeStamp);
            uint interval = now - finishedTimeStamp;
            //require(interval > 3 days);
        }
        currentCycleAddress = cycles[currentCycleNumber];
        currentCycleNumber += 1;
    }
    // to add FundingRounds
    function addFundingRound(uint _startTime,uint _endTime, uint _rate, address[] _whitelist) public only(operator) {
        if (_whitelist.length == 0) {
            roundPrices.push(FundingRound(_startTime, _endTime,_rate,false));
        } else {
            for (uint i=0 ; i < _whitelist.length ; i++ ) {
                whitelist[roundPrices.length][_whitelist[i]] = true;
            }
            roundPrices.push(FundingRound(_startTime, _endTime,_rate,true));
        }
    }
    // to set rate directly
    function setRate(uint _rate) only(operator) public {
        uint interval = now - lastRateChange;
        //require(interval < 1 days);
        rate = _rate;
    }
    // to activate a fundingRound
    function setCurrentFundingRound(uint _fundingRound) public only(operator) {
        require(roundPrices.length > _fundingRound);
        currentFundingRound = _fundingRound;
        rate = roundPrices[_fundingRound].rate;
    }
    // sends futureDeal funds to next cycle
    // it has loop control in case of lack of gas
    function sendFundsToNextCycle(uint _startLoop, uint _endLoop) public only(operator) {
        AgileCycle cycle = AgileCycle(currentCycleAddress);
        require(cycle.sealTimestamp() > 0);

        uint _promisedTokens = cycle.promisedTokens();
        uint _balanceTokens = token.balanceOf(currentCycleAddress);

        if (_endLoop == 0) _endLoop = investorList.length;
        require(_endLoop <= investorList.length);

        require(token.balanceOf(currentCycleAddress) >= promisedTokens + _tokenAmount);

        for ( uint i=_startLoop; i < _endLoop; i++ ) {
    	    address _investor = investorList[i];
    	    uint _etherAmount = futureDeals[_investor].etherAmount;
    	    uint _tokenAmount = futureDeals[_investor].tokenAmount;
            _promisedTokens += _tokenAmount;
            if (requireTokens) require(_balanceTokens >= _promisedTokens);
    	    cycle.offerAccepted.value(_etherAmount)(_investor, _tokenAmount);
    	    futureDeals[_investor].etherAmount = 0;
    	    futureDeals[_investor].tokenAmount = 0;
    	    //futureDeals[_investor].sent = true;
        }
    }
    // -------------------------------------------------------------------------
    // HELPERS -----------------------------------------------------------------
    function failSafe() public {
        if (msg.sender == operator) {
            saveMe = true;
        }
        if (msg.sender == juryOperator) {
            require(saveMe == true);
            require(juryOperator.send(address(this).balance));
            uint allTheLockedTokens = token.balanceOf(this);
            require(token.transfer(juryOperator,allTheLockedTokens));
        }
    }

}

contract AgileCycle {
    using SafeMath for uint;
    //VARIABLES
    address public operator; // should be same as ICO (no check for this yet)
    address public juryOperator; // for failsafe
    uint public promisedTokens; // the number of tokens owed to investor by accepting offer
    uint public raisedEther; // amount of ether raised by accepting offers

    bool public tokenReleaseAtStart; // whether tokens released at start or by milestones

    address public icoAddress; // ICO address
    address public arbitrationAddress;

    bool public roundFailedToStart;
    address public projectWallet;
    address public juryOnlineWallet;

    struct Milestone {
        uint etherAmount; //how many Ether is needed for this milestone
        uint tokenAmount; //how many tokens releases this milestone
        uint startTime; //real time when milestone has started, set upon start
        uint finishTime; //real time when milestone has finished, set upon finish
        uint duration; //assumed duration for milestone implementation, set upon milestone creation
        string description;
        string result;
    }
    Milestone[] public milestones; // list of milestones

    uint[] public commissionEth; // each element corresponds to amount of commission paid in each milestone
    uint[] public commissionJot; // same as above, but in JOT. Both amount stored in percentages
    uint public currentMilestone; // stores index of current milestone
    uint public etherAllowance; // amount allowed for Jury.Online in commission ETH
    uint public jotAllowance; // amount allowed for Jury.Online in commission JOT
    uint public ethForMilestone; // amomunt allowed for project to withdraw in milestone
    Token public token; // Real or Proxy token
    uint public totalToken; // sum of Tokens in all milestones
    uint public totalEther; // sum of ETH in all milstones
    uint public sealTimestamp; // timestamp when Cycle is sealed

    mapping(address => uint[]) public etherPartition;
    mapping(address => uint[]) public tokenPartition;

    struct Deal {
        uint etherAmount; // amount of ETH in deal
        uint tokenAmount; // amount of Tokens in deal
        bool disputing; // true if disputing, funds are frozen
        uint tokenAllowance; // amount allowed for investor to withdraw
        uint etherUsed; // ETH already used and not available for refund
        bool verdictForProject; // verdict for project
        bool verdictForInvestor; // verdict for investor
    }
    mapping(address => Deal) public deals; // mapping of investor to deal
    address[] public dealsList; // list of addresses of investor deals, used for iteration in startMilestone()

    uint public finishedTimeStamp; // when all milestones are finished. Checked by ICO.

    uint public postDisputeEth; // for debugging
    bool public saveMe; //for failsafe
    bool public cycleApproved; // Jury must approve the start of an ICO

    modifier only(address _allowed) {
        require(msg.sender == _allowed);
        _;
    }
    modifier sealed() {
    	require(sealTimestamp > 0);
    	_;
    }
    modifier notSealed() {
    	require(sealTimestamp == 0);
    	_;
    }

    constructor(
            bool _tokenReleaseAtStart,
            address _icoAddress,
            uint[] _commissionEth,
            uint[] _commissionJot,
            address _operator,
            address _juryOperator,
            address _arbitrationAddress,
            address _projectWallet,
            address _juryOnlineWallet
        ) public {
            tokenReleaseAtStart = _tokenReleaseAtStart;
            icoAddress = _icoAddress;
            commissionEth = _commissionEth;
            commissionJot = _commissionJot;
            operator = _operator;
            juryOperator = _juryOperator;
            arbitrationAddress = _arbitrationAddress;
            projectWallet = _projectWallet;
            juryOnlineWallet = _juryOnlineWallet;
    }

    function setToken(address _tokenAddress) public only(operator) {
    	require(token == 0x0000000000000000000000000000000000000000);
	    token = Token(_tokenAddress);
    }
    // CALLED BY JURY.ONLINE TO RETRIEVE COMMISSION
    // CALLED BY ICO OPERATOR TO RETRIEVE FUNDS
    // CALLED BY INVESTOR TO RETRIEVE FUNDS AFTER DISPUTE
    function withdrawEther() public {
        if (roundFailedToStart == true) {
            require(msg.sender.send(deals[msg.sender].etherAmount));
        }
        if (msg.sender == operator) {
            require(projectWallet.send(ethForMilestone+postDisputeEth));
            ethForMilestone = 0;
            postDisputeEth = 0;
        }
        if (msg.sender == juryOperator) {
            require(juryOnlineWallet.send(etherAllowance));
            //require(jotter.call.value(jotAllowance)(abi.encodeWithSignature("swapMe()")));
            etherAllowance = 0;
            jotAllowance = 0;
        }
        if (deals[msg.sender].verdictForInvestor == true) {
            require(msg.sender.send(deals[msg.sender].etherAmount - deals[msg.sender].etherUsed));
        }
    }
    // CALLED BY INVESTOR TO RETRIEVE TOKENS
    function withdrawToken() public {
        require(token.transfer(msg.sender,deals[msg.sender].tokenAllowance));
        deals[msg.sender].tokenAllowance = 0;
    }


    // OPERATOR ----------------------------------------------------------------
    function addMilestonesAndSeal(uint[] _etherAmounts, uint[] _tokenAmounts, uint[] _startTimes, uint[] _durations) public notSealed only(operator) {
    	require(_etherAmounts.length == _tokenAmounts.length);
	require(_startTimes.length == _durations.length);
	require(_durations.length == _etherAmounts.length);
	for (uint i = 0; i < _etherAmounts.length; i++) {
		totalEther = totalEther.add(_etherAmounts[i]);
		totalToken = totalToken.add(_tokenAmounts[i]);
		milestones.push(Milestone(_etherAmounts[i], _tokenAmounts[i], _startTimes[i],0,_durations[i],"",""));
	}
	sealTimestamp = now;
    }
    function addMilestone(uint _etherAmount, uint _tokenAmount, uint _startTime, uint _duration, string _description) public notSealed only(operator) returns(uint) {
        totalEther = totalEther.add(_etherAmount);
        totalToken = totalToken.add(_tokenAmount);
        return milestones.push(Milestone(_etherAmount, _tokenAmount, _startTime, 0, _duration, _description, ""));
    }
    function approveCycle(bool _approved) public {
        require(cycleApproved != true && roundFailedToStart != true);
        require(msg.sender == juryOperator);
        if (_approved == true) {
            cycleApproved = true;
        } else {
            roundFailedToStart = true;
        }
    }
    function startMilestone() public sealed only(operator) {
        require(cycleApproved);
        // UNCOMMENT 2 LINES BELOW FOR PROJECT FAILS START IF totalEther < raisedEther
        // if (currentMilestone == 0 && totalEther < raisedEther) { roundFailedToStart = true; }
        // require(!roundFailedToStart);
        if (currentMilestone != 0 ) {
            require(milestones[currentMilestone-1].finishTime > 0);
            uint interval = now - milestones[currentMilestone-1].finishTime;
            require(interval > 3 days);
        }
        for (uint i=0; i < dealsList.length ; i++) {
            address investor = dealsList[i];
            if (deals[investor].disputing == false) {
                if (deals[investor].verdictForInvestor != true) {
                    ethForMilestone += etherPartition[investor][currentMilestone];
                    deals[investor].etherUsed += etherPartition[investor][currentMilestone];
                    if (tokenReleaseAtStart == false) {
                        deals[investor].tokenAllowance += tokenPartition[investor][currentMilestone];
                    }
                }
            }
        }
        milestones[currentMilestone].startTime = now;
        currentMilestone +=1;
        ethForMilestone = payCommission();
    }
    function finishMilestone(string _result) public only(operator) {
        require(milestones[currentMilestone-1].finishTime == 0);
        // UNCOMMENT LINES BELOW FOR PRODUCTION!!!!
	    uint interval = now - milestones[currentMilestone-1].startTime;
        require(interval > 1 weeks);
        milestones[currentMilestone-1].finishTime = now;
        milestones[currentMilestone-1].result = _result;
        if (currentMilestone == milestones.length) {
            finishedTimeStamp = now;
        }
    }
    function editMilestone(uint _id, uint _etherAmount, uint _tokenAmount, uint _startTime, uint _duration, string _description) public notSealed only(operator) {
        assert(_id < milestones.length);
        totalEther = (totalEther - milestones[_id].etherAmount).add(_etherAmount); //previous addition
        totalToken = (totalToken - milestones[_id].tokenAmount).add(_tokenAmount);
        milestones[_id].etherAmount = _etherAmount;
        milestones[_id].tokenAmount = _tokenAmount;
        milestones[_id].startTime = _startTime;
        milestones[_id].duration = _duration;
        milestones[_id].description = _description;
    }

    function seal() public notSealed only(operator) {
        require(milestones.length > 0);
        // Uncomment bottom line to require balance when sealing contract
        // currently balance is required only when accepting offer
        //require(token.balanceOf(address(this)) >= promisedTokens);
        sealTimestamp = now;
    }
    // -------------------------------------------------------------------------
    // ONLY(ICO) ---------------------------------------------------------------
    // when operator accepts offer in ICO contract, it calls this function to add deal
    function offerAccepted(address _investor, uint _tokenAmount) public payable only(icoAddress) {
	    require(sealTimestamp > 0);
        uint _etherAmount = msg.value;
        assignPartition(_investor, _etherAmount, _tokenAmount);
        if (!(deals[_investor].etherAmount > 0)) dealsList.push(_investor);
        if (tokenReleaseAtStart == true) {
            deals[_investor].tokenAllowance = _tokenAmount;
        }
        deals[_investor].etherAmount += _etherAmount;
        deals[_investor].tokenAmount += _tokenAmount;
    	// ADDS TO TOTALS
    	promisedTokens += _tokenAmount;
    	raisedEther += _etherAmount;
    }
    // -------------------------------------------------------------------------
    // ONLY(ARBITRATION) -------------------------------------------------------
    function disputeOpened(address _investor) public only(arbitrationAddress) {
        deals[_investor].disputing = true;
    }
    function verdictExecuted(address _investor, bool _verdictForInvestor,uint _milestoneDispute) public only(arbitrationAddress) {
        require(deals[_investor].disputing == true);
        if (_verdictForInvestor) {
            deals[_investor].verdictForInvestor = true;
        } else {
            deals[_investor].verdictForProject = true;
            for (uint i = _milestoneDispute; i < currentMilestone; i++) {
                postDisputeEth += etherPartition[_investor][i];
                deals[_investor].etherUsed += etherPartition[_investor][i];
            }
        }
        deals[_investor].disputing = false;
    }
    // -------------------------------------------------------------------------
    // INTERNAL ----------------------------------------------------------------
    function assignPartition(address _investor, uint _etherAmount, uint _tokenAmount) internal {
        uint milestoneEtherAmount; //How much Ether does investor send for a milestone
        uint milestoneTokenAmount; //How many Tokens does investor receive for a milestone
        uint milestoneEtherTarget; //How much TOTAL Ether a milestone needs
        uint milestoneTokenTarget; //How many TOTAL tokens a milestone releases
        uint totalEtherInvestment;
        uint totalTokenInvestment;
        for(uint i=currentMilestone; i<milestones.length; i++) {
            milestoneEtherTarget = milestones[i].etherAmount;
            milestoneTokenTarget = milestones[i].tokenAmount;
            milestoneEtherAmount = _etherAmount.mul(milestoneEtherTarget).div(totalEther);
            milestoneTokenAmount = _tokenAmount.mul(milestoneTokenTarget).div(totalToken);
            totalEtherInvestment = totalEtherInvestment.add(milestoneEtherAmount); //used to prevent rounding errors
            totalTokenInvestment = totalTokenInvestment.add(milestoneTokenAmount); //used to prevent rounding errors
            if (deals[_investor].etherAmount > 0) {
                etherPartition[_investor][i] += milestoneEtherAmount;
                tokenPartition[_investor][i] += milestoneTokenAmount;
            } else {
                etherPartition[_investor].push(milestoneEtherAmount);
                tokenPartition[_investor].push(milestoneTokenAmount);
            }

        }
        /* roundingErrors += _etherAmount - totalEtherInvestment; */
        etherPartition[_investor][currentMilestone] += _etherAmount - totalEtherInvestment; //rounding error is added to the first milestone
        tokenPartition[_investor][currentMilestone] += _tokenAmount - totalTokenInvestment; //rounding error is added to the first milestone
    }
    function payCommission() internal returns(uint) {
        if (commissionEth.length >= currentMilestone) {
            uint ethCommission = raisedEther.mul(commissionEth[currentMilestone-1]).div(100);
            uint jotCommission = raisedEther.mul(commissionJot[currentMilestone-1]).div(100);
            etherAllowance += ethCommission;
            jotAllowance += jotCommission;
            return ethForMilestone.sub(ethCommission).sub(jotCommission);
        } else {
            return ethForMilestone;
        }
    }
    // -------------------------------------------------------------------------
    // HELPERS -----------------------------------------------------------------
    function milestonesLength() public view returns(uint) {
        return milestones.length;
    }
    function investorExists(address _investor) public view returns(bool) {
        if (deals[_investor].etherAmount > 0) return true;
        else return false;
    }
    function failSafe() public {
        if (msg.sender == operator) {
            saveMe = true;
        }
        if (msg.sender == juryOperator) {
            require(saveMe == true);
            require(juryOperator.send(address(this).balance));
            uint allTheLockedTokens = token.balanceOf(this);
            require(token.transfer(juryOperator,allTheLockedTokens));
        }
    }
}


contract AgileArbitration is Owned {

    address public operator;

    uint public quorum = 3;

    struct Dispute {
        address icoRoundAddress;
        address investorAddress;
        bool pending;
        uint timestamp;
        uint milestone;
        string reason;
        uint votesForProject;
        uint votesForInvestor;
        // bool verdictForProject;
        // bool verdictForInvestor;
        mapping(address => bool) voters;
    }
    mapping(uint => Dispute) public disputes;

    uint public disputeLength;

    mapping(address => mapping(address => bool)) public arbiterPool;

    modifier only(address _allowed) {
        require(msg.sender == _allowed);
        _;
    }

    constructor() public {
        operator = msg.sender;
    }

    // OPERATOR
    function setArbiters(address _icoRoundAddress, address[] _arbiters) only(owner) public {
        for (uint i = 0; i < _arbiters.length ; i++) {
            arbiterPool[_icoRoundAddress][_arbiters[i]] = true;
        }
    }

    // ARBITER
    function vote(uint _disputeId, bool _voteForInvestor) public {
        require(disputes[_disputeId].pending == true);
        require(arbiterPool[disputes[_disputeId].icoRoundAddress][msg.sender] == true);
        require(disputes[_disputeId].voters[msg.sender] != true);
        if (_voteForInvestor == true) { disputes[_disputeId].votesForInvestor += 1; }
        else { disputes[_disputeId].votesForProject += 1; }
        if (disputes[_disputeId].votesForInvestor == quorum) {
            executeVerdict(_disputeId,true);
        }
        if (disputes[_disputeId].votesForProject == quorum) {
            executeVerdict(_disputeId,false);
        }
        disputes[_disputeId].voters[msg.sender] == true;
    }

    // INVESTOR
    function openDispute(address _icoRoundAddress, string _reason) public {
        AgileCycle cycle = AgileCycle(_icoRoundAddress);
        uint milestoneDispute = cycle.currentMilestone();
        require(milestoneDispute > 0);
        require(cycle.investorExists(msg.sender) == true);
        disputes[disputeLength].milestone = milestoneDispute;

        disputes[disputeLength].icoRoundAddress = _icoRoundAddress;
        disputes[disputeLength].investorAddress = msg.sender;
        disputes[disputeLength].timestamp = now;
        disputes[disputeLength].reason = _reason;
        disputes[disputeLength].pending = true;

        cycle.disputeOpened(msg.sender);
        disputeLength +=1;
    }

    // INTERNAL
    function executeVerdict(uint _disputeId, bool _verdictForInvestor) internal {
        disputes[_disputeId].pending = false;
        uint milestoneDispute = disputes[_disputeId].milestone;
        AgileCycle cycle = AgileCycle(disputes[_disputeId].icoRoundAddress);
        cycle.verdictExecuted(disputes[_disputeId].investorAddress,_verdictForInvestor,milestoneDispute);
        //counter +=1;
    }

    function isPending(uint _disputedId) public view returns(bool) {
        return disputes[_disputedId].pending;
    }

}