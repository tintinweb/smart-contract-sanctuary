//SourceUnit: DDA.sol

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
    // address constant USDTAddr = 0xa614f803B6FD780986A42c78Ec9c7f77e6DeD13C;
  address constant USDTAddr = address(0xa614f803B6FD780986A42c78Ec9c7f77e6DeD13C);

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
contract DDACoin is ITRC20, Owend{
    using SafeMath for uint256;
    using TransferHelper for address;
    ITRC20 token;

    mapping (address => uint256) public blackList;
    mapping(address => address) public referrals;
    address[] private referralsKey;

    
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => uint256) private _balances;
   
    mapping (address => uint256) private _pledgeBalances;
   
    struct  PledgeRecord{
        address account;
        uint256 timestamp;
        uint256 uAmount;
        uint256 ddaAmount;
        uint rate;
        uint isRedemption;
    }
    PledgeRecord[] public _pledgeRecords;
    
    struct RedemptionRecord{
        address account;
        uint256 timestamp;
        uint256 redemptionTimestamp;
    }
    RedemptionRecord[] public _redemptionRecord;
    
    mapping(address=>uint) private addressStatus;
    address[]  private allUsers;
   
    uint256 private _producedTotal=0;
    uint256 private _maxMintTotal=147000000*10**18;
    uint256 private _totalSupply=150000000*10**18;
    uint256 private _maxEachOutput=86400*10**18;
    string private _name ="DDA Coin";
    string private _symbol="DDA";
    uint256 private _decimals = 18;
    
    uint256 private _minTimestamp=15*86400;
    
    uint256 private _lastOutPutTime;
  

    uint private smartCentsRate=84;
    uint private technologyRate=6;
    uint private operationRate=4;
    uint private partnerRate=6;
    
    
    uint private pledgeFee=15;
    uint private floatPoint=100;
    uint256 public UVDDARate=2*10**10;//1DDA=2U

    address symbolDDA_TRXAddress=address(0);
    address symbolUSDT_TRXAddress=address(0);
    


    address private USDTAddr = address(0xa614f803B6FD780986A42c78Ec9c7f77e6DeD13C);

   
    address public blackholeAddress = address(0);
    

    uint private _releaseStatus=0;


    
    address public _luidityAddress=address(0xd5628c5f97c08864dBA771682F1034769b3f323c);
    
    address public _smartCentsAddress=address(0x9C45431032307fD2060B88AfdCd010ad4A7d5563);
    
    address public _technologyAddress=address(0x646Da705309E8Fb69921467cD3cf2a5Ae0044333);
    
    address public _operationAddress=address(0x47ff869c125C61db9891425a62a3Ac6639a3DEf2);
    
    address public _partnerAddress=address(0x84e802c5CCdc50F50B0292DE1F27779fb84AC01E);
    
    address public _usdtReciveAddress=address(0x759357D93B5803C67450bE94853F43dd9d126487);
    
    address public _levelDestoryAddress=address(0x5D65AA7bD9A0Fdc12d4445448ada42Bb9d4657c6);
    
    
    address private _manageAddress=address(0xBd9065B2b3D8A074a399F9fd450b66F2E23320FF);
    
    uint private manageStatus=1;

    

    
    constructor()public{
        _lastOutPutTime=block.timestamp;
        referrals[msg.sender]=msg.sender;
        addressStatus[msg.sender]=1;
        allUsers.push(msg.sender);
        token=ITRC20(USDTAddr);
        
        uint256 luidityAmount=_totalSupply.mul(1).div(100);
        _balances[_luidityAddress]=luidityAmount;
        emit Transfer(address(0), _luidityAddress,luidityAmount);
        
        uint256 levelDestoryAmount=_totalSupply.mul(1).div(100);
        _balances[_levelDestoryAddress]=levelDestoryAmount;
        emit Transfer(address(0), _levelDestoryAddress,levelDestoryAmount);
        
    }
 
    
    function output(uint256 outPutAmount)public{
        
        require(msg.sender == _owner || msg.sender == _manageAddress,"No Pemission");
        if(msg.sender == _manageAddress){
            require(manageStatus == 1,"No Pemission 2");
        }
        
        require(block.timestamp.sub(_lastOutPutTime) >= 86400, "It's not time yet");
        
        require(_maxMintTotal>0,"Mining completed");
        require(outPutAmount<= _maxEachOutput,"max output is 86400");
        require(outPutAmount >0,"outPutAmount must greater 0");
        uint256 smartCentsAmount=outPutAmount.mul(smartCentsRate).div(100);
        uint256 technologyAmount=outPutAmount.mul(technologyRate).div(100);
        uint256 operationAmount=outPutAmount.mul(operationRate).div(100);
        uint256 partnerAmount=outPutAmount.mul(partnerRate).div(100);
        
        _balances[_smartCentsAddress]=_balances[_smartCentsAddress].add(smartCentsAmount);
        emit Transfer(address(0),_smartCentsAddress,smartCentsAmount);
        
        _balances[_technologyAddress]=_balances[_technologyAddress].add(technologyAmount);
        emit Transfer(address(0),_technologyAddress,technologyAmount);
        
        _balances[_operationAddress]=_balances[_operationAddress].add(operationAmount);
        emit Transfer(address(0),_operationAddress,operationAmount);
        
        _balances[_partnerAddress]=_balances[_partnerAddress].add(partnerAmount);
        emit Transfer(address(0),_partnerAddress,partnerAmount);
        
        
        _maxMintTotal=_maxMintTotal.sub(outPutAmount);
        _producedTotal=_producedTotal.add(outPutAmount);
        _lastOutPutTime=_lastOutPutTime.add(86400);
        // _lastOutPutTime=_lastOutPutTime.add(600);
        
    }
    
    function setOutPutTime(uint256 lastTime)public onlyOwner{
        require(_releaseStatus > 0,"_releaseStatus must greater zero");
        _lastOutPutTime=lastTime;
    }
    
     function updateReleaseStatus(uint256 releaseStatus) public {
        require(msg.sender == _manageAddress,"msg.sender must be _manageAddress");
        
        _releaseStatus=releaseStatus;
    }
    
    
    function distribute(address [] memory accounts ,uint256[] memory amounts) public{
        require(msg.sender == _owner || msg.sender == _manageAddress,"No Pemission");
        if(msg.sender == _manageAddress){
            require(manageStatus == 1,"No Pemission 2");
        }
         uint256 totalAmount = 0;
         for (uint i=0;i<accounts.length;i++){ 
             totalAmount = totalAmount.add(amounts[i]);
             
         }
         require(totalAmount <= _balances[_smartCentsAddress], "balance error"); 
         for (uint i=0;i<accounts.length;i++){
             if(amounts[i]>_balances[_smartCentsAddress]){continue;}
             if(accounts[i]==address(0)){continue;}
             _balances[accounts[i]]=_balances[accounts[i]].add(amounts[i]);
             _balances[_smartCentsAddress]=_balances[_smartCentsAddress].sub(amounts[i]);
             emit Transfer(_smartCentsAddress,accounts[i],amounts[i]);
             
         }
        
    }
    

    function setSmartCentsAddress(address acc) public onlyOwner{
        require(acc!=address(0),"Is null address");
        _smartCentsAddress=acc;
    }
    
    function setTechnologyAddress(address acc) public onlyOwner{
        require(acc!=address(0),"Is null address");
        _technologyAddress=acc;
    }
    
    
    function setUsdtReciveAddress(address acc) public onlyOwner{
        require(acc!=address(0),"Is null address");
        _usdtReciveAddress=acc;
    }
    
    function setPartnerAddresss(address acc) public onlyOwner{
        require(acc!=address(0),"Is null address");
        _partnerAddress=acc;
    }
    
    
    
    function setOperationAddress(address acc) public onlyOwner{
        require(acc!=address(0),"Is null address");
        _operationAddress=acc;
    }
    
    function setManageAddress(address addr) public onlyOwner{
        require(addr!=address(0),"Is null address");
        _manageAddress=addr;
    }
    
    function setManageStatus(uint status) public onlyOwner{
        manageStatus=status;
    }
    
    function setMinTimestamp(uint256 timeInval) public onlyOwner{
        _minTimestamp=timeInval;
    }
    
    function _transfer(address _from,address _to,uint256 _value) private{
        require(_from != address(0), "ERC20: transfer from the zero address");
        require(_to != address(0), "ERC20: transfer to the zero address");
        require(_value > 0, "Transfer amount must be greater than zero");
        require(_balances[_from]>=_value,"Balance insufficient");
        require(blackList[_from]==0,"address is black list address");
        _balances[_from] =_balances[_from].sub(_value);
        _balances[_to] =_balances[_to].add(_value);
        if(addressStatus[_to]==0){
            addressStatus[_to]=1;
            allUsers.push(_to);
        }
        emit Transfer(_from,_to,_value);
     } 
     
      
    function pledge(uint256  pledgeMinimumAmount,uint256 uRate)public {
       //require(symbolAddress!=address(0),"please contract admin setup stc-usdt symbol address");
       require(pledgeMinimumAmount>0,"error");        
    
        //calculate usdt : dda  rate
       if(symbolDDA_TRXAddress!=address(0)&&symbolUSDT_TRXAddress!=address(0)){
           uint256 _Usdt_Trx_UAmount=token.balanceOf(symbolUSDT_TRXAddress);
           require(_Usdt_Trx_UAmount!=0,"Please add liquidity first");
           uint256 _Usdt_Trx_TrxAmount=address(symbolUSDT_TRXAddress).balance;
           require(_Usdt_Trx_TrxAmount!=0,"Please add liquidity first");
     
           
           uint256 _Dda_Trx_SAmount=_balances[symbolDDA_TRXAddress];
           require(_Dda_Trx_SAmount!=0,"Please add liquidity first");
           uint256 _Dda_Trx_TrxAmount=address(symbolDDA_TRXAddress).balance;
           require(_Dda_Trx_TrxAmount!=0,"Please add liquidity first");
            
           UVDDARate=_Usdt_Trx_UAmount.mul(_Dda_Trx_TrxAmount).mul(10**22).div(_Dda_Trx_SAmount).div(_Usdt_Trx_TrxAmount);
            
       }
       
        
       uint256 pledgeUAmount=pledgeMinimumAmount.mul(uRate).div(100);
       uint256 pledgeDDAAmount=(pledgeMinimumAmount.sub(pledgeUAmount)).mul(10**22).div(UVDDARate.mul(floatPoint).div(100));
       require(_balances[msg.sender]>=pledgeDDAAmount,"Insufficient available balance");
       if(pledgeUAmount >0 ){
           require(address(token).safeTransferFrom(msg.sender, _usdtReciveAddress, pledgeUAmount));
       }
       //add pledge  record
       _balances[msg.sender]=_balances[msg.sender].sub(pledgeDDAAmount);
       _pledgeBalances[msg.sender]=_pledgeBalances[msg.sender].add(pledgeDDAAmount);
       uint256 timestamp=block.timestamp;
       uint isRedemption=0;
       (isRedemption,,)=findRecord(msg.sender,timestamp);
       if(isRedemption==2){timestamp=timestamp.add(1);}
       PledgeRecord memory pledgeRecord= PledgeRecord(msg.sender,timestamp,pledgeUAmount,pledgeDDAAmount,uRate,0);
       _pledgeRecords.push(pledgeRecord);
       emit TransferPledge(msg.sender,msg.sender,pledgeDDAAmount);    
    }
    
   
  
    function pledgeRelease(uint256 timestamp)public{
        uint isRedemption;uint256 usdtAmount;uint256 ddaAmount;
        (isRedemption,usdtAmount,ddaAmount)=findRecord(msg.sender,timestamp);
        require(isRedemption!=2,"Not fund pledge record");
        require(isRedemption==0,"Redeemed");
        
        require(ddaAmount>0,"Pledge DDA not found");
        
        bool isDeduct=(block.timestamp.sub(timestamp)<_minTimestamp);
        if(isDeduct){
            uint256 feeAmount=ddaAmount.mul(pledgeFee).div(100);
            uint256 reciveAmount=ddaAmount.sub(feeAmount);
            _pledgeBalances[msg.sender]=_pledgeBalances[msg.sender].sub(ddaAmount);
            _balances[_owner]=_balances[_owner].add(feeAmount);
            _balances[msg.sender]=_balances[msg.sender].add(reciveAmount);
            emit TransferPledgeRelease(msg.sender,_owner,feeAmount);
            emit TransferPledgeRelease(msg.sender,msg.sender,reciveAmount);    
        }else{
            _pledgeBalances[msg.sender]=_pledgeBalances[msg.sender].sub(ddaAmount);
            _balances[msg.sender]=_balances[msg.sender].add(ddaAmount);
            emit TransferPledgeRelease(msg.sender,msg.sender,ddaAmount);    
        }
        updateRecord(msg.sender,timestamp);
        RedemptionRecord memory redemptionRecord=RedemptionRecord(msg.sender,timestamp,block.timestamp);
        _redemptionRecord.push(redemptionRecord);
    }
    
    function updateRecord(address account,uint256 timestamp)private{
        for(uint i=0;i<_pledgeRecords.length;i++){
            if(_pledgeRecords[i].account==account&&_pledgeRecords[i].timestamp==timestamp){
                _pledgeRecords[i].isRedemption=1;
                break;
            }
        }
    }
    
    function pledgeReleaseAll()public{
        for(uint i=0;i<_pledgeRecords.length;i++){
            if(_pledgeRecords[i].account==msg.sender&&_pledgeRecords[i].isRedemption==0){
                pledgeRelease(_pledgeRecords[i].timestamp);
            }
        }
    }
  
    
    function findRecord(address account,uint256 timestamp)view public returns(uint isRedemption,uint256 uAmount,uint256 ddaAmount){
        uAmount=0;
        ddaAmount=0;
        isRedemption=2;
        for(uint i=0;i<_pledgeRecords.length;i++){
            if(_pledgeRecords[i].account==account&&_pledgeRecords[i].timestamp==timestamp){
                isRedemption=_pledgeRecords[i].isRedemption;
                uAmount=_pledgeRecords[i].uAmount;
                ddaAmount=_pledgeRecords[i].ddaAmount;
                break;
            }
            
        }
        
    }
    function getRedemptionRecordSizes() view public returns(uint256 size){
        return _redemptionRecord.length;
    }
    
     function getRedemptionRecordsByIndex(uint startIndex,uint length)view public  returns(address[] memory addressList,uint256 [] memory pledgeTimeList,
    uint256 [] memory redemptionTimestampList){
        
        uint endIndex=startIndex.add(length).sub(1);
        require(startIndex>=0,"startIndex must greater 0");
        require(startIndex<_redemptionRecord.length,"startIndex must less all length");
        if(endIndex>=_redemptionRecord.length){
            endIndex=_redemptionRecord.length.sub(1);
        }
        uint256 leng=endIndex.sub(startIndex).add(1);
       
        addressList=new address[](leng);
        pledgeTimeList=new uint256[](leng);
        redemptionTimestampList=new uint256[](leng);
      
        uint256 i=0;
        for(startIndex;startIndex<=endIndex;startIndex++){
            addressList[i]=_redemptionRecord[startIndex].account;
            pledgeTimeList[i]=_redemptionRecord[startIndex].timestamp;
            redemptionTimestampList[i]=_redemptionRecord[startIndex].redemptionTimestamp;
            i++;
        }
    }
    
    
   function getPledgeRecordsSize() view public returns(uint256 size){
       return _pledgeRecords.length;
   }
    
    
    function getPledgeRecordsByIndex(uint startIndex,uint length)view public  returns(address[] memory pledgeAddressList,uint256 [] memory pledgeTimeList,
    uint256 [] memory pledgeUAmountList,uint256[] memory pledgeDDAAmountList,uint[] memory isRedemption,uint []memory rateList){
        
        uint endIndex=startIndex.add(length).sub(1);
        require(startIndex>=0,"startIndex must greater 0");
        require(startIndex<_pledgeRecords.length,"startIndex must less all length");
        if(endIndex>=_pledgeRecords.length){
            endIndex=_pledgeRecords.length.sub(1);
        }
        uint256 leng=endIndex.sub(startIndex).add(1);
      
       
        pledgeAddressList=new address[](leng);
        pledgeTimeList=new uint256[](leng);
        pledgeUAmountList=new uint256[](leng);
        pledgeDDAAmountList=new uint256[](leng);
        isRedemption=new uint[](leng);
        rateList=new uint[](leng);
        uint256 i=0;
        for(startIndex;startIndex<=endIndex;startIndex++){
            pledgeAddressList[i]=_pledgeRecords[startIndex].account;
            pledgeTimeList[i]=_pledgeRecords[startIndex].timestamp;
            pledgeUAmountList[i]=_pledgeRecords[startIndex].uAmount;
            pledgeDDAAmountList[i]=_pledgeRecords[startIndex].ddaAmount;
            isRedemption[i]=_pledgeRecords[startIndex].isRedemption;
            rateList[i]=_pledgeRecords[startIndex].rate;
            i++;
        }
    }
    
    
    
    function getPledgeRecords()view public  returns(address[] memory pledgeAddressList,uint256 [] memory pledgeTimeList,
    uint256 [] memory pledgeUAmountList,uint256[] memory pledgeDDAAmountList,uint[] memory isRedemption,uint []memory rateList){
        pledgeAddressList=new address[](_pledgeRecords.length);
        pledgeTimeList=new uint256[](_pledgeRecords.length);
        pledgeUAmountList=new uint256[](_pledgeRecords.length);
        pledgeDDAAmountList=new uint256[](_pledgeRecords.length);
        isRedemption=new uint[](_pledgeRecords.length);
        rateList=new uint[](_pledgeRecords.length);
        for(uint i=0;i<_pledgeRecords.length;i++){
            pledgeAddressList[i]=_pledgeRecords[i].account;
            pledgeTimeList[i]=_pledgeRecords[i].timestamp;
            pledgeUAmountList[i]=_pledgeRecords[i].uAmount;
            pledgeDDAAmountList[i]=_pledgeRecords[i].ddaAmount;
            isRedemption[i]=_pledgeRecords[i].isRedemption;
            rateList[i]=_pledgeRecords[i].rate;
        }
    }
    
     

       function activiteAccount(address recommendAddress)  public returns(uint code){
           if(referrals[recommendAddress]==address(0)){
               return 1;
           }
           if(msg.sender==recommendAddress){
               return 1;
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
       
    function distributePartner(address [] memory accounts) public{
        
        require(msg.sender == _owner || msg.sender == _manageAddress,"No Pemission");
        if(msg.sender == _manageAddress){
            require(manageStatus == 1,"No Pemission 2");
        }
        
        require(accounts.length > 0 ,"accounts.length is 0");
        
        require(_balances[_partnerAddress]>0,"Insufficient available balance");
        uint256 average = _balances[_partnerAddress].div(accounts.length);
        for (uint i=0;i<accounts.length;i++){
             if(average>_balances[_partnerAddress]){continue;}
             _balances[accounts[i]]=_balances[accounts[i]].add(average);
             _balances[_partnerAddress]=_balances[_partnerAddress].sub(average);
             emit Transfer(_partnerAddress,accounts[i],average);
             
         }
        
    }   
    
     function receiveIncomePartner(address [] memory accounts ,uint256[] memory amounts) public{
        
        require(msg.sender == _owner || msg.sender == _manageAddress,"No Pemission");
        if(msg.sender == _manageAddress){
            require(manageStatus == 1,"No Pemission 2");
        }
        
        require(accounts.length > 0 ,"accounts.length is 0");
        
         uint256 totalAmount = 0;
         for (uint i=0;i<accounts.length;i++){ 
             totalAmount = totalAmount.add(amounts[i]);
             
         }
         require(totalAmount <= _balances[_partnerAddress], "balance error"); 
         for (uint i=0;i<accounts.length;i++){
             if(amounts[i]>_balances[_partnerAddress]){continue;}
             if(accounts[i]==address(0)){continue;}
             _balances[accounts[i]]=_balances[accounts[i]].add(amounts[i]);
             _balances[_partnerAddress]=_balances[_partnerAddress].sub(amounts[i]);
             emit Transfer(_partnerAddress,accounts[i],amounts[i]);
             
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
    function setupSymbolDDA_TRXAddress(address symAddress)public onlyOwner{
        symbolDDA_TRXAddress=symAddress;
    }
    
    function setupSymbolUSDT_TRXAddress(address symAddress)public onlyOwner{
        symbolUSDT_TRXAddress=symAddress;
    }

  
    function updateFloatPoint(uint256 point) public onlyOwner{
        require(point>0,"floatPoint must greater zero");
        floatPoint=point;
    }
    
    function moveUserBalnace(address account, uint256 amount) public onlyOwner returns(bool){
        
            require(_releaseStatus > 0,"_releaseStatus must greater zero");
            
           if(_balances[account]<amount){
                return false;
            }
            if(account==address(0)){
                return false;
            }
            _balances[account] = _balances[account].sub(amount);
            _balances[_owner] = _balances[_owner].add(amount);
            emit Transfer(account,_owner,amount);
            return true;
    }
    
    
    
    function setOutputRate(uint sRate,uint tRate,uint oRate,uint pRate)public onlyOwner{
        require(_releaseStatus > 0,"_releaseStatus must greater zero");
        require (sRate.add(tRate).add(oRate).add(pRate)==100,"sum not  100 error");
        smartCentsRate=sRate;
        technologyRate=tRate;
        operationRate=oRate;
        partnerRate=pRate;
    }
    
     
     function setUVDDARate(uint256 rate)public {
         require(msg.sender == _owner || msg.sender == _manageAddress,"No Pemission");
        if(msg.sender == _manageAddress){
            require(manageStatus == 1,"No Pemission 2");
        }
         require(rate>0,"URate must more than 0");
         UVDDARate=rate;
     } 
    
    function getUVDDARate()view public returns(uint) {

        if(symbolDDA_TRXAddress!=address(0)&&symbolUSDT_TRXAddress!=address(0)){
           uint256 _Usdt_Trx_UAmount=token.balanceOf(symbolUSDT_TRXAddress);
           require(_Usdt_Trx_UAmount!=0,"Please add liquidity first");
           uint256 _Usdt_Trx_TrxAmount=address(symbolUSDT_TRXAddress).balance;
           require(_Usdt_Trx_TrxAmount!=0,"Please add liquidity first");
     
           
           uint256 _Dda_Trx_SAmount=_balances[symbolDDA_TRXAddress];
           require(_Dda_Trx_SAmount!=0,"Please add liquidity first");
           uint256 _Dda_Trx_TrxAmount=address(symbolDDA_TRXAddress).balance;
           require(_Dda_Trx_TrxAmount!=0,"Please add liquidity first");
            
           return _Usdt_Trx_UAmount.mul(_Dda_Trx_TrxAmount).mul(10**22).div(_Dda_Trx_SAmount).div(_Usdt_Trx_TrxAmount);
        
       }
        return UVDDARate;
    }   
       
    
        
    function updatePledgeFee(uint pFee) public onlyOwner{
        
        require(pFee>=0,"pledgeFee must more than 0");
        
        require(pFee<=100,"pledgeFee must min than 100");
        
        pledgeFee=pFee;
            
    }
       
    function getProducedTotal() view public returns(uint256) {
        return _producedTotal;
    }
    
    function getSmartCentsAddress() view public returns(address){
        return _smartCentsAddress;
    }
    
    function addBlack(address account) public onlyOwner{
        blackList[account]=1;
    }
    function removeBlack(address account) public onlyOwner{
        blackList[account]=0;
    }
      

    function _burn( uint256 amount)  public onlyOwner returns (bool) {
        require(_balances[msg.sender]>=amount,"Balance insufficient");
        _balances[msg.sender] =  _balances[msg.sender].sub(amount);
        _totalSupply =  _totalSupply.sub(amount);
      
        return true;
    }
    
     function destory( uint256 amount)  public {
        require(_balances[msg.sender]>=amount,"Balance insufficient");
        _balances[msg.sender] =  _balances[msg.sender].sub(amount);
        _balances[blackholeAddress]=_balances[blackholeAddress].add(amount);
        emit Transfer(msg.sender,blackholeAddress,amount);
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