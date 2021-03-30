/**
 *Submitted for verification at Etherscan.io on 2021-03-30
*/

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
    function getRewardOf(uint256 Id, address participator)public returns(uint256, address);

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
    function updateTokenReward(uint256 Id, uint256 totalFund) public ;

    //    function getTotalFundOf(uint256 Id)public view returns (uint256 totalFund);

    function getTotalAmountOf(uint256 Id)public view returns (uint256 totalAmount);

    function canProjectStop(uint256 Id) public view returns(bool canStop);

    function canProjectCancel(uint256  Id)view public returns(bool canStop);

    function isProjectStart(uint256 Id) public view returns(bool isStart);

    function isProjectExist(uint256 Id) public view returns(bool isExist);

    function getVaultBy(uint256 Id)public view returns(address vault);

    function getInfoBy(uint256 Id) public view returns(
        address underlying,
        uint256 decimals,
        uint256 startAmountMin,
        uint256 perAmountMin,
        uint memberMin,
        uint256 deadline,
        uint256 duration);
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

// File: contracts/controllers/Manager.sol

pragma solidity 0.5.16;

// todo put it into interface
//import "./Reservoir/ILPToken.sol";
//import "./RewardPool/IRewardPool.sol";
// todo put it into interface





contract Manager is IManager, Governable{
    // IERC20 public lpToken;
    using SafeMath for uint256;
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

    address public controller;

    modifier onlyControllerOrGovernance(){
        require(msg.sender == governance() || msg.sender == controller);
        _;
    }

    modifier onlyController(){
        require( msg.sender == controller);
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
            profits: 0
        });

        projects.push(_project);
        investorListOf[id].push(_launcher);
        investorOf[id][_launcher] = _amount;

        return id;
    }

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
        address participator) public onlyControllerOrGovernance returns(uint256 reward, address vault){
        vault = projects[Id].vault;
        uint256 input = investorOf[Id][participator];
        if (input == 0){// 如果地址不在项目中，那么不发收益，只更新总收益额
            return (0, vault);
        }

        uint256 totalProfit = projects[Id].profits;
        uint256 _totalAmount = projects[Id].totalAmount;
        // todo safeMath    !!!!!! 这里有问题，需要先扩增下，乘以倍数再去做除法
        reward = input * totalProfit / _totalAmount;
//        lpReward = input * _totalShare / _totalAmount;
        // todo 收益者项目参数数量+1，回购额度更新

//        IRewardPool(rewardPool).pushReward(participator, lpReward);
        return (reward, vault);
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

        // todo use safeMath
        // todo use memory to save gas?
        projects[Id].totalAmount += amount;
        if (investorOf[Id][_investor] == 0){
            investorListOf[Id].push(_investor);
        }
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

        // todo wait for the clear formula
        // todo 投资者开始进行项目token收益挖矿
        updateTokenReward(Id, totalShare);
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

    function updateTokenReward(uint256 Id, uint256 _totalShare) public {
//        uint memory len = investorListOf.length;
//        uint256 memory totalAmount = projects[Id].totalAmount;
//        for (uint i = 0; i < len; i++){
//            address memory investor = investorListOf[i];
//            uint256 memory amount =  investorOf[Id][investor];
//            // todo safeMath
//            uint256 memory share = amount * _totalShare / totalAmount;
//            IRewardPool(rewardPool).stakeFor(investor, share);
//
//            address memory _fInviter = promotersOf[Id][investor].fInviter;
//            address memory _sInviter = promotersOf[Id][investor].sInviter;
//            // todo compare with eth
//            uint256 ethPrice;
//            if (_fInviter != address(0)){
//                IERC(rewardToken).safeTransfer(_fInviter, amount * 20 /  ethPrice);
//                if (_sInviter != address(0)) IERC(rewardToken).safeTransfer(_sInviter, amount * 20 *10 / (100 * ethPrice));
//            }
//        }
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
        return projects.length >= Id;
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
        address underlying,
        uint256 decimals,
        uint256 startAmountMin,
        uint256 perAmountMin,
        uint memberMin,
        uint256 deadline,
        uint256 duration){
        require(isProjectExist(Id), "Project dose not exist");
        address _vault = projects[Id].vault;
        underlying = IVault(_vault).underlying();
        decimals = IVault(_vault).underlyingUnit();
        startAmountMin = projectsCondition[Id].totalAmountMin;
        perAmountMin = projectsCondition[Id].perAmountMin;
        memberMin = projectsCondition[Id].attendanceMin;
        deadline = projectsCondition[Id].deadline;
        duration = projects[Id].duration;
        return (underlying, decimals, startAmountMin, perAmountMin, memberMin, deadline, duration);
    }
}