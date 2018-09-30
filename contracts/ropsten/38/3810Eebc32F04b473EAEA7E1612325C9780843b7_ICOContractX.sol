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

// File: contracts/ArchXArch2.sol

//import "./Pullable.sol";
// DEPLOYED BY JURY.ONLINE, ONCE PER ICO
contract ICOContractX {
    // STORAGE -------------------------------------
    address public operator;
    address public projectWallet;
    Token public token;
    address public juryOnlineWallet;
    address public arbitrationAddress;

    uint public currentRound;
    struct Round {
        bool exists;
        bool approved;
        address icoRoundAddress;
    }
    mapping(uint => Round) public rounds;
    // ---------------------------------------------
    constructor(address _operator, address _projectWallet, address _tokenAddress, address _arbitrationAddress, address _juryOnlineWallet) public {
        operator = _operator;
        projectWallet = _projectWallet;
        token = Token(_tokenAddress);
        arbitrationAddress = _arbitrationAddress;
        juryOnlineWallet = _juryOnlineWallet;
    }
    //
    function addRound() public {
        rounds[currentRound].exists = true;
        rounds[currentRound].icoRoundAddress = msg.sender;
    }
    function approveRound(address _icoRoundAddress) public {
        require(msg.sender == operator);
        require(rounds[currentRound].icoRoundAddress == _icoRoundAddress);
        currentRound +=1;
    }
}
// DEPLOYED BY JURY.ONLINE, ONCE PER ROUND
contract ICORoundX {
    using SafeMath for uint;
    // STORAGE -------------------------------------
    address public juryOperator;
    address public operator;
    address public icoAddress;
    address public juryOnlineWallet;
    address public projectWallet;
    address public arbitrationAddress;
    address public swapper;

    bool public saveMe;

    Token public token;
    uint public sealTimestamp;
    struct Milestone {
        uint etherAmount; //how many Ether is needed for this milestone
        uint tokenAmount; //how many tokens releases this milestone
        uint startTime; //real time when milestone has started, set upon start
        uint finishTime; //real time when milestone has finished, set upon finish
        uint duration; //assumed duration for milestone implementation, set upon milestone creation
        string description;
        string result;
    }
    Milestone[] public milestones;
    uint public currentMilestone;
    bool public roundFailedToStart;

    uint public ethForMilestone;
    uint public ethAfterCommission;

    struct Deal {
        uint etherAmount;
        uint tokenAmount;
        bool accepted;
        bool disputing;
        uint tokenAllowance;
        uint etherUsed;
        bool verdictForProject;
        bool verdictForInvestor;
    }
    mapping(address => Deal) public deals;
    address[] public dealsList;

    uint[] public commissionEth;
    uint[] public commissionJot;

    uint public totalEther;
    uint public totalToken;

    uint public promisedTokens;
    uint public raisedEther;

    uint public etherAllowance;
    uint public jotAllowance;

    uint public defaultPrice;
    bool public tokenReleaseAtStart = true;

    mapping(address => uint[]) public etherPartition;
    mapping(address => uint[]) public tokenPartition;

    struct FundingRound {
        uint startTime;
        uint endTime;
        uint price;
        bool hasWhitelist;
    }
    FundingRound[] public roundPrices;
    mapping(uint => mapping(address => bool)) public whitelist;
    // ---------------------------------------------
    //
    modifier onlyOperator() {
        require(msg.sender == operator || msg.sender == juryOperator);
        _;
    }
    modifier onlyAdmin() {
        require(msg.sender == operator || msg.sender == juryOperator);
        _;
    }
    /* modifier only(address _sender) {
        require(msg.sender == _sender);
        _;
    } */
    modifier sealed() {
        require(sealTimestamp != 0);
        /* require(now > sealTimestamp); */
        _;
    }
    modifier notSealed() {
        require(sealTimestamp == 0);
        /* require(now <= sealTimestamp); */
        _;
    }
    // ---------------------------------------------
    //
    constructor( address _icoAddress, address _operator, uint _defaultPrice, address _swapper, uint[] _commissionEth, uint[] _commissionJot) public {
        require(_commissionEth.length == _commissionJot.length);
        juryOperator = msg.sender;
        icoAddress = _icoAddress;
        operator = _operator;
        defaultPrice = _defaultPrice;
        swapper = _swapper;
        commissionEth = _commissionEth;
        commissionJot = _commissionJot;
    }
    function dealsGetter(address _investor, uint _param) public constant returns(uint) {
        if (_param == 0) return deals[_investor].etherAmount;
        if (_param == 1) return deals[_investor].tokenAllowance;
        if (_param == 2) return deals[_investor].tokenAllowance;
        if (_param == 3) return deals[_investor].etherUsed;
    }
    function setSwapper(address _swapper) public {
        require(msg.sender == juryOperator);
        swapper = _swapper;
    }
    function activate() public notSealed {
        ICOContractX icoContract = ICOContractX(icoAddress);
        require(icoContract.operator() == operator);
        juryOnlineWallet = icoContract.juryOnlineWallet();
        projectWallet = icoContract.projectWallet();
        arbitrationAddress = icoContract.arbitrationAddress();
        token = icoContract.token();
        icoContract.addRound();
        //
    }
    // METHODS -------------------------------------
    // PUBLIC
    function withdrawEther() public {
        if (roundFailedToStart == true) {
            require(msg.sender.send(deals[msg.sender].etherAmount));
        }
        if (msg.sender == operator) {
            //uint ethAfterCommission = payCommission();
            require(projectWallet.send(ethAfterCommission));
            ethForMilestone = 0;
            ethAfterCommission = 0;
        }
        if (msg.sender == juryOnlineWallet) {
            //uint totalCommission = etherAllowance + jotAllowance;
            require(juryOnlineWallet.send(etherAllowance));
            /* require(swapper.send(jotAllowance)); */
            //require(swapper.call(bytes4(keccak256("setA(uint256)")),_val));
            //contract_address.call.value(1 ether).gas(10)(abi.encodeWithSignature("register(string)", "MyName"));
            /* swapper.call.value(jotAllowance)(bytes4(keccak256("swapMe()"))); */
            /* contract_address.call.value(1 ether).gas(10)(abi.encodeWithSignature("register(string)", "MyName")); */
            swapper.call.value(jotAllowance)(abi.encodeWithSignature("swapMe()"));
            etherAllowance = 0;
            jotAllowance = 0;
        }
        if (deals[msg.sender].verdictForInvestor == true) {
            require(msg.sender.send(deals[msg.sender].etherAmount - deals[msg.sender].etherUsed));
        }
    }
    /* function payCommission() internal returns(uint) {
        if (commissionEth.length >= currentMilestone) {
            uint ethCommission = totalEther.mul(commissionEth[currentMilestone-1]).div(100);
            uint jotCommission = totalEther.mul(commissionJot[currentMilestone-1]).div(100);
            //uint ethCommission = ethForMilestone.mul(commissionEth[currentMilestone-1]).div(100);
            //uint jotCommission = ethForMilestone.mul(commissionJot[currentMilestone-1]).div(100);
            etherAllowance += ethCommission;
            jotAllowance += jotCommission;
            return ethForMilestone.sub(ethCommission).sub(jotCommission);
        } else {
            return ethForMilestone;
        }
    } */
    function withdrawToken() public {
        require(token.transfer(msg.sender,deals[msg.sender].tokenAllowance));
        deals[msg.sender].tokenAllowance = 0;
    }
    // INVESTOR
    function addRoundPrice(uint _startTime,uint _endTime, uint _price, address[] _whitelist) public onlyAdmin {
        if (_whitelist.length == 0) {
            roundPrices.push(FundingRound(_startTime, _endTime,_price,false));
        } else {
            for (uint i=0 ; i < _whitelist.length ; i++ ) {
                whitelist[roundPrices.length][_whitelist[i]] = true;
            }
            roundPrices.push(FundingRound(_startTime, _endTime,_price,true));
        }
    }
    function () public payable {
        require(msg.value > 0);
        deals[msg.sender].etherAmount = msg.value;
        //uint priceForRound;
        for (uint i=0 ; i < roundPrices.length ; i++) {
            if (roundPrices[i].endTime > now && roundPrices[i].startTime < now) {
                defaultPrice = roundPrices[i].price;
                if (roundPrices[i].hasWhitelist == true) {
                    require(whitelist[i][msg.sender] == true);
                }
            }
        }
        deals[msg.sender].tokenAmount = msg.value.mul(defaultPrice);
    }
    function withdrawOffer() public {
        require(deals[msg.sender].accepted == false);
        require(msg.sender.send(deals[msg.sender].etherAmount));
        delete deals[msg.sender];
    }
    // ARBITRATION
    function disputeOpened(address _investor) public {
        require(msg.sender == arbitrationAddress);
        require(deals[_investor].accepted == true);
        deals[_investor].disputing = true;
    }
    function verdictExecuted(address _investor, bool _verdictForInvestor) public {
        require(msg.sender == arbitrationAddress);
        require(deals[_investor].disputing == true);
        if (_verdictForInvestor) {
            deals[_investor].verdictForInvestor = true;
        } else {
            deals[_investor].verdictForProject = true;
        }
        deals[_investor].disputing = false;
    }
    // OPERATOR
    function addMilestone(uint _etherAmount, uint _tokenAmount, uint _startTime, uint _duration, string _description) public notSealed onlyOperator returns(uint) {
        totalEther = totalEther.add(_etherAmount);
        totalToken = totalToken.add(_tokenAmount);
        return milestones.push(Milestone(_etherAmount, _tokenAmount, _startTime, 0, _duration, _description, ""));
    }
    function seal() public notSealed onlyOperator {
        /* uint[] memory etherAmounts;
        for (uint i=0;i<commissionEth.length;i++) {
            //etherAmounts.push(milestones[i].etherAmount);
            etherAmounts[i] = milestones[i].etherAmount;
        }
        require(commissionCheck(commissionEth, commissionJot, etherAmounts, totalEther) == true); */
        require(commissionCheck() == true);
        require(milestones.length > 0);
        //require(token.balanceOf(address(this)) >= totalToken);
        sealTimestamp = now;
    }
    function acceptOffer(address _investor) public sealed onlyOperator {
        require(deals[_investor].etherAmount > 0);
        deals[_investor].accepted = true;
        uint _tokenAmount = deals[_investor].tokenAmount;
        require(token.balanceOf(address(this)) >= promisedTokens + _tokenAmount);
        etherAllowance += deals[_investor].etherAmount.mul(4).div(100);
        assignPartition(_investor, deals[_investor].etherAmount, _tokenAmount);
        dealsList.push(_investor);
        if (tokenReleaseAtStart == true) {
            deals[_investor].tokenAllowance = _tokenAmount;
        }
    }
    function startMilestone() public sealed onlyOperator {
        // UNCOMMENT 2 LINES BELOW FOR PROJECT FAILS START IF totalEther < raisedEther
        // if (currentMilestone == 0 && totalEther < raisedEther) { roundFailedToStart = true; }
        // require(!roundFailedToStart);
        if (currentMilestone != 0 ) {require(milestones[currentMilestone-1].finishTime > 0);}
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
        currentMilestone +=1;
        //ethAfterCommission = payCommission();
    }
    function finishMilestone(string _result) public onlyOperator {
        milestones[currentMilestone-1].finishTime = now;
        milestones[currentMilestone-1].result = _result;
    }
    // -------------------------------------------------------------------------
    //
    // HELPERS -----------------------------------------------------------------
    function failSafe() public onlyAdmin {
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
            etherPartition[_investor].push(milestoneEtherAmount);
            tokenPartition[_investor].push(milestoneTokenAmount);
        }
        etherPartition[_investor][currentMilestone] += _etherAmount - totalEtherInvestment; //rounding error is added to the first milestone
        tokenPartition[_investor][currentMilestone] += _tokenAmount - totalTokenInvestment; //rounding error is added to the first milestone
    }
    function isDisputing(address _investor) public view returns(bool) {
        return deals[_investor].disputing;
    }
    function commissionCheck() internal view returns(bool) {
        for ( uint i=0 ; i < commissionEth.length ; i++ ) {
            uint percentToBeReleased = milestones[i].etherAmount.mul(100).div(totalEther);
            uint percentToPay = commissionEth[i] + commissionJot[i];
            require(percentToPay <= percentToBeReleased);
        }
        return true;
    }
}

