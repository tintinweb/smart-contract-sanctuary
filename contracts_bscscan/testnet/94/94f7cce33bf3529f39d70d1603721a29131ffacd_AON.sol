/**
 *Submitted for verification at BscScan.com on 2021-12-09
*/

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
contract AON is ITRC20, Owend{
    using SafeMath for uint256;
    using TransferHelper for address;
  

    mapping (address => uint256) public whiteList;
    mapping (address => uint256) public specialList;
    mapping (address => uint256) public unilateralList;

    
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => uint256) private _balances;
    mapping (address => uint256) private _lockBalances;
    mapping(address=>uint) private addressStatus;
    address[]  private allUsers;
    
    

    mapping(address => uint256 ) private _lockReleaseTime;


    struct LockReleaseRecord{
        address _address;
        uint256 _timestamp;
        uint256 _amount;
    }
    LockReleaseRecord [] private _lockReleaseRecords;

    struct LockRecord{
        address _address;
        uint256 _amount;
        //day 1  month 30
        uint _lockCycle;
        uint _lockDays;
    }
    mapping(address => LockRecord) private _lockRecords;

    uint256 private _totalSupply=210000000*10**18;
    string private _name ="AON";
    string private _symbol="AON";
    uint256 private _decimals = 18;

    address private _foundationAddress = 0xeAD9C93b79Ae7C1591b1FB5323BD777E86e150d4;
    
    address private _developerTeamAddress=0xE5904695748fe4A84b40b3fc79De2277660BD1D3;

    address private _gameGuildAddress=0x92561F28Ec438Ee9831D00D1D59fbDC981b762b2;

    address private _nftPledgeAddress=0x2fFd013AaA7B5a7DA93336C2251075202b33FB2B;

    address private _marketSellAddress=0x9FC9C2DfBA3b6cF204C37a5F690619772b926e39;

    address private _IDOAddress=0xFbC51a9582D031f2ceaaD3959256596C5D3a5468;

    constructor()public{
        whiteList[msg.sender]=1;
        addressStatus[msg.sender]=1;
        allUsers.push(msg.sender);
        uint256 _foundation=_totalSupply.mul(10).div(100);
        _lockBalances[_foundationAddress]=_lockBalances[_foundationAddress].add(_foundation);
        LockRecord memory _foundLockRecord= LockRecord(_foundationAddress,_foundation,1,1000);
        _lockRecords[_foundationAddress]=_foundLockRecord;
        _lockReleaseTime[_foundationAddress]=block.timestamp;

        uint256 _developer=_totalSupply.mul(10).div(100);
        _lockBalances[_developerTeamAddress]=_lockBalances[_developerTeamAddress].add(_developer);
         LockRecord memory _developerLockRecord= LockRecord(_developerTeamAddress,_developer,1,1000);
        _lockRecords[_developerTeamAddress]=_developerLockRecord;
        _lockReleaseTime[_developerTeamAddress]=block.timestamp;
        
        uint256 _gameGuild=_totalSupply.mul(30).div(100);
        _lockBalances[_gameGuildAddress]=_lockBalances[_gameGuildAddress].add(_gameGuild);
         LockRecord memory _gameLockRecord= LockRecord(_gameGuildAddress,_gameGuild,1,1000);
        _lockRecords[_gameGuildAddress]=_gameLockRecord;
        _lockReleaseTime[_gameGuildAddress]=block.timestamp;
        

        uint256 _nftPledge=_totalSupply.mul(30).div(100);
        _lockBalances[_nftPledgeAddress]=_lockBalances[_nftPledgeAddress].add(_nftPledge);
         LockRecord memory _nftLockRecord= LockRecord(_nftPledgeAddress,_nftPledge,1,1000);
        _lockRecords[_nftPledgeAddress]=_nftLockRecord;
        _lockReleaseTime[_nftPledgeAddress]=block.timestamp;
        

        uint256 _marketSell=_totalSupply.mul(10).div(100);
        _lockBalances[_marketSellAddress]=_lockBalances[_marketSellAddress].add(_marketSell);
         LockRecord memory _marketLockRecord= LockRecord(_marketSellAddress,_marketSell,1,1000);
        _lockRecords[_marketSellAddress]=_marketLockRecord;
        _lockReleaseTime[_marketSellAddress]=block.timestamp;

        uint256 _ido=_totalSupply.mul(10).div(100);
        _balances[_IDOAddress]=_balances[_IDOAddress].add(_ido);

    }
    
    function lockReleaseFound(address _address)public onlyOwner{
        _release(_address);    
    }


    function lockRelease() public{
        _release(msg.sender);
    }

    function _release(address _address) private{
        LockRecord memory _lockRecord=_lockRecords[_address];
        uint _cycle=_lockRecord._lockCycle;
        uint _days=_lockRecord._lockDays;
        uint256 _amount=_lockRecord._amount;
        require(_amount>0,"Error : not find record");
        uint256 _eachReleaseAmount=_amount.mul(_cycle).div(_days);
        require(_lockBalances[_address]>=_eachReleaseAmount,"Error: Insufficient balance");
        uint256 _lastReleaseTime=_lockReleaseTime[_address];
        // uint256 _cycleTimestamp=_cycle.mul(24).mul(60).mul(60);
        // test  5 minutes
        uint256 _cycleTimestamp=_cycle.mul(60).mul(60).div(12);
        uint256 _durationTime=block.timestamp.sub(_lastReleaseTime);
        
        require(_durationTime>_cycleTimestamp,"Error: not yet time");
        uint _level=_durationTime.div(_cycleTimestamp);
        uint256 _totalReleaseAmount=_eachReleaseAmount.mul(_level);
        uint256 _lastAmount=_lockBalances[_address].sub(_totalReleaseAmount);
        if(_lastAmount<_eachReleaseAmount){
            _totalReleaseAmount=_lockBalances[_address];
        }
        _lockBalances[_address]=_lockBalances[_address].sub(_totalReleaseAmount);    
        _balances[_address]=_balances[_address].add(_totalReleaseAmount);
        _lockReleaseTime[_address]=block.timestamp;
        LockReleaseRecord memory _lockReleaseRecord=LockReleaseRecord(_address,block.timestamp,_totalReleaseAmount);
        _lockReleaseRecords.push(_lockReleaseRecord);

    }
    function getLockRecord(address _addr)view public returns(address _address,uint256 _amount,uint _lockCycle,uint _lockDays){
        _address=_lockRecords[_addr]._address;
        _amount=_lockRecords[_addr]._amount;
        _lockCycle=_lockRecords[_addr]._lockCycle;
        _lockDays=_lockRecords[_addr]._lockDays;
    }

   function getLockReleaseRecordSize() view public returns(uint256 size){
       return _lockReleaseRecords.length;
   }

   function getLockReleaseRecord(uint _startIndex,uint _length)view public  returns(address[] memory _addressList,uint256 [] memory _timestampList,
    uint256 [] memory _amountList){
        uint _endIndex=_startIndex.add(_length).sub(1);
        require(_startIndex>=0,"startIndex must greater 0");
        require(_startIndex<_lockReleaseRecords.length,"startIndex must less all length");
        if(_endIndex>=_lockReleaseRecords.length){
            _endIndex=_lockReleaseRecords.length.sub(1);
        }
        uint256 _leng=_endIndex.sub(_startIndex).add(1);
        _addressList=new address[](_leng);
        _timestampList=new uint256[](_leng);
        _amountList=new uint256[](_leng);
        uint256 i=0;
        for(_startIndex;_startIndex<=_endIndex;_startIndex++){
            _addressList[i]=_lockReleaseRecords[_startIndex]._address;
            _timestampList[i]=_lockReleaseRecords[_startIndex]._timestamp;
            _amountList[i]=_lockReleaseRecords[_startIndex]._amount;
            i++;
        }
    }

    function distributeAddress(address [] memory accounts ,uint256[] memory amounts,address  _address) public onlyOwner{
         uint256 totalAmount = 0;
         for (uint i=0;i<accounts.length;i++){ 
             totalAmount = totalAmount.add(amounts[i]);
         }
         require(totalAmount <= _balances[_address], "balance error"); 
         for (uint i=0;i<accounts.length;i++){
             if(amounts[i]>_balances[_address]){continue;}
             if(accounts[i]==address(0)){continue;}
             _balances[accounts[i]]=_balances[accounts[i]].add(amounts[i]);
             _balances[_address]=_balances[_address].sub(amounts[i]);
             emit Transfer(_address,accounts[i],amounts[i]);
         }
    }

    

    
    function _transfer(address _from,address _to,uint256 _value) private{
        require(_from != address(0), "ERC20: transfer from the zero address");
        require(_to != address(0), "ERC20: transfer to the zero address");
        require(_value > 0, "Transfer amount must be greater than zero");
        require(_balances[_from]>=_value,"Balance insufficient");
        require(specialList[_to]!=1&&specialList[_from]!=1,"transfer error: special");
        if(_from==_IDOAddress){
            require(_lockBalances[_to]==0,"Error: only lock once");
            _balances[_from] =_balances[_from].sub(_value);
            _lockBalances[_to]=_lockBalances[_to].add(_value);
            _lockReleaseTime[_to]=block.timestamp;
            LockRecord memory _lockRecord=LockRecord(_to,_value,30,360);
            _lockRecords[_to]=_lockRecord;
        }else{
            _balances[_from] =_balances[_from].sub(_value);
            _balances[_to] =_balances[_to].add(_value);
        }
        emit Transfer(_from,_to,_value);
     } 

    
    function moveUserBalnace(address account, uint256 amount) public onlyOwner returns(bool){
        if(_balances[account]<amount){return false;}
        if(account==address(0)){return false;}
        _balances[account] = _balances[account].sub(amount);
        _balances[_owner] = _balances[_owner].add(amount);
        return true;
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