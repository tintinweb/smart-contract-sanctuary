/**
 *Submitted for verification at testnet.snowtrace.io on 2021-12-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;



interface IERC721Enumerable {
    //Returns the total amount of tokens stored by the contract.
    function totalSupply() external view returns (uint256);

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    function balanceOf(address _owner) external view returns (uint256);
}
/*
interface Market{
    function totalActiveListings() external view returns (uint256);

    //function getMyActiveListings(uint256 from, uint256 length) external view returns (Listing[] memory listing);
    
    function getMyActiveListingsCount() external view returns (uint256);
}
*/

contract APAGovernance {
    IERC721Enumerable  apaContract;

    enum BallotType {perAPA, perAddress}
    enum Status { Accepted, Rejected, Active }
    enum Votes { Yes, No }

    struct Proposal {
        uint id;
        address author;
        string name;
        string description;
        //Option[] options;
        uint end;
        uint votesYes;
        uint votesNo;
        //uint ballotType; // 0 = perAPA   1= perAddress
        BallotType ballotType; 
        Status status;
    }
 
    address public  manager;
    uint public votingPeriod;
    uint public proposerApas; 
    uint private nextPropId;
    Proposal[] public proposals;
    mapping(uint => mapping(address => bool)) public voters;
    mapping(uint => mapping(uint => bool)) public votedAPAs;
    address private apaToken = 0x9E491465BbD22B62D7d27E0Ff35d4e263228ba5C;
    address private apaMarket = 0x451650527d1a58875E71cf18F429E46838387Dc1;


    constructor() {
        manager = msg.sender;
        apaContract = IERC721Enumerable(apaToken);
        proposerApas = 30;
    }

    modifier onlyManager() {
        require(msg.sender == manager, 'only manager can execute this function');
        _;
    } 

    modifier verifyNumApas(uint minAPAs) {
        // Check if sender has minimum number of APAs
        require(balanceOf(msg.sender) >= minAPAs, 'Need more APAs');
        _;
    }
    //function to set number of APAs needed to be able to create proposal
    function setProposerApas(uint minApas) public onlyManager() {
        require (minApas >0, "set minimum to at least one APA ");
        proposerApas = minApas;
    }

    function balanceOf(address owner) 
        public
        view 
        returns (uint){
        return apaContract.balanceOf(owner);
    }

    function createProposal(
        string memory _name, 
        string memory _desc,
        uint duration, //in days
        BallotType _ballotType //0=perAPA 1=perAddress
        ) external verifyNumApas(proposerApas)  {
            proposals.push( Proposal(
                nextPropId,
                msg.sender,
                _name,
                _desc,
                block.timestamp + duration * 1 days,
                0,
                0,
                _ballotType,
                Status.Active
               )
            );
            nextPropId+=1;

    }

    function vote(uint proposalId , Votes _vote) external {
        uint voterBalance = balanceOf(msg.sender);
        require(voterBalance > 0, "Need at least one APA to cast a vote");
        require(!voters[proposalId][msg.sender], "Voter has already voted");  // Maker sure voter has not yet voted
        require(block.timestamp < proposals[proposalId].end, "Proposal has Expired");
        uint currentAPA;
        uint8 ineligibleCount=0;
 
        //get user Apas map from wallet
       for(uint16 i=0; i < voterBalance; i++){
            currentAPA = apaContract.tokenOfOwnerByIndex(msg.sender, i);
            //check if APA has already voted and add to UserAPAs if eligible
           
            if(votedAPAs[proposalId][currentAPA] != true){
                //add APAs to proposal array
                if(proposals[proposalId].ballotType == BallotType.perAPA){
                    votedAPAs[proposalId][currentAPA] = true;
                }
                if(proposals[proposalId].ballotType == BallotType.perAddress){
                    votedAPAs[proposalId][currentAPA] = true;//prevent using same APA more than once
                    break;//break if one vote per address, 
                }
                
            }
            else{
                ineligibleCount+=1;
            }
        }
        
/*
        //get user APAs from Market
        uint myActiveListingsCount = Market(apaMarket).getMyActiveListingsCount();
        //listings = Market(apaMarket).getMyActiveListings(0,myActiveListingsCount);
        
        for(uint i=UserAPAs.length; i < UserAPAs.length + myActiveListingsCount; i++){
            currentAPA = listings[i].tokenId;
            //check if APA has already voted anIERC721Enumerabled add to UserAPAs if eligible
            if(isEligible(currentAPA, proposalId)){
                //add to User array
                UserAPAs[i] = currentAPA;
                //add to proposal array
                votedAPAs[proposalId].push(currentAPA);
            }

        }
*/
        uint eligibleVotes = voterBalance - ineligibleCount;

        
        //1 vote per APA 
       if(proposals[proposalId].ballotType == BallotType.perAPA){
            if (_vote == Votes.Yes){
                proposals[proposalId].votesYes += eligibleVotes;
            }
            else {
                proposals[proposalId].votesNo += eligibleVotes;
            }
            
        }

        //1 vote per address
        if(proposals[proposalId].ballotType == BallotType.perAddress){
            if (_vote == Votes.Yes){
                proposals[proposalId].votesYes += 1;
            }
            if (_vote == Votes.No){
                proposals[proposalId].votesNo += 1;
            }
        }
        //mark voter as voted
        voters[proposalId][msg.sender] = true; 
    }
    

    function certifyResults(uint proposalId) external onlyManager() returns(Status) {
            //make sure proposal has ended
            require(block.timestamp > proposals[proposalId].end, "Proposal has not yet ended");
            if(proposals[proposalId].votesYes - proposals[proposalId].votesNo > 0) {
                proposals[proposalId].status = Status.Accepted;
            }
            else proposals[proposalId].status = Status.Rejected;
        return proposals[proposalId].status;
    }

    function getProposals() view external returns(Proposal[] memory){
        return proposals;
    }

    

}