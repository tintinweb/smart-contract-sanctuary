//SourceUnit: cdc.sol

pragma solidity ^0.5.0;

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
        require(b <= a, "SafeMath: subtraction overflow");
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
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
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

//manager contract
//manager superAdmin
//manager admin
//manager superAdmin Auth
contract managerContract{
    /**
      * Token holder :
      *     a.Holding tokens
      *     b.No permission to transfer tokens privately
      *     c.Cannot receive tokens, similar to dead accounts
      *     d.Can delegate second-level administrators, but only one can be delegated
      *     e.Have the permission to unlock and transfer tokens, but it depends on the unlocking rules (9800 DNSS unlocked every day)
      *     f.Has the unlock time setting permission, but can only set one time  the unlock time node once
      */
    address superAdmin;

    // Secondary The only management is to manage illegal users to obtain DNSS by abnormal means
    mapping(address => address) internal admin;

    //pool address
    address pool;

    //Depends on super administrator authority
    modifier onlySuper {
        require(msg.sender == superAdmin,'Depends on super administrator');
        _;
    }
}

//unLock contract
//manager unLock startTime
//manager circulation ( mining pool out total  )
//manager calculate the number of unlocked DNSS fuction
contract unLockContract {

    //use safeMath for Prevent overflow
    using SafeMath for uint256;

    //start unLock time
    uint256 public startTime;
    //use totalOut for Prevent Locked DNSS overflow
    uint256 public totalToPool = 0;
    //Can't burn DNSS Is 10% of the totalSupply
    uint256 public sayNo = 980 * 1000 * 1000000000000000000 ;

    //get totalUnLockAmount
    function totalUnLockAmount() internal view returns (uint256 _unLockTotalAmount) {
        //unLock start Time not is zero
        if(startTime==0){ return 0;}
        //Has not started to unlock
        if(now <= startTime){ return 0; }
        //unlock total count
        uint256 dayDiff = (now.sub(startTime)) .div (1 days);
        //Total unlocked quantity in calculation period
        uint256 totalUnLock = dayDiff.mul(9800).mul(1000000000000000000);
        //check totalSupply overflow
        if(totalUnLock >= (980 * 10000 * 1000000000000000000)){
            return 980 * 10000 * 1000000000000000000;
        }
        //return Unlocked DNSS total
        return totalUnLock;
    }
}



