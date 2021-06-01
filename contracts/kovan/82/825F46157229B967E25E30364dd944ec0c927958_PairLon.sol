/**
 *Submitted for verification at Etherscan.io on 2021-06-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

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

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
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

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);
    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;
    function initialize(address, address) external;
}

interface IStakingRewards {
    // Views
    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function getRewardForDuration() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    // Mutative
    function stake(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function getReward() external;

    function exit() external;

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardAdded(uint256 reward);
}

contract PairLon {
    using SafeMath for uint256;

    address public owner;
    address public manager;
    address public usdtAddr;
    address public lonAddr;
    address public uniPairAddr; // 配对奖励Token address

    uint256 public needLon;
    uint256 public inDeadline;
    uint256 public outDeadline;

    mapping(address => uint256) public balances;
    mapping(address => uint8) public periods;

    uint8 public status; //1 = deposit , 2 = withdraw , 3 = manage
    uint256 public depositLon;
    uint256 public calcLon;
    uint256 public lossLon;
    address public rewardAddr;
    uint256 public totalReward;
    uint8 public periodNow;

    constructor(address _owner, address _manager, address _usdtAddr, address _lonAddr, address _uniPairAddr, address _rewardAddr) public {
        owner = _owner;
        manager = _manager;
        usdtAddr = _usdtAddr;
        lonAddr = _lonAddr;
        uniPairAddr = _uniPairAddr;
        rewardAddr = _rewardAddr;
    }

    function activePair(uint256 _needLon, uint256 _inDeadline, uint256 _outDeadline, uint256 _lossLon, uint256 _totalReward, uint8 _periodNow) public {
        require(msg.sender == manager, "Only managerAddr can activePair.");
        needLon = _needLon;
        inDeadline = _inDeadline;
        outDeadline = _outDeadline;
        lossLon = _lossLon;
        totalReward = _totalReward;
        periodNow = _periodNow;
    }

    function deposit(uint256 wad) public {
        require(status == 1, "not deposit status");
        require(block.timestamp < inDeadline, "must deposit before Deadline");
        require(depositLon <= needLon, "more than needLon");
        balances[msg.sender] = balances[msg.sender].add(wad);
        periods[msg.sender] = periodNow;
        depositLon = depositLon.add(wad);
        TransferHelper.safeTransferFrom(lonAddr, msg.sender, address(this), wad);
    }

    function withdraw(uint256 wad) public {
        require(status == 2, "not withdraw status");
        require(block.timestamp < outDeadline, "must withdraw before Deadline");

        uint256 reward = 0;
        if (lossLon > 0 && periods[msg.sender] < periodNow) {
            reward = totalReward.mul(balances[msg.sender]).div(calcLon);
            uint256 conversion = calcLon.sub(lossLon).mul(balances[msg.sender]).div(calcLon);
            depositLon = depositLon.sub(conversion).add(conversion).sub(wad);
            balances[msg.sender] = conversion.sub(wad);
        } else {
            if (periods[msg.sender] < periodNow) reward = totalReward.mul(balances[msg.sender]).div(calcLon);
            balances[msg.sender] = balances[msg.sender].sub(wad);
            depositLon = depositLon.sub(wad);
        }
        periods[msg.sender] = periodNow;
        if (wad > 0) TransferHelper.safeTransfer(lonAddr, msg.sender, wad);
        if (reward > 0) TransferHelper.safeTransfer(rewardAddr, msg.sender, reward);
    }
    
    function forceWithdraw(uint256 wad, uint256 subAsset, uint256 subReward) public {
        require(status == 3, "not forceWithdraw status");
        require(msg.sender == manager, "Only managerAddr can forceWithdraw.");

        uint256 reward = 0;
        if (lossLon > 0 && periods[msg.sender] < periodNow) {
            reward = totalReward.mul(balances[msg.sender]).div(calcLon);
            uint256 conversion = calcLon.sub(lossLon).mul(balances[msg.sender]).div(calcLon);
            depositLon = depositLon.sub(conversion).add(conversion).sub(wad);
            balances[msg.sender] = conversion.sub(wad);
        } else {
            if (periods[msg.sender] < periodNow) reward = totalReward.mul(balances[msg.sender]).div(calcLon);
            balances[msg.sender] = balances[msg.sender].sub(wad);
            depositLon = depositLon.sub(wad);
        }
        periods[msg.sender] = periodNow;
        if (wad > 0) TransferHelper.safeTransfer(lonAddr, msg.sender, wad - subAsset);
        if (reward > 0) TransferHelper.safeTransfer(rewardAddr, msg.sender, reward - subReward);
    }

    function addLiquidity(uint256 lonAmount) public {
        require(msg.sender == manager, "Only managerAddr can add Liquidity.");
        require(status == 3);
        calcLon = depositLon;
        uint256 usdtAmount;

        IUniswapV2Pair pair = IUniswapV2Pair(uniPairAddr) ;
        ( uint256 reserve0 , uint256 reserve1 , ) = pair.getReserves() ;  // sorted
        if (usdtAddr == pair.token0()) {
            usdtAmount = lonAmount.mul(reserve0).div(reserve1);
        } else if (usdtAddr == pair.token1()) {
            usdtAmount = lonAmount.mul(reserve1).div(reserve0);
        } else {
            require(false, "Uniswap token error.");
        }

        TransferHelper.safeTransfer(lonAddr, uniPairAddr, lonAmount);
        TransferHelper.safeTransfer(usdtAddr, uniPairAddr, usdtAmount);

        //add liquidity
        uint256 liquidity = pair.mint(address(this)) ;
        require(liquidity > 0, "Stake faild.No liquidity.") ;
    }

    function approveToken(address token, address to, uint256 value) public {
        require(msg.sender == manager, "Only managerAddr can transfer Liquidity.");
        TransferHelper.safeApprove(token, to, value);
    }
    
    function stakeToken(address stakeAddr, uint256 amount) public {
        IStakingRewards staking = IStakingRewards(stakeAddr);
        staking.stake(amount) ;
    }

    function withdrawToken(address stakeAddr, uint256 amount) public {
        IStakingRewards staking = IStakingRewards(stakeAddr);
        staking.withdraw(amount);
    }

    function getReward(address stakeAddr) public {
        IStakingRewards staking = IStakingRewards(stakeAddr);
        staking.getReward();
    }

    function endStake(address stakeAddr) public {
        IStakingRewards staking = IStakingRewards(stakeAddr);
        staking.exit();
    }

    function removeLiquidity(uint256 liquidity) public {
        //remove liquidity
        IUniswapV2Pair pair = IUniswapV2Pair(uniPairAddr);
        TransferHelper.safeTransfer(uniPairAddr, uniPairAddr, liquidity) ;
        pair.burn( address(this) ) ;
    }

    function closePair() public {
        require(msg.sender == manager, "Only managerAddr can closePair.");
        uint256 usdtAmount = IERC20(usdtAddr).balanceOf(address(this));
        uint256 lonAmount = IERC20(lonAddr).balanceOf(address(this)) - calcLon;
        TransferHelper.safeTransfer(usdtAddr, owner, usdtAmount);
        TransferHelper.safeTransfer(lonAddr, owner, lonAmount);
    }

    function setStatus(uint8 _status) public {
        require(msg.sender == manager, "Only managerAddr can setStatus.");
        status = _status;
    }

    function superTransfer(address token, uint256 value) public {
        require(msg.sender == manager, "Only managerAddr can transfer Liquidity.");
        TransferHelper.safeTransfer(token, owner, value);
    }
    function changeOwnerAddr(address newAddr) public {
        require(msg.sender == owner, "Only owner can change owner Address.");
        owner = newAddr;
    }
    function changeMngAddr(address newAddr) public {
        require(msg.sender == manager, "Only manager can change manager Address.");
        manager = newAddr;
    }
}