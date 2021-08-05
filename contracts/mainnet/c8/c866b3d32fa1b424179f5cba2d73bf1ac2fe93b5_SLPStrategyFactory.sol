/**
 *Submitted for verification at Etherscan.io on 2020-11-27
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

// Dependency file: contracts/modules/BaseShareField.sol

// pragma solidity >=0.6.6;
// import 'contracts/libraries/SafeMath.sol';
// import 'contracts/libraries/TransferHelper.sol';

interface IERC20 {
    function approve(address spender, uint value) external returns (bool);
    function balanceOf(address owner) external view returns (uint);
}

contract BaseShareField {
    using SafeMath for uint;
    
    uint public totalProductivity;
    uint public accAmountPerShare;
    
    uint public totalShare;
    uint public mintedShare;
    uint public mintCumulation;
    
    uint private unlocked = 1;
    address public shareToken;
    
    modifier lock() {
        require(unlocked == 1, 'Locked');
        unlocked = 0;
        _;
        unlocked = 1;
    }
    
    struct UserInfo {
        uint amount;     // How many tokens the user has provided.
        uint rewardDebt; // Reward debt. 
        uint rewardEarn; // Reward earn and not minted
        bool initialize; // already setup.
    }

    mapping(address => UserInfo) public users;
    
    function _setShareToken(address _shareToken) internal {
        shareToken = _shareToken;
    }

    // Update reward variables of the given pool to be up-to-date.
    function _update() internal virtual {
        if (totalProductivity == 0) {
            totalShare = totalShare.add(_currentReward());
            return;
        }
        
        uint256 reward = _currentReward();
        accAmountPerShare = accAmountPerShare.add(reward.mul(1e12).div(totalProductivity));
        totalShare += reward;
    }
    
    function _currentReward() internal virtual view returns (uint) {
        return mintedShare.add(IERC20(shareToken).balanceOf(address(this))).sub(totalShare);
    }
    
    // Audit user's reward to be up-to-date
    function _audit(address user) internal virtual {
        UserInfo storage userInfo = users[user];
        if (userInfo.amount > 0) {
            uint pending = userInfo.amount.mul(accAmountPerShare).div(1e12).sub(userInfo.rewardDebt);
            userInfo.rewardEarn = userInfo.rewardEarn.add(pending);
            mintCumulation = mintCumulation.add(pending);
            userInfo.rewardDebt = userInfo.amount.mul(accAmountPerShare).div(1e12);
        }
    }

    // External function call
    // This function increase user's productivity and updates the global productivity.
    // the users' actual share percentage will calculated by:
    // Formula:     user_productivity / global_productivity
    function _increaseProductivity(address user, uint value) internal virtual returns (bool) {
        require(value > 0, 'PRODUCTIVITY_VALUE_MUST_BE_GREATER_THAN_ZERO');

        UserInfo storage userInfo = users[user];
        _update();
        _audit(user);

        totalProductivity = totalProductivity.add(value);

        userInfo.amount = userInfo.amount.add(value);
        userInfo.rewardDebt = userInfo.amount.mul(accAmountPerShare).div(1e12);
        return true;
    }

    // External function call 
    // This function will decreases user's productivity by value, and updates the global productivity
    // it will record which block this is happenning and accumulates the area of (productivity * time)
    function _decreaseProductivity(address user, uint value) internal virtual returns (bool) {
        UserInfo storage userInfo = users[user];
        require(value > 0 && userInfo.amount >= value, 'INSUFFICIENT_PRODUCTIVITY');
        
        _update();
        _audit(user);
        
        userInfo.amount = userInfo.amount.sub(value);
        userInfo.rewardDebt = userInfo.amount.mul(accAmountPerShare).div(1e12);
        totalProductivity = totalProductivity.sub(value);
        
        return true;
    }

    function _transferTo(address user, address to, uint value) internal virtual returns (bool) {
        UserInfo storage userInfo = users[user];
        require(value > 0 && userInfo.amount >= value, 'INSUFFICIENT_PRODUCTIVITY');
        
        _update();
        _audit(user);

        uint transferAmount = value.mul(userInfo.rewardEarn).div(userInfo.amount);
        userInfo.rewardEarn = userInfo.rewardEarn.sub(transferAmount);
        users[to].rewardEarn = users[to].rewardEarn.add(transferAmount);
        
        userInfo.amount = userInfo.amount.sub(value);
        userInfo.rewardDebt = userInfo.amount.mul(accAmountPerShare).div(1e12);
        totalProductivity = totalProductivity.sub(value);
        
        return true;
    }
    
    function _takeWithAddress(address user) internal view returns (uint) {
        UserInfo storage userInfo = users[user];
        uint _accAmountPerShare = accAmountPerShare;
        if (totalProductivity != 0) {
            uint reward = _currentReward();
            _accAmountPerShare = _accAmountPerShare.add(reward.mul(1e12).div(totalProductivity));
        }
        return userInfo.amount.mul(_accAmountPerShare).div(1e12).add(userInfo.rewardEarn).sub(userInfo.rewardDebt);
    }

    // External function call
    // When user calls this function, it will calculate how many token will mint to user from his productivity * time
    // Also it calculates global token supply from last time the user mint to this time.
    function _mint(address user) internal virtual lock returns (uint) {
        _update();
        _audit(user);
        require(users[user].rewardEarn > 0, "NOTHING TO MINT SHARE");
        uint amount = users[user].rewardEarn;
        TransferHelper.safeTransfer(shareToken, user, amount);
        users[user].rewardEarn = 0;
        mintedShare += amount;
        return amount;
    }

    function _mintTo(address user, address to) internal virtual lock returns (uint) {
        _update();
        _audit(user);
        uint amount = users[user].rewardEarn;
        if(amount > 0) {
            TransferHelper.safeTransfer(shareToken, to, amount);
        }
        
        users[user].rewardEarn = 0;
        mintedShare += amount;
        return amount;
    }

    // Returns how many productivity a user has and global has.
    function getProductivity(address user) public virtual view returns (uint, uint) {
        return (users[user].amount, totalProductivity);
    }

    // Returns the current gorss product rate.
    function interestsPerBlock() public virtual view returns (uint) {
        return accAmountPerShare;
    }
    
}

// Dependency file: contracts/SLPStrategy.sol

// pragma solidity >=0.5.16;
// import "contracts/libraries/TransferHelper.sol";
// import "contracts/libraries/SafeMath.sol";
// import "contracts/modules/BaseShareField.sol";

interface ICollateralStrategy {
    function invest(address user, uint amount) external; 
    function withdraw(address user, uint amount) external;
    function liquidation(address user) external;
    function claim(address user, uint amount, uint total) external;
    function exit(uint amount) external;
    function migrate(address old) external;
    function query() external view returns (uint);
    function mint() external;

    function interestToken() external returns (address);
    function collateralToken() external returns (address);
}

interface IMasterChef {
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function pendingSushi(uint256 _pid, address _user) external view returns (uint256);
    function poolInfo(uint _index) external view returns(address, uint, uint, uint);
}

contract SLPStrategy is ICollateralStrategy, BaseShareField
{
    event Mint(address indexed user, uint amount);
    using SafeMath for uint;

    address override public interestToken;
    address override public collateralToken;

    address public poolAddress;
    address public masterChef;
    address public old;
    uint public lpPoolpid;

    address public factory;

    constructor() public {
        factory = msg.sender;
    }

    function initialize(address _interestToken, address _collateralToken, address _poolAddress, address _sushiMasterChef, uint _lpPoolpid) public
    {
        require(msg.sender == factory, 'STRATEGY FORBIDDEN');
        interestToken = _interestToken;
        collateralToken = _collateralToken;
        poolAddress = _poolAddress;
        masterChef = _sushiMasterChef;
        lpPoolpid = _lpPoolpid;
        _setShareToken(_interestToken);
    }

    function migrate(address _old) external override 
    {
        require(msg.sender == poolAddress, "INVALID CALLER");
        if(_old != address(0)) {
            uint amount = IERC20(collateralToken).balanceOf(address(this));
            if(amount > 0) {
                IERC20(collateralToken).approve(masterChef, amount);
                IMasterChef(masterChef).deposit(lpPoolpid, amount);
            }

            totalProductivity = BaseShareField(_old).totalProductivity();
            old = _old;
        }
    }

    function invest(address user, uint amount) external override
    {
        _sync(user);

        require(msg.sender == poolAddress, "INVALID CALLER");
        TransferHelper.safeTransferFrom(collateralToken, msg.sender, address(this), amount);
        IERC20(collateralToken).approve(masterChef, amount);
        IMasterChef(masterChef).deposit(lpPoolpid, amount);
        _increaseProductivity(user, amount);
    }

    function withdraw(address user, uint amount) external override
    {
        _sync(user);

        require(msg.sender == poolAddress, "INVALID CALLER");
        IMasterChef(masterChef).withdraw(lpPoolpid, amount);
        TransferHelper.safeTransfer(collateralToken, msg.sender, amount);
        _decreaseProductivity(user, amount);
    }

    function liquidation(address user) external override {
        _sync(user);
        _sync(msg.sender);

        require(msg.sender == poolAddress, "INVALID CALLER");
        uint amount = users[user].amount;
        _decreaseProductivity(user, amount);

        uint reward = users[user].rewardEarn;
        users[msg.sender].rewardEarn = users[msg.sender].rewardEarn.add(reward);
        users[user].rewardEarn = 0;
        _increaseProductivity(msg.sender, amount);
    }

    function claim(address user, uint amount, uint total) external override {
        _sync(msg.sender);

        require(msg.sender == poolAddress, "INVALID CALLER");
        IMasterChef(masterChef).withdraw(lpPoolpid, amount);
        TransferHelper.safeTransfer(collateralToken, msg.sender, amount);
        _decreaseProductivity(msg.sender, amount);
    
        uint claimAmount = users[msg.sender].rewardEarn.mul(amount).div(total);
        users[user].rewardEarn = users[user].rewardEarn.add(claimAmount);
        users[msg.sender].rewardEarn = users[msg.sender].rewardEarn.sub(claimAmount);
    }

    function exit(uint amount) external override {
        require(msg.sender == poolAddress, "INVALID CALLER");
        IMasterChef(masterChef).withdraw(lpPoolpid, amount);
        TransferHelper.safeTransfer(collateralToken, msg.sender, amount);
    }

    function _sync(address user) internal 
    {
        if(old != address(0) && users[user].initialize == false) {
            (uint amount, ) = BaseShareField(old).getProductivity(user);
            users[user].amount = amount;
            users[user].initialize = true;
        } 
    }

    function _currentReward() internal override view returns (uint) {
        return mintedShare.add(IERC20(shareToken).balanceOf(address(this))).add(IMasterChef(masterChef).pendingSushi(lpPoolpid, address(this))).sub(totalShare);
    }

    function query() external override view returns (uint){
        return _takeWithAddress(msg.sender);
    }

    function mint() external override {
        _sync(msg.sender);
        
        IMasterChef(masterChef).deposit(lpPoolpid, 0);
        uint amount = _mint(msg.sender);
        emit Mint(msg.sender, amount);
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

// Root file: contracts/SLPStrategyFactory.sol

pragma solidity >=0.5.16;

// import 'contracts/SLPStrategy.sol';
// import 'contracts/modules/Configable.sol';

interface ISLPStrategy {
    function initialize(address _interestToken, address _collateralToken, address _poolAddress, address _sushiMasterChef, uint _lpPoolpid) external;
}

interface ISushiMasterChef {
    function sushi() external view returns(address);
}

interface IAAAAPool {
    function collateralToken() external view returns(address);
}

contract SLPStrategyFactory is Configable {
    address public masterchef;
    address[] public strategies;

    event StrategyCreated(address indexed _strategy, address indexed _collateralToken, address indexed _poolAddress, uint _lpPoolpid);

    constructor() public {
        owner = msg.sender;
    }

    function initialize(address _masterchef) onlyOwner public {
        masterchef = _masterchef;
    }

    function createStrategy(address _collateralToken, address _poolAddress, uint _lpPoolpid) onlyDeveloper external returns (address _strategy) {
        require(IAAAAPool(_poolAddress).collateralToken() == _collateralToken, 'Not found collateralToken in Pool');
        (address cToken, , ,) = IMasterChef(masterchef).poolInfo(_lpPoolpid);
        require(cToken == _collateralToken, 'Not found collateralToken in Masterchef');
        
        bytes memory bytecode = type(SLPStrategy).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(_collateralToken, _poolAddress, _lpPoolpid, block.number));
        assembly {
            _strategy := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        address _interestToken = ISushiMasterChef(masterchef).sushi();
        ISLPStrategy(_strategy).initialize(_interestToken, _collateralToken, _poolAddress, masterchef, _lpPoolpid);
        emit StrategyCreated(_strategy, _collateralToken, _poolAddress, _lpPoolpid);
        strategies.push(_strategy);
        return _strategy;
    }

    function countStrategy() external view returns(uint) {
        return strategies.length;
    }

}