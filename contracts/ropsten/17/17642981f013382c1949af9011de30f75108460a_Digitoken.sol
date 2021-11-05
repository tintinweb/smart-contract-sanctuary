/**
 *Submitted for verification at Etherscan.io on 2021-11-04
*/

// SPDX-License-Identifier: unlicensed
pragma solidity 0.8.9;
pragma experimental ABIEncoderV2;

contract SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;    }

    function safeAdd(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;}
            uint256 c = a * b;
            require(c / a == b, "SafeMath: multiplication overflow");
            return c;}

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;    }
}

abstract contract ERC20Interface {
    function totalSupply() virtual public view returns (uint);
    function balanceOf(address tokenOwner) virtual public view returns (uint balance);
    function allowance(address tokenOwner, address spender) virtual public view returns (uint remaining);
    function transfer(address to, uint tokens) virtual public returns (bool success);
    function approve(address spender, uint tokens) virtual public returns (bool success);
    function transferFrom(address from, address to, uint tokens) virtual public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract Digitoken is ERC20Interface, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    address contractAddress;
    uint public _totalSupply;
    uint public daoSupply;
    uint public devFund;
    address public digidao_address;
    address public devFund_address;
    uint public current_rate;
    uint public votingPeriod;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    //mapping(bool => mapping(address => Proposal)) voted;

    address public minter;
    uint public mintingAllowedAfter;
    uint public burnratechangeAllowedAfter;
    uint32 public minimumTimeBetweenMints;
    uint32 public minimumTimeBetweenBurnRateChanges;
    uint8 mintCap;
    uint8 burnCap;
    bool public mintLock;
    bool public rateLock;
    address _burnAddress;
    event Burn(address indexed burner, uint256 value);
    uint repMaturation =10; //change before launch

    struct Proposal {
        address proposer;
        string basic_description;
        uint yesVotes;
        uint noVotes;
        uint startVoteBlock;
        uint endVoteBlock;
        bool changeDigirate;
        bool fundIdea;
        bool mintCoin;
        address [] alreadyVoted;
        bool voteEnded;
        bool votePass;
        bool enacted;
    }

    struct Representative{
        address _rep;
        uint _startBlock;
        uint _unlockBlock;
    }

    mapping(address => Representative )  public registeredReps;
    Representative[] public representatives;
    mapping(address => Proposal )  public proposers;
    Proposal[] public proposals;
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");
    bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    constructor() {
        symbol = "DGT";
        name = "Digitrade";
        decimals = 18;
        _totalSupply = 1900000000000000000000000000;
        daoSupply = 50000000000000000000000000;
        devFund = 50000000000000000000000000;
        digidao_address = 0x138A3640a8EE21caa145014e3fAA22E359cF1B03; //Change to hardcoded dao controller address 
        devFund_address = 0x3f22EE8EB88d5120DcAB0E203F103f07800D07a3; //Change to hardcoded dev address
        current_rate = mul(div(1,90),100000000000000000); // 1.11% of every operator transaction to burn address
        mintCap = 10; // No more than 10% increase in number of coins
        burnCap = 10; // No more than 10% increase in burn rate
        minimumTimeBetweenMints = 1 days * 90; //90 days
        minimumTimeBetweenBurnRateChanges = 1 days * 60; //60 days 
        balances[msg.sender] = _totalSupply;
        transfer(digidao_address, daoSupply);
        transfer(devFund_address, devFund);
        mintLock = true; //Minting can only be called by enact, which is result of vote which requires rep to propose.
        rateLock = true; //Burn rate can only called by enact, which is result of vote which requires rep to propose.
        _burnAddress = 0x000000000000000000000000000000000000dEaD;
        contractAddress = address(this);
    }

    function totalSupply() public override view returns (uint) {
        return _totalSupply - balances[address(0)];
    }

    function balanceOf(address tokenOwner) public override view returns (uint balance) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint tokens) public override returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[receiver] = safeAdd(balances[receiver], tokens);
        emit Transfer(msg.sender, receiver, tokens);
        return true;
    }

    function approve(address spender, uint tokens) public override returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address sender, address receiver, uint tokens) public override returns (bool success) {
        balances[sender] = safeSub(balances[sender], tokens);
        allowed[sender][msg.sender] = safeSub(allowed[sender][msg.sender], tokens);
        balances[receiver] = safeAdd(balances[receiver], tokens);
        emit Transfer(sender, receiver, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender) public override view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    modifier onlyVested(uint _proposal) {
       require(balances[msg.sender] > mul(div(1,10000),_totalSupply), "Not enough Digitrade"); //>.0001% of totalSupply or 190000 
       require(block.number > registeredReps[msg.sender]._unlockBlock, "Not vested yet"); //current block> unlockblock  
       require(block.number < proposals[_proposal].endVoteBlock, "Voting has not ended yet"); //before voting ends
      _;
    }
    modifier onlyVestedReps(){
       require(balances[msg.sender] > mul(div(1,10000),_totalSupply), "Not enough digitrade");
       require(msg.sender == registeredReps[msg.sender]._rep,"You are not the rep" );
       require(block.number > registeredReps[msg.sender]._unlockBlock, "Not a vested registered rep yet");
      _;
    }
    modifier onlyProposalSponsor(uint _proposal){
       require(msg.sender == proposals[_proposal].proposer, "Only the proposal creator can call this function");
      _;
    }
    modifier onlyNonEnactedProposals(uint _proposal){
        require(block.number > proposals[_proposal].endVoteBlock, "Less than endVoteBlock");
        require(proposals[_proposal].enacted == false, "Proposal is already enacted");

        _;
    }

    function propose(string memory detailedDescription, bool _rateChange, bool _fundIdea, bool _mint ) public onlyVestedReps{
        address[] memory iVoted;
        proposals.push(Proposal({
                proposer: msg.sender,
                basic_description: detailedDescription,
                yesVotes: 0,
                noVotes: 0,
                startVoteBlock:block.number,
                endVoteBlock: safeAdd(block.number,mul(25,1)),//safeAdd(block.number,mul(5760,7));
                changeDigirate:_rateChange,
                fundIdea:_fundIdea,
                mintCoin:_mint,
                alreadyVoted:iVoted,
                voteEnded:false,
                votePass:false,
                enacted:false
            }));
    }
    
    function vote(uint proposal, bool yes, bool no) public onlyVested(proposal){
       for (uint i=0; i<proposals[proposal].alreadyVoted.length; i++) {
       require(proposals[proposal].alreadyVoted[i] != msg.sender, "Only one vote per address");}
       require(yes || no == true);
       require(yes || no == false);
       if(yes == true)proposals[proposal].yesVotes += 1;
       if(no  == true)proposals[proposal].noVotes -= 1;
       proposals[proposal].alreadyVoted.push(msg.sender);
    }

    function enact(uint _proposal, bool _rateChange, uint _rate, bool _fundIdea, address _shawdowySuperCoder, uint _fundAmount, bool _mint, uint96 _mintAmount) public onlyProposalSponsor(_proposal) onlyNonEnactedProposals(_proposal) returns (string memory _message){
        if(proposals[_proposal].yesVotes > proposals[_proposal].noVotes){
        proposals[_proposal].voteEnded = true;
        proposals[_proposal].votePass = true;
        if(_rateChange == true){
        changeBurnRate(_rate,_proposal);
        }
        if(_fundIdea == true){  emit Transfer(address(0), _shawdowySuperCoder, _fundAmount);}
        if(_mint == true) {
            mint(contractAddress ,_mintAmount);
        }
        _message = 'The proposal passes';
        return _message;
        }
        if(proposals[_proposal].yesVotes < proposals[_proposal].noVotes){
        proposals[_proposal].voteEnded = true;
        proposals[_proposal].votePass = false;
        delete proposals[_proposal];
        return 'The proposal fails';
        }
        
    }

    function changeBurnRate(uint _rate, uint _proposal) internal onlyProposalSponsor(_proposal) onlyNonEnactedProposals(_proposal) {
        require(_rate != current_rate);
        require(block.timestamp >= burnratechangeAllowedAfter, "Digi::burnchange: BurnRateChange not allowed yet");
        burnratechangeAllowedAfter = add(block.timestamp, minimumTimeBetweenBurnRateChanges);
        require(safeSub(_rate, current_rate) <= 1, "Digi::burnchange: exceeded burnchange cap");
        current_rate = _rate;
    }

    function fundIdea(uint _amount, address dev, uint front, uint back, uint timeLock) internal {
        //sponsor
    }

    function mint(address account, uint96 rawAmount) internal {
        require(block.timestamp >= mintingAllowedAfter, "Uni::mint: minting not allowed yet");
        require(account != address(0), "Uni::mint: cannot transfer to the zero address");
        mintingAllowedAfter = add(block.timestamp, minimumTimeBetweenMints);
        // mint the amount
        uint96 amount = rawAmount;
        require(amount <= div(mul(_totalSupply, mintCap), 100), "Uni::mint: exceeded mint cap");
        _totalSupply = add(_totalSupply, amount);

        // transfer the amount to the recipient
        balances[account] = add(balances[account], amount);
        emit Transfer(address(0), account, amount);   

    }
        
    function getBlockNumber() public view returns(uint blockNumber){
        return block.number;
    }   

    function registerRep(address _rep) public {
      require(msg.sender ==_rep);
      require(balances[msg.sender] > 10000, "Balance under 10K digitrade");
      uint _unlockBlock = block.number + repMaturation;  //unlocks after 30 days or so
      registeredReps[_rep] = Representative(_rep,block.number, _unlockBlock);
    }
    
    function checkRegistration() public view returns(uint _unlockBlock, string memory){
      if(registeredReps[msg.sender]._unlockBlock < block.number){
           return (1,'You are registered');
      }else{
          return ((registeredReps[msg.sender]._unlockBlock - registeredReps[msg.sender]._startBlock), 'more blocks until registration');
       }
      }
      
}