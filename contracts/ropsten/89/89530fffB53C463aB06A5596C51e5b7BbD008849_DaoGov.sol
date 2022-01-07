/**
 *Submitted for verification at Etherscan.io on 2022-01-07
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
//DAO GOV version 1.0.0

//NOT READY FOR PRODUCTION 12/30/2021
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

interface InterfaceDigi {
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function totalSupply() external view returns (uint);
    function transfer(address receiver, uint tokens) external returns (bool success);
    function transferFrom(address sender, address receiver, uint tokens) external returns (bool success);
    function get3DAOAddress() external view returns(address);
    function getRepsAddress() external view returns(address);
    function getDevFund() external view returns(uint);
}


interface InterfaceReps {
    function checkRep() external view returns (bool);
    function getMaturationTime() external view returns (uint);
    function getRepMin() external view returns (uint);
    function getRep() external view returns (address);
    function getUnlockBlock() external view returns (uint);
    function getStartBlock() external view returns (uint);

}

contract DaoGov is SafeMath{
    address tokenAddress;
    address DIGI;
    address DAO;
    address REP;
    address public stakePoolAddress;
    uint public minimumVotingPeriod;
    address [] public proposalContracts;
    uint proposalContractID;
    event proposalResult(uint _proposal, bool dtlcontract);
    event Digichecked(uint _block);
    uint DigiCheckBlock;
    uint FullProposerBonus;
    uint PartialProposerBonus;
    uint treasuryReturn;
    uint proposalIntializationThreshold;
    uint currentTreasury;
    uint treasury;

    struct Proposal {
        address proposer;
        string basic_description;
        uint yesVotes;
        uint noVotes;
        uint startVoteBlock;
        uint endVoteBlock;
        uint proposalCost;
        address [] alreadyVoted;
        bool voteEnded;
        bool votePass;
        bool enacted;
        uint initializationPoints;
        bool initialized;
        address [] initializers;
    }

    mapping(address => Proposal )  public proposers;
    Proposal[] public proposals;

    constructor(){
        minimumVotingPeriod = 10; //01 blocks
        proposalIntializationThreshold = 1000000 *10 *18; //1000000 DGT 1% of total supply
        DIGI = msg.sender;
        FullProposerBonus = 3;      //  3% of proposal cost
        PartialProposerBonus = 2500;   //  2500 DGT
        treasuryReturn = div(11,100);       //  1.11% of proposal cost
        treasury = 25_000_000e18;

    }

    modifier onlyDIGI(){
        require(msg.sender == DIGI);
        _;
    }
    modifier DIGIcheck{
        require(block.number < DigiCheckBlock,"DIGI no longer has any priviledges");
        _;

    }

    function getMaxAvailiableTokens() public view returns(uint){
        uint devFund = InterfaceDigi(tokenAddress).getDevFund();
        currentTreasury == devFund;
        uint availiableTokens = (div(1,50)) * (currentTreasury*currentTreasury) / treasury;
     return availiableTokens;
    }

    function getTreasuryReturn() public view returns (uint){
        return treasuryReturn;
    }
    function setStakePool(address pool) public onlyDIGI{
        require(stakePoolAddress==address(0),"Stake pool has already been set");
        stakePoolAddress = pool;
    }
    function getStakePool() public view returns (address){
       return stakePoolAddress;
    }
    function checkDigi() public onlyDIGI{
       require(DigiCheckBlock==0,"Digi has already been checked");
       DigiCheckBlock =  add(block.number,1726272);
       emit Digichecked(DigiCheckBlock);
    }
    function getDigiCheckBlock() public view returns(uint){
        return DigiCheckBlock;
    }
    function setDigitradeAddress(address digitoken) public onlyDIGI(){
        require(tokenAddress==address(0),"Token Address has already been set");
        tokenAddress = digitoken;
    }
    function getDigitradeAddress() public view returns(address){
        return tokenAddress;
    }
    function set3DAOAddress() public onlyDIGI{
        DAO = InterfaceDigi(tokenAddress).get3DAOAddress();
    }
    function get3DAOAddress() public view returns(address) {
        return DAO;
    }
    function setRepAddress() public onlyDIGI{
        REP = InterfaceDigi(tokenAddress).getRepsAddress();
    }

    modifier onlyVestedReps(){
       require(InterfaceDigi(tokenAddress).balanceOf(msg.sender) > InterfaceReps(REP).getRepMin(), "Not enough digitrade tokens");
       require(msg.sender == InterfaceReps(REP).getRep(),"You are not a rep" );
       require(block.number > InterfaceReps(REP).getUnlockBlock(), "UnlockBlock <  current block number");
      _;
    }
    modifier onlyInitializedProposal(uint _proposal){
      require(proposals[_proposal].initialized == true,"Proposal is not initialized");
      _;
    }
    modifier onlyProposalSponsor(uint _proposal){
       require(msg.sender == proposals[_proposal].proposer, "Only the proposal creator can call this function");
      _;
    }
    modifier onlyNonEnactedProposals(uint _proposal){
      require(proposals[_proposal].enacted == false, "Proposal is already enacted");
      _;
    }
    modifier onlyEndedProposals(uint _proposal){
      require(block.number > proposals[_proposal].endVoteBlock ,"Voting period has not ended");
      _;
    }


    function checkRegistration() public view returns(uint _unlockBlock, string memory){
        require(msg.sender == InterfaceReps(REP).getRep(), "You have not registered yet");
        if(InterfaceReps(REP).getUnlockBlock()< block.number){
           return (1,'You are registered');
        }else{
          return ((InterfaceReps(REP).getUnlockBlock() - InterfaceReps(REP).getStartBlock()), 'more blocks until registration');
        }
    }
      //VOTING PROCESS...

    function propose(string memory detailedDescription, uint256 _dgtCost, uint _votePeriod) public onlyVestedReps{
        uint256 stakeBalance = InterfaceDigi(tokenAddress).balanceOf(stakePoolAddress);
        uint maximumAvailiableTokens = mul(div(stakeBalance,100),2);
        require((_dgtCost*10*18) < maximumAvailiableTokens, "Proposal cost exceeds 2% of avaliable tokens");
        require(_votePeriod > minimumVotingPeriod);
        address[] memory iVoted;
        proposals.push(Proposal({
                proposer: msg.sender,
                basic_description: detailedDescription,
                yesVotes: 0,
                noVotes: 0,
                startVoteBlock:block.number,
                endVoteBlock: add(_votePeriod,block.number),
                proposalCost: _dgtCost,
                alreadyVoted:iVoted,
                voteEnded:false,
                votePass:false,
                enacted:false,
                initializationPoints: 0,
                initialized:false,
                initializers:iVoted
            }));
    }

    function initializeProposal(uint _proposal) public onlyVestedReps returns (string memory message, uint points){
      require(proposals[_proposal].initializationPoints < 1000000, "Proposal Already initialized");
      uint previousPoints = proposals[_proposal].initializationPoints;
      uint addedPoints = InterfaceDigi(tokenAddress).balanceOf(msg.sender);
      uint currentPoints = add(previousPoints, addedPoints);
      proposals[_proposal].initializationPoints = currentPoints;
      if(currentPoints > proposalIntializationThreshold){
        for (uint i=0; i<proposals[_proposal].initializers.length; i++){
            require(proposals[_proposal].initializers[i] != msg.sender, "Only one vote per address");
        }
      proposals[_proposal].initialized = true;
      string memory _message = "Proposal is initalized";
      message = _message;
      return (message, proposals[_proposal].initializationPoints);
        }else{
        return ("1000000 required to initialize, Current initialization points: ", proposals[_proposal].initializationPoints);
        }
    }

    function vote(uint _proposal, bool yes, bool no) public onlyVestedReps onlyInitializedProposal(_proposal) returns (string memory message){
       for (uint i=0; i<proposals[_proposal].alreadyVoted.length; i++) {
       require(proposals[_proposal].alreadyVoted[i] != msg.sender, "Only one vote per address");}
       require(proposals[_proposal].endVoteBlock > block.number, "Voting has ended");
       if(yes == true){
           require(no == false);
           proposals[_proposal].yesVotes += 1;
           return "You voted yes!";}
       if(no == true){
           require(yes == false);
           proposals[_proposal].noVotes += 1;
           return "You voted no!";}
       proposals[_proposal].alreadyVoted.push(msg.sender);
    }

    function tallyProposal(uint _proposal) public onlyEndedProposals(_proposal)  returns (bool _result) {
        if(proposals[_proposal].yesVotes > proposals[_proposal].noVotes){
        proposals[_proposal].voteEnded = true;
        proposals[_proposal].votePass = true;
        emit proposalResult(_proposal, true);
        return true;
        }
        if(proposals[_proposal].yesVotes < proposals[_proposal].noVotes){
        proposals[_proposal].voteEnded = true;
        proposals[_proposal].votePass = false;
        emit proposalResult(_proposal, true);
        delete proposals[_proposal];
        return false;
        }
    }

    function veto(uint _proposal) public onlyDIGI DIGIcheck(){
        uint yesVotes = proposals[_proposal].yesVotes;
        uint noVotes  = proposals[_proposal].noVotes;
        require((div(yesVotes,noVotes)) < mul((div(2,3)),(add(yesVotes,noVotes)))," 66% majority overides DIGI authority");
        proposals[_proposal].votePass = false;
        proposals[_proposal].enacted = false;
        proposals[_proposal].voteEnded = true;
        emit proposalResult(_proposal, false);
    }

    function calculateReleaseBlock(uint _weeks) public view returns (uint _releaseBlock){
        _releaseBlock = block.number + (_weeks * 70000);
        return _releaseBlock;
    }

    function enactProposal(
        uint _proposal,
        uint _weeks,
        address _facilitator
        )
        public  onlyProposalSponsor(_proposal) returns (address) {
        require(_weeks > 0," Proprosal needs at least 1 week to be completed");
        require(proposals[_proposal].votePass = true, "The vote did not pass");
        uint proposerBalance = InterfaceDigi(tokenAddress).balanceOf(msg.sender);
        require(proposerBalance >= proposals[_proposal].proposalCost,"Your DGT balance is < than the amount needed to enact proposal");
        uint _releaseBlock = calculateReleaseBlock(_weeks);

        proposalContractID = proposalContractID ++;

        ProposalContract newContract = new ProposalContract(
        proposalContractID,
        proposals[_proposal].proposer,
        proposals[_proposal].proposalCost,
        _facilitator,
        _releaseBlock,
        DIGI,
        DAO,
        tokenAddress,
        stakePoolAddress);
        address newContractAddress = address(newContract);
        proposalContracts.push(address(newContract));

        return newContractAddress;
    }

    //END VOTING PROCESS

}

interface InterfaceDaoGov {
  function getStakePool() external view returns (address);
  function getDIGI() external view returns (address);
  function getDigiCheckBlock() external view returns (uint);
  function get3DAOAddress() external view returns (address);
  function getDigitradeAddress() external view returns (address);
}

contract ProposalContract is SafeMath{
    address DIGI;
    uint DigiCheckBlock;
    address public tokenAddress;
    address public DAO;
    address public proposer;
    address public facilitator;
    uint public proposalCost;
    uint public releaseBlock;
    bool public penalized;
    bool enable;
    uint burnAmount;
    uint ID;

    uint public proposerStake;
    uint public otherStakers;
    uint completionBlock;
    uint timeOut;
    bool public taskComplete;
    address stakePoolAddress;
    address [] sponsors;
    mapping(address => uint) balances;

    struct Sponsors{
    address sponsor;
    uint balance;
    }

    event FundingNeeded(uint contractNumber, uint _amount, uint _timeRemaining);

    event TaskComplete(string completionMessage, bool _completionStatus);


    //TEAM STAKING
    constructor(
      uint _ID,
      address _proposer,
      uint _cost,
      address _facilitator,
      uint _releaseBlock,
      address _DIGI,
      address _DAO,
      address _tokenAddress,
      address _stakePool){
        ID = _ID;
        proposer = _proposer;
        facilitator = _facilitator;
        proposalCost = _cost;
        releaseBlock = _releaseBlock;
        DIGI = _DIGI;
        DAO = _DAO;
        tokenAddress = _tokenAddress;
        completionBlock = safeSub(_releaseBlock , div(_releaseBlock,10));
        stakePoolAddress = _stakePool;
        enable = false;
        penalized = false;

    }

    function sponsorBalance(address _sponsor) public  view returns (uint balance) {
        return balances[_sponsor];
    }

    modifier DIGIcheck{
        DigiCheckBlock = InterfaceDaoGov(DAO).getDigiCheckBlock();
        require(block.number < DigiCheckBlock,"DIGI no longer has any priviledges");
        _;

    }
    modifier onlyEnabled(){
        require(enable == true);
        _;
    }
    modifier onlyProposer(){
        require(msg.sender == proposer);
        _;
    }
    modifier onlyFacilitator(){
        require(msg.sender == facilitator);
        _;
    }
    modifier onlyDIGI(){
        require(msg.sender == DIGI);
        _;
    }

    function ProposerFundContract(uint _amount) public onlyProposer returns (string memory message, uint _completionBlock){
        require(_amount <= proposalCost, "Sending more than agreed upon amount");
        require(enable == false, "Proposal already enabled");
        InterfaceDigi(tokenAddress).transferFrom(msg.sender, address(this) , _amount);
        InterfaceDigi(tokenAddress).transfer(0x000000000000000000000000000000000000dEaD , mul(burnAmount,_amount));
        enable = true;
        proposerStake= safeSub(proposalCost,_amount);
        if(proposerStake < _amount){
            uint fundsNeeded = safeSub(_amount, proposerStake);
            emit FundingNeeded(ID, fundsNeeded, completionBlock);
        }
        message = "Completion notification due by";
        _completionBlock = completionBlock;
        return (message, _completionBlock);
    }

    function DigiFundContract() public onlyDIGI DIGIcheck{
        InterfaceDigi(tokenAddress).transfer(address(this),proposalCost);
        enable = true;
    }

    function checkFunds() public view returns(uint){
        return InterfaceDigi(tokenAddress).balanceOf(address(this));
    }

    function completionNotification(string memory message, bool _complete) public onlyFacilitator {
      require(block.number < releaseBlock, "The time to complete the complete the proposal has passed");
      taskComplete = _complete;
      emit TaskComplete(message, _complete);
      if(_complete == false){
        cancel(message);
      }
    }

    function releasePayments() public onlyFacilitator onlyEnabled{
        require(block.number > releaseBlock, "The current block number is less than the release block");
        InterfaceDigi(tokenAddress).transfer(facilitator,proposalCost);
    }

    function cancel(string memory reason) public onlyEnabled returns ( string memory _reason){
        if(msg.sender == DIGI || msg.sender == facilitator){
            require(block.number < releaseBlock);
            InterfaceDigi(tokenAddress).transfer(proposer, proposerStake);
            InterfaceDigi(tokenAddress).transfer(stakePoolAddress ,otherStakers);
            //100% return of tokens to stakePoolAddress and proposer
            enable = false;
            _reason = reason;
            return _reason;
            }
        if(msg.sender == proposer){
            require(block.number < releaseBlock);
            enable = false;
            penalized = true;
            proposerStake = mul((div(90,100)),proposerStake);
            InterfaceDigi(tokenAddress).transfer(stakePoolAddress ,(otherStakers+(1*proposerStake)));
            //100% return of tokens to stakePoolAddress but penalize proposer 10%
            enable = false;
            _reason = reason;
            return _reason;
            }

    }

    function collectProposerBenefit() public {

    }

    function returnPenalizedStake() public onlyProposer{
            require(penalized == true, "You weren't penalized");
            require(block.number > timeOut);
            InterfaceDigi(tokenAddress).transfer(proposer,proposerStake);
    }





}

contract StakePool{

}