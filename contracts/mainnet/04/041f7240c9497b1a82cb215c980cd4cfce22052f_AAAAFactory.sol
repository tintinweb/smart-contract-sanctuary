/**
 *Submitted for verification at Etherscan.io on 2020-12-02
*/

// Dependency file: contracts/libraries/TransferHelper.sol

//SPDX-License-Identifier: MIT

// pragma solidity >=0.6.0;

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}


// Dependency file: contracts/libraries/SafeMath.sol


// pragma solidity >=0.6.0;

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

// Dependency file: contracts/modules/Configable.sol

// pragma solidity >=0.5.16;
pragma experimental ABIEncoderV2;

interface IConfig {
    function developer() external view returns (address);
    function platform() external view returns (address);
    function factory() external view returns (address);
    function mint() external view returns (address);
    function token() external view returns (address);
    function developPercent() external view returns (uint);
    function share() external view returns (address);
    function base() external view returns (address); 
    function governor() external view returns (address);
    function getPoolValue(address pool, bytes32 key) external view returns (uint);
    function getValue(bytes32 key) external view returns(uint);
    function getParams(bytes32 key) external view returns(uint, uint, uint, uint); 
    function getPoolParams(address pool, bytes32 key) external view returns(uint, uint, uint, uint); 
    function wallets(bytes32 key) external view returns(address);
    function setValue(bytes32 key, uint value) external;
    function setPoolValue(address pool, bytes32 key, uint value) external;
    function setParams(bytes32 _key, uint _min, uint _max, uint _span, uint _value) external;
    function setPoolParams(bytes32 _key, uint _min, uint _max, uint _span, uint _value) external;
    function initPoolParams(address _pool) external;
    function isMintToken(address _token) external returns (bool);
    function prices(address _token) external returns (uint);
    function convertTokenAmount(address _fromToken, address _toToken, uint _fromAmount) external view returns (uint);
    function DAY() external view returns (uint);
    function WETH() external view returns (address);
}

contract Configable {
    address public config;
    address public owner;

    event OwnerChanged(address indexed _oldOwner, address indexed _newOwner);

    constructor() public {
        owner = msg.sender;
    }
    
    function setupConfig(address _config) external onlyOwner {
        config = _config;
        owner = IConfig(config).developer();
    }

    modifier onlyOwner() {
        require(msg.sender == owner, 'OWNER FORBIDDEN');
        _;
    }
    
    modifier onlyDeveloper() {
        require(msg.sender == IConfig(config).developer(), 'DEVELOPER FORBIDDEN');
        _;
    }
    
    modifier onlyPlatform() {
        require(msg.sender == IConfig(config).platform(), 'PLATFORM FORBIDDEN');
        _;
    }

    modifier onlyFactory() {
        require(msg.sender == IConfig(config).factory(), 'FACTORY FORBIDDEN');
        _;
    }

    modifier onlyGovernor() {
        require(msg.sender == IConfig(config).governor(), 'Governor FORBIDDEN');
        _;
    }
}

// Dependency file: contracts/modules/ConfigNames.sol

// pragma solidity >=0.5.16;

library ConfigNames {
    //GOVERNANCE
    bytes32 public constant PROPOSAL_VOTE_DURATION = bytes32('PROPOSAL_VOTE_DURATION');
    bytes32 public constant PROPOSAL_EXECUTE_DURATION = bytes32('PROPOSAL_EXECUTE_DURATION');
    bytes32 public constant PROPOSAL_CREATE_COST = bytes32('PROPOSAL_CREATE_COST');
    bytes32 public constant STAKE_LOCK_TIME = bytes32('STAKE_LOCK_TIME');
    bytes32 public constant MINT_AMOUNT_PER_BLOCK =  bytes32('MINT_AMOUNT_PER_BLOCK');
    bytes32 public constant INTEREST_PLATFORM_SHARE =  bytes32('INTEREST_PLATFORM_SHARE');
    bytes32 public constant CHANGE_PRICE_DURATION =  bytes32('CHANGE_PRICE_DURATION');
    bytes32 public constant CHANGE_PRICE_PERCENT =  bytes32('CHANGE_PRICE_PERCENT');

    // POOL
    bytes32 public constant POOL_BASE_INTERESTS = bytes32('POOL_BASE_INTERESTS');
    bytes32 public constant POOL_MARKET_FRENZY = bytes32('POOL_MARKET_FRENZY');
    bytes32 public constant POOL_PLEDGE_RATE = bytes32('POOL_PLEDGE_RATE');
    bytes32 public constant POOL_LIQUIDATION_RATE = bytes32('POOL_LIQUIDATION_RATE');
    bytes32 public constant POOL_MINT_BORROW_PERCENT = bytes32('POOL_MINT_BORROW_PERCENT');
    bytes32 public constant POOL_MINT_POWER = bytes32('POOL_MINT_POWER');
    
    //NOT GOVERNANCE
    bytes32 public constant AAAA_USER_MINT = bytes32('AAAA_USER_MINT');
    bytes32 public constant AAAA_TEAM_MINT = bytes32('AAAA_TEAM_MINT');
    bytes32 public constant AAAA_REWAED_MINT = bytes32('AAAA_REWAED_MINT');
    bytes32 public constant DEPOSIT_ENABLE = bytes32('DEPOSIT_ENABLE');
    bytes32 public constant WITHDRAW_ENABLE = bytes32('WITHDRAW_ENABLE');
    bytes32 public constant BORROW_ENABLE = bytes32('BORROW_ENABLE');
    bytes32 public constant REPAY_ENABLE = bytes32('REPAY_ENABLE');
    bytes32 public constant LIQUIDATION_ENABLE = bytes32('LIQUIDATION_ENABLE');
    bytes32 public constant REINVEST_ENABLE = bytes32('REINVEST_ENABLE');
    bytes32 public constant INTEREST_BUYBACK_SHARE =  bytes32('INTEREST_BUYBACK_SHARE');

    //POOL
    bytes32 public constant POOL_PRICE = bytes32('POOL_PRICE');

    //wallet
    bytes32 public constant TEAM = bytes32('team'); 
    bytes32 public constant SPARE = bytes32('spare');
    bytes32 public constant REWARD = bytes32('reward');
}

