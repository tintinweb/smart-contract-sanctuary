//SourceUnit: UsdtLinkJustlend.sol

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
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
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

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

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

    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals
    ) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @return the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @return the symbol of the token.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @return the number of decimals of the token.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

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
    ) internal {
        require(token.transfer(to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        require(token.transferFrom(from, to, value));
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
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
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(
            value
        );
        require(token.approve(spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value
        );
        require(token.approve(spender, newAllowance));
    }
}

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
        require(
            initializing || isConstructor() || !initialized,
            "Contract instance has already been initialized"
        );

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
        assembly {
            cs := extcodesize(address)
        }
        return cs == 0;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}

contract LPTokenWrapper is Initializable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20Detailed;

    ERC20Detailed internal y;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    function initialize(address _y) internal initializer {
        y = ERC20Detailed(_y); //
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function stake(
        uint256 amount,
        uint256 feeAmount,
        address _freMinePool
    ) internal {
        _totalSupply = _totalSupply.add(amount.sub(feeAmount));
        _balances[msg.sender] = _balances[msg.sender].add(
            amount.sub(feeAmount)
        );
        y.safeTransferFrom(msg.sender, address(_freMinePool), amount);
    }

    function withdraw(uint256 amount) internal {
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
    }
}

// justlend interface
interface JustlendPool {
    function mint(uint256 mintAmount) external;

    function redeem(uint256 redeemTokens) external;

    function balanceOf(address own_address) external view returns (uint256);
}

contract UsdtMinePool {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address _owner;

    JustlendPool public justlendPool =
        JustlendPool(0x41ea09611b57e89d67fbb33a516eb90508ca95a3e5);

    constructor() public {
        _owner = msg.sender;
    }

    function approve(
        IERC20 token,
        address to,
        uint256 value
    ) external {
        require(msg.sender == _owner);
        token.approve(to, value);
    }

    function transfer(
        IERC20 token,
        address to,
        uint256 value
    ) public {
        require(msg.sender == _owner);
        token.transfer(to, value);
    }

    function mint(uint256 mintAmount) public {
        justlendPool.mint(mintAmount);
    }

    function redeem(uint256 redeemTokens) public {
        justlendPool.redeem(redeemTokens);
    }

    function balanceOf(address own_address) public view returns (uint256) {
        return justlendPool.balanceOf(own_address);
    }
}

contract UsdtLinkJustlend is LPTokenWrapper {
    using SafeERC20 for IERC20;

    address private jUSDT =
        address(0x41ea09611b57e89d67fbb33a516eb90508ca95a3e5);
    address private usdtToken =
        address(0x41a614f803b6fd780986a42c78ec9c7f77e6ded13c);
    IERC20 private token;

    uint256 private initreward;

    bool private flag = false;
    uint256 private totalRewards = 0;
    uint256 private precision = 1e6;

    uint256 private starttime;
    uint256 private stoptime;
    uint256 private rewardRate = 0;
    uint256 private lastUpdateTime;
    uint256 private rewardPerTokenStored;

    address public deployer;

    mapping(address => uint256) private userRewardPerTokenPaid;
    mapping(address => uint256) private rewards;

    mapping(address => address) public userFreMinePool;

    event StartPool(uint256 initreward, uint256 starttime, uint256 stoptime);
    event Staked(address indexed user, uint256 amount, uint256 feeAmount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    function setDeployer(address _deployer) public {
        require(msg.sender == deployer, "sender must deployer");

        deployer = _deployer;
    }

    constructor(address _token, uint256 _initreward) public {
        deployer = msg.sender;

        super.initialize(usdtToken);
        token = IERC20(_token);
        starttime = block.timestamp;
        stoptime = starttime + 3 * 365 days;
        initreward = _initreward * (precision);
        rewardRate = initreward.div(stoptime.sub(starttime));
        emit StartPool(initreward, starttime, stoptime);
    }

    function setPool(
        uint256 _initreward,
        uint256 _starttime,
        uint256 _stoptime
    ) public {
        require(msg.sender == deployer, "sender must deployer");

        starttime = _starttime;
        stoptime = _stoptime;
        initreward = _initreward * (precision);
        rewardRate = initreward.div(stoptime.sub(starttime));
        emit StartPool(initreward, starttime, stoptime);
    }

    function stake(uint256 amount) public updateReward(msg.sender) checkStop {
        require(amount > 0, "The number must be greater than 0");

        if (userFreMinePool[msg.sender] == address(0)) {
            UsdtMinePool _freMinePool = new UsdtMinePool();
            userFreMinePool[msg.sender] = address(_freMinePool);
        }

        super.stake(amount, 0, userFreMinePool[msg.sender]);

        uint256 allowances = IERC20(usdtToken).allowance(
            userFreMinePool[msg.sender],
            address(jUSDT)
        );
        if (allowances <= 0) {
            UsdtMinePool(userFreMinePool[msg.sender]).approve(
                IERC20(usdtToken),
                address(jUSDT),
                115792089237316195423570985008687907853269984665640564039457584007913129639935
            );
        }
        UsdtMinePool(userFreMinePool[msg.sender]).mint(amount);

        emit Staked(msg.sender, amount, 0);
    }

    function getReward() public updateReward(msg.sender) checkStart {
        require(userFreMinePool[msg.sender] != address(0));

        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            rewards[msg.sender] = 0;

            token.safeTransfer(msg.sender, reward);

            emit RewardPaid(msg.sender, reward);
            totalRewards = totalRewards.add(reward);
        }
    }

    function exit() public updateReward(msg.sender) {
        uint256 amount = balanceOf(msg.sender);
        require(amount > 0, "Cannot withdraw 0");

        if (userFreMinePool[msg.sender] != address(0)) {
            uint256 jUSDTBalance = UsdtMinePool(userFreMinePool[msg.sender])
                .balanceOf(userFreMinePool[msg.sender]);
            if (jUSDTBalance > 0) {
                UsdtMinePool(userFreMinePool[msg.sender]).redeem(jUSDTBalance);

                uint256 usdtBalance = IERC20(usdtToken).balanceOf(
                    userFreMinePool[msg.sender]
                );
                uint256 fee = (usdtBalance.sub(amount)).div(2);
                UsdtMinePool(userFreMinePool[msg.sender]).transfer(
                    IERC20(usdtToken),
                    msg.sender,
                    usdtBalance.sub(fee)
                );
                UsdtMinePool(userFreMinePool[msg.sender]).transfer(
                    IERC20(usdtToken),
                    deployer,
                    fee
                );
            }
        }

        super.withdraw(amount);
        emit Withdrawn(msg.sender, amount);
        if (block.timestamp > starttime) {
            getReward();
        }
        emit Withdrawn(msg.sender, balanceOf(msg.sender));
    }

    function earned(address account) public view returns (uint256) {
        if (block.timestamp < starttime) {
            return 0;
        }
        return
            balanceOf(account)
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                .div(precision)
                .add(rewards[account]);
    }

    function lastTimeRewardApplicable() internal view returns (uint256) {
        return SafeMath.min(block.timestamp, stoptime);
    }

    function rewardPerToken() internal view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        uint256 lastTime = 0;
        if (flag) {
            lastTime = lastUpdateTime;
        } else {
            lastTime = starttime;
        }

        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastTime)
                    .mul(rewardRate)
                    .mul(precision)
                    .div(totalSupply())
            );
    }

    modifier checkStart() {
        require(block.timestamp > starttime, "not start");
        _;
    }

    modifier checkStop() {
        require(block.timestamp < stoptime, "already stop");
        _;
    }

    modifier updateReward(address account) {
        if (block.timestamp > starttime) {
            rewardPerTokenStored = rewardPerToken();
            flag = true;

            lastUpdateTime = lastTimeRewardApplicable();
            if (account != address(0)) {
                rewards[account] = earned(account);

                userRewardPerTokenPaid[account] = rewardPerTokenStored;
            }
        }
        _;
    }

    function getPoolInfo()
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 left = initreward.sub(totalRewards);
        if (left < 0) {
            left = 0;
        }
        return (starttime, stoptime, totalSupply(), left);
    }

    function clearPot() public {
        if (msg.sender == deployer) {
            token.safeTransfer(msg.sender, token.balanceOf(address(this)));
        }
    }
}