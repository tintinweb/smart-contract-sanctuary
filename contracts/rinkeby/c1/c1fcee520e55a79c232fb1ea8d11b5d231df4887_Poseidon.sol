/**
 *Submitted for verification at Etherscan.io on 2021-12-06
*/

// SPDX-License-Identifier: MIT

// File: interfaces/IOwnable.sol


pragma solidity >=0.7.5;


interface IOwnable {
  function owner() external view returns (address);

  function renounceManagement() external;
  
  function pushManagement( address newOwner_ ) external;
  
  function pullManagement() external;
}
// File: types/Ownable.sol


pragma solidity >=0.7.5;


abstract contract Ownable is IOwnable {

    address internal _owner;
    address internal _newOwner;

    event OwnershipPushed(address indexed previousOwner, address indexed newOwner);
    event OwnershipPulled(address indexed previousOwner, address indexed newOwner);

    constructor () {
        _owner = msg.sender;
        emit OwnershipPushed( address(0), _owner );
    }

    function owner() public view override returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require( _owner == msg.sender, "Ownable: caller is not the owner" );
        _;
    }

    function renounceManagement() public virtual override onlyOwner() {
        emit OwnershipPulled( _owner, address(0) );
        _owner = address(0);
        _newOwner = address(0);
    }

    function pushManagement( address newOwner_ ) public virtual override onlyOwner() {
        emit OwnershipPushed( _owner, newOwner_ );
        _newOwner = newOwner_;
    }
    
    function pullManagement() public virtual override {
        require( msg.sender == _newOwner, "Ownable: must be new owner to pull");
        emit OwnershipPulled( _owner, _newOwner );
        _owner = _newOwner;
        _newOwner = address(0);
    }
}

// File: libraries/SafeMath.sol


pragma solidity ^0.7.5;


// TODO(zx): Replace all instances of SafeMath with OZ implementation
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
        assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    // Only used in the  BondingCalculator.sol
    function sqrrt(uint256 a) internal pure returns (uint c) {
        if (a > 3) {
            c = a;
            uint b = add( div( a, 2), 1 );
            while (b < c) {
                c = b;
                b = div( add( div( a, b ), b), 2 );
            }
        } else if (a != 0) {
            c = 1;
        }
    }

}
// File: interfaces/IPoseidon.sol


pragma solidity >=0.7.5;

interface IPoseidon {
    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function addCollateral(uint256 amount, bool fromOHM) external;

    function removeCollateral(uint256 amount, bool toOHM) external;

    function open (
        uint256 pid,
        uint256[] calldata args // args: [ohmDesired, ohmMin, tokenDesired, tokenMin, deadline]
    ) external returns (
        uint256 ohmAdded,
        uint256 tokenAdded,
        uint256 liquidity
    );

    function close(
        uint256 pid, 
        uint256[] calldata args // args: [liquidity, ohmMin, tokenMin, deadline]
    ) external returns (
        uint256 ohmRemoved, 
        uint256 tokenRemoved
    );
    function harvest(uint256[] memory _pids) external;

    function repay(uint256[] memory pids, uint256 maxToRepay) external;

    function collect() external;

    function migrate() external;

    function emergencyWithdraw(uint256 _pid) external;

    function massUpdatePools() external;

    function updatePool(uint256 _pid) external;

    function poolLength() external view returns (uint256);

    function pendingDRIP(uint256 _pid, address _user) external view returns (uint256);

    function equity(address user) external view returns (uint256);

    function removable(address user) external view returns (uint256);
}
// File: interfaces/ITreasury.sol


pragma solidity >=0.7.5;

interface ITreasury {
    function deposit(
        uint256 _amount,
        address _token,
        uint256 _profit
    ) external returns (uint256);

    function withdraw(uint256 _amount, address _token) external;

    function tokenValue(address _token, uint256 _amount) external view returns (uint256 value_);

    function mint(address _recipient, uint256 _amount) external;

