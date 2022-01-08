// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IGame {
    function isUserGov(address _user) external view returns(bool);
    function withdrowGov()external;
}

contract Gov {

    struct Voter{
        bool voted;
    }

    struct Proposal {
        uint256 proposalID;
        uint voteCount; // number of accumulated votes
        address maker;
    }

    struct Event {

        uint256 eventId; //Identifier of the events

        uint256 prize;

        uint256 startTime; //event start
        uint256 endTime; //End Time

        uint256 proposalsVotes;


        uint256 propIdCounter; //default value is 0

        Proposal [] proposals;
        uint256 [] winnersIndexs;

     }

    address public admin;
    address public operator;

    uint256 public fee;
    uint256 public currentEvent; //Id of the current Event

    bool public genesisEventIsStarted;


    uint256 public eventPeriod;
    uint256 public bufferSeconds;

    mapping(uint256 => mapping (uint256 =>mapping (address=> Voter))) public proposalsVoter;
    mapping (uint256 => Event) public events;

    IGame [] public games;

    modifier onlyOperator() {
        require(msg.sender == operator, "operator");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "not admin");
        _;
    }

    constructor (uint256 _eventPeriod, uint256 _bufferSeconds, uint256 _fee, address _admin, address _operator){
        fee = _fee;
        eventPeriod = _eventPeriod;
        bufferSeconds = _bufferSeconds;
        admin = _admin;
        operator = _operator;
    }


    function addGame(address _game)external  onlyAdmin{
        games.push(IGame(_game));
    }

    //start the first event
    function startGenesisEvent() external onlyOperator{
        require(!genesisEventIsStarted, "can only run the genesis Event once.");
        _safeStartEvent();
        genesisEventIsStarted = true;
    }



    //it starts the next event
    function executeEvent()external onlyOperator{
            _safeLockEvent();
            currentEvent++;
            _safeStartEvent();

    }

    function _setWinners() internal{
        Proposal [] memory proposals = events[currentEvent].proposals;
        Event storage eventi = events[currentEvent];

        uint256 temp = 0;
        for (uint256 i = 0; i < proposals.length; i++){
            if(proposals[i].voteCount > temp){
                temp = proposals[i].voteCount;
            }
        }

        for (uint256 i = 0; i < proposals.length; i++){
            if(proposals[i].voteCount == temp){
                eventi.winnersIndexs.push(i);
            }
        }



    }


    function _safeLockEvent() internal{
        require( genesisEventIsStarted, "genesis event has to be started");
        require(block.timestamp <= events[currentEvent].endTime + bufferSeconds
           && block.timestamp >= events[currentEvent].endTime
            , "can only run within the buffer Seconds");
        require(events[currentEvent].prize == 0, "prize already Closed for this event.");


        _setWinners();

        Event storage eventi = events[currentEvent];
        eventi.prize = (address(this).balance/10000) * 7500; //75% of the balance will be the prizes.


        uint256 [] memory winnersIndex = eventi.winnersIndexs;

        uint256 rewardPerWinner = events[currentEvent].prize / winnersIndex.length;


        for (uint i=0;  i<winnersIndex.length;  i++){
            address winner = events[currentEvent].proposals[winnersIndex[i]].maker;
            _safeTransfer(winner, rewardPerWinner);
        }

    }

    function _safeTransfer(address to, uint256 value) internal {
      (bool success, )  = to.call{value: value}("");
      require(success , "Transfer Failed.");
    }


    function _withdrowGames() internal{
        for (uint256 i = 0; i< games.length; i++){
            games[i].withdrowGov();
        }
    }

    function _safeStartEvent()internal {
      require(events[currentEvent].eventId == 0 && events[currentEvent].startTime == 0, "event Ids have to be uniqe");
      if (games.length > 0){
        _withdrowGames();
      }

      Event storage eventi = events[currentEvent];
      eventi.eventId = currentEvent;
      eventi.startTime = block.timestamp;
      eventi.endTime = block.timestamp + eventPeriod;


    }

    function addProp (uint256 _eventId) external  payable{
        //require(msg.value >= fee, "Fee is too low");
        require(
                block.timestamp >= events[_eventId].startTime
            &&  block.timestamp <= events[_eventId].endTime ,
                "can vote only add propsals during the event.");


        Event storage eventi = events[_eventId];
        Proposal memory proposal = Proposal(events[_eventId].propIdCounter, 0, msg.sender);
        eventi.proposals.push(proposal);
        eventi.propIdCounter += 1;
    }
    function voteOnProposal (uint256 _eventId, uint256 _propId) external payable{
        //(msg.value >= fee, "Fee is too low");
        require(
                block.timestamp > events[_eventId].startTime
            &&  block.timestamp <= events[_eventId].endTime ,
                "can vote only in the right timing.");
        require(!proposalsVoter[_eventId][_propId][msg.sender].voted, "can only vote once on proposals.");
        Voter storage voter = proposalsVoter[_eventId][_propId][msg.sender];
        Proposal storage proposal = events[_eventId].proposals[_propId];
        proposal.voteCount++;
        voter.voted = true;
    }
    function getProposals(uint256 _eventID,uint256 _propID) external view returns (uint256 _voteCount, address _maker, uint256 _proposalID){
        _voteCount = events[_eventID].proposals[_propID].voteCount;
        _maker = events[_eventID].proposals[_propID].maker;
        _proposalID = events[_eventID].proposals[_propID].proposalID;
    }
     function getWinningProposals(uint256 _eventID) external view returns (uint256 [] memory _winningProps){
        require(events[_eventID].endTime != 0, "event didnt finish yet.");
        _winningProps = events[_eventID].winnersIndexs;
    }
    function currentPool()external view returns(uint256){
        return address(this).balance;
    }
    fallback() external payable{
    }
    receive() external payable{
    }

}