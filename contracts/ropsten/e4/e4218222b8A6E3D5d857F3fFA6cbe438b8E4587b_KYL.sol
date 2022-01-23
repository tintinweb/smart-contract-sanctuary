// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library AttoDecimal {
    using SafeMath for uint256;

    struct Instance {
        uint256 mantissa;
    }

    uint256 internal constant BASE = 10;
    uint256 internal constant EXPONENTIATION = 18;
    uint256 internal constant ONE_MANTISSA = BASE**EXPONENTIATION;
    uint256 internal constant ONE_TENTH_MANTISSA = ONE_MANTISSA / 10;
    uint256 internal constant HALF_MANTISSA = ONE_MANTISSA / 2;
    uint256 internal constant SQUARED_ONE_MANTISSA = ONE_MANTISSA * ONE_MANTISSA;
    uint256 internal constant MAX_INTEGER = type(uint128).max / ONE_MANTISSA;

    function maximum() internal pure returns (Instance memory) {
        return Instance({mantissa: type(uint128).max});
    }

    function zero() internal pure returns (Instance memory) {
        return Instance({mantissa: 0});
    }

    function one() internal pure returns (Instance memory) {
        return Instance({mantissa: ONE_MANTISSA});
    }

    function convert(uint256 integer) internal pure returns (Instance memory) {
        return Instance({mantissa: integer.mul(ONE_MANTISSA)});
    }

    function compare(Instance memory a, Instance memory b) internal pure returns (int8) {
        if (a.mantissa < b.mantissa) return -1;
        return int8(a.mantissa > b.mantissa ? 1 : 0);
    }

    function compare(Instance memory a, uint256 b) internal pure returns (int8) {
        return compare(a, convert(b));
    }

    function add(Instance memory a, Instance memory b) internal pure returns (Instance memory) {
        return Instance({mantissa: a.mantissa.add(b.mantissa)});
    }

    function add(Instance memory a, uint256 b) internal pure returns (Instance memory) {
        return Instance({mantissa: a.mantissa.add(b.mul(ONE_MANTISSA))});
    }

    function sub(Instance memory a, Instance memory b) internal pure returns (Instance memory) {
        return Instance({mantissa: a.mantissa.sub(b.mantissa)});
    }

    function sub(Instance memory a, uint256 b) internal pure returns (Instance memory) {
        return Instance({mantissa: a.mantissa.sub(b.mul(ONE_MANTISSA))});
    }

    function sub(uint256 a, Instance memory b) internal pure returns (Instance memory) {
        return Instance({mantissa: a.mul(ONE_MANTISSA).sub(b.mantissa)});
    }

    function mul(Instance memory a, Instance memory b) internal pure returns (Instance memory) {
        return Instance({mantissa: a.mantissa.mul(b.mantissa) / ONE_MANTISSA});
    }

    function mul(Instance memory a, uint256 b) internal pure returns (Instance memory) {
        return Instance({mantissa: a.mantissa.mul(b)});
    }

    function div(Instance memory a, Instance memory b) internal pure returns (Instance memory) {
        return Instance({mantissa: a.mantissa.mul(ONE_MANTISSA).div(b.mantissa)});
    }

    function div(Instance memory a, uint256 b) internal pure returns (Instance memory) {
        return Instance({mantissa: a.mantissa.mul(ONE_MANTISSA).div(b)});
    }

    function div(uint256 a, Instance memory b) internal pure returns (Instance memory) {
        return Instance({mantissa: a.mul(SQUARED_ONE_MANTISSA).div(b.mantissa)});
    }

    function div(uint256 a, uint256 b) internal pure returns (Instance memory) {
        return Instance({mantissa: a.mul(ONE_MANTISSA).div(b)});
    }

    function idiv(Instance memory a, Instance memory b) internal pure returns (uint256) {
        return a.mantissa.div(b.mantissa);
    }

    function idiv(Instance memory a, uint256 b) internal pure returns (uint256) {
        return a.mantissa.div(b.mul(ONE_MANTISSA));
    }

    function idiv(uint256 a, Instance memory b) internal pure returns (uint256) {
        return a.mul(ONE_MANTISSA).div(b.mantissa);
    }

    function mod(Instance memory a, Instance memory b) internal pure returns (Instance memory) {
        return Instance({mantissa: a.mantissa.mod(b.mantissa)});
    }

    function mod(Instance memory a, uint256 b) internal pure returns (Instance memory) {
        return Instance({mantissa: a.mantissa.mod(b.mul(ONE_MANTISSA))});
    }

    function mod(uint256 a, Instance memory b) internal pure returns (Instance memory) {
        if (a > MAX_INTEGER) return Instance({mantissa: a.mod(b.mantissa).mul(ONE_MANTISSA) % b.mantissa});
        return Instance({mantissa: a.mul(ONE_MANTISSA).mod(b.mantissa)});
    }

    function floor(Instance memory a) internal pure returns (uint256) {
        return a.mantissa / ONE_MANTISSA;
    }

    function ceil(Instance memory a) internal pure returns (uint256) {
        return (a.mantissa / ONE_MANTISSA) + (a.mantissa % ONE_MANTISSA > 0 ? 1 : 0);
    }

    function round(Instance memory a) internal pure returns (uint256) {
        return (a.mantissa / ONE_MANTISSA) + ((a.mantissa / ONE_TENTH_MANTISSA) % 10 >= 5 ? 1 : 0);
    }

    function eq(Instance memory a, Instance memory b) internal pure returns (bool) {
        return a.mantissa == b.mantissa;
    }

    function eq(Instance memory a, uint256 b) internal pure returns (bool) {
        if (b > MAX_INTEGER) return false;
        return a.mantissa == b * ONE_MANTISSA;
    }

    function gt(Instance memory a, Instance memory b) internal pure returns (bool) {
        return a.mantissa > b.mantissa;
    }

    function gt(Instance memory a, uint256 b) internal pure returns (bool) {
        if (b > MAX_INTEGER) return false;
        return a.mantissa > b * ONE_MANTISSA;
    }

    function gte(Instance memory a, Instance memory b) internal pure returns (bool) {
        return a.mantissa >= b.mantissa;
    }

    function gte(Instance memory a, uint256 b) internal pure returns (bool) {
        if (b > MAX_INTEGER) return false;
        return a.mantissa >= b * ONE_MANTISSA;
    }

    function lt(Instance memory a, Instance memory b) internal pure returns (bool) {
        return a.mantissa < b.mantissa;
    }

    function lt(Instance memory a, uint256 b) internal pure returns (bool) {
        if (b > MAX_INTEGER) return true;
        return a.mantissa < b * ONE_MANTISSA;
    }

    function lte(Instance memory a, Instance memory b) internal pure returns (bool) {
        return a.mantissa <= b.mantissa;
    }

    function lte(Instance memory a, uint256 b) internal pure returns (bool) {
        if (b > MAX_INTEGER) return true;
        return a.mantissa <= b * ONE_MANTISSA;
    }

    function isInteger(Instance memory a) internal pure returns (bool) {
        return a.mantissa % ONE_MANTISSA == 0;
    }

    function isPositive(Instance memory a) internal pure returns (bool) {
        return a.mantissa > 0;
    }

    function isZero(Instance memory a) internal pure returns (bool) {
        return a.mantissa == 0;
    }

    function sum(Instance[] memory array) internal pure returns (Instance memory result) {
        uint256 length = array.length;
        for (uint256 index = 0; index < length; index++) result = add(result, array[index]);
    }

    function toTuple(Instance memory a)
        internal
        pure
        returns (
            uint256 mantissa,
            uint256 base,
            uint256 exponentiation
        )
    {
        return (a.mantissa, BASE, EXPONENTIATION);
    }
}

