contract Raffle {
  uint private chosenNumber;
  address private winnerParticipant;
  uint8 maxParticipants;
  uint8 minParticipants;
  uint8 joinedParticipants;
  address organizer;
  bool raffleFinished = false;
  address[] participants;
  mapping (address => bool) participantsMapping;
  event ChooseWinner(uint _chosenNumber,address winner);
  event RandomNumberGenerated(uint);
  constructor() public {
    address _org = msg.sender; 
    uint8 _min = 2; 
    uint8 _max = 10; 
    require(_min < _max && _min >=2 && _max <=50);
    organizer = _org;
    chosenNumber = 999;
    maxParticipants = _max;
    minParticipants = _min;
  }
function() public payable {}
function joinraffle() public {
    require(!raffleFinished);
    require(msg.sender != organizer);
    require(joinedParticipants + 1 < maxParticipants);
    require(!participantsMapping[msg.sender]);
    participants.push(msg.sender);
    participantsMapping[msg.sender] = true;
    joinedParticipants ++;
  }
function chooseWinner(uint _chosenNum) internal{
    chosenNumber = _chosenNum;
    winnerParticipant = participants[chosenNumber];
    emit ChooseWinner(chosenNumber,participants[chosenNumber]);
}
function generateRandomNum() public {
    require(!raffleFinished);
    require(joinedParticipants >=minParticipants && joinedParticipants<=maxParticipants);
    raffleFinished=true;
    
    chooseWinner(0); //We&#39;ll replace this with a call to Oraclize service later on.
}
function getChosenNumber() public view returns (uint) {
    return chosenNumber;
  }
function getWinnerAddress() public view returns (address) {
    return winnerParticipant;
  }
function getParticipants() public view returns (address[]) {
    return participants;
  }
}