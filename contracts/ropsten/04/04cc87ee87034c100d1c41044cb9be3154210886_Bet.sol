pragma solidity ^0.4.22;

library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract AccessControl
{
    address public ceoAddress;
    address public cityContractAddress;
    bool public paused = false;
    modifier onlyCityContract() {
        require(msg.sender == cityContractAddress);
        _;
    }
    function setCityContract(address _newCityContract) external onlyCEO() {
        require(_newCityContract != address(0));
        cityContractAddress = _newCityContract;
    }
    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }
    function setCEO(address _newCEO) external onlyCEO {
        require(_newCEO != address(0));
        ceoAddress = _newCEO;
    }
    /*** Pausable functionality adapted from OpenZeppelin ***/

    /// @dev Modifier to allow actions only when the contract IS NOT paused
    modifier whenNotPaused() {
        require(!paused);
        _;
    }
    /// @dev Modifier to allow actions only when the contract IS paused
    modifier whenPaused {
        require(paused);
        _;
    }

    function pause() external onlyCityContract whenNotPaused {
        paused = true;
    }
    function unpause() public onlyCityContract whenPaused {
        // can&#39;t unpause if contract was upgraded
        paused = false;
    }
}



contract Bet is AccessControl
{    
     using SafeMath for uint256;
     uint public cityId;
     uint[] public luckyLandIds;
     uint[] public luckyRewards;
     uint32 public readyTime;
     uint cooldownTime = 1 hours;
     uint public times = 0;
     uint public gamblerNum = 0;
     //mapping (address => uint) public cityBets;
     
     mapping (uint =>address[]) public cityBets;
     mapping (address => uint[]) public gamblerChoices;
         
     CityContractInterface cityContract;
     function Bet() public payable
     {
        ceoAddress = msg.sender;
     }

     function () public payable 
     {
 
     }
 
     function InitBetContract(address _address, uint _cityId) public onlyCEO()
     {
        cityId = _cityId;
        cityContractAddress = _address;
        cityContract = CityContractInterface(cityContractAddress);
        TriggerCooldown();
     }

     function MakeBet(address _gambler, uint _landId)  public payable returns(bool)
     {
        uint betPrice = 100 szabo;
        require(msg.value >= (betPrice * 110/100));
        address(this).transfer(betPrice);
        
        address owner = cityContract.OwnerOf(_landId);
        owner.transfer(msg.value - betPrice);

        uint id =  GetBetId(_landId,times);
        cityBets[id].push(_gambler);
        gamblerChoices[_gambler].push(id);
        gamblerNum++;
        return true;
     }
     
     function GetBetId(uint _landId,uint _times) public pure returns(uint)
     {
        return _times * 10**10 + _landId;
     }

     function GetLandId(uint _Id,uint _times) public pure returns(uint)
     {
        return _Id - _times * 10**10;
     }
     function GetBetResult() public onlyCEO
     {
         //require(_isReady());
         uint luckyLandIndex = rand();
         uint luckyLandId = cityContract.GetLandId(luckyLandIndex);
         luckyLandIds.push(luckyLandId);
         luckyRewards.push(address(this).balance);
         uint id = GetBetId(luckyLandId,times);
         address[] storage luckyGamblers = cityBets[id];
         if(luckyGamblers.length > 0 && address(this).balance > 0)
         {
             uint price = address(this).balance/luckyGamblers.length;
             for (uint i = 0; i < luckyGamblers.length; i++) 
             {
                luckyGamblers[i].transfer(price);
             }   
         }
         //else
            //gameCoreContractAddress.transfer(address(this).balance);
         TriggerCooldown();
         times++;
         gamblerNum = 0;
         
     }
     
     function GetLuckyLandIds() public view returns(uint[])
     {
         return luckyLandIds;
     }
     
     function GetLuckyGamblers(uint _times) public view returns(address[])
     {
         uint luckyLandId = luckyLandIds[_times];
         uint id = GetBetId(luckyLandId,_times);
         address[] storage luckyGamblers = cityBets[id];
         return luckyGamblers;
     }
     function GetLuckyRewards() public view returns(uint[])
     {
         return luckyRewards;
     }
     function GetGamblerChoices(address _gambler) public view returns(uint[])
     {
         return gamblerChoices[_gambler];
     }
     
     
     function rand() public view returns(uint256)
     {
        uint256 random = uint256(keccak256(block.difficulty,now,address(this).balance));
        return  random%cityContract.GetCityLandNums();
     } 
    
     function GetTotalGamblerNum() public view returns (uint)
     {
        return gamblerNum;
     } 
     function GetBetNums(uint _landId) public view returns (uint)
     {
        return cityBets[_landId].length;//0
     }
    
     function GetBetGamblers(uint _landId) public view returns (address[])
     {
        return cityBets[_landId];//0
     }
              
     function GetBetReadyTime() public view returns (uint) 
     {
        return readyTime;
     }
     
     function GetBetBalance() public view returns (uint) 
     {
        return address(this).balance;//0
     }
  
     function TriggerCooldown() internal
     {
        readyTime = uint32(now + cooldownTime);
     }
     function IsReady() public view returns (bool) 
     {
      return (readyTime <= now);
     }

}

contract CityContractInterface
{
    function GetCityLandNums() public view returns (uint);
    function GetLandId(uint _index) public view returns (uint);
    function OwnerOf(uint256 _tokenId) public view returns (address _owner);
}