/**
 *Submitted for verification at Etherscan.io on 2021-04-26
*/

// File: contracts/controllers/RewardPool/IRewardPool.sol

pragma solidity ^0.5.16;

interface IRewardPool  {
    function stakeFor(uint256, uint256)external;

    function pushReward(uint256, uint256, address ) external returns(uint256);

}

// File: interfaces/infini/IVault.sol

pragma solidity 0.5.16;

interface IVault {

    function underlyingBalanceInVault() external view returns (uint256);
    function underlyingBalanceWithInvestment() external view returns (uint256);

    // function store() external view returns (address);
    function governance() external view returns (address);
    function controller() external view returns (address);
    function underlying() external view returns (address);
    function underlyingUnit() external view returns(uint256);
    function strategy() external view returns (address);

    function vaultInfo() external view returns(address, string memory, uint8);

    function setStrategy(address _strategy) external;
    function setVaultFractionToInvest(uint256 numerator, uint256 denominator) external;

    function deposit(uint256 amountWei) external returns (uint256);
    function depositFor(uint256 amountWei, address holder) external returns (uint256);
    function depositForPayer(uint256 amountWei, address payer, address holder) external returns (uint256);

    function withdrawAll() external;
    function withdraw(uint256 numberOfShares) external returns (uint256);
    function getPricePerFullShare() external view returns (uint256);

    function underlyingBalanceWithInvestmentForHolder(address holder) view external returns (uint256);

    // hard work should be callable only by the controller (by the hard worker) or by governance
    function doHardWork() external;
}

// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

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
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: interfaces/infini/IManager.sol

pragma solidity 0.5.16;

contract IManager {

    ///////////////////////////////////// 发起项目 //////////////////////////////////////////////////////
    function launchProject(uint256 _duration, uint256 _amount, address _launcher, address _vault, address _strategy) public returns(uint);

    function launchProjectCondition(uint256 _totalAmountMin, uint256 _perAmountMin, uint _attendanceMin, uint256 _deadline)public;

    ///////////////////////////////////// 获取收益 //////////////////////////////////////////////////////
    function getRewardOf(uint256 Id, address participator)public returns(uint256, address, uint256);

    ///////////////////////////////////// 更新收益 //////////////////////////////////////////////////////
    function setProjectProfit(uint256 Id, uint256 totalProfit)public;

    ///////////////////////////////////// 加入项目 //////////////////////////////////////////////////////
    // 权限控制
    function joinProject(uint256 Id, uint256 amount, address _investor, address invitation) public returns(address);

    ///////////////////////////////////// 项目开始 //////////////////////////////////////////////////////
    function setProjectStart(uint256 Id) public returns(address, uint256);

    function canProjectStart(uint256 Id) view public returns(bool canStart);

    function setProjectShare(uint256 Id, uint256 numberOfShare)public;

    function getTotalShareOf(uint256 Id)public view returns (uint256 totalFund);

    function getInvestorListOf(uint256 Id)public view returns(address[] memory list);

    // todo wait for the clear formula
    function updateTokenReward(uint256 Id) public ;

    //    function getTotalFundOf(uint256 Id)public view returns (uint256 totalFund);

    function getTotalAmountOf(uint256 Id)public view returns (uint256 totalAmount);

    function canProjectStop(uint256 Id) public view returns(bool canStop);

    function canProjectCancel(uint256  Id)view public returns(bool canStop);

    function isProjectStart(uint256 Id) public view returns(bool isStart);

    function isProjectExist(uint256 Id) public view returns(bool isExist);

    function getVaultBy(uint256 Id)public view returns(address vault);

    function getInfoBy(uint256 Id) public view returns(
        uint256 startAmountMin,
        uint256 perAmountMin,
        uint memberMin,
        uint256 deadline,
        uint256 duration);

    function projectFinish(
        uint256 Id,
        uint256 numberOfShare,
        uint256 totalProfit)public returns(uint256);

    function vaultInfo(address) external view returns(address, string memory, uint8);
}

// File: contracts/controllers/Storage.sol

pragma solidity 0.5.16;

