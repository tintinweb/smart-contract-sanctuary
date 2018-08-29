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

// File: contracts/Pullable.sol

/**
 * @title Pullable
 * @dev Base contract supporting async send for pull payments. Inherit from this
 * contract and use asyncSend instead of send. Originally taken from https://github.com/OpenZeppelin/zeppelin-solidity
 * with few changes.
 */
contract Pullable {
  using SafeMath for uint256;

  mapping(address => uint256) public etherPayments;

  /**
  * @dev withdraw accumulated balance, called by payee.
  */
  function withdrawEtherPayment() public {
    uint payment = etherPayments[msg.sender];
    require(payment != 0);
    require(address(this).balance >= payment);
    etherPayments[msg.sender] = 0;
    assert(msg.sender.send(payment));
  }

  /**
  * @dev Called by the payer to store the sent amount as credit to be pulled.
  * @param _destination The destination address of the funds.
  * @param _amount The amount to transfer.
  */
  function asyncSend(address _destination, uint256 _amount) internal {
    etherPayments[_destination] = etherPayments[_destination].add(_amount);
  }
}

//Asynchronous send is used both for sending the Ether and tokens.
contract TokenPullable {
  using SafeMath for uint256;
  Token public token;

  mapping(address => uint256) public tokenPayments;

  constructor(address _token) public {
      token = Token(_token);
  }

  /**
  * @dev withdraw accumulated balance, called by payee.
  */
  function withdrawTokenPayment() public {
    uint tokenPayment = tokenPayments[msg.sender];
    require(tokenPayment != 0);
    require(token.balanceOf(address(this)) >= tokenPayment);
    tokenPayments[msg.sender] = 0;
    assert(token.transfer(msg.sender, tokenPayment));
  }

  function asyncTokenSend(address _destination, uint _amount) internal {
    tokenPayments[_destination] = tokenPayments[_destination].add(_amount);
  }
}

// File: contracts/ClassicSet.sol

/* import "./JuryOnlineInvestContract.sol"; */

