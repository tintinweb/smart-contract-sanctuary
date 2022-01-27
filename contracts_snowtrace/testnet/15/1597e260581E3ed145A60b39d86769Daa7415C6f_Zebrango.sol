// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Pausable.sol";
import "./IZGame.sol";
import "./Ownable.sol";

/***********************************
Zebrango Protocol
************************************/

contract Zebrango is Pausable, Ownable{

    struct Voter{
        bool voted;
    }


    struct Proposal {
        uint256 proposalId; // Identifier of the proposal
        uint voteCount; // number of accumulated votes
        address maker;
    }

    struct Event {
        uint256 eventId; //Identifier of the event
        uint256 prize;  //the prize collected

        uint256 startTime; //event start
        uint256 endTime; //End Time

        uint256 propIdCounter; // to keep track of the proposals

        Proposal [] proposals; // the proposals list
        uint256 [] winnersIndexs; // the winners

     }

    address public admin; //admin address
    address public operator; //operator address


    uint256 public currentEvent; //Id of the current Event

    bool public genesisEventIsStarted;


    uint256 public eventPeriod;
    uint256 public bufferSeconds;

    uint256 public participationFee;

    //mapping Document (eventID => proposalID => address => voter of a proposal)
    mapping(uint256 => mapping (uint256 =>mapping (address=> Voter))) public proposalsVoter;

    //mapping Events (EventID => Event)
    mapping (uint256 => Event) public events;


    IGame [] public games;    //lotteries added to the protokol


    event AddGame(address indexed _game);
    event LockEvent(uint256 indexed _eventID, uint256 indexed _timestamp, uint256 indexed _prize, uint256 _rewardPerWinner);
    event StartEvent(uint256 indexed _eventID, uint256 indexed _timestamp);
    event AddProp(uint256 indexed _eventID, address indexed _maker);
    event NewAdminAddress(address admin);
    event NewOperatorAddress(address operator);
    event NewBufferAndEventPeriod(uint256 bufferSeconds, uint256 _eventPeriod);
    event VoteOnProposal(uint256 indexed _eventID, uint256 indexed _propID);
    event NewFee(uint256 Fee);




    modifier onlyOperator() {
        require(msg.sender == operator, "operator");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "not admin");
        _;
    }

    constructor (uint256 _eventPeriod, uint256 _bufferSeconds, address _admin, address _operator, uint256 _participationFee){
        eventPeriod = _eventPeriod;
        bufferSeconds = _bufferSeconds;
        admin = _admin;
        operator = _operator;
        participationFee= _participationFee;
    }

    function setParticipationFee(uint256 _fee) external whenPaused onlyAdmin {
        participationFee = _fee;
        emit NewFee(participationFee);
    }
    function setAdmin(address _adminAddress) external onlyOwner {
    require(_adminAddress != address(0), "Cannot be zero address");
    admin = _adminAddress;

    emit NewAdminAddress(_adminAddress);
  }
  function setOperator(address _operatorAddress) external onlyAdmin {
  require(_operatorAddress != address(0), "Cannot be zero address");
  operator = _operatorAddress;

  emit NewOperatorAddress(_operatorAddress);
  }

  function setBufferAndeventPeriod(uint256 _bufferSeconds, uint256 _eventPeriod)
         external
         whenPaused
         onlyAdmin
     {
         require(_bufferSeconds < _eventPeriod, "bufferSeconds must be inferior to intervalSeconds");
         bufferSeconds = _bufferSeconds;
         eventPeriod = _eventPeriod;

         emit NewBufferAndEventPeriod(_bufferSeconds, _eventPeriod);
     }

    //adding new game to the protokol
    function addGame(address _game)external  onlyAdmin whenNotPaused{
        games.push(IGame(_game));
        emit AddGame(_game);

    }

    //start the first event
    function startGenesisEvent() external onlyOperator whenNotPaused{
      require(!genesisEventIsStarted, "can only start the gensis once");
        genesisEventIsStarted = true;

        currentEvent = currentEvent + 1;
        _safeStartEvent(currentEvent);

    }



    //excecute Event: notice it locks the current event, and starts the next event
    function executeEvent()external onlyOperator whenNotPaused{

            _safeLockEvent(currentEvent);
            currentEvent = currentEvent + 1;
            _safeStartEvent(currentEvent);

    }

    //setting the winners
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


    function _safeLockEvent(uint256 _eventID) internal {
        require( genesisEventIsStarted, "genesis event has to be started");
        require(block.timestamp <= events[_eventID].endTime + bufferSeconds
           && block.timestamp >= events[_eventID].endTime
            , "can only run within the buffer Seconds");

        require(events[_eventID].winnersIndexs.length==0 , "winners already set.");

        _setWinners();
        Event storage eventi = events[_eventID];
        uint256 prize =  eventi.prize;
        uint256 rewardPerWinner = 0;

        if (prize > 0){

           uint256 [] memory winnersIndex = eventi.winnersIndexs;
           rewardPerWinner = prize / winnersIndex.length;

            for (uint i=0;  i<winnersIndex.length;  i++){
               address winner = events[_eventID].proposals[winnersIndex[i]].maker;
              _safeTransfer(winner, rewardPerWinner);
            }
        }
        emit LockEvent(_eventID, block.timestamp, prize, rewardPerWinner);
    }

    function _safeTransfer(address to, uint256 value) internal {
      (bool success, )  = to.call{value: value}("");
      require(success , "Transfer Failed.");
    }


    function _withdrowGames(uint256 _eventID) internal{
      uint256 addedRewards;
        for (uint256 i = 0; i< games.length; i++){
            addedRewards = addedRewards + games[i].withdrowGov();
        }
        events[_eventID].prize = events[_eventID].prize + addedRewards;
    }

    function _safeStartEvent(uint256 _eventID)internal {
      require(events[_eventID].eventId == 0 && events[_eventID].startTime == 0, "event Ids have to be uniqe");
      if (games.length > 0){
        _withdrowGames(_eventID);
      }

      Event storage eventi = events[_eventID];
      eventi.eventId = currentEvent;
      eventi.startTime = block.timestamp;
      eventi.endTime = block.timestamp + eventPeriod;
      emit StartEvent(_eventID, block.timestamp);
     }

    function addProp (uint256 _eventId) external  payable whenNotPaused{
        require(msg.value == participationFee, "the amount should be higher than the participationFee");
        require(!hasParticipated(_eventId));
        require(
                block.timestamp >= events[_eventId].startTime
            &&  block.timestamp <= events[_eventId].endTime ,
                "can vote only add propsals during the event.");

        //modifing storage state, event instance
        Event storage eventi = events[_eventId];

        eventi.prize = eventi.prize + msg.value;

        Proposal memory proposal = Proposal(
                                    events[_eventId].propIdCounter,
                                    0,
                                    msg.sender);

        eventi.proposals.push(proposal);
        eventi.propIdCounter += 1;
        emit AddProp(_eventId, msg.sender);
    }
    function voteOnProposal (uint256 _eventId, uint256 _propId) external payable whenNotPaused{
      require(msg.value == participationFee, "the amount should be higher than the participationFee");
        require(
                block.timestamp > events[_eventId].startTime
            &&  block.timestamp <= events[_eventId].endTime ,
                "can vote only in the right timing.");
        require(!proposalsVoter[_eventId][_propId][msg.sender].voted, "can only vote once on proposals.");
        Voter storage voter = proposalsVoter[_eventId][_propId][msg.sender];
        Proposal storage proposal = events[_eventId].proposals[_propId];
        events[_eventId].prize = events[_eventId].prize + msg.value;

        proposal.voteCount++;
        voter.voted = true;
        emit VoteOnProposal(_eventId, _propId);
    }
    function getProposals(uint256 _eventID,uint256 _propID) external view returns (uint256 _voteCount, address _maker, uint256 _proposalID){
        _voteCount = events[_eventID].proposals[_propID].voteCount;
        _maker = events[_eventID].proposals[_propID].maker;
        _proposalID = events[_eventID].proposals[_propID].proposalId;
    }
     function getWinningProposals(uint256 _eventID) external view returns (uint256 [] memory _winningProps){
        require(events[_eventID].endTime != 0, "event didnt finish yet.");
        _winningProps = events[_eventID].winnersIndexs;
    }
    function currentPool()external view returns(uint256){
        return events[currentEvent].prize;
    }

    function pause() external whenNotPaused onlyOperator {
        _pause();

    }
    function unpause() external whenPaused onlyOperator {
     genesisEventIsStarted = false;
     _unpause();
    }
    function hasParticipated(uint256 _eventID) public view returns (bool){
        Proposal [] memory proposals = events[_eventID].proposals;
        for (uint i=0;i<proposals.length;i++){
            if(msg.sender == proposals[i].maker){
                return true;
            }
        }

        return false;


    }
    fallback() external payable{
    }
    receive() external payable{
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./Context.sol";



pragma solidity ^0.8.0;

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGame {
    function isUserGov(address _user) external view returns(bool);
    function withdrowGov()external returns(uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}