// Dependency file: contracts/modules/BaseMintField.sol

// pragma solidity >=0.5.16;
// import "contracts/libraries/SafeMath.sol";
// import "contracts/libraries/TransferHelper.sol";
// import "contracts/modules/Configable.sol";
// import "contracts/modules/ConfigNames.sol";

interface IERC20 {
    function approve(address spender, uint value) external returns (bool);
    function balanceOf(address owner) external view returns (uint);
}

contract BaseMintField is Configable {
    using SafeMath for uint;
    
    uint public mintCumulation;
    
    uint public totalLendProductivity;
    uint public totalBorrowProducitivity;
    uint public accAmountPerLend;
    uint public accAmountPerBorrow;
    
    uint public totalBorrowSupply;
    uint public totalLendSupply;
    
    struct UserInfo {
        uint amount;     // How many tokens the user has provided.
        uint rewardDebt; // Reward debt. 
        uint rewardEarn; // Reward earn and not minted
        uint index;
    }
    
    mapping(address => UserInfo) public lenders;
    mapping(address => UserInfo) public borrowers;
    
    uint public totalShare;
    uint public mintedShare;

    event BorrowPowerChange (uint oldValue, uint newValue);
    event InterestRatePerBlockChanged (uint oldValue, uint newValue);
    event BorrowerProductivityIncreased (address indexed user, uint value);
    event BorrowerProductivityDecreased (address indexed user, uint value);
    event LenderProductivityIncreased (address indexed user, uint value);
    event LenderProductivityDecreased (address indexed user, uint value);
    event MintLender(address indexed user, uint userAmount);
    event MintBorrower(address indexed user, uint userAmount);

    // Update reward variables of the given pool to be up-to-date.
    function _update() internal virtual {
        uint256 reward = _currentReward();
        totalShare += reward;
        if (totalLendProductivity.add(totalBorrowProducitivity) == 0 || reward == 0) {
            return;
        }
        
        uint borrowReward = reward.mul(IConfig(config).getPoolValue(address(this), ConfigNames.POOL_MINT_BORROW_PERCENT)).div(10000);
        uint lendReward = reward.sub(borrowReward);
     
        if(totalLendProductivity != 0 && lendReward > 0) {
            totalLendSupply = totalLendSupply.add(lendReward);
            accAmountPerLend = accAmountPerLend.add(lendReward.mul(1e12).div(totalLendProductivity));
        }

        if(totalBorrowProducitivity != 0 && borrowReward > 0) {
            totalBorrowSupply = totalBorrowSupply.add(borrowReward);
            accAmountPerBorrow = accAmountPerBorrow.add(borrowReward.mul(1e12).div(totalBorrowProducitivity));
        }
    }
    
    function _currentReward() internal virtual view returns (uint){
        return mintedShare.add(IERC20(IConfig(config).token()).balanceOf(address(this))).sub(totalShare);
    }
    
    // Audit borrowers's reward to be up-to-date
    function _auditBorrower(address user) internal {
        UserInfo storage userInfo = borrowers[user];
        if (userInfo.amount > 0) {
            uint pending = userInfo.amount.mul(accAmountPerBorrow).div(1e12).sub(userInfo.rewardDebt);
            userInfo.rewardEarn = userInfo.rewardEarn.add(pending);
            mintCumulation = mintCumulation.add(pending);
            userInfo.rewardDebt = userInfo.amount.mul(accAmountPerBorrow).div(1e12);
        }
    }
    
    // Audit lender's reward to be up-to-date
    function _auditLender(address user) internal {
        UserInfo storage userInfo = lenders[user];
        if (userInfo.amount > 0) {
            uint pending = userInfo.amount.mul(accAmountPerLend).div(1e12).sub(userInfo.rewardDebt);
            userInfo.rewardEarn = userInfo.rewardEarn.add(pending);
            mintCumulation = mintCumulation.add(pending);
            userInfo.rewardDebt = userInfo.amount.mul(accAmountPerLend).div(1e12);
        }
    }

    function _increaseBorrowerProductivity(address user, uint value) internal returns (bool) {
        require(value > 0, 'PRODUCTIVITY_VALUE_MUST_BE_GREATER_THAN_ZERO');

        UserInfo storage userInfo = borrowers[user];
        _update();
        _auditBorrower(user);

        totalBorrowProducitivity = totalBorrowProducitivity.add(value);

        userInfo.amount = userInfo.amount.add(value);
        userInfo.rewardDebt = userInfo.amount.mul(accAmountPerBorrow).div(1e12);
        emit BorrowerProductivityIncreased(user, value);
        return true;
    }

    function _decreaseBorrowerProductivity(address user, uint value) internal returns (bool) {
        require(value > 0, 'INSUFFICIENT_PRODUCTIVITY');
        
        UserInfo storage userInfo = borrowers[user];
        require(userInfo.amount >= value, "FORBIDDEN");
        _update();
        _auditBorrower(user);
        
        userInfo.amount = userInfo.amount.sub(value);
        userInfo.rewardDebt = userInfo.amount.mul(accAmountPerBorrow).div(1e12);
        totalBorrowProducitivity = totalBorrowProducitivity.sub(value);

        emit BorrowerProductivityDecreased(user, value);
        return true;
    }
    
    function _increaseLenderProductivity(address user, uint value) internal returns (bool) {
        require(value > 0, 'PRODUCTIVITY_VALUE_MUST_BE_GREATER_THAN_ZERO');

        UserInfo storage userInfo = lenders[user];
        _update();
        _auditLender(user);

        totalLendProductivity = totalLendProductivity.add(value);

        userInfo.amount = userInfo.amount.add(value);
        userInfo.rewardDebt = userInfo.amount.mul(accAmountPerLend).div(1e12);
        emit LenderProductivityIncreased(user, value);
        return true;
    }

    // External function call 
    // This function will decreases user's productivity by value, and updates the global productivity
    // it will record which block this is happenning and accumulates the area of (productivity * time)
    function _decreaseLenderProductivity(address user, uint value) internal returns (bool) {
        require(value > 0, 'INSUFFICIENT_PRODUCTIVITY');
        
        UserInfo storage userInfo = lenders[user];
        require(userInfo.amount >= value, "FORBIDDEN");
        _update();
        _auditLender(user);
        
        userInfo.amount = userInfo.amount.sub(value);
        userInfo.rewardDebt = userInfo.amount.mul(accAmountPerLend).div(1e12);
        totalLendProductivity = totalLendProductivity.sub(value);

        emit LenderProductivityDecreased(user, value);
        return true;
    }
    
    function takeBorrowWithAddress(address user) public view returns (uint) {
        UserInfo storage userInfo = borrowers[user];
        uint _accAmountPerBorrow = accAmountPerBorrow;
        if (totalBorrowProducitivity != 0) {
            uint reward = _currentReward();
            uint borrowReward = reward.mul(IConfig(config).getPoolValue(address(this), ConfigNames.POOL_MINT_BORROW_PERCENT)).div(10000);
            
            _accAmountPerBorrow = accAmountPerBorrow.add(borrowReward.mul(1e12).div(totalBorrowProducitivity));
        }

        return userInfo.amount.mul(_accAmountPerBorrow).div(1e12).sub(userInfo.rewardDebt).add(userInfo.rewardEarn);
    }
    
    function takeLendWithAddress(address user) public view returns (uint) {
        UserInfo storage userInfo = lenders[user];
        uint _accAmountPerLend = accAmountPerLend;
        if (totalLendProductivity != 0) {
            uint reward = _currentReward();
            uint lendReward = reward.sub(reward.mul(IConfig(config).getPoolValue(address(this), ConfigNames.POOL_MINT_BORROW_PERCENT)).div(10000)); 
            _accAmountPerLend = accAmountPerLend.add(lendReward.mul(1e12).div(totalLendProductivity));
        }
        return userInfo.amount.mul(_accAmountPerLend).div(1e12).sub(userInfo.rewardDebt).add(userInfo.rewardEarn);
    }

    function takeBorrowWithBlock() external view returns (uint, uint) {
        uint earn = takeBorrowWithAddress(msg.sender);
        return (earn, block.number);
    }
    
    function takeLendWithBlock() external view returns (uint, uint) {
        uint earn = takeLendWithAddress(msg.sender);
        return (earn, block.number);
    }

    function takeAll() public view returns (uint) {
        return takeBorrowWithAddress(msg.sender).add(takeLendWithAddress(msg.sender));
    }

    function takeAllWithBlock() external view returns (uint, uint) {
        return (takeAll(), block.number);
    }

    function _mintBorrower() internal returns (uint) {
        _update();
        _auditBorrower(msg.sender); 
        if(borrowers[msg.sender].rewardEarn > 0) {
            uint amount = borrowers[msg.sender].rewardEarn;
            _mintDistribution(msg.sender, amount);
            borrowers[msg.sender].rewardEarn = 0;
            emit MintBorrower(msg.sender, amount);
            return amount;
        }
    }
    
    function _mintLender() internal returns (uint) {
        _update();
        _auditLender(msg.sender);
        if(lenders[msg.sender].rewardEarn > 0) {
            uint amount = lenders[msg.sender].rewardEarn;
            _mintDistribution(msg.sender, amount);
            lenders[msg.sender].rewardEarn = 0;
            emit MintLender(msg.sender, amount);
            return amount;
        }
    }

    // Returns how many productivity a user has and global has.
    function getBorrowerProductivity(address user) external view returns (uint, uint) {
        return (borrowers[user].amount, totalBorrowProducitivity);
    }
    
    function getLenderProductivity(address user) external view returns (uint, uint) {
        return (lenders[user].amount, totalLendProductivity);
    }

    // Returns the current gorss product rate.
    function interestsPerBlock() external view returns (uint, uint) {
        return (accAmountPerBorrow, accAmountPerLend);
    }

    function _mintDistribution(address user, uint amount) internal {
        if(amount > 0) {
           mintedShare += amount;
           TransferHelper.safeTransfer(IConfig(config).token(), user, amount);
        }
    }
}