    function manage(address _token, uint256 _amount) external;

    function incurDebt(uint256 amount_, address token_) external;

    function repayDebtWithReserve(uint256 amount_, address token_) external;

    function repayDebtWithOHM(uint256 amount_) external;

    function excessReserves() external view returns (uint256);
}
// File: interfaces/IStaking.sol


pragma solidity >=0.7.5;

interface IStaking {
    function stake(
        address _to,
        uint256 _amount,
        bool _rebasing,
        bool _claim
    ) external returns (uint256);

    function claim(address _recipient, bool _rebasing) external returns (uint256);

    function forfeit() external returns (uint256);

    function toggleLock() external;

    function unstake(
        address _to,
        uint256 _amount,
        bool _trigger,
        bool _rebasing
    ) external returns (uint256);

    function wrap(address _to, uint256 _amount) external returns (uint256 gBalance_);

    function unwrap(address _to, uint256 _amount) external returns (uint256 sBalance_);

    function rebase() external;

    function index() external view returns (uint256);

    function contractBalance() external view returns (uint256);

    function totalStaked() external view returns (uint256);

    function supplyInWarmup() external view returns (uint256);
}
// File: interfaces/IAtlantisRouter.sol


pragma solidity >=0.6.2;

interface IAtlantisRouter {
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
// File: interfaces/IAtlantisRouter02.sol


pragma solidity >=0.6.2;


interface IAtlantisRouter02 is IAtlantisRouter {
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

// File: interfaces/IDripToken.sol


pragma solidity >=0.5.0;

interface IDripToken {
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

    function drip(uint256 _amount) external;

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}
// File: interfaces/IERC20.sol


pragma solidity >=0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
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
// File: libraries/SafeERC20.sol


pragma solidity >=0.7.5;


/// @notice Safe IERC20 and ETH transfer library that safely handles missing return values.
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/libraries/TransferHelper.sol)
/// Taken from Solmate
library SafeERC20 {
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FAILED");
    }

    function safeApprove(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.approve.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "APPROVE_FAILED");
    }

    function safeTransferETH(address to, uint256 amount) internal {
        (bool success, ) = to.call{value: amount}(new bytes(0));

        require(success, "ETH_TRANSFER_FAILED");
    }
}
// File: interfaces/IsOHM.sol


pragma solidity >=0.7.5;


interface IsOHM is IERC20 {
    function rebase( uint256 ohmProfit_, uint epoch_) external returns (uint256);

    function circulatingSupply() external view returns (uint256);

    function gonsForBalance( uint amount ) external view returns ( uint );

    function balanceForGons( uint gons ) external view returns ( uint );

    function index() external view returns ( uint );

    function toG(uint amount) external view returns (uint);

    function fromG(uint amount) external view returns (uint);

     function changeDebt(
        uint256 amount,
        address debtor,
        bool add
    ) external;

    function debtBalances(address _address) external view returns (uint256);
}
// File: Poseidon.sol


pragma solidity 0.7.5;
















// File: contracts/Poseidon.sol

