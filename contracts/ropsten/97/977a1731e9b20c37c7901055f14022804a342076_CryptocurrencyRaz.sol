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
    
    uint numberOfRazzes = 3;
    
    mapping(uint=>bool) razCompletion;
    mapping(uint=>mapping(uint=>address)) numbersTaken;
    mapping(uint=>uint) maxBetsForEachRaz;
    mapping(uint=>uint256) participationFeeForEachRaz;
    mapping(uint=>uint256) winnerPrizeMoneyForEachRaz;
    mapping(uint=>uint256) ownerPrizeMoneyForEachRaz;
    uint[] razList;
    uint[] empty;
    
  
    //address ownerWallet = 0x07A12f1B25f3B1802A44A64a4A1199EC2a171841; 
    constructor(address _owner) public 
    {
        owner = _owner;
        Setup();
    }
    
    function Setup() internal {
        maxBetsForEachRaz[1] = 10;
        maxBetsForEachRaz[2] = 20;
        maxBetsForEachRaz[3] = 10;
        
        participationFeeForEachRaz[1] = 3 * 10 ** 16;
        participationFeeForEachRaz[2] = 1 * 10 ** 16;
        participationFeeForEachRaz[3] = 1 * 10 ** 16;
        
        winnerPrizeMoneyForEachRaz[1] = 21 * 10 ** 16;
        winnerPrizeMoneyForEachRaz[2] = 15 * 10 ** 16;
        winnerPrizeMoneyForEachRaz[3] = 7 * 10 ** 16;
        
        ownerPrizeMoneyForEachRaz[1] = 9 * 10 ** 16;
        ownerPrizeMoneyForEachRaz[2] = 5 * 10 ** 16;
        ownerPrizeMoneyForEachRaz[3] = 3 * 10 ** 16;
    }
    
    function EnterBetsForRaz(uint razNumber, uint[] bets) public payable
    {
        require(razNumber>=1 && razNumber<=numberOfRazzes);
        uint numBets = bets.length;     //finding the numbers of bets the user has placed
        require(msg.value>=participationFeeForEachRaz[razNumber].mul(numBets));    //user has to pay according to the number of bets placed
        require(razCompletion[razNumber] == false);
        for (uint i=0;i<numBets;i++)
        {
            require(numbersTaken[razNumber][bets[i]] == 0);
            require(bets[i]>=1 && bets[i]<=maxBetsForEachRaz[razNumber]);
            numbersTaken[razNumber][bets[i]] = msg.sender;
        }
        MarkRazAsComplete(razNumber);
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
        uint randomNumber = uint8(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty)))%(maxBetsForEachRaz[razNumber].add(1)));
        declareWinnerForRaz(razNumber,randomNumber);
        return true;
    }
    function hasRazCompleted(uint razNumber) public constant returns (bool) 
    {
        require(razNumber>=1 && razNumber<=numberOfRazzes);
        return razCompletion[razNumber];    
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
    
    function resetRaz(uint razNumber) internal 
    {
        for (uint i=1;i<=maxBetsForEachRaz[razNumber];i++)
        {
            numbersTaken[razNumber][i]=0;
        }   
    }
    
    function declareWinnerForRaz(uint razNumber,uint winningNumber) internal
    {
        require(razNumber>=1 && razNumber<=numberOfRazzes);
        require(razCompletion[razNumber] == true);   
        address winningAddress =  numbersTaken[razNumber][winningNumber];
        winningAddress.transfer(winnerPrizeMoneyForEachRaz[razNumber]);
        owner.transfer(ownerPrizeMoneyForEachRaz[razNumber]);
        resetRaz(razNumber);
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
        participationFeeForEachRaz[razNumber] = participationFee * 10 ** 18;
    }
    
     function changeWinnerPrizeMoneyForRaz(uint razNumber,uint prizeMoney) public onlyOwner 
     {
        require(razNumber>=1 && razNumber<=numberOfRazzes);
        winnerPrizeMoneyForEachRaz[razNumber] = prizeMoney * 10 ** 18;
    }
    
    function addNewRaz(uint maxBets, uint winningAmount, uint ownerAmount, uint particFee) public onlyOwner returns (uint) 
    {
        numberOfRazzes = numberOfRazzes.add(1);
        maxBetsForEachRaz[numberOfRazzes] = maxBets;
        participationFeeForEachRaz[numberOfRazzes] = particFee * 10 ** 18;
        winnerPrizeMoneyForEachRaz[numberOfRazzes] = winningAmount * 10 ** 18;
        ownerPrizeMoneyForEachRaz[numberOfRazzes] = ownerAmount * 10 ** 18;    
        return numberOfRazzes;
    }
    
    function updateExistingRaz(uint razNumber, uint maxBets, uint winningAmount, uint ownerAmount, uint particFee) public onlyOwner returns (uint) 
    {
        require (razNumber<=numberOfRazzes);
        maxBetsForEachRaz[razNumber] = maxBets;
        participationFeeForEachRaz[razNumber] = particFee * 10 ** 18;
        winnerPrizeMoneyForEachRaz[razNumber] = winningAmount * 10 ** 18;
        ownerPrizeMoneyForEachRaz[razNumber] = ownerAmount * 10 ** 18;    
    }
}