// Dependency file: contracts/AAAA.sol

// pragma solidity >=0.5.16;
// import "contracts/libraries/TransferHelper.sol";
// import "contracts/libraries/SafeMath.sol";
// import "contracts/modules/Configable.sol";
// import "contracts/modules/ConfigNames.sol";
// import "contracts/modules/BaseMintField.sol";

interface ICollateralStrategy {
    function invest(address user, uint amount) external; 
    function withdraw(address user, uint amount) external;
    function liquidation(address user) external;
    function claim(address user, uint amount, uint total) external;
    function exit(uint amount) external;
    function migrate(address old) external;
    function collateralToken() external returns (address);
}

interface IAAAAMint {
    function take() external view returns (uint);
    function mint() external returns (uint);
}

contract AAAAPool is Configable, BaseMintField
{
    using SafeMath for uint;

    address public factory;
    address public supplyToken;
    uint public supplyDecimal;
    address public collateralToken;
    uint public collateralDecimal;

    struct SupplyStruct {
        uint amountSupply;
        uint interestSettled;
        uint liquidationSettled;

        uint interests;
        uint liquidation;
    }

    struct BorrowStruct {
        uint index;
        uint amountCollateral;
        uint interestSettled;
        uint amountBorrow;
        uint interests;
    }

    struct LiquidationStruct {
        uint amountCollateral;
        uint liquidationAmount;
        uint timestamp;
    }

    address[] public borrowerList;
    uint public numberBorrowers;

    mapping(address => SupplyStruct) public supplys;
    mapping(address => BorrowStruct) public borrows;
    mapping(address => LiquidationStruct []) public liquidationHistory;
    mapping(address => uint) public liquidationHistoryLength;

    uint public interestPerSupply;
    uint public liquidationPerSupply;
    uint public interestPerBorrow;

    uint public totalLiquidation;
    uint public totalLiquidationSupplyAmount;

    uint public totalStake;
    uint public totalBorrow;
    uint public totalPledge;

    uint public remainSupply;

    uint public lastInterestUpdate;

    address public collateralStrategy;
    address[] public strategyList;
    uint strategyCount;

    event Deposit(address indexed _user, uint _amount, uint _collateralAmount);
    event Withdraw(address indexed _user, uint _supplyAmount, uint _collateralAmount, uint _interestAmount);
    event Borrow(address indexed _user, uint _supplyAmount, uint _collateralAmount);
    event Repay(address indexed _user, uint _supplyAmount, uint _collateralAmount, uint _interestAmount);
    event Liquidation(address indexed _liquidator, address indexed _user, uint _supplyAmount, uint _collateralAmount);
    event Reinvest(address indexed _user, uint _reinvestAmount);

    function switchStrategy(address _collateralStrategy) external onlyPlatform
    {

        if(collateralStrategy != address(0) && totalPledge > 0)
        {
            ICollateralStrategy(collateralStrategy).exit(totalPledge);
        }

        if(_collateralStrategy != address(0))
        {
            require(ICollateralStrategy(_collateralStrategy).collateralToken() == collateralToken && collateralStrategy != _collateralStrategy, "AAAA: INVALID STRATEGY");

            strategyCount++;
            strategyList.push(_collateralStrategy);

            if(totalPledge > 0) {
                TransferHelper.safeTransfer(collateralToken, _collateralStrategy, totalPledge);
            }
            ICollateralStrategy(_collateralStrategy).migrate(collateralStrategy);
        }

        collateralStrategy = _collateralStrategy;
    }

    constructor() public 
    {
        factory = msg.sender;
    }

    function init(address _supplyToken, address _collateralToken) external onlyFactory
    {
        supplyToken = _supplyToken;
        collateralToken = _collateralToken;

        lastInterestUpdate = block.number;
    }

    function updateInterests() internal
    {
        uint totalSupply = totalBorrow + remainSupply;
        uint interestPerBlock = getInterests();

        interestPerSupply = interestPerSupply.add(totalSupply == 0 ? 0 : interestPerBlock.mul(block.number - lastInterestUpdate).mul(totalBorrow).div(totalSupply));
        interestPerBorrow = interestPerBorrow.add(interestPerBlock.mul(block.number - lastInterestUpdate));
        lastInterestUpdate = block.number;
    }

    function getInterests() public view returns(uint interestPerBlock)
    {
        uint totalSupply = totalBorrow + remainSupply;
        uint baseInterests = IConfig(config).getPoolValue(address(this), ConfigNames.POOL_BASE_INTERESTS);
        uint marketFrenzy = IConfig(config).getPoolValue(address(this), ConfigNames.POOL_MARKET_FRENZY);
        uint aDay = IConfig(config).DAY();
        interestPerBlock = totalSupply == 0 ? 0 : baseInterests.add(totalBorrow.mul(marketFrenzy).div(totalSupply)).div(365 * aDay);
    }

    function updateLiquidation(uint _liquidation) internal
    {
        uint totalSupply = totalBorrow + remainSupply;
        liquidationPerSupply = liquidationPerSupply.add(totalSupply == 0 ? 0 : _liquidation.mul(1e18).div(totalSupply));
    }

    function deposit(uint amountDeposit, address from) public onlyPlatform
    {
        require(amountDeposit > 0, "AAAA: INVALID AMOUNT");
        uint amountIn = IERC20(supplyToken).balanceOf(address(this)).sub(remainSupply);
        require(amountIn >= amountDeposit, "AAAA: INVALID AMOUNT");

        updateInterests();

        uint addLiquidation = liquidationPerSupply.mul(supplys[from].amountSupply).div(1e18).sub(supplys[from].liquidationSettled);

        supplys[from].interests = supplys[from].interests.add(interestPerSupply.mul(supplys[from].amountSupply).div(1e18).sub(supplys[from].interestSettled));
        supplys[from].liquidation = supplys[from].liquidation.add(addLiquidation);

        supplys[from].amountSupply = supplys[from].amountSupply.add(amountDeposit);
        remainSupply = remainSupply.add(amountDeposit);
        
        totalStake = totalStake.add(amountDeposit);
        _mintToPool();
        _increaseLenderProductivity(from, amountDeposit);

        supplys[from].interestSettled = interestPerSupply.mul(supplys[from].amountSupply).div(1e18);
        supplys[from].liquidationSettled = liquidationPerSupply.mul(supplys[from].amountSupply).div(1e18);
        emit Deposit(from, amountDeposit, addLiquidation);
    }

    function reinvest(address from) public onlyPlatform returns(uint reinvestAmount)
    {
        updateInterests();

        uint addLiquidation = liquidationPerSupply.mul(supplys[from].amountSupply).div(1e18).sub(supplys[from].liquidationSettled);

        supplys[from].interests = supplys[from].interests.add(interestPerSupply.mul(supplys[from].amountSupply).div(1e18).sub(supplys[from].interestSettled));
        supplys[from].liquidation = supplys[from].liquidation.add(addLiquidation);

        reinvestAmount = supplys[from].interests;

        uint platformShare = reinvestAmount.mul(IConfig(config).getValue(ConfigNames.INTEREST_PLATFORM_SHARE)).div(1e18);
        reinvestAmount = reinvestAmount.sub(platformShare);

        supplys[from].amountSupply = supplys[from].amountSupply.add(reinvestAmount);
        totalStake = totalStake.add(reinvestAmount);
        supplys[from].interests = 0;

        supplys[from].interestSettled = supplys[from].amountSupply == 0 ? 0 : interestPerSupply.mul(supplys[from].amountSupply).div(1e18);
        supplys[from].liquidationSettled = supplys[from].amountSupply == 0 ? 0 : liquidationPerSupply.mul(supplys[from].amountSupply).div(1e18);

        distributePlatformShare(platformShare);
        _mintToPool();
        if(reinvestAmount > 0) {
           _increaseLenderProductivity(from, reinvestAmount); 
        }

        emit Reinvest(from, reinvestAmount);
    }

    function distributePlatformShare(uint platformShare) internal 
    {
        require(platformShare <= remainSupply, "AAAA: NOT ENOUGH PLATFORM SHARE");
        if(platformShare > 0) {
            uint buybackShare = IConfig(config).getValue(ConfigNames.INTEREST_BUYBACK_SHARE);
            uint buybackAmount = platformShare.mul(buybackShare).div(1e18);
            uint dividendAmount = platformShare.sub(buybackAmount);
            if(dividendAmount > 0) TransferHelper.safeTransfer(supplyToken, IConfig(config).share(), dividendAmount);
            if(buybackAmount > 0) TransferHelper.safeTransfer(supplyToken, IConfig(config).wallets(bytes32("team")), buybackAmount);
            remainSupply = remainSupply.sub(platformShare);
        }
    }

    function withdraw(uint amountWithdraw, address from) public onlyPlatform returns(uint withdrawSupplyAmount, uint withdrawLiquidation)
    {
        require(amountWithdraw > 0, "AAAA: INVALID AMOUNT");
        require(amountWithdraw <= supplys[from].amountSupply, "AAAA: NOT ENOUGH BALANCE");

        updateInterests();

        uint addLiquidation = liquidationPerSupply.mul(supplys[from].amountSupply).div(1e18).sub(supplys[from].liquidationSettled);

        supplys[from].interests = supplys[from].interests.add(interestPerSupply.mul(supplys[from].amountSupply).div(1e18).sub(supplys[from].interestSettled));
        supplys[from].liquidation = supplys[from].liquidation.add(addLiquidation);

        withdrawLiquidation = supplys[from].liquidation.mul(amountWithdraw).div(supplys[from].amountSupply);
        uint withdrawInterest = supplys[from].interests.mul(amountWithdraw).div(supplys[from].amountSupply);

        uint platformShare = withdrawInterest.mul(IConfig(config).getValue(ConfigNames.INTEREST_PLATFORM_SHARE)).div(1e18);
        uint userShare = withdrawInterest.sub(platformShare);

        distributePlatformShare(platformShare);

        uint withdrawLiquidationSupplyAmount = totalLiquidation == 0 ? 0 : withdrawLiquidation.mul(totalLiquidationSupplyAmount).div(totalLiquidation);
        
        if(withdrawLiquidationSupplyAmount < amountWithdraw.add(userShare))
            withdrawSupplyAmount = amountWithdraw.add(userShare).sub(withdrawLiquidationSupplyAmount);
        
        require(withdrawSupplyAmount <= remainSupply, "AAAA: NOT ENOUGH POOL BALANCE");
        require(withdrawLiquidation <= totalLiquidation, "AAAA: NOT ENOUGH LIQUIDATION");

        remainSupply = remainSupply.sub(withdrawSupplyAmount);
        totalLiquidation = totalLiquidation.sub(withdrawLiquidation);
        totalLiquidationSupplyAmount = totalLiquidationSupplyAmount.sub(withdrawLiquidationSupplyAmount);
        totalPledge = totalPledge.sub(withdrawLiquidation);

        supplys[from].interests = supplys[from].interests.sub(withdrawInterest);
        supplys[from].liquidation = supplys[from].liquidation.sub(withdrawLiquidation);
        supplys[from].amountSupply = supplys[from].amountSupply.sub(amountWithdraw);
        totalStake = totalStake.sub(amountWithdraw);

        supplys[from].interestSettled = supplys[from].amountSupply == 0 ? 0 : interestPerSupply.mul(supplys[from].amountSupply).div(1e18);
        supplys[from].liquidationSettled = supplys[from].amountSupply == 0 ? 0 : liquidationPerSupply.mul(supplys[from].amountSupply).div(1e18);

        _mintToPool();
        if(withdrawSupplyAmount > 0) {
            TransferHelper.safeTransfer(supplyToken, msg.sender, withdrawSupplyAmount);
        } 

        _decreaseLenderProductivity(from, amountWithdraw); 

        if(withdrawLiquidation > 0) {
            if(collateralStrategy != address(0))
            {
                ICollateralStrategy(collateralStrategy).claim(from, withdrawLiquidation, totalLiquidation.add(withdrawLiquidation));   
            }
            TransferHelper.safeTransfer(collateralToken, msg.sender, withdrawLiquidation);
        }
        
        emit Withdraw(from, withdrawSupplyAmount, withdrawLiquidation, withdrawInterest);
    }

    function borrow(uint amountCollateral, uint repayAmount, uint expectBorrow, address from) public onlyPlatform
    {
        uint amountIn = IERC20(collateralToken).balanceOf(address(this));
        if(collateralStrategy == address(0))
            amountIn = amountIn.sub(totalPledge);
            
        require(amountIn == amountCollateral, "AAAA: INVALID AMOUNT");

        // if(amountCollateral > 0) TransferHelper.safeTransferFrom(collateralToken, from, address(this), amountCollateral);

        updateInterests();
        
        uint pledgeRate = IConfig(config).getPoolValue(address(this), ConfigNames.POOL_PLEDGE_RATE);
        uint maxAmount = IConfig(config).convertTokenAmount(collateralToken, supplyToken, borrows[from].amountCollateral.add(amountCollateral));

        uint maximumBorrow = maxAmount.mul(pledgeRate).div(1e18);
        // uint repayAmount = getRepayAmount(borrows[from].amountCollateral, from);

        require(repayAmount + expectBorrow <= maximumBorrow, "AAAA: EXCEED MAX ALLOWED");
        require(expectBorrow <= remainSupply, "AAAA: INVALID BORROW");

        totalBorrow = totalBorrow.add(expectBorrow);
        totalPledge = totalPledge.add(amountCollateral);
        remainSupply = remainSupply.sub(expectBorrow);

        if(collateralStrategy != address(0) && amountCollateral > 0)
        {
            IERC20(ICollateralStrategy(collateralStrategy).collateralToken()).approve(collateralStrategy, amountCollateral);
            ICollateralStrategy(collateralStrategy).invest(from, amountCollateral); 
        }

        if(borrows[from].index == 0)
        {
            borrowerList.push(from);
            borrows[from].index = borrowerList.length;
            numberBorrowers ++;
        }

        borrows[from].interests = borrows[from].interests.add(interestPerBorrow.mul(borrows[from].amountBorrow).div(1e18).sub(borrows[from].interestSettled));
        borrows[from].amountCollateral = borrows[from].amountCollateral.add(amountCollateral);
        borrows[from].amountBorrow = borrows[from].amountBorrow.add(expectBorrow);
        borrows[from].interestSettled = interestPerBorrow.mul(borrows[from].amountBorrow).div(1e18);

        _mintToPool();
        if(expectBorrow > 0) {
            TransferHelper.safeTransfer(supplyToken, msg.sender, expectBorrow);
            _increaseBorrowerProductivity(from, expectBorrow);
        } 
        
        emit Borrow(from, expectBorrow, amountCollateral);
    }

    function repay(uint amountCollateral, address from) public onlyPlatform returns(uint repayAmount, uint repayInterest)
    {
        require(amountCollateral <= borrows[from].amountCollateral, "AAAA: NOT ENOUGH COLLATERAL");
        require(amountCollateral > 0, "AAAA: INVALID AMOUNT");

        uint amountIn = IERC20(supplyToken).balanceOf(address(this)).sub(remainSupply);

        updateInterests();

        borrows[from].interests = borrows[from].interests.add(interestPerBorrow.mul(borrows[from].amountBorrow).div(1e18).sub(borrows[from].interestSettled));

        repayAmount = borrows[from].amountBorrow.mul(amountCollateral).div(borrows[from].amountCollateral);
        repayInterest = borrows[from].interests.mul(amountCollateral).div(borrows[from].amountCollateral);

        totalPledge = totalPledge.sub(amountCollateral);
        totalBorrow = totalBorrow.sub(repayAmount);
        
        borrows[from].amountCollateral = borrows[from].amountCollateral.sub(amountCollateral);
        borrows[from].amountBorrow = borrows[from].amountBorrow.sub(repayAmount);
        borrows[from].interests = borrows[from].interests.sub(repayInterest);
        borrows[from].interestSettled = borrows[from].amountBorrow == 0 ? 0 : interestPerBorrow.mul(borrows[from].amountBorrow).div(1e18);

        remainSupply = remainSupply.add(repayAmount.add(repayInterest));

        if(collateralStrategy != address(0))
        {
            ICollateralStrategy(collateralStrategy).withdraw(from, amountCollateral);
        }
        TransferHelper.safeTransfer(collateralToken, msg.sender, amountCollateral);
        require(amountIn >= repayAmount.add(repayInterest), "AAAA: INVALID AMOUNT");
        // TransferHelper.safeTransferFrom(supplyToken, from, address(this), repayAmount.add(repayInterest));
        
        _mintToPool();
        if(repayAmount > 0) {
            _decreaseBorrowerProductivity(from, repayAmount);
        }

        emit Repay(from, repayAmount, amountCollateral, repayInterest);
    }

    function liquidation(address _user, address from) public onlyPlatform returns(uint borrowAmount)
    {
        require(supplys[from].amountSupply > 0, "AAAA: ONLY SUPPLIER");

        updateInterests();

        borrows[_user].interests = borrows[_user].interests.add(interestPerBorrow.mul(borrows[_user].amountBorrow).div(1e18).sub(borrows[_user].interestSettled));

        uint liquidationRate = IConfig(config).getPoolValue(address(this), ConfigNames.POOL_LIQUIDATION_RATE);
        
        // uint pledgePrice = IConfig(config).getPoolValue(address(this), ConfigNames.POOL_PRICE);
        // uint collateralValue = borrows[_user].amountCollateral.mul(pledgePrice).div(1e18);
        uint collateralValue = IConfig(config).convertTokenAmount(collateralToken, supplyToken, borrows[_user].amountCollateral);
        
        uint expectedRepay = borrows[_user].amountBorrow.add(borrows[_user].interests);

        require(expectedRepay >= collateralValue.mul(liquidationRate).div(1e18), 'AAAA: NOT LIQUIDABLE');

        updateLiquidation(borrows[_user].amountCollateral);

        totalLiquidation = totalLiquidation.add(borrows[_user].amountCollateral);
        totalLiquidationSupplyAmount = totalLiquidationSupplyAmount.add(expectedRepay);
        totalBorrow = totalBorrow.sub(borrows[_user].amountBorrow);

        borrowAmount = borrows[_user].amountBorrow;

        LiquidationStruct memory liq;
        liq.amountCollateral = borrows[_user].amountCollateral;
        liq.liquidationAmount = expectedRepay;
        liq.timestamp = block.timestamp;
        
        liquidationHistory[_user].push(liq);
        liquidationHistoryLength[_user] ++;
        ICollateralStrategy(collateralStrategy).liquidation(_user);
        
        emit Liquidation(from, _user, borrows[_user].amountBorrow, borrows[_user].amountCollateral);

        borrows[_user].amountCollateral = 0;
        borrows[_user].amountBorrow = 0;
        borrows[_user].interests = 0;
        borrows[_user].interestSettled = 0;
        
        _mintToPool();
        if(borrowAmount > 0) {
            _decreaseBorrowerProductivity(_user, borrowAmount);
        }
    }

    function getTotalAmount() external view returns (uint) {
        return totalStake.add(totalBorrow);
    }

    function _mintToPool() internal {
        if(IAAAAMint(IConfig(config).mint()).take() > 0) {
            IAAAAMint(IConfig(config).mint()).mint();
        }
    }

    function mint() external {
        _mintToPool();
        _mintLender();
        _mintBorrower();
    }

    function _currentReward() internal override view returns (uint) {
        uint remain = IAAAAMint(IConfig(config).mint()).take();
        return remain.add(mintedShare).add(IERC20(IConfig(config).token()).balanceOf(address(this))).sub(totalShare);
    }
}

