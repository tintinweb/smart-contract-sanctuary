/**
 *Submitted for verification at BscScan.com on 2021-09-10
*/

pragma solidity ^0.6.12;
// SPDX-License-Identifier: Unlicensed
interface IERC20 {

    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
  /**
   * @dev Returns the addition of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `+` operator.
   *
   * Requirements:
   * - Addition cannot overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  /**
   * @dev Returns the multiplication of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `*` operator.
   *
   * Requirements:
   * - Multiplication cannot overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts with custom message when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

contract Owend {
    address public _owner;

    constructor () internal {
        _owner = msg.sender;
    }
   
    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _owner = newOwner;
    }
}
contract Spark is IERC20, Owend{
    using SafeMath for uint256;
    
    struct User{
        address userAddress;
        address recommendAddress;
       
        address[] effectiveAddresss;
       }
       
     
     address [] private lockAddress;
     uint [] private lockTime;
     uint256 [] private lockAmount;
        
    
    address[] private pledgeAddresss;


    mapping(address=>bool) public isEffective;
    mapping (address => uint256) public whiteList;
    mapping (address => uint256) public unilateralList;
    mapping(address => address) public referrals;
    address[] private referralsKey;
    mapping(address => User) private users;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => uint256) public reallyBalanceOf;

    mapping (address => uint256) public lockBalanceOf;

    mapping (address => uint256) public pledgeBalanceOf;
    
 
  
    uint256 public pledgeMinLimit=50*10**18;

    uint8 public minRecommends=5;
    uint256 private minEffectiveAmount=10*10**18;
    uint256 private _mintTotal=105000*10**18;
    uint256 private mintSupplyTotal=0;
    uint256 private _totalSupply=210000*10**18;
    string private _name ="Spark Token";
    string private _symbol="SPK";
    uint256 private _decimals = 18;
    uint8 public teamNumber = 30; 
    address public ownerAddress;
    
    uint private pledageStatus = 0; 
    
   
    address public blackholeAddress = 0x0000000000000000000000000000000000000000;
 
  
    address public consensusAddress=0x437ddaf5D7b8Ad48E75dc05eB86F5bb4838C528c;
  
    address public liquidityPoolAddress=0x9236344B0593149B55066A645cBa9FD7E632eF3c;
    

    address public distributionAddress=0xbB48D50cBA410A06C8eF3Df67a3f682B4dB15a08; 
    
    address public dynamicRewardAddress=0x442c09479F3d700A75E1360aE65bDBB27C7be4F5;
 
    address public pledgeAddress=0xE3d4E3354317931d812109E84f4A96Ac1b2E648b;
  
    address public minPoolAddress=0xA3725DD1cA77504018F284F4D548c37e1c1EB774;
    
    address public newPledgeAddress=0xF4908Accba772F110544a4F458442796dBbC0c05;
    constructor()public{
        ownerAddress=msg.sender;
        whiteList[msg.sender]=1;
        referrals[msg.sender]=ownerAddress;
        users[ownerAddress].userAddress = ownerAddress;
        users[ownerAddress].recommendAddress = ownerAddress;
        reallyBalanceOf[ownerAddress] =_totalSupply.div(2); 
        emit Transfer(address(0), ownerAddress,_totalSupply.div(2));
        }
    
    function _transfer(address _from,address _to,uint256 _value) private{
        require(_from != address(0), "ERC20: transfer from the zero address");
        require(_to != address(0), "ERC20: transfer to the zero address");
        require(_value > 0, "Transfer amount must be greater than zero");
        require(reallyBalanceOf[_from]>=_value,"Balance insufficient");
        reallyBalanceOf[_from] =reallyBalanceOf[_from].sub(_value);
        if(unilateralList[_to]==1){
             reallyBalanceOf[_to] =reallyBalanceOf[_to].add(_value);
        }else{
           if(_from==pledgeAddress){
               reallyBalanceOf[_to] = reallyBalanceOf[_to].add(_value.mul(10).div(100));
               lockBalanceOf[_to] = lockBalanceOf[_to].add(_value.mul(90).div(100));
               lockAddress.push(_to);
               lockTime.push(now);
               lockAmount.push(_value);
               
           }else if(_from==newPledgeAddress){
               lockBalanceOf[_to] = lockBalanceOf[_to].add(_value);
               lockAddress.push(_to);
               lockTime.push(now);
               lockAmount.push(_value);
           }else{
               if(whiteList[_from]==1||whiteList[_to]==1){
                   reallyBalanceOf[_to] = reallyBalanceOf[_to].add(_value);
                   
               }else{
                       uint256 amount = _value.mul(90).div(100);
                       uint256 recommendRewardAmount=_value.mul(5).div(100);
                       uint256 consensusAmount=_value.mul(3).div(100);
                       uint256 destroyAmount=_value.mul(2).div(100);
                       reallyBalanceOf[_to] = reallyBalanceOf[_to].add(amount);
                       reallyBalanceOf[consensusAddress] = reallyBalanceOf[consensusAddress].add(consensusAmount);
                       reallyBalanceOf[blackholeAddress] = reallyBalanceOf[blackholeAddress].add(destroyAmount);
                       updateRecommendReward(recommendRewardAmount,_to);
                       if(_mintTotal>0){
                           if(_mintTotal>=destroyAmount.mul(3)){
                               _mint(destroyAmount.mul(3));
                           }else{
                               _mint(_mintTotal);
                           }
                        }
                }
        
         }
          updateUserInfo(_from,_to);
          updateEffectiveAccount(_to);
          updateEffectiveAccount(_from);
        }
        emit Transfer(_from,_to,_value);
     } 
     
    function changeOwner(address account) public onlyOwner{
       _owner=account;
       ownerAddress=account;
    }
     
    function updateEffectiveAccount(address account) private{
        if(pledgeBalanceOf[account].add(reallyBalanceOf[account])>minEffectiveAmount){
            isEffective[account]=true;
        }else{
            isEffective[account]=false;
        }
    }
     
     function getLockRecordByAccount() view public returns(address[] memory add,uint[] memory   time,uint256 [] memory amount){
         return(lockAddress,lockTime,lockAmount);
     }
     
    
     function updateUserInfo(address _from,address _to) private {
        User storage _users = users[_to];
        User storage _user = users[_from];
        if(_users.userAddress == address(0)){
            _users.userAddress = _to;
            users[_to] = _users;
        }
        if(_user.userAddress==address(0)){
            _user.userAddress=_from;
            users[_from]=_user;
        }
     }

     function updateRecommendReward(uint256 recommendRewardAmount,address _to) private{
        
            uint256 oneRewardAmount = recommendRewardAmount.mul(60).div(100);
            uint256 twoRewardAmount = recommendRewardAmount.mul(40).div(100);
            address oneAddress=referrals[_to];
            if(oneAddress==address(0)){
               reallyBalanceOf[ownerAddress]=reallyBalanceOf[ownerAddress].add(recommendRewardAmount);
                return;
            }
            reallyBalanceOf[oneAddress] = reallyBalanceOf[oneAddress].add(oneRewardAmount); 
            address toAddress=referrals[oneAddress];
            if(toAddress==address(0)){
                reallyBalanceOf[ownerAddress]= reallyBalanceOf[ownerAddress].add(twoRewardAmount);
                return;
            }
            reallyBalanceOf[toAddress] = reallyBalanceOf[toAddress].add(twoRewardAmount);
         } 
     
      function updateTopUser(address _from,address _to) private{
     
          User storage fromUser=users[_from];
         
          address fromUserRecommendAddress=referrals[fromUser.userAddress];
          if(fromUserRecommendAddress!=address(0)){
          
            User storage recommendUser =users[fromUserRecommendAddress];
            if(recommendUser.effectiveAddresss.length>0){
                uint index=findIndexByValue(recommendUser.effectiveAddresss,_from);
  
                if(index==recommendUser.effectiveAddresss.length){
                     recommendUser.effectiveAddresss.push(_from);
                }
            }else{
                recommendUser.effectiveAddresss.push(_from);
            }
              
          }
       
          User storage toUser=users[_to];
          address toUserRecommendAddress=referrals[toUser.userAddress];
          if(toUserRecommendAddress!=address(0)){
        
            User storage recommendUser =users[toUserRecommendAddress];    
                if(recommendUser.effectiveAddresss.length>0){
                    uint index=findIndexByValue(recommendUser.effectiveAddresss,_to);
                         
                    if(index==recommendUser.effectiveAddresss.length){
                        recommendUser.effectiveAddresss.push(_to);
                        
                    }
                }else{
                    recommendUser.effectiveAddresss.push(_to);
                
                }
            }
      }
    
       function activiteAccount(address recommendAddress)  public returns(uint code){
           if(msg.sender==recommendAddress){
               return 1;
           }
       
           if (whiteList[recommendAddress]==0){
               if(referrals[recommendAddress]==address(0)){
                return 1;   
               }
               if(referrals[recommendAddress]==msg.sender){
                   return 1;
               }
           }
         
           if(referrals[msg.sender]!=address(0)){
               return 1;
           }
           updateUserInfo(msg.sender,recommendAddress);
           referrals[msg.sender]=recommendAddress;
           referralsKey.push(msg.sender);
           updateTopUser(recommendAddress,msg.sender);
           return 0;
       }
  
       function getUpAddress(address account) view public returns(address,bool){
           bool isNode=false;
           if(pledgeBalanceOf[account]>=pledgeMinLimit && getEffectiveAddresssSize(account)>=minRecommends){
            isNode=true;
           }
           return (referrals[account],isNode);
       }
        
        function getEffectiveAddresssSize(address account) view public returns(uint ){
            uint count=0;
            User storage _user=users[account];
            for (uint i=0;i<_user.effectiveAddresss.length;i++){
                if(isEffective[_user.effectiveAddresss[i]]){
                    count++;
                }
            }
            return count;
        }
  
        function getEffectiveAddresss(address account) view public returns(address [] memory effectiveList){
             uint count=getEffectiveAddresssSize(account);
             if(count==0){
                 return effectiveList;
             }
             effectiveList=new address[](count);
             uint index=0;    
             User storage _user=users[account];
              for (uint i=0;i<_user.effectiveAddresss.length;i++){
                  if(isEffective[_user.effectiveAddresss[i]]){
                    effectiveList[index]=_user.effectiveAddresss[i];
                    index++;
                  }
            }
            return effectiveList;
        }
       
       
     
       function getReferralsByAddress()view public   returns(address[] memory referralsKeyList,address [] memory referralsList){
        address [] memory values=new address[](referralsKey.length);  
         for(uint i=0;i<referralsKey.length;i++){
             address key=referralsKey[i];
             address addr=referrals[key];
             values[i]=addr;
         }  
         return(referralsKey,values);
       }
       
  
     
       function getNodeAddresss()public view returns(address [] memory nodeAddressList){
        uint length=0;
           for(uint i=0;i<pledgeAddresss.length;i++){
                if(pledgeBalanceOf[pledgeAddresss[i]]>=pledgeMinLimit&&getEffectiveAddresssSize(pledgeAddresss[i])>=minRecommends){
                    length++;
                  }
              
            }
         nodeAddressList=new address[](length);
         uint index=0;
         for(uint i=0;i<pledgeAddresss.length;i++){
            if(pledgeBalanceOf[pledgeAddresss[i]]>=pledgeMinLimit &&getEffectiveAddresssSize(pledgeAddresss[i])>=minRecommends){
                nodeAddressList[index]=pledgeAddresss[i];
                index++;
                if(index==length){
                break;
                }
            }
         }
         
        return nodeAddressList ;
       }
       
       
       function updateRecommendShip(address[] memory upAddress,address [] memory downAddress)public onlyOwner{
           for(uint i=0;i<upAddress.length;i++){ 
               if(downAddress[i]==upAddress[i]){
                   continue;
               }
               updateUserInfo(downAddress[i],upAddress[i]);
               referrals[downAddress[i]]=upAddress[i];
               referralsKey.push(downAddress[i]);
               updateTopUser(upAddress[i],downAddress[i]);
           }
           
       }
       
       
        function nodeRewardRelease(address[]  memory accounts,uint256[]  memory amounts) public onlyOwner{

            uint256 totalAmount = 0;

            for (uint i=0;i<accounts.length;i++){ 
                 totalAmount = totalAmount.add(amounts[i]);
             }

             require(totalAmount <= reallyBalanceOf[consensusAddress], "balance error"); 
     
             for (uint i=0;i<accounts.length;i++){
                 if(amounts[i]>reallyBalanceOf[consensusAddress] || amounts[i] <0){
                     continue;
                 }
                 if(accounts[i]==address(0)){
                     continue;
                 }
                 reallyBalanceOf[accounts[i]]=reallyBalanceOf[accounts[i]].add(amounts[i]);
                 reallyBalanceOf[consensusAddress]=reallyBalanceOf[consensusAddress].sub(amounts[i]);
                 emit Transfer(consensusAddress,accounts[i],amounts[i]);
             }
          

    }
     
     function assignNodeRewardsList(address[] memory nodeList)  onlyOwner public returns(bool){
         if(nodeList.length==0){
             return false;
         }
         uint256 nodeRewards= reallyBalanceOf[consensusAddress];
         if(nodeRewards==0){
             return false;
         }
        uint256 eachReward=nodeRewards.div(nodeList.length);
         for(uint i=0;i<nodeList.length;i++){
             reallyBalanceOf[nodeList[i]] = reallyBalanceOf[nodeList[i]].add(eachReward);
         }
        reallyBalanceOf[consensusAddress]=reallyBalanceOf[consensusAddress].sub(nodeRewards);
         return true;
     }  
       
      

     function assignNodeRewards() public  onlyOwner returns(bool){    
   
         address [] memory tempAddress= getNodeAddresss();
         if(tempAddress.length==0){
             return false;
         }
         uint256 nodeRewards= reallyBalanceOf[consensusAddress];
         if(nodeRewards==0){
             return false;
         }
         
         uint256 eachReward=nodeRewards.div(tempAddress.length);
         for(uint i=0;i<tempAddress.length;i++){
             reallyBalanceOf[tempAddress[i]] = reallyBalanceOf[tempAddress[i]].add(eachReward);
         }
         reallyBalanceOf[consensusAddress]=reallyBalanceOf[consensusAddress].sub(nodeRewards);
         return true;
 
     }
     
     function setPledgeMinLimit(uint8 min) public onlyOwner returns( bool){
         if(min<=0){
             return false;
         }
         pledgeMinLimit=min;
         return true;
     }
     function setMinRecommends(uint8 min)public onlyOwner returns(bool){
         minRecommends=min;
         return true;
     }
     function setMinEffectiveAmount(uint256 min) public onlyOwner returns(bool){
         minEffectiveAmount=min;
         return true;
     }
    
    function pledge(uint256 amount)  public returns(bool){
      require(amount >0, "ERC20: amount must more than zero ");
      if(reallyBalanceOf[msg.sender]<amount){
          return false;
      }
      reallyBalanceOf[msg.sender] = reallyBalanceOf[msg.sender].sub(amount);
      pledgeBalanceOf[msg.sender] = pledgeBalanceOf[msg.sender].add(amount);
      uint index =findIndexByValue(pledgeAddresss,msg.sender);
      if(index==pledgeAddresss.length){
        pledgeAddresss.push(msg.sender);
      }
      updateEffectiveAccount(msg.sender);
      return true;
    }
   
    function pledgeRelease(uint256 amount)  public returns(bool){
        require(amount >0, "ERC20: amount must more than zero ");
        require(pledageStatus >0, "cannot return ");

        if(pledgeBalanceOf[msg.sender]<amount){
            return false;
        }
        pledgeBalanceOf[msg.sender] = pledgeBalanceOf[msg.sender].sub(amount);
        reallyBalanceOf[msg.sender] = reallyBalanceOf[msg.sender].add(amount);
        updateEffectiveAccount(msg.sender);
        return true;
     }
     
    
        function lockAccount(address account,uint256 amount) public onlyOwner returns(bool){
            if(reallyBalanceOf[pledgeAddress]<amount){
                return false;
            }
            if(account==address(0)){
                return false;
            }
            reallyBalanceOf[pledgeAddress] = reallyBalanceOf[pledgeAddress].sub(amount);
            lockBalanceOf[account] = lockBalanceOf[account].add(amount);
       
            return true;
          }   
        
        function lockRelease(address account,uint256 amount)public onlyOwner returns(bool){
             if(lockBalanceOf[account]<amount){
                 return false;
             }
             if(account==address(0)){
                 return false;
             }
             lockBalanceOf[account] = lockBalanceOf[account].sub(amount);
             reallyBalanceOf[account] = reallyBalanceOf[account].add(amount);
 
             return true;
             
         }
  
     
     
    function pledgeReleaseUseManager(address account,uint256 amount) public onlyOwner{
        require(pledgeBalanceOf[account]>=amount,"Balance insufficient");
        pledgeBalanceOf[account] = pledgeBalanceOf[account].sub(amount);
        reallyBalanceOf[account] = reallyBalanceOf[account].add(amount);
    }
    
    
    

    function findIndexByValue(address[] storage list,address account) private view returns(uint index){
       for (uint i = 0; i<list.length; i++){
           if(account==list[i]){
            return i;   
           }
        }
        return list.length;
    }
   
   

    function updateRecommendNumber(address _recommendAddress,uint number) private{
        User storage recommendUser = users[_recommendAddress];
        if(recommendUser.userAddress != address(0) && number <= teamNumber){
       
            number++;
            updateRecommendNumber(recommendUser.recommendAddress,number);
        }
    }
    
    function addWhite(address account) public onlyOwner returns(bool){
        whiteList[account]=1;
        if(referrals[account]==address(0)){
            referrals[account]=ownerAddress;
        }
        return true;
    }
    
    function setPledageStatus(uint status) public onlyOwner returns(bool){
        
        pledageStatus = status;
        
        return true;
    }
    
    function removeWhite(address account) public onlyOwner returns(bool){
        whiteList[account]=0;
        return true;
    }
    function addUnilateralList(address account) public onlyOwner returns(bool){
        unilateralList[account]=1;
        return true;
    }
    
    function removeUnilateralList(address account) public onlyOwner returns(bool){
        unilateralList[account]=0;
        return true;
    }
      

    function _burn( uint256 amount)  public onlyOwner returns (bool) {
        require(reallyBalanceOf[msg.sender]>=amount,"Balance insufficient");
        reallyBalanceOf[msg.sender] =  reallyBalanceOf[msg.sender].sub(amount);
        _totalSupply =  _totalSupply.sub(amount);
      
        return true;
    }

   function _mint(uint256 amount) internal {
        require(ownerAddress != address(0), "BEP20: mint to the zero address");
        mintSupplyTotal = mintSupplyTotal.add(amount);

        uint256 liquidityPoolAmount=amount.mul(20).div(100);
    
        uint256 distributionAmount=amount.mul(30).div(100);
       
        uint256 dynamicRewardAmount=amount.mul(50).div(100);
        
        reallyBalanceOf[liquidityPoolAddress] = reallyBalanceOf[liquidityPoolAddress].add(liquidityPoolAmount);
        reallyBalanceOf[distributionAddress] = reallyBalanceOf[distributionAddress].add(distributionAmount);
        reallyBalanceOf[dynamicRewardAddress] = reallyBalanceOf[dynamicRewardAddress].add(dynamicRewardAmount);
        _mintTotal = _mintTotal.sub(amount);
    
    }
    
    function receiveIncome(address account,uint256 amount) public onlyOwner{
        
        require(reallyBalanceOf[minPoolAddress] >= amount,"Balance insufficient");
        
        reallyBalanceOf[minPoolAddress] = reallyBalanceOf[minPoolAddress].sub(amount);
        reallyBalanceOf[account] = reallyBalanceOf[account].add(amount);
    }      
    
     function collectionBalanceToPool() public onlyOwner{
        reallyBalanceOf[minPoolAddress]=reallyBalanceOf[minPoolAddress].add(reallyBalanceOf[distributionAddress]).add(reallyBalanceOf[dynamicRewardAddress]);
        reallyBalanceOf[distributionAddress] =0;
        reallyBalanceOf[dynamicRewardAddress] =0;
     }
     
    function updateLockRecords(address [] memory accounts,uint256 [] memory amounts,uint[] memory times) public onlyOwner{
        for(uint i=0;i<accounts.length;i++){
              lockAddress.push(accounts[i]);
              lockTime.push(times[i]);
              lockAmount.push(amounts[i]);
        }
    } 
     
     
    function updateTheAddress(address consensus,address liquidityPool, address distribution
    ,address dynamicReward,address pledgeAdd,address minPool,address newPledge) public
     onlyOwner {
         if(consensus!=address(0)){consensusAddress=consensus;}
         if(liquidityPool!=address(0)){liquidityPoolAddress=liquidityPool;}
         if(distribution!=address(0)){distributionAddress=distribution;}
         if(dynamicReward!=address(0)){dynamicRewardAddress=dynamicReward;}
         if(pledgeAdd!=address(0)){pledgeAddress=pledgeAdd;}
         if(minPool!=address(0)){minPoolAddress=minPool;}
         if(newPledge!=address(0)){newPledgeAddress=newPledge;}
     }
 
        
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        require(amount >0, "ERC20: amount must more than zero ");
        
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    

    

    function getMintTotal() view public returns(uint256) {
        return mintSupplyTotal;
    }
    
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint256) {
        return _decimals;
    }

   function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address account) public view override returns (uint256) {
        return (reallyBalanceOf[account] .add(lockBalanceOf[account]).add(pledgeBalanceOf[account]));
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(amount >0, "ERC20: amount must more than zero ");
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        require(amount >0, "ERC20: amount must more than zero ");
    
        _approve(msg.sender, spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        require(amount >0, "ERC20: amount must more than zero ");
        require(_allowances[sender][msg.sender] >= amount, " _allowances must more than amount ");
        
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "transfer amount exceeds allowance"));
     return true;
    }
             
}