abstract contract TwoStageOwnable {
    address private _nominatedOwner;
    address private _owner;

    function nominatedOwner() public view returns (address) {
        return _nominatedOwner;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    event OwnerChanged(address indexed newOwner);
    event OwnerNominated(address indexed nominatedOwner);

    constructor(address owner_) internal {
        require(owner_ != address(0), "Owner is zero");
        _setOwner(owner_);
    }

    function acceptOwnership() external returns (bool success) {
        require(msg.sender == _nominatedOwner, "Not nominated to ownership");
        _setOwner(_nominatedOwner);
        return true;
    }

    function nominateNewOwner(address owner_) external onlyOwner returns (bool success) {
        _nominateNewOwner(owner_);
        return true;
    }

    modifier onlyOwner {
        require(msg.sender == _owner, "Not owner");
        _;
    }

    function _nominateNewOwner(address owner_) internal {
        if (_nominatedOwner == owner_) return;
        require(_owner != owner_, "Already owner");
        _nominatedOwner = owner_;
        emit OwnerNominated(owner_);
    }

    function _setOwner(address newOwner) internal {
        if (_owner == newOwner) return;
        _owner = newOwner;
        _nominatedOwner = address(0);
        emit OwnerChanged(newOwner);
    }
}


contract KYL is ERC20, ReentrancyGuard, TwoStageOwnable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using AttoDecimal for AttoDecimal.Instance;

    struct Strategy {
        uint256 endBlockNumber;
        uint256 perBlockReward;
        uint256 startBlockNumber;
    }

    struct Unstake {
        uint256 amount;
        uint256 applicableAt;
    }

    uint256 public constant MIN_STAKE_BALANCE = 10**18;

    uint256 public claimingFeePercent;
    uint256 public lastUpdateBlockNumber;

    uint256 private _feePool;
    uint256 private _lockedRewards;
    uint256 private _totalStaked;
    uint256 private _totalUnstaked;
    uint256 private _unstakingTime;
    IERC20 private _stakingToken;

    AttoDecimal.Instance private _defaultPrice;
    AttoDecimal.Instance private _price;
    Strategy private _currentStrategy;
    Strategy private _nextStrategy;

    mapping(address => Unstake) private _unstakes;

    function getBlockNumber() internal view virtual returns (uint256) {
        return block.number;
    }

    function getTimestamp() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    function feePool() public view returns (uint256) {
        return _feePool;
    }

    function lockedRewards() public view returns (uint256) {
        return _lockedRewards;
    }

    function totalStaked() public view returns (uint256) {
        return _totalStaked;
    }

    function totalUnstaked() public view returns (uint256) {
        return _totalUnstaked;
    }

    function stakingToken() public view returns (IERC20) {
        return _stakingToken;
    }

    function unstakingTime() public view returns (uint256) {
        return _unstakingTime;
    }

    function currentStrategy() public view returns (Strategy memory) {
        return _currentStrategy;
    }

    function nextStrategy() public view returns (Strategy memory) {
        return _nextStrategy;
    }

    function getUnstake(address account) public view returns (Unstake memory result) {
        result = _unstakes[account];
    }

    function defaultPrice()
        external
        view
        returns (
            uint256 mantissa,
            uint256 base,
            uint256 exponentiation
        )
    {
        return _defaultPrice.toTuple();
    }

    function getCurrentStrategyUnlockedRewards() public view returns (uint256 unlocked) {
        unlocked = _getStrategyUnlockedRewards(_currentStrategy);
    }

    function getUnlockedRewards() public view returns (uint256 unlocked, bool currentStrategyEnded) {
        unlocked = _getStrategyUnlockedRewards(_currentStrategy);
        if (getBlockNumber() >= _currentStrategy.endBlockNumber) {
            currentStrategyEnded = true;
            if (_nextStrategy.endBlockNumber != 0) unlocked = unlocked.add(_getStrategyUnlockedRewards(_nextStrategy));
        }
    }

    /// @notice Calculates price of synthetic token for current block
    function price()
        public
        view
        returns (
            uint256 mantissa,
            uint256 base,
            uint256 exponentiation
        )
    {
        (uint256 unlocked, ) = getUnlockedRewards();
        uint256 totalStaked_ = _totalStaked;
        uint256 totalSupply_ = totalSupply();
        AttoDecimal.Instance memory result = _defaultPrice;
        if (totalSupply_ > 0) result = AttoDecimal.div(totalStaked_.add(unlocked), totalSupply_);
        return result.toTuple();
    }

    /// @notice Returns last updated price of synthetic token
    function priceStored()
        public
        view
        returns (
            uint256 mantissa,
            uint256 base,
            uint256 exponentiation
        )
    {
        return _price.toTuple();
    }

    /// @notice Calculates expected result of swapping synthetic tokens for staking tokens
    /// @param account Account that wants to swap
    /// @param amount Minimum amount of staking tokens that should be received at swapping process
    /// @return unstakedAmount Amount of staking tokens that should be received at swapping process
    /// @return burnedAmount Amount of synthetic tokens that should be burned at swapping process
    function calculateUnstake(address account, uint256 amount)
        public
        view
        returns (uint256 unstakedAmount, uint256 burnedAmount)
    {
        (uint256 mantissa_, , ) = price();
        return _calculateUnstake(account, amount, AttoDecimal.Instance(mantissa_));
    }

    event Claimed(
        address indexed account,
        uint256 requestedAmount,
        uint256 claimedAmount,
        uint256 feeAmount,
        uint256 burnedAmount
    );

    event ClaimingFeePercentUpdated(uint256 feePercent);
    event CurrentStrategyUpdated(uint256 perBlockReward, uint256 startBlockNumber, uint256 endBlockNumber);
    event FeeClaimed(address indexed receiver, uint256 amount);

    event Migrated(
        address indexed account,
        uint256 omTokenV1StakeAmount,
        uint256 stakingPoolV1Reward,
        uint256 stakingPoolV2Reward
    );

    event NextStrategyUpdated(uint256 perBlockReward, uint256 startBlockNumber, uint256 endBlockNumber);
    event UnstakingTimeUpdated(uint256 unstakingTime);
    event NextStrategyRemoved();
    event PoolDecreased(uint256 amount);
    event PoolIncreased(address indexed payer, uint256 amount);
    event PriceUpdated(uint256 mantissa, uint256 base, uint256 exponentiation);
    event RewardsUnlocked(uint256 amount);
    event Staked(address indexed account, address indexed payer, uint256 stakedAmount, uint256 mintedAmount);
    event Unstaked(address indexed account, uint256 requestedAmount, uint256 unstakedAmount, uint256 burnedAmount);
    event UnstakingCanceled(address indexed account, uint256 amount);
    event Withdrawed(address indexed account, uint256 amount);

    constructor(
        string memory syntheticTokenName,
        string memory syntheticTokenSymbol,
        IERC20 stakingToken_,
        address owner_,
        uint256 claimingFeePercent_,
        uint256 perBlockReward_,
        uint256 startBlockNumber_,
        uint256 duration_,
        uint256 unstakingTime_,
        uint256 defaultPriceMantissa
    ) public TwoStageOwnable(owner_) ERC20(syntheticTokenName, syntheticTokenSymbol) {
        _defaultPrice = AttoDecimal.Instance(defaultPriceMantissa);
        _stakingToken = stakingToken_;
        _setClaimingFeePercent(claimingFeePercent_);
        _validateStrategyParameters(perBlockReward_, startBlockNumber_, duration_);
        _setUnstakingTime(unstakingTime_);
        _setCurrentStrategy(perBlockReward_, startBlockNumber_, startBlockNumber_.add(duration_));
        lastUpdateBlockNumber = getBlockNumber();
        _price = _defaultPrice;
    }

    /// @notice Cancels unstaking by staking locked for withdrawals tokens
    /// @param amount Amount of locked for withdrawals tokens
    function cancelUnstaking(uint256 amount) external onlyPositiveAmount(amount) returns (bool success) {
        _update();
        address caller = msg.sender;
        Unstake storage unstake_ = _unstakes[caller];
        uint256 unstakingAmount = unstake_.amount;
        require(unstakingAmount >= amount, "Not enough unstaked balance");
        uint256 stakedAmount = _price.mul(balanceOf(caller)).floor();
        require(stakedAmount.add(amount) >= MIN_STAKE_BALANCE, "Stake balance lt min stake");
        uint256 synthAmount = AttoDecimal.div(amount, _price).floor();
        _mint(caller, synthAmount);
        _totalStaked = _totalStaked.add(amount);
        _totalUnstaked = _totalUnstaked.sub(amount);
        unstake_.amount = unstakingAmount.sub(amount);
        emit Staked(caller, address(0), amount, synthAmount);
        emit UnstakingCanceled(caller, amount);
        return true;
    }

    /// @notice Swaps synthetic tokens for staking tokens and immediately sends them to the caller but takes some fee
    /// @param amount Staking tokens amount to swap for. Fee will be taked from this amount
    /// @return claimedAmount Amount of staking tokens that was been sended to caller
    /// @return burnedAmount Amount of synthetic tokens that was burned while swapping
    function claim(uint256 amount)
        external
        onlyPositiveAmount(amount)
        returns (uint256 claimedAmount, uint256 burnedAmount)
    {
        _update();
        address caller = msg.sender;
        (claimedAmount, burnedAmount) = _calculateUnstake(caller, amount, _price);
        uint256 fee = claimedAmount.mul(claimingFeePercent).div(100);
        _burn(caller, burnedAmount);
        _totalStaked = _totalStaked.sub(claimedAmount);
        claimedAmount = claimedAmount.sub(fee);
        _feePool = _feePool.add(fee);
        emit Claimed(caller, amount, claimedAmount, fee, burnedAmount);
        _stakingToken.safeTransfer(caller, claimedAmount);
    }

    /// @notice Withdraws all staking tokens, that have been accumulated in imidiatly claiming process.
    ///     Allowed to be called only by the owner
    /// @return amount Amount of accumulated and withdrawed tokens
    function claimFees() external onlyOwner returns (uint256 amount) {
        require(_feePool > 0, "No fees");
        amount = _feePool;
        _feePool = 0;
        emit FeeClaimed(owner(), amount);
        _stakingToken.safeTransfer(owner(), amount);
    }

    /// @notice Creates new strategy. Allowed to be called only by the owner
    /// @param perBlockReward_ Reward that should be added to common staking tokens pool every block
    /// @param startBlockNumber_ Number of block from which strategy should starts
    /// @param duration_ Blocks count for which new strategy should be applied
    function createNewStrategy(
        uint256 perBlockReward_,
        uint256 startBlockNumber_,
        uint256 duration_
    ) public onlyOwner returns (bool success) {
        _update();
        _validateStrategyParameters(perBlockReward_, startBlockNumber_, duration_);
        uint256 endBlockNumber = startBlockNumber_.add(duration_);
        Strategy memory strategy =
            Strategy({
                perBlockReward: perBlockReward_,
                startBlockNumber: startBlockNumber_,
                endBlockNumber: endBlockNumber
            });
        if (_currentStrategy.startBlockNumber > getBlockNumber()) {
            delete _nextStrategy;
            emit NextStrategyRemoved();
            _currentStrategy = strategy;
            emit CurrentStrategyUpdated(perBlockReward_, startBlockNumber_, endBlockNumber);
        } else {
            emit NextStrategyUpdated(perBlockReward_, startBlockNumber_, endBlockNumber);
            _nextStrategy = strategy;
            if (_currentStrategy.endBlockNumber > startBlockNumber_) {
                _currentStrategy.endBlockNumber = startBlockNumber_;
                emit CurrentStrategyUpdated(
                    _currentStrategy.perBlockReward,
                    _currentStrategy.startBlockNumber,
                    startBlockNumber_
                );
            }
        }
        return true;
    }

    function decreasePool(uint256 amount) external onlyPositiveAmount(amount) onlyOwner returns (bool success) {
        _update();
        _lockedRewards = _lockedRewards.sub(amount, "Not enough locked rewards");
        emit PoolDecreased(amount);
        _stakingToken.safeTransfer(owner(), amount);
        return true;
    }

    /// @notice Increases pool of rewards
    /// @param amount Amount of staking tokens (in wei) that should be added to rewards pool
    function increasePool(uint256 amount) external onlyPositiveAmount(amount) returns (bool success) {
        _update();
        address payer = msg.sender;
        _lockedRewards = _lockedRewards.add(amount);
        emit PoolIncreased(payer, amount);
        _stakingToken.safeTransferFrom(payer, address(this), amount);
        return true;
    }

    /// @notice Change claiming fee percent. Can be called only by the owner
    /// @param feePercent New claiming fee percent
    function setClaimingFeePercent(uint256 feePercent) external onlyOwner returns (bool success) {
        _setClaimingFeePercent(feePercent);
        return true;
    }

    /// @notice Converts staking tokens to synthetic tokens
    /// @param amount Amount of staking tokens to be swapped
    /// @return mintedAmount Amount of synthetic tokens that was received at swapping process
    function stake(uint256 amount) external onlyPositiveAmount(amount) returns (uint256 mintedAmount) {
        address staker = msg.sender;
        return _stake(staker, staker, amount);
    }

    /// @notice Converts staking tokens to synthetic tokens and sends them to specific account
    /// @param account Receiver of synthetic tokens
    /// @param amount Amount of staking tokens to be swapped
    /// @return mintedAmount Amount of synthetic tokens that was received by specified account at swapping process
    function stakeForUser(address account, uint256 amount)
        external
        onlyPositiveAmount(amount)
        returns (uint256 mintedAmount)
    {
        return _stake(account, msg.sender, amount);
    }

    /// @notice Swapes synthetic tokens for staking tokens and locks them for some period
    /// @param amount Minimum amount of staking tokens that should be locked after swapping process
    /// @return unstakedAmount Amount of staking tokens that was locked
    /// @return burnedAmount Amount of synthetic tokens that was burned
    function unstake(uint256 amount)
        external
        onlyPositiveAmount(amount)
        returns (uint256 unstakedAmount, uint256 burnedAmount)
    {
        _update();
        address caller = msg.sender;
        (unstakedAmount, burnedAmount) = _calculateUnstake(caller, amount, _price);
        _burn(caller, burnedAmount);
        _totalStaked = _totalStaked.sub(unstakedAmount);
        _totalUnstaked = _totalUnstaked.add(unstakedAmount);
        Unstake storage unstake_ = _unstakes[caller];
        unstake_.amount = unstake_.amount.add(unstakedAmount);
        unstake_.applicableAt = getTimestamp().add(_unstakingTime);
        emit Unstaked(caller, amount, unstakedAmount, burnedAmount);
    }

    /// @notice Updates price of synthetic token
    /// @dev Automatically has been called on every contract action, that uses or can affect price
    function update() external returns (bool success) {
        _update();
        return true;
    }

    /// @notice Withdraws unstaked staking tokens
    function withdraw() external returns (bool success) {
        address caller = msg.sender;
        Unstake storage unstake_ = _unstakes[caller];
        uint256 amount = unstake_.amount;
        require(amount > 0, "Not unstaked");
        require(unstake_.applicableAt <= getTimestamp(), "Not released at");
        delete _unstakes[caller];
        _totalUnstaked = _totalUnstaked.sub(amount);
        emit Withdrawed(caller, amount);
        _stakingToken.safeTransfer(caller, amount);
        return true;
    }

    /// @notice Change unstaking time. Can be called only by the owner
    /// @param unstakingTime_ New unstaking process duration in seconds
    function setUnstakingTime(uint256 unstakingTime_) external onlyOwner returns (bool success) {
        _setUnstakingTime(unstakingTime_);
        return true;
    }

    function _getStrategyUnlockedRewards(Strategy memory strategy_) internal view returns (uint256 unlocked) {
        uint256 currentBlockNumber = getBlockNumber();
        if (currentBlockNumber < strategy_.startBlockNumber || currentBlockNumber == lastUpdateBlockNumber) {
            return unlocked;
        }
        uint256 lastRewardedBlockNumber = Math.max(lastUpdateBlockNumber, strategy_.startBlockNumber);
        uint256 lastRewardableBlockNumber = Math.min(currentBlockNumber, strategy_.endBlockNumber);
        if (lastRewardedBlockNumber < lastRewardableBlockNumber) {
            uint256 blocksDiff = lastRewardableBlockNumber.sub(lastRewardedBlockNumber);
            unlocked = unlocked.add(blocksDiff.mul(strategy_.perBlockReward));
        }
    }

    function _calculateUnstake(
        address account,
        uint256 amount,
        AttoDecimal.Instance memory price_
    ) internal view returns (uint256 unstakedAmount, uint256 burnedAmount) {
        unstakedAmount = amount;
        burnedAmount = AttoDecimal.div(amount, price_).ceil();
        uint256 balance = balanceOf(account);
        require(burnedAmount > 0, "Too small unstaking amount");
        require(balance >= burnedAmount, "Not enough synthetic tokens");
        uint256 remainingSyntheticBalance = balance.sub(burnedAmount);
        uint256 remainingStake = _price.mul(remainingSyntheticBalance).floor();
        if (remainingStake < 10**18) {
            burnedAmount = balance;
            unstakedAmount = unstakedAmount.add(remainingStake);
        }
    }

    function _unlockRewardsAndStake() internal {
        (uint256 unlocked, bool currentStrategyEnded) = getUnlockedRewards();
        if (currentStrategyEnded) {
            _currentStrategy = _nextStrategy;
            emit NextStrategyRemoved();
            if (_currentStrategy.endBlockNumber != 0) {
                emit CurrentStrategyUpdated(
                    _currentStrategy.perBlockReward,
                    _currentStrategy.startBlockNumber,
                    _currentStrategy.endBlockNumber
                );
            }
            delete _nextStrategy;
        }
        unlocked = Math.min(unlocked, _lockedRewards);
        if (unlocked > 0) {
            emit RewardsUnlocked(unlocked);
            _lockedRewards = _lockedRewards.sub(unlocked);
            _totalStaked = _totalStaked.add(unlocked);
        }
        lastUpdateBlockNumber = getBlockNumber();
    }

    function _update() internal {
        if (getBlockNumber() <= lastUpdateBlockNumber) return;
        _unlockRewardsAndStake();
        _updatePrice();
    }

    function _updatePrice() internal {
        uint256 totalStaked_ = _totalStaked;
        uint256 totalSupply_ = totalSupply();
        if (totalSupply_ == 0) _price = _defaultPrice;
        else _price = AttoDecimal.div(totalStaked_, totalSupply_);
        emit PriceUpdated(_price.mantissa, AttoDecimal.BASE, AttoDecimal.EXPONENTIATION);
    }

    function _validateStrategyParameters(
        uint256 perBlockReward,
        uint256 startBlockNumber,
        uint256 duration
    ) internal view {
        require(duration > 0, "Duration is zero");
        require(startBlockNumber >= getBlockNumber(), "Start block number lt current");
        require(perBlockReward <= 188 * 10**18, "Per block reward overflow");
    }

    function _setClaimingFeePercent(uint256 feePercent) internal {
        require(feePercent >= 0 && feePercent <= 100, "Invalid fee percent");
        claimingFeePercent = feePercent;
        emit ClaimingFeePercentUpdated(feePercent);
    }

    function _setUnstakingTime(uint256 unstakingTime_) internal {
        _unstakingTime = unstakingTime_;
        emit UnstakingTimeUpdated(unstakingTime_);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        _update();
        string memory errorText = "Minimal stake balance should be more or equal to 1 token";
        if (from != address(0)) {
            uint256 fromNewBalance = _price.mul(balanceOf(from).sub(amount)).floor();
            require(fromNewBalance >= MIN_STAKE_BALANCE || fromNewBalance == 0, errorText);
        }
        if (to != address(0)) {
            require(_price.mul(balanceOf(to).add(amount)).floor() >= MIN_STAKE_BALANCE, errorText);
        }
    }

    function _setCurrentStrategy(
        uint256 perBlockReward_,
        uint256 startBlockNumber_,
        uint256 endBlockNumber_
    ) private {
        _currentStrategy = Strategy({
            perBlockReward: perBlockReward_,
            startBlockNumber: startBlockNumber_,
            endBlockNumber: endBlockNumber_
        });
        emit CurrentStrategyUpdated(perBlockReward_, startBlockNumber_, endBlockNumber_);
    }

    function _stake(
        address staker,
        address payer,
        uint256 amount
    ) private returns (uint256 mintedAmount) {
        _update();
        mintedAmount = AttoDecimal.div(amount, _price).floor();
        require(mintedAmount > 0, "Too small staking amount");
        _mint(staker, mintedAmount);
        _totalStaked = _totalStaked.add(amount);
        emit Staked(staker, payer, amount, mintedAmount);
        _stakingToken.safeTransferFrom(payer, address(this), amount);
    }

    modifier onlyPositiveAmount(uint256 amount) {
        require(amount > 0, "Amount is not positive");
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
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
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
     * by making the `nonReentrant` function external, and making it call a
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