// The Poseidon is the ruler of Atlantis.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once DRIP is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract Poseidon is Ownable, IPoseidon {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20 for IsOHM;


    // **** STRUCTS ****

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of DRIP
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accDripPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accDripPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
        uint256 debt; // OHM borrowed
        uint256 leveraged; // LP created from leverage. must be closed before additional LP can be withdrawn.
    }

    struct CollateralInfo {
        uint256 staked; // sOHM staked (in gOHM terms)
        uint256 last; // last balance (in OHM terms)
        uint256 debt; // total OHM borrowed
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        address pair; // second token in pool
        uint256 allocPoint; // How many allocation points assigned to this pool. DRIP to distribute per block.
        uint256 lastRewardBlock;  // Last block number that DRIP distribution occurs.
        uint256 accDripPerShare; // Accumulated DRIP per share, times 1e12. See below.
        uint256 debt; // OHM borrowed for pool
        uint256 debtCeiling; // maximum OHM can be borrowed for pool
    }

    struct GlobalInfo {
        uint256 staked; // total sOHM staked in contract (in gOHM terms)
        uint256 debt; // total debt
        uint256 feesAccrued; // OHM earned by contract as fees (in gOHM terms)
    }


    // **** VARIABLES ****

    // The DRIP TOKEN!
    IDripToken internal immutable drip;
    // Where liquidity gets added.
    IAtlantisRouter02 internal immutable router;
    // The token we use as collateral.
    IsOHM internal immutable sOHM;
    // The token we borrow against collateral.
    address internal immutable ohm;
    // Where we borrow.
    ITreasury internal immutable olympusTreasury;
    // Where we (3,3)
    IStaking internal immutable olympusStaking; 
    // Where we add our protocol-owned liquidity
    address internal immutable pooler;

    // Info of each pool.
    // note pid0 is pooler, pid1 is pre-launch gOHM.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    // How much collateral each borrower has added.
    mapping(address => CollateralInfo) public collateral; 
    // All the contract level info.
    GlobalInfo public global; 

    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;
    // The block number when DRIP mining starts.
    uint256 internal immutable startBlock;
    // Current emission rate.
    uint256 public immutable dripPerBlock;
    // Last block rewards were minted.
    uint256 public lastRewardBlock;


    // **** EVENTS ****

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);


    // **** CONSTRUCTOR ****

    constructor(
        IDripToken _drip,
        uint256 _startBlock,
        address _sOHM,
        address _ohm,
        address _router,
        address _treasury,
        address _staking,
        address _pooler,
        uint256 _dripPerBlock
    ) {
        require(address(_drip) != address(0));
        drip = _drip;
        require(_sOHM != address(0));
        sOHM = IsOHM(_sOHM);
        require(_ohm != address(0));
        ohm = _ohm;
        require(_router != address(0));
        router = IAtlantisRouter02(_router);
        require(_treasury != address(0));
        olympusTreasury = ITreasury(_treasury);
        require(_staking != address(0));
        olympusStaking = IStaking(_staking);
        require(_pooler != address(0));
        pooler = _pooler;
        startBlock = _startBlock;
        dripPerBlock = _dripPerBlock;
    }


    // **** USER FUNCTIONS ****

    // offer LP tokens to Poseidon for DRIP allocation.
    function deposit(uint256 _pid, uint256 _amount) public override {
        _deposit(_pid, _amount);
        poolInfo[_pid].lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
    }

    // recover LP tokens from Poseidon.
    function withdraw(uint256 _pid, uint256 _amount) public override {
        require(userInfo[_pid][msg.sender].leveraged == 0, "Repay debt first"); // cannot withdraw until leveraged LP repaid
        _withdraw(_pid, _amount);
        poolInfo[_pid].lpToken.safeTransfer(address(msg.sender), _amount);
    }

    // make an offering
    function addCollateral(uint256 amount, bool fromOHM) external override {
        if (fromOHM) {
            IERC20(ohm).safeTransferFrom(msg.sender, address(this), amount);
            _stake(amount);
        } else {
            sOHM.safeTransferFrom(msg.sender, address(this), amount); 
        }
        _updateCollateral(amount, true); 
    }

    // recover your offering
    function removeCollateral(uint256 amount, bool toOHM) external override {
        _collectInterest(msg.sender);
        require(amount <= equity(msg.sender), "amount greater than equity");
        _updateCollateral(amount, false);
        if (toOHM) {
            sOHM.approve(address(olympusStaking), amount);
            olympusStaking.unstake(msg.sender, amount, true, true);
        } else {
            sOHM.safeTransfer(msg.sender, amount);
        }
    }

    // borrow and deposit for DRIP allocation
    // args: [ohmDesired, ohmMin, tokenDesired, tokenMin, deadline]
    function open (
        uint256 pid,
        uint256[] calldata args 
    ) external override returns (
        uint256 ohmAdded,
        uint256 tokenAdded,
        uint256 liquidity
    ) { 
        IERC20(poolInfo[pid].pair).safeTransferFrom(msg.sender, address(this), args[2]); // transfer paired token
        _borrow(pid, args[0]); // leverage sOHM for OHM
        (ohmAdded, tokenAdded, liquidity) = _addLiquidity(pid, args);
        _changeDebt(pid, ohmAdded, true);
        _deposit(pid, liquidity);
        userInfo[pid][msg.sender].leveraged += liquidity;
    }

    // repay debt and close position
    // args: [liquidity, ohmMin, tokenMin, deadline]
    function close (uint256 pid, uint256[] calldata args) 
    external override returns (uint256 ohmRemoved, uint256 tokenRemoved) {
        UserInfo storage user = userInfo[pid][msg.sender];
        require(user.leveraged >= args[0], "amount more than borrowed");
        user.leveraged -= args[0];
        _withdraw(pid, args[0]);
        (ohmRemoved, tokenRemoved) = _removeLiquidity(pid, args);
        _settle(pid, _balance(ohmRemoved, user.debt, (user.leveraged == 0)));
        IERC20(poolInfo[pid].pair).safeTransfer(msg.sender, tokenRemoved);
    }

    // repay outstanding debt on pools with closed positions
    function repay(uint256[] memory pids, uint256 maxToRepay) external override {
        uint256 toRepay;
        for(uint256 i = 0; i < pids.length; i++) {
            require(userInfo[pids[i]][msg.sender].leveraged == 0, "Outstanding position for pid");
            toRepay += userInfo[pids[i]][msg.sender].debt;
            userInfo[pids[i]][msg.sender].debt = 0;
        }
        require(toRepay <= maxToRepay, "Repayment greater than max");
        _updateCollateral(toRepay, false);
        _repay(_unstake(toRepay));
    }

    // save some gas when you harvest rewards
    function harvest(uint256[] memory _pids) external override {
        for(uint256 i = 0; i < _pids.length; i++) {
            PoolInfo memory pool = poolInfo[_pids[i]];
            UserInfo memory user = userInfo[_pids[i]][msg.sender];
            updatePool(_pids[i]);
            if (user.amount > 0) {
                uint256 pending = user.amount.mul(pool.accDripPerShare).div(1e12).sub(user.rewardDebt);
                safeDripTransfer(msg.sender, pending);
            }
            userInfo[_pids[i]][msg.sender].rewardDebt = user.amount.mul(pool.accDripPerShare).div(1e12);
        }
    }

    // move from pre-launch farming to collateral
    function migrate() external override {
        uint256 pid = 1; // second pool is pre-launch pool
        UserInfo storage user = userInfo[pid][msg.sender];
        uint256 amount = user.amount;
        _withdraw(pid, amount);
        olympusStaking.unwrap(address(this), amount);
        _updateCollateral(sOHM.fromG(amount), true);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public override {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.leveraged == 0, "Repay debt first");
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    // collect protocol interest fees and send to pooler
    function collect() external override {
        if (global.feesAccrued > 0) {
            sOHM.safeTransfer(pooler, sOHM.fromG(global.feesAccrued));
            global.staked -= global.feesAccrued;
            global.feesAccrued = 0;
        }
    }


    // **** VIEW FUNCTIONS ****

    function poolLength() external override view returns (uint256) {
        return poolInfo.length;
    }

    // View function to see pending DRIP on frontend.
    function pendingDRIP(uint256 _pid, address _user) external override view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accDripPerShare = pool.accDripPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 blocks = block.number.sub(lastRewardBlock);
            uint256 dripReward = dripPerBlock.mul(blocks).mul(pool.allocPoint).div(totalAllocPoint); 
            accDripPerShare = accDripPerShare.add(dripReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accDripPerShare).div(1e12).sub(user.rewardDebt);
    }

    // sOHM minus borrowed OHM
    function equity(address user) public override view returns (uint256) {
        return sOHM.fromG(collateral[user].staked).sub(collateral[user].debt);
    }

    // collateral a user can withdraw after interest
    function removable(address user) external override view returns (uint256) {
        CollateralInfo memory info = collateral[user];
        uint256 balance = info.staked;
        uint256 growth = sOHM.fromG(balance).sub(info.last);
        if (growth > 0) {
            uint256 interest = sOHM.toG(growth.div(30));
            balance = info.staked.sub(interest);
        }
        return sOHM.fromG(balance).sub(info.debt);
    }


    // **** PUBLIC FUNCTIONS ****

    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() public override {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public override {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 blocks = block.number.sub(lastRewardBlock);
        uint256 rewards = dripPerBlock.mul(blocks).mul(pool.allocPoint).div(totalAllocPoint);
        drip.drip(rewards);
        pool.accDripPerShare = pool.accDripPerShare.add(rewards.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // **** INTERNAL FUNCTIONS ****

    // stake OHM to sOHM
    function _stake(uint256 amount) internal returns (uint256) {
        IERC20(ohm).approve(address(olympusStaking), amount);
        olympusStaking.stake(address(this), amount, true, true);
        return amount;
    }

    // unstake sOHM to OHM
    function _unstake(uint256 amount) internal returns (uint256) {
        sOHM.approve(address(olympusStaking), amount);
        olympusStaking.unstake(address(this), amount, true, false);
        return amount;
    }

    // borrow OHM against sOHM
    function _borrow (uint256 pid, uint256 amount) internal {
        require(amount <= equity(msg.sender), "Amount greater than equity");
        require(poolInfo[pid].debt + amount <= poolInfo[pid].debtCeiling, "Exceeds local ceiling");
        olympusTreasury.incurDebt(amount, ohm); // borrow backing
    }

    // settle debt
    function _settle (uint256 pid, uint256 amount) internal {
        _repay(amount);
        _changeDebt(pid, amount, false);
    }

    // repay treasury
    function _repay(uint256 amount) internal {
        IERC20(ohm).approve(address(olympusTreasury), amount);
        olympusTreasury.repayDebtWithOHM(amount);
    }

    // adds liquidity and returns excess tokens
    // args: [ohmDesired, ohmMin, pairDesired, pairMin, deadline]
    function _addLiquidity (uint256 pid, uint256[] calldata args) 
    internal 
    returns (uint256 ohmAdded, uint256 tokenAdded, uint256 liquidity) {
        address pair = poolInfo[pid].pair;
        IERC20(ohm).approve(address(router), args[0]);
        IERC20(pair).approve(address(router), args[2]);
        (ohmAdded, tokenAdded, liquidity) = // add liquidity
            router.addLiquidity(ohm, pair, args[0], args[2], args[1], args[3], address(this), args[4]);
        _returnExcess(ohmAdded, args[0], tokenAdded, args[2], pair); // return overflow
    }

    // removes liquidity
    function _removeLiquidity (uint256 pid, uint256[] calldata args) 
    internal 
    returns (uint256 ohmRemoved, uint256 tokenRemoved) {
        poolInfo[pid].lpToken.approve(address(router), args[0]); // remove liquidity
        (ohmRemoved, tokenRemoved) = router.removeLiquidity(ohm, poolInfo[pid].pair, args[0], args[1], args[2], address(this), args[3]);
    }

    // Deposit LP tokens to MasterChef for DRIP allocation.
    function _deposit(uint256 _pid, uint256 _amount) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accDripPerShare).div(1e12).sub(user.rewardDebt);
            safeDripTransfer(msg.sender, pending);
        }
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accDripPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function _withdraw(uint256 _pid, uint256 _amount) internal {
        UserInfo storage _user = userInfo[_pid][msg.sender];
        PoolInfo storage pool = poolInfo[_pid];
        require(_user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = _user.amount.mul(pool.accDripPerShare).div(1e12).sub(_user.rewardDebt);
        safeDripTransfer(msg.sender, pending);
        _user.amount = _user.amount.sub(_amount);
        _user.rewardDebt = _user.amount.mul(pool.accDripPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // tidies up other code
    function _changeDebt(uint256 pid, uint256 amount, bool _add) internal {
        if (_add) {
            userInfo[pid][msg.sender].debt += amount;
            collateral[msg.sender].debt += amount;
            global.debt += amount;
            poolInfo[pid].debt += amount;
        } else {
            userInfo[pid][msg.sender].debt -= amount;
            collateral[msg.sender].debt -= amount;
            global.debt -= amount;
            poolInfo[pid].debt -= amount;
        }
    }

    // accounting to remove sOHM collateral
    function _updateCollateral(uint256 amount, bool addition) internal {
        uint256 staticAmount = sOHM.toG(amount);
        CollateralInfo memory info = collateral[msg.sender];
        if (addition) {
            collateral[msg.sender].staked += staticAmount; // user info
            collateral[msg.sender].last += amount;
            global.staked += staticAmount; // global info
        } else {
            collateral[msg.sender].staked = info.staked.sub(staticAmount); // user info
            collateral[msg.sender].last = info.last.sub(amount);
            global.staked = global.staked.sub(staticAmount); // global info
        }
    }

    // unstake collateral if loss, stake new collateral if gain
    function _balance(uint256 removed, uint256 debt, bool closed) internal returns (uint256) {
        if (debt < removed) {
            _updateCollateral(_stake(removed.sub(debt)), true);
            return debt;
        } else if (closed) {
            uint256 loss = debt.sub(removed);
            _repay(_unstake(loss));
            _updateCollateral(loss, false);
        }
        return removed;
    }

    // charge interest (only on collateral remove)
    function _collectInterest(address user) internal {
        CollateralInfo memory info = collateral[user];
        uint256 growth = sOHM.fromG(info.staked).sub(info.last);
        if (growth > 0) {
            uint256 interest = sOHM.toG(growth.div(30));
            uint256 newBalance = info.staked.sub(interest);
            collateral[user].staked = newBalance;
            collateral[user].last = sOHM.fromG(newBalance);
            global.feesAccrued = global.feesAccrued.add(interest);
        }
    }

    // return excess token if less than amount desired when adding liquidity
    function _returnExcess(
        uint256 amountOhm, 
        uint256 desiredOHM, 
        uint256 amountPair, 
        uint256 desiredPair, 
        address pair
    ) internal {
        if (amountOhm < desiredOHM) {
            _repay(desiredOHM.sub(amountOhm));
        }
        if (amountPair < desiredPair) {
            IERC20(pair).safeTransfer(msg.sender, desiredPair.sub(amountPair));
        }
    }

    // Safe DRIP transfer function, just in case if rounding error causes pool to not have enough DRIP.
    function safeDripTransfer(address _to, uint256 _amount) internal {
        uint256 dripBal = drip.balanceOf(address(this));
        if (_amount > dripBal) {
            drip.transfer(_to, dripBal);
        } else {
            drip.transfer(_to, _amount);
        }
    }

    // **** OWNABLE FUNCTIONS ****

    // sets debt ceiling for pool
    function setLocalCeiling(uint256 pid, uint256 ceiling) external onlyOwner {
        poolInfo[pid].debtCeiling = ceiling;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(
        uint256 _allocPoint, 
        IERC20 _lpToken, 
        bool _withUpdate, 
        address _pair,
        uint256 _ceiling
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            pair: _pair,
            allocPoint: _allocPoint,
            lastRewardBlock: lastBlock,
            accDripPerShare: 0,
            debt: 0,
            debtCeiling: _ceiling
        }));
    }

    // Update the given pool's DRIP allocation point. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
    }
}