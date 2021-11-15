// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Randomizer.sol";
import './Ownable.sol';

contract MyLottery is Ownable
{
    event LotteryStarted(uint256 indexed id, uint256 beginningDate, uint256 endDate);
    event LotteryEnded(uint256 indexed id, uint256 endTimestamp, uint256 einWinner);
    
    struct Lottery{
        bool isFinished;
        bool exists;
        uint256 id;
        string name;
        uint256 price;
        uint256 beginningDate;
        uint256 endDate;
        address[]  participant;
        uint256 winner;
    }
    
    RandomizerInterface private randomizer = RandomizerInterface(0x1bBb5C45a12F801f39103FF8C0c36f8628018c16);
    
    mapping(uint256 => Lottery) public lotteryById;
    Lottery[] public lotteries;
    uint256[] public lotteryIds;
    uint256 public activeLotteryId;
    
    
    function createLottery(string memory name, uint256 lotteryPrice,uint256 _beginningTimeStamp,uint256 _endTimeStamp) onlyOwner 
    public returns(uint256)
    {
        uint256 newLotteryId = lotteries.length;
        activeLotteryId=newLotteryId;
        require( _endTimeStamp > _beginningTimeStamp, 'The lottery must end after the start not earlier');
        Lottery memory newLottery = Lottery(
            {
            isFinished:false,
            exists:true,
            id:newLotteryId,
            name:name,
            price:lotteryPrice,
            beginningDate:_beginningTimeStamp,
            endDate:_endTimeStamp,
            participant:new address[](0),
            winner:0
            });
            
        lotteries.push(newLottery);
        lotteryById[newLotteryId] = newLottery;
        lotteryIds.push(newLotteryId);
        emit LotteryStarted(newLotteryId, _beginningTimeStamp, _endTimeStamp);
        return newLotteryId;
    }
    
    function buyTicket(address participantAddress) public onlyOwner returns(uint256)
    {
        require(participantAddress != address(0), 'ParticipantAddress cannot Be Zero');
        require(!lotteryById[activeLotteryId].isFinished,'Wait Until Admin Started Lottery');
        uint256 ticketId = lotteryById[activeLotteryId].participant.length;
        lotteryById[activeLotteryId].participant.push(participantAddress);
        return ticketId;
    }
    
    
    function drawLottery() onlyOwner public
    {
      Lottery storage lottery=lotteryById[activeLotteryId]; 
      require(!lottery.isFinished,'Lottery is Already Completed. Please start new One');
      require(block.timestamp>lottery.endDate,'You must wait until the lottery end date is reached before selecting the winner');
      uint256 numberOfParticipants = lottery.participant.length;
      lottery.winner=randomizer.startGeneratingRandom(numberOfParticipants);
      lottery.isFinished= true;
      emit LotteryEnded(activeLotteryId, block.timestamp, lottery.winner);
    }
    
     function getLotteryIds() public view returns(uint256[] memory) {
        return lotteryIds;
    } 
    
    function getWinnerByLotteryId(uint256 lotteryId) public view returns (address)
    {
       require(lotteryById[lotteryId].isFinished,'Lottery must be finished to get winner');
       Lottery memory lottery=lotteryById[lotteryId];
       return lottery.participant[lottery.winner];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./RandomizerInterface.sol";

contract Randomizer is RandomizerInterface {
   
     uint256 public randomNumber;

 
    /// @notice Starts the process of ending a lottery by executing the function that generates random numbers from oraclize
    /// @return queryId The queryId identifier to associate a lottery ID with a query ID
    function startGeneratingRandom(uint256 _maxNumber) public override payable returns(uint256) {
        randomNumber = (uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, _maxNumber)))%_maxNumber);
        emit GeneratedRandom(_maxNumber,randomNumber);
        return randomNumber ;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Ownable
{
  address private _owner;
  
  event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

   constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }
    
    function owner() public view returns(address) {
        return _owner;
    }
    
    modifier onlyOwner() {
        require(isOwner());
        _;
    }
    
    function isOwner() public view returns(bool) {
        return msg.sender == _owner;
    }
    
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }
    
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface RandomizerInterface {
    event GeneratedRandom(uint256 _numberOfParticipants, uint256 _generatedRandomNumber);
    function startGeneratingRandom(uint256 _maxNumber) external payable returns(uint256); 
}

