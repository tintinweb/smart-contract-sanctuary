/**
 *Submitted for verification at Etherscan.io on 2021-07-16
*/

pragma solidity ^0.8.0;




interface IERC20 {
    
    
   
    /**
     * @dev Returns the amount of tokens in existence.
     */
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
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
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
     *
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
     *
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

}
contract NewTokenTest is IERC20,SafeMath{
   
    //发行总量 
    uint256 _totalSupply;
    //现有总量
    uint256 _nowTotalSupply;
    //余额 
    mapping(address => uint256) _balances;
    
    mapping(address => mapping(address => uint256)) private _allowance;
    
    string _name;
    
    string _symbol;
    
    uint8 _decimals = 18;
    
    address _owner;
    
    //用来实现持币地址数列表
    address[] holdingAddress;
     //最大转账比例  
    uint256 maxProportion = 1;
    uint256 maxProportionBranch = 100;
    //分红数量
    uint256 dividendRatio = 2;
    //销毁数量
    uint256 destructionRatio = 20;
   /**
     * 上次解锁时间（创世区块为锁仓时间 ） 
     */
    uint256 lastUnLockTimestamp;
    //单月相差时间戳 
    uint256 monthTimestamp = 2592000000;
    /**
     * 已解锁数量 
     */
    uint256 unlockedQuantity;
    
    /**
     * 锁仓数量 
     */
    uint256 lockedQuantity;
    //锁仓比例
    uint256 lockedPositionRatio = 20;
    
    //团队地址
    address teamAddress;
    //解锁比例
    uint256 unlockRatio = 1;
    
    
    // 事件，用来通知客户端交易发生 ERC20标准
    event Transfer(address indexed from, address indexed to, uint256 value);

    // 事件，用来通知客户端代币被消费 ERC20标准
    event Burn(address indexed from, uint256 value);
    
    constructor (string memory tokenName,string memory tokenSymbol,address _teamAddress){
        _name = tokenName;
        _symbol = tokenSymbol;
        _totalSupply = 1000000000 *10 ** _decimals;
       
        _nowTotalSupply = _totalSupply;
        _initDestroy(_totalSupply);
        _owner = getSenter();
        holdingAddress.push(_owner);
        teamAddress = _teamAddress;
       uint256 _lock = _initLockUp();
        _balances[_owner] = SafeMath.sub(_nowTotalSupply,_lock);
       
    }
    
    
    function getSenter() public returns(address){
        return msg.sender;
    }
    
    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual  returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual  returns (string memory) {
        return _symbol;
    }
    
    
    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual  returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
    
     function nowTotalSupply() public view virtual  returns (uint256) {
        return _nowTotalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    
    /**
     *  代币交易转移
     *  从自己（创建交易者）账号发送`_value`个代币到 `_to`账号
     * ERC20标准
     * @param _to 接收者地址
     * @param _value 转移数额
     */
    function transfer(address _to, uint256 _value) public override returns(bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }
    
    // function tested(uint256 _value,uint256 blance) public view returns(uint256){
       
      
    //     return SafeMath.div(SafeMath.mul(_value,blance), 1000000000 *10 ** _decimals);
        
    // }
    
    
    function getDividends(uint256 value) public view returns (uint256) {
        return SafeMath.div(SafeMath.mul(value,dividendRatio),maxProportionBranch);
    }
   
    
    
    function _transfer(address _from ,address _to , uint256 _value) internal{
        require(_balances[_from] >= _value);
        // 确保转移为正数个
        require(_balances[_to] + _value > _balances[_to]);
        //如果转账地址是团地地址增加判断转账数量是否超过已经解锁的数量
        if(_from == teamAddress){
            require(SafeMath.sub(_balances[_from],_value) >= lockedQuantity);
        }
        if(_owner != _from){
            //每次转账或交易不可超过发行量的1%(除owner地址)
            require(_value > SafeMath.mul(SafeMath.div(_totalSupply,maxProportionBranch),maxProportion));
        }
        // //分红数
        uint256 dividends = SafeMath.div(SafeMath.mul(_value,dividendRatio),maxProportionBranch);
        //转账前余额为0的话加入持币地址       
        if(_balances[_to] == 0){
            holdingAddress.push(_to);
        }
        
        _balances[_from] -= _value;
        // Add the same to the recipient
        if(dividends > 0){
             _value = SafeMath.sub(_value,dividends);
            _dividends(dividends,_from);
        }
        _balances[_to] += _value;
       emit Transfer(_from, _to, _value);
    }
    
    //分红
    function _dividends(uint256 value,address from) public{
    
        uint256 blanceAll;
        for (uint256 i = 0; i < holdingAddress.length; i++) {
            uint256 blance = _balances[holdingAddress[i]];
            if(blance > 0){
               blanceAll += blance;
            }
        }
        
        for (uint256 i = 0; i < holdingAddress.length; i++) {
            uint256 blance = _balances[holdingAddress[i]];
            if(blance > 0){
                // value*_decimals*blance/blanceAll;
                uint256 dividends = SafeMath.div(SafeMath.mul(value,blance),blanceAll);
            //   uint256 dividends =  SafeMath.mul(SafeMath.div( SafeMath.mul(blance,_decimals),blanceAll),value);
            //  uint256 dividends = SafeMath.mul(SafeMath.div(blance,blanceAll),value);
               _balances[holdingAddress[i]] += dividends;
               emit Transfer(from, holdingAddress[i], dividends);
            }
        }
        
        
    }
    
    //销毁  
    function _initDestroy(uint256 value) private {
        uint256 destroyValue = SafeMath.mul(SafeMath.div(value,maxProportionBranch),destructionRatio);
        _nowTotalSupply -= destroyValue;
        emit Burn(getSenter(),destroyValue);
    }
    
     /**
     * 设置某个地址（合约）可以创建交易者名义花费的代币数。
     *
     * 允许发送者`_spender` 花费不多于 `_value` 个代币
     * ERC20标准
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public override
    returns (bool success) {
        _allowance[msg.sender][_spender] = _value;
        return true;
    }
    
    /**
     * 账号之间代币交易转移
     * ERC20标准
     * @param _from 发送者地址
     * @param _to 接收者地址
     * @param _value 转移数额
     */
    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool success) {
        require(_value <= _allowance[_from][msg.sender]);     // Check allowance
        _allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    // //9.获取_spender可以从账户_owner中转出token的剩余数量
    // function allowance(address _owner, address _spender) public  override returns (uint256){
    //      return _balances[getSenter()];
    // }
    
     function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowance[owner][spender];
    }

    /**
     * 锁仓
     */
    function _initLockUp() internal returns(uint256){
        lastUnLockTimestamp = block.timestamp;
        unlockedQuantity = 0;
        lockedQuantity = SafeMath.div(SafeMath.mul(_totalSupply,lockedPositionRatio),maxProportionBranch);
        _balances[teamAddress] = lockedQuantity;
        holdingAddress.push(teamAddress);
        return lockedQuantity;
    }
    
    
    /**
     * 解锁  
     */
     function unLock() public returns(bool){
         require(_owner == getSenter());
         uint256 nowTimestamp = block.timestamp;
         require(SafeMath.sub(nowTimestamp,lastUnLockTimestamp) >= monthTimestamp);
         //本次解锁
         uint256 currentlyUnlocked = SafeMath.div(SafeMath.mul(lockedQuantity,unlockRatio),maxProportionBranch);
         unlockedQuantity += currentlyUnlocked;
         lockedQuantity -= currentlyUnlocked;
         lastUnLockTimestamp += monthTimestamp;
         return true;
     }



}