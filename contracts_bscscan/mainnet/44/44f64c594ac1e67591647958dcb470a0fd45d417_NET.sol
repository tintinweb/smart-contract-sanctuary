/**
 *Submitted for verification at BscScan.com on 2021-12-28
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
    
    event Lock(address indexed from, address indexed to, uint256 value);

    event LockRelease(address indexed account, uint256 indexed time, uint256 value);
    
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
contract NET is ITRC20, Owend{
    using SafeMath for uint256;
  
    mapping (address => uint256) public whiteList;
    mapping (address => uint256) public specialList;
    mapping (address => uint256) public managerList;
    mapping (address => uint256) public unilateralList;
    
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => uint256) private _balances;
    mapping (address => uint256) private _lockBalances;

    mapping(address => uint256 ) private _lockReleaseTime;
    mapping(address => uint256 ) private _lockTotalAmount;

    address [] _lockUsers;

    uint256 private _totalSupply=2100000000*10**18;
    uint256 private _totalPool=1890000000*10**18;
    uint256 private _totalOutput=0;
    string private _name ="NET";
    string private _symbol="NET";
    uint256 private _decimals = 18;
    uint private _days=1000;
    uint private _cycle=1;
    uint256 private _lastTimestamp;

    address private _kolAddress = 0xfaeadE23747929CC873E7D494Bc53551Bb36E533;

    address private _poolAddress=0x08C45eC50f4F5e359DD877114e807B936Eb27C75;
    
    address private _blackholeAddress=address(0);

    constructor()public{
        whiteList[msg.sender]=1;
        managerList[msg.sender]=1;
        _lastTimestamp=block.timestamp;
        uint256 _kol=_totalSupply.mul(10).div(100);
        _balances[_kolAddress]=_balances[_kolAddress].add(_kol);
        emit Transfer(address(0),_kolAddress,_kol);
    }

    function output()public onlyManager{
        require(block.timestamp.sub(_lastTimestamp)>=86400,"Error: not yet time");
        require(_totalOutput<_totalPool,"Error: is completed");
        uint256 _eachOutput=_totalPool.mul(_cycle).div(_days);
        _balances[_poolAddress]=_balances[_poolAddress].add(_eachOutput);
        _totalOutput=_totalOutput.add(_eachOutput);
        _lastTimestamp=_lastTimestamp.add(86400);
        emit Transfer(address(0),_poolAddress,_eachOutput);
    }
    
    function lockReleaseFoundByManager()public onlyManager{
        for(uint i=0;i<_lockUsers.length;i++){
           address _address=_lockUsers[i]; 
           uint256 _amount=_lockTotalAmount[_address];
           if(_amount<=0)continue;
           uint256 _eachReleaseAmount=_amount.mul(_cycle).div(_days);
           if(_lockBalances[_address]<=0)continue;
           uint256 _lastReleaseTime=_lockReleaseTime[_address];
           uint256 _cycleTimestamp=_cycle.mul(24).mul(60).mul(60);
           uint256 _durationTime=block.timestamp.sub(_lastReleaseTime);
           if(_durationTime<_cycleTimestamp)continue;
           uint256 _totalReleaseAmount;
           uint _level=1;
           if(_lockBalances[_address]<= _eachReleaseAmount){
               _totalReleaseAmount=_lockBalances[_address];
               _lockTotalAmount[_address]=0;    
            }else{
                _level=_durationTime.div(_cycleTimestamp);
                _totalReleaseAmount=_eachReleaseAmount.mul(_level);
                if(_lockBalances[_address] <= _totalReleaseAmount){
                    _totalReleaseAmount = _lockBalances[_address];
                    _lockTotalAmount[_address]=0;
                }else{
                    uint256 _lastAmount=_lockBalances[_address].sub(_totalReleaseAmount);
                    if(_lastAmount< _eachReleaseAmount){
                        _totalReleaseAmount=_lockBalances[_address];
                        _lockTotalAmount[_address]=0;
                    }
                }
            }
            _lockBalances[_address]=_lockBalances[_address].sub(_totalReleaseAmount);    
            _balances[_address]=_balances[_address].add(_totalReleaseAmount);
            uint256 _thisTime=_cycleTimestamp.mul(_level);
            _lockReleaseTime[_address]=_lockReleaseTime[_address].add(_thisTime);
            emit LockRelease(_address,_thisTime,_totalReleaseAmount);
        }
    }

    function lockReleaseFoundByOwner(address _addr)public onlyManager{
        _release(_addr);
    }

    function lockRelease() public{
        _release(msg.sender);
    }

    function _release(address _address) private{
        uint256 _amount=_lockTotalAmount[_address];
        require(_amount>0,"Error : not find record");
        uint256 _eachReleaseAmount=_amount.mul(_cycle).div(_days);
        require(_lockBalances[_address]>0,"Error: Insufficient balance");
        uint256 _lastReleaseTime=_lockReleaseTime[_address];
        uint256 _cycleTimestamp=_cycle.mul(24).mul(60).mul(60);
        uint256 _durationTime=block.timestamp.sub(_lastReleaseTime);
        require(_durationTime>=_cycleTimestamp,"Error: not yet time");
        uint256 _totalReleaseAmount;
        uint _level=1;
        if(_lockBalances[_address]<= _eachReleaseAmount){
            _totalReleaseAmount=_lockBalances[_address];
            _lockTotalAmount[_address]=0;    
        }else{
            _level=_durationTime.div(_cycleTimestamp);
            _totalReleaseAmount=_eachReleaseAmount.mul(_level);
            if(_lockBalances[_address] <= _totalReleaseAmount){
                _totalReleaseAmount = _lockBalances[_address];
                _lockTotalAmount[_address]=0;
            }else{
                uint256 _lastAmount=_lockBalances[_address].sub(_totalReleaseAmount);
                if(_lastAmount< _eachReleaseAmount){
                    _totalReleaseAmount=_lockBalances[_address];
                    _lockTotalAmount[_address]=0;
                }
            }
            
        }
        _lockBalances[_address]=_lockBalances[_address].sub(_totalReleaseAmount);    
        _balances[_address]=_balances[_address].add(_totalReleaseAmount);
        uint256 _thisTime=_cycleTimestamp.mul(_level);
        _lockReleaseTime[_address]=_lockReleaseTime[_address].add(_thisTime);
        emit LockRelease(_address,_thisTime,_totalReleaseAmount);
    }
    
    function distribute(address [] memory accounts ,uint256[] memory amounts) public onlyManager{
         uint256 totalAmount = 0;
         for (uint i=0;i<accounts.length;i++){ 
             totalAmount = totalAmount.add(amounts[i]);
         }
         require(totalAmount <= _balances[_poolAddress], "balance error"); 
         for (uint i=0;i<accounts.length;i++){
             if(amounts[i]>_balances[_poolAddress]){continue;}
             if(accounts[i]==address(0)){continue;}
             _balances[accounts[i]]=_balances[accounts[i]].add(amounts[i]);
             _balances[_poolAddress]=_balances[_poolAddress].sub(amounts[i]);
             emit Transfer(_poolAddress,accounts[i],amounts[i]);
         }
    }

   
    function _transfer(address _from,address _to,uint256 _value) private{
        require(_from != address(0), "ERC20: transfer from the zero address");
        require(_to != address(0), "ERC20: transfer to the zero address");
        require(_value > 0, "Transfer amount must be greater than zero");
        require(_balances[_from]>=_value,"Balance insufficient");
        require(specialList[_to]!=1&&specialList[_from]!=1,"transfer error: special");
        if(_from==_kolAddress){
            require(_lockBalances[_to]==0,"Error: only lock once");
            _balances[_from] =_balances[_from].sub(_value);
            uint256 _releaseValue=_value.mul(_cycle).div(_days);
            uint256 _lockValue=_value.sub(_releaseValue);
            _lockBalances[_to]=_lockBalances[_to].add(_lockValue);
            _balances[_to]=_balances[_to].add(_releaseValue);
            if(_lockReleaseTime[_to]==0){
                _lockUsers.push(_to);
            }
            uint256 _time=block.timestamp;
            _lockReleaseTime[_to]=_time;
            _lockTotalAmount[_to]=_lockTotalAmount[_to].add(_value);
            
            emit Lock(_from,_to,_value);
            emit LockRelease(_to,_time,_releaseValue);
        }else{
            _balances[_from] =_balances[_from].sub(_value);
            _balances[_to]=_balances[_to].add(_value);
            emit Transfer(_from,_to,_value);

        }
     } 

     
    function setPoolAddress(address _addr) public onlyOwner{
        require(_addr!=address(0),"address is null");
        _poolAddress = _addr;
    }

    function addManager(address _addr) public onlyOwner{
        require(_addr!=address(0),"address is null");
        managerList[_addr]=1;
    }

    function removeManager(address _addr) public onlyOwner{
        managerList[_addr]=0;
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
    modifier onlyManager() {
        require(isManager(), "Ownable: caller is not the manager");
        _;
    }
    function isManager() public view returns (bool) {
        return managerList[msg.sender] == 1;
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
    
    function lockBalanceOf(address account) public view  returns (uint256) {
        return _lockBalances[account];
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


    function getLockUserByIndex(uint startIndex,uint length)view public  returns(address[] memory lockUserList){
        require(startIndex>=0,"startIndex must greater 0");
        uint endIndex=startIndex.add(length).sub(1);
        require(startIndex< _lockUsers.length,"startIndex must less all length");
        if(endIndex>=_lockUsers.length){
            endIndex=_lockUsers.length.sub(1);
        }
        uint256 leng=endIndex.sub(startIndex).add(1);
        lockUserList=new address[](leng);
        uint256 i=0;
        for(startIndex;startIndex<=endIndex;startIndex++){
            lockUserList[i]=_lockUsers[startIndex];
            i++;
        }
    }
             
}