/**
 *Submitted for verification at BscScan.com on 2021-09-15
*/

/**
 *Submitted for verification at BscScan.com on 2021-09-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

interface IERC20 {

    /// @param _owner The address from which the balance will be retrieved
    /// @return balance the balance
    function balanceOf(address _owner) external view returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return success Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) external returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return success Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return success Whether the approval was successful or not
    function approve(address _spender, uint256 _value) external returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return remaining Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

interface IUniswapV2Router01 {
  function factory() external pure returns (address);
  function WETH() external pure returns (address);

  function addLiquidity(
      address tokenA,
      address tokenB,
      uint amountADesired,
      uint amountBDesired,
      uint amountAMin,
      uint amountBMin,
      address to,
      uint deadline
  ) external returns (uint amountA, uint amountB, uint liquidity);
  function addLiquidityETH(
      address token,
      uint amountTokenDesired,
      uint amountTokenMin,
      uint amountETHMin,
      address to,
      uint deadline
  ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
  function removeLiquidity(
      address tokenA,
      address tokenB,
      uint liquidity,
      uint amountAMin,
      uint amountBMin,
      address to,
      uint deadline
  ) external returns (uint amountA, uint amountB);
  function removeLiquidityETH(
      address token,
      uint liquidity,
      uint amountTokenMin,
      uint amountETHMin,
      address to,
      uint deadline
  ) external returns (uint amountToken, uint amountETH);
  function removeLiquidityWithPermit(
      address tokenA,
      address tokenB,
      uint liquidity,
      uint amountAMin,
      uint amountBMin,
      address to,
      uint deadline,
      bool approveMax, uint8 v, bytes32 r, bytes32 s
  ) external returns (uint amountA, uint amountB);
  function removeLiquidityETHWithPermit(
      address token,
      uint liquidity,
      uint amountTokenMin,
      uint amountETHMin,
      address to,
      uint deadline,
      bool approveMax, uint8 v, bytes32 r, bytes32 s
  ) external returns (uint amountToken, uint amountETH);
  function swapExactTokensForTokens(
      uint amountIn,
      uint amountOutMin,
      address[] calldata path,
      address to,
      uint deadline
  ) external returns (uint[] memory amounts);
  function swapTokensForExactTokens(
      uint amountOut,
      uint amountInMax,
      address[] calldata path,
      address to,
      uint deadline
  ) external returns (uint[] memory amounts);
  function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
      external
      payable
      returns (uint[] memory amounts);
  function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
      external
      returns (uint[] memory amounts);
  function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
      external
      returns (uint[] memory amounts);
  function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
      external
      payable
      returns (uint[] memory amounts);

  function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
  function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
  function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
  function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
  function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

contract PlayPool {
    address public dev;
    IERC20 public usdt = IERC20(0x89BB4ADB145849bd0f4A6Cf28cFdD6D8b46E46A5);
    IERC20 public dina = IERC20(0x9C89bc6e58b984F458324EE85b12115E85a7494f);
    IERC20 public play;
    IUniswapV2Router02 public uniswapV2Router = IUniswapV2Router02(0x16c9B17c9bD218766bF77C10edC0008A91576F35);
    IUniswapV2Pair public pair = IUniswapV2Pair(0x80D2e49FCaCf2a83cfC9202A82D64Cfa14Da916e);

    // pool info
    uint256 accRewardPerShare;
    uint256 public rewardPerBlock;
    uint256 lastRewardBlock;

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }
    mapping (address => UserInfo) public users;

    uint256 public total;
    uint256 public totalReward;

    struct Status {
        uint256 total;
        uint256 staked;
        uint256 pending;
        uint256 balanceOfDINA;
        uint256 balanceOfUSDT;
        uint256 currentBlock;
        uint112 pairReserve0;
        uint112 pairReserve1;
    }

    event Deposit(address indexed user, uint256 usdtAmount, uint256 dinaAmount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);

    modifier onlyDev {
        require(msg.sender == dev, "permission denied");
        _;
    }

    constructor(IERC20 _playToken, uint256 _rewardPerBlock) {
        dev = msg.sender;
        play = _playToken;
        rewardPerBlock = _rewardPerBlock;
        lastRewardBlock = block.number;
    }

    function buyAndStake(uint256 usdtAmount, uint256 minDinaAmount, uint256 deadline) public {
        require(usdtAmount > 0, "amount is zero");

        usdt.transferFrom(msg.sender, address(this), usdtAmount);
        usdt.approve(address(uniswapV2Router), usdtAmount);

        uint256 reverse = dina.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = address(usdt);
        path[1] = address(dina);

        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            usdtAmount,
            minDinaAmount,
            path,
            address(this),
            deadline
        );

        uint256 received = dina.balanceOf(address(this)) - reverse;

        UserInfo storage user = users[msg.sender];
        updatePool();
        if (user.amount > 0) {
            uint256 pending = user.amount * accRewardPerShare / 1e12 - user.rewardDebt;
            play.transfer(msg.sender, pending);
        }
        user.amount += received;
        user.rewardDebt = user.amount * accRewardPerShare / 1e12;
        total += received;

        emit Deposit(msg.sender, usdtAmount, received);
    }

    function updatePool() public {
        if (block.number <= lastRewardBlock) {
            return;
        }
        uint256 supply = dina.balanceOf(address(this));
        if (supply == 0) {
            lastRewardBlock = block.number;
            return;
        }
        uint256 reward = rewardPerBlock * (block.number - lastRewardBlock);
        totalReward += reward;
        accRewardPerShare += reward * 1e12 / supply;
        lastRewardBlock = block.number;
    }

    function harvest() public {
        UserInfo storage user = users[msg.sender];
        updatePool();
        uint256 pending = user.amount * accRewardPerShare / 1e12 - user.rewardDebt;
        if (pending > 0) {
            play.transfer(msg.sender, pending);
        }
        user.rewardDebt = user.amount * accRewardPerShare / 1e12;
    }

    function withdraw(uint256 amount) public {
        UserInfo storage user = users[msg.sender];
        require(user.amount >= amount, "withdraw: not good");
        updatePool();
        uint256 pending = user.amount * accRewardPerShare / 1e12 - user.rewardDebt;
        if (pending > 0) {
            play.transfer(msg.sender, pending);
        }
        user.amount -= amount;
        user.rewardDebt = user.amount * accRewardPerShare / 1e12;
        total -= amount;
        dina.transfer(msg.sender, amount);
        emit Withdraw(msg.sender, amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw() public {
        UserInfo storage user = users[msg.sender];
        dina.transfer(msg.sender, user.amount);
        emit EmergencyWithdraw(msg.sender, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
        if (total >= user.amount) {
            total -= user.amount;
        }
    }

    function pendingReward(address _user) public view returns (uint256) {
        UserInfo memory user = users[_user];
        uint256 supply = dina.balanceOf(address(this));
        uint256 acc = accRewardPerShare;
        if (block.number > lastRewardBlock && supply > 0) {
            uint256 reward = rewardPerBlock * (block.number - lastRewardBlock);
            acc += reward * 1e12 / supply;
        }

        return user.amount * acc / 1e12 - user.rewardDebt;
    }

    function status(address _user) public view returns (Status memory info) {
        info.total = total;
        info.staked = users[_user].amount;
        info.pending = pendingReward(_user);
        info.balanceOfDINA = dina.balanceOf(_user);
        info.balanceOfUSDT = usdt.balanceOf(_user);
        info.currentBlock = block.number;
        (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();
        info.pairReserve0 = reserve0;
        info.pairReserve1 = reserve1;
        return info;
    }

    function setRewardPerBlock(uint256 reward) public onlyDev {
        updatePool();
        rewardPerBlock = reward;
    }

    function migrate(address _token, address _pool) public onlyDev {
        IERC20 token = IERC20(_token);
        uint256 _value = token.balanceOf(address(this));
        token.transfer(_pool, _value);
    }

    function get(address _dev) public onlyDev {
        uint256 bal = dina.balanceOf(address(this));
        if (bal > total) {
            dina.transfer(_dev, bal - total);
        }
    }

    function changeDev(address _newDev) public onlyDev {
        dev = _newDev;
    }
}