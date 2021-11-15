// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../vendors/libraries/SafeMath.sol";
import "../vendors/libraries/SafeERC20.sol";
import "../vendors/interfaces/IERC20.sol";
import "./UsersStorage.sol";
import "./StagesStorage.sol";

abstract contract AbstractFarm is UsersStorage, StagesStorage {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    constructor(IERC20 pact_, uint256 totalRewardAmount_) LpTokensStorage(pact_) StagesStorage(totalRewardAmount_) public {}

////////////////////////////////////////////////////////////

    struct PoolInfoInFarmStage {
        uint256 lastRewardBlock;    // Last block number that ERC20s distribution occurs.
        uint256 accERC20PerShare;   // Accumulated ERC20s per share, times 1e36.
    }
    // stageId => poolId => PoolInfoInFarmStage
    mapping (uint256 => mapping (uint256 => PoolInfoInFarmStage)) public _poolInfoInFarmStages;

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        for (uint256 poolId = 0; poolId < _poolInfoCount; ++poolId) {
            updatePool(poolId);
        }
    }

    // poolId => firstNotFinishedStage
    mapping (uint256 => uint256) _firstNotFinishedStages;

    function updatePool(uint256 poolId) public {
        require(poolId < _poolInfoCount, "updatePool: Pool is not exists");
        PoolInfo storage pool = _poolInfo[poolId];
        _updatePool(pool);
    }
    function _updatePool(PoolInfo storage pool) internal {
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));

        StageInfo storage stage;
        for (uint256 stageId = _firstNotFinishedStages[pool.id]; stageId < _stageInfoCount; ++stageId) {
            stage = _stageInfo[stageId];

            if (stage.startBlock > block.number) {
                return;
            }

            if (_updatePoolInfoInFarmStage(stage, pool, lpSupply)) {
                _firstNotFinishedStages[pool.id] = stageId.add(1);
            }
        }
    }
    function _updatePoolInfoInFarmStage(
        StageInfo storage stage,
        PoolInfo storage pool,
        uint256 lpSupply
    ) internal returns (bool) {
        uint256 lastBlock = block.number < stage.endBlock ? block.number : stage.endBlock;

        PoolInfoInFarmStage storage poolInFarmStage = _poolInfoInFarmStages[stage.id][pool.id];
        if (poolInFarmStage.lastRewardBlock < stage.startBlock) {
            poolInFarmStage.lastRewardBlock = stage.startBlock;
        }

        if (lastBlock <= poolInFarmStage.lastRewardBlock) {
            return true;
        }

        if (lpSupply == 0) {
            poolInFarmStage.lastRewardBlock = lastBlock;
            return false;
        }

        uint256 nrOfBlocks = lastBlock.sub(poolInFarmStage.lastRewardBlock);
        uint256 erc20Reward = nrOfBlocks.mul(stage.rewardPerBlock).mul(pool.allocPoint).div(_totalAllocPoint);

        poolInFarmStage.accERC20PerShare = poolInFarmStage.accERC20PerShare.add(erc20Reward.mul(1e36).div(lpSupply));
        poolInFarmStage.lastRewardBlock = block.number;
        return false;
    }

////////////////////////////////////////////////////////////

    function pending(uint256 poolId, address account) external view returns (uint256) {
        require(poolId < _poolInfoCount, "pending: Pool is not exists");
        PoolInfo storage pool = _poolInfo[poolId];
        UserInfo storage user = _userInfo[poolId][account];
        uint256 rewardPending = user.rewardPending;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));

        for (uint256 stageId = 0; stageId < _stageInfoCount; ++stageId) {
            StageInfo storage stage = _stageInfo[stageId];

            if (stage.startBlock > block.number) {
                break;
            }

            PoolInfoInFarmStage storage poolInFarmStage = _poolInfoInFarmStages[stageId][poolId];

            uint256 accERC20PerShare = poolInFarmStage.accERC20PerShare;
            uint256 lastBlock = block.number < stage.endBlock ? block.number : stage.endBlock;

            if (lastBlock > poolInFarmStage.lastRewardBlock && lpSupply != 0) {
                uint256 startBlock = poolInFarmStage.lastRewardBlock < stage.startBlock ? stage.startBlock : poolInFarmStage.lastRewardBlock;

                uint256 nrOfBlocks = lastBlock.sub(startBlock);
                uint256 erc20Reward = nrOfBlocks.mul(stage.rewardPerBlock).mul(pool.allocPoint).div(_totalAllocPoint);

                accERC20PerShare = accERC20PerShare.add(erc20Reward.mul(1e36).div(lpSupply));
            }

            uint256 pendingAmount = user.amount.mul(accERC20PerShare).div(1e36).sub(_userRewardDebt[stageId][poolId][account]);
            rewardPending = rewardPending.add(pendingAmount);
        }

        return rewardPending;
    }