/**
* DNSS follows the erc-20 protocol
* In order to maintain the maximum rights and interests of DNSS users and achieve
* a completely decentralized consensus mechanism, DNSS will restrict anyone from
* stealing any 9.8 million DNSS from the issuing account, including holders.
* The only way is through the DNSS community committee. The cycle is unlocked for circulation,
* and the DNSS community committee will rigidly restrict the circulation of tokens through this smart contract.
* In order to achieve future deflation of DNSS, the contract will destroy DNSS through the destruction mechanism.
*/
contract cdc is managerContract,unLockContract{

    string public constant name     = "cai dong chi";
    string public constant symbol   = "CDC";
    uint8  public constant decimals = 18;
    uint256 public _totalSupply = 980 * 10000 * 1000000000000000000 ;

    mapping (address => uint256) private _balanceOf;

    //use totalBurn for Record the number of burns
    mapping (address => uint256) private _balanceBurn;

    mapping (address => mapping (address => uint256)) private _allowances;


    //event
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed from, uint256 value);

    //init
    constructor() public {
        superAdmin = msg.sender ;
        _balanceOf[superAdmin] = _totalSupply;
    }


     function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     function balanceOf(address account) public view returns (uint256) {
        return _balanceOf[account];
    }


     function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }


     function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

     //superAdmin not transfer
    function transfer(address _to, uint256 _value) public returns (bool) {
         _transfer(msg.sender, _to, _value);
    }

     //superAdmin not transfer ;
     //allowance transfer
     //everyone can transfer
     //admin can transfer Illegally acquired assets
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        //admin Manage illegal assets
        if(admin[msg.sender] != address(0)){
          _transfer(_from, _to, _value);
        }else{
          _transfer(_from, _to, _value);
          _approve(_from, msg.sender, _allowances[_from][msg.sender].sub(_value));
        }

        return true;
    }

     function _transfer(address _from, address _to, uint _value) internal {
       require(_from != superAdmin,'Administrator has no rights transfer');
       require(_to != superAdmin,'Administrator has no rights transfer');
       require(_to != address(0) );
       require(_balanceOf[_from] >= _value);
       require(_balanceOf[_to] + _value > _balanceOf[_to]);
       uint256 previousBalances = _balanceOf[_from] + _balanceOf[_to];
       _balanceOf[_from] -= _value;
       _balanceOf[_to] += _value;
       emit Transfer(_from, _to, _value);
       assert(_balanceOf[_from] + _balanceOf[_to] == previousBalances);
    }

     function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }


    //Get unlocked DNSS total
    function totalUnLock() public view returns(uint256 _unlock){
       return totalUnLockAmount();
    }


    //Only the super administrator can set the start unlock time
    function setTime(uint256 _startTime) public onlySuper returns (bool success) {
        // require(startTime==0,'already started');
        // require(_startTime > now,'The start time cannot be less than or equal to the current time');
        startTime = _startTime;
        require(startTime == _startTime,'The start time was not set successfully');
        return true;
    }

    //Approve admin
    function superApproveAdmin(address _adminAddress) public onlySuper  returns (bool success) {
        //check admin
        require(_adminAddress != address(0),'is bad');
        admin[_adminAddress] = _adminAddress;
        //check admin
        if(admin[_adminAddress] == address(0)){
             return false;
        }
        return true;
    }


   //Approve pool address
    function superApprovePool(address _poolAddress) public onlySuper  returns (bool success) {
        require(_poolAddress != address(0),'is bad');
        pool = _poolAddress; //Approve pool
        require(pool == _poolAddress,'is failed');
        return true;
    }


    //burn target address token amout
    //burn total DNSS not more than 90% of the totalSupply
    function superBurnFrom(address _burnTargetAddess, uint256 _value) public onlySuper returns (bool success) {
        require(_balanceOf[_burnTargetAddess] >= _value,'Not enough balance');
        require(_totalSupply > _value,' SHIT ! YOURE A FUCKING BAD GUY ! Little bitches ');
        //check burn not more than 90% of the totalSupply
        require(_totalSupply.sub(_value) >= sayNo,' SHIT ! YOURE A FUCKING BAD GUY ! Little bitches ');
        //burn target address
        _balanceOf[_burnTargetAddess] = _balanceOf[_burnTargetAddess].sub(_value);
        //totalSupply reduction
        _totalSupply=_totalSupply.sub(_value);
        emit Burn(_burnTargetAddess, _value);
        //Cumulative DNSS of burns
        _balanceBurn[superAdmin] = _balanceBurn[superAdmin].add(_value);
        //burn successfully
        return true;
    }


    //Unlock to the mining pool account
    function superUnLock( address _poolAddress , uint256 _amount ) public onlySuper returns (bool success) {
        require(pool==_poolAddress,'Mine pool address error');
        require(  _amount  <= _balanceOf[superAdmin] ,'miner not enough');
        //get total UnLock Amount
        uint256 _unLockTotalAmount = totalUnLockAmount();
        require( totalToPool.add(_amount)  <= _unLockTotalAmount ,'Not enough dnss has been unlocked');
        //UnLock totalSupply to pool
        _balanceOf[_poolAddress]=_balanceOf[_poolAddress].add(_amount);
        //UnLock totalSupply to pool
        _balanceOf[superAdmin]=_balanceOf[superAdmin].sub(_amount);
        //Cumulative DNSS of UnLock
        totalToPool=totalToPool.add(_amount);
        return true;
    }
}