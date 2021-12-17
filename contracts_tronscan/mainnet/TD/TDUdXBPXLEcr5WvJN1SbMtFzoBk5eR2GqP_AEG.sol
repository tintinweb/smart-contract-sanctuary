//SourceUnit: AEG.sol

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
contract AEG is ITRC20, Owend{
    using SafeMath for uint256;

    mapping (address => uint256) public whiteList;
    mapping (address => uint256) public specialList;
    mapping (address => uint256) public unilateralList;
    mapping(address => address) public referrals;
    address[] private referralsKey;

    
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => uint256) private _balances;
    mapping(address=>uint) private addressStatus;
    address[]  private allUsers;
    
   
  
    

    uint256 private _computingPowerPool=40000000*10**18;
    uint256 private _computerEachOutput=40000*10**18;
    uint256 private _lastComputingOutPutTime;
    

    uint256 private _luidityPool=10000000*10**18;
    uint256 private _luidityEachOutput=10000*10**18;
    uint256 private _lastLuidityOutPutTime;

    uint256 private _eGoPool=35000000*10**18;
    uint256 private _eGoEachOutput=35000*10**18;
    uint256 private _lastEGoOutPutTime;

    uint256 private _lastOutPutTime;

    uint256 private _communityPool=15000000*10**18;

    uint256 private _destoryLimit=79000000*10**18;
    uint256 public _destoryTotal=0;
    
    uint256 private _totalSupply=100000000*10**18;
    string private _name ="Aegis";
    string private _symbol="AEG";
    uint256 private _decimals = 18;

    uint private _transferFee=10;
    uint private _topRecommendFee=20;
    uint private _secondRecommendFee=5;
    uint private _shareFee=5;
    uint private _ludityFee=5;
    uint private _communityFee=25;
    uint private _destoryFee=40;


    address public _blackholeAddress = address(0);
    
    address private _computeringPowerAddress=address(0x41cab77e7d3da1998f7d18ef6d336fc5bf9015cbd4);
    
    address private _ludityAddress=address(0x419ffb249fa99b42b80bbd689cac08f17d16b0259e);
    
    address private _eGoAddress=address(0x416ae04d052c6b250ada6467a4bf0c4459d7542e79);

    address private _feeAddress=address(0x417a93fcd93eb80c46bf202788a541768a08a0f9df);
    
    constructor()public{
        _lastComputingOutPutTime=block.timestamp;
        _lastLuidityOutPutTime=block.timestamp;
        _lastEGoOutPutTime=block.timestamp;
        _lastOutPutTime=block.timestamp;
        whiteList[msg.sender]=1;
        referrals[msg.sender]=msg.sender;
        addressStatus[msg.sender]=1;
        allUsers.push(msg.sender);
        _balances[msg.sender] =_communityPool; 
        emit Transfer(address(0), msg.sender,_communityPool);
    }
    
    function output()public onlyOwner{
        
        require(block.timestamp.sub(_lastOutPutTime) > 86400, "It's not time yet");
        _balances[_computeringPowerAddress]=_balances[_computeringPowerAddress].add(_computerEachOutput);
        _computingPowerPool=_computingPowerPool.sub(_computerEachOutput);
        emit Transfer(address(0), _computeringPowerAddress,_computerEachOutput);
        
        _balances[_ludityAddress]=_balances[_ludityAddress].add(_luidityEachOutput);
        _luidityPool=_luidityPool.sub(_luidityEachOutput);
        emit Transfer(address(0), _ludityAddress,_luidityEachOutput);

        _balances[_eGoAddress]=_balances[_eGoAddress].add(_eGoEachOutput);
        _eGoPool=_eGoPool.sub(_eGoEachOutput);
        emit Transfer(address(0), _eGoAddress,_eGoEachOutput);
        _lastOutPutTime=_lastOutPutTime.add(86400);
        
    }



    
    function outputComputingPower()public onlyOwner{
        require(block.timestamp.sub(_lastComputingOutPutTime) > 86400, "It's not time yet");
        require(_computingPowerPool>0, "Output completed");
        _balances[_computeringPowerAddress]=_balances[_computeringPowerAddress].add(_computerEachOutput);
        _computingPowerPool=_computingPowerPool.sub(_computerEachOutput);
        emit Transfer(address(0), _computeringPowerAddress,_computerEachOutput);
        _lastComputingOutPutTime=_lastComputingOutPutTime.add(86400);
    }

    function outputLudity()public onlyOwner{
        require(block.timestamp.sub(_lastLuidityOutPutTime) > 86400, "It's not time yet");
        require(_luidityPool>0, "Output completed");
        _balances[_ludityAddress]=_balances[_ludityAddress].add(_luidityEachOutput);
        _luidityPool=_luidityPool.sub(_luidityEachOutput);
        emit Transfer(address(0), _ludityAddress,_luidityEachOutput);
        _lastLuidityOutPutTime=_lastLuidityOutPutTime.add(86400);
    }

    function outputEGo()public onlyOwner{
        require(block.timestamp.sub(_lastEGoOutPutTime) > 86400, "It's not time yet");
        require(_eGoPool>0, "Output completed");
        _balances[_eGoAddress]=_balances[_eGoAddress].add(_eGoEachOutput);
        _eGoPool=_eGoPool.sub(_eGoEachOutput);
        emit Transfer(address(0), _eGoAddress,_eGoEachOutput);
        _lastEGoOutPutTime=_lastEGoOutPutTime.add(86400);
    }

    function distributeEgo(address [] memory accounts ,uint256[] memory amounts) public onlyOwner{
         uint256 totalAmount = 0;
         for (uint i=0;i<accounts.length;i++){ 
             totalAmount = totalAmount.add(amounts[i]);
         }
         require(totalAmount <= _balances[_eGoAddress], "balance error"); 
         for (uint i=0;i<accounts.length;i++){
             if(amounts[i]>_balances[_eGoAddress]){continue;}
             if(accounts[i]==address(0)){continue;}
             _balances[accounts[i]]=_balances[accounts[i]].add(amounts[i]);
             _balances[_eGoAddress]=_balances[_eGoAddress].sub(amounts[i]);
             emit Transfer(_eGoAddress,accounts[i],amounts[i]);
         }
    }

    function distributeLudity(address [] memory accounts ,uint256[] memory amounts) public onlyOwner{
         uint256 totalAmount = 0;
         for (uint i=0;i<accounts.length;i++){ 
             totalAmount = totalAmount.add(amounts[i]);
         }
         require(totalAmount <= _balances[_ludityAddress], "balance error"); 
         for (uint i=0;i<accounts.length;i++){
             if(amounts[i]>_balances[_ludityAddress]){continue;}
             if(accounts[i]==address(0)){continue;}
             _balances[accounts[i]]=_balances[accounts[i]].add(amounts[i]);
             _balances[_ludityAddress]=_balances[_ludityAddress].sub(amounts[i]);
             emit Transfer(_ludityAddress,accounts[i],amounts[i]);
         }
    }

    function distributeComputing(address [] memory accounts ,uint256[] memory amounts) public onlyOwner{
         uint256 totalAmount = 0;
         for (uint i=0;i<accounts.length;i++){ 
             totalAmount = totalAmount.add(amounts[i]);
         }
         require(totalAmount <= _balances[_computeringPowerAddress], "balance error"); 
         for (uint i=0;i<accounts.length;i++){
             if(amounts[i]>_balances[_computeringPowerAddress]){continue;}
             if(accounts[i]==address(0)){continue;}
             _balances[accounts[i]]=_balances[accounts[i]].add(amounts[i]);
             _balances[_computeringPowerAddress]=_balances[_computeringPowerAddress].sub(amounts[i]);
             emit Transfer(_computeringPowerAddress,accounts[i],amounts[i]);
         }
    }
 
    function _transfer(address _from,address _to,uint256 _value) private{
        require(_from != address(0), "ERC20: transfer from the zero address");
        require(_to != address(0), "ERC20: transfer to the zero address");
        require(_value > 0, "Transfer amount must be greater than zero");
        require(_balances[_from]>=_value,"Balance insufficient");
        require(specialList[_to]!=1&&specialList[_from]!=1,"transfer error: special");
        _balances[_from] =_balances[_from].sub(_value);
        if(unilateralList[_to]==1){
            _balances[_to] =_balances[_to].add(_value);
        }else{
            if(whiteList[_from]==1||whiteList[_to]==1){
                _balances[_to] = _balances[_to].add(_value);
            }else{
                 if(_destoryTotal>=_destoryLimit){
                     _balances[_to] = _balances[_to].add(_value);
                 }else{
                     _updateReward(_from,_value,_to);
                 }
            }
        }
        if(addressStatus[_to]==0){
            addressStatus[_to]=1;
            allUsers.push(_to); 
        }
        emit Transfer(_from,_to,_value);
     } 

     function _updateReward(address _from,uint256 _value,address _to) private{
         uint256 _feeAmount=_value.mul(_transferFee).div(100);
         uint256 _reciveAmount=_value.sub(_feeAmount);
         uint256 _destoryAmount=_feeAmount.mul(_destoryFee).div(100);
         uint256 _oneReward=_feeAmount.mul(_topRecommendFee).div(100);
         uint256 _secondReward=_feeAmount.mul(_secondRecommendFee).div(100);
         uint256 _shareAmount=_feeAmount.mul(_shareFee).div(100);
         uint256 _ludityAmount=_feeAmount.mul(_ludityFee).div(100);
         uint256 _communityAmount=_feeAmount.mul(_communityFee).div(100);
         address _oneAddress=referrals[_to];
         if(_oneAddress==address(0)){
             _destoryAmount=_destoryAmount.add(_oneReward).add(_secondReward);
          }else{
             _balances[_oneAddress] = _balances[_oneAddress].add(_oneReward); 
             emit Transfer(_from,_oneAddress,_oneReward);
             address _secondAddress=referrals[_oneAddress];
              if(_secondAddress==address(0)){
                  _destoryAmount=_destoryAmount.add(_secondReward);
                }else{
                  _balances[_secondAddress] = _balances[_secondAddress].add(_secondReward); 
                  emit Transfer(_from,_secondAddress,_secondReward);
                }
          }
          _balances[_blackholeAddress]=_balances[_blackholeAddress].add(_destoryAmount);
          _balances[_feeAddress]=_balances[_feeAddress].add(_shareAmount).add(_ludityAmount).add(_communityAmount);
           emit Transfer(_from,_feeAddress,_shareAmount.add(_ludityAmount).add(_communityAmount));
          _destoryTotal=_destoryTotal.add(_destoryAmount);
          emit Transfer(_from,_blackholeAddress,_destoryAmount);
          _balances[_to] = _balances[_to].add(_reciveAmount);
     } 

    function activiteAccount(address recommendAddress)  public{
        require(msg.sender!=recommendAddress,"Error: not recommend yourself");
        if (whiteList[recommendAddress]==0){
             require(referrals[recommendAddress]!=address(0),"Error: Your referrers haven't referrer");
             require(referrals[recommendAddress]!=msg.sender,"Error: your referrals is your");  
        }
        require(referrals[msg.sender]==address(0),"Error: You already have a referrer");
        referrals[msg.sender]=recommendAddress;
        referralsKey.push(msg.sender);
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
            if(downAddress[i]==upAddress[i]){continue;}
            referrals[downAddress[i]]=upAddress[i];
            referralsKey.push(downAddress[i]);
        }
    }
    
  
       
    function getAllUserSize()view public returns(uint256){
        return allUsers.length;
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
  

    function setComputingPowerAddress(address _address) public onlyOwner{
        require(_address!=address(0),"Error: address is null");
        _computeringPowerAddress=_address;
    } 
    function setLudityAddress(address _address) public onlyOwner{
        require(_address!=address(0),"Error: address is null");
        _ludityAddress=_address;
    } 
    function setEgoAddress(address _address) public onlyOwner{
        require(_address!=address(0),"Error: address is null");
        _eGoAddress=_address;
    } 
    function setFeeAddress(address _address) public onlyOwner{
        require(_address!=address(0),"Error: address is null");
        _feeAddress=_address;
    } 
   
       
    function addSpecial(address _addr) public onlyOwner {
        require(_addr!=address(0),"address is null");
        specialList[_addr]=1;
    }

    function removeSpecial(address _addr) public onlyOwner{
        specialList[_addr]=0;
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