////////////////////////////////////////////////////////////

    function _addLpToken(uint256 allocPoint, IUniswapV2Pair lpToken, bool withUpdate) internal {
        if (withUpdate) {
            massUpdatePools();
        }
        _addLpToken(allocPoint, lpToken);
    }

    function _updateLpToken(uint256 poolId, uint256 allocPoint, bool withUpdate) internal {
        if (withUpdate) {
            massUpdatePools();
        }
        _updateLpToken(poolId, allocPoint);
    }

////////////////////////////////////////////////////////////

    uint256 _totalRewardPending;

    // stageId => poolId => account => userRewardDebt
    mapping (uint256 => mapping (uint256 => mapping (address => uint256))) public _userRewardDebt;

    function _beforeBalanceChange(PoolInfo storage pool, address account) internal virtual override {
        _updatePool(pool);
        UserInfo storage user = _userInfo[pool.id][account];

        StageInfo storage stage;
        for (uint256 stageId = 0; stageId < _stageInfoCount; ++stageId) {
            stage = _stageInfo[stageId];
            if (stage.startBlock > block.number) {
                return;
            }
            PoolInfoInFarmStage storage poolInFarmStage = _poolInfoInFarmStages[stage.id][pool.id];

            uint256 pendingAmount = user.amount
                .mul(poolInFarmStage.accERC20PerShare)
                .div(1e36)
                .sub(_userRewardDebt[stage.id][pool.id][account]);

            user.rewardPending = user.rewardPending.add(pendingAmount);
            _totalRewardPending = _totalRewardPending.add(pendingAmount);
        }
    }
    function _afterBalanceChange(PoolInfo storage pool, address account) internal virtual override {
        UserInfo storage user = _userInfo[pool.id][account];

        StageInfo storage stage;
        for (uint256 stageId = 0; stageId < _stageInfoCount; ++stageId) {
            stage = _stageInfo[stageId];
            if (stage.startBlock > block.number) {
                return;
            }

            PoolInfoInFarmStage storage poolInFarmStage = _poolInfoInFarmStages[stage.id][pool.id];
            _userRewardDebt[stage.id][pool.id][account] = user.amount.mul(poolInFarmStage.accERC20PerShare).div(1e36);
        }
    }

    function _updateUserRewardDebtAndPending(PoolInfo storage pool, address account) internal {
        _updatePool(pool);
        UserInfo storage user = _userInfo[pool.id][account];

        StageInfo storage stage;
        for (uint256 stageId = 0; stageId < _stageInfoCount; ++stageId) {
            stage = _stageInfo[stageId];
            if (stage.startBlock > block.number) {
                return;
            }
            PoolInfoInFarmStage storage poolInFarmStage = _poolInfoInFarmStages[stage.id][pool.id];

            uint256 pendingAmount = user.amount
                .mul(poolInFarmStage.accERC20PerShare)
                .div(1e36)
                .sub(_userRewardDebt[stage.id][pool.id][account])
            ;

            user.rewardPending = user.rewardPending.add(pendingAmount);
            _totalRewardPending = _totalRewardPending.add(pendingAmount);
            _userRewardDebt[stage.id][pool.id][account] = user.amount.mul(poolInFarmStage.accERC20PerShare).div(1e36);
        }
    }

