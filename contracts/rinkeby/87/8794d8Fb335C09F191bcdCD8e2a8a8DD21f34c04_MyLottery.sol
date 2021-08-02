// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Randomizer.sol";

contract MyLottery
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
    
    uint256 public randomNumber;
    
    RandomizerInterface public randomizer = RandomizerInterface(0xaE036c65C649172b43ef7156b009c6221B596B8b);
    
    mapping(uint256 => Lottery) public lotteryById;
    Lottery[] public lotteries;
    uint256[] public lotteryIds;
    uint256 activeLotteryId;
    
    
    function createLottery(string memory name, uint256 lotteryPrice,uint256 _beginningTimeStamp,uint256 _endTimeStamp) 
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
    
    function buyTicket(address participantAddress) public returns(uint256)
    {
        uint256 ticketId = lotteryById[activeLotteryId].participant.length;
        lotteryById[activeLotteryId].participant.push(participantAddress);
        return ticketId;
    }
    
    
    function drawLottery() public
    {
      Lottery memory lottery=lotteryById[activeLotteryId]; 
      require(!lottery.isFinished,'Lottery is Already Completed. Please start new One');
      require(block.timestamp>lottery.endDate,'You must wait until the lottery end date is reaced before selecting teh winner');
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
       Lottery memory lottery=lotteryById[lotteryId];
       return lottery.participant[lottery.winner];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./RandomizerInterface.sol";

// Remember to setup the address of the hydroLottery contract before using it

// Create a contract that inherits oraclize and has the address of the hydro lottery
// A function that returns the query id and generates a random id which calls the hydro lottery
contract Randomizer is RandomizerInterface {
    event QueryRandom(string message);
    event SetHydroLotteryAddress(address _hydroLottery);
     uint256 public randomNumber;

   
    // address public owner;
    // mapping(bytes32 => uint256) public numberOfParticipants;

    // modifier onlyOwner {
    //     require(msg.sender == owner, 'This function can only be executed by the owner of the contract');
    //     _;
    // }

    // modifier onlyHydroLottery {
    //     require(msg.sender == address(hydroLottery), 'This function can only be executed by the Hydro Lottery smart contract');
    //     _;
    // }

    constructor ()  {
        // /* OAR = OraclizeAddrResolverI(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475); */
        // oraclize_setProof(proofType_Ledger);
        // owner = msg.sender;
    }

    // /// @notice Set the address of the hydro lottery contract for communicating with it later
    // /// @param _hydroLottery The address of the lottery contract
    // function setHydroLottery(address _hydroLottery) public onlyOwner {
    //     require(_hydroLottery != address(0), 'The hydro lottery address can only be set by the owner of this contract');
    //     hydroLottery = HydroLotteryInterface(_hydroLottery);
    //     emit SetHydroLotteryAddress(_hydroLottery);
    // }

    /// @notice Starts the process of ending a lottery by executing the function that generates random numbers from oraclize
    /// @return queryId The queryId identifier to associate a lottery ID with a query ID
    function startGeneratingRandom(uint256 _maxNumber) public override payable returns(uint256) {
        randomNumber = (uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, _maxNumber)))%_maxNumber);
        emit GeneratedRandom(_maxNumber,randomNumber);
        return randomNumber ;
    }

   /// @notice Callback function that gets called by oraclize when the random number is generated
   /// @param _queryId The query id that was generated to proofVerify
   /// @param _result String that contains the number generated
   /// @param _proof A string with a proof code to verify the authenticity of the number generation
//   function __callback(
//       bytes32 _queryId,
//       string memory _result,
//       bytes memory _proof
//   ) public {
//       require(msg.sender == oraclize_cbAddress(), 'The callback function can only be executed by oraclize');
//       emit GeneratedRandom(_queryId, numberOfParticipants[_queryId], parseInt(_result));
//       hydroLottery.endLottery(_queryId, parseInt(_result));
//   }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface RandomizerInterface {
    event GeneratedRandom(uint256 _numberOfParticipants, uint256 _generatedRandomNumber);
    ///event QueryRandom(string message);

    //function setHydroLottery(address _hydroLottery) external;
    function startGeneratingRandom(uint256 _maxNumber) external payable returns(uint256);
    //function __callback(bytes32 _queryId, string calldata  _result, bytes calldata _proof) external;
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}