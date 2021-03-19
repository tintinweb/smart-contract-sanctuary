/**
 *Submitted for verification at Etherscan.io on 2021-03-19
*/

pragma solidity ^0.4.24;

/**
 * @title SafeMath
 * @dev   Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256){
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b,"Calculation error");
        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256){
        // Solidity only automatically asserts when dividing by 0
        require(b > 0,"Calculation error");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256){
        require(b <= a,"Calculation error");
        uint256 c = a - b;
        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256){
        uint256 c = a + b;
        require(c >= a,"Calculation error");
        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256){
        require(b != 0,"Calculation error");
        return a % b;
    }
}


 /**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


 contract ICliq {

    function getowner() public view returns (address) {}

    function isOwner() internal view returns (bool) {}

    function transferOwnership(address) public returns (bool) {}

    function name() public pure returns (string memory) {}

    function symbol() public pure returns (string memory) {}

    function decimals() public pure returns (uint8) {}

    function totalSupply() public view returns (uint256) {}

    function balanceOf(address) public view returns (uint256) {}

    function allowance(address, address) public view returns (uint256) {}

    function transfer(address, uint256) public returns (bool) {}

    function transferFrom(address, address, uint256) public returns (bool) {}

    function _transfer(address , address, uint256 ) internal pure {}

    function approve(address , uint256 ) public returns (bool) {}

    function _approve(address , address , uint256 ) internal {}

    function increaseAllowance(address , uint256 ) public returns (bool) {}

    function decreaseAllowance(address , uint256 ) public returns (bool) {}

    function airdropByOwner(address[] memory , uint256[] memory) public returns (bool){}

    function _burn(address , uint256 ) internal {}

    function burn(uint256 ) public {}

    function mint(uint256 ) public returns(bool) {}

    function getContractBNBBalance() public view returns(uint256) {}
 }


contract Staking is IERC20, ICliq {
    
  using SafeMath for uint256;

  //---------------------------------------------------Variable, Mapping for Token Staking------------------------------------------------------//
  address private _owner;                         // Variable for Owner of the Contract.
  uint256 private _tokenPriceBNB;                 // variable to set price of token with respect to BNB.
  address private _tokenStakePoolAddress;         // Stake Pool Address to manage Staking user's Token.
  address private _tokenPurchaseAddress;          // Address for managing token for token purchase.
  
  // mapping for users with id => address Staking Address
  mapping (uint256 => address) private _tokenStakingAddress;

  // mapping for users with id => Staking Time
  mapping (uint256 => uint256) private _tokenStakingStartTime;

  // mapping for users with id => End Time
  mapping (uint256 => uint256) private _tokenStakingEndTime;

  // mapping for users with id => Tokens 
  mapping (uint256 => uint256) private _usersTokens;
  
  // mapping for users with id => Status
  mapping (uint256 => bool) private _TokenTransactionstatus;    
  
  // mapping to track purchased token
  mapping(address=>uint256) private _myPurchasedTokens;
  
  // mapping for open order BNB
  mapping(address=>uint256) private _BNBAmountByAddress;
  
  // mapping to keep track of final withdraw value of staked token
  mapping(uint256=>uint256) private _finalTokenStakeWithdraw;
  
  // mapping to keep track total number of staking days
  mapping(uint256=>uint256) private _tokenTotalDays;
  
  // penalty amount after staking time
  uint256 private _penaltyAmountAfterStakingTime;
  
  // variable to keep count of Token Staking
  uint256 private _tokenStakingCount = 0;

  // variable for Total BNB
  uint256 private _totalBNB;
  
  // variable for time management
  uint256 private _tokentime;
  
  // variable for token staking pause and unpause mechanism
  bool public tokenPaused = false;
  
  // events to handle staking pause or unpause
  event Paused();
  event Unpaused();
  
  constructor(address owner) public {
        _owner = owner;
    }
  
  // modifier to check the user for staking || Re-enterance Guard
  modifier tokenStakeCheck(uint256 tokens, uint256 timePeriod){
    require(tokens > 0, "Invalid Token Amount, Please Try Again!!! ");
    require(tokens <= 1e20, "Invalid Amount, Select amount less than 100 and try again!!!");
    require(timePeriod == 30 || timePeriod == 60 || timePeriod == 90, "Enter the Valid Time Period and Try Again !!!");
    _;
  }
  
  // modifier to check for the payable amount for purchasing the tokens
  modifier payableCheck(){
    require(msg.value > 0 ,"Cannot buy tokens, either amount is less or no tokens for sale");
    require(cliq.balanceOf(_tokenPurchaseAddress) > 0, "Cannot buy tokens, either amount is less or no tokens for sale");
    _;
  }
  
  //Interface 
    ICliq cliq;
    
    //Set Layer Contract Address for Token Transfer Functions
    function setLayerContractAddress(address CliqToken) external onlyOwner{
        cliq = ICliq(CliqToken);
    }
  
  /*
     * ----------------------------------------------------------------------------------------------------------------------------------------------
     * Functions for owner.
     
     * ----------------------------------------------------------------------------------------------------------------------------------------------
     */

    /**
    * @dev get address of smart contract owner
    * @return address of owner
    */
    function getowner() public view returns (address) {
      return _owner;
    }

    /**
    * @dev modifier to check if the message sender is owner
    */
    modifier onlyOwner() {
        require(isOwner(),"You are not authenticate to make this transfer");
        _;
    }

    /**
     * @dev Internal function for modifier
    */
    function isOwner() internal view returns (bool) {
      return msg.sender == _owner;
    }

    /**
     * @dev Transfer ownership of the smart contract. For owner only
     * @return request status
    */
    function transferOwnership(address newOwner) public onlyOwner returns (bool){
      _owner = newOwner;
      return true;
    }


  /*
  * ----------------------------------------------------------------------------------------------------------------------------------------------
  * Owner functions of get value, set value and withdraw Functionality
  * ----------------------------------------------------------------------------------------------------------------------------------------------
  */

  // function to set Token Stake Pool address
  function setTokenStakePoolAddress(address add) public onlyOwner returns(bool){
    require(add != address(0),"Invalid Address");
    _tokenStakePoolAddress = add;
    return true;
  }
  
  // function to get Token Stake Pool address
  function getTokenStakePoolAddress() public view returns(address){
    return _tokenStakePoolAddress;
  }

  // funtion to set _purchaseableTokensAddress
  function setpurchaseableTokensAddress(address add) public onlyOwner returns(bool){
    require(add != address(0),"Invalid Address");
    _tokenPurchaseAddress = add;
    return true;
  }

  // function to get _purchaseableTokensAddress
  function getpurchaseableTokensAddress() public view returns(address){
    return _tokenPurchaseAddress;
  }

  // function to Set the price of each token for BNB purchase
  function setPriceToken(uint256 tokenPrice) external onlyOwner returns (bool){
    require(tokenPrice >0,"Invalid Amount");
    _tokenPriceBNB = tokenPrice;
    return(true);
  }
    
  // function to get price of each token for BNB purchase
  function getPriceToken() public view returns(uint256) {
    return _tokenPriceBNB;
  }
  
