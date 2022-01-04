//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/IIzludeV2.sol";
import "./interfaces/IByalan.sol";
import "./interfaces/IFeeKafraV2.sol";
import "./interfaces/IAllocKafraV2.sol";

import "./PronteraV2.sol";

contract MorrocViewV2 {
    PronteraV2 public immutable prontera;

    constructor(PronteraV2 _prontera) {
        prontera = _prontera;
    }

    function balance(IIzludeV2 izlude) public view returns (uint256) {
        // want izlude + want byalan
        return izlude.balance();
    }

    function jellopyOf(address izlude, address user) public view returns (uint256 jellopy, uint256 storedJellopy) {
        // share balance
        (jellopy, , storedJellopy) = prontera.userInfo(izlude, user);
    }

    function balanceOfMasterChef(IIzludeV2 izlude) public view returns (uint256) {
        return izlude.byalan().balanceOfMasterChef();
    }

    function pronteraWant(address izlude) public view returns (IERC20 want) {
        (want, , , , ) = prontera.poolInfo(izlude);
    }

    function pendingKSW(address izlude, address user) public view returns (uint256) {
        return prontera.pendingKSW(izlude, user);
    }

    function pendingRewardTokens(IIzludeV2 izlude)
        public
        view
        returns (IERC20[] memory rewardTokens, uint256[] memory rewardAmounts)
    {
        return izlude.byalan().pendingRewardTokens();
    }

    function totalSupply(IIzludeV2 izlude) public view returns (uint256) {
        return izlude.totalSupply();
    }

    function kafraMaxFee(IIzludeV2 izlude) public view returns (uint256) {
        address feeKafra = izlude.feeKafra();
        if (feeKafra == address(0)) {
            return 0;
        }
        return IFeeKafraV2(feeKafra).MAX_FEE();
    }

    function kafraMaxAllocation(IIzludeV2 izlude) public view returns (uint16) {
        address allocKafra = izlude.allocKafra();
        if (allocKafra == address(0)) {
            return 0;
        }
        return IAllocKafraV2(allocKafra).MAX_ALLOCATION();
    }

    function limitAllocation(IIzludeV2 izlude) public view returns (uint16) {
        address allocKafra = izlude.allocKafra();
        if (allocKafra == address(0)) {
            return 0;
        }
        return IAllocKafraV2(allocKafra).limitAllocation();
    }

    function userLimitAllocation(IIzludeV2 izlude, address user) public view returns (uint16) {
        address allocKafra = izlude.allocKafra();
        if (allocKafra == address(0)) {
            return 0;
        }
        return IAllocKafraV2(allocKafra).userLimitAllocation(user);
    }

    function canAllocate(
        IIzludeV2 izlude,
        uint256 amount,
        address user
    ) public view returns (bool) {
        if (izlude.allocKafra() == address(0)) {
            return true;
        }
        return
            IAllocKafraV2(izlude.allocKafra()).canAllocate(
                amount,
                izlude.byalan().balanceOf() + amount,
                izlude.byalan().balanceOfMasterChef(),
                user
            );
    }

    function withdrawFee(IIzludeV2 izlude) public view returns (uint256) {
        address feeKafra = izlude.feeKafra();
        if (feeKafra == address(0)) {
            return 0;
        }
        return IFeeKafraV2(feeKafra).withdrawFee();
    }

    function holdingKSWWithdrawFee(IIzludeV2 izlude) public view returns (uint256) {
        address feeKafra = izlude.feeKafra();
        if (feeKafra == address(0)) {
            return 0;
        }
        return IFeeKafraV2(feeKafra).holdingKSWWithdrawFee();
    }

    function holdingKSWGodWithdrawFee(IIzludeV2 izlude) public view returns (uint256) {
        address feeKafra = izlude.feeKafra();
        if (feeKafra == address(0)) {
            return 0;
        }
        return IFeeKafraV2(feeKafra).holdingKSWGodWithdrawFee();
    }

    function userWithdrawFee(IIzludeV2 izlude, address user) public view returns (uint256) {
        address feeKafra = izlude.feeKafra();
        if (feeKafra == address(0)) {
            return 0;
        }
        return IFeeKafraV2(feeKafra).userWithdrawFee(user);
    }

    function calculateWithdrawFee(
        IIzludeV2 izlude,
        uint256 wantAmount,
        address user
    ) public view returns (uint256) {
        if (izlude.feeKafra() == address(0)) {
            return 0;
        }
        return izlude.calculateWithdrawFee(wantAmount, user);
    }

    function performanceMaxFee(IIzludeV2 izlude) public view returns (uint256) {
        return izlude.byalan().MAX_FEE();
    }

    function paused(IIzludeV2 izlude) public view returns (bool) {
        return izlude.byalan().paused();
    }

    function allocPoint(address izlude) public view returns (uint256) {
        (, , , uint64 ap, ) = prontera.poolInfo(izlude);
        return ap;
    }

    function callFee(IIzludeV2 izlude) public view returns (uint256) {
        return izlude.byalan().callFee();
    }

    function totalFee(IIzludeV2 izlude) public view returns (uint256) {
        return izlude.byalan().totalFee();
    }

    function canHarvest(IIzludeV2 izlude, address user) public view returns (bool) {
        address byalan = address(izlude.byalan());
        (bool success, bytes memory ret) = address(byalan).staticcall(abi.encodeWithSignature("harvester()"));
        if (!success) {
            return true;
        }
        address harvester = abi.decode(ret, (address));
        return harvester == address(0) || user == harvester;
    }

    struct IzludeInfoItem {
        IERC20 want;
        uint256 balance;
        uint256 balanceOfMasterChef;
        IERC20[] rewardTokens;
        uint256[] rewardAmounts;
        uint256 totalSupply;
        uint256 kafraMaxFee;
        uint256 withdrawFee;
        uint256 holdingKSWWithdrawFee;
        uint256 holdingKSWGodWithdrawFee;
        uint256 userWithdrawFee;
        uint256 performanceMaxFee;
        uint256 allocPoint;
        uint256 callFee;
        uint256 totalFee;
        uint256 jellopy;
        uint256 storedJellopy;
        uint256 pendingKSW;
        uint16 kafraMaxAllocation;
        uint16 limitAllocation;
        uint16 userLimitAllocation;
        bool canAllocate;
        bool paused;
        bool canHarvest;
    }

    function izludeInfo(IIzludeV2 izlude, address user) external view returns (IzludeInfoItem memory izludeItem) {
        (izludeItem.jellopy, izludeItem.storedJellopy) = jellopyOf(address(izlude), user);
        izludeItem.pendingKSW = pendingKSW(address(izlude), user);
        izludeItem.canAllocate = canAllocate(izlude, 0, user);
        izludeItem.want = pronteraWant(address(izlude));
        izludeItem.balance = balance(izlude);
        izludeItem.balanceOfMasterChef = balanceOfMasterChef(izlude);
        (izludeItem.rewardTokens, izludeItem.rewardAmounts) = pendingRewardTokens(izlude);
        izludeItem.totalSupply = totalSupply(izlude);
        izludeItem.kafraMaxFee = kafraMaxFee(izlude);
        izludeItem.withdrawFee = withdrawFee(izlude);
        izludeItem.holdingKSWWithdrawFee = holdingKSWWithdrawFee(izlude);
        izludeItem.holdingKSWGodWithdrawFee = holdingKSWGodWithdrawFee(izlude);
        izludeItem.userWithdrawFee = userWithdrawFee(izlude, user);
        izludeItem.performanceMaxFee = performanceMaxFee(izlude);
        izludeItem.allocPoint = allocPoint(address(izlude));
        izludeItem.callFee = callFee(izlude);
        izludeItem.totalFee = totalFee(izlude);
        izludeItem.kafraMaxAllocation = kafraMaxAllocation(izlude);
        izludeItem.limitAllocation = limitAllocation(izlude);
        izludeItem.userLimitAllocation = userLimitAllocation(izlude, user);
        izludeItem.paused = paused(izlude);
        izludeItem.canHarvest = canHarvest(izlude, user);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IByalan.sol";

interface IIzludeV2 {
    function totalSupply() external view returns (uint256);

    function prontera() external view returns (address);

    function want() external view returns (IERC20);

    function deposit(address user, uint256 amount) external returns (uint256 jellopy);

    function withdraw(address user, uint256 jellopy) external returns (uint256);

    function balance() external view returns (uint256);

    function byalan() external view returns (IByalan);

    function feeKafra() external view returns (address);

    function allocKafra() external view returns (address);

    function calculateWithdrawFee(uint256 amount, address user) external view returns (uint256);
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IByalanIsland.sol";
import "./ISailor.sol";

interface IByalan is IByalanIsland, ISailor {
    function want() external view returns (address);

    function beforeDeposit() external;

    function deposit() external;

    function withdraw(uint256) external;

    function balanceOf() external view returns (uint256);

    function balanceOfWant() external view returns (uint256);

    function balanceOfPool() external view returns (uint256);

    function balanceOfMasterChef() external view returns (uint256);

    function pendingRewardTokens() external view returns (IERC20[] memory rewardTokens, uint256[] memory rewardAmounts);

    function harvest() external;

    function retireStrategy() external;

    function panic() external;

    function pause() external;

    function unpause() external;

    function paused() external view returns (bool);
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IFeeKafra.sol";

interface IFeeKafraV2 is IFeeKafra {
    function MAX_FEE() external view returns (uint256);

    function withdrawFee() external view returns (uint256);

    function userWithdrawFee(address _user) external view returns (uint256);

    function holdingKSW() external view returns (uint256);

    function holdingKSWWithdrawFee() external view returns (uint256);

    function holdingKSWGodWithdrawFee() external view returns (uint256);

    function treasuryFeeWithdraw() external view returns (uint256);

    function kswFeeWithdraw() external view returns (uint256);

    function calculateWithdrawFee(uint256 _wantAmount, address _user) external view returns (uint256);

    function distributeWithdrawFee(IERC20 _token, address _fromUser) external;

    function ignoreFee(bool enable) external;
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IAllocKafra.sol";

interface IAllocKafraV2 is IAllocKafra {
    function MAX_ALLOCATION() external view returns (uint16);

    function limitAllocation() external view returns (uint16);

    function userLimitAllocation(address user) external view returns (uint16);

    function canAllocate(
        uint256 _amount,
        uint256 _balanceOfWant,
        uint256 _balanceOfMasterChef,
        address _user
    ) external view returns (bool);
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../libraries/Math.sol";

import "./interfaces/IPronteraReserve.sol";
import "./interfaces/IIzludeV2.sol";
import "./interfaces/IWETH.sol";

contract PronteraV2 is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeERC20 for IWETH;
    using Address for address;
    using Address for address payable;

    IWETH public constant WETH = IWETH(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);

    // Info of each user.
    struct UserInfo {
        uint256 jellopy;
        uint256 rewardDebt;
        uint256 storedJellopy;
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 want;
        address izlude;
        uint256 accKSWPerJellopy;
        uint64 allocPoint;
        uint64 lastRewardTime;
    }

    // Reserve
    IPronteraReserve public immutable reserve;

    // KSW address
    address public immutable ksw;
    // KSW tokens rewards per second.
    uint256 public kswPerSecond;

    // Info of each pool.
    address[] public traversalPools;
    mapping(address => bool) public isInTraversalPools; // remember is izlude in traversal
    mapping(address => PoolInfo) public poolInfo;
    uint256 public totalPool;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;

    // Info of each user that stakes to izlude.
    mapping(address => mapping(address => UserInfo)) public userInfo;

    // [user] [izlude] [store] => amount
    mapping(address => mapping(address => mapping(address => uint256))) private _storeAllowances;
    mapping(address => mapping(address => mapping(address => uint256))) public jellopyStorage;

    // Juno transportation
    address public juno;
    address public junoGuide;

    event Deposit(address indexed user, address indexed izlude, uint256 amount);
    event DepositFor(address indexed user, address indexed izlude, uint256 amount);
    event DepositToken(address indexed user, address indexed izlude, uint256[] tokenAmount, uint256 amount);
    event DepositEther(address indexed user, address indexed izlude, uint256 value, uint256 amount);
    event Withdraw(address indexed user, address indexed izlude, uint256 amount);
    event WithdrawToken(address indexed user, address indexed izlude, uint256 jellopyAmount, uint256 tokenAmount);
    event WithdrawEther(address indexed user, address indexed izlude, uint256 jellopyAmount, uint256 value);
    event EmergencyWithdraw(address indexed user, address indexed izlude, uint256 amount);

    event StoreApproval(address indexed owner, address indexed izlude, address indexed spender, uint256 value);
    event StoreKeepJellopy(address indexed owner, address indexed izlude, address indexed store, uint256 value);
    event StoreReturnJellopy(address indexed user, address indexed izlude, address indexed store, uint256 amount);
    event StoreWithdraw(address indexed user, address indexed izlude, address indexed store, uint256 amount);

    event AddPool(address indexed izlude, uint256 allocPoint, bool withUpdate);
    event SetPool(address indexed izlude, uint256 allocPoint, bool withUpdate);
    event SetKSWPerSecond(uint256 kswPerSecond);
    event SetJuno(address juno);
    event SetJunoGuide(address junoGuide);

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "Prontera: EXPIRED");
        _;
    }

    constructor(
        IPronteraReserve _reserve,
        address _ksw,
        uint256 _kswPerSecond,
        address _juno,
        address _junoGuide
    ) {
        reserve = _reserve;
        kswPerSecond = _kswPerSecond;
        juno = _juno;
        junoGuide = _junoGuide;
        ksw = _ksw;
    }

    function traversalPoolsLength() external view returns (uint256) {
        return traversalPools.length;
    }

    function _addTraversal(address izlude) private {
        if (isInTraversalPools[izlude]) {
            return;
        }

        isInTraversalPools[izlude] = true;
        traversalPools.push(izlude);
    }

    function removeTraversal(uint256 index) external {
        address izlude = traversalPools[index];
        require(poolInfo[izlude].allocPoint == 0, "allocated");

        isInTraversalPools[izlude] = false;
        traversalPools[index] = traversalPools[traversalPools.length - 1];
        traversalPools.pop();
    }

    // Add a new izlude to the pool.
    function add(
        address izlude,
        uint64 allocPoint,
        bool withUpdate
    ) external onlyOwner {
        require(IIzludeV2(izlude).prontera() == address(this), "?");
        require(IIzludeV2(izlude).totalSupply() >= 0, "??");
        require(poolInfo[izlude].izlude == address(0), "duplicated");
        if (withUpdate) {
            massUpdatePools();
        }

        poolInfo[izlude] = PoolInfo({
            want: IIzludeV2(izlude).want(),
            izlude: izlude,
            allocPoint: allocPoint,
            lastRewardTime: uint64(block.timestamp),
            accKSWPerJellopy: 0
        });
        totalPool += 1;
        totalAllocPoint += allocPoint;
        if (allocPoint > 0) {
            _addTraversal(izlude);
        }
        emit AddPool(izlude, allocPoint, withUpdate);
    }

    // Update the given pool's KSW allocation point.
    function set(
        address izlude,
        uint64 allocPoint,
        bool withUpdate
    ) external onlyOwner {
        require(izlude != address(0), "invalid izlude");
        PoolInfo storage pool = poolInfo[izlude];
        require(pool.izlude == izlude, "!found");
        if (withUpdate) {
            massUpdatePools();
        }

        totalAllocPoint = (totalAllocPoint - pool.allocPoint) + allocPoint;
        pool.allocPoint = allocPoint;
        if (allocPoint > 0) {
            _addTraversal(izlude);
        }
        emit SetPool(izlude, allocPoint, withUpdate);
    }

    /**
     * @dev View function to see pending KSWs on frontend.
     *
     */
    function pendingKSW(address izlude, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[izlude];
        UserInfo storage user = userInfo[izlude][_user];
        uint256 accKSWPerJellopy = pool.accKSWPerJellopy;
        uint256 izludeSupply = IIzludeV2(izlude).totalSupply();
        if (block.timestamp > pool.lastRewardTime && izludeSupply != 0) {
            uint256 time = block.timestamp - pool.lastRewardTime;
            uint256 kswReward = (time * kswPerSecond * pool.allocPoint) / totalAllocPoint;

            uint256 stakingBal = reserve.balances();
            accKSWPerJellopy += (Math.min(kswReward, stakingBal) * 1e12) / izludeSupply;
        }

        uint256 tJellopy = user.jellopy + user.storedJellopy;
        uint256 r = ((tJellopy * accKSWPerJellopy) / 1e12) - user.rewardDebt;
        return r;
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        for (uint256 i = 0; i < traversalPools.length; i++) {
            updatePool(traversalPools[i]);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(address izlude) public {
        PoolInfo storage pool = poolInfo[izlude];
        require(pool.izlude == izlude, "!pool");
        if (block.timestamp > pool.lastRewardTime) {
            uint256 izludeSupply = IIzludeV2(izlude).totalSupply();
            if (izludeSupply > 0) {
                uint256 time = block.timestamp - pool.lastRewardTime;
                uint256 kswReward = (time * kswPerSecond * pool.allocPoint) / totalAllocPoint;
                uint256 r = reserve.withdraw(address(this), kswReward);
                pool.accKSWPerJellopy += (r * 1e12) / izludeSupply;
            }
            pool.lastRewardTime = uint64(block.timestamp);
        }
    }

    /**
     * @dev low level deposit 'want' to izlude or staking here
     *
     * 'warning' deposit amount must be guarantee by caller
     */
    function _deposit(
        address _user,
        address izlude,
        IERC20 want,
        uint256 amount
    ) private {
        PoolInfo storage pool = poolInfo[izlude];
        UserInfo storage user = userInfo[izlude][_user];

        updatePool(izlude);
        uint256 tJellopy = user.jellopy + user.storedJellopy;
        if (tJellopy > 0) {
            uint256 pending = ((tJellopy * pool.accKSWPerJellopy) / 1e12) - user.rewardDebt;
            if (pending > 0) {
                IERC20(ksw).transfer(_user, pending);
            }
        }

        // amount must guaranteed by caller
        if (amount > 0) {
            want.safeIncreaseAllowance(izlude, amount);
            uint256 addAmount = IIzludeV2(izlude).deposit(_user, amount);
            tJellopy += addAmount;
            user.jellopy += addAmount;
        }
        user.rewardDebt = (tJellopy * pool.accKSWPerJellopy) / 1e12;
    }

    function harvest(address[] calldata izludes) external {
        for (uint256 i = 0; i < izludes.length; i++) {
            _deposit(msg.sender, izludes[i], IERC20(address(0)), 0);
        }
    }

    function deposit(address izlude, uint256 amount) external nonReentrant {
        PoolInfo storage pool = poolInfo[izlude];
        if (amount > 0) {
            require(_safeERC20TransferIn(pool.want, amount) == amount, "!amount");
        }
        _deposit(msg.sender, izlude, pool.want, amount);
        emit Deposit(msg.sender, izlude, amount);
    }

    function depositFor(
        address user,
        address izlude,
        uint256 amount
    ) external nonReentrant {
        PoolInfo storage pool = poolInfo[izlude];
        if (amount > 0) {
            require(_safeERC20TransferIn(pool.want, amount) == amount, "!amount");
        }
        _deposit(user, izlude, pool.want, amount);
        emit DepositFor(user, izlude, amount);
    }

    function depositToken(
        address izlude,
        IERC20[] calldata tokens,
        uint256[] calldata tokenAmounts,
        uint256 amountOutMin,
        uint256 deadline,
        bytes calldata data
    ) external nonReentrant ensure(deadline) {
        require(tokens.length == tokenAmounts.length, "length mismatch");
        PoolInfo storage pool = poolInfo[izlude];
        IERC20 want = pool.want;

        uint256 beforeBal = want.balanceOf(address(this));
        for (uint256 i = 0; i < tokens.length; i++) {
            require(_safeERC20TransferIn(tokens[i], tokenAmounts[i]) == tokenAmounts[i], "!amount");
            if (tokens[i] != want) {
                tokens[i].safeTransfer(juno, tokenAmounts[i]);
            }
        }
        juno.functionCall(data, "juno: failed");
        uint256 amount = want.balanceOf(address(this)) - beforeBal;
        require(amount >= amountOutMin, "insufficient output amount");

        _deposit(msg.sender, izlude, want, amount);
        emit DepositToken(msg.sender, izlude, tokenAmounts, amount);
    }

    function depositEther(
        address izlude,
        uint256 amountOutMin,
        uint256 deadline,
        bytes calldata data
    ) external payable nonReentrant ensure(deadline) {
        require(msg.value > 0, "!value");
        PoolInfo storage pool = poolInfo[izlude];
        IERC20 want = pool.want;

        uint256 beforeBal = want.balanceOf(address(this));
        {
            WETH.deposit{value: msg.value}();
            WETH.safeTransfer(juno, msg.value);
            juno.functionCall(data, "juno: failed");
        }
        uint256 afterBal = want.balanceOf(address(this));
        uint256 amount = afterBal - beforeBal;
        require(amount >= amountOutMin, "insufficient output amount");

        _deposit(msg.sender, izlude, want, amount);
        emit DepositEther(msg.sender, izlude, msg.value, amount);
    }

    function _withdraw(
        address _user,
        address izlude,
        IERC20 want,
        uint256 jellopyAmount
    ) private returns (uint256 amount) {
        PoolInfo storage pool = poolInfo[izlude];
        UserInfo storage user = userInfo[izlude][_user];
        jellopyAmount = Math.min(user.jellopy, jellopyAmount);

        updatePool(izlude);
        uint256 tJellopy = user.jellopy + user.storedJellopy;
        uint256 pending = ((tJellopy * pool.accKSWPerJellopy) / 1e12) - user.rewardDebt;
        if (pending > 0) {
            IERC20(ksw).transfer(_user, pending);
        }

        tJellopy -= jellopyAmount;
        user.jellopy -= jellopyAmount;
        user.rewardDebt = (tJellopy * pool.accKSWPerJellopy) / 1e12;
        if (jellopyAmount > 0) {
            uint256 wantBefore = want.balanceOf(address(this));
            IIzludeV2(izlude).withdraw(_user, jellopyAmount);
            uint256 wantAfter = want.balanceOf(address(this));
            amount = wantAfter - wantBefore;
        }
    }

    function withdraw(address izlude, uint256 jellopyAmount) external nonReentrant {
        PoolInfo storage pool = poolInfo[izlude];
        uint256 amount = _withdraw(msg.sender, izlude, pool.want, jellopyAmount);
        if (amount > 0) {
            pool.want.safeTransfer(msg.sender, amount);
        }
        emit Withdraw(msg.sender, izlude, jellopyAmount);
    }

    // withdraw from allowed store. send pending reward to owner but transfer want to store and let store handle the rest
    function storeWithdraw(
        address _user,
        address izlude,
        uint256 jellopyAmount
    ) external nonReentrant {
        require(jellopyAmount > 0, "invalid amount");
        PoolInfo storage pool = poolInfo[izlude];
        UserInfo storage user = userInfo[izlude][_user];
        jellopyStorage[_user][izlude][msg.sender] -= jellopyAmount;
        user.storedJellopy -= jellopyAmount;
        user.jellopy += jellopyAmount;

        uint256 amount = _withdraw(_user, izlude, pool.want, jellopyAmount);
        if (amount > 0) {
            pool.want.safeTransfer(msg.sender, amount);
        }
        emit StoreWithdraw(_user, izlude, msg.sender, amount);
    }

    function withdrawToken(
        address izlude,
        IERC20 token,
        uint256 jellopyAmount,
        uint256 amountOutMin,
        uint256 deadline,
        bytes calldata data
    ) external nonReentrant ensure(deadline) {
        PoolInfo storage pool = poolInfo[izlude];
        IERC20 want = pool.want;
        require(token != want, "!want");
        uint256 amount = _withdraw(msg.sender, izlude, want, jellopyAmount);

        uint256 beforeBal = token.balanceOf(address(this));
        {
            want.safeTransfer(juno, amount);
            juno.functionCall(data, "juno: failed");
        }
        uint256 afterBal = token.balanceOf(address(this));
        uint256 amountOut = afterBal - beforeBal;
        require(amountOut >= amountOutMin, "insufficient output amount");

        token.safeTransfer(msg.sender, amountOut);
        emit WithdrawToken(msg.sender, izlude, jellopyAmount, amountOut);
    }

    function withdrawEther(
        address izlude,
        uint256 jellopyAmount,
        uint256 amountOutMin,
        uint256 deadline,
        bytes calldata data
    ) external nonReentrant ensure(deadline) {
        PoolInfo storage pool = poolInfo[izlude];
        uint256 amount = _withdraw(msg.sender, izlude, pool.want, jellopyAmount);

        uint256 beforeBal = WETH.balanceOf(address(this));
        {
            pool.want.safeTransfer(juno, amount);
            juno.functionCall(data, "juno: failed");
        }
        uint256 afterBal = WETH.balanceOf(address(this));
        uint256 amountOut = afterBal - beforeBal;
        require(amountOut >= amountOutMin, "insufficient output amount");

        WETH.withdraw(amountOut);
        payable(msg.sender).sendValue(amountOut);
        emit WithdrawEther(msg.sender, izlude, jellopyAmount, amountOut);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(address izlude) external {
        PoolInfo storage pool = poolInfo[izlude];
        UserInfo storage user = userInfo[izlude][msg.sender];

        uint256 jellopy = user.jellopy;
        user.jellopy = 0;
        user.rewardDebt = (user.storedJellopy * pool.accKSWPerJellopy) / 1e12;
        if (jellopy > 0) {
            IERC20 want = pool.want;
            uint256 wantBefore = want.balanceOf(address(this));
            IIzludeV2(izlude).withdraw(msg.sender, jellopy);
            uint256 wantAfter = want.balanceOf(address(this));
            want.safeTransfer(msg.sender, wantAfter - wantBefore);
        }
        emit EmergencyWithdraw(msg.sender, izlude, jellopy);
    }

    /**
     * @dev Returns the remaining number of jellopy that `store` will be
     * allowed to keep on behalf of `user` through {storeKeepJellopy}. This is
     * zero by default.
     *
     * This value changes when {approveStore} or {storeKeepJellopy} are called.
     */
    function storeAllowance(
        address user,
        address izlude,
        address store
    ) external view returns (uint256) {
        return _storeAllowances[user][izlude][store];
    }

    function _approveStore(
        address user,
        address izlude,
        address store,
        uint256 amount
    ) private {
        require(user != address(0), "approve from the zero address");
        require(izlude != address(0), "approve izlude zero address");
        require(store != address(0), "approve to the zero address");

        _storeAllowances[user][izlude][store] = amount;
        emit StoreApproval(user, izlude, store, amount);
    }

    /**
     * @dev grant store to keep jellopy
     */
    function approveStore(
        address izlude,
        address store,
        uint256 amount
    ) external {
        _approveStore(msg.sender, izlude, store, amount);
    }

    /**
     * @dev Atomically increases the allowance granted to `store` by the caller.
     */
    function increaseStoreAllowance(
        address izlude,
        address store,
        uint256 addedAmount
    ) external {
        _approveStore(msg.sender, izlude, store, _storeAllowances[msg.sender][izlude][store] + addedAmount);
    }

    /**
     * @dev Atomically decreases the allowance granted to `store` by the caller.
     */
    function decreaseStoreAllowance(
        address izlude,
        address store,
        uint256 subtractedAmount
    ) external {
        uint256 currentAllowance = _storeAllowances[msg.sender][izlude][store];
        require(currentAllowance >= subtractedAmount, "decreased allowance below zero");
        unchecked {
            _approveStore(msg.sender, izlude, store, currentAllowance - subtractedAmount);
        }
    }

    /**
     * @dev store pull user jellopy to keep
     */
    function storeKeepJellopy(
        address _user,
        address izlude,
        uint256 amount
    ) external {
        require(amount > 0, "invalid amount");
        UserInfo storage user = userInfo[izlude][_user];
        user.jellopy -= amount;
        user.storedJellopy += amount;
        jellopyStorage[_user][izlude][msg.sender] += amount;

        uint256 currentAllowance = _storeAllowances[_user][izlude][msg.sender];
        require(currentAllowance >= amount, "keep amount exceeds allowance");
        unchecked {
            _approveStore(_user, izlude, msg.sender, currentAllowance - amount);
        }
        emit StoreKeepJellopy(_user, izlude, msg.sender, amount);
    }

    /**
     * @dev store return jellopy to user
     */
    function storeReturnJellopy(
        address _user,
        address izlude,
        uint256 amount
    ) external {
        require(amount > 0, "invalid amount");
        UserInfo storage user = userInfo[izlude][_user];
        jellopyStorage[_user][izlude][msg.sender] -= amount;
        user.storedJellopy -= amount;
        user.jellopy += amount;
        emit StoreReturnJellopy(_user, izlude, msg.sender, amount);
    }

    function setKSWPerSecond(uint256 _kswPerSecond) external onlyOwner {
        massUpdatePools();
        kswPerSecond = _kswPerSecond;
        emit SetKSWPerSecond(_kswPerSecond);
    }

    function setJuno(address _juno) external {
        require(msg.sender == junoGuide, "!guide");
        juno = _juno;
        emit SetJuno(_juno);
    }

    function setJunoGuide(address _junoGuide) external onlyOwner {
        junoGuide = _junoGuide;
        emit SetJunoGuide(_junoGuide);
    }

    function _safeERC20TransferIn(IERC20 token, uint256 amount) private returns (uint256) {
        require(amount > 0, "zero amount");

        uint256 balanceBefore = token.balanceOf(address(this));
        token.safeTransferFrom(msg.sender, address(this), amount);
        uint256 balanceAfter = token.balanceOf(address(this));
        return balanceAfter - balanceBefore;
    }

    receive() external payable {
        require(msg.sender == address(WETH), "reject");
    }
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IByalanIsland {
    function izlude() external view returns (address);
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface ISailor {
    function MAX_FEE() external view returns (uint256);

    function totalFee() external view returns (uint256);

    function callFee() external view returns (uint256);

    function kswFee() external view returns (uint256);
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IFeeKafra {
    function MAX_FEE() external view returns (uint256);

    function withdrawFee() external view returns (uint256);

    function treasuryFeeWithdraw() external view returns (uint256);

    function kswFeeWithdraw() external view returns (uint256);

    function calculateWithdrawFee(uint256 _wantAmount, address _user) external view returns (uint256);

    function distributeWithdrawFee(IERC20 _token, address _fromUser) external;
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IAllocKafra {
    function MAX_ALLOCATION() external view returns (uint16);

    function limitAllocation() external view returns (uint16);

    function canAllocate(
        uint256 _amount,
        uint256 _balanceOfWant,
        uint256 _balanceOfMasterChef,
        address _user
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

library Math {
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
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IPronteraReserve {
    function balances() external view returns (uint256);

    function withdraw(address to, uint256 amount) external returns (uint256);
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}