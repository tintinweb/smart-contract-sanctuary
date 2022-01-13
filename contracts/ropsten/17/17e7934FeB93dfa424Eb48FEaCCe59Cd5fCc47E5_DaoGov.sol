/**
 *Submitted for verification at Etherscan.io on 2022-01-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


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

interface Digi {
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function totalSupply() external view returns (uint);
    function transfer(address receiver, uint tokens) external returns (bool success);
    function transferFrom(address sender, address receiver, uint tokens) external returns (bool success);
    function getDevFund() external view returns(uint);
}

interface Reps {
    function getRepMin() external view returns (uint);
    function getRep() external view returns (address);
    function getUnlockBlock() external view returns (uint);
    function getStartBlock() external view returns (uint);

}

interface Pool{
    function getMaxAvailiableTokens() external view returns(uint);
}

contract DaoGov is SafeMath{
    address public tokenAddress; // Address of digitoken
    address digi; //Address of digitoken creator
    address governance; //This address
    address pool; //Address of pool
    address public representative;  //Address where represenative information is stored
    uint public minimumVotingPeriod; //Minimum time allotted for voting on a proposal
    address [] public proposalContracts; //An Array of enacted proposal contracts
    event proposalResult(uint _proposal, bool passed); 
    uint resignBlock; //block digi loses all special rights and system becomes truly decentralized.
    uint proposalIntializationThreshold; //Required amount of voting power to allow full voting on a proposal
    

    struct Proposal {
        address proposer;
        string basic_description;
        uint yesVotes;
        uint noVotes;
        uint endVoteBlock;
        uint proposalCost;
        address [] alreadyVoted;
        bool voteEnded;
        bool votePass;
        bool enacted;
        uint initializationPoints;
        bool initialized;
        address [] initializers;
        uint proposalType;
        bool active;
    }

    mapping(address => Proposal )  public proposers;
    Proposal[] public proposals;

    constructor(){
        minimumVotingPeriod = 10; //(Change to 70000)minimum blocks(Around 7 days) voting is allowed on proposal
        proposalIntializationThreshold = 1_000_000e18; //1000000 DGT 1% of total supply
        digi = 0x454486384935312cab9a53870083e1C898Ed4Fb3;
        pool = 0x707560515D37a0e8d7eC8a0014AE46DeF3D9B8af;
        tokenAddress = 0x0e8637266D6571a078384A6E3670A1aAA966166F; //Address of DGT token
        representative = 0x6Bea0FBdD23a094d92949a7226164E6aBAaAC038; //Address of Reprensatives
        governance = address(this); //Governance Contract
        resignBlock = add(block.number,1726272); //(6 months from launch)block digi loses all special rights and system becomes truly decentralized. 
    }

    modifier onlyDIGI(){
        require(msg.sender == digi);
        _;
    }
    modifier DIGIcheck{
        require(block.number < resignBlock, "DIGI no longer has any priviledges");
        _;

    }
    modifier onlyReps(){
       require(Digi(tokenAddress).balanceOf(msg.sender) > Reps(representative).getRepMin(), "Not enough digitrade tokens");
       require(msg.sender == Reps(representative).getRep(),"You are not a rep" );
       require(block.number > Reps(representative).getUnlockBlock(), "UnlockBlock <  current block number");
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

    function getMaxAvailiableTokens() public view returns (uint){
        return Pool(pool).getMaxAvailiableTokens();
    }
    function getDigiCheckBlock() public view returns(uint){
        return resignBlock; 
    }
    function getDigitradeAddress() public view returns(address){
        return tokenAddress;
    }
    function getDaoGovAddress() public view returns(address) {
        return governance;
    }

    function checkRegistration() public view returns(uint _unlockBlock, string memory){
        require(msg.sender == Reps(representative).getRep(), "You have not registered yet");
        if(Reps(representative).getUnlockBlock()< block.number){
           return (1,'You are registered');
        }else{
          return ((Reps(representative).getUnlockBlock() - Reps(representative).getStartBlock()), 'more blocks until registration');
        }
    }

    function propose(string memory detailedDescription, uint256 _dgtCost, uint _votePeriod, uint _type) public onlyReps{
        require((_dgtCost*10*18) < getMaxAvailiableTokens(), "Proposal cost exceeds 2% of avaliable tokens");
        require(_votePeriod > minimumVotingPeriod, "Not enough time for potential voters to become aware of proposal");
        require(_type < 2, "0 = EcosystemImprovementContract(EIC) 1 = ProfitOrientedContract(POC)");
        address[] memory iVoted;
        proposals.push(Proposal({
                proposer: msg.sender,
                basic_description: detailedDescription,
                yesVotes: 0,
                noVotes: 0,
                endVoteBlock: add(_votePeriod,block.number),
                proposalCost: _dgtCost,
                alreadyVoted:iVoted,
                voteEnded:false,
                votePass:false,
                enacted:false,
                initializationPoints: 0,
                initialized:false,
                initializers:iVoted,
                proposalType:_type,
                active:false
            }));
    }

    function initializeProposal(uint _proposal) public onlyReps returns (string memory message, uint points){
      require(proposals[_proposal].initializationPoints < 1000000, "Proposal Already initialized");
      uint previousPoints = proposals[_proposal].initializationPoints;
      uint addedPoints = Digi(tokenAddress).balanceOf(msg.sender);
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

    function vote(uint _proposal, bool yes, bool no) public onlyReps onlyInitializedProposal(_proposal) returns (string memory message){
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
        emit proposalResult(_proposal, false);
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
 /**  Inactive until 1/19/2022
    function enactProposal(uint _proposal,uint _weeks,address _facilitator)
        public  onlyProposalSponsor(_proposal) returns (address) {
        require(_weeks > 0," Proprosal needs at least 1 week to be completed");
        require(proposals[_proposal].votePass = true, "The vote did not pass");
        uint proposerBalance = Digi(tokenAddress).balanceOf(msg.sender);
        require(proposerBalance >= proposals[_proposal].proposalCost,"Your DGT balance is < than the amount needed to enact proposal");
        uint _releaseBlock = calculateReleaseBlock(_weeks);
        address newContractAddress;

        if(proposals[_proposal].proposalType ==0){

        DaoImprovementContract newContract = new DaoImprovementContract(
            msg.sender,
            proposals[_proposal].proposalCost,
            _facilitator,
            _releaseBlock,
            digi,
            representative,
            tokenAddress,
            pool);
        newContractAddress = address(newContract);
        proposalContracts.push(address(newContract));
        }

        if(proposals[_proposal].proposalType ==1){

        ProfitOrientedContract newContract = new ProfitOrientedContract();
        newContractAddress = address(newContract);
        proposalContracts.push(address(newContract));
        }


        return newContractAddress;
    }
*/
}

interface Gov {
  function getPool() external view returns (address);
  function getDIGI() external view returns (address);
  function getDigiCheckBlock() external view returns (uint);
  function getDaoGovAddress() external view returns (address);
  function getDigitradeAddress() external view returns (address);
}

contract ProfitOrientedContract is SafeMath{
    //1/19/2022
}

contract DaoImprovementContract is SafeMath{
    //1/19/2022

}