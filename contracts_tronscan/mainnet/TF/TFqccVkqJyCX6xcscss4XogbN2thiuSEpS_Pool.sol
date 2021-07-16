//SourceUnit: ERC20Detailed.sol

pragma solidity ^0.5.0;

import "./IERC20.sol";

/**
 * @title ERC20Detailed token
 * @dev The decimals are only for visualization purposes.
 * All the operations are done using the smallest and indivisible token unit,
 * just as on Ethereum all the operations are done in wei.
 */
contract ERC20Detailed is IERC20 {
  string private _name;
  string private _symbol;
  uint8 private _decimals;

  constructor(string memory name, string memory symbol, uint8 decimals) public {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
  }

  /**
   * @return the name of the token.
   */
  function name() public view returns(string memory) {
    return _name;
  }

  /**
   * @return the symbol of the token.
   */
  function symbol() public view returns(string memory) {
    return _symbol;
  }

  /**
   * @return the number of decimals of the token.
   */
  function decimals() public view returns(uint8) {
    return _decimals;
  }
}

//SourceUnit: IERC20.sol

pragma solidity ^0.5.0;

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}


//SourceUnit: Initializable.sol

pragma solidity ^0.5.0;

/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool wasInitializing = initializing;
    initializing = true;
    initialized = true;

    _;

    initializing = wasInitializing;
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    uint256 cs;
    assembly { cs := extcodesize(address) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}


//SourceUnit: Pool.sol

pragma solidity ^0.5.0;
import "./SafeMath.sol";
import "./PoolWrapper.sol";

contract Pool is PoolWrapper {
    using SafeERC20 for IERC20;
    IERC20 private yfi;

    uint256 private outputDay;
    uint256 private outputWeek;
    uint256 private outputMon;

    uint private second = 24 *3600;

    uint256 private precision = 1e18;
    address private deployer;

    address private controlPoolAddress;
    uint8 private flag;

    uint256 public totalSupply ;
    uint256 public useTotal = 0;

    struct userInfo  {
        uint256 LockDeadline;
        uint256 LockAmount;
        uint256 startTime;
        uint256 endTime;
        uint256 getInterestTime;
        uint256 unLockFlag;
    }

    mapping (address => mapping(uint256 => userInfo)) private user;

    mapping (address => uint256) private keys;

    event  Lock(address indexed user, uint256 amount,uint256 day);
    event  UnLock(address indexed user, uint256 f, uint256 uid);
    event  Interest(address indexed user, uint256 uid,uint256  interest);

    uint private unlocked = 1;
    modifier checkLock() {
        require(unlocked == 1, "LOCKED");
        if(totalSupply.sub(useTotal) <= outputMon.mul(30)){
          unlocked = 0;
        }
        _;
        unlocked = 1;
    }


    modifier checkFlag() {
        require(flag == 1,"1111");
        _;
    }

    constructor(
        address _y,
        address _yfi,
        uint256 _outputDay,
        uint256 _outputWeek,
        uint256 _outputMon,
        address _ControlPoolAddress,
        uint256 _totalSupply,
        uint8 _flag)
    public {
        super.initialize(_y);
        yfi = IERC20(_yfi);
        deployer = msg.sender;
        outputDay = _outputDay;
        outputWeek = _outputWeek;
        outputMon = _outputMon;
        totalSupply = _totalSupply.mul(precision);
        controlPoolAddress = _ControlPoolAddress;
        flag = _flag;
    }


    function setFlag(uint8 _flag) public {
        require(msg.sender == controlPoolAddress,"1112" );
        flag = _flag;
    }

    function getFlag() public view returns(uint8) {
        uint8 flagA;
        if(totalSupply.sub(useTotal) == 0){
            flagA = 2;
        }else{
            flagA = flag;
        }
        return flagA;
    }

    function getInterestBalance()public view returns(uint256) {
        return totalSupply.sub(useTotal);
    }

    function lock(uint256 amount,uint256 day) public checkFlag checkLock {
      require(day == 7 || day == 1 || day ==30,"1113");
      require(amount > 0,"1114");
      require(useTotal < totalSupply,"1115");
      uint256 tokenInterest = interest(amount, day);

      require(totalSupply.sub(useTotal) >= tokenInterest,"1116");

      uint256 sTime  = block.timestamp;
      uint256 eTime = sTime + (day * second);

      super.stake(amount);
      uint256 _uid = keys[msg.sender] + 1;
      keys[msg.sender] = _uid;


      useTotal = useTotal + tokenInterest;

      userInfo storage uf = user[msg.sender][_uid];
      uf.LockDeadline = day;
      uf.LockAmount = amount;
      uf.startTime = sTime;
      uf.endTime = eTime;
      uf.getInterestTime = sTime;
      uf.unLockFlag = 0;

      emit Lock(msg.sender,amount,day);
    }

    function interest(uint256 amount,uint256 day) private view returns(uint256) {
        return getOutput(day).mul(amount).mul(day).div(precision);
    }

    function unLock(uint256 uid) public {

        userInfo storage uf = user[msg.sender][uid];
        require(block.timestamp > uf.endTime ,"1117");
        uint256 _amount = uf.LockAmount;
        require(_amount > 0,"1118");
        if (uf.unLockFlag == 0){
            super.withdraw(_amount);
            uf.unLockFlag = 1;
        }

        if(uf.getInterestTime < uf.endTime){
            getInterest(uid);
        }
        emit UnLock(msg.sender,uf.unLockFlag,uid);
    }

    function getInterest(uint256 uid) public {
        uint256 reward = earned(uid);
        if (reward > 0) {
            yfi.safeTransfer(msg.sender, reward);
        }

    }


    function earned( uint256 uid) private returns (uint256) {

        userInfo storage uf = user[msg.sender][uid];
        uint256 day = uf.LockDeadline;
        uint256 output = getOutput(day);

        if(uf.getInterestTime > uf.endTime){
            return 0;
        }

        uint256 time = block.timestamp;

        uint256 timed = (SafeMath.min(time, uf.endTime).sub(SafeMath.max(uf.startTime, uf.getInterestTime)));

        uint256 date = timed.sub(timed % (second)).div(second) ;

        uf.getInterestTime = uf.getInterestTime + date.mul(second);
        uint256 interestAmount  = uf.LockAmount.mul(date).mul(output).div(precision);
        emit Interest(msg.sender,uid,interestAmount);
        return interestAmount;
    }

    function getOutput(uint256 day) private view returns(uint256){
        uint256 output;
        if (day == 1) {
            output = outputDay;
        } else if (day == 7) {
            output = outputWeek;
        } else if (day == 30) {
            output = outputMon;
        }
        return output;
    }

    function getLockInfo(uint _type) public view returns(uint[] memory,uint[] memory, uint[] memory,uint[] memory,uint[] memory){
        uint[] memory keyArr = new uint[](keys[msg.sender]);
        uint[] memory   amountArr = new uint[](keys[msg.sender]);
        uint[] memory  dayArr = new uint[](keys[msg.sender]);
        uint[] memory   timeArr = new uint[](keys[msg.sender]);
        uint[] memory   flagArr = new uint[](keys[msg.sender]);
        uint256 time = block.timestamp;
        for(uint i=0; i < keys[msg.sender];i++){
            userInfo storage uf = user[msg.sender][i+1];
            if (_type == 0 || (_type == 1 && time< uf.endTime) || (_type == 2 && time >  uf.endTime)) {
                keyArr[i] = i+1;
                amountArr[i] = uf.LockAmount;
                dayArr[i] = uf.LockDeadline;
                timeArr[i] = uf.endTime;
                flagArr[i] = uf.unLockFlag;
            }
        }
        return (keyArr, amountArr,dayArr,timeArr,flagArr);
    }

    function clearPot() public {
        if(msg.sender == deployer){
            yfi.safeTransfer(msg.sender, yfi.balanceOf(address(this)));
        }
    }
}