// Root file: contracts/AAAAFactory.sol

pragma solidity >=0.5.16;

// import "contracts/AAAA.sol";
// import "contracts/modules/Configable.sol";

interface IAAAAPool {
    function init(address supplyToken,  address collateralToken) external;
    function setupConfig(address config) external;
}

interface IAAAABallot {
    function initialize(address creator, address pool, bytes32 name, uint value, uint reward, string calldata subject, string calldata content) external;
    function setupConfig(address config) external;
}

contract AAAAFactory is Configable{

    event PoolCreated(address indexed lendToken, address indexed collateralToken, address indexed pool);
    event BallotCreated(address indexed creator, address indexed pool, address indexed ballot, bytes32 name, uint value);

    
    address[] public allPools;
    mapping(address => bool) public isPool;
    mapping (address => mapping (address => address)) public getPool;
    
    address[] public allBallots;
    bytes32 ballotByteCodeHash;

    function createPool(address _lendToken, address _collateralToken) onlyDeveloper external returns (address pool) {
        require(getPool[_lendToken][_collateralToken] == address(0), "ALREADY CREATED");
        
        bytes32 salt = keccak256(abi.encodePacked(_lendToken, _collateralToken));
        bytes memory bytecode = type(AAAAPool).creationCode;
        assembly {
            pool := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        getPool[_lendToken][_collateralToken] = pool;
            
        allPools.push(pool);
        isPool[pool] = true;
        IConfig(config).initPoolParams(pool);
        IAAAAPool(pool).setupConfig(config);
        IAAAAPool(pool).init(_lendToken, _collateralToken);
        
        emit PoolCreated(_lendToken, _collateralToken, pool);
        return pool;
    }

    function countPools() external view returns(uint) {
        return allPools.length;
    }
    
    function createBallot(
        address _creator, 
        address _pool, 
        bytes32 _name, 
        uint _value, 
        uint _reward, 
        string calldata _subject, 
        string calldata _content, 
        bytes calldata _bytecode) onlyGovernor external returns (address ballot) 
    {
        bytes32 salt = keccak256(abi.encodePacked(_creator, _value, _subject, block.number));
        bytes memory bytecode = _bytecode;
        require(keccak256(bytecode) == ballotByteCodeHash, "INVALID BYTECODE.");
        
        assembly {
            ballot := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        allBallots.push(ballot);
        IAAAABallot(ballot).setupConfig(config);
        IAAAABallot(ballot).initialize(_creator, _pool, _name, _value, _reward, _subject, _content);
        
        emit BallotCreated(_creator, _pool, ballot, _name, _value);
        return ballot;
    }
    
    function countBallots() external view returns (uint){
        return allBallots.length;
    }

    function changeBallotByteHash(bytes32 _hash) onlyDeveloper external {
        ballotByteCodeHash = _hash;
    }
}