// SPDX-License-Identifier: MIT 
pragma solidity >=0.7.0 <0.9.0;
import "./Election.sol";

contract Club {

    // - - - - - ° - - - - -° - - -° - - --  Static Values for the Contract
    string  public name; 
    address public clubLeader; 
    address public memberLead;
    uint256 private termLength;
    address public immutable ContractAddress;


    // - - - - - °- - - - - -° - - - -° - - Membership 
    Member[] public allMembers;
    //Mapping
    mapping (address => uint256) public memberAdrToID;  

    //how long are the rolles set in unix time 1 year approx 31557600
    uint256 public memberCount;

    // - - - - -  - - - - - - - - - - -- Application Process - - - - - -- - - - - - - - -- 
    //Buffer of max 31-1 wating applicants since index 0 is not included
    Member[31] private applicants;
    uint public applicantsCounter;
    mapping (address => bool) public applicationCheck;
    // 11- memberlead accpet 22- leader accetpt 33- memlead 1 44- lead 1 
    uint private aggreedOnAppl;
    // - - - - -  - - - - - - - - - - -- Election Process
    //Current Elections
    Election public currentElection; 
    address public currentElectionAdr;
    
    Election[] public oldElections;
    uint public oldElectonCount; 



    // - - - - -  - - - - - - - - - - -- Functions 
    constructor(string memory _name){
        allMembers.push();
        //applicants.push(); counter +1 than add not needed
        name = _name;
        ContractAddress = address(this);
        clubLeader = msg.sender;
        //termLength = 3 hours ;
        //memberLead = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
        memberLead = 0x8B9602A60334DA8ab834080880EeAe35a1e7499f;
        termLength = 31557600;//1 year
        
        /*addMember("Lilly Fee");
        addMember("Meister Member", memberLead);
        addMember("Hal Finney",0x9d44197549d6FBe9A695f3d866deC6DEa9d090A5); //account 3 
        addMember("Jackson Palmer",0xf7eBaDa39A818939f5078D1AD8714Ab6C7213Eb0); //account 6 

        //test cases
        applicantsCounter = 0;
        applyForMemberShipTestCase("Donald Duck", 0x32c55F570507B30Ab17f5a6281B5aD1025510aAA); //Account 4
        applyForMemberShipTestCase("Sepp Hochreiter", 0x7dfa72251f71fe95F5137B559505B2F66c43A530); //Account 5
        //applyForMemberShip("Trick Duck ");
        */
    }

    //Structs 
    struct Member{
        string  name;
        address memberAddress;
        //string  personalInfo;
        uint256 joiningDate;
    }
    struct Candidate{
        uint256 voteId;
        string  name;
        address addressCandidate;
        uint    numberVotes; //string  personalInfo;
    }
    
    struct smallCanditate{
        string name;
        uint numberVotes;
    }


    //modifiers 
    modifier onlyMembers(){
        require (memberAdrToID[msg.sender] != 0 , "only Member has access rights to paticipate");
        _;
    }
    modifier memberLeadOnly(){
        require (msg.sender == memberLead, "only Membershipleader has access rights");
        _;
    }

    modifier manageRigthsOnly(){
        require (msg.sender == memberLead || msg.sender==clubLeader , "only Membershipleader has access rights");
        _;
    }
    

    // - - - °- -  - - ° - - - - - - - - -- Elections Process - - - - - -°- - - - -° - - - -- Functions
   function startElection(uint _votingDuraInHours, uint8 typElection) public onlyMembers returns(address){
        currentElection = new Election();
        currentElectionAdr = address(currentElection);
        currentElection.setClubAddress(ContractAddress); 
        currentElection.setEndTime(_votingDuraInHours);
        currentElection.setElectionTyp(typElection);
        //currentElection.setElectionTyp(_votingDuraInHours); 
        return address(currentElection);
    }

    function proposeCandidate(address _candidateAdr) public onlyMembers{
        if (currentElectionAdr != address(0) && memberAdrToID[_candidateAdr] != 0 ){
            currentElection.addCandidate(_candidateAdr, allMembers[memberAdrToID[_candidateAdr]].name );
        }

    }

    function voteCandidate(uint _idOfCandidate) public onlyMembers(){
        currentElection.vote(_idOfCandidate);
    }
    
    function endVote() public onlyMembers{
        currentElection.endVoting();
        uint8 typElection = currentElection.getElectionTyp();
        address winner = currentElection.getWinner();
        if (winner != address(57005)){
            electionResult(typElection,winner);
        }
        oldElections.push(currentElection);
        oldElectonCount++;
        delete currentElection;
    }

    function electionResult(uint8 typeElection, address selectedAddress) private {
        if(typeElection == 1){
            clubLeader = selectedAddress;
        }else if(typeElection == 2){
            memberLead = selectedAddress;
            //remove member afterVote
        }else if(typeElection == 3){
            uint candidateId = currentElection.getCanIdByAddr(selectedAddress);
            uint numberVotes = currentElection.getCandidateVotesById(candidateId);
            if (2*numberVotes > memberCount ){
                delete allMembers[memberAdrToID[selectedAddress]];
        }
        }
    }
 
    
    // - - - °- -  - - ° - - - - - - - - -- Elections Show - - - - - -°- - - - -° - - - -- Functions Show 
    
    /*function showMemCandidates() private returns(Member[] memory ){
        uint numberCandidates = currentElection.candidateCount();
        Member[] memory candidatesReturn =  new Member[](numberCandidates);
        for(uint256 i=1; i < numberCandidates+1; i++){
            address addr = currentElection.getCandidate(i).canAddress;
            candidatesReturn[i-1] = (allMembers[memberAdrToID[addr]]);
        }
        return candidatesReturn;
    }*/

    function showVotes() public view returns(smallCanditate[] memory ){
        uint numberCandidates = currentElection.candidateCount();
        smallCanditate[] memory candidatesReturn =  new smallCanditate[](numberCandidates);
        for(uint256 i=1; i < numberCandidates+1; i++){
            //uint iD = currentElection.getCandidate(i).voteID
            address addr = currentElection.getCandidate(i).canAddress;
            string memory nameSmallCan = allMembers[memberAdrToID[addr]].name;
            uint numberVotes = currentElection.getCandidate(i).numberVotes;
            candidatesReturn[i-1] = (smallCanditate(nameSmallCan,numberVotes));
        }
        return candidatesReturn;
    }
/*
    function showCandidates() public view returns(Candidate[] memory ){
        uint numberCandidates = currentElection.candidateCount();
        Candidate[] memory candidatesReturn =  new Candidate[](numberCandidates);
        for(uint256 i=1; i < numberCandidates+1; i++){
            uint iD = currentElection.getCandidate(i).voteId;
            address addr = currentElection.getCandidate(i).canAddress;
            string memory nameCan = allMembers[memberAdrToID[addr]].name;
            uint numberVotes = currentElection.getCandidate(i).numberVotes;

            candidatesReturn[i-1] = (Candidate(iD,nameCan,addr,numberVotes));

        }
        return candidatesReturn;
    }
    */
    function showElectionTime() public view returns(uint){
        return currentElection.getEndTime();
    }

    function getWinner() public view returns(address){
        return currentElection.getWinner();
    }

   /* function getElectionTyp() public view returns( string memory){
        uint8 electId =  currentElection.getElectionTyp();
        if(electId == 1){
            return "Typ 1: club leader election ";
        }else if(electId == 2){
            return "Typ 2: club meber leader election ";
        }else if(electId == 3){
            return "Typ 3: kick member address ";
        }else{
            return "Typ ? no eleciton";
        }
    }
    */
    // - - - °- -  - - ° - - - - - - - - -- Application Proces - - - - - -°- - - - -° - - - -- Functions
    function applyForMemberShip(string memory _name) public {
        require(applicantsCounter<30, "too many applicants at the moment");
        require(applicationCheck[msg.sender] == false,"you allready applied for the club");
        applicantsCounter++;
        applicants[applicantsCounter] = Member(_name,msg.sender,block.timestamp);
        applicationCheck[msg.sender] = true;
    }
    function getApplicants() public view returns (Member[] memory ){
        Member[] memory retApp = new Member[](applicantsCounter);
        for (uint256 i= 1; i<applicantsCounter+1; i++){
            retApp[i-1]= applicants[i];
        }
        return retApp;
    }

    function acceptLastApplicant(address _lastApplicantsAdr) private {
        require (applicants[applicantsCounter].memberAddress == _lastApplicantsAdr, 'Adress does not match!');
        addMember(applicants[applicantsCounter].name, applicants[applicantsCounter].memberAddress);
        applicantsCounter--;
    }
    
    function voteAcceptAllApplicants() public manageRigthsOnly() {
        require(applicantsCounter > 0, "1-no applicants for the club");
        if(msg.sender == clubLeader){
            if(11 == aggreedOnAppl ){
                acceptAllApplicants();
                aggreedOnAppl = 0;
            }else{
                aggreedOnAppl = 22;
            }
        }else if(msg.sender == memberLead){
            if(22 == aggreedOnAppl  ){
                acceptAllApplicants();
                aggreedOnAppl = 0;
            }else{
                aggreedOnAppl = 11; 
            }
        }
    }

    function voteAcceptLastApplicant(address _lastApplicantsAdr) public manageRigthsOnly() {
        require(applicantsCounter > 0, "2-no applicants for the club");
        if(msg.sender == clubLeader){
            if (11 == aggreedOnAppl || aggreedOnAppl == 33 ){
                acceptLastApplicant(_lastApplicantsAdr);
                aggreedOnAppl = 0;
            }else{
                aggreedOnAppl = 44;
            }
        }else if(msg.sender == memberLead){
            if(22 == aggreedOnAppl || aggreedOnAppl == 44 ){
                acceptLastApplicant(_lastApplicantsAdr);
                aggreedOnAppl = 0;
            }else{
                aggreedOnAppl = 33; 
            }
        }
    }

    function acceptAllApplicants() private {
        for (uint256 i= applicantsCounter; applicantsCounter> 0; i--){
            addMember(applicants[i].name, applicants[i].memberAddress);
            applicantsCounter--;
        }

    }  

    function denyLastApplicant(address _lastApplicantsAdr) public manageRigthsOnly() {
        require (applicants[applicantsCounter].memberAddress == _lastApplicantsAdr, 'Adress does not match!');
        require(applicantsCounter > 0, 'No applicants in queue!');
        applicantsCounter--; 
    } 
    
    // - - - - - ^  - - - - ^ - - - -^ - - -- Application Proces - - -^ - - - -  ^- - - - - ^- - -- Functions

  


   


    // - - - °- -  - - ° - - - - - - - - -- MemberMangement - - - - - -°- - - - -° - - - -- Functions
    function addMember(string memory _name ) private {
        memberCount++; 
        allMembers.push(Member(_name, tx.origin, block.timestamp ));
        memberAdrToID[tx.origin] = memberCount;
    
    }

    function addMember(string memory _name, address _memberAddress) private {
        memberCount++; 
        allMembers.push(Member(_name, _memberAddress, block.timestamp ));
        memberAdrToID[_memberAddress] = memberCount;
    }

    function getMemberAdd(address _addressMember) private view returns(uint ) {
        return memberAdrToID[_addressMember]; 
    }

    function getMembers() public view returns (Member[] memory ){
        Member[] memory retApp = new Member[](memberCount);
        for (uint256 i= 1; i<memberCount+1; i++){
            retApp[i-1]= allMembers[i];
        }
        return retApp;
    }
    // - - - - - ^  - - - - ^ - - - -^ - - -- MemberManagement - - -^ - - - -  ^- - - - - ^- - -- Functions


    // - - - °- -  - - ° - - - - - - - - - - Test Function - - - - - -°- - - - -° - - - -- Functions
    function applyForMemberShipTestCase(string memory _name, address _memberAddress) private {
        require(applicantsCounter<30, "too many applicants at the moment contact");
        require(applicationCheck[_memberAddress] == false,"address allready applied");
        applicantsCounter++;
        applicants[applicantsCounter] = Member(_name,_memberAddress,block.timestamp);
        applicationCheck[_memberAddress] = true;
    }

    function Test1Case() public{
        addMember("Lilly Fee"); //acc 1
        addMember("Meister Member", memberLead); //acc 2
        addMember("Hal Finney",0x9d44197549d6FBe9A695f3d866deC6DEa9d090A5); //account 3 
        addMember("Jackson Palmer",0xf7eBaDa39A818939f5078D1AD8714Ab6C7213Eb0); //account 6 

    }
    function StartTestElecion() public{
        //test cases
        applyForMemberShipTestCase("Donald Duck", 0x32c55F570507B30Ab17f5a6281B5aD1025510aAA); //Account 4
        applyForMemberShipTestCase("Sepp Hochreiter", 0x7dfa72251f71fe95F5137B559505B2F66c43A530); //Account 5
        //applyForMemberShip("Trick Duck ");
    
        require(currentElectionAdr == address(0));
        startElection(10, 2); //in hours 
        proposeCandidate(0x9d44197549d6FBe9A695f3d866deC6DEa9d090A5);// "Hal Finney"); //account 3 
        proposeCandidate(0xf7eBaDa39A818939f5078D1AD8714Ab6C7213Eb0); //"Jackson Palmer"); //account 6
    }

}