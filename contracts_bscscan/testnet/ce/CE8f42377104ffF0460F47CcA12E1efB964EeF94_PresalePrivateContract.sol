/**
 *Submitted for verification at BscScan.com on 2021-11-01
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


   

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor()  {
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


interface Token {
    function balanceOf(address) view external  returns (uint256);
    function transfer(address, uint256) external  returns (bool);
    function transferFrom(address, address, uint256) external  returns (bool);
    function symbol() view external  returns (string calldata);
    function name() view external  returns (string calldata);
    function decimals() view external  returns (uint256);
    function totalSupply() view external  returns (uint256);
}


contract PresalePrivateContract is Ownable {
    using SafeMath for uint256;

    struct Presale {
        string details;
        address token;
        address payable creator;
        uint256 startTime;
        uint256 endTime;
        uint256 tokenAmount;
        uint256 softcap;
        uint256 hardCap;
        uint256 saleRate;
        uint256 taxRate;
        uint256 maxAllocation;
        uint256 raisedAmount;
        uint256 vestingScheduled;
        uint256[] vetsingPercentage;
        uint256 status;
        bool active;
        bool whitelisted;
        bool mintable;
        bool audit;
        bool kyc;
        bool insured;

    }

    mapping(uint256 => Presale )  presaleList ; 
    mapping(string => uint256 ) public presaleListSlug ; 
    mapping(string => bool ) public presaleListSlugExist ; 
    mapping(uint256 => mapping(address => uint256)) public users;
    mapping(uint256 => address[]) public usersArray;
    mapping(uint256 => mapping(address => uint256)) public usersClaimed;
    mapping(uint256 => mapping(address => uint256)) public usersLastClaimedTime;
    mapping(uint256 => mapping(address => bool)) public whitelistedUsers;
    uint256[] public presaleArray;
    bool public defaultActive = true ;
    uint256 public defaultStatus = 1 ;
    uint256 public ownerFee ;
    address payable public  feeWallet ;
  

    function getTokenInfo(address _token) public view  returns(string memory,string memory,uint256,uint256) {
        string memory _name = Token(_token).name() ;
        string memory _symbol = Token(_token).symbol() ;
        uint256 _decimals = Token(_token).decimals() ;
        uint256 _totalSupply = Token(_token).totalSupply() ;
        return (_name,_symbol,_decimals,_totalSupply);
    } 
    
     function getPresale(uint256 _saleId) public view  returns(Presale memory) {
        return presaleList[_saleId];
    } 

     function getParticpants(uint256 _saleId) public view  returns(address[] memory) {
        return usersArray[_saleId];
    } 

    
 
    function createPresale(
        string memory _details,
        string memory _slug,
        address _token,
        uint256 _startTime,
        uint256 _endTime, 
        uint256 _softcap,
        uint256 _hardCap,
        uint256[] memory _saleRate,
        uint256 _maxAllocation,
        uint256 _vestingScheduled,
        uint256[] memory _vetsingPercentage,
        bool _whitelist
        ) public payable  {

             
            require(!presaleListSlugExist[_slug] , "Already Exist");
            uint256 _saleId = presaleArray.length ;
            presaleArray.push(_saleId) ; 
            presaleList[_saleId].details = _details;
            presaleListSlug[_slug] = _saleId ;
            presaleListSlugExist[_slug] = true ;
            presaleList[_saleId].whitelisted = _whitelist ;
            presaleList[_saleId].taxRate = _saleRate[1] ;
            saveBasic(_token,_startTime,_endTime,_saleId) ;
            saveCreator(payable(msg.sender),_maxAllocation,_saleId) ;
            saveAdvance(getEstimatedToken(_saleRate[0],_hardCap,0),_softcap,_hardCap,_saleRate[0],_saleId) ;
            saveSettings(_vestingScheduled,_vetsingPercentage,_saleId) ;
            Token(_token).transferFrom(msg.sender, address(this), getEstimatedToken(_saleRate[0],_hardCap,_saleRate[1]));
        
    } 

      function saveBasic(address _token,uint256 _startTime,uint256 _endTime,uint256 _count) internal {
            presaleList[_count].token = _token;
            presaleList[_count].startTime = _startTime;
            presaleList[_count].endTime = _endTime;
 }

  function saveCreator(address payable _creator,uint256 _maxAllocation,uint256 _count) internal {
       
            presaleList[_count].creator = _creator;
            presaleList[_count].maxAllocation = _maxAllocation;
           
  }

  function saveAdvance(uint256 _tokenAmount,uint256 _softcap,uint256 _hardCap,uint256 _saleRate,uint256 _count) internal {
           presaleList[_count].tokenAmount = _tokenAmount ;
            presaleList[_count].softcap = _softcap;
            presaleList[_count].hardCap = _hardCap;
            presaleList[_count].saleRate = _saleRate ;
  }

   function OwnerDetails(bool _mintable,bool _audit,bool _kyc,bool _insured,uint256 _saleId) public onlyOwner {
           presaleList[_saleId].mintable = _mintable ;
            presaleList[_saleId].audit = _audit;
            presaleList[_saleId].kyc = _kyc;
            presaleList[_saleId].insured = _insured ;
  }
  
  function saveSettings(uint256 _vestingScheduled,uint256[] memory _vetsingPercentage, uint256 _count) internal {
       
            presaleList[_count].vestingScheduled = _vestingScheduled;
            presaleList[_count].vetsingPercentage = _vetsingPercentage;
            presaleList[_count].active = defaultActive;
            presaleList[_count].status = defaultStatus;
           
  }

    function whiteListUsersStatusChange(address[] memory _users, bool _whitelistStatus,uint256 _saleId) public {
        require((msg.sender == presaleList[_saleId].creator || msg.sender == owner), "Not Allowed" );
        for (uint256 i = 0; i < _users.length; i++) {
                whitelistedUsers[_saleId][_users[i]] = _whitelistStatus;               
            }
    }



    function getEstimatedToken(uint256 _saleRate,uint256 _amount,uint256 _tax ) public pure returns (uint256){
         
        uint256 _token = _saleRate.mul(_amount).div(1e18) ;
        uint256 _taxAmt = _token.mul(_tax).div(1e4) ;
        _token = _token.add(_taxAmt);
       
        return _token ; 
    }

    function getAmountToken(uint256 _saleId,uint256 _amount) public view returns (uint256){
         
        uint256 _token = presaleList[_saleId].saleRate.mul(_amount).div(1e18) ;
        
        return _token ; 
    }

    function getPresaleCount() public view returns (uint256){
         return presaleArray.length ; 
    }

    
    function getParticipants(uint256 _saleId) public view returns (uint256){
         return usersArray[_saleId].length ; 
    }
    
 

     function getMaxraise(uint256 _saleId) public view returns (uint256){
       
        uint256 _amount = presaleList[_saleId].hardCap  ;
        
        return _amount ; 
    }


    function getUnsold(uint256 _saleId) public view returns (uint256){
       
        uint256 _tokenSold = getAmountToken(_saleId,presaleList[_saleId].raisedAmount)  ;
        uint256 _tokenUnsold = presaleList[_saleId].tokenAmount.sub(_tokenSold) ;
        
        return _tokenUnsold ; 
    }

         function getTokenDue(uint256 _saleId, address _user ) public view returns (uint256,uint256,uint256){
       
            uint256 _tokenAmount = getAmountToken(_saleId,users[_saleId][_user]) ;
            uint256 _remainingToken = _tokenAmount.sub(usersClaimed[_saleId][_user]) ;
            uint256 _lastClaimed = usersLastClaimedTime[_saleId][_user] ;
            uint256[] memory _vestingPercentage = presaleList[_saleId].vetsingPercentage ;
            if(_lastClaimed == 0){
            uint256 _tokenDue = _tokenAmount.mul(_vestingPercentage[0].div(1000)) ;             
            return (_tokenAmount,_remainingToken,_tokenDue) ; 
            }
            else{
            uint256 _difference = block.timestamp.sub(_lastClaimed) ;

            uint256 _vestingCycle = _difference.div(presaleList[_saleId].vestingScheduled) ; 

            uint256 _percycle = _tokenAmount.mul(_vestingPercentage[1].div(1000)) ;
            uint256 _tokenDue = _vestingCycle.mul(_percycle) ; 
            return (_tokenAmount,_remainingToken,_tokenDue) ; 

            }
         
        
      }


 

    function checkWhiteList(uint256 _saleId , address _account ) public view returns (bool){
       
            if(presaleList[_saleId].whitelisted){
                return whitelistedUsers[_saleId][_account] ;
            }
            else{
              return true;
            }
           
      }

   function buyPresale(
        uint256 _saleId
        ) payable public  {
            uint256 _amount = msg.value   ;
            address _user = msg.sender   ;
            require(presaleList[_saleId].status == 1 , "Not Allowed") ; 
            require(checkWhiteList(_saleId,msg.sender), "Not Whitelisted" );
            require(presaleList[_saleId].active  , "Not Active") ; 
            require(presaleList[_saleId].raisedAmount.add(_amount) <= getMaxraise(_saleId)  , "Sale Filled/Sale Capacity Not Enough") ; 
            require(presaleList[_saleId].startTime  <= block.timestamp  , "Sale Not Started") ; 
            require(presaleList[_saleId].endTime  > block.timestamp  , "Sale Ended") ; 
            require(users[_saleId][_user].add(_amount) <=  presaleList[_saleId].maxAllocation  , "Maximum Alocation Reached") ; 

            presaleList[_saleId].raisedAmount = presaleList[_saleId].raisedAmount.add(_amount);
              
            users[_saleId][_user] =  users[_saleId][_user].add(_amount);
            usersArray[_saleId].push(_user) ;
        
    } 




    function claimPresale(
        uint256 _saleId
        ) public  {
            address _user = msg.sender   ;
            uint256 _tokenAmount = getAmountToken(_saleId,users[_saleId][_user]) ;
             
            require(usersClaimed[_saleId][_user] < _tokenAmount , "All Claimed") ; 
            require(users[_saleId][_user] > 0 , "Nothing to Claim") ; 

            require(presaleList[_saleId].status == 2   , "Sale Claim Not Allowed") ; 



            if(presaleList[_saleId].vestingScheduled == 0 ){
            Token(presaleList[_saleId].token).transfer(_user, _tokenAmount);              
            usersLastClaimedTime[_saleId][_user] =  block.timestamp ;
            usersClaimed[_saleId][_user] =  _tokenAmount ;
            }
            else{
            (,,uint256 _tokenDueNow) = getTokenDue(_saleId,_user);
            Token(presaleList[_saleId].token).transfer(_user, _tokenDueNow);              
            users[_saleId][_user] =   users[_saleId][_user] ;
            usersLastClaimedTime[_saleId][_user] =  block.timestamp ;
            usersClaimed[_saleId][_user] = usersClaimed[_saleId][_user].add(_tokenDueNow) ;
            
            }

        
    } 


    
    function finishPresale(
        uint256 _saleId
        )  public onlyOwner {


            uint256 _unsold = getUnsold(_saleId) ;
            if(_unsold > 0){
            Token(presaleList[_saleId].token).transfer(presaleList[_saleId].creator, _unsold);         
            }
            presaleList[_saleId].status == 2 ;   
            uint256 _fee =  presaleList[_saleId].raisedAmount.mul(ownerFee.div(1000));

            if(_fee > 0 ){
            feeWallet.transfer(_fee); 

            }
            uint256 _remaining =  presaleList[_saleId].raisedAmount.sub(_fee);
            if(_remaining > 0){
            presaleList[_saleId].creator.transfer(_remaining); 

            }

            }


    // ADMIN FUNCTION


        function changeDefaultActive(
        bool _active
        )  public onlyOwner {
            defaultActive = _active ;
            }

        function changeDefaultStatus(
        uint256 _status
        )  public onlyOwner {
            defaultStatus = _status ;
            }

        function changeOwnerFee(
        uint256 _fee
        )  public onlyOwner {
            ownerFee = _fee ;
            }

        function changeFeeWallet(
        address payable _wallet
        )  public onlyOwner {
            feeWallet = _wallet ;
            }

      function cancelPresale(
        uint256 _saleId
        )  public onlyOwner {
            require(presaleList[_saleId].status == 1   , "Sale Already Not Live") ; 
            require(presaleList[_saleId].active    , "Sale Not Active") ; 
            require(presaleList[_saleId].raisedAmount == 0   , "Sale is Live") ; 
             Token(presaleList[_saleId].token).transfer(presaleList[_saleId].creator, presaleList[_saleId].tokenAmount); 
              presaleList[_saleId].status = 3 ;
              presaleList[_saleId].active = false ;
            }

                function changeActive(
        uint256 _saleId, 
        bool _active
        )  public onlyOwner {
              presaleList[_saleId].active = _active ;
            }

             function changeStatus(
        uint256 _saleId, 
        uint256 _status
        )  public onlyOwner {
              presaleList[_saleId].status = _status ;
            }



    function withdrawBNB() public onlyOwner {
        feeWallet.transfer(address(this).balance);        
    }
    
    // function to allow admin to claim *other* ERC20 tokens sent to this contract (by mistake)
    function transferAnyERC20Tokens(address _tokenAddr, address _to, uint _amount) public onlyOwner {   
        Token(_tokenAddr).transfer(_to, _amount);
    }


}