//SourceUnit: PoolWrapper.sol

pragma solidity ^0.5.0;

import "./SafeMath.sol";
import "./ERC20Detailed.sol";
import "./SafeERC20.sol";

import "./Initializable.sol";

contract PoolWrapper is Initializable {

    using SafeMath for uint256;
    using SafeERC20 for ERC20Detailed;

    ERC20Detailed internal  y;

    function initialize(address _y) internal  initializer {
        y = ERC20Detailed(_y);
    }

    function stake(uint256 amount) internal  {
        y.safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount) internal {
        y.transfer(msg.sender, amount);
    }
}


//SourceUnit: SafeERC20.sol

pragma solidity ^0.5.0;

import "./IERC20.sol";
import "./SafeMath.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {

  using SafeMath for uint256;

  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(
    IERC20 token,
    address spender,
    uint256 value
  )
    internal
  {
    // safeApprove should only be called when setting an initial allowance, 
    // or when resetting it to zero. To increase and decrease it, use
    // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
    require((value == 0) || (token.allowance(msg.sender, spender) == 0));
    require(token.approve(spender, value));
  }

  function safeIncreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  )
    internal
  {
    uint256 newAllowance = token.allowance(address(this), spender).add(value);
    require(token.approve(spender, newAllowance));
  }

  function safeDecreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  )
    internal
  {
    uint256 newAllowance = token.allowance(address(this), spender).sub(value);
    require(token.approve(spender, newAllowance));
  }
}


//SourceUnit: SafeMath.sol

pragma solidity ^0.5.0;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {
  /**
  * @dev Returns the largest of two numbers.
  */
  function max(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  /**
  * @dev Returns the smallest of two numbers.
  */
  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

  /**
  * @dev Calculates the average of two numbers. Since these are integers,
  * averages of an even and odd number cannot be represented, and will be
  * rounded down.
  */
  function average(uint256 a, uint256 b) internal pure returns (uint256) {
    // (a + b) / 2 can overflow, so we distribute
    return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
  }
  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}