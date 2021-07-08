/**
 *Submitted for verification at BscScan.com on 2021-07-08
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash =
            0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }
}

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
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
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

    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface IController {
    function withdraw(address, uint256) external;
    function balanceOf(address) external view returns (uint256);
    function earn(address, uint256) external;
    function want(address) external view returns (address);
    function rewards() external view returns (address);
    function vaults(address) external view returns (address);
    function strategies(address) external view returns (address);
}

struct UserInfo {
    uint256 amount;     
    uint256 rewardDebt; 
}

struct PoolInfo {
    address want;           // Address of LP token contract.
    uint256 allocPoint;       // How many allocation points assigned to this pool. CAKEs to distribute per block.
    uint256 lastRewardBlock;  // Last block number that CAKEs distribution occurs.
    uint256 accCakePerShare; // Accumulated CAKEs per share, times 1e12. See below.
}

interface IPool {
    function emergencyWithdraw(uint256 _pid) external;
    function userInfo(uint pid, address user) external view returns (UserInfo memory);
    function poolInfo(uint pid) external view returns (PoolInfo memory);
    function enterStaking(uint256 _amount) external;
    function leaveStaking(uint256 _amount) external;
}

contract StrategyCake {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    uint256 public strategistReward = 0;
    uint256 public withdrawalFee = 0;
    uint256 public constant FEE_DENOMINATOR = 10000;

    address public constant masterChef = 0x73feaa1eE314F8c655E354234017bE2193C9E24E;
    IPool public pool = IPool(masterChef);
    uint public poolId = 0;

    address public want = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;  // Cake

    address public governance;
    address public controller;
    address public strategist;

    constructor(
        address _controller
    ) {
        governance = msg.sender;
        strategist = msg.sender;
        controller = _controller;

        require(pool.poolInfo(poolId).want == want);

        IERC20(want).safeApprove(address(pool), 0);
        IERC20(want).safeApprove(address(pool), uint(-1));
    }

    function setStrategist(address _strategist) external {
        require(msg.sender == governance || msg.sender == strategist, "!authorized");
        strategist = _strategist;
    }

    function setWithdrawalFee(uint256 _withdrawalFee) external {
        require(msg.sender == governance, "!governance");
        withdrawalFee = _withdrawalFee;
    }

    function setStrategistReward(uint256 _strategistReward) external {
        require(msg.sender == governance, "!governance");
        strategistReward = _strategistReward;
    }

    function e_exit() external {
        require(msg.sender == governance, "!governance");
        pool.emergencyWithdraw(poolId);
        uint balance = IERC20(want).balanceOf(address(this));
        address _vault = IController(controller).vaults(address(want));
        require(_vault != address(0), "!vault"); 
        IERC20(want).safeTransfer(_vault, balance);
    }

    function deposit() public {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IPool(pool).enterStaking(_want);
        }
    }

    function withdraw(IERC20 _asset) external returns (uint256 balance) {
        require(msg.sender == controller, "!controller");
        require(want != address(_asset), "want");
        balance = _asset.balanceOf(address(this));
        _asset.safeTransfer(controller, balance);
    }

    function withdraw(uint256 _amount) external {
        require(msg.sender == controller, "!controller");
        uint256 _balance = IERC20(want).balanceOf(address(this));
        if (_balance < _amount) {
            _amount = _withdrawSome(_amount.sub(_balance));
            _amount = _amount.add(_balance);
        }

        uint256 _fee = _amount.mul(withdrawalFee).div(FEE_DENOMINATOR);

        if (_fee > 0) {
            IERC20(want).safeTransfer(IController(controller).rewards(), _fee);
        }
        address _vault = IController(controller).vaults(address(want));
        require(_vault != address(0), "!vault"); 
        if (_amount > _fee) {
            IERC20(want).safeTransfer(_vault, _amount.sub(_fee));
        }
    }

    function _withdrawSome(uint256 _amount) internal returns (uint256) {
        uint256 before = IERC20(want).balanceOf(address(this));
        if (_amount > 0) {
            pool.leaveStaking(_amount);
        }
        return IERC20(want).balanceOf(address(this)).sub(before);
    }

    function withdrawAll() external returns (uint256 balance) {
        require(msg.sender == controller, "!controller");
        _withdrawAll();

        balance = IERC20(want).balanceOf(address(this));

        address _vault = IController(controller).vaults(address(want));
        require(_vault != address(0), "!vault"); 
        if (balance > 0) {
            IERC20(want).safeTransfer(_vault, balance);
        }
    }

    function _withdrawAll() internal {
        _withdrawSome(balanceOfPool());
    }

    modifier onlyBenevolent {
        require(msg.sender == tx.origin || msg.sender == governance || msg.sender == strategist);
        _;
    }

    function harvest() public onlyBenevolent {
        IPool(pool).leaveStaking(0);
        deposit();
    }

    function balanceOfWant() public view returns (uint256) {
        return IERC20(want).balanceOf(address(this));
    }

    function balanceOfPool() public view returns (uint256) {
        UserInfo memory info = pool.userInfo(poolId, address(this));
        return info.amount;
    }

    function balanceOf() public view returns (uint256) {
        return balanceOfWant().add(balanceOfPool());
    }

    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function setController(address _controller) external {
        require(msg.sender == governance, "!governance");
        controller = _controller;
    }
}