//   // function to blacklist any stake
//   function blacklistStake(bool status,uint256 stakingId) external onlyOwner returns(bool){
//     _TokenTransactionstatus[stakingId] = status;
//   }

  // function to withdraw Funds by owner only
  function withdraw(uint256 amount) external onlyOwner returns(bool){
    msg.sender.transfer(amount);
    //msg.sender.transfer(address(this).balance);
    return true;
  }
  
  /*
  * ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  * Function for purchase Token Functionality
  * ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  */
  
  // function to perform purchased token
  function purchaseTokens() external payable payableCheck returns(bool){
    _myPurchasedTokens[msg.sender] = _myPurchasedTokens[msg.sender] + msg.value * _tokenPriceBNB;
    _BNBAmountByAddress[msg.sender] = msg.value;
    _totalBNB = _totalBNB + msg.value;
    return true;
  }
  
//   // funtion to withdraw purchased token 
//   function withdrawPurchaseToken() external returns(bool){
//     require(_myPurchasedTokens[msg.sender]>0,"You do not have any purchased token");
//     _myPurchasedTokens[msg.sender] = 0;
//     _BNBAmountByAddress[msg.sender] = 0;
//     cliq.approve(msg.sender,tokens);
//     cliq.transferFrom(msg.sender, _tokenStakePoolAddress, tokens);
//     cliq._transfer(_tokenPurchaseAddress, msg.sender, _myPurchasedTokens[msg.sender]);
//     _totalBNB  = _totalBNB.sub(_myPurchasedTokens[msg.sender]);
//     return true;
//   }
  
  // function to get purchased token 
  function getMyPurchasedTokens(address add) public view returns(uint256){
    return _myPurchasedTokens[add];
  }
  
  // function to get BNB deposit amount by address
  function getBNBAmountByAddress(address add) public view returns(uint256){
    return _BNBAmountByAddress[add];
  }
  
  // function to total BNB
  function getTotalBNB() public view returns(uint256){
    return _totalBNB;
  }
  
  /*
  * ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  * Functions for Token Staking Functionality
  * ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  */

  // function to performs staking for user tokens for a specific period of time
  function stakeToken(uint256 tokens, uint256 time) public tokenStakeCheck(tokens, time) returns(bool){
    require(tokenPaused == false, "Staking is Paused, Please try after staking get unpaused!!!");
    _tokentime = now + (time * 1 days);
    _tokenTotalDays[_tokenStakingCount] = time;
    _tokenStakingAddress[_tokenStakingCount] = msg.sender;
    _tokenStakingEndTime[_tokenStakingCount] = _tokentime;
    _tokenStakingStartTime[_tokenStakingCount] = now;
    _usersTokens[_tokenStakingCount] = tokens;
    //cliq.approve(msg.sender,tokens);
    cliq.transferFrom(msg.sender, _tokenStakePoolAddress, tokens);
    //cliq._transfer(msg.sender, _tokenStakePoolAddress, tokens);
    _TokenTransactionstatus[_tokenStakingCount] = false;
    _tokenStakingCount = _tokenStakingCount +1 ;
    return true;
  }

  // function to get staking count
  function getTokenStakingCount() public view returns(uint256){
      return _tokenStakingCount;
  }
  
  // function to get Rewards on the stake
  function getRewardDetailsByUserId(uint256 id) public view returns(uint256){
    if(_tokenTotalDays[id] == 30) {
        return ((_usersTokens[id]*10/100));
    } else if(_tokenTotalDays[id] == 60) {
               return ((_usersTokens[id]*20/100));
      } else if(_tokenTotalDays[id] == 90) { 
                 return ((_usersTokens[id]*30/100));
        } else{
              return 0;
          }
  }

  // function to calculate penalty for the message sender
  function getPenaltyDetailByUserId(uint256 id) public view returns(uint256){
     if(_tokenStakingEndTime[id] > now){
         if(_tokenTotalDays[id]==30){
             return ((_usersTokens[id]*3/100));
         } else if(_tokenTotalDays[id] == 60) {
               return ((_usersTokens[id]*6/100));
           } else if(_tokenTotalDays[id] == 90) { 
                 return ((_usersTokens[id]*9/100));
             } else {
                 return 0;
               }
     } else{
        return 0;
     }
  }
 
  // function for withdrawing staked tokens
  function withdrawStakedTokens(uint256 stakingId) public returns(bool){
    require(_tokenStakingAddress[stakingId] == msg.sender,"No staked token found on this address and ID");
    require(_TokenTransactionstatus[stakingId] != true,"Either tokens are already withdrawn or blocked by admin");
    require(cliq.balanceOf(_tokenStakePoolAddress) > _usersTokens[stakingId], "Pool is dry or empty, transaction cannot be performed!!!");
    require(now >= _tokenStakingStartTime[stakingId] + 1296000, "Unable to Withdraw Stake, Please Try after 15 Days from the date of Staking");
    _TokenTransactionstatus[stakingId] = true;
    if(now >= _tokenStakingEndTime[stakingId]){
        _finalTokenStakeWithdraw[stakingId] = _usersTokens[stakingId] + getRewardDetailsByUserId(stakingId);
        //cliq.approve(_tokenStakePoolAddress ,_finalTokenStakeWithdraw[stakingId]);
        cliq.transferFrom(_tokenStakePoolAddress, msg.sender,_finalTokenStakeWithdraw[stakingId]);
        //ICliq._transfer(_tokenStakePoolAddress,msg.sender,_finalTokenStakeWithdraw[stakingId]);
    } else {
        _finalTokenStakeWithdraw[stakingId] = _usersTokens[stakingId] + getPenaltyDetailByUserId(stakingId);
        cliq.approve(_tokenStakePoolAddress ,_finalTokenStakeWithdraw[stakingId]);
        cliq.transferFrom(_tokenStakePoolAddress, msg.sender,_finalTokenStakeWithdraw[stakingId]);
        //ICliq._transfer(_tokenStakePoolAddress,msg.sender,_finalTokenStakeWithdraw[stakingId]);
      }
    return true;
  }
  
  // function to get Final Withdraw Staked value
  function getFinalTokenStakeWithdraw(uint256 id) public view returns(uint256){
    return _finalTokenStakeWithdraw[id];
  }
  
  // function to pause Token Staking
  function pauseTokenStaking() public onlyOwner {
    tokenPaused = true;
    emit Paused();
    }

  // function to unpause Token Staking
  function unpauseTokenStaking() public onlyOwner {
    tokenPaused = false;
    emit Unpaused();
    }
    
  /*
  * ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  * Functions for Stake Token Functionality
  * ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  */

  // function to get Staking address by id
  function getTokenStakingAddressById(uint256 id) external view returns (address){
    require(id <= _tokenStakingCount,"Unable to reterive data on specified id, Please try again!!");
    return _tokenStakingAddress[id];
  }
  
  // function to get Staking Starting time by id
  function getTokenStakingStartTimeById(uint256 id) external view returns(uint256){
    require(id <= _tokenStakingCount,"Unable to reterive data on specified id, Please try again!!");
    return _tokenStakingStartTime[id];
  }
  
  // function to get Staking Ending time by id
  function getTokenStakingEndTimeById(uint256 id) external view returns(uint256){
    require(id <= _tokenStakingCount,"Unable to reterive data on specified id, Please try again!!");
    return _tokenStakingEndTime[id];
  }
  
  // function to get Staking Total Days by Id
  function getTokenStakingTotalDaysById(uint256 id) external view returns(uint256){
    require(id <= _tokenStakingCount,"Unable to reterive data on specified id, Please try again!!");
    return _tokenTotalDays[id];
  }

  // function to get Staking tokens by id
  function getStakingTokenById(uint256 id) external view returns(uint256){
    require(id <= _tokenStakingCount,"Unable to reterive data on specified id, Please try again!!");
    return _usersTokens[id];
  }

  // function to get Token lockstatus by id
  function getTokenLockStatus(uint256 id) external view returns(bool){
    require(id <= _tokenStakingCount,"Unable to reterive data on specified id, Please try again!!");
    return _TokenTransactionstatus[id];
  }

    
        
  //---------------------------------------------------Variable, Mapping for BNB Staking------------------------------------------------------//
  
  // variable to keep count of BNB Staking
  uint256 private _bnbStakingCount = 0;

  // variable for time management
  uint256 private _bnbTime;

  // mapping for users with id => Staking Time
  mapping (uint256 => uint256) private _bnbStakingStartTime;

  // mapping for users with id => End Time
  mapping (uint256 => uint256) private _bnbStakingEndTime;

  // mapping for users with id => address Staking Address
  mapping (uint256 => address) private _bnbStakingAddress;
  
  // mapping for users with id => BNB
  mapping (uint256 => uint256) private _usersBNB;

  // mapping for BNB deposited by user 
  mapping(address=>uint256) private _bnbStakedByUser;

  // mapping to keep track total number of staking days
  mapping(uint256=>uint256) private _bnbTotalDays;

  // mapping for users with id => Status
  mapping (uint256 => bool) private _bnbTransactionstatus;   
  
  // variable for BNB staking pause and unpause mechanism
  bool public BNBPaused = false;
  
   // modifier to check time for BNB Staking 
  modifier BNBStakeCheck(uint256 timePeriod){
    require(timePeriod == 30 || timePeriod == 60 || timePeriod == 90, "Enter the Valid Time Period and Try Again !!!");
      _;
  }
  
   /*
  * ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  * Functions for BNB Staking Functionality
  * ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  */
  
  // function to pause BNB Staking
  function pauseBNBStaking() public onlyOwner {
    BNBPaused = true;
    emit Paused();
    }

  // function to unpause BNB Staking
  function unpauseBNBStaking() public onlyOwner {
    BNBPaused = false;
    emit Unpaused();
    }
  
  function stakeBNB(uint256 time) external payable BNBStakeCheck(time) returns(bool){
    require(BNBPaused == false, "BNB Staking is Paused, Please try after staking get unpaused!!!");
    _bnbTime = now + (time * 1 days);
    _bnbTotalDays[_bnbStakingCount] = time;
    _bnbStakingAddress[_bnbStakingCount] = msg.sender;
    _bnbStakingEndTime[_bnbStakingCount] = _bnbTime;
    _bnbStakingStartTime[_bnbStakingCount] = now;
    _usersBNB[_bnbStakingCount] = msg.value;
    _bnbStakedByUser[msg.sender] = _bnbStakedByUser[msg.sender ].add(msg.value);
    _bnbTransactionstatus[_bnbStakingCount] = false;
    _bnbStakingCount = _bnbStakingCount + 1 ;
    return true;
  }

  // function to get staking count
  function getBNBStakingCount() public view returns(uint256){
      return _bnbStakingCount;
  }
  
  // function for withdrawing staked tokens
  function withdrawStakedBNB(uint256 stakingId) public returns(bool){
    require(_bnbStakingAddress[stakingId] == msg.sender,"No staked token found on this address and ID");
    require(_bnbTransactionstatus[stakingId] != true,"Either tokens are already withdrawn or blocked by admin");
    require(now >= _bnbStakingStartTime[stakingId] + 1296000, "Unable to Withdraw Stake, Please Try after 15 Days from the date of Staking");
    _bnbTransactionstatus[stakingId] = true;
    _bnbStakingAddress[stakingId].transfer(_usersBNB[stakingId]);
    // if(now >= _tokenStakingEndTime[stakingId]){
    //     _finalTokenStakeWithdraw[stakingId] = _usersTokens[stakingId] + getRewardDetailsByUserId(stakingId);
    //     _transfer(_tokenStakePoolAddress,msg.sender,_finalTokenStakeWithdraw[stakingId]);
    // } else {
    //     _finalTokenStakeWithdraw[stakingId] = _usersTokens[stakingId] + getPenaltyDetailByUserId(stakingId);
    //     _transfer(_tokenStakePoolAddress,msg.sender,_finalTokenStakeWithdraw[stakingId]);
    //   }
    return true;
  }

        
}