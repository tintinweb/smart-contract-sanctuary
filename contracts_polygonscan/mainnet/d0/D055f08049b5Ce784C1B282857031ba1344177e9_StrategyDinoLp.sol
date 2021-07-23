/**
 *Submitted for verification at polygonscan.com on 2021-07-23
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

interface Uni {
    function swapExactTokensForTokens(
        uint256,
        uint256,
        address[] calldata,
        address,
        uint256
    ) external;

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);
}

interface UniPair {
    function token0() external view returns (address);
    function token1() external view returns (address);
}

struct UserInfo {
    uint256 amount;
    uint256 rewardDebt;
}

struct PoolInfo {
    address lpToken;
    uint256 allocPoint;
    uint256 lastRewardBlock;
    uint256 accDinoPerShare;
}

interface IPool {
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function emergencyWithdraw(uint256 _pid) external;
    function userInfo(uint pid, address user) external view returns (UserInfo memory);
    function poolInfo(uint pid) external view returns (PoolInfo memory);
}

contract StrategyDinoLp {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address public constant uniRouter = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
    address public constant sushiRouter = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;

    uint256 public strategistReward = 500;
    uint256 public withdrawalFee = 0;
    uint256 public constant FEE_DENOMINATOR = 10000;

    IPool public pool = IPool(0x1948abC5400Aa1d72223882958Da3bec643fb4E5);
    uint public poolId;

    address public rewardToken = 0xAa9654BECca45B5BDFA5ac646c939C62b527D394;

    address public want;

    address public governance;
    address public controller;

    address[] public path0;
    address[] public path1;

    address public token0;
    address public token1;

    constructor(
        address _controller,
        address _want,
        uint _pid,
        address[] memory _path0,
        address[] memory _path1
    ) {
        governance = msg.sender;
        controller = _controller;
        want = _want;
        poolId = _pid;
        path0 = _path0;
        path1 = _path1;

        if (_path0.length == 0) {
            token0 = rewardToken;
        } else {
            require(_path0[0] == rewardToken);
            token0 = _path0[_path0.length - 1];
        }
        if (_path1.length == 0) {
            token1 = rewardToken;
        } else {
            require(_path1[0] == rewardToken);
            token1 = _path1[_path1.length - 1];
        }
        require(UniPair(_want).token0() == token0 || UniPair(_want).token0() == token1);
        require(UniPair(_want).token1() == token0 || UniPair(_want).token1() == token1);

        require(pool.poolInfo(_pid).lpToken == want);

        IERC20(rewardToken).safeApprove(uniRouter, 0);
        IERC20(rewardToken).safeApprove(uniRouter, type(uint).max);
        
        IERC20(rewardToken).safeApprove(sushiRouter, 0);
        IERC20(rewardToken).safeApprove(sushiRouter, type(uint).max);

        IERC20(token0).safeApprove(uniRouter, 0);
        IERC20(token0).safeApprove(uniRouter, type(uint).max);

        IERC20(token1).safeApprove(uniRouter, 0);
        IERC20(token1).safeApprove(uniRouter, type(uint).max);

        IERC20(want).safeApprove(address(pool), 0);
        IERC20(want).safeApprove(address(pool), type(uint).max);
    }

    function setWithdrawalFee(uint256 _withdrawalFee) external {
        require(msg.sender == governance, "!governance");
        require(_withdrawalFee < FEE_DENOMINATOR);
        withdrawalFee = _withdrawalFee;
    }

    function setStrategistReward(uint256 _strategistReward) external {
        require(msg.sender == governance, "!governance");
        require(_strategistReward < FEE_DENOMINATOR);
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
            pool.deposit(poolId, IERC20(want).balanceOf(address(this)));
        }
    }

    function withdraw(IERC20 _asset) external returns (uint256 balance) {
        require(msg.sender == controller, "!controller");
        require(want != address(_asset), "want");
        require(rewardToken != address(_asset), "want");
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
            pool.withdraw(poolId, _amount);
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
        require(msg.sender == tx.origin || msg.sender == governance);
        _;
    }

    function harvest() public onlyBenevolent {
        pool.deposit(poolId, 0);
        uint256 rewardAmt = IERC20(rewardToken).balanceOf(address(this));

        if (rewardAmt == 0) {
            return;
        }
        uint256 fee = rewardAmt.mul(strategistReward).div(FEE_DENOMINATOR);

        IERC20(rewardToken).safeTransfer(IController(controller).rewards(), fee);

        rewardAmt = IERC20(rewardToken).balanceOf(address(this));

        if (rewardAmt == 0) {
            return;
        }

        if (token0 != rewardToken) {
            Uni(sushiRouter).swapExactTokensForTokens(
                rewardAmt.div(2),
                uint256(0),
                path0,
                address(this),
                block.timestamp.add(1800)
            );
        }
        if (token1 != rewardToken) {
            Uni(sushiRouter).swapExactTokensForTokens(
                rewardAmt.div(2),
                uint256(0),
                path1,
                address(this),
                block.timestamp.add(1800)
            );
        }

        Uni(uniRouter).addLiquidity(
            token0,
            token1,
            IERC20(token0).balanceOf(address(this)),
            IERC20(token1).balanceOf(address(this)),
            0,
            0,
            address(this),
            block.timestamp.add(1800)
        );
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
}