contract ICOContract {
    using SafeMath for uint;

    address public projectWallet; //beneficiary wallet
    address public operator; //address of the ICO operator — the one who adds milestones and InvestContracts

    address public juryOnlineWallet = 0x3e134C5dAf56e0e28bd04beD46969Bd516932f02; //address that receives commission
    uint public commission = 1; //in percents

    //uint constant waitPeriod = 7 days; //wait period after milestone finish and until the next one can be started

    mapping(address => bool) public pendingInvestContracts; //pending = not yet paid

    address[] public investContracts = [0x0]; // accepted InvestContracts
    mapping(address => uint) public investContractsIndices;

    uint public totalEther; // How much Ether is collected = sum of all milestones&#39; etherAmount
    uint public totalToken; // how many tokens are distributed = sum of all milestones&#39; tokenAmount

    uint public tokenLeft;
    uint public etherLeft;

    Token public token;

    ///ICO caps
    uint public minimumCap; // set in constructor
    uint public maximumCap;  // set in constructor

    uint public minimalInvestment;

    //Structure for milestone
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
    uint public currentMilestone; //0 indicates that no milestone has started, so the real ones start from 1
    uint public sealTimestamp; //Until when it&#39;s possible to add new and change existing milestones

    modifier only(address _sender) {
        require(msg.sender == _sender);
        _;
    }

    modifier notSealed() {
        require(now <= sealTimestamp);
        _;
    }

    modifier sealed() {
        require(now > sealTimestamp);
        _;
    }

    modifier started() {
        require(currentMilestone > 0);
        _;
    }

    modifier notStarted() {
        require(currentMilestone == 0);
        _;
    }

    /// @dev Create an ICOContract.
    /// @param _tokenAddress Address of project token contract
    /// @param _projectWallet Address of project developers wallet
    /// @param _sealTimestamp Until this timestamp it&#39;s possible to alter milestones
    /// @param _minimumCap Wei value of minimum cap for responsible ICO
    /// @param _maximumCap Wei value of maximum cap for responsible ICO
    /// @param _minimalInvestment minimal possible investment
    /// @param _operator ICO operator, the person who adds, starts, and finishes milestones; creates InvestContracts
    constructor(address _tokenAddress, address _projectWallet, uint _sealTimestamp, uint _minimumCap,
                         uint _maximumCap, uint _minimalInvestment, address _operator) public {
        operator = _operator;
        token = Token(_tokenAddress);
        projectWallet = _projectWallet;
        sealTimestamp = _sealTimestamp;
        minimumCap = _minimumCap;
        maximumCap = _maximumCap;
        minimalInvestment = _minimalInvestment;
    }

    /// @dev Adds a milestone.
    /// @param _etherAmount amount of Ether needed for the added milestone
    /// @param _tokenAmount amount of tokens which will be released for added milestone
    /// @param _startTime field for start timestamp of added milestone
    /// @param _duration assumed duration of the milestone
    /// @param _description description of added milestone
    function addMilestone(uint _etherAmount, uint _tokenAmount, uint _startTime, uint _duration, string _description) public notSealed only(operator) returns(uint) {
        totalEther = totalEther.add(_etherAmount);
        totalToken = totalToken.add(_tokenAmount);
        return milestones.push(Milestone(_etherAmount, _tokenAmount, _startTime, 0, _duration, _description, ""));
    }

    /// @dev Edits milestone by given id and new parameters.
    /// @param _id id of editing milestone
    /// @param _etherAmount amount of Ether needed for the milestone
    /// @param _tokenAmount amount of tokens which will be released for the milestone
    /// @param _startTime start timestamp of the milestone
    /// @param _duration assumed duration of the milestone
    /// @param _description description of the milestone
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

    //TODO: add check if ICOContract has tokens
    ///@dev Seals milestone making them no longer changeable. Works by setting changeable timestamp to the current one, //so in future it would be no longer callable.
    function seal() public notSealed only(operator) {
        require(milestones.length > 1); //Has to have at least 2 milestones
        //require(token.balanceOf(this) >= totalToken;
        sealTimestamp = now;
        etherLeft = totalEther;
        tokenLeft = totalToken;
    }

    ///in fact modifier started is useless, as it will throw if currentMilestone <1, however it remains here for readability
    ///@dev Finishes milestone
    ///@param _result milestone result
    function finishMilestone(string _result) public started only(operator) {
        require(milestones[currentMilestone-1].finishTime == 0); //can be called only once
        milestones[currentMilestone-1].finishTime = now;
        milestones[currentMilestone-1].result = _result;
    }

    ///@dev Starts next milestone
    function startNextMilestone() public sealed only(operator) {
        require(currentMilestone != milestones.length); //checking if final milestone. There should be more than 1 milestone in the project
        if (currentMilestone != 0) {
            require(milestones[currentMilestone-1].finishTime != 0);//previous milestone has to be finished
        }
        milestones[currentMilestone].startTime = now; //setting the of the next milestone
        for(uint i=1; i < investContracts.length; i++) {
                InvestContract investContract =  InvestContract(investContracts[i]);
                investContract.milestoneStarted(currentMilestone);
        }
        currentMilestone +=1;
    }

    //InvestContract part
    /// @dev Adds InvestContract at given addres to the pending (waiting for payment) InvestContracts
    /// @param _investContractAddress address of InvestContract
    function addInvestContract(address _investContractAddress) public sealed notStarted only(operator) {
        InvestContract investContract = InvestContract(_investContractAddress);
        require(investContract.icoContract() == this);
        require(investContract.amountToPay() >= minimalInvestment);
        //require(milestones[0].startTime - now >= 5 days);
        //require(maximumCap >= _etherAmount + investorEther);
        //require(token.balanceOf(this) >= _tokenAmount + investorTokens);
        pendingInvestContracts[_investContractAddress] = true;
    }

    /// @dev This function is called by InvestContract when it receives Ether. It moves this InvestContract from pending to the real ones.
    function investContractDeposited() public notStarted {
        require(pendingInvestContracts[msg.sender]);
        delete pendingInvestContracts[msg.sender];
        investContracts.push(msg.sender);
        investContractsIndices[msg.sender]=investContracts.length-1;

        InvestContract investContract = InvestContract(msg.sender);
        uint investmentToken = investContract.tokenAmount();
        uint investmentEther = investContract.etherAmount();

        etherLeft = etherLeft.sub(investmentEther);
        tokenLeft = tokenLeft.sub(investmentToken);
        assert(token.transfer(msg.sender, investmentToken));
    }

    /// @dev If investor has won the dispute, then InvestContract is deleted by calling this function
    function deleteInvestContract() public started {
        uint index = investContractsIndices[msg.sender];
        require(index > 0);
        uint len = investContracts.length;
        investContracts[index] = investContracts[len-1];
        investContracts.length = len-1;
        delete investContractsIndices[msg.sender];
    }

    /// @dev Sends all unused tokens to projectWallet
    function returnTokens() public only(operator) {
        uint balance = token.balanceOf(this);
        token.transfer(projectWallet, balance);
    }

    ///@dev Returns number of the current milestone. Starts from 1. 0 indicates that project implementation has not started yet.
    function getCurrentMilestone() public view returns(uint) {
        return currentMilestone;
    }

    /// @dev Getter function for length. For testing purposes.
    function milestonesLength() public view returns(uint) {
        return milestones.length;
    }

}


