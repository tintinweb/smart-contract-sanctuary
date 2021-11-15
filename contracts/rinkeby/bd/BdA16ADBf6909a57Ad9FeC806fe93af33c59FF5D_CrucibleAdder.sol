// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <=0.8.0;
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

library Constants {
    address constant uniV2FactoryAddress = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address constant uniV3FactoryAddress = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    IUniswapV2Factory constant uniV2Factory = IUniswapV2Factory(uniV2FactoryAddress);

    address constant uniV2Router02Address = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswapV2Router02 constant uniV2Router02 = IUniswapV2Router02(uniV2Router02Address);

    uint32 constant Future2100 = 4102448400;

    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <=0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library SafeAmount {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 amount) internal returns (uint256)  {
        uint256 preBalance = IERC20(token).balanceOf(to);
        IERC20(token).transferFrom(from, to, amount);
        uint256 postBalance = IERC20(token).balanceOf(to);
        return postBalance.sub(preBalance);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <=0.8.0;

import "../token/reshape/ReshapableERC20.sol";
import "../token/Taxable.sol";
import "../token/safety/TaxedLocker.sol";

/**
 * A reshapable token with programmable conversion ratio.
 * One conversion ratio at a time:
 * - For example, owner will set cap of 1M tokens.
 * This is also a taxable token.
 */
abstract contract Crucible is ReshapableERC20, Taxable, ILockerUser {
    using SafeMath for uint256;
    uint256 public defaultTaxRateOver1000;
    uint256 public mintTaxRateOver1000;
    ILocker public override locker;
    address public liquidityAdder;

    function setLiquidityAdder(address _liquidityAdder) external onlyOwner() {
        liquidityAdder = _liquidityAdder;
    }

    function setLocker(address _locker) external onlyOwner() {
        locker = ILocker(_locker);
        // ILocker(_locker).lockOrGetPenalty(msg.sender, address(this)); //verify can be called
    }

    function setDefaultTaxRate(uint256 _taxRateOver1000, uint256 _mintTaxOver1000)
    external onlyOwner() {
        defaultTaxRateOver1000 = _taxRateOver1000;
        mintTaxRateOver1000 = _mintTaxOver1000;
    }

    function _transfer(address sender, address recipient, uint256 amount)
    internal virtual override {
        return _transferWithTax(sender, recipient, amount);
    }

    function _transferWithTax(address sender, address recipient, uint256 amount)
    internal
    {
        require(amount < 2 ** 127, "ERC20: amount too large");
        if (sender == address(taxDistributor)) {
            // Short circuit to save gas
            _transferWithoutTax(sender, recipient, amount);
            return;
        }

        (bool shouldOverridePenalty, uint256 overridenPenaltyOver1000) = locker.lockOrGetPenalty(sender, recipient);
        // get the tax rate.
        uint256 taxRate = shouldOverridePenalty ? overridenPenaltyOver1000 : defaultTaxRateOver1000;
        if (taxRate != 0) {
            uint256 taxAmount = taxRate.mul(amount).div(1000);
            require(tax(sender, taxAmount), "ERC20: Could not apply tax");
            amount = amount.sub(taxAmount);
        }
        _transferWithoutTax(sender, recipient, amount);
    }

    function _transferWithoutTax(address sender, address recipient, uint256 amount)
    internal override {
        return ERC20._transfer(sender, recipient, amount);
    }

    function setRatio(address token, uint256 paddedRatio)
    external virtual override returns (bool) {
        require(msg.sender == liquidityAdder, "Crucible: Not allowed");
        _setRatio(token, paddedRatio);
        return true;
    }

    function deposit(address token, uint256 amount) external virtual override returns(uint256) {
        require(msg.sender == liquidityAdder || msg.sender == owner(), "Crucible: Not allowed");
        uint256 taxRate = mintTaxRateOver1000;
        if (taxRate != 0) {
            uint256 taxAmount = taxRate.mul(amount).div(1000);
            address _taxDistributor = address(taxDistributor);
            if (_taxDistributor != address(0)) {
                SafeAmount.safeTransferFrom(token, msg.sender, _taxDistributor, taxAmount);
                amount = amount.sub(taxAmount);
            }
        }
        return _deposit(msg.sender, msg.sender, token, amount);
    }
}

// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Crucible.sol";
import "../staking/IFestaked.sol";

/**
 * Adds liquidity based on provided parameters
 */
contract CrucibleAdder is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    mapping(address => uint256) public caps;
    mapping(address => uint256) public balances;
    mapping(address => address) public tokens;
    mapping(address => address) public pools;

    function mint(address crucible, uint256 amount, bool autoStake) external {
        require(crucible != address(0), "CrucibleAdder: Bad crucible");
        require(amount != 0, "CrucibleAdder: Bad amount");
        address token = tokens[crucible];
        require(token != address(0), "CrucibleAdder: Not configured");
        amount = SafeAmount.safeTransferFrom(token, msg.sender, address(this), amount);

        uint256 _cap = caps[crucible];
        uint256 _balance = balances[crucible];
        require(_cap == 0 || _balance < _cap, "CrucibleAdder: Cap filled");
        _balance = _balance.add(amount);
        uint256 refund = (_cap != 0 && _balance > _cap) ? _balance.sub(_cap) : 0;
        if (refund > 0) {
            IERC20(token).transfer(msg.sender, refund);
            _balance = _cap;
            amount = amount.sub(refund);
        }
        balances[crucible] = _balance;
        uint256 deposited = Crucible(crucible).deposit(token, amount);
        if (autoStake) {
            // @dev: make sure to add approvals for the crucible token befoer launch
            // IERC20(crucible).approve(address(stake), deposited);
            address stake = pools[crucible];
            require(stake != address(0), "CrucibleAdder: stake pool unconfigured");
            IFestaked(stake).stakeFor(msg.sender, deposited);
        } else {
            IERC20(crucible).transfer(msg.sender, deposited);
        }
    }

    function setCapAndRatio(address crucible, address token, uint256 cap, uint256 paddedRatio)
    external onlyOwner {
        caps[crucible] = cap;
        tokens[crucible] = token;
        Crucible(crucible).setRatio(token, paddedRatio);
    }

    function setStakingPool(address crucible, address stake) external onlyOwner {
        pools[crucible] = stake;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Ferrum Staking interface for adding reward
 */
interface IFestakeRewardManager {
    /**
     * @dev legacy add reward. To be used by contract support time limitted rewards.
     */
    function addReward(uint256 rewardAmount) external returns (bool);

    /**
     * @dev withdraw rewards for the user.
     * The only option is to withdraw all rewards is one go.
     */
    function withdrawRewards() external returns (uint256);

    /**
     * @dev marginal rewards is to be used by contracts supporting ongoing rewards.
     * Send the reward to the contract address first.
     */
    function addMarginalReward() external returns (bool);

    function rewardToken() external view returns (IERC20);

    function rewardsTotal() external view returns (uint256);

    /**
     * @dev returns current rewards for an address
     */
    function rewardOf(address addr) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <=0.8.0;

/**
 * @dev Ferrum Staking interface
 */
interface IFestaked {
    
    event Staked(address indexed token, address indexed staker_, uint256 requestedAmount_, uint256 stakedAmount_);

    function stake (uint256 amount) external returns (bool);

    function stakeFor (address staker, uint256 amount) external returns (bool);

    function stakeOf(address account) external view returns (uint256);

    function tokenAddress() external view returns (address);

    function stakedTotal() external view returns (uint256);

    function stakedBalance() external view returns (uint256);

    function stakingStarts() external view returns (uint256);

    function stakingEnds() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <=0.8.0;

import "./IFestakeRewardManager.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IRewardDistributor {
    function rollAndGetDistributionAddress(address addressForRandom) external view returns(address);
    function updateRewards(address target) external returns(bool);
}

contract RewardDistributor is Ownable, IRewardDistributor {
    struct RewardPools {
        bytes pools;
    }
    RewardPools rewardPools;
    address[] rewardReceivers;

    function addNewPool(address pool)
    onlyOwner()
    external returns(bool) {
        require(pool != address(0), "RewardD: Zero address");
        require(rewardReceivers.length < 30, "RewardD: Max no of pools reached");
        IFestakeRewardManager manager = IFestakeRewardManager(pool);
        require(address(manager.rewardToken()) != address(0), "RewardD: No reward address was provided");
        rewardReceivers.push(pool);
        IFestakeRewardManager firstManager = IFestakeRewardManager(rewardReceivers[0]);
        require(firstManager.rewardToken() == manager.rewardToken(),
            "RewardD: Reward token inconsistent with current pools");
        return true;
    }

    /**
     * poolRatio is used for a gas efficient round-robbin distribution of rewards.
     * Pack a number of uint8s in poolRatios. Maximum number of pools is 14.
     * Sum of ratios must add to 100.
     */
    function updateRewardDistributionForPools(bytes calldata poolRatios)
    onlyOwner()
    external returns (bool) {
        uint sum = 0;
        uint len = rewardReceivers.length;
        for (uint i = 0; i < len; i++) {
            sum = toUint8(poolRatios, i) + sum;
        }
        require(sum == 100, "ReardD: ratios must add to 100");
        rewardPools.pools = poolRatios;
        return true;
    }

    /**
     * @dev be carefull. Randomly chooses a pool using round robbin.
     * Assuming the transaction sizes are randomly distributed, each pool gets
     * the right share of rewards in aggregate.
     * Sacrificing accuracy for reduction in gas for each transaction.
     */
    function rollAndGetDistributionAddress(address addressForRandom)
    external override view returns(address) {
        require(addressForRandom != address(0) , "RewardD: address cannot be 0");
        uint256 rand = block.timestamp * (block.difficulty == 0 ? 1 : block.difficulty) *
             (uint256(bytes32(bytes20(addressForRandom))) >> 128) * 31 % 100;
        uint sum = 0;
        bytes memory poolRatios = rewardPools.pools;
        uint256 len = rewardReceivers.length;
        for (uint i = 0; i < len && i < poolRatios.length; i++) {
            uint poolRatio = toUint8(poolRatios, i);
            sum += poolRatio;
            if (sum >= rand && poolRatio != 0 ) {
                return rewardReceivers[i];
            }
        }
        return address(0);
    }

    function updateRewards(address target) external override returns(bool) {
        IFestakeRewardManager manager = IFestakeRewardManager(target);
        return manager.addMarginalReward();
    }

    function bytes32ToBytes(bytes32 _bytes32) private pure returns (bytes memory) {
        bytes memory bytesArray = new bytes(32);
        for (uint256 i; i < 32; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return bytesArray;
    }

    function toByte32(bytes memory _bytes)
    private pure returns (bytes32) {
        bytes32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), 0))
        }

        return tempUint;
    }

    function toUint8(bytes memory _bytes, uint256 _start)
    private pure returns (uint8) {
        require(_start + 1 >= _start, "toUint8_overflow");
        require(_bytes.length >= _start + 1 , "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <=0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../staking/RewardDistributor.sol";

interface IERC20Burnable {
    function burn(uint256 amount) external;
}

interface ITaxDistributor {
    function distributeTax(address token) external returns(bool);
}

contract TaxDistributor is ITaxDistributor, Ownable {
    using SafeMath for uint256;
    struct Distribution {
        uint8 stake;
        uint8 burn;
        uint8 future;
        uint8 dev;
    }

    mapping(address => Distribution) distribution;
    mapping(address => IRewardDistributor) rewardDistributor;
    mapping(address => address) devAddress;
    mapping(address => address) futureAddress;
    address globalDevAddress;
    uint256 globalDevFeePer100;

    function setRewardDistributor(address token, address _rewardDistributor)
    onlyOwner()
    external returns(bool) {
        require(address(token) != address(0), "TaxDistributor: Bad token");
        IRewardDistributor rd = IRewardDistributor(_rewardDistributor);
        address someAddress = rd.rollAndGetDistributionAddress(msg.sender);
        require(someAddress != address(0), "TaxDistributor: Bad reward distributor");
        rewardDistributor[token] = rd;
        return true;
    }

    function setDevAddress(address token, address _devAddress)
    onlyOwner()
    external returns(bool) {
        require(address(token) != address(0), "TaxDistributor: Bad token");
        devAddress[token] = _devAddress; // Allow 0
        return true;
    }

    function setGlobalDevAddress(address _devAddress, uint256 devFeePer100)
    onlyOwner()
    external returns(bool) {
        require(devFeePer100 < 100, "TaxDistributor: Invalid devFeePer100");
        globalDevAddress = _devAddress; // Allow 0
        globalDevFeePer100 = devFeePer100;
        return true;
    }

    function setFutureAddress(address token, address _futureAddress)
    onlyOwner()
    external returns(bool) {
        require(address(token) != address(0), "TaxDistributor: Bad token");
        futureAddress[token] = _futureAddress; // Allow 0
        return true;
    }

    function setDefaultDistribution(address token, uint8 stake, uint8 burn, uint8 dev, uint8 future)
    onlyOwner()
    external returns(bool) {
        require(address(token) != address(0), "TaxDistributor: Bad token");
        require(stake+burn+dev+future == 100, "StakeDevBurnTaxable: taxes must add to 100");
        distribution[token] = Distribution({ stake: stake, burn: burn, dev: dev, future: future });
        return true;
    }

    /**
     * @dev Can be called by anybody, but make this contract is tax exempt.
     */
    function distributeTax(address token) external override returns(bool) {
        return _distributeTax(token, IERC20(token).balanceOf(address(this)));
    }

    function _distributeTax(address token, uint256 amount) internal returns(bool) {
        Distribution memory dist = distribution[token];
        uint256 remaining = amount;
        uint256 _globalDevFeePer100 = globalDevFeePer100;
        if (_globalDevFeePer100 != 0) {
            uint256 globalDevAmount = amount.mul(_globalDevFeePer100).div(100);
            if (globalDevAmount != 0) {
                IERC20(token).transfer(globalDevAddress, globalDevAmount);
                remaining = remaining.sub(globalDevAmount);
            }
        }
        if (dist.burn != 0) {
            uint256 burnAmount = amount.mul(dist.burn).div(100);
            if (burnAmount != 0) {
                IERC20Burnable(token).burn(burnAmount);
                remaining = remaining.sub(burnAmount);
            }
        }
        if (dist.dev != 0) {
            uint256 devAmount = amount.mul(dist.dev).div(100);
            if (devAmount != 0) {
                IERC20(token).transfer(devAddress[token], devAmount);
                remaining = remaining.sub(devAmount);
            }
        }
        if (dist.future != 0) {
            uint256 futureAmount = amount.mul(dist.future).div(100);
            if (futureAmount != 0) {
                IERC20(token).transfer(futureAddress[token], futureAmount);
                remaining = remaining.sub(futureAmount);
            }
        }
        if (dist.stake != 0) {
            uint256 stakeAmount = remaining;
            address stakeAddress = rewardDistributor[token].rollAndGetDistributionAddress(msg.sender);
            if (stakeAddress != address(0)) {
                IERC20(token).transfer(stakeAddress, stakeAmount);
                bool res = rewardDistributor[token].updateRewards(stakeAddress);
                require(res, "StakeDevBurnTaxable: Error staking rewards");
            }
        }
        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <=0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./TaxDistributor.sol";

/**
 * Allows taxation efficiently.
 */
abstract contract Taxable is ERC20Burnable, Ownable  {
    uint128 public _buffer = 20 * 10 ** 18; // Default to 20 tokens;
    ITaxDistributor taxDistributor;

    function updateBuffer(uint256 buffer) external onlyOwner returns (bool) {
        require(buffer < 2 ** 127, "Taxable: Buffer too large");
        _buffer = uint128(buffer);
    }

    function updateTaxDistributor(address _taxDistributor) external onlyOwner returns (bool) {
        taxDistributor = ITaxDistributor(_taxDistributor);
        return ITaxDistributor(_taxDistributor).distributeTax(address(this)); // Verify it works
    }

    function tax(address sender, uint256 amount) internal returns(bool) {
        require(amount < 2 ** 127, "Taxable: Tax amount too large");
        ITaxDistributor _taxDistributor = taxDistributor;
        if (address(_taxDistributor) == address(0)) { return false; }
        _transferWithoutTax(sender, address(_taxDistributor), amount);
        uint256 buffer = _buffer;
        uint256 taxAmount = balanceOf(address(_taxDistributor));
        if (taxAmount >= buffer) {
            return _taxDistributor.distributeTax(address(this));
        }
        return true;
    }

    function _transferWithoutTax(address sender, address recipient, uint256 amount) internal virtual;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <=0.8.0;

interface IReshapableToken {
    function deposit(address token, uint256 amount) external returns(uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <=0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "../../common/SafeAmount.sol";
import "./IReshapableToken.sol";

abstract contract ReshapableERC20 is ERC20Burnable, IReshapableToken, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    uint256 public cap;
    uint256 constant RATIO_PADDING = 10 ** (18 + 9);
    uint256 constant DECIMALS = 10 ** 18;

    mapping (address=>uint256) internal _ratios;
    event Deposit(address from, address to, address source, uint256 sourceAmount,
     address target, uint256 targetAmount);

    /**
     * @dev ratio must be padded by the ratio_padding amount. 
     * For example if 1 wBTC (dec 8) -> 0.0001 (dec 18) SuperBTC, ratio is calculated as
     * Ratio =  0.0001 / 10**8 = 10**-12, then pad the ratio to make it positive. 10**-12 * 10**36
     * 10**8 wBTC -> 10**[(8 - 12 + 36) - 36 + 18]
     */
    function setRatio(address token, uint256 paddedRatio)
    external virtual onlyOwner() returns (bool) {
        _setRatio(token, paddedRatio);
        return true;
    }

    /**
     * Owner can set the cap. If the cap lower than supply it will have no effect.
     * Setting this to zero will open up the cap.
     */
    function setCap(uint256 _cap)
    external virtual onlyOwner() returns (bool) {
        cap = _cap;
        return true;
    }

    function _setRatio(address token, uint256 ratio) internal {
        require(token != address(0), "ReshapableERC20: Bad token");
        require(ratio != 0, "ReshapableERC20: Ratio must be set");
        require(ratio < 2 ** 127, "ReshapableERC20: Ratio too large");
        require(ratio.mul(DECIMALS) != 0, "ReshapableERC20: Ratio or token decimals too small");
        _ratios[token] = ratio.mul(DECIMALS);
    }

    function deposit(address token, uint256 amount) external virtual override returns(uint256) {
        return _deposit(msg.sender, msg.sender, token, amount);
    }

    function getInAmount(address token, uint256 outAmount)
        external virtual view returns(uint256) {
        require(token != address(0), "ReshapableERC20: Bad token");
        require(outAmount != 0, "ReshapableERC20: Amount was zero");
        require(outAmount < 2 ** 127, "ReshapableERC20: Amount too large");
        return _getInAmount(token, outAmount);
    }

    function _getInAmount(address token, uint256 amountOut)
        internal virtual view returns(uint256) {
        uint256 ratio = _ratios[token];
        require(ratio != 0, "ReshapableERC20: Unsupported token");
        return amountOut.mul(RATIO_PADDING).div(ratio);
    }

    function _deposit(address from, address to, address token, uint256 amount) internal returns (uint256) {
        require(from != address(0), "ReshapableERC20: Bad from");
        uint256 ratio = _ratios[token];
        require(ratio != 0, "ReshapableERC20: Unsupported token");
        require(amount != 0, "ReshapableERC20: Amount was zero");
        require(amount < 2 ** 127, "ReshapableERC20: Amount too large");
        uint256 _totalSupply = totalSupply();
        require(cap == 0 || _totalSupply < cap, "ReshapableERC20: Cap reached"); // Shortcut
        // Support fee-on-transfer tokens
        amount = SafeAmount.safeTransferFrom(token, from, address(this), amount);
        uint256 mintAmount = amount.mul(ratio).div(RATIO_PADDING);
        require(mintAmount != 0, "ReshapableERC20: Mint amount will be zero");
        uint256 newSupply = _totalSupply.add(mintAmount);
        if (cap != 0 && newSupply > cap) {
            uint256 extra = newSupply - cap;
            uint amountExtra = amount.mul(extra).div(mintAmount);
            amount = amount.sub(amountExtra);
            mintAmount = amount.mul(ratio).div(RATIO_PADDING);
            IERC20(token).safeTransfer(from, amountExtra);  // Sorry you will be hit by fee twice if token charges fee
        }
        _mint(to, mintAmount);
        emit Deposit(from, to, token, amount, address(this), mintAmount);
        return mintAmount;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <=0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./LockLib.sol";
import "./ISafetyLocker.sol";
import "./ILocker.sol";

/**
 * Owner can lock unlock temporarily, or make them permanent.
 * It can also add penalty to certain activities.
 * Addresses can be whitelisted or have different penalties.
 * This must be inherited by the token itself.
 */
contract BasicLocker is ILocker, Ownable {
    // Putting all conditions in one mapping to prevent unnecessary lookup and save gas
    mapping (address=>LockLib.TargetPolicy) locked;
    address public safetyLocker;
    address public token;

    function getLockType(address target) external view returns(LockLib.LockType, uint16, bool) {
        LockLib.TargetPolicy memory res = locked[target];
        return (res.lockType, res.penaltyRateOver1000, res.isPermanent);
    }

    function setSafetyLocker(address _token, address _safetyLocker) external onlyOwner() {
        require(_token != address(0), "Locker: Bad token");
        token = _token;
        safetyLocker = _safetyLocker;
        if (safetyLocker != address(0)) {
            require(ISafetyLocker(_safetyLocker).IsSafetyLocker(), "Bad safetyLocker");
        }
    }

    /**
     */
    function lockAddress(address target, LockLib.LockType lockType,
        uint16 penaltyRateOver1000, bool permanent)
    external
    onlyOwner()
    returns(bool) {
        require(target != address(0), "Locker: invalid target address");
        require(!locked[target].isPermanent, "Locker: address lock is permanent");

        locked[target].lockType = lockType;
        locked[target].penaltyRateOver1000 = penaltyRateOver1000;
        locked[target].isPermanent = permanent;
        return true;
    }

    function multiBlackList(address[] calldata addresses) external onlyLockAdmin() {
        for(uint i=0; i < addresses.length; i++) {
            locked[addresses[i]].lockType = LockLib.LockType.NoTransaction;
        }
    }

    function multiWhitelist(address[] calldata addresses) external onlyLockAdmin() {
        for(uint i=0; i < addresses.length; i++) {
            // Do not change other lock types
            if (locked[addresses[i]].lockType == LockLib.LockType.NoTransaction) {
                locked[addresses[i]].lockType = LockLib.LockType.None;
            }
        }
    }

    /**
     * @dev Fails if transaction is not allowed. Otherwise returns the penalty.
     */
    function lockOrGetPenalty(address source, address dest) external virtual override
    returns (bool, uint256) {
        LockLib.TargetPolicy memory sourcePolicy = locked[source];
        LockLib.TargetPolicy memory destPolicy = locked[dest];

        require(sourcePolicy.lockType != LockLib.LockType.NoOut &&
            sourcePolicy.lockType != LockLib.LockType.NoTransaction, "Locker: not allowed source");
        require(destPolicy.lockType != LockLib.LockType.NoIn &&
            destPolicy.lockType != LockLib.LockType.NoTransaction, "Locker: not allowed destination");

        if (safetyLocker != address(0)) {
            require(msg.sender == token, "Locker: not allowed caller");
            ISafetyLocker(safetyLocker).verifyTransfer(source, dest);
        }
        return (false, 0); // No pentaly  so unused
    }

    /**
        * @dev Throws if called by any account other than lock admin or master.
     */
    modifier onlyLockAdmin() {
        LockLib.LockType senderState = locked[_msgSender()].lockType;
        require(senderState == LockLib.LockType.BlacklistAdmin ||
            senderState == LockLib.LockType.Master, "Locker: Only call from BL admin");
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <=0.8.0;

interface ILiquiditySyncer {
    function syncLiquiditySupply(address pool) external;
}

interface ILocker {
    /**
     * @dev Fails if transaction is not allowed. Otherwise returns the penalty.
     * Returns a bool and a uint16, bool clarifying the penalty applied, and uint16 the penaltyOver1000
     */
    function lockOrGetPenalty(address source, address dest)
    external
    returns (bool, uint256);
}

interface ILockerUser {
    function locker() external view returns (ILocker);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <=0.8.0;

interface ISafetyLocker {
    function verifyTransfer(address source, address dest) external;
    function verifyUserAddress(address user, uint256 amount) external;
    function IsSafetyLocker() external pure returns(bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <=0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library LockLib {

    enum LockType {
        None, NoBurnPool, NoIn, NoOut, NoTransaction,
        PenaltyOut, PenaltyIn, PenaltyInOrOut, Master, LiquidityAdder, BlacklistAdmin
    }

    struct TargetPolicy {
        LockType lockType;
        uint16 penaltyRateOver1000;
        bool isPermanent;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <=0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "../../common/Constants.sol";
import "./LockLib.sol";
import "./ISafetyLocker.sol";
import "./ILocker.sol";
import "./BasicLocker.sol";

/**
 * Owner can lock unlock temporarily, or make them permanent.
 * It can also add penalty to certain activities.
 * Addresses can be whitelisted or have different penalties.
 * This must be inherited by the token itself.
 */
contract TaxedLocker is Ownable, BasicLocker {

    /**
     * @dev Fails if transaction is not allowed. Otherwise returns the penalty.
     * Returns a bool and a uint16, bool clarifying the penalty applied, and uint16 the penaltyOver1000
     */
    function lockOrGetPenalty(address source, address dest) external override
    returns (bool, uint256) {
        LockLib.TargetPolicy memory sourcePolicy = locked[source];
        LockLib.TargetPolicy memory destPolicy = locked[dest];
        bool overridePenalty = false;

        if (sourcePolicy.lockType == LockLib.LockType.Master || destPolicy.lockType == LockLib.LockType.Master) {
            return (true, 0);
        }
        require(sourcePolicy.lockType != LockLib.LockType.NoOut &&
            sourcePolicy.lockType != LockLib.LockType.NoTransaction, "Locker: not allowed source");
        require(destPolicy.lockType != LockLib.LockType.NoIn &&
            destPolicy.lockType != LockLib.LockType.NoTransaction, "Locker: not allowed destination");
        uint256 sourcePenalty = 0;
        if (sourcePolicy.lockType == LockLib.LockType.PenaltyOut ||
            sourcePolicy.lockType == LockLib.LockType.PenaltyInOrOut) {
            sourcePenalty = sourcePolicy.penaltyRateOver1000;
            overridePenalty = true;
        }
        uint256 destPenalty = 0;
        if (destPolicy.lockType == LockLib.LockType.PenaltyIn ||
            destPolicy.lockType == LockLib.LockType.PenaltyInOrOut) {
            destPenalty = destPolicy.penaltyRateOver1000;
            overridePenalty = true;
        }
        if (safetyLocker != address(0)) {
            ISafetyLocker(safetyLocker).verifyTransfer(source, dest);
        }
        return (overridePenalty, Math.max(sourcePenalty, destPenalty));
    }
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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20 is Context, IERC20 {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overloaded;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

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
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
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
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
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
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        _approve(account, _msgSender(), currentAllowance - amount);
        _burn(account, amount);
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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

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
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.6.2;

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

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

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

