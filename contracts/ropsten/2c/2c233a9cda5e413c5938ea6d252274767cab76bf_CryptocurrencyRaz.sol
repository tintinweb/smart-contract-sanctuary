pragma solidity 0.4.24;

library SafeMath {
  function mul(uint a, uint b) internal pure returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal pure returns (uint) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }
}
contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}
contract CryptocurrencyRaz is Ownable {
    
    using SafeMath for uint256;
    
    uint public numberOfRazzes = 3;
    uint idCounter = 1;
    struct RazInformation
    {
        uint razInstance;
        uint winningBet;
        address winningAddress;
        address[] allLosers;
        uint timestamp;
        uint id;
    }
    
    struct previousBets
    {
        uint timestamp;
        uint[] bets;
    }
    mapping(uint=>mapping(uint=>RazInformation)) public RazInstanceInformation;
    mapping(uint=>mapping(uint=>mapping(address=>previousBets))) public userBetsInEachRazInstance;
    
    mapping(uint=>uint) public runningRazInstance;
   
    mapping(uint=>bool) public razCompletion;
    mapping(uint=>mapping(uint=>address)) public numbersTaken;
    mapping(uint=>uint) public maxBetsForEachRaz;
    mapping(uint=>uint256) public participationFeeForEachRaz;
    mapping(uint=>uint256) public winnerPrizeMoneyForEachRaz;
    mapping(uint=>uint256) public ownerPrizeMoneyForEachRaz;
    mapping(uint=>string) public razName;
    mapping (address=>uint[]) public pastWinnings;
    mapping (address=>uint[]) public pastLosings;
    
    
    uint[] razList;
    uint[] empty;
    
    uint[] winOrLoseArray;
    uint WinOrLoseNumber;
    previousBets aBet;
    address[] losers;
    
    RazInformation information;
    
    event BetPlaced(address gambler, string razName, uint[] bets);
    event BetWon(address gambler, string razName, uint betNum, uint razNumber, uint razInstance);
    event allBetsPlaced(uint[] b);
    uint[] bb;
    
    constructor(address _owner) public 
    {
        owner = _owner;
        Setup();
    }
    
    function Setup() internal {
        maxBetsForEachRaz[1] = 10;
        maxBetsForEachRaz[2] = 20;
        maxBetsForEachRaz[3] = 10;
        
        razName[1] = "Mighty genesis";
        razName[2] = "Second titan";
        razName[3] = "Trinity affair";
        
        participationFeeForEachRaz[1] = 3 * 10 ** 16;
        participationFeeForEachRaz[2] = 1 * 10 ** 16;
        participationFeeForEachRaz[3] = 1 * 10 ** 16;
        
        winnerPrizeMoneyForEachRaz[1] = 21 * 10 ** 16;
        winnerPrizeMoneyForEachRaz[2] = 15 * 10 ** 16;
        winnerPrizeMoneyForEachRaz[3] = 7 * 10 ** 16;
        
        ownerPrizeMoneyForEachRaz[1] = 9 * 10 ** 16;
        ownerPrizeMoneyForEachRaz[2] = 5 * 10 ** 16;
        ownerPrizeMoneyForEachRaz[3] = 3 * 10 ** 16;
        
        runningRazInstance[1] = 1;
        runningRazInstance[2] = 1;
        runningRazInstance[3] = 1;
    }
    
    function EnterBetsForRaz(uint razNumber, uint[] bets) public payable
    {
        require(razNumber>=1 && razNumber<=numberOfRazzes);
        uint numBets = bets.length;     //finding the numbers of bets the user has placed
        require(msg.value>=participationFeeForEachRaz[razNumber].mul(numBets));    //user has to pay according to the number of bets placed
        require(razCompletion[razNumber] == false);
        uint instance = runningRazInstance[razNumber];
        bb = userBetsInEachRazInstance[razNumber][instance][msg.sender].bets;
        for (uint i=0;i<numBets;i++)
        {
            require(numbersTaken[razNumber][bets[i]] == 0);
            require(bets[i]>=1 && bets[i]<=maxBetsForEachRaz[razNumber]);
            numbersTaken[razNumber][bets[i]] = msg.sender;
            bb.push(bets[i]);
        }
        aBet.bets = bb;
        aBet.timestamp = now;
        userBetsInEachRazInstance[razNumber][instance][msg.sender] = aBet;
        MarkRazAsComplete(razNumber);
       
        emit BetPlaced(msg.sender,razName[razNumber],bets);
    }
    
    function MarkRazAsComplete(uint razNumber) internal returns (bool)
    {
        require(razNumber>=1 && razNumber<=numberOfRazzes);
        for (uint i=1;i<=maxBetsForEachRaz[razNumber];i++)
        {
            if (numbersTaken[razNumber][i] == 0)
            return false;
        }
        razCompletion[razNumber] = true;
        uint randomNumber = uint8(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty)))%maxBetsForEachRaz[razNumber]);
        randomNumber = randomNumber.add(1);
        declareWinnerForRaz(razNumber,randomNumber);
        return true;
    }
   
    function getAvailableNumbersForRaz (uint razNumber) public returns (uint[])
    {
        require(razNumber>=1 && razNumber<=numberOfRazzes);
        razList = empty;
        for (uint i=1;i<=maxBetsForEachRaz[razNumber];i++)
        {
            if (numbersTaken[razNumber][i] == 0)
                razList.push(i);
        }
        return razList;
    }
    
    function resetRaz(uint razNumber,address winningAddress, uint winningNumber) internal 
    {
        delete losers;
        
        bool isRepeat;
        for (uint i=1;i<=maxBetsForEachRaz[razNumber];i++)
        {
            isRepeat = false;
            if (numbersTaken[razNumber][i] == winningAddress && i == winningNumber)
            {
                winOrLoseArray = pastWinnings[numbersTaken[razNumber][i]];
                winOrLoseArray.push(razNumber);
                pastWinnings[numbersTaken[razNumber][i]] = winOrLoseArray;
            }
            else
            {
                if (numbersTaken[razNumber][i] != winningAddress)
                {
                    for (uint j=0;j<losers.length;j++)
                    {
                        if (numbersTaken[razNumber][i] == losers[j])
                            isRepeat = true;
                    }
                    if (!isRepeat)
                    {
                        winOrLoseArray = pastLosings[numbersTaken[razNumber][i]];
                        winOrLoseArray.push(razNumber);
                        pastLosings[numbersTaken[razNumber][i]] = winOrLoseArray;
                        losers.push(numbersTaken[razNumber][i]);
                    }
                }
            }
            numbersTaken[razNumber][i]=0;
        }   
        razCompletion[razNumber] = false;
        uint thisInstance = runningRazInstance[razNumber];
        information = RazInformation({razInstance:thisInstance, winningBet: winningNumber, winningAddress: winningAddress,allLosers: losers, timestamp:now, id:idCounter});
        idCounter = idCounter.add(1);
        RazInstanceInformation[razNumber][thisInstance] = information;
        runningRazInstance[razNumber] = runningRazInstance[razNumber].add(1);
    }
    
    function declareWinnerForRaz(uint razNumber,uint winningNumber) internal
    {
        require(razNumber>=1 && razNumber<=numberOfRazzes);
        require(razCompletion[razNumber] == true);   
        address winningAddress =  numbersTaken[razNumber][winningNumber];
        winningAddress.transfer(winnerPrizeMoneyForEachRaz[razNumber]);
        owner.transfer(ownerPrizeMoneyForEachRaz[razNumber]);
        emit BetWon(winningAddress,razName[razNumber],winningNumber,razNumber,runningRazInstance[razNumber]);
        resetRaz(razNumber,winningAddress,winningNumber);
    }
    
    function GetUserBetsInRaz(address userAddress, uint razNumber) public returns (uint[])
    {
        require(razNumber>=1 && razNumber<=numberOfRazzes);
        razList = empty;
        for (uint i=1;i<=maxBetsForEachRaz[razNumber];i++)
        {
            if (numbersTaken[razNumber][i]==userAddress)
                razList.push(i);
        }   
        return razList;
    }
    function changeParticipationFeeForRaz(uint razNumber,uint participationFee) public onlyOwner 
    {
        require(razNumber>=1 && razNumber<=numberOfRazzes);
        participationFeeForEachRaz[razNumber] = participationFee;
    }
    
     function changeWinnerPrizeMoneyForRaz(uint razNumber,uint prizeMoney) public onlyOwner 
     {
        require(razNumber>=1 && razNumber<=numberOfRazzes);
        winnerPrizeMoneyForEachRaz[razNumber] = prizeMoney;
    }
    
    function addNewRaz(uint maxBets, uint winningAmount, uint ownerAmount, uint particFee, string name) public onlyOwner returns (uint) 
    {
        require(maxBets.mul(particFee) == winningAmount.add(ownerAmount));
        numberOfRazzes = numberOfRazzes.add(1);
        maxBetsForEachRaz[numberOfRazzes] = maxBets;
        participationFeeForEachRaz[numberOfRazzes] = particFee;
        winnerPrizeMoneyForEachRaz[numberOfRazzes] = winningAmount;
        ownerPrizeMoneyForEachRaz[numberOfRazzes] = ownerAmount;    
        razName[numberOfRazzes] = name;
        runningRazInstance[numberOfRazzes] = 1;
        return numberOfRazzes;
    }
    
    function updateExistingRaz(uint razNumber, uint maxBets, uint winningAmount, uint ownerAmount, uint particFee, string name) public onlyOwner returns (uint) 
    {
        require (razNumber<=numberOfRazzes);
        require(!IsRazRunning(razNumber));
        require(maxBets.mul(particFee) == winningAmount.add(ownerAmount));
        maxBetsForEachRaz[razNumber] = maxBets;
        participationFeeForEachRaz[razNumber] = particFee;
        winnerPrizeMoneyForEachRaz[razNumber] = winningAmount;
        ownerPrizeMoneyForEachRaz[razNumber] = ownerAmount;   
        razName[razNumber] = name;
    }
    function getMyPastWins(address addr) public constant returns (uint[])
    {
        return pastWinnings[addr];
    }
    function getMyPastLosses(address addr) public constant returns (uint[]) 
    {
        return pastLosings[addr];
    }
    
    function getRazInstanceInformation(uint razNumber, uint instanceNumber) public constant returns (uint, address, address[],uint,uint)
    {
        return (RazInstanceInformation[razNumber][instanceNumber].winningBet, 
                RazInstanceInformation[razNumber][instanceNumber].winningAddress,
                RazInstanceInformation[razNumber][instanceNumber].allLosers,
                RazInstanceInformation[razNumber][instanceNumber].timestamp,
                RazInstanceInformation[razNumber][instanceNumber].id);
    }
    function getRunningRazInstance(uint razNumber) public constant returns (uint)
    {
        return runningRazInstance[razNumber];
    }
    
    function getUserBetsInARazInstance(uint razNumber, uint instanceNumber) public constant returns(uint[])
    {
        return (userBetsInEachRazInstance[razNumber][instanceNumber][msg.sender].bets);
    }
    function getUserBetsTimeStampInARazInstance(uint razNumber, uint instanceNumber) public constant returns(uint)
    {
        return (userBetsInEachRazInstance[razNumber][instanceNumber][msg.sender].timestamp);
    }
    
    function IsRazRunning(uint razNumber) constant public returns (bool)
    {
        require(razNumber>=1 && razNumber<=numberOfRazzes);
        for (uint i=1;i<=maxBetsForEachRaz[razNumber];i++)
        {
            if (numbersTaken[razNumber][i] != 0)
                return true;
        }
        return false;
    }
}