contract ArbitrationX {
    address public operator;
    uint public quorum = 3;
    //uint public counter;
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

    constructor() public {
        operator = msg.sender;
    }
    // OPERATOR
    function setArbiters(address _icoRoundAddress, address[] _arbiters) public {
        for (uint i = 0; i < _arbiters.length ; i++) {
            arbiterPool[_icoRoundAddress][_arbiters[i]] = true;
        }
    }
    // ARBITER
    function vote(uint _disputeId, bool _voteForInvestor) public {
        require(disputes[_disputeId].pending == true);
        /* require(arbiterPool[disputes[_disputeId].icoRoundAddress][msg.sender] == true); */
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
        disputes[disputeLength].icoRoundAddress = _icoRoundAddress;
        disputes[disputeLength].investorAddress = msg.sender;
        disputes[disputeLength].timestamp = now;
        disputes[disputeLength].reason = _reason;
        disputes[disputeLength].pending = true;
        ICORoundX icoRound = ICORoundX(_icoRoundAddress);
        disputes[disputeLength].milestone = icoRound.currentMilestone();
        icoRound.disputeOpened(msg.sender);
        disputeLength +=1;
    }
    // INTERNAL
    function executeVerdict(uint _disputeId, bool _verdictForInvestor) internal {
        disputes[_disputeId].pending = false;
        ICORoundX icoRound = ICORoundX(disputes[_disputeId].icoRoundAddress);
        icoRound.verdictExecuted(disputes[_disputeId].investorAddress,_verdictForInvestor);
        //counter +=1;
    }
    function isPending(uint _disputedId) public view returns(bool) {
        return disputes[_disputedId].pending;
    }
}