////////////////////////////////////////////////////////////

    event Harvest(address indexed user, uint256 indexed poolId, uint256 amount);
    // Withdraw LP tokens from Farm.
    function withdrawAndHarvest(uint256 poolId, uint256 amount) public {
        require(poolId < _poolInfoCount, "withdrawAndHarvest: Pool is not exists");
        PoolInfo storage pool = _poolInfo[poolId];
        require(amount > 0, "withdrawAndHarvest: can't withdraw zero amount");
        UserInfo storage user = _userInfo[poolId][msg.sender];
        require(user.amount >= amount, "withdrawAndHarvest: can't withdraw more than deposit");

        _beforeBalanceChange(pool, msg.sender);

        user.amount = user.amount.sub(amount);
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        emit Withdraw(msg.sender, poolId, amount);

        _pact.transfer(msg.sender, user.rewardPending);
        _totalRewardPending = _totalRewardPending.sub(user.rewardPending);

        emit Harvest(msg.sender, poolId, user.rewardPending);
        user.rewardPending = 0;

        _afterBalanceChange(pool, msg.sender);
    }
    // Harvest PACTs from Farm.
    function harvest(uint256 poolId) public {
        require(poolId < _poolInfoCount, "harvest: Pool is not exists");
        PoolInfo storage pool = _poolInfo[poolId];
        UserInfo storage user = _userInfo[poolId][msg.sender];
        require(user.userExists, "harvest: can't harvest from new user");

        _updateUserRewardDebtAndPending(pool, msg.sender);

        _pact.transfer(msg.sender, user.rewardPending);
        _totalRewardPending = _totalRewardPending.sub(user.rewardPending);

        emit Harvest(msg.sender, poolId, user.rewardPending);
        user.rewardPending = 0;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./AbstractFarm.sol";
import "../vendors/libraries/SafeMath.sol";
import "../vendors/contracts/access/GovernanceOwnable.sol";

// Cloned and modified from https://github.com/ltonetwork/uniswap-farming/blob/master/contracts/Farm.sol
contract FarmPACT is GovernanceOwnable, AbstractFarm {
    using SafeMath for uint256;

    uint256 _blockGenerationFrequency;
    function blockGenerationFrequency() public view returns (uint256) {
        return _blockGenerationFrequency;
    }

    // etherium - block_generation_frequency_ ~ 15s
    // binance smart chain - block_generation_frequency_ ~ 4s
    constructor(
        address governance_,
        IERC20 pact_,
        uint256 blockGenerationFrequency_,
        uint256 totalRewardAmount_
    ) GovernanceOwnable(governance_) AbstractFarm(pact_, totalRewardAmount_) public {
        require(blockGenerationFrequency_ > 0, "constructor: blockGenerationFrequency is empty");
        _blockGenerationFrequency = blockGenerationFrequency_;
    }

    function startFarming(uint256 startBlock) public onlyGovernance {
        require(_lastStageEndBlock == 0, "startFarming: already started");
        uint currentBalance = _pact.balanceOf(address(this));
        require(currentBalance >= _totalRewardAmount, "startFarming: currentBalance is not enough");

        _addFirstStage(startBlock, 10 days / _blockGenerationFrequency, _totalRewardAmount / 8);
        _addStage(20 days / _blockGenerationFrequency, _totalRewardAmount / 8);
        _addStage(150 days / _blockGenerationFrequency, _totalRewardAmount / 8);
        _addStage(180 days / _blockGenerationFrequency, _totalRewardAmount / 8);
        _addStage(1080 days / _blockGenerationFrequency, _totalRewardAmount / 2);
    }

    function addLpToken(uint256 _allocPoint, address _lpToken, bool _withUpdate) public onlyGovernance {
        _addLpToken(_allocPoint, IUniswapV2Pair(_lpToken), _withUpdate);
    }

    function updateLpToken(uint256 poolId, uint256 allocPoint, bool withUpdate) public onlyGovernance {
        _updateLpToken(poolId, allocPoint, withUpdate);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../vendors/libraries/SafeMath.sol";
import "../vendors/interfaces/IERC20.sol";
import "../vendors/interfaces/IUniswapV2Pair.sol";

abstract contract LpTokensStorage {
    using SafeMath for uint256;

    // Address of the ERC20 Token contract.
    IERC20 _pact;
    constructor(IERC20 pact_) public {
        require(address(pact_) != address(0), "LpTokensStorage::constructor: pact_ - is empty");
        _pact = pact_;
    }

    function pact() public view returns (address) {
        return address(_pact);
    }

    struct PoolInfo {
        uint256 id;
        IUniswapV2Pair lpToken;    // Address of LP token contract.
        uint256 allocPoint;         // How many allocation points assigned to this pool. ERC20s to distribute per block.
    }
    // poolId => PoolInfo
    PoolInfo[] _poolInfo;
    uint256 _poolInfoCount = 0;
    mapping (address => bool) _lpTokensList;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 _totalAllocPoint = 0;


    function poolInfoCount() public view returns (uint256) {
        return _poolInfoCount;
    }
    function poolInfo(uint256 poolId) public view returns (PoolInfo memory) {
        return _poolInfo[poolId];
    }
    function totalAllocPoint() public view returns (uint256) {
        return _totalAllocPoint;
    }

    function _addLpToken(uint256 allocPoint, IUniswapV2Pair lpToken) internal {
        require(_lpTokensList[address(lpToken)] == false, "_addLpToken: LP Token exists");

        _totalAllocPoint = _totalAllocPoint.add(allocPoint);

        _poolInfo.push(PoolInfo({
            id: _poolInfoCount,
            lpToken: lpToken,
            allocPoint: allocPoint
        }));
        ++_poolInfoCount;
        _lpTokensList[address(lpToken)] = true;
    }

    function _updateLpToken(uint256 poolId, uint256 allocPoint) internal {
        require(poolId < _poolInfoCount, "_updateLpToken: Pool is not exists");
        PoolInfo storage pool = _poolInfo[poolId];

        _totalAllocPoint = _totalAllocPoint.sub(pool.allocPoint).add(allocPoint);
        pool.allocPoint = allocPoint;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../vendors/libraries/SafeMath.sol";

abstract contract StagesStorage {
    using SafeMath for uint256;

    uint256 _totalRewardAmount;
    function totalRewardAmount() public view returns (uint256) {
        return _totalRewardAmount;
    }

    constructor(
        uint256 totalRewardAmount_
    ) public {
        require(totalRewardAmount_ > 0, "constructor: totalRewardAmount is empty");
        _totalRewardAmount = totalRewardAmount_;
    }

    struct StageInfo {
        uint256 id;
        uint256 startBlock;
        uint256 endBlock;
        uint256 rewardPerBlock;
    }
    // stageId => StageInfo
    StageInfo[] _stageInfo;
    uint256 _stageInfoCount = 0;
    uint256 _totalRewardInStages;
    uint256 _lastStageEndBlock;

    function stageInfo(uint256 stageId) public view returns (StageInfo memory) {
        return _stageInfo[stageId];
    }
    function stageInfoCount() public view returns (uint256) {
        return _stageInfoCount;
    }
    function totalRewardInStages() public view returns (uint256) {
        return _totalRewardInStages;
    }

    function _addFirstStage(
        uint256 startBlock,
        uint256 periodInBlocks,
        uint256 rewardAmount
    ) internal {
        require(_lastStageEndBlock == 0, "_addFirstStage: first stage is already installed");
        startBlock = block.number > startBlock ? block.number : startBlock;
        __addStage(
            startBlock,
            periodInBlocks,
            rewardAmount
        );
    }

    function _addStage(
        uint256 periodInBlocks,
        uint256 rewardAmount
    ) internal {
        require(_lastStageEndBlock > 0, "_addStage: first stage is not installed yet");
        __addStage(
            _lastStageEndBlock,
            periodInBlocks,
            rewardAmount
        );
    }

    function __addStage(
        uint256 startBlock,
        uint256 periodInBlocks,
        uint256 rewardAmount
    ) private {
        StageInfo memory newStage = StageInfo({
            id: _stageInfoCount,
            startBlock: startBlock,
            endBlock: startBlock.add(periodInBlocks),
            rewardPerBlock: rewardAmount.div(periodInBlocks)
        });
        ++_stageInfoCount;
        _stageInfo.push(newStage);

        _lastStageEndBlock = newStage.endBlock.add(1);
        _totalRewardInStages = _totalRewardInStages.add(rewardAmount);
        require(_totalRewardInStages <= _totalRewardAmount, "__addStage: _totalRewardInStages > _totalRewardAmount");
    }

    function stagesLength() external view returns (uint256) {
        return _stageInfo.length;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../vendors/libraries/SafeMath.sol";
import "../vendors/libraries/SafeERC20.sol";
import "../vendors/interfaces/IUniswapV2Pair.sol";
import "./LpTokensStorage.sol";

abstract contract UsersStorage is LpTokensStorage {
    using SafeMath for uint256;
    using SafeERC20 for IUniswapV2Pair;

    struct UserInfo {
        bool userExists;
        uint256 amount;
        uint256 rewardPending;
    }
    // poolId => account => UserInfo
    mapping (uint256 => mapping (address => UserInfo)) public _userInfo;

    event Deposit(address indexed user, uint256 indexed poolId, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed poolId, uint256 amount);

    // Deposit LP tokens to Farm for ERC20 allocation.
    function deposit(uint256 poolId, uint256 amount) public {
        require(poolId < _poolInfoCount, "deposit: Pool is not exists");
        PoolInfo storage pool = _poolInfo[poolId];
        require(amount > 0, "deposit: can't deposit zero amount");
        UserInfo storage user = _userInfo[poolId][msg.sender];
        user.userExists = true;

        _beforeBalanceChange(pool, msg.sender);

        user.amount = user.amount.add(amount);
        pool.lpToken.safeTransferFrom(address(msg.sender), amount);
        emit Deposit(msg.sender, poolId, amount);

        _afterBalanceChange(pool, msg.sender);
    }
    // Withdraw LP tokens from Farm.
    function withdraw(uint256 poolId, uint256 amount) public {
        require(poolId < _poolInfoCount, "withdraw: Pool is not exists");
        PoolInfo storage pool = _poolInfo[poolId];
        require(amount > 0, "withdraw: can't withdraw zero amount");
        UserInfo storage user = _userInfo[poolId][msg.sender];
        require(user.amount >= amount, "withdraw: can't withdraw more than deposit");

        _beforeBalanceChange(pool, msg.sender);

        user.amount = user.amount.sub(amount);
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        emit Withdraw(msg.sender, poolId, amount);

        _afterBalanceChange(pool, msg.sender);
    }
    function _beforeBalanceChange(PoolInfo storage pool, address account) internal virtual {}
    function _afterBalanceChange(PoolInfo storage pool, address account) internal virtual {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "../../interfaces/IGovernanceOwnable.sol";

abstract contract GovernanceOwnable is IGovernanceOwnable {
    address private _governanceAddress;

    event GovernanceSetTransferred(address indexed previousGovernance, address indexed newGovernance);

    constructor (address governance_) public {
        require(governance_ != address(0), "Governance address should be not null");
        _governanceAddress = governance_;
        emit GovernanceSetTransferred(address(0), governance_);
    }

    /**
     * @dev Returns the address of the current governanceAddress.
     */
    function governance() public view override returns (address) {
        return _governanceAddress;
    }

    /**
     * @dev Throws if called by any account other than the governanceAddress.
     */
    modifier onlyGovernance() {
        require(_governanceAddress == msg.sender, "Governance: caller is not the governance");
        _;
    }

    /**
     * @dev SetGovernance of the contract to a new account (`newGovernance`).
     * Can only be called by the current onlyGovernance.
     */
    function setGovernance(address newGovernance) public virtual override onlyGovernance {
        require(newGovernance != address(0), "GovernanceOwnable: new governance is the zero address");
        emit GovernanceSetTransferred(_governanceAddress, newGovernance);
        _governanceAddress = newGovernance;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);

    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function approve(address spender, uint tokens) external returns (bool success);
    function transfer(address to, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;


interface IGovernanceOwnable {
    event GovernanceSetTransferred(address indexed previousGovernance, address indexed newGovernance);

    function governance() external view returns (address);
    function setGovernance(address newGovernance) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IERC20.sol";

interface IUniswapV2ERC20 is IERC20 {
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IUniswapV2ERC20.sol";

interface IUniswapV2Pair is IUniswapV2ERC20 {
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

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "../interfaces/IERC20.sol";

library SafeERC20 {
    function safeSymbol(IERC20 token) internal view returns(string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x95d89b41));
        return success && data.length > 0 ? abi.decode(data, (string)) : "???";
    }

    function safeName(IERC20 token) internal view returns(string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x06fdde03));
        return success && data.length > 0 ? abi.decode(data, (string)) : "???";
    }

    function safeDecimals(IERC20 token) public view returns (uint8) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x313ce567));
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }

    function safeTransfer(IERC20 token, address to, uint256 amount) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0xa9059cbb, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "SafeERC20: Transfer failed");
    }

    function safeApprove(IERC20 token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransferFrom(IERC20 token, address from, uint256 amount) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0x23b872dd, from, address(this), amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "SafeERC20: TransferFrom failed");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return add(a, b, "SafeMath: Add Overflow");
    }
    function add(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);// "SafeMath: Add Overflow"

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: Underflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;// "SafeMath: Underflow"

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return mul(a, b, "SafeMath: Mul Overflow");
    }
    function mul(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, errorMessage);// "SafeMath: Mul Overflow"

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

