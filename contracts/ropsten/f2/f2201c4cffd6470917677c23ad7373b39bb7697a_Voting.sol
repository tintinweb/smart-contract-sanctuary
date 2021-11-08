/**
 *Submitted for verification at Etherscan.io on 2021-11-07
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7 ;  // last version : 03/11/2021  !!! différent dans remix ! 0.8.7+commit.e28d00a7 
//pragma solidity >=0.7.0 <0.9.0;
//pragma solidity 0.8.9; // last version : 03/11/2021  !!! différent dans remix ! 0.8.7+commit.e28d00a7 


// import openzeppling :  - comment : not used here 
//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

//import "stringFunctions"; 
//import "library_str.sol - obo-devs/library_str";

/** 
 * @title Voting
 * @dev Implements a voting process 
 */
contract Voting {
    
    // TODO 01 
    // set admin :  msg.sender par défaut 
    // faire une fct setAdmin pour changer admin si nécessaire ... 
    address public voteAdmin = msg.sender; 
    
    // les ints ici : 
    uint public winningProposalId; // voir si on garde (fct getWinner) :
    uint public nbVoters;
    
    // Structs : 
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
        //uint votedProposalId;
    }

    struct Proposal {
        // If you can limit the length to a certain number of bytes, 
        // always use one of bytes1 to bytes32 because they are much cheaper
        uint proposalId; 
        string prop; 
        // moins coûteux que string - comparaison des chaines plus rapide 
        
        // string description;
        uint voteCount; // number of accumulated votes
        
        
    }
    
    mapping(address => Voter) public voters;
    
    // vote status : 
    enum WorkflowStatus {
        
        RegisteringVoters,              // 0 - State 00 : Registering Voters 
        ProposalsRegistrationStarted,   // 1 - State 01 : Proposals - Started registration
        ProposalsRegistrationEnded,     // 2 - State 02 : Proposals - Ended registration
        VotingSessionStarted,           // 3 - State 03 : Votes - Started Voting 
        VotingSessionEnded,             // 4 - State 04 : Votes - Ended Voting
        VotesTallied                    // 5 - State 05 : VotesTallied
    }
    
    // Events : 4 events to watch ... 
    event VoterRegistered(address voterAddress);                                            // E01 
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);    // E02
    // event ProposalRegistered(uint proposalId);                                              // E03
    event ProposalRegistered(string proposalId);                                              // E03
    event Voted (address voter, uint proposalId);                                           // E04 

    Proposal[] public proposals;
    
    
    
    // vote status :
    WorkflowStatus public voteStatus  = WorkflowStatus.VotesTallied;
    
    // Process :
    // Task 01 - liste de voters whitelist : 
    
    // Task 02 - start recording proposals : 
    // Solution 1 - admin enregistre 
    // construite le tableau des proposals  : 
    // constructor(string[] memory _listProposals) {
    
    
    // pas utilisé pour cet exemple : 
    /**
    constructor(string[] memory _listProposals) {
        
        //Voter memory _newVoter ;
        
        for (uint i = 0; i < _listProposals.length; i++) {
            
            proposals.push(Proposal({
                proposalId: i, 
                prop: _listProposals[i],
                voteCount: 0
            }));
        }
    } 
    */
    // fonctions nommées avec 1 2 3 en préfixe pour les avoir dans l'ordre dans le deploy : 
    function a_startRegistration () public {
            
        
        require( msg.sender == voteAdmin, "Only Admin can open registration.");
        //emit event WorkflowStatusChange( previousStatus,  newStatus);
        
        emit WorkflowStatusChange(voteStatus, WorkflowStatus.RegisteringVoters);
        // new status : 
        voteStatus = WorkflowStatus.RegisteringVoters;
    }
    
    
    function b_registerVoter(address _voter) public {
        
        // pré-requis : 
        // add status = RegisteringVoters
        require(voteStatus == WorkflowStatus.RegisteringVoters , "Voter registration not stated");
        // 1 - admin enregistre le voter 
        require( msg.sender == voteAdmin, "Only Admin can give right to vote.");
        // 2 - s'il n'a pas voté 
        require( !voters[_voter].hasVoted, "Voted !");  
        // 3 - si voter n'est pas enregistré 
        require (!voters[_voter].isRegistered, "already Registred");
        
        voters[_voter].isRegistered = true;
        voters[_voter].votedProposalId = 0; 
        nbVoters+=1;
        
        emit VoterRegistered(_voter); 
    }
    
    function c_openPropositions () public {
            
        //emit event WorkflowStatusChange( previousStatus,  newStatus);
        
        emit WorkflowStatusChange(voteStatus, WorkflowStatus.ProposalsRegistrationStarted); 
        // new status : 
        voteStatus = WorkflowStatus.ProposalsRegistrationStarted;
    }
    
    
    // Solution 2 - chaque voter peut enregistrer ses propositions: - demandé dans l'énoncé : 
    
    function d_propose(uint _id , string memory _prop) public {
            
            // check vote status : 
            require(voteStatus == WorkflowStatus.ProposalsRegistrationStarted , "Registration not stated");
            //require(voteStatus == 0 , "Registration not stated");
            // check if _prop exists then store it :
            require(!propExists(_prop ) , "Proposition existante");
            //if propExists(_prop )
            proposals.push(Proposal( {
                // modifier : 
                // description: _prep,
                proposalId: _id,
                prop: _prop,
                voteCount: 0
            } 
            )
            );
            // event : 
            emit ProposalRegistered(_prop);
    }
    
    function e_closePropositions () public {
            
        //emit event WorkflowStatusChange( previousStatus,  newStatus);
        emit WorkflowStatusChange(voteStatus, WorkflowStatus.ProposalsRegistrationEnded); 
        // new status : 
        voteStatus = WorkflowStatus.ProposalsRegistrationEnded;
    }
    
    // Session 2 - Vote :
    function f_startVoting () public {
            
        //emit event WorkflowStatusChange( previousStatus,  newStatus);
        emit WorkflowStatusChange(voteStatus, WorkflowStatus.VotingSessionStarted); 
        // new status : 
        voteStatus = WorkflowStatus.VotingSessionStarted;
    }
        
    
    
        // Voters :
        // Task 02 - whitelist  : 
        // construite la liste de voters   :  liste address : 
        
    //function makeListVoters ( address[] memory _voters ) public {
    /**
    function makeListVoters () public {
        
            
            for (uint i = 0; i < nbVoters; i++) {
            
                registerVoter(voters[i]);
            
            }
            
            // new status : 
            
            //emit event WorkflowStatusChange( previousStatus,  newStatus);
            emit WorkflowStatusChange(voteStatus, WorkflowStatus.ProposalsRegistrationStarted); 
            
            voteStatus = WorkflowStatus.ProposalsRegistrationStarted;
        
    }
    */
    
    // Session 2 - Vote :
    
    function g_voter( address  _voterAdr, uint _proposal) public {
        
        // prérequis du vote : 
        // 1 - require sur état du vote : lancé - ajouter : 
        
        // 2 - voter enregistré et n'a pas encore voté 
        // map
        // current voter : 
        //voter curVoter    = voters[msg.sender];
        
        // fait après les requires :
        //_curVoter.hasVoted = true;
        //_curVoter.votedProposalId = _proposal;
        //voters[msg.sender] = _curVoter; fait après les requires :
        
        Voter memory _curVoter = voters[_voterAdr];
        
        require(voteStatus == WorkflowStatus.VotingSessionStarted , "Vote not stated");
        require(_curVoter.isRegistered , "Voter not registered - please try later");
        require(!_curVoter.hasVoted, "Voter has already voted - No Chance to cheat!");
        
        // comptabiliser le vote : 
        proposals[_proposal].voteCount += 1;
        _curVoter.hasVoted = true;
        _curVoter.votedProposalId = _proposal;
        //voters[msg.sender] = _curVoter;
        voters[_voterAdr] = _curVoter;
        
        // event voted  : 
        emit Voted(_voterAdr, _proposal);
    
    }
    
    // Session 2 - Vote :
    function h_endVoting () public {
            
        //emit event WorkflowStatusChange( previousStatus,  newStatus);
        emit WorkflowStatusChange(voteStatus, WorkflowStatus.VotingSessionEnded); 
        // new status : 
        voteStatus = WorkflowStatus.VotingSessionEnded;
    }
    
    // get the winner : 
    // 2 solutions différentes pour getWinner 
    // error identifier ! why ? 
    // commented pour éliminer les err de compil - et chercher la cause :
    // remplacée par getWinnerVote
    /****
    function winner() public returns(unint) {
        // show the Winner : 
        // trouver le winner avec max votes - boucle sur proposals et get max nb votes 
        
        uint  winnerIndex;
        for (uint i = 1; i < proposals.length; i++) {
            
            if (proposals[winnerIndex].voteCount < proposals[i].voteCount) {
                winnerIndex = i;
               
            }
        }
        // winningProposalId = winnerIndex;
        return winnerIndex;
        
    }
    */
    
    function i_getWinnerVote() public returns(uint, uint){
        // show the Winner - return index and nb votes for the winner - 
        // trouver le winner avec max votes - boucle sur proposals et get max nb votes 
    uint maxVote;
    uint maxIndex;
    
    require(voteStatus == WorkflowStatus.VotingSessionEnded , "Vote not ended");

    for (uint i = 0; i < proposals.length; i++) {
        if (proposals[i].voteCount > maxVote) {
            maxVote = proposals[i].voteCount;
            maxIndex = i; 
        }
    }
    winningProposalId = maxIndex;
    return (winningProposalId, maxVote);
    }
    
    // show winner : 
    function j_showWinnerProp() public view returns (string memory, uint) {
        // show the Winner : 
        
        require(voteStatus == WorkflowStatus.VotingSessionEnded , "Vote not ended");
            
        return (proposals[winningProposalId].prop , proposals[winningProposalId].voteCount);
        
    }
    
    function hashCompareLower(string memory a, string memory b) public pure returns (bool) {
        //function hashCompare(string memory a, string memory b) internal pure returns (bool) {
        string memory aCap = a; // modif : a majuscule 
        string memory bCap = b; // modif : b majuscule 
        if(bytes(a).length != bytes(b).length) {
            return false;
        } else {
            // convertir en maj avant de comparer - pour notre exemple : paris == PARIS etc 
            
            return keccak256(abi.encodePacked(aCap)) == keccak256(abi.encodePacked(bCap));
            
            //keccak256(abi.encodePacked(_s1))
            //abi.encodePacked(a)
        }
    }
    
    //function propExists(string memory _prop) public view returns(bool) {
    function propExists(string memory _prop) public view returns( bool ) {
        
        // in proposals - find  prop == _prop :
        bool check;
        string memory propLower;
        for (uint i = 0; i < proposals.length; i++) {
            
            // to lower : mettre les props en minuscules avant de comparer : paris = PARIS ! 
            propLower = toLower(proposals[i].prop);
            
            
            //if ( hashCompareCapitals(proposals[i].prop, _prop) ) {
            if ( hashCompareLower(propLower, toLower(_prop) ) ) {
                check = true; 
            }
        }
    
        return check; 
        
    }
    
    function toLower(string memory str) public pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint i = 0; i < bStr.length; i++) {
            // Uppercase character...
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                // So we add 32 to make it lowercase
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }
    
    function setAdmin(address _admin) public {
        
        voteAdmin = _admin;
    }
   
}