contract Swapper {
    // for an ethToJot of 2,443.0336457941, Aug 21, 2018
    Token public token;
    uint public ethToJot = 2443;
    address public myBal;
    address public owner;
    uint public myJot;
    uint public ujot;
    constructor(address _jotAddress) public {
        owner = msg.sender;
        token = Token(_jotAddress);
        myBal = address(this);
        /* myJot = token.balanceOf(myBal); */
    }
    /* function() payable public { */
        /* myBal = address(this); */
        /* myJot = token.balanceOf(myBal); */
        /* require(token.balanceOf(myBal) >= jot); */
        /* require(token.transfer(msg.sender,jot)); */

    function swapMe() public payable {
        uint jot = msg.value * ethToJot;
        myJot = token.balanceOf(myBal);
        ujot = jot;
        require(token.transfer(owner,jot));
    }
}

/*
// LIBRARIES -------------------------------------------------------------------
library ICOHelper {
    using SafeMath for uint;
    function commissionCheck(uint[] _commissionEth, uint[] _commissionJot, uint[] _etherAmounts, uint _totalEther) internal view returns(bool) {
        require(_commissionEth.length <= _etherAmounts.length);
        for (uint i=0;i<_commissionEth.length;i++) {
            uint percentToBeReleased = _etherAmounts[i].mul(100).div(_totalEther);
            uint percentToPay = _commissionEth[i] + _commissionJot[i];
            require(percentToPay <= percentToBeReleased);
        }
        return true;
    }
}



contract PriceTicker is Owned {

    uint public ethToJot = 2443;

    //event NewPrice(uint _price);

    function updatePrice(uint _newEthJot) only(owner) {
    //some error checks
        //require(newEthJot !=0);
        ethJOT = _newEthJot;
        //emit NewPrice(_newEthJot);
    }
}

// -----------------------------------------------------------------------------
// DEPLOYED BY JURY.ONLINE, ONLY ONCE
contract ArbitrationAX {
    //
}

contract CommissionContractAX {
    //
}
*/