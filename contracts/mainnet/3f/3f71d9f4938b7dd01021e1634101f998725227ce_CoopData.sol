/**
 *Submitted for verification at Etherscan.io on 2021-02-04
*/

//Audit report available at https://www.tkd-coop.com/files/audit.pdf

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

//Control who can access various functions.
contract AccessControl {
    address payable public creatorAddress;
    mapping (address => bool) public admins;

    modifier onlyCREATOR() {
        require(msg.sender == creatorAddress, "You are not the creator of this contract");
        _;
    }

    modifier onlyADMINS() {
      
      require(admins[msg.sender] == true);
        _;
    }

    // Constructor
    constructor() {
        creatorAddress = 0x813dd04A76A716634968822f4D30Dfe359641194;
    }

    //Admins are contracts or addresses that have write access
    function addAdmin(address _newAdmin) onlyCREATOR public {
        if (admins[_newAdmin] == false) {
            admins[_newAdmin] = true;
        }
    }
    
    function removeAdmin(address _oldAdmin) onlyCREATOR public {
        if (admins[_oldAdmin] == true) {
            admins[_oldAdmin] = false;
        }
    }
}

//Interface to TAC Contract
abstract contract ITAC {
     function awardTAC(address winner, address loser, address referee) public virtual;
     function transferFrom(address sender, address recipient, uint256 amount) public virtual returns (bool);
     function balanceOf(address account) external virtual view returns (uint256);
}