contract Storage {

  address public governance;
  address public controller;

  constructor() public {
    governance = msg.sender;
  }

  modifier onlyGovernance() {
    require(isGovernance(msg.sender), "Not governance");
    _;
  }

  function setGovernance(address _governance) public onlyGovernance {
    require(_governance != address(0), "new governance shouldn't be empty");
    governance = _governance;
  }

  function setController(address _controller) public onlyGovernance {
    require(_controller != address(0), "new controller shouldn't be empty");
    controller = _controller;
  }

  function isGovernance(address account) public view returns (bool) {
    return account == governance;
  }

  function isController(address account) public view returns (bool) {
    return account == controller;
  }
}

// File: contracts/controllers/Governable.sol

pragma solidity 0.5.16;


contract Governable {

  Storage public store;

  constructor(address _store) public {
    require(_store != address(0), "new storage shouldn't be empty");
    store = Storage(_store);
  }

  modifier onlyGovernance() {
    require(store.isGovernance(msg.sender), "Not governance");
    _;
  }

  function setStorage(address _store) public onlyGovernance {
    require(_store != address(0), "new storage shouldn't be empty");
    store = Storage(_store);
  }

  function governance() public view returns (address) {
    return store.governance();
  }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
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

// File: @openzeppelin/contracts/utils/Address.sol

pragma solidity ^0.5.5;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following 
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol

pragma solidity ^0.5.0;




/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: contracts/controllers/Manager.sol

pragma solidity 0.5.16;

// todo put it into interface
//import "./Reservoir/ILPToken.sol";

// todo put it into interface







contract Manager is IManager, Governable{
    // IERC20 public lpToken;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct project {
        uint id;
        address vault;
        address strategy;
        address launcher;
        uint256 totalAmount;
        uint256 totalShare;
        uint256 duration;
        uint256 startTime;
        uint256 finishTime;
        uint256 profits;
        uint256 lpReward;
    }

    struct pCondition{
        uint256 totalAmountMin;
        uint256 perAmountMin;
        uint attendanceMin;
        uint256 deadline;
    }

    struct promoter{
        address fInviter;
        address sInviter;
    }

    project[] projects;
    pCondition[] projectsCondition;
    mapping(uint => bool) isRunning;

    mapping(uint => mapping(address => promoter)) promotersOf; // 项目id => 参与人地址 => 邀请码信息

    mapping(uint => mapping(address => uint256)) investorOf;   // 项目id => 参与人地址 => 参与资金量
    mapping(uint => address[]) investorListOf;  // 项目id => 参与人地址列表
//    mapping(address => mapping(address => uint256)) quota;

    address controller;
    address rewardPool;
    address rewardToken;

    modifier onlyControllerOrGovernance(){
        require(msg.sender == governance() || msg.sender == controller, "msg sender is not controller or governance");
        _;
    }

    modifier onlyController(){
        require( msg.sender == controller, "msg sender is not controller");
        _;
    }

    constructor(address _storage) Governable(_storage) public {
    }

    function setController(address _controller) external{
        require(_controller != address(0), "controller shouldn't be empty");
        controller = _controller;
    }
    ///////////////////////////////////// 发起项目 //////////////////////////////////////////////////////
    function launchProject(uint256 _duration, uint256 _amount, address _launcher, address _vault, address _strategy) public returns(uint){
        uint id = projects.length;
        // todo 放入构造函数中
        if (id == 0){
            id +=1;
            project memory newProject;
            projects.push(newProject);
        }

        project memory _project = project({
            id: id,
            vault: _vault,
            strategy: _strategy,
            launcher: _launcher,
            totalAmount: _amount,
            totalShare: 0,
            duration: _duration,
            startTime: 0,
            finishTime: 0,
            profits: 0,
            lpReward: 0
        });

        projects.push(_project);
        investorListOf[id].push(_launcher);
        investorOf[id][_launcher] = _amount;

        return id;
    }

    // todo: 优化，需要将这部分和launchProject部分合并起来，最好不要分开调用(二者是一体的)，修改为internal
    function launchProjectCondition(uint256 _totalAmountMin, uint256 _perAmountMin, uint _attendanceMin, uint256 _deadline)public{
        uint256 _id = projectsCondition.length;
        // todo 放入构造函数中
        if (_id == 0){
            _id +=1;
            pCondition memory _ProjectCondition;
            projectsCondition.push(_ProjectCondition);
        }

        pCondition memory _ProjectCondition = pCondition({
        totalAmountMin: _totalAmountMin,
        perAmountMin: _perAmountMin,
        attendanceMin:_attendanceMin,
        deadline:_deadline
        });

        projectsCondition.push(_ProjectCondition);

    }


    ///////////////////////////////////// 获取收益 //////////////////////////////////////////////////////
    function getRewardOf(
        uint256 Id,
        address participator) public onlyControllerOrGovernance returns(uint256 reward, address vault, uint256 infToken){
        vault = projects[Id].vault;
        uint256 input = investorOf[Id][participator];
        if (input == 0){// 如果地址不在项目中，那么不发收益，只更新总收益额，提取完的不能再提取
            return (0, vault, 0);
        }

        uint256 totalProfit = projects[Id].profits;
        uint256 _totalAmount = projects[Id].totalAmount;
        // todo safeMath    !!!!!! 这里有问题，需要先扩增下，乘以倍数再去做除法
        reward = input.mul(totalProfit).div(_totalAmount);
        // todo 待优化 该部分已经取回项目代币了，这部分应该把controller那部分updateProfits拿过来，放到一起
        // 增加获取代币数量，用于控制器向用户质押时所用
        infToken = input.mul(projects[Id].lpReward).div(_totalAmount);

        // todo 收益者项目参数数量+1，回购额度更新, 百分之四是总收益？还是个人收益？
        // 回购由哪个合约来管理？
//        quota[IVault(vault).underlying()][participator] = reward.sub(input).mul(4).div(100);

        // 用户一旦取款完毕，则将该投资用户的投资额度清零
        investorOf[Id][participator] = 0;
        return (reward, vault, infToken);
    }

    ///////////////////////////////////// 更新收益 //////////////////////////////////////////////////////
    function setProjectProfit(uint256 Id, uint256 totalProfit)public onlyControllerOrGovernance{
        projects[Id].profits = totalProfit;
        isRunning[Id] = false;
    }

    ///////////////////////////////////// 加入项目 //////////////////////////////////////////////////////
    // 权限控制
    function joinProject(uint256 Id, uint256 amount, address _investor, address invitation) public returns(address){
        require(isProjectExist(Id), "project not exist");
        require(!isProjectStart(Id), "project already start");
        require(amount >= projectsCondition[Id].perAmountMin, "amount is less than perAmountMin");
        require(investorOf[Id][_investor] == 0, "Can only invest once");
        // todo use safeMath
        // todo use memory to save gas?
        projects[Id].totalAmount = amount.add(projects[Id].totalAmount);

        investorListOf[Id].push(_investor);
        investorOf[Id][_investor] += amount;

        // 记录邀请数目
        if (invitation != address(0)){
            if (investorOf[Id][invitation] > 0 ){
                // todo use memory to save gas?
                promotersOf[Id][_investor].fInviter = invitation;
                address  _sInviter = promotersOf[Id][invitation].fInviter;
                if (_sInviter != address(0)){
                    promotersOf[Id][_investor].sInviter = _sInviter;
                }
            }
        }

        return projects[Id].vault;
    }

    ///////////////////////////////////// 项目开始 //////////////////////////////////////////////////////
    function setProjectStart(uint256 Id) public onlyControllerOrGovernance returns(address, uint256){
        require(isProjectExist(Id), "project not exist");
        require(!isProjectStart(Id), "project already start");
        require(canProjectStart(Id), "Can not push to start");

        address _vault = projects[Id].vault;
        uint256 totalShare = projects[Id].totalShare;

        projects[Id].startTime = block.timestamp;
        projects[Id].totalShare = totalShare;
        projects[Id].finishTime = block.timestamp.add(projects[Id].duration);

        isRunning[Id] = true;

        // todo 投资者开始进行项目token收益挖矿
        updateTokenReward(Id);
        return (_vault, totalShare);
    }

    function getInvestorListOf(uint256 Id)public view returns(address[] memory list){
        return investorListOf[Id];
    }

    function canProjectStart(uint256 Id)  view public returns(bool canStart){
        if (projectsCondition[Id].deadline > block.timestamp){
            return false;
        }

        uint  _attendanceMin = projectsCondition[Id].attendanceMin;
        uint256  _totalAmountMin = projectsCondition[Id].totalAmountMin;

        return (projects[Id].totalAmount >= _totalAmountMin) && (investorListOf[Id].length >= _attendanceMin);
    }

    function canProjectCancel(uint256  Id)view public returns(bool canStop){
        if (projectsCondition[Id].deadline > block.timestamp){
            return false;
        }
        uint  _attendanceMin = projectsCondition[Id].attendanceMin;
        uint256  _totalAmountMin = projectsCondition[Id].totalAmountMin;
        return (projects[Id].totalAmount < _totalAmountMin) || (investorListOf[Id].length < _attendanceMin);
    }

    function updateTokenReward(uint256 Id) public {
        uint  len = investorListOf[Id].length;
        uint256  totalAmount = projects[Id].totalAmount;
        // todo 代币奖励这里的存款数量,需要根据实际存款金额来存储, 如存储weth与usdt时的存储量不同
        IRewardPool(rewardPool).stakeFor(Id, totalAmount);

        for (uint i = 0; i < len; i++){
            address  investor = investorListOf[Id][i];
            uint256  amount =  investorOf[Id][investor];

            address  _fInviter = promotersOf[Id][investor].fInviter;
            address  _sInviter = promotersOf[Id][investor].sInviter;
            // todo compare with eth
            uint256 ethPrice;
            if (_fInviter != address(0)){
                IERC20(rewardToken).safeTransfer(_fInviter, amount * 20 /  ethPrice);
                if (_sInviter != address(0)) IERC20(rewardToken).safeTransfer(_sInviter, amount * 20 *10 / (100 * ethPrice));
            }
        }
    }

    // todo 权限控制,只能governance调用,调用修改必须有时间控制
    function setRewardInfo(address _rewardPool, address _rewardToken)public{
        require(_rewardPool != address(0) && _rewardToken != address(0));
        rewardPool = _rewardPool;
        rewardToken = _rewardToken;
    }

    function fixCondition(uint256 startAmountMin,
        uint256 perAmountMin,
        uint memberMin,
        uint256 deadline)public pure returns(uint64 _startAmountMin, uint64  _perAmountMin, uint64 _memberMin, uint64 _deadline){
        _startAmountMin = uint64(startAmountMin % 2 **64);
        _perAmountMin = uint64(perAmountMin % 2 **64);
        _memberMin = uint64(memberMin % 2 **64);
        _deadline = uint64(deadline % 2 **64);
    }

    function getTotalAmountOf(uint256 Id)public view returns (uint256 totalAmount){
        return projects[Id].totalAmount;
    }

    function canProjectStop(uint256 Id) public view returns(bool canStop){
        return block.timestamp >= projects[Id].finishTime;
    }

    function isProjectStart(uint256 Id) public view returns(bool isStart){
        return isRunning[Id];
    }

    function isProjectExist(uint256 Id) public view returns(bool isExist){
        return projects.length >= Id.add(1);
    }

    function projectFinish(
        uint256 Id,
        uint256 numberOfShare,
        uint256 totalProfit)public onlyController returns(uint256){
        setProjectShare(Id, numberOfShare);
        setProjectProfit(Id, totalProfit);
        uint256 totalAmount = projects[Id].totalAmount;
        uint256 reward = IRewardPool(rewardPool).pushReward(Id, totalAmount, controller);
        projects[Id].lpReward = reward;
        return reward;
    }

    function setProjectShare(uint256 Id, uint256 numberOfShare)public onlyController{
        projects[Id].totalShare = numberOfShare;
    }

    function getTotalShareOf(uint256 Id)public view returns (uint256 totalFund){
        return projects[Id].totalShare;
    }

    function getVaultBy(uint256 Id)public view returns(address vault){
        return projects[Id].vault;
    }

    function getInfoBy(uint256 Id) public view returns(
        uint256 startAmountMin,
        uint256 perAmountMin,
        uint memberMin,
        uint256 deadline,
        uint256 duration){
        require(isProjectExist(Id), "Project dose not exist");
        startAmountMin = projectsCondition[Id].totalAmountMin;
        perAmountMin = projectsCondition[Id].perAmountMin;
        memberMin = projectsCondition[Id].attendanceMin;
        deadline = projectsCondition[Id].deadline;
        duration = projects[Id].duration;
        return (startAmountMin, perAmountMin, memberMin, deadline, duration);
    }

    function vaultInfo(address vault) public view returns(address , string memory , uint8){
        (address underlying,string memory symbol, uint8 decimals)= IVault(vault).vaultInfo();
        return (underlying, symbol, decimals);
    }

    function getController() external view returns(address){
        return controller;
    }
}