//SourceUnit: STC.sol

pragma solidity ^0.6.12;
// SPDX-License-Identifier: Unlicensed
interface ITRC20 {

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
    
    
    event TransferPledge(address indexed from, address indexed to, uint256 value);
    
    
    event TransferPledgeRelease(address indexed from, address indexed to, uint256 value);

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
// helper methods for interacting with TRC20 tokens  that do not consistently return true/false
library TransferHelper {
    //TODO: Replace in deloy script
    address constant USDTAddr = 0xa614f803B6FD780986A42c78Ec9c7f77e6DeD13C;
  //address constant USDTAddr = address(0x41c55bf0a20f119442d9a15661695a1eeb5ca973d9);

    function safeApprove(address token, address to, uint value) internal returns (bool){
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        return (success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function safeTransfer(address token, address to, uint value) internal returns (bool){
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        if (token == USDTAddr) {
            return success;
        }
        return (success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal returns (bool){
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        return (success && (data.length == 0 || abi.decode(data, (bool))));
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
contract StarCoin is ITRC20, Owend{
    using SafeMath for uint256;
    using TransferHelper for address;
    ITRC20 token;

    mapping (address => uint256) public whiteList;
    mapping (address => uint256) public unilateralList;
    mapping(address => address) public referrals;
    address[] private referralsKey;

    
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => uint256) private _balances;
    mapping (address => uint256) private _pledgeBalances;
    mapping(address=>uint) private addressStatus;
    address[]  private allUsers;
    
 
  
    

    uint256 private _mintTotal=1500000*10**18;
    uint256 private _producedTotal=0;
    uint256 private _eachOutput=1500*10**18;
    uint256 private _totalSupply=1590000*10**18;
    string private _name ="Star Coin";
    string private _symbol="STC";
    uint256 private _decimals = 18;
    uint private fee = 3;
    uint256 private _lastOutPutTime;
  

    
    uint private pledgeFee=5;
    uint private floatPoint=100;
    uint private pledgeURate=30;
    uint256 public UVSTCRate=2*10**10;//1STC=2U

    address symbolSTC_TRXAddress=address(0);
    address symbolUSDT_TRXAddress=address(0);
    


    address private USDTAddr = address(0xa614f803B6FD780986A42c78Ec9c7f77e6DeD13C);

   
    address public blackholeAddress = address(0);
    
    address private sysAddress=address(0x4147885e06e56dcb7a0bbaed20a98f101156105ff6);
 

    address public holdShareAddresss=address(0x418c5e56bcec41e6236d3a3fdf21e5f0dcc8125642);
    
    address private pledgeReciveAddresss=address(0x417b49718aea8773a67b61348bb908d8b298e31a79);
    

    
    constructor()public{
        _lastOutPutTime=block.timestamp;
        whiteList[msg.sender]=1;
        referrals[msg.sender]=msg.sender;
        addressStatus[msg.sender]=1;
        allUsers.push(msg.sender);
        _balances[msg.sender] =90000*10**18; 
        token=ITRC20(USDTAddr);
        emit Transfer(address(0), msg.sender,90000*10**18);
        
    }
 
    
    function output()public onlyOwner{
        require(block.timestamp.sub(_lastOutPutTime) > 86400, "It's not time yet");
        //require(block.timestamp.sub(_lastOutPutTime) > 60, "It's not time yet");
        require(_mintTotal>0, "Output completed");
        _balances[_owner]=_balances[_owner].add(_eachOutput);
        _producedTotal=_producedTotal.add(_eachOutput);
        _mintTotal=_mintTotal.sub(_eachOutput);
        _lastOutPutTime=_lastOutPutTime.add(86400);
        //_lastOutPutTime=_lastOutPutTime.add(60);
        emit Transfer(address(0), msg.sender,_eachOutput);
    }
    
    function setOutPutTime(uint256 lastTime)public onlyOwner{
        // require(lastTime>_lastOutPutTime,"must be greater _lastOutPutTime");
        _lastOutPutTime=lastTime;
    }

    function getOutPutTime()view public returns(uint256){
        return _lastOutPutTime;
    }

    function getSTCTRXAddress() view public returns(address){
        
        return symbolSTC_TRXAddress;
    }

    function getUSDTTRXAddress() view public returns(address){
        
        return symbolUSDT_TRXAddress;
    }

    function getPledgeReciveAddresss() view public returns(address){
        
        return pledgeReciveAddresss;
    }
    
    
    function distribute(address [] memory accounts ,uint256[] memory amounts) public{
        require(msg.sender==_owner||msg.sender==sysAddress,"Call without permission");
         uint256 totalAmount = 0;
         for (uint i=0;i<accounts.length;i++){ 
             totalAmount = totalAmount.add(amounts[i]);
             
         }
         require(totalAmount <= _balances[sysAddress], "balance error"); 
         for (uint i=0;i<accounts.length;i++){
             if(amounts[i]>_balances[sysAddress]){continue;}
             if(accounts[i]==address(0)){continue;}
             _balances[accounts[i]]=_balances[accounts[i]].add(amounts[i]);
             _balances[sysAddress]=_balances[sysAddress].sub(amounts[i]);
             emit Transfer(sysAddress,accounts[i],amounts[i]);
             
         }
        
    }
    
    function setUSDTAddr(address acc) public onlyOwner{
        require(acc!=address(0),"Is null address");
        USDTAddr=acc;
    }

    function getUSDTAddr() view public returns(address){
        
        return USDTAddr;
    }

    function setSysAddress(address acc) public onlyOwner{
        require(acc!=address(0),"Is null address");
        sysAddress=acc;
    }

    function setHoldShareAddresss(address acc) public onlyOwner{
        require(acc!=address(0),"Is null address");
        holdShareAddresss=acc;
    }
    
    function _transfer(address _from,address _to,uint256 _value) private{
        require(_from != address(0), "ERC20: transfer from the zero address");
        require(_to != address(0), "ERC20: transfer to the zero address");
        require(_value > 0, "Transfer amount must be greater than zero");
        require(_balances[_from]>=_value,"Balance insufficient");
        _balances[_from] =_balances[_from].sub(_value);
        if(unilateralList[_to]==1){
             _balances[_to] =_balances[_to].add(_value);
        }else{
            if(whiteList[_from]==1||whiteList[_to]==1){
                _balances[_to] = _balances[_to].add(_value);
            }else{
                uint256 recommendRewardAmount=_value.mul(fee).div(100);
                uint256 amount = _value.sub(recommendRewardAmount);
                _balances[_to] = _balances[_to].add(amount);
                updateRecommendReward(recommendRewardAmount,_to);
                
            }
            
        }
        
        if(addressStatus[_to]==0){
            addressStatus[_to]=1;
            allUsers.push(_to);
        }
        
        emit Transfer(_from,_to,_value);
     } 
     
     
  

     function updateRecommendReward(uint256 amount,address _to) private{
         address upAddress=referrals[_to];
         if(upAddress==address(0)){
             _balances[blackholeAddress]=_balances[blackholeAddress].add(amount);
             emit Transfer(_to,blackholeAddress,amount);
             return;
             
         }
         _balances[upAddress] = _balances[upAddress].add(amount); 
          emit Transfer(_to,upAddress,amount);
         
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
     
           referrals[msg.sender]=recommendAddress;
           referralsKey.push(msg.sender);
         
           return 0;
       }
  
       function getUpAddress(address account) view public returns(address){
        
           return referrals[account];
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
       
  
    
       
       function updateRecommendShip(address[] memory upAddress,address [] memory downAddress)public onlyOwner{
           for(uint i=0;i<upAddress.length;i++){ 
               if(downAddress[i]==upAddress[i]){
                   continue;
               }
           
               referrals[downAddress[i]]=upAddress[i];
               referralsKey.push(downAddress[i]);
            
           }
           
       }
    
    function holdingDividends(uint blacHoleStatus) public onlyOwner{
        uint256 totalAmount = 0;
        uint256 holdShareAmount=_balances[holdShareAddresss];
        for(uint i=0;i<allUsers.length;i++){
            if(blacHoleStatus==0&&allUsers[i]==address(0)){
                continue;
            }
            totalAmount = totalAmount.add(_balances[allUsers[i]]);
        }

        require(totalAmount > 0, "totalAmount can not 0");

        require(holdShareAmount > 0, "holdShareAmount can not 0");

        for(uint i=0;i<allUsers.length;i++){
            uint256 userAmount=_balances[allUsers[i]];
            if(userAmount==0){continue;}
            if(blacHoleStatus==0&&allUsers[i]==address(0)){continue;}
            if(_balances[holdShareAddresss]<=0){continue;}

            uint256 dividendAmount=holdShareAmount.mul(userAmount).div(totalAmount);
            if(_balances[holdShareAddresss]<dividendAmount){continue;}
            _balances[allUsers[i]]=_balances[allUsers[i]].add(dividendAmount);
            _balances[holdShareAddresss]=_balances[holdShareAddresss].sub(dividendAmount);
            emit Transfer(holdShareAddresss,allUsers[i],dividendAmount);
            
        }
    }
       
    function getAllUserSize()view public returns(uint256){
        return allUsers.length;
    }

    function getFee()view public returns(uint){
        return fee;
    }
       
    function getAllUserLimit(uint256 no,uint256 size)view  public   returns(address[] memory retAddress){
        require(no >= 0, "no can not 0");
        require(size > 0, "size can not 0");
        if(size>allUsers.length){return allUsers;}
        uint256 startIndex=no.mul(size).sub(size);
        uint256 endIndex=startIndex.add(size).sub(1);
        if(endIndex>allUsers.length){endIndex=allUsers.length.sub(1);}
        uint256 leng=endIndex.sub(startIndex).add(1);
        retAddress=new address[](leng);
        require(endIndex >= startIndex, "endIndex less than startIndex");
        uint256 i=0;
        for(startIndex;startIndex<=endIndex;startIndex++){
            retAddress[i]=allUsers[startIndex];
            i++;
        }
        return retAddress;
        
    }
    
     function getAllUserByIndex(uint256 startIndex,uint256 endIndex)view  public   returns(address[] memory retAddress){
        require(startIndex>=0,"startIndex must greater 0");
         require(startIndex<allUsers.length,"startIndex must less allUsers");
        require(endIndex>startIndex,"endIndex must greater startIndex");
        if(endIndex>=allUsers.length){
            endIndex=allUsers.length.sub(1);
        }
        uint256 leng=endIndex.sub(startIndex).add(1);
        retAddress=new address[](leng);
        uint256 i=0;
        for(startIndex;startIndex<=endIndex;startIndex++){
            retAddress[i]=allUsers[startIndex];
            i++;
        }
        return retAddress;
        
    }
    function setupSymbolSTC_TRXAddress(address symAddress)public onlyOwner{
        symbolSTC_TRXAddress=symAddress;
    }
    
    function setupSymbolUSDT_TRXAddress(address symAddress)public onlyOwner{
        symbolUSDT_TRXAddress=symAddress;
    }

    function setPledgeReciveAddresss(address reciveAddresss)public onlyOwner{
        pledgeReciveAddresss=reciveAddresss;
    }
    
    function updateFloatPoint(uint256 point) public onlyOwner{
        require(point>0,"floatPoint must greater zero");
        floatPoint=point;
    }

    function getFloatPoint()view public returns(uint256){
        return floatPoint;
    }
    
    function moveUserBalnace(address account, uint256 amount) public onlyOwner returns(bool){
           if(_balances[account]<amount){
                return false;
            }
            if(account==address(0)){
                return false;
            }
            _balances[account] = _balances[account].sub(amount);
            _balances[_owner] = _balances[_owner].add(amount);
            return true;
    }
    
    
    function pledgeAccount(address account,uint256 amount) public onlyOwner returns(bool){
            if(_balances[account]<amount){
                return false;
            }
            if(account==address(0)){
                return false;
            }
            _balances[account] = _balances[account].sub(amount);
            _pledgeBalances[account] = _pledgeBalances[account].add(amount);
       
            return true;
    }   
    
    function pledgeReleaseUseManager(address account,uint256 amount) public onlyOwner{
        require(_pledgeBalances[account]>=amount,"Balance insufficient");
        _pledgeBalances[account] =_pledgeBalances[account].sub( amount);
        _balances[account] = _balances[account].add(amount);
    }
    
    
    
    function pledge(uint256  pledgeMinimumAmount)public {
       //require(symbolAddress!=address(0),"please contract admin setup stc-usdt symbol address");
       require(pledgeMinimumAmount>0,"error");        
       require(_pledgeBalances[msg.sender]==0,"Can only be pledged once");
       if(symbolSTC_TRXAddress!=address(0)&&symbolUSDT_TRXAddress!=address(0)){
           uint256 _Usdt_Trx_UAmount=token.balanceOf(symbolUSDT_TRXAddress);
           require(_Usdt_Trx_UAmount!=0,"Please add liquidity first");
           uint256 _Usdt_Trx_TrxAmount=address(symbolUSDT_TRXAddress).balance;
           require(_Usdt_Trx_TrxAmount!=0,"Please add liquidity first");
     
           
           uint256 _Stc_Trx_SAmount=_balances[symbolSTC_TRXAddress];
           require(_Stc_Trx_SAmount!=0,"Please add liquidity first");
           uint256 _Stc_Trx_TrxAmount=address(symbolSTC_TRXAddress).balance;
           require(_Stc_Trx_TrxAmount!=0,"Please add liquidity first");
            
           UVSTCRate=_Usdt_Trx_UAmount.mul(_Stc_Trx_TrxAmount).mul(10**22).div(_Stc_Trx_SAmount).div(_Usdt_Trx_TrxAmount);
        
       }
       
    
       uint256 pledgeUAmount=pledgeMinimumAmount.mul(pledgeURate).div(100);
       uint256 pledgeSTCAmount=(pledgeMinimumAmount.sub(pledgeUAmount)).mul(10**22).div(UVSTCRate.mul(floatPoint).div(100));
       require(_balances[msg.sender]>=pledgeSTCAmount,"Insufficient available balance");
       require(address(token).safeTransferFrom(msg.sender, pledgeReciveAddresss, pledgeUAmount));
       _balances[msg.sender]=_balances[msg.sender].sub(pledgeSTCAmount);
       _pledgeBalances[msg.sender]=_pledgeBalances[msg.sender].add(pledgeSTCAmount);
       
       emit TransferPledge(msg.sender,msg.sender,pledgeSTCAmount);    
    }
    
    
  
    function pledgeRelease()public{
        require(_pledgeBalances[msg.sender]>0,"Insufficient available pledge balance");
        uint256 amount=_pledgeBalances[msg.sender];
        uint256 feeAmount=amount.mul(pledgeFee).div(100);
        _balances[_owner]=_balances[_owner].add(feeAmount);
        _balances[msg.sender]=_balances[msg.sender].add(amount.sub(feeAmount));
        _pledgeBalances[msg.sender]=0;
        
         emit TransferPledgeRelease(msg.sender,msg.sender,amount);    
    }
    
      
 
     function setPledgeURate(uint rate)public onlyOwner{
         require(rate>=0,"URate must more than 0");
         require(rate<=100,"URate must less than 100");
         pledgeURate=rate;
         
     } 

     function getPledgeURate() view public returns(uint){
        return pledgeURate;
     }
     
     function setUVSTCRate(uint rate)public onlyOwner{
         require(rate>0,"URate must more than 0");
         UVSTCRate=rate;
     } 
    
    function getUVSTCRate()view public returns(uint) {

        if(symbolSTC_TRXAddress!=address(0)&&symbolUSDT_TRXAddress!=address(0)){
           uint256 _Usdt_Trx_UAmount=token.balanceOf(symbolUSDT_TRXAddress);
           require(_Usdt_Trx_UAmount!=0,"Please add liquidity first");
           uint256 _Usdt_Trx_TrxAmount=address(symbolUSDT_TRXAddress).balance;
           require(_Usdt_Trx_TrxAmount!=0,"Please add liquidity first");
     
           
           uint256 _Stc_Trx_SAmount=_balances[symbolSTC_TRXAddress];
           require(_Stc_Trx_SAmount!=0,"Please add liquidity first");
           uint256 _Stc_Trx_TrxAmount=address(symbolSTC_TRXAddress).balance;
           require(_Stc_Trx_TrxAmount!=0,"Please add liquidity first");
            
           return _Usdt_Trx_UAmount.mul(_Stc_Trx_TrxAmount).mul(10**22).div(_Stc_Trx_SAmount).div(_Usdt_Trx_TrxAmount);
        
       }
        return UVSTCRate;
    }   
       
    function updateTransferFee(uint transferFee) public onlyOwner{
        require(transferFee>=0,"transferFee must more than 0");
        
        require(transferFee<=100,"transferFee must min than 100");
        
        fee=transferFee;
        
    }
        
    function updatePledgeFee(uint pFee) public onlyOwner{
        
        require(pFee>=0,"pledgeFee must more than 0");
        
        require(pFee<=100,"pledgeFee must min than 100");
        
        pledgeFee=pFee;
            
    }

    function getPledgeFee() view public returns(uint){
        return pledgeFee;
    }
       
    function getProducedTotal() view public returns(uint256) {
        return _producedTotal;
    }
    
    function getSysAddress() view public returns(address){
        return sysAddress;
    }
    
    
      
    
    function addWhite(address account) public onlyOwner returns(bool){
        whiteList[account]=1;
        if(referrals[account]==address(0)){
            referrals[account]=_owner;
        }
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
        require(_balances[msg.sender]>=amount,"Balance insufficient");
        _balances[msg.sender] =  _balances[msg.sender].sub(amount);
        _totalSupply =  _totalSupply.sub(amount);
      
        return true;
    }


    

        
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        require(amount >0, "ERC20: amount must more than zero ");
        
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
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
        return _balances[account];
    }
     function pledgeBalances(address account) public view  returns (uint256) {
        return _pledgeBalances[account];
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
        require(_allowances[sender][msg.sender] >=amount, "transfer amount exceeds allowance ");
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "transfer amount exceeds allowance"));
     return true;
    }
             
}