contract CoopData is AccessControl {

    /////////////////////////////////////////////////DATA STRUCTURES AND GLOBAL VARIABLES ///////////////////////////////////////////////////////////////////////
  
    uint256 public numUsers = 0; //total number of user profiles, independent of number of addresses with balances
    uint64 public numMatches = 0; //total number of matches recorded
    uint16 public numEvents = 0; //number of events created

    uint256 public eventHostingCost = 100000000000000000000; //cost to host an event in Hwangs.

    //Main data structure to hold info about an athlete
    struct User {
        address userAddress; //since the address is unique this also serves as their id.
        uint8 allowedMatches;
        uint64[] matches;
        uint64[] proposedMatches;
        uint64[] approvedMatches;
    }

    //Main data structure to hold info about an event
    struct Event {
        address promoter; //the person who holds the tournament
        string eventName;
        uint64 time;
        uint64 eventId;
        uint16 allowedMatches;
    }

    // Main data structure to hold info about a match
    struct Match {
        uint64 id;
        address winner; //address (id) of the athlete who won
        uint8 winnerPoints;
        address loser; //address (id) of the athlete who lost
        uint8 loserPoints;
        address referee; //Who recorded the match
        bool loserVerified;
        bool winnerVerified;
        uint64 time;
        string notes;
    }
    
    // Main mapping storing an Match record for each match id.
    Match[] public allMatches;
    Match[] public proposedMatches;
    Event[] allEvents;
    address[] public allUsersById;
        
    // Main mapping storing an athlete record for each address.
    mapping(address => User) public allUsers;

    // Mapping storing which users are authorized to act as staff for which event.
    // A user can only be authorized for one event at a time
    mapping(address  => uint64) public tournamentStaff;

    //A list of all proposed matches to be used as ID. 
    uint64 public numProposedMatches = 0;
    bool public requireMembership = true;

    address public TACContract = 0xABa8ace37f301E7a3A3FaD44682C8Ec8DC2BD18A;
    
    //The amount of Hwangs required to spar a match. 
    uint public matchCost = 10000000000000000000;

    /////////////////////////////////////////////////////////CONTRACT CONTROL FUNCTIONS //////////////////////////////////////////////////

    function changeParameters(uint256 _eventHostingCost, address _TACContract, uint _matchCost, bool _requireMembership) external onlyCREATOR {
        
        eventHostingCost = _eventHostingCost;
        TACContract = _TACContract;
        matchCost = _matchCost;
        requireMembership = _requireMembership;
    }

    function getParameters() external view returns (uint256 _eventHostingCost) {
        _eventHostingCost = eventHostingCost;
    }

    /////////////////////////////////////////////////////////USER INFO FUNCTIONS  //////////////////////////////////////////////////

   //function which sets information for the address which submitted the transaction.
    function setUser() public {

        bool zeroMatches = false;

        if (allUsers[msg.sender].userAddress == address(0)) {
            //new user so add to number of users
             numUsers ++;
             allUsersById.push(msg.sender);
             zeroMatches = true;
        }

        User storage user = allUsers[msg.sender];
        user.userAddress = msg.sender;
        if (zeroMatches == true) {
            user.allowedMatches = 0;
        }
    }

    //Function which specifies how many matches a user has left.
    //Only coop members have approved matches and only referees need them. 
    //Set 0 to remove a user's ability to record matches. 
    function setUserAllowedMatches(address user, uint8 newApprovalNumber) public onlyADMINS {
        allUsers[user].allowedMatches = newApprovalNumber;
    }

    //Function which returns user information for the specified address. 
    function getUser(address _address) public view returns(address userAddress, uint64[] memory matches, uint8 allowedMatches) {
      
       User storage user = allUsers[_address];
       userAddress = user.userAddress;
       matches = user.matches;
       allowedMatches = user.allowedMatches;
      }
      
    //Function which returns user information for the specified address. 
    function getUserMatches(address _address) public view returns(uint64[] memory _proposedMatches, uint64[] memory approvedMatches) {
       
       User storage user = allUsers[_address];
       _proposedMatches = user.proposedMatches;
       approvedMatches = user.approvedMatches;
      }
      
      function getUserMatchNumber(address _address) public view returns (uint256) {
          return allUsers[_address].approvedMatches.length;
      }

    /////////////////////////////////////////////////////////MATCH FUNCTIONS  //////////////////////////////////////////////////

    function proposeMatch(address _winner, uint8 _winnerPoints, address _loser, uint8 _loserPoints, address _referee, string memory _notes) public {
       
        require((allUsers[_referee].allowedMatches > 0 || requireMembership == false), "Members must have available allowed matches");
        require(msg.sender == _referee, "The referee must record the match");
        require((_winner != _loser) && (_winner != _referee) && (_loser != _referee), "The only true battle is against yourself, but can't count it here.");
        
        require(allUsers[_winner].userAddress != address(0), "User is not yet registered");
        require(allUsers[_loser].userAddress != address(0), "User is not yet registered");
        
        //Decrement the referee's match allowance
        if (requireMembership == true) {
        allUsers[_referee].allowedMatches -= 1;
        }

        // Create the proposed match
        Match memory proposedMatch;
        proposedMatch.id = numProposedMatches;
        proposedMatch.winner = _winner;
        proposedMatch.winnerPoints = _winnerPoints;
        proposedMatch.loser = _loser;
        proposedMatch.loserPoints = _loserPoints;
        proposedMatch.referee = _referee;
        proposedMatch.loserVerified = false;
        proposedMatch.winnerVerified = false;
        proposedMatch.time = uint64 (block.timestamp);
        proposedMatch.notes = _notes;
        
        numProposedMatches ++;
        
        // Add it to the list of each person as well as the overall list. 
        proposedMatches.push(proposedMatch);
        allUsers[_winner].proposedMatches.push(proposedMatch.id);
        allUsers[_loser].proposedMatches.push(proposedMatch.id);
        allUsers[_referee].proposedMatches.push(proposedMatch.id);
    }
    
    function overwriteMatch(uint64 id, address _winner, uint8 _winnerPoints, address _loser, uint8 _loserPoints, string memory _notes) public {
        // The referee only can overwrite matches
        require(proposedMatches[id].referee == msg.sender, "Only the referee may overwrite a match");
        // Matches can only be overwritten before they have been approved by both athletes
        require(proposedMatches[id].winnerVerified == false || proposedMatches[id].loserVerified == false, "This match has already been finalized");
        // Each participant can have only one role. 
        require((_winner != _loser) && (_winner != msg.sender) && (_loser != msg.sender), "The only true battle is against yourself, but can't count it here.");
        
        // Reset the athlete approvals since the result has changed. 
        proposedMatches[id].winnerVerified = false;
        proposedMatches[id].loserVerified = false;

        require(allUsers[_winner].userAddress != address(0), "User is not yet registered");
        require(allUsers[_loser].userAddress != address(0), "User is not yet registered");

        //Push to their proposedMatches if athlete changes
        if ((_winner != proposedMatches[id].winner) && (_winner != proposedMatches[id].loser)) {
            allUsers[_winner].proposedMatches.push(id);
        }

        if ((_loser != proposedMatches[id].winner) && (_loser != proposedMatches[id].loser)) {
            allUsers[_loser].proposedMatches.push(id);
        }

        // Overwrite the match. 
        proposedMatches[id].winner = _winner;
        proposedMatches[id].winnerPoints = _winnerPoints;
        proposedMatches[id].loser = _loser;
        proposedMatches[id].loserPoints = _loserPoints;
        proposedMatches[id].notes = _notes;
        
        allUsers[_winner].proposedMatches.push(id);
        allUsers[_loser].proposedMatches.push(id);
    }

    function getProposedMatch(uint64 matchId) public view returns (uint64 id, address winner, uint8 winnerPoints, address loser, uint8 loserPoints, address referee, uint64 time, string memory notes, bool winnerVerified, bool loserVerified) {
        
        id = proposedMatches[matchId].id;
        winner = proposedMatches[matchId].winner;
        winnerPoints = proposedMatches[matchId].winnerPoints;
        loser = proposedMatches[matchId].loser;
        loserPoints = proposedMatches[matchId].loserPoints;
        referee = proposedMatches[matchId].referee;
        notes = proposedMatches[matchId].notes;
        winnerVerified = proposedMatches[matchId].winnerVerified;
        loserVerified = proposedMatches[matchId].loserVerified;
        time = proposedMatches[matchId].time;
    }

    function approveMatch(uint64 id) public {
        // Make sure the match has not already been verified. 
        require(((proposedMatches[id].winnerVerified == false) || (proposedMatches[id].loserVerified == false)), 'Both athletes have already verified this match' );
        
        //  Find if the user calling approve is the winner or loser. 
        bool winner = false;
        bool loser = false;
        if (proposedMatches[id].winner == msg.sender) {
            winner = true;
        }
         if (proposedMatches[id].loser == msg.sender) {
            loser = true;
        }
        
        require(winner || loser, "You are not a player in this match");
        
          // First see if the other player has verified. 
          
          //Case 1 - The caller is the winner   
          if (winner) {
              // If the loser has not verified.
              if (proposedMatches[id].loserVerified == false) {
              proposedMatches[id].winnerVerified = true;
                }
             //If the loser has verified
            else {
                proposedMatches[id].winnerVerified = true;
                finalizeMatch(id);
            }
          }
          
               //Case 2 - The caller is the losing athlete  
          if (loser) {
              // If the winner has not verified.
              if (proposedMatches[id].winnerVerified == false) {
              proposedMatches[id].loserVerified = true;
                }
             //If the loser has verified
            else {
                proposedMatches[id].loserVerified = true;
                finalizeMatch(id);
            }
          }
          
    }
    
    //Called to record match and award TAC
    //Internal function called only once all checks are passed
    function finalizeMatch(uint64 id) internal {

        allUsers[proposedMatches[id].winner].approvedMatches.push(id);
        allUsers[proposedMatches[id].loser].approvedMatches.push(id);
        allUsers[proposedMatches[id].referee].approvedMatches.push(id);
           
        proposedMatches[id].id = numMatches;
         
        //Add the match to the athletes
        allUsers[proposedMatches[id].winner].matches.push(numMatches);
        allUsers[proposedMatches[id].loser].matches.push(numMatches);
           
        allMatches.push(proposedMatches[id]);
        numMatches ++;
           
        ITAC TAC = ITAC(TACContract);
        //Transfer the 10 TAC from each athlete. 
        TAC.transferFrom(proposedMatches[id].loser, creatorAddress, matchCost);
        TAC.transferFrom(proposedMatches[id].winner, creatorAddress, matchCost);
        //Award bonus TAC
        TAC.awardTAC(allUsers[proposedMatches[id].winner].userAddress, allUsers[proposedMatches[id].loser].userAddress, allUsers[proposedMatches[id].referee].userAddress);
     
    }


    function recordEventMatch(uint64 _eventId, address _winner, uint8 _winnerPoints, address _loser, uint8 _loserPoints, address _referee) public {
        //Check that the tournament promoter is the caller
        require((msg.sender == allEvents[_eventId].promoter || tournamentStaff[msg.sender] == _eventId), "Only the promoter can record event matches");
        //Check that the event has enough matches left. 
        require(allEvents[_eventId].allowedMatches > 0, "This event does not have any matches left");
        //Make sure that the tournament isn't too old. 
        require(allEvents[_eventId].time + 604800 > block.timestamp, "This event is too old");
        //Decrement the allowedMatches
        allEvents[_eventId].allowedMatches = allEvents[_eventId].allowedMatches - 1;
       
        //Record the match. 
        Match memory newMatch;
        newMatch.id = numMatches;
        newMatch.winner = _winner;
        newMatch.winnerPoints = _winnerPoints;
        newMatch.loser = _loser;
        newMatch.loserPoints = _loserPoints;
        newMatch.referee = _referee;
        newMatch.time = uint64 (block.timestamp);
       
        numMatches ++;
        allMatches.push(newMatch);
        
           
        ITAC TAC = ITAC(TACContract);
        
         //Add the match to the athletes and ref
        allUsers[_winner].matches.push(newMatch.id);
        allUsers[_loser].matches.push(newMatch.id);
        allUsers[_referee].matches.push(newMatch.id);
        

        if ((TAC.balanceOf(_loser) >= matchCost) && (TAC.balanceOf(_winner) >= matchCost)) {
            //Transfer the 10 TAC from each athlete. 
            TAC.transferFrom(_loser, creatorAddress, matchCost);
            TAC.transferFrom(_winner, creatorAddress, matchCost);
        
            //Issue TAC
            TAC.awardTAC(_winner, _loser, _referee);
        }
    }

     function getMatch(uint64 _id) public view returns(uint64 id, address winner, uint8 winnerPoints, address loser, uint8 loserPoints, uint64 time, string memory notes, address referee) {

       Match memory matchToGet = allMatches[_id];
       id = matchToGet.id;
       winner = matchToGet.winner;
       winnerPoints = matchToGet.winnerPoints;
       loser = matchToGet.loser;
       loserPoints = matchToGet.loserPoints;
       time = matchToGet.time;
       notes = matchToGet.notes;
       referee = matchToGet.referee;
    }


  /////////////////////////////////////////////////////////EVENT FUNCTIONS  //////////////////////////////////////////////////

    function hostEvent(uint64 startTime, string memory eventName) public {

        Event memory newEvent;
        ITAC TAC = ITAC(TACContract);
        require((allUsers[msg.sender].allowedMatches > 0 || requireMembership == false), "Members must have available allowed matches");
        require(TAC.balanceOf(msg.sender) >= eventHostingCost, "You need to have more TAC to open an event. ");
        TAC.transferFrom(msg.sender, creatorAddress, eventHostingCost);
        newEvent.promoter = msg.sender;
        newEvent.eventName = eventName;
        newEvent.time = startTime;
        newEvent.eventId = numEvents;
        newEvent.allowedMatches = 0;
        allEvents.push(newEvent);
        numEvents += 1;
    }

    function getEvent(uint64 _eventId) public view returns(address promoter, uint64 time, uint64 eventId, string memory eventName, uint16 allowedMatches) {

       Event memory eventToGet = allEvents[_eventId];
       promoter = eventToGet.promoter;
       time = eventToGet.time;
       eventName = eventToGet.eventName;
       eventId = eventToGet.eventId;
       allowedMatches = eventToGet.allowedMatches;   
    }
    
    
    function approveEvent(uint64 _eventId, uint16 _numMatches) public onlyADMINS {
        // Function to allow an event host to approve a specified number of matches.
        allEvents[_eventId].allowedMatches = _numMatches;
     }
    
    //Function a tournament promoter can call to delegate staff to record matches. 
    function addStaff(uint64 _eventId, address _newStaff) public {
        //Check that the tournament promoter is the caller
        require(msg.sender == allEvents[_eventId].promoter, "Only the promoter can add staff");
        tournamentStaff[_newStaff] = _eventId;

    }

}