// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/IFeeCollector.sol";
import "./libraries/UniERC20.sol";
import "./libraries/Sqrt.sol";
import "./libraries/VirtualBalance.sol";
import "./governance/MooniswapGovernance.sol";


contract Mooniswap is MooniswapGovernance {
    using Sqrt for uint256;
    using SafeMath for uint256;
    using UniERC20 for IERC20;
    using VirtualBalance for VirtualBalance.Data;

    struct Balances {
        uint256 src;
        uint256 dst;
    }

    struct SwapVolumes {
        uint128 confirmed;
        uint128 result;
    }

    struct Fees {
        uint256 fee;
        uint256 slippageFee;
    }

    event Error(string reason);

    event Deposited(
        address indexed sender,
        address indexed receiver,
        uint256 share,
        uint256 token0Amount,
        uint256 token1Amount
    );

    event Withdrawn(
        address indexed sender,
        address indexed receiver,
        uint256 share,
        uint256 token0Amount,
        uint256 token1Amount
    );

    event Swapped(
        address indexed sender,
        address indexed receiver,
        address indexed srcToken,
        address dstToken,
        uint256 amount,
        uint256 result,
        uint256 srcAdditionBalance,
        uint256 dstRemovalBalance,
        address referral
    );

    event Sync(
        uint256 srcBalance,
        uint256 dstBalance,
        uint256 fee,
        uint256 slippageFee,
        uint256 referralShare,
        uint256 governanceShare
    );

    uint256 private constant _BASE_SUPPLY = 1000;  // Total supply on first deposit

    IERC20 public immutable token0;
    IERC20 public immutable token1;
    mapping(IERC20 => SwapVolumes) public volumes;
    mapping(IERC20 => VirtualBalance.Data) public virtualBalancesForAddition;
    mapping(IERC20 => VirtualBalance.Data) public virtualBalancesForRemoval;

    modifier whenNotShutdown {
        require(mooniswapFactoryGovernance.isActive(), "Mooniswap: factory shutdown");
        _;
    }

    constructor(
        IERC20 _token0,
        IERC20 _token1,
        string memory name,
        string memory symbol,
        IMooniswapFactoryGovernance _mooniswapFactoryGovernance
    )
        public
        ERC20(name, symbol)
        MooniswapGovernance(_mooniswapFactoryGovernance)
    {
        require(bytes(name).length > 0, "Mooniswap: name is empty");
        require(bytes(symbol).length > 0, "Mooniswap: symbol is empty");
        require(_token0 != _token1, "Mooniswap: duplicate tokens");
        token0 = _token0;
        token1 = _token1;
    }

    function getTokens() external view returns(IERC20[] memory tokens) {
        tokens = new IERC20[](2);
        tokens[0] = token0;
        tokens[1] = token1;
    }

    function tokens(uint256 i) external view returns(IERC20) {
        if (i == 0) {
            return token0;
        } else if (i == 1) {
            return token1;
        } else {
            revert("Pool has two tokens");
        }
    }

    function getBalanceForAddition(IERC20 token) public view returns(uint256) {
        uint256 balance = token.uniBalanceOf(address(this));
        return Math.max(virtualBalancesForAddition[token].current(decayPeriod(), balance), balance);
    }

    function getBalanceForRemoval(IERC20 token) public view returns(uint256) {
        uint256 balance = token.uniBalanceOf(address(this));
        return Math.min(virtualBalancesForRemoval[token].current(decayPeriod(), balance), balance);
    }

    function getReturn(IERC20 src, IERC20 dst, uint256 amount) external view returns(uint256) {
        return _getReturn(src, dst, amount, getBalanceForAddition(src), getBalanceForRemoval(dst), fee(), slippageFee());
    }

    function deposit(uint256[2] memory maxAmounts, uint256[2] memory minAmounts) external payable returns(uint256 fairSupply, uint256[2] memory receivedAmounts) {
        return depositFor(maxAmounts, minAmounts, msg.sender);
    }

    function depositFor(uint256[2] memory maxAmounts, uint256[2] memory minAmounts, address target) public payable nonReentrant returns(uint256 fairSupply, uint256[2] memory receivedAmounts) {
        IERC20[2] memory _tokens = [token0, token1];
        require(msg.value == (_tokens[0].isETH() ? maxAmounts[0] : (_tokens[1].isETH() ? maxAmounts[1] : 0)), "Mooniswap: wrong value usage");

        uint256 totalSupply = totalSupply();

        if (totalSupply == 0) {
            fairSupply = _BASE_SUPPLY.mul(99);
            _mint(address(this), _BASE_SUPPLY); // Donate up to 1%

            for (uint i = 0; i < maxAmounts.length; i++) {
                fairSupply = Math.max(fairSupply, maxAmounts[i]);

                require(maxAmounts[i] > 0, "Mooniswap: amount is zero");
                require(maxAmounts[i] >= minAmounts[i], "Mooniswap: minAmount not reached");

                _tokens[i].uniTransferFrom(msg.sender, address(this), maxAmounts[i]);
                receivedAmounts[i] = maxAmounts[i];
            }
        }
        else {
            uint256[2] memory realBalances;
            for (uint i = 0; i < realBalances.length; i++) {
                realBalances[i] = _tokens[i].uniBalanceOf(address(this)).sub(_tokens[i].isETH() ? msg.value : 0);
            }

            // Pre-compute fair supply
            fairSupply = type(uint256).max;
            for (uint i = 0; i < maxAmounts.length; i++) {
                fairSupply = Math.min(fairSupply, totalSupply.mul(maxAmounts[i]).div(realBalances[i]));
            }

            uint256 fairSupplyCached = fairSupply;

            for (uint i = 0; i < maxAmounts.length; i++) {
                require(maxAmounts[i] > 0, "Mooniswap: amount is zero");
                uint256 amount = realBalances[i].mul(fairSupplyCached).add(totalSupply - 1).div(totalSupply);
                require(amount >= minAmounts[i], "Mooniswap: minAmount not reached");

                _tokens[i].uniTransferFrom(msg.sender, address(this), amount);
                receivedAmounts[i] = _tokens[i].uniBalanceOf(address(this)).sub(realBalances[i]);
                fairSupply = Math.min(fairSupply, totalSupply.mul(receivedAmounts[i]).div(realBalances[i]));
            }

            uint256 _decayPeriod = decayPeriod();  // gas savings
            for (uint i = 0; i < maxAmounts.length; i++) {
                virtualBalancesForRemoval[_tokens[i]].scale(_decayPeriod, realBalances[i], totalSupply.add(fairSupply), totalSupply);
                virtualBalancesForAddition[_tokens[i]].scale(_decayPeriod, realBalances[i], totalSupply.add(fairSupply), totalSupply);
            }
        }

        require(fairSupply > 0, "Mooniswap: result is not enough");
        _mint(target, fairSupply);

        emit Deposited(msg.sender, target, fairSupply, receivedAmounts[0], receivedAmounts[1]);
    }

    function withdraw(uint256 amount, uint256[] memory minReturns) external returns(uint256[2] memory withdrawnAmounts) {
        return withdrawFor(amount, minReturns, msg.sender);
    }

    function withdrawFor(uint256 amount, uint256[] memory minReturns, address payable target) public nonReentrant returns(uint256[2] memory withdrawnAmounts) {
        IERC20[2] memory _tokens = [token0, token1];

        uint256 totalSupply = totalSupply();
        uint256 _decayPeriod = decayPeriod();  // gas savings
        _burn(msg.sender, amount);

        for (uint i = 0; i < _tokens.length; i++) {
            IERC20 token = _tokens[i];

            uint256 preBalance = token.uniBalanceOf(address(this));
            uint256 value = preBalance.mul(amount).div(totalSupply);
            token.uniTransfer(target, value);
            withdrawnAmounts[i] = value;
            require(i >= minReturns.length || value >= minReturns[i], "Mooniswap: result is not enough");

            virtualBalancesForAddition[token].scale(_decayPeriod, preBalance, totalSupply.sub(amount), totalSupply);
            virtualBalancesForRemoval[token].scale(_decayPeriod, preBalance, totalSupply.sub(amount), totalSupply);
        }

        emit Withdrawn(msg.sender, target, amount, withdrawnAmounts[0], withdrawnAmounts[1]);
    }

    function swap(IERC20 src, IERC20 dst, uint256 amount, uint256 minReturn, address referral) external payable returns(uint256 result) {
        return swapFor(src, dst, amount, minReturn, referral, msg.sender);
    }

    function swapFor(IERC20 src, IERC20 dst, uint256 amount, uint256 minReturn, address referral, address payable receiver) public payable nonReentrant whenNotShutdown returns(uint256 result) {
        require(msg.value == (src.isETH() ? amount : 0), "Mooniswap: wrong value usage");

        Balances memory balances = Balances({
            src: src.uniBalanceOf(address(this)).sub(src.isETH() ? msg.value : 0),
            dst: dst.uniBalanceOf(address(this))
        });
        uint256 confirmed;
        Balances memory virtualBalances;
        Fees memory fees = Fees({
            fee: fee(),
            slippageFee: slippageFee()
        });
        (confirmed, result, virtualBalances) = _doTransfers(src, dst, amount, minReturn, receiver, balances, fees);
        emit Swapped(msg.sender, receiver, address(src), address(dst), confirmed, result, virtualBalances.src, virtualBalances.dst, referral);
        _mintRewards(confirmed, result, referral, balances, fees);

        // Overflow of uint128 is desired
        volumes[src].confirmed += uint128(confirmed);
        volumes[src].result += uint128(result);
    }

    function _doTransfers(IERC20 src, IERC20 dst, uint256 amount, uint256 minReturn, address payable receiver, Balances memory balances, Fees memory fees)
        private returns(uint256 confirmed, uint256 result, Balances memory virtualBalances)
    {
        uint256 _decayPeriod = decayPeriod();
        virtualBalances.src = virtualBalancesForAddition[src].current(_decayPeriod, balances.src);
        virtualBalances.src = Math.max(virtualBalances.src, balances.src);
        virtualBalances.dst = virtualBalancesForRemoval[dst].current(_decayPeriod, balances.dst);
        virtualBalances.dst = Math.min(virtualBalances.dst, balances.dst);
        src.uniTransferFrom(msg.sender, address(this), amount);
        confirmed = src.uniBalanceOf(address(this)).sub(balances.src);
        result = _getReturn(src, dst, confirmed, virtualBalances.src, virtualBalances.dst, fees.fee, fees.slippageFee);
        require(result > 0 && result >= minReturn, "Mooniswap: return is not enough");
        dst.uniTransfer(receiver, result);

        // Update virtual balances to the same direction only at imbalanced state
        if (virtualBalances.src != balances.src) {
            virtualBalancesForAddition[src].set(virtualBalances.src.add(confirmed));
        }
        if (virtualBalances.dst != balances.dst) {
            virtualBalancesForRemoval[dst].set(virtualBalances.dst.sub(result));
        }
        // Update virtual balances to the opposite direction
        virtualBalancesForRemoval[src].update(_decayPeriod, balances.src);
        virtualBalancesForAddition[dst].update(_decayPeriod, balances.dst);
    }

    function _mintRewards(uint256 confirmed, uint256 result, address referral, Balances memory balances, Fees memory fees) private {
        (uint256 referralShare, uint256 governanceShare, address govWallet, address feeCollector) = mooniswapFactoryGovernance.shareParameters();

        uint256 refReward;
        uint256 govReward;

        uint256 invariantRatio = uint256(1e36);
        invariantRatio = invariantRatio.mul(balances.src.add(confirmed)).div(balances.src);
        invariantRatio = invariantRatio.mul(balances.dst.sub(result)).div(balances.dst);
        if (invariantRatio > 1e36) {
            // calculate share only if invariant increased
            invariantRatio = invariantRatio.sqrt();
            uint256 invIncrease = totalSupply().mul(invariantRatio.sub(1e18)).div(invariantRatio);

            refReward = (referral != address(0)) ? invIncrease.mul(referralShare).div(MooniswapConstants._FEE_DENOMINATOR) : 0;
            govReward = (govWallet != address(0)) ? invIncrease.mul(governanceShare).div(MooniswapConstants._FEE_DENOMINATOR) : 0;

            if (feeCollector == address(0)) {
                if (refReward > 0) {
                    _mint(referral, refReward);
                }
                if (govReward > 0) {
                    _mint(govWallet, govReward);
                }
            }
            else if (refReward > 0 || govReward > 0) {
                uint256 len = (refReward > 0 ? 1 : 0) + (govReward > 0 ? 1 : 0);
                address[] memory wallets = new address[](len);
                uint256[] memory rewards = new uint256[](len);

                wallets[0] = referral;
                rewards[0] = refReward;
                if (govReward > 0) {
                    wallets[len - 1] = govWallet;
                    rewards[len - 1] = govReward;
                }

                try IFeeCollector(feeCollector).updateRewards(wallets, rewards) {
                    _mint(feeCollector, refReward.add(govReward));
                }
                catch {
                    emit Error("updateRewards() failed");
                }
            }
        }

        emit Sync(balances.src, balances.dst, fees.fee, fees.slippageFee, refReward, govReward);
    }

    /*
        spot_ret = dx * y / x
        uni_ret = dx * y / (x + dx)
        slippage = (spot_ret - uni_ret) / spot_ret
        slippage = dx * dx * y / (x * (x + dx)) / (dx * y / x)
        slippage = dx / (x + dx)
        ret = uni_ret * (1 - slip_fee * slippage)
        ret = dx * y / (x + dx) * (1 - slip_fee * dx / (x + dx))
        ret = dx * y / (x + dx) * (x + dx - slip_fee * dx) / (x + dx)

        x = amount * denominator
        dx = amount * (denominator - fee)
    */
    function _getReturn(IERC20 src, IERC20 dst, uint256 amount, uint256 srcBalance, uint256 dstBalance, uint256 fee, uint256 slippageFee) internal view returns(uint256) {
        if (src > dst) {
            (src, dst) = (dst, src);
        }
        if (amount > 0 && src == token0 && dst == token1) {
            uint256 taxedAmount = amount.sub(amount.mul(fee).div(MooniswapConstants._FEE_DENOMINATOR));
            uint256 srcBalancePlusTaxedAmount = srcBalance.add(taxedAmount);
            uint256 ret = taxedAmount.mul(dstBalance).div(srcBalancePlusTaxedAmount);
            uint256 feeNumerator = MooniswapConstants._FEE_DENOMINATOR.mul(srcBalancePlusTaxedAmount).sub(slippageFee.mul(taxedAmount));
            uint256 feeDenominator = MooniswapConstants._FEE_DENOMINATOR.mul(srcBalancePlusTaxedAmount);
            return ret.mul(feeNumerator).div(feeDenominator);
        }
    }

    function rescueFunds(IERC20 token, uint256 amount) external nonReentrant onlyOwner {
        uint256 balance0 = token0.uniBalanceOf(address(this));
        uint256 balance1 = token1.uniBalanceOf(address(this));

        token.uniTransfer(msg.sender, amount);

        require(token0.uniBalanceOf(address(this)) >= balance0, "Mooniswap: access denied");
        require(token1.uniBalanceOf(address(this)) >= balance1, "Mooniswap: access denied");
        require(balanceOf(address(this)) >= _BASE_SUPPLY, "Mooniswap: access denied");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./interfaces/IMooniswapDeployer.sol";
import "./interfaces/IMooniswapFactory.sol";
import "./libraries/UniERC20.sol";
import "./Mooniswap.sol";
import "./governance/MooniswapFactoryGovernance.sol";


contract MooniswapFactory is IMooniswapFactory, MooniswapFactoryGovernance {
    using UniERC20 for IERC20;

    event Deployed(
        Mooniswap indexed mooniswap,
        IERC20 indexed token1,
        IERC20 indexed token2
    );

    IMooniswapDeployer public immutable mooniswapDeployer;
    address public immutable poolOwner;
    Mooniswap[] public allPools;
    mapping(Mooniswap => bool) public override isPool;
    mapping(IERC20 => mapping(IERC20 => Mooniswap)) private _pools;

    constructor (address _poolOwner, IMooniswapDeployer _mooniswapDeployer, address _governanceMothership) public MooniswapFactoryGovernance(_governanceMothership) {
        poolOwner = _poolOwner;
        mooniswapDeployer = _mooniswapDeployer;
    }

    function getAllPools() external view returns(Mooniswap[] memory) {
        return allPools;
    }

    function pools(IERC20 tokenA, IERC20 tokenB) external view override returns (Mooniswap pool) {
        (IERC20 token1, IERC20 token2) = sortTokens(tokenA, tokenB);
        return _pools[token1][token2];
    }

    function deploy(IERC20 tokenA, IERC20 tokenB) public returns(Mooniswap pool) {
        require(tokenA != tokenB, "Factory: not support same tokens");
        (IERC20 token1, IERC20 token2) = sortTokens(tokenA, tokenB);
        require(_pools[token1][token2] == Mooniswap(0), "Factory: pool already exists");

        string memory symbol1 = token1.uniSymbol();
        string memory symbol2 = token2.uniSymbol();

        pool = mooniswapDeployer.deploy(
            token1,
            token2,
            string(abi.encodePacked("1inch Liquidity Pool (", symbol1, "-", symbol2, ")")),
            string(abi.encodePacked("1LP-", symbol1, "-", symbol2)),
            poolOwner
        );

        _pools[token1][token2] = pool;
        allPools.push(pool);
        isPool[pool] = true;

        emit Deployed(pool, token1, token2);
    }

    function sortTokens(IERC20 tokenA, IERC20 tokenB) public pure returns(IERC20, IERC20) {
        if (tokenA < tokenB) {
            return (tokenA, tokenB);
        }
        return (tokenB, tokenA);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../interfaces/IGovernanceModule.sol";


abstract contract BaseGovernanceModule is IGovernanceModule {
    address public immutable mothership;

    modifier onlyMothership {
        require(msg.sender == mothership, "Access restricted to mothership");

        _;
    }

    constructor(address _mothership) public {
        mothership = _mothership;
    }

    function notifyStakesChanged(address[] calldata accounts, uint256[] calldata newBalances) external override onlyMothership {
        require(accounts.length == newBalances.length, "Arrays length should be equal");

        for(uint256 i = 0; i < accounts.length; ++i) {
            _notifyStakeChanged(accounts[i], newBalances[i]);
        }
    }

    function notifyStakeChanged(address account, uint256 newBalance) external override onlyMothership {
        _notifyStakeChanged(account, newBalance);
    }

    function _notifyStakeChanged(address account, uint256 newBalance) internal virtual;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "../interfaces/IMooniswapFactoryGovernance.sol";
import "../libraries/ExplicitLiquidVoting.sol";
import "../libraries/MooniswapConstants.sol";
import "../libraries/SafeCast.sol";
import "../utils/BalanceAccounting.sol";
import "./BaseGovernanceModule.sol";


contract MooniswapFactoryGovernance is IMooniswapFactoryGovernance, BaseGovernanceModule, BalanceAccounting, Ownable, Pausable {
    using Vote for Vote.Data;
    using ExplicitLiquidVoting for ExplicitLiquidVoting.Data;
    using VirtualVote for VirtualVote.Data;
    using SafeMath for uint256;
    using SafeCast for uint256;

    event DefaultFeeVoteUpdate(address indexed user, uint256 fee, bool isDefault, uint256 amount);
    event DefaultSlippageFeeVoteUpdate(address indexed user, uint256 slippageFee, bool isDefault, uint256 amount);
    event DefaultDecayPeriodVoteUpdate(address indexed user, uint256 decayPeriod, bool isDefault, uint256 amount);
    event ReferralShareVoteUpdate(address indexed user, uint256 referralShare, bool isDefault, uint256 amount);
    event GovernanceShareVoteUpdate(address indexed user, uint256 governanceShare, bool isDefault, uint256 amount);
    event GovernanceWalletUpdate(address governanceWallet);
    event FeeCollectorUpdate(address feeCollector);

    ExplicitLiquidVoting.Data private _defaultFee;
    ExplicitLiquidVoting.Data private _defaultSlippageFee;
    ExplicitLiquidVoting.Data private _defaultDecayPeriod;
    ExplicitLiquidVoting.Data private _referralShare;
    ExplicitLiquidVoting.Data private _governanceShare;
    address public override governanceWallet;
    address public override feeCollector;

    mapping(address => bool) public override isFeeCollector;

    constructor(address _mothership) public BaseGovernanceModule(_mothership) {
        _defaultFee.data.result = MooniswapConstants._DEFAULT_FEE.toUint104();
        _defaultSlippageFee.data.result = MooniswapConstants._DEFAULT_SLIPPAGE_FEE.toUint104();
        _defaultDecayPeriod.data.result = MooniswapConstants._DEFAULT_DECAY_PERIOD.toUint104();
        _referralShare.data.result = MooniswapConstants._DEFAULT_REFERRAL_SHARE.toUint104();
        _governanceShare.data.result = MooniswapConstants._DEFAULT_GOVERNANCE_SHARE.toUint104();
    }

    function shutdown() external onlyOwner {
        _pause();
    }

    function isActive() external view override returns (bool) {
        return !paused();
    }

    function shareParameters() external view override returns(uint256, uint256, address, address) {
        return (_referralShare.data.current(), _governanceShare.data.current(), governanceWallet, feeCollector);
    }

    function defaults() external view override returns(uint256, uint256, uint256) {
        return (_defaultFee.data.current(), _defaultSlippageFee.data.current(), _defaultDecayPeriod.data.current());
    }

    function defaultFee() external view override returns(uint256) {
        return _defaultFee.data.current();
    }

    function defaultFeeVotes(address user) external view returns(uint256) {
        return _defaultFee.votes[user].get(MooniswapConstants._DEFAULT_FEE);
    }

    function virtualDefaultFee() external view returns(uint104, uint104, uint48) {
        return (_defaultFee.data.oldResult, _defaultFee.data.result, _defaultFee.data.time);
    }

    function defaultSlippageFee() external view override returns(uint256) {
        return _defaultSlippageFee.data.current();
    }

    function defaultSlippageFeeVotes(address user) external view returns(uint256) {
        return _defaultSlippageFee.votes[user].get(MooniswapConstants._DEFAULT_SLIPPAGE_FEE);
    }

    function virtualDefaultSlippageFee() external view returns(uint104, uint104, uint48) {
        return (_defaultSlippageFee.data.oldResult, _defaultSlippageFee.data.result, _defaultSlippageFee.data.time);
    }

    function defaultDecayPeriod() external view override returns(uint256) {
        return _defaultDecayPeriod.data.current();
    }

    function defaultDecayPeriodVotes(address user) external view returns(uint256) {
        return _defaultDecayPeriod.votes[user].get(MooniswapConstants._DEFAULT_DECAY_PERIOD);
    }

    function virtualDefaultDecayPeriod() external view returns(uint104, uint104, uint48) {
        return (_defaultDecayPeriod.data.oldResult, _defaultDecayPeriod.data.result, _defaultDecayPeriod.data.time);
    }

    function referralShare() external view override returns(uint256) {
        return _referralShare.data.current();
    }

    function referralShareVotes(address user) external view returns(uint256) {
        return _referralShare.votes[user].get(MooniswapConstants._DEFAULT_REFERRAL_SHARE);
    }

    function virtualReferralShare() external view returns(uint104, uint104, uint48) {
        return (_referralShare.data.oldResult, _referralShare.data.result, _referralShare.data.time);
    }

    function governanceShare() external view override returns(uint256) {
        return _governanceShare.data.current();
    }

    function governanceShareVotes(address user) external view returns(uint256) {
        return _governanceShare.votes[user].get(MooniswapConstants._DEFAULT_GOVERNANCE_SHARE);
    }

    function virtualGovernanceShare() external view returns(uint104, uint104, uint48) {
        return (_governanceShare.data.oldResult, _governanceShare.data.result, _governanceShare.data.time);
    }

    function setGovernanceWallet(address newGovernanceWallet) external onlyOwner {
        governanceWallet = newGovernanceWallet;
        isFeeCollector[newGovernanceWallet] = true;
        emit GovernanceWalletUpdate(newGovernanceWallet);
    }

    function setFeeCollector(address newFeeCollector) external onlyOwner {
        feeCollector = newFeeCollector;
        isFeeCollector[newFeeCollector] = true;
        emit FeeCollectorUpdate(newFeeCollector);
    }

    function defaultFeeVote(uint256 vote) external {
        require(vote <= MooniswapConstants._MAX_FEE, "Fee vote is too high");
        _defaultFee.updateVote(msg.sender, _defaultFee.votes[msg.sender], Vote.init(vote), balanceOf(msg.sender), MooniswapConstants._DEFAULT_FEE, _emitDefaultFeeVoteUpdate);
    }

    function discardDefaultFeeVote() external {
       _defaultFee.updateVote(msg.sender, _defaultFee.votes[msg.sender], Vote.init(), balanceOf(msg.sender), MooniswapConstants._DEFAULT_FEE, _emitDefaultFeeVoteUpdate);
    }

    function defaultSlippageFeeVote(uint256 vote) external {
        require(vote <= MooniswapConstants._MAX_SLIPPAGE_FEE, "Slippage fee vote is too high");
        _defaultSlippageFee.updateVote(msg.sender, _defaultSlippageFee.votes[msg.sender], Vote.init(vote), balanceOf(msg.sender), MooniswapConstants._DEFAULT_SLIPPAGE_FEE, _emitDefaultSlippageFeeVoteUpdate);
    }

   function discardDefaultSlippageFeeVote() external {
        _defaultSlippageFee.updateVote(msg.sender, _defaultSlippageFee.votes[msg.sender], Vote.init(), balanceOf(msg.sender), MooniswapConstants._DEFAULT_SLIPPAGE_FEE, _emitDefaultSlippageFeeVoteUpdate);
    }

    function defaultDecayPeriodVote(uint256 vote) external {
        require(vote <= MooniswapConstants._MAX_DECAY_PERIOD, "Decay period vote is too high");
        require(vote >= MooniswapConstants._MIN_DECAY_PERIOD, "Decay period vote is too low");
        _defaultDecayPeriod.updateVote(msg.sender, _defaultDecayPeriod.votes[msg.sender], Vote.init(vote), balanceOf(msg.sender), MooniswapConstants._DEFAULT_DECAY_PERIOD, _emitDefaultDecayPeriodVoteUpdate);
    }

    function discardDefaultDecayPeriodVote() external {
        _defaultDecayPeriod.updateVote(msg.sender, _defaultDecayPeriod.votes[msg.sender], Vote.init(), balanceOf(msg.sender), MooniswapConstants._DEFAULT_DECAY_PERIOD, _emitDefaultDecayPeriodVoteUpdate);
    }

    function referralShareVote(uint256 vote) external {
        require(vote <= MooniswapConstants._MAX_SHARE, "Referral share vote is too high");
        require(vote >= MooniswapConstants._MIN_REFERRAL_SHARE, "Referral share vote is too low");
        _referralShare.updateVote(msg.sender, _referralShare.votes[msg.sender], Vote.init(vote), balanceOf(msg.sender), MooniswapConstants._DEFAULT_REFERRAL_SHARE, _emitReferralShareVoteUpdate);
    }

    function discardReferralShareVote() external {
        _referralShare.updateVote(msg.sender, _referralShare.votes[msg.sender], Vote.init(), balanceOf(msg.sender), MooniswapConstants._DEFAULT_REFERRAL_SHARE, _emitReferralShareVoteUpdate);
    }

    function governanceShareVote(uint256 vote) external {
        require(vote <= MooniswapConstants._MAX_SHARE, "Gov share vote is too high");
        _governanceShare.updateVote(msg.sender, _governanceShare.votes[msg.sender], Vote.init(vote), balanceOf(msg.sender), MooniswapConstants._DEFAULT_GOVERNANCE_SHARE, _emitGovernanceShareVoteUpdate);
    }

    function discardGovernanceShareVote() external {
        _governanceShare.updateVote(msg.sender, _governanceShare.votes[msg.sender], Vote.init(), balanceOf(msg.sender), MooniswapConstants._DEFAULT_GOVERNANCE_SHARE, _emitGovernanceShareVoteUpdate);
    }

    function _notifyStakeChanged(address account, uint256 newBalance) internal override {
        uint256 balance = _set(account, newBalance);
        if (newBalance == balance) {
            return;
        }

        _defaultFee.updateBalance(account, _defaultFee.votes[account], balance, newBalance, MooniswapConstants._DEFAULT_FEE, _emitDefaultFeeVoteUpdate);
        _defaultSlippageFee.updateBalance(account, _defaultSlippageFee.votes[account], balance, newBalance, MooniswapConstants._DEFAULT_SLIPPAGE_FEE, _emitDefaultSlippageFeeVoteUpdate);
        _defaultDecayPeriod.updateBalance(account, _defaultDecayPeriod.votes[account], balance, newBalance, MooniswapConstants._DEFAULT_DECAY_PERIOD, _emitDefaultDecayPeriodVoteUpdate);
        _referralShare.updateBalance(account, _referralShare.votes[account], balance, newBalance, MooniswapConstants._DEFAULT_REFERRAL_SHARE, _emitReferralShareVoteUpdate);
        _governanceShare.updateBalance(account, _governanceShare.votes[account], balance, newBalance, MooniswapConstants._DEFAULT_GOVERNANCE_SHARE, _emitGovernanceShareVoteUpdate);
    }

    function _emitDefaultFeeVoteUpdate(address user, uint256 newDefaultFee, bool isDefault, uint256 balance) private {
        emit DefaultFeeVoteUpdate(user, newDefaultFee, isDefault, balance);
    }

    function _emitDefaultSlippageFeeVoteUpdate(address user, uint256 newDefaultSlippageFee, bool isDefault, uint256 balance) private {
        emit DefaultSlippageFeeVoteUpdate(user, newDefaultSlippageFee, isDefault, balance);
    }

    function _emitDefaultDecayPeriodVoteUpdate(address user, uint256 newDefaultDecayPeriod, bool isDefault, uint256 balance) private {
        emit DefaultDecayPeriodVoteUpdate(user, newDefaultDecayPeriod, isDefault, balance);
    }

    function _emitReferralShareVoteUpdate(address user, uint256 newReferralShare, bool isDefault, uint256 balance) private {
        emit ReferralShareVoteUpdate(user, newReferralShare, isDefault, balance);
    }

    function _emitGovernanceShareVoteUpdate(address user, uint256 newGovernanceShare, bool isDefault, uint256 balance) private {
        emit GovernanceShareVoteUpdate(user, newGovernanceShare, isDefault, balance);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../interfaces/IMooniswapFactoryGovernance.sol";
import "../libraries/LiquidVoting.sol";
import "../libraries/MooniswapConstants.sol";
import "../libraries/SafeCast.sol";


abstract contract MooniswapGovernance is ERC20, Ownable, ReentrancyGuard {
    using Vote for Vote.Data;
    using LiquidVoting for LiquidVoting.Data;
    using VirtualVote for VirtualVote.Data;
    using SafeCast for uint256;

    event FeeVoteUpdate(address indexed user, uint256 fee, bool isDefault, uint256 amount);
    event SlippageFeeVoteUpdate(address indexed user, uint256 slippageFee, bool isDefault, uint256 amount);
    event DecayPeriodVoteUpdate(address indexed user, uint256 decayPeriod, bool isDefault, uint256 amount);

    IMooniswapFactoryGovernance public mooniswapFactoryGovernance;
    LiquidVoting.Data private _fee;
    LiquidVoting.Data private _slippageFee;
    LiquidVoting.Data private _decayPeriod;

    constructor(IMooniswapFactoryGovernance _mooniswapFactoryGovernance) internal {
        mooniswapFactoryGovernance = _mooniswapFactoryGovernance;
        _fee.data.result = _mooniswapFactoryGovernance.defaultFee().toUint104();
        _slippageFee.data.result = _mooniswapFactoryGovernance.defaultSlippageFee().toUint104();
        _decayPeriod.data.result = _mooniswapFactoryGovernance.defaultDecayPeriod().toUint104();
    }

    function setMooniswapFactoryGovernance(IMooniswapFactoryGovernance newMooniswapFactoryGovernance) external onlyOwner {
        mooniswapFactoryGovernance = newMooniswapFactoryGovernance;
        this.discardFeeVote();
        this.discardSlippageFeeVote();
        this.discardDecayPeriodVote();
    }

    function fee() public view returns(uint256) {
        return _fee.data.current();
    }

    function slippageFee() public view returns(uint256) {
        return _slippageFee.data.current();
    }

    function decayPeriod() public view returns(uint256) {
        return _decayPeriod.data.current();
    }

    function virtualFee() external view returns(uint104, uint104, uint48) {
        return (_fee.data.oldResult, _fee.data.result, _fee.data.time);
    }

    function virtualSlippageFee() external view returns(uint104, uint104, uint48) {
        return (_slippageFee.data.oldResult, _slippageFee.data.result, _slippageFee.data.time);
    }

    function virtualDecayPeriod() external view returns(uint104, uint104, uint48) {
        return (_decayPeriod.data.oldResult, _decayPeriod.data.result, _decayPeriod.data.time);
    }

    function feeVotes(address user) external view returns(uint256) {
        return _fee.votes[user].get(mooniswapFactoryGovernance.defaultFee);
    }

    function slippageFeeVotes(address user) external view returns(uint256) {
        return _slippageFee.votes[user].get(mooniswapFactoryGovernance.defaultSlippageFee);
    }

    function decayPeriodVotes(address user) external view returns(uint256) {
        return _decayPeriod.votes[user].get(mooniswapFactoryGovernance.defaultDecayPeriod);
    }

    function feeVote(uint256 vote) external {
        require(vote <= MooniswapConstants._MAX_FEE, "Fee vote is too high");

        _fee.updateVote(msg.sender, _fee.votes[msg.sender], Vote.init(vote), balanceOf(msg.sender), totalSupply(), mooniswapFactoryGovernance.defaultFee(), _emitFeeVoteUpdate);
    }

    function slippageFeeVote(uint256 vote) external {
        require(vote <= MooniswapConstants._MAX_SLIPPAGE_FEE, "Slippage fee vote is too high");

        _slippageFee.updateVote(msg.sender, _slippageFee.votes[msg.sender], Vote.init(vote), balanceOf(msg.sender), totalSupply(), mooniswapFactoryGovernance.defaultSlippageFee(), _emitSlippageFeeVoteUpdate);
    }

    function decayPeriodVote(uint256 vote) external {
        require(vote <= MooniswapConstants._MAX_DECAY_PERIOD, "Decay period vote is too high");
        require(vote >= MooniswapConstants._MIN_DECAY_PERIOD, "Decay period vote is too low");

        _decayPeriod.updateVote(msg.sender, _decayPeriod.votes[msg.sender], Vote.init(vote), balanceOf(msg.sender), totalSupply(), mooniswapFactoryGovernance.defaultDecayPeriod(), _emitDecayPeriodVoteUpdate);
    }

    function discardFeeVote() external {
        _fee.updateVote(msg.sender, _fee.votes[msg.sender], Vote.init(), balanceOf(msg.sender), totalSupply(), mooniswapFactoryGovernance.defaultFee(), _emitFeeVoteUpdate);
    }

    function discardSlippageFeeVote() external {
        _slippageFee.updateVote(msg.sender, _slippageFee.votes[msg.sender], Vote.init(), balanceOf(msg.sender), totalSupply(), mooniswapFactoryGovernance.defaultSlippageFee(), _emitSlippageFeeVoteUpdate);
    }

    function discardDecayPeriodVote() external {
        _decayPeriod.updateVote(msg.sender, _decayPeriod.votes[msg.sender], Vote.init(), balanceOf(msg.sender), totalSupply(), mooniswapFactoryGovernance.defaultDecayPeriod(), _emitDecayPeriodVoteUpdate);
    }

    function _emitFeeVoteUpdate(address account, uint256 newFee, bool isDefault, uint256 newBalance) private {
        emit FeeVoteUpdate(account, newFee, isDefault, newBalance);
    }

    function _emitSlippageFeeVoteUpdate(address account, uint256 newSlippageFee, bool isDefault, uint256 newBalance) private {
        emit SlippageFeeVoteUpdate(account, newSlippageFee, isDefault, newBalance);
    }

    function _emitDecayPeriodVoteUpdate(address account, uint256 newDecayPeriod, bool isDefault, uint256 newBalance) private {
        emit DecayPeriodVoteUpdate(account, newDecayPeriod, isDefault, newBalance);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        if (from == to) {
            // ignore transfers to self
            return;
        }

        IMooniswapFactoryGovernance _mooniswapFactoryGovernance = mooniswapFactoryGovernance;
        bool updateFrom = !(from == address(0) || _mooniswapFactoryGovernance.isFeeCollector(from));
        bool updateTo = !(to == address(0) || _mooniswapFactoryGovernance.isFeeCollector(to));

        if (!updateFrom && !updateTo) {
            // mint to feeReceiver or burn from feeReceiver
            return;
        }

        uint256 balanceFrom = (from != address(0)) ? balanceOf(from) : 0;
        uint256 balanceTo = (to != address(0)) ? balanceOf(to) : 0;
        uint256 newTotalSupply = totalSupply()
            .add(from == address(0) ? amount : 0)
            .sub(to == address(0) ? amount : 0);

        ParamsHelper memory params = ParamsHelper({
            from: from,
            to: to,
            updateFrom: updateFrom,
            updateTo: updateTo,
            amount: amount,
            balanceFrom: balanceFrom,
            balanceTo: balanceTo,
            newTotalSupply: newTotalSupply
        });

        (uint256 defaultFee, uint256 defaultSlippageFee, uint256 defaultDecayPeriod) = _mooniswapFactoryGovernance.defaults();

        _updateOnTransfer(params, defaultFee, _emitFeeVoteUpdate, _fee);
        _updateOnTransfer(params, defaultSlippageFee, _emitSlippageFeeVoteUpdate, _slippageFee);
        _updateOnTransfer(params, defaultDecayPeriod, _emitDecayPeriodVoteUpdate, _decayPeriod);
    }

    struct ParamsHelper {
        address from;
        address to;
        bool updateFrom;
        bool updateTo;
        uint256 amount;
        uint256 balanceFrom;
        uint256 balanceTo;
        uint256 newTotalSupply;
    }

    function _updateOnTransfer(
        ParamsHelper memory params,
        uint256 defaultValue,
        function(address, uint256, bool, uint256) internal emitEvent,
        LiquidVoting.Data storage votingData
    ) private {
        Vote.Data memory voteFrom = votingData.votes[params.from];
        Vote.Data memory voteTo = votingData.votes[params.to];

        if (voteFrom.isDefault() && voteTo.isDefault() && params.updateFrom && params.updateTo) {
            emitEvent(params.from, voteFrom.get(defaultValue), true, params.balanceFrom.sub(params.amount));
            emitEvent(params.to, voteTo.get(defaultValue), true, params.balanceTo.add(params.amount));
            return;
        }

        if (params.updateFrom) {
            votingData.updateBalance(params.from, voteFrom, params.balanceFrom, params.balanceFrom.sub(params.amount), params.newTotalSupply, defaultValue, emitEvent);
        }

        if (params.updateTo) {
            votingData.updateBalance(params.to, voteTo, params.balanceTo, params.balanceTo.add(params.amount), params.newTotalSupply, defaultValue, emitEvent);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;


interface IFeeCollector {
    function updateReward(address receiver, uint256 amount) external;
    function updateRewards(address[] calldata receivers, uint256[] calldata amounts) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;


interface IGovernanceModule {
    function notifyStakeChanged(address account, uint256 newBalance) external;
    function notifyStakesChanged(address[] calldata accounts, uint256[] calldata newBalances) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../Mooniswap.sol";

interface IMooniswapDeployer {
    function deploy(
        IERC20 token1,
        IERC20 token2,
        string calldata name,
        string calldata symbol,
        address poolOwner
    ) external returns(Mooniswap pool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../Mooniswap.sol";

interface IMooniswapFactory is IMooniswapFactoryGovernance {
    function pools(IERC20 token0, IERC20 token1) external view returns (Mooniswap);
    function isPool(Mooniswap mooniswap) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;


interface IMooniswapFactoryGovernance {
    function shareParameters() external view returns(uint256 referralShare, uint256 governanceShare, address governanceWallet, address referralFeeReceiver);
    function defaults() external view returns(uint256 defaultFee, uint256 defaultSlippageFee, uint256 defaultDecayPeriod);

    function defaultFee() external view returns(uint256);
    function defaultSlippageFee() external view returns(uint256);
    function defaultDecayPeriod() external view returns(uint256);
    function referralShare() external view returns(uint256);
    function governanceShare() external view returns(uint256);
    function governanceWallet() external view returns(address);
    function feeCollector() external view returns(address);

    function isFeeCollector(address) external view returns(bool);
    function isActive() external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./SafeCast.sol";
import "./VirtualVote.sol";
import "./Vote.sol";


library ExplicitLiquidVoting {
    using SafeMath for uint256;
    using SafeCast for uint256;
    using Vote for Vote.Data;
    using VirtualVote for VirtualVote.Data;

    struct Data {
        VirtualVote.Data data;
        uint256 _weightedSum;
        uint256 _votedSupply;
        mapping(address => Vote.Data) votes;
    }

    function updateVote(
        ExplicitLiquidVoting.Data storage self,
        address user,
        Vote.Data memory oldVote,
        Vote.Data memory newVote,
        uint256 balance,
        uint256 defaultVote,
        function(address, uint256, bool, uint256) emitEvent
    ) internal {
        return _update(self, user, oldVote, newVote, balance, balance, defaultVote, emitEvent);
    }

    function updateBalance(
        ExplicitLiquidVoting.Data storage self,
        address user,
        Vote.Data memory oldVote,
        uint256 oldBalance,
        uint256 newBalance,
        uint256 defaultVote,
        function(address, uint256, bool, uint256) emitEvent
    ) internal {
        return _update(self, user, oldVote, newBalance == 0 ? Vote.init() : oldVote, oldBalance, newBalance, defaultVote, emitEvent);
    }

    function _update(
        ExplicitLiquidVoting.Data storage self,
        address user,
        Vote.Data memory oldVote,
        Vote.Data memory newVote,
        uint256 oldBalance,
        uint256 newBalance,
        uint256 defaultVote,
        function(address, uint256, bool, uint256) emitEvent
    ) private {
        uint256 oldWeightedSum = self._weightedSum;
        uint256 newWeightedSum = oldWeightedSum;
        uint256 oldVotedSupply = self._votedSupply;
        uint256 newVotedSupply = oldVotedSupply;

        if (!oldVote.isDefault()) {
            newWeightedSum = newWeightedSum.sub(oldBalance.mul(oldVote.get(defaultVote)));
            newVotedSupply = newVotedSupply.sub(oldBalance);
        }

        if (!newVote.isDefault()) {
            newWeightedSum = newWeightedSum.add(newBalance.mul(newVote.get(defaultVote)));
            newVotedSupply = newVotedSupply.add(newBalance);
        }

        if (newWeightedSum != oldWeightedSum) {
            self._weightedSum = newWeightedSum;
        }

        if (newVotedSupply != oldVotedSupply) {
            self._votedSupply = newVotedSupply;
        }

        {
            uint256 newResult = newVotedSupply == 0 ? defaultVote : newWeightedSum.div(newVotedSupply);
            VirtualVote.Data memory data = self.data;

            if (newResult != data.result) {
                VirtualVote.Data storage sdata = self.data;
                (sdata.oldResult, sdata.result, sdata.time) = (
                    data.current().toUint104(),
                    newResult.toUint104(),
                    block.timestamp.toUint48()
                );
            }
        }

        if (!newVote.eq(oldVote)) {
            self.votes[user] = newVote;
        }

        emitEvent(user, newVote.get(defaultVote), newVote.isDefault(), newBalance);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./SafeCast.sol";
import "./VirtualVote.sol";
import "./Vote.sol";


library LiquidVoting {
    using SafeMath for uint256;
    using SafeCast for uint256;
    using Vote for Vote.Data;
    using VirtualVote for VirtualVote.Data;

    struct Data {
        VirtualVote.Data data;
        uint256 _weightedSum;
        uint256 _defaultVotes;
        mapping(address => Vote.Data) votes;
    }

    function updateVote(
        LiquidVoting.Data storage self,
        address user,
        Vote.Data memory oldVote,
        Vote.Data memory newVote,
        uint256 balance,
        uint256 totalSupply,
        uint256 defaultVote,
        function(address, uint256, bool, uint256) emitEvent
    ) internal {
        return _update(self, user, oldVote, newVote, balance, balance, totalSupply, defaultVote, emitEvent);
    }

    function updateBalance(
        LiquidVoting.Data storage self,
        address user,
        Vote.Data memory oldVote,
        uint256 oldBalance,
        uint256 newBalance,
        uint256 newTotalSupply,
        uint256 defaultVote,
        function(address, uint256, bool, uint256) emitEvent
    ) internal {
        return _update(self, user, oldVote, newBalance == 0 ? Vote.init() : oldVote, oldBalance, newBalance, newTotalSupply, defaultVote, emitEvent);
    }

    function _update(
        LiquidVoting.Data storage self,
        address user,
        Vote.Data memory oldVote,
        Vote.Data memory newVote,
        uint256 oldBalance,
        uint256 newBalance,
        uint256 newTotalSupply,
        uint256 defaultVote,
        function(address, uint256, bool, uint256) emitEvent
    ) private {
        uint256 oldWeightedSum = self._weightedSum;
        uint256 newWeightedSum = oldWeightedSum;
        uint256 oldDefaultVotes = self._defaultVotes;
        uint256 newDefaultVotes = oldDefaultVotes;

        if (oldVote.isDefault()) {
            newDefaultVotes = newDefaultVotes.sub(oldBalance);
        } else {
            newWeightedSum = newWeightedSum.sub(oldBalance.mul(oldVote.get(defaultVote)));
        }

        if (newVote.isDefault()) {
            newDefaultVotes = newDefaultVotes.add(newBalance);
        } else {
            newWeightedSum = newWeightedSum.add(newBalance.mul(newVote.get(defaultVote)));
        }

        if (newWeightedSum != oldWeightedSum) {
            self._weightedSum = newWeightedSum;
        }

        if (newDefaultVotes != oldDefaultVotes) {
            self._defaultVotes = newDefaultVotes;
        }

        {
            uint256 newResult = newTotalSupply == 0 ? defaultVote : newWeightedSum.add(newDefaultVotes.mul(defaultVote)).div(newTotalSupply);
            VirtualVote.Data memory data = self.data;

            if (newResult != data.result) {
                VirtualVote.Data storage sdata = self.data;
                (sdata.oldResult, sdata.result, sdata.time) = (
                    data.current().toUint104(),
                    newResult.toUint104(),
                    block.timestamp.toUint48()
                );
            }
        }

        if (!newVote.eq(oldVote)) {
            self.votes[user] = newVote;
        }

        emitEvent(user, newVote.get(defaultVote), newVote.isDefault(), newBalance);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;


library MooniswapConstants {
    uint256 internal constant _FEE_DENOMINATOR = 1e18;

    uint256 internal constant _MIN_REFERRAL_SHARE = 0.05e18; // 5%
    uint256 internal constant _MIN_DECAY_PERIOD = 1 minutes;

    uint256 internal constant _MAX_FEE = 0.01e18; // 1%
    uint256 internal constant _MAX_SLIPPAGE_FEE = 1e18;  // 100%
    uint256 internal constant _MAX_SHARE = 0.1e18; // 10%
    uint256 internal constant _MAX_DECAY_PERIOD = 5 minutes;

    uint256 internal constant _DEFAULT_FEE = 0;
    uint256 internal constant _DEFAULT_SLIPPAGE_FEE = 1e18;  // 100%
    uint256 internal constant _DEFAULT_REFERRAL_SHARE = 0.1e18; // 10%
    uint256 internal constant _DEFAULT_GOVERNANCE_SHARE = 0;
    uint256 internal constant _DEFAULT_DECAY_PERIOD = 1 minutes;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

library SafeCast {
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value < 2**216, "value does not fit in 216 bits");
        return uint216(value);
    }

    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value < 2**104, "value does not fit in 104 bits");
        return uint104(value);
    }

    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value < 2**48, "value does not fit in 48 bits");
        return uint48(value);
    }

    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value < 2**40, "value does not fit in 40 bits");
        return uint40(value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;


library Sqrt {
    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256) {
        if (y > 3) {
            uint256 z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
            return z;
        } else if (y != 0) {
            return 1;
        } else {
            return 0;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";


library UniERC20 {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    function isETH(IERC20 token) internal pure returns(bool) {
        return (address(token) == address(0));
    }

    function uniBalanceOf(IERC20 token, address account) internal view returns (uint256) {
        if (isETH(token)) {
            return account.balance;
        } else {
            return token.balanceOf(account);
        }
    }

    function uniTransfer(IERC20 token, address payable to, uint256 amount) internal {
        if (amount > 0) {
            if (isETH(token)) {
                to.transfer(amount);
            } else {
                token.safeTransfer(to, amount);
            }
        }
    }

    function uniTransferFrom(IERC20 token, address payable from, address to, uint256 amount) internal {
        if (amount > 0) {
            if (isETH(token)) {
                require(msg.value >= amount, "UniERC20: not enough value");
                require(from == msg.sender, "from is not msg.sender");
                require(to == address(this), "to is not this");
                if (msg.value > amount) {
                    // Return remainder if exist
                    from.transfer(msg.value.sub(amount));
                }
            } else {
                token.safeTransferFrom(from, to, amount);
            }
        }
    }

    function uniSymbol(IERC20 token) internal view returns(string memory) {
        if (isETH(token)) {
            return "ETH";
        }

        (bool success, bytes memory data) = address(token).staticcall{ gas: 20000 }(
            abi.encodeWithSignature("symbol()")
        );
        if (!success) {
            (success, data) = address(token).staticcall{ gas: 20000 }(
                abi.encodeWithSignature("SYMBOL()")
            );
        }

        if (success && data.length >= 96) {
            (uint256 offset, uint256 len) = abi.decode(data, (uint256, uint256));
            if (offset == 0x20 && len > 0 && len <= 256) {
                return string(abi.decode(data, (bytes)));
            }
        }

        if (success && data.length == 32) {
            uint len = 0;
            while (len < data.length && data[len] >= 0x20 && data[len] <= 0x7E) {
                len++;
            }

            if (len > 0) {
                bytes memory result = new bytes(len);
                for (uint i = 0; i < len; i++) {
                    result[i] = data[i];
                }
                return string(result);
            }
        }

        return _toHex(address(token));
    }

    function _toHex(address account) private pure returns(string memory) {
        return _toHex(abi.encodePacked(account));
    }

    function _toHex(bytes memory data) private pure returns(string memory) {
        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        uint j = 2;
        for (uint i = 0; i < data.length; i++) {
            uint a = uint8(data[i]) >> 4;
            uint b = uint8(data[i]) & 0x0f;
            str[j++] = byte(uint8(a + 48 + (a/10)*39));
            str[j++] = byte(uint8(b + 48 + (b/10)*39));
        }

        return string(str);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;


import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "./SafeCast.sol";


library VirtualBalance {
    using SafeMath for uint256;
    using SafeCast for uint256;

    struct Data {
        uint216 balance;
        uint40 time;
    }

    function set(VirtualBalance.Data storage self, uint256 balance) internal {
        (self.balance, self.time) = (
            balance.toUint216(),
            block.timestamp.toUint40()
        );
    }

    function update(VirtualBalance.Data storage self, uint256 decayPeriod, uint256 realBalance) internal {
        set(self, current(self, decayPeriod, realBalance));
    }

    function scale(VirtualBalance.Data storage self, uint256 decayPeriod, uint256 realBalance, uint256 num, uint256 denom) internal {
        set(self, current(self, decayPeriod, realBalance).mul(num).add(denom.sub(1)).div(denom));
    }

    function current(VirtualBalance.Data memory self, uint256 decayPeriod, uint256 realBalance) internal view returns(uint256) {
        uint256 timePassed = Math.min(decayPeriod, block.timestamp.sub(self.time));
        uint256 timeRemain = decayPeriod.sub(timePassed);
        return uint256(self.balance).mul(timeRemain).add(
            realBalance.mul(timePassed)
        ).div(decayPeriod);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";


library VirtualVote {
    using SafeMath for uint256;

    uint256 private constant _VOTE_DECAY_PERIOD = 1 days;

    struct Data {
        uint104 oldResult;
        uint104 result;
        uint48 time;
    }

    function current(VirtualVote.Data memory self) internal view returns(uint256) {
        uint256 timePassed = Math.min(_VOTE_DECAY_PERIOD, block.timestamp.sub(self.time));
        uint256 timeRemain = _VOTE_DECAY_PERIOD.sub(timePassed);
        return uint256(self.oldResult).mul(timeRemain).add(
            uint256(self.result).mul(timePassed)
        ).div(_VOTE_DECAY_PERIOD);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;


library Vote {
    struct Data {
        uint256 value;
    }

    function eq(Vote.Data memory self, Vote.Data memory vote) internal pure returns(bool) {
        return self.value == vote.value;
    }

    function init() internal pure returns(Vote.Data memory data) {
        return Vote.Data({
            value: 0
        });
    }

    function init(uint256 vote) internal pure returns(Vote.Data memory data) {
        return Vote.Data({
            value: vote + 1
        });
    }

    function isDefault(Data memory self) internal pure returns(bool) {
        return self.value == 0;
    }

    function get(Data memory self, uint256 defaultVote) internal pure returns(uint256) {
        if (self.value > 0) {
            return self.value - 1;
        }
        return defaultVote;
    }

    function get(Data memory self, function() external view returns(uint256) defaultVoteFn) internal view returns(uint256) {
        if (self.value > 0) {
            return self.value - 1;
        }
        return defaultVoteFn();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";


contract BalanceAccounting {
    using SafeMath for uint256;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function _mint(address account, uint256 amount) internal virtual {
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        _balances[account] = _balances[account].sub(amount, "Burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
    }

    function _set(address account, uint256 amount) internal virtual returns(uint256 oldAmount) {
        oldAmount = _balances[account];
        if (oldAmount != amount) {
            _balances[account] = amount;
            _totalSupply = _totalSupply.add(amount).sub(oldAmount);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../GSN/Context.sol";
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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

pragma solidity ^0.6.0;

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

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
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
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
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

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
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
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
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

pragma solidity ^0.6.0;

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

pragma solidity ^0.6.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
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
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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

pragma solidity ^0.6.2;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

pragma solidity ^0.6.0;

import "../GSN/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
contract ReentrancyGuard {
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

    constructor () internal {
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