contract InvestContract is TokenPullable, Pullable {
    using SafeMath for uint;

    address public projectWallet; //beneficiary
    address public investor;

    uint public arbiterAcceptCount;
    uint public quorum;

    ICOContract public icoContract;

    uint[] public etherPartition; //weis
    uint[] public tokenPartition; //tokens

    //Each arbiter has parameter delay which equals time interval in seconds betwwen dispute open and when the arbiter can vote
    struct ArbiterInfo {
        uint index;
        bool accepted;
        uint voteDelay;
    }

    mapping(address => ArbiterInfo) public arbiters; //arbiterAddress => ArbiterInfo{acceptance, voteDelay}
    address[] public arbiterList = [0x0]; //it&#39;s needed to show complete arbiter list

    //this structure can be optimized
    struct Dispute {
        uint timestamp;
        string reason;
        address[5] voters;
        mapping(address => address) votes;
        uint votesProject;
        uint votesInvestor;
    }

    mapping(uint => Dispute) public disputes;

    uint public etherAmount; //How much Ether investor wants to invest
    uint public tokenAmount; //How many tokens investor wants to receive

    bool public disputing = false;
    uint public amountToPay; //investAmount + commission

    modifier only(address _sender) {
        require(msg.sender == _sender);
        _;
    }

    modifier onlyArbiter() {
        require(arbiters[msg.sender].voteDelay > 0);
        _;
    }

    modifier started() {
        require(getCurrentMilestone() > 0);
        _;
    }

    modifier notStarted() {
        require(getCurrentMilestone() == 0);
        _;
    }

    ///@dev Creates an InvestContract
    constructor(address _ICOContractAddress, address _investor,  uint _etherAmount, uint _tokenAmount)
    TokenPullable(ICOContract(_ICOContractAddress).token()) //wierd initialization: TokenPullable needs token address and must be set before InvestContract constructor takes place
    public {
        icoContract = ICOContract(_ICOContractAddress);
        amountToPay = _etherAmount;
		etherAmount = _etherAmount*(100-icoContract.commission())/100; //Ether commission handling
        tokenAmount = _tokenAmount;
        projectWallet = icoContract.projectWallet();
        investor = _investor;
        quorum = 2;

        addAcceptedArbiter(0xB69945E2cB5f740bAa678b9A9c5609018314d950); //Valery
        addAcceptedArbiter(0x82ba96680D2b790455A7Eee8B440F3205B1cDf1a); //Valery
        addAcceptedArbiter(0x4C67EB86d70354731f11981aeE91d969e3823c39); //Alex

		uint milestoneEtherAmount; //How much Ether does investor send for a milestone
		uint milestoneTokenAmount; //How many Tokens does investor receive for a milestone

		uint milestoneEtherTarget; //How much TOTAL Ether a milestone needs
		uint milestoneTokenTarget; //How many TOTAL tokens a milestone releases

		uint totalEtherInvestment;
		uint totalTokenInvestment;
		for(uint i=0; i<icoContract.milestonesLength(); i++) {
			(milestoneEtherTarget, milestoneTokenTarget, , , , , ) = icoContract.milestones(i);
			milestoneEtherAmount = etherAmount.mul(milestoneEtherTarget).div(icoContract.totalEther());
			milestoneTokenAmount = tokenAmount.mul(milestoneTokenTarget).div(icoContract.totalToken());
			totalEtherInvestment = totalEtherInvestment.add(milestoneEtherAmount); //used to prevent rounding errors
			totalTokenInvestment = totalTokenInvestment.add(milestoneTokenAmount); //used to prevent rounding errors
			etherPartition.push(milestoneEtherAmount);
			tokenPartition.push(milestoneTokenAmount);
		}
		etherPartition[0] += etherAmount - totalEtherInvestment; //rounding error is added to the first milestone
		tokenPartition[0] += tokenAmount - totalTokenInvestment; //rounding error is added to the first milestone
    }

    function() payable public notStarted only(investor) {
        require(arbiterAcceptCount >= quorum);
        require(msg.value == amountToPay);
        icoContract.juryOnlineWallet().transfer(amountToPay-etherAmount);
        icoContract.investContractDeposited();
    }

    //Adding an arbiter which has already accepted his participation in ICO.
    function addAcceptedArbiter(address _arbiter) internal notStarted {
        arbiterAcceptCount +=1;
        uint index = arbiterList.push(_arbiter);
        arbiters[_arbiter] = ArbiterInfo(index, true, 1);
    }

    function addArbiter(address _arbiter, uint _delay) public notStarted only(investor) {
        require(_delay > 0);
        uint index = arbiterList.push(_arbiter);
        arbiters[_arbiter] = ArbiterInfo(index, false, _delay);
    }

    function acceptArbiter() public onlyArbiter {
        require(!arbiters[msg.sender].accepted);
        arbiters[msg.sender].accepted = true;
        arbiterAcceptCount += 1;
    }

    function vote(address _voteAddress) public onlyArbiter {
        require(disputing);
        require(_voteAddress == investor || _voteAddress == projectWallet);

        uint milestone = getCurrentMilestone();
        require(milestone > 0);
        Dispute storage dispute = disputes[milestone-1];
        require(dispute.votes[msg.sender] == 0);
        require(now - dispute.timestamp >= arbiters[msg.sender].voteDelay); //checking if enough time has passed since dispute had been opened
        dispute.votes[msg.sender] = _voteAddress; //sets the vote
        dispute.voters[dispute.votesProject+dispute.votesInvestor] = msg.sender; // this line means adding arbiter to dispute.voters
        if (_voteAddress == projectWallet) {
            dispute.votesProject += 1;
            if (dispute.votesProject >= quorum) {
                executeVerdict(true);
            }
        } else {
            dispute.votesInvestor += 1;
            if (dispute.votesInvestor >= quorum) {
                executeVerdict(false);
            }
        }
    }

    function executeVerdict(bool _projectWon) internal {
        if (!_projectWon) {
            asyncSend(investor, address(this).balance);
            token.transfer(icoContract, token.balanceOf(this)); // send all tokens back
            //asyncTokenSend(token.transfer(icoContract, token.balanceOf(this))); // send all tokens back
            icoContract.deleteInvestContract();
        } else {//if project won then implementation proceeds
            disputing = false;
        }
    }

    function openDispute(string _reason) public started only(investor) {
        require(!disputing);
        uint milestone = getCurrentMilestone();
        require(milestone > 0);
        disputing = true;
        disputes[milestone-1].timestamp = now;
        disputes[milestone-1].reason = _reason;
    }

    ///@dev When new milestone is started this functions is called
	function milestoneStarted(uint _milestone) public only(icoContract) {
        require(!disputing);
		uint etherToSend = etherPartition[_milestone];
		uint tokensToSend = tokenPartition[_milestone];

		asyncSend(projectWallet, etherToSend);
		asyncTokenSend(investor, tokensToSend);
    }

    function getCurrentMilestone() public view returns(uint) {
        return icoContract.currentMilestone();
    }

}