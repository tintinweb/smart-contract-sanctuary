// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


interface LeagueKeys {
        function approveKey(string calldata, uint256) external returns (bool);
        function getId(uint256) external returns (bool);

}

interface Token {
    function transferFrom(address, address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function balanceOf(address) external returns (uint256);
}

interface Profile {
    function getPlayersHistory(address) external returns (string[] memory);
 
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


library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
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

contract Leagues is Ownable {
    using SafeMath for uint256;
    
    event Create (address owner,string id);
    struct League {
        uint256 id;
        address owner;       
        string  name;
        uint256  startWeek;
        uint256  endWeek;
        uint256  amount;
        address first;
        address second;
        address third;
        bool loadflag;
    }
    mapping(uint256=>address[]) public joiners;
    mapping(address=>uint256[]) public owners;
    mapping(address=>uint256[]) public members;
    
    mapping(uint256=>League) public leaguesById;
    mapping(string=>League) public leaguesByKey;
    mapping(uint=>uint[]) public leaguesByWeeks;
    mapping(string=>address[]) public leagueChild;
    mapping(string=>uint256) public childId;    
    mapping(address=>uint) public rewardEarned;
    mapping(uint256=>uint256) public poolCollected;
    mapping(string => string) public playersHistoryWeek;
    

    uint256[] public leaguesArray ;  

    LeagueKeys public leagueKeyContract = LeagueKeys(0x0841138607E10C58C02Fae87Cf1ab776cBEB3abD) ;
    // Profile public profileContract = Profile(0x9b040041F335054538ff2Ae9A67dD218DbA4CFd8) ;
    Token public mainToken  = Token(0x79fDe167C18C51892BE4B559b60d9420c02afd05) ;
    address public feeWallet = 0x759C8682800fE744516C5E4CF85D19Df2C8eD72D ;

    uint256 public firstShare  ;
    uint256 public secondShare  ;
    uint256 public thirdShare  ;
    uint256 public feeShare  ;

    
    function getLeagues()  external view returns(uint256) {
       return leaguesArray.length ;
    }

    function getOwnerLength(address _account)  external view returns(uint256) {
       return owners[_account].length ;
    }

    function getMemberLength(address _account)  external view returns(uint256) {
       return members[_account].length ;
    }

    function getJoiner(
        uint256 _id    
    )
        external view returns (address[] memory)
    {
        address[] memory tempList = joiners[_id];
        return tempList;
    }
    
    
    
    function create(
       uint256 _id , string calldata _name, uint256 _startWeek, uint256 _endWeek, uint256 _amount
    )
        external returns (uint256)
    {
        uint256 id =  _id ;
        bool approval = leagueKeyContract.getId(id);
        require(approval,"id wrong");
        require(!leaguesById[id].loadflag,"id created");
        joiners[id] = new address[](1);
        joiners[id][0] = msg.sender;
        
   
        leaguesById[id] = League(id, msg.sender, _name, _startWeek, _endWeek, _amount, address(0), address(0), address(0), true);

        mainToken.transferFrom(msg.sender, address(this), _amount);        
        poolCollected[id] = poolCollected[id].add(_amount);

         for(uint i=_startWeek;i <= _endWeek; i++){
             leaguesByWeeks[i].push(id) ;
         }
        leaguesArray.push(id) ;
        owners[msg.sender].push(id);
        emit Create(msg.sender,_name);
        return id;
    }


    
     function syncPlayers(
        string calldata _id,
        string calldata _data
    )
    external
    {
        playersHistoryWeek[_id] = _data ;

    }

    
    function Join(
        string calldata _key,
        uint256  _id
    )
        external
    {
        bool flag = false;
        for(uint i=0;i<joiners[_id].length;i++){
           if(joiners[_id][i]==msg.sender){
               flag=true;
           }
        }
        require(!flag,"joiner is already exist");

        bool approval = leagueKeyContract.approveKey(_key, _id);
        require(approval,"key wrong");

        mainToken.transferFrom(msg.sender, address(this), leaguesById[_id].amount);
        poolCollected[_id] = poolCollected[_id].add(leaguesById[_id].amount);
 

        joiners[_id].push(msg.sender);
        members[msg.sender].push(_id);

        
    }

    function claim(       
        
    )
        external
    {
        require(rewardEarned[msg.sender] > 0 , "Zero Reward Available");
        mainToken.transfer(msg.sender, rewardEarned[msg.sender]);
  
    }

    
    function Update(
        uint256 _id, address first, address second, address third, bool loadflag
    )
        external onlyOwner
    {
 
        leaguesById[_id].first = first;
        uint256 firstReward =  poolCollected[_id].mul(firstShare).div(1e3);
        rewardEarned[first] = rewardEarned[first].add(firstReward) ;

        leaguesById[_id].second = second;
        uint256 secondReward =  poolCollected[_id].mul(secondShare).div(1e3);
        rewardEarned[second] = rewardEarned[second].add(secondReward)  ;


        leaguesById[_id].third = third;
        uint256 thirdReward =  poolCollected[_id].mul(thirdShare).div(1e3);
        rewardEarned[third] = rewardEarned[third].add(thirdReward)  ;

        
        uint256 fee =  poolCollected[_id].mul(feeShare).div(1e3);
        mainToken.transfer(feeWallet, fee);
 
        
    }


    // Admin Functions

    function updateFirstShare(
        uint256 _share 
    )
        external onlyOwner
    {
        firstShare = _share ;
    }

   function updateSecondShare(
        uint256 _share 
    )
        external onlyOwner
    {
        secondShare = _share ;
    }

   function updateThirdShare(
        uint256 _share 
    )
        external onlyOwner
    {
        thirdShare = _share ;
    }

   function updateFeeShare(
        uint256 _share 
    )
        external onlyOwner
    {
        feeShare = _share ;
    }

   function updateFeeWallet(
        address _wallet 
    )
        external onlyOwner
    {
        feeWallet = _wallet ;
    }


   function updateMainToken(
        Token _token 
    )
        external onlyOwner
    {
        mainToken = _token ;
    }

   function updateLeagueKeyContract(
        LeagueKeys _contract 
    )
        external onlyOwner
    {
        leagueKeyContract = _contract ;
    }

    


}