/**
 *Submitted for verification at FtmScan.com on 2021-12-21
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

interface IOwnable {
    function owner() external view returns (address);

    function renounceOwnership() external;

    function transferOwnership(address newOwner_) external;
}

contract Ownable is IOwnable {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view override returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual override onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner_) public virtual override onlyOwner {
        require(newOwner_ != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner_);
        _owner = newOwner_;
    }
}

interface IERC20 {
    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function totalSupply() external view returns (uint256);

    function burn(uint256 amount) external;

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface ITreasury {
    function deposit(
        uint256 _amount,
        address _token,
        uint256 _profit
    ) external returns (bool);

    function valueOf(address _token, uint256 _amount) external view returns (uint256 value_);
}

interface ISpookyRouter {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );
}

interface IStaking {
    function stake(uint256 _amount, address _recipient) external returns (bool);
}

// mint 15k HUSKY
// 10k for rocket pool
// 5k for liquidity
contract RocketPool is Ownable {
    using SafeMath for uint256;

    uint256 private constant TOTAL_RAISE = 40000e18; // limit 40k DAI
    uint256 private constant PER_ADDR = 1000e18; // 1k DAI
    uint256 private constant RATE = 4; // HUSKY = $4

    IERC20 public DAI;
    address public husky;
    address public staking;
    uint256 public totalDAI;
    uint256 public openTime;

    address[] public addresses;
    mapping(address => uint256) public amountDAI;

    event Deposit(address indexed depositor, uint256 indexed amount);
    event Redeem(address indexed depositor, uint256 indexed amount);

    constructor(IERC20 _dai) {
        DAI = _dai;
    }

    function deposit(uint256 _amount) external {
        require(block.timestamp > 1640196000, "not open"); // Wed Dec 22 2021 18:00:00 GMT+0000
        require(totalDAI.add(_amount) <= TOTAL_RAISE, "limit total");
        require(amountDAI[msg.sender].add(_amount) <= PER_ADDR, "limit per addr");

        totalDAI = totalDAI.add(_amount);
        amountDAI[msg.sender] = amountDAI[msg.sender].add(_amount);

        DAI.transferFrom(msg.sender, address(this), _amount);

        if (!listContains(addresses, msg.sender)) {
            addresses.push(msg.sender);
        }

        emit Deposit(msg.sender, _amount);
    }

    function setup(
        address _husky,
        address _staking,
        address _treasury,
        address _huskyDAI,
        ISpookyRouter _router
    ) external onlyOwner {
        husky = _husky;
        staking = _staking;

        uint256 huskyStaking = totalDAI.div(1e9).div(RATE);
        uint256 huskyLiquidity = huskyStaking.div(2);
        uint256 huskyTotal = huskyStaking.add(huskyLiquidity);
        require(IERC20(husky).balanceOf(address(this)) >= huskyTotal, "diff HUSKY amount");

        DAI.approve(address(_router), 0);
        DAI.approve(address(_router), totalDAI);
        IERC20(husky).approve(address(_router), 0);
        IERC20(husky).approve(address(_router), huskyLiquidity);
        _router.addLiquidity(husky, address(DAI), huskyLiquidity, totalDAI, 0, 0, address(this), block.timestamp);

        IERC20(_huskyDAI).approve(_treasury, 0);
        IERC20(_huskyDAI).approve(_treasury, IERC20(_huskyDAI).balanceOf(address(this)));
        uint256 profit = ITreasury(_treasury).valueOf(_huskyDAI, IERC20(_huskyDAI).balanceOf(address(this)));
        ITreasury(_treasury).deposit(IERC20(_huskyDAI).balanceOf(address(this)), _huskyDAI, profit);

        uint256 huskyBalance = IERC20(husky).balanceOf(address(this));
        uint256 burnHuskyAmount = huskyBalance.sub(huskyStaking);
        IERC20(husky).burn(burnHuskyAmount);

        for (uint256 i = 0; i < addresses.length; i++) {
            uint256 shareAmount = amountDAI[addresses[i]].mul(huskyStaking).div(totalDAI);

            uint256 stakeAmount;
            if (IERC20(husky).balanceOf(address(this)) < shareAmount) {
                stakeAmount = IERC20(husky).balanceOf(address(this));
            } else {
                stakeAmount = shareAmount;
            }

            IERC20(husky).approve(staking, 0);
            IERC20(husky).approve(staking, stakeAmount);
            IStaking(staking).stake(stakeAmount, addresses[i]);
        }
    }

    function listContains(address[] storage _list, address _token) internal view returns (bool) {
        for (uint256 i = 0; i < _list.length; i++) {
            if (_list[i] == _token) {
                return true;
            }
        }
        return false;
    }
}