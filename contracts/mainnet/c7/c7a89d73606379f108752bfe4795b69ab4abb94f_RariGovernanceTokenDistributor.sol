/**
 * COPYRIGHT © 2020 RARI CAPITAL, INC. ALL RIGHTS RESERVED.
 * Anyone is free to integrate the public (i.e., non-administrative) application programming interfaces (APIs) of the official Ethereum smart contract instances deployed by Rari Capital, Inc. in any application (commercial or noncommercial and under any license), provided that the application does not abuse the APIs or act against the interests of Rari Capital, Inc.
 * Anyone is free to study, review, and analyze the source code contained in this package.
 * Reuse (including deployment of smart contracts other than private testing on a private network), modification, redistribution, or sublicensing of any source code contained in this package is not permitted without the explicit permission of David Lucid of Rari Capital, Inc.
 * No one is permitted to use the software for any purpose other than those allowed by this license.
 * This license is liable to change at any time at the sole discretion of David Lucid of Rari Capital, Inc.
 */

pragma solidity 0.5.17;

import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20Detailed.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20Pausable.sol";

/**
 * @title RariGovernanceToken
 * @author David Lucid <[email protected]> (https://github.com/davidlucid)
 * @notice RariGovernanceToken is the contract behind the Rari Governance Token (RGT), an ERC20 token accounting for the ownership of Rari Stable Pool, Yield Pool, and Ethereum Pool.
 */
contract RariGovernanceToken is Initializable, ERC20, ERC20Detailed, ERC20Burnable, ERC20Pausable {
    /**
     * @dev Initializer that reserves 8.75 million RGT for liquidity mining and 1.25 million RGT to the team/advisors/etc.
     */
    function initialize(address distributor, address vesting) public initializer {
        ERC20Detailed.initialize("Rari Governance Token", "RGT", 18);
        ERC20Pausable.initialize(msg.sender);
        _mint(distributor, 8750000 * (10 ** uint256(decimals())));
        _mint(vesting, 1250000 * (10 ** uint256(decimals())));
    }
}

/**
 * COPYRIGHT © 2020 RARI CAPITAL, INC. ALL RIGHTS RESERVED.
 * Anyone is free to integrate the public (i.e., non-administrative) application programming interfaces (APIs) of the official Ethereum smart contract instances deployed by Rari Capital, Inc. in any application (commercial or noncommercial and under any license), provided that the application does not abuse the APIs or act against the interests of Rari Capital, Inc.
 * Anyone is free to study, review, and analyze the source code contained in this package.
 * Reuse (including deployment of smart contracts other than private testing on a private network), modification, redistribution, or sublicensing of any source code contained in this package is not permitted without the explicit permission of David Lucid of Rari Capital, Inc.
 * No one is permitted to use the software for any purpose other than those allowed by this license.
 * This license is liable to change at any time at the sole discretion of David Lucid of Rari Capital, Inc.
 */

pragma solidity 0.5.17;

import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";

import "@chainlink/contracts/src/v0.5/interfaces/AggregatorV3Interface.sol";

import "./RariGovernanceToken.sol";
import "./interfaces/IRariFundManager.sol";

/**
 * @title RariGovernanceToken
 * @author David Lucid <[email protected]> (https://github.com/davidlucid)
 * @notice RariGovernanceTokenDistributor distributes RGT (Rari Governance Token) to Rari Stable Pool, Yield Pool, and Ethereum Pool holders.
 */
contract RariGovernanceTokenDistributor is Initializable, Ownable {
    using SafeMath for uint256;

    /**
     * @dev Initializer that reserves 8.75 million RGT for liquidity mining and 1.25 million RGT to the team.
     */
    function initialize(uint256 startBlock, IRariFundManager[3] memory fundManagers, IERC20[3] memory fundTokens) public initializer {
        Ownable.initialize(msg.sender);
        require(fundManagers.length == 3 && fundTokens.length == 3, "Fund manager and fund token array lengths must be equal to 3.");
        distributionStartBlock = startBlock;
        distributionEndBlock = distributionStartBlock + DISTRIBUTION_PERIOD;
        rariFundManagers = fundManagers;
        rariFundTokens = fundTokens;
        _ethUsdPriceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
    }

    /**
     * @notice Boolean indicating if this contract is disabled.
     */
    bool public disabled;

    /**
     * @dev Emitted when the primary functionality of this RariGovernanceTokenDistributor contract has been disabled.
     */
    event Disabled();

    /**
     * @dev Emitted when the primary functionality of this RariGovernanceTokenDistributor contract has been enabled.
     */
    event Enabled();

    /**
     * @dev Disables/enables primary functionality of this RariGovernanceTokenDistributor so contract(s) can be upgraded.
     */
    function setDisabled(bool _disabled) external onlyOwner {
        require(_disabled != disabled, "No change to enabled/disabled status.");
        disabled = _disabled;
        if (_disabled) emit Disabled(); else emit Enabled();
    }

    /**
     * @dev Throws if fund is disabled.
     */
    modifier enabled() {
        require(!disabled, "This governance token distributor contract is disabled. This may be due to an upgrade.");
        _;
    }

    /**
     * @dev The RariGovernanceToken contract.
     */
    RariGovernanceToken rariGovernanceToken;

    /**
     * @dev Sets the RariGovernanceToken distributed by ths RariGovernanceTokenDistributor.
     * @param governanceToken The new RariGovernanceToken contract.
     */
    function setGovernanceToken(RariGovernanceToken governanceToken) external onlyOwner {
        if (address(rariGovernanceToken) != address(0)) require(disabled, "This governance token distributor contract must be disabled before changing the governance token contract.");
        require(address(governanceToken) != address(0), "New governance token contract cannot be the zero address.");
        rariGovernanceToken = governanceToken;
    }

    /**
     * @notice Enum for the Rari pools to which distributions are rewarded.
     */
    enum RariPool {
        Stable,
        Yield,
        Ethereum
    }

    /**
     * @dev The RariFundManager contracts for each RariPool.
     */
    IRariFundManager[3] rariFundManagers;

    /**
     * @dev The RariFundToken contracts for each RariPool.
     */
    IERC20[3] rariFundTokens;

    /**
     * @dev Sets the RariFundManager for `pool`.
     * @param pool The pool associated with this RariFundManager.
     * @param fundManager The RariFundManager associated with this pool.
     */
    function setFundManager(RariPool pool, IRariFundManager fundManager) external onlyOwner {
        require(disabled, "This governance token distributor contract must be disabled before changing fund manager contracts.");
        require(address(fundManager) != address(0), "New fund manager contract cannot be the zero address.");
        rariFundManagers[uint8(pool)] = fundManager;
    }

    /**
     * @dev Sets the RariFundToken for `pool`.
     * @param pool The pool associated with this RariFundToken.
     * @param fundToken The RariFundToken associated with this pool.
     */
    function setFundToken(RariPool pool, IERC20 fundToken) external onlyOwner {
        require(disabled, "This governance token distributor contract must be disabled before changing fund token contracts.");
        require(address(fundToken) != address(0), "New fund token contract cannot be the zero address.");
        rariFundTokens[uint8(pool)] = fundToken;
    }

    /**
     * @notice Starting block number of the distribution.
     */
    uint256 public distributionStartBlock;

    /**
     * @notice Ending block number of the distribution.
     */
    uint256 public distributionEndBlock;

    /**
     * @notice Length in blocks of the distribution period.
     */
    uint256 public constant DISTRIBUTION_PERIOD = 390000;

    /**
     * @notice Total and final quantity of all RGT to be distributed by the end of the period.
     */
    uint256 public constant FINAL_RGT_DISTRIBUTION = 8750000e18;

    /**
     * @notice Returns the amount of RGT earned via liquidity mining at the given `blockNumber`.
     * See the following graph for a visualization of RGT distributed via liquidity mining vs. blocks since distribution started: https://www.desmos.com/calculator/2yvnflg4ir
     * @param blockNumber The block number to check.
     */
    function getRgtDistributed(uint256 blockNumber) public view returns (uint256) {
        if (blockNumber <= distributionStartBlock) return 0;
        if (blockNumber >= distributionEndBlock) return FINAL_RGT_DISTRIBUTION;
        uint256 blocks = blockNumber.sub(distributionStartBlock);
        if (blocks < 97500) return uint256(1e18).mul(blocks ** 2).div(2730).add(uint256(1450e18).mul(blocks).div(273));
        if (blocks < 195000) return uint256(14600e18).mul(blocks).div(273).sub(uint256(2e18).mul(blocks ** 2).div(17745)).sub(uint256(1000000e18).div(7));
        if (blocks < 292500) return uint256(1e18).mul(blocks ** 2).div(35490).add(uint256(39250000e18).div(7)).sub(uint256(950e18).mul(blocks).div(273));
        return uint256(1e18).mul(blocks ** 2).div(35490).add(uint256(34750000e18).div(7)).sub(uint256(50e18).mul(blocks).div(39));
    }

    /**
     * @dev Caches fund balances (to calculate distribution speeds).
     */
    uint256[3] _fundBalancesCache;

    /**
     * @dev Maps RariPool indexes to the quantity of RGT distributed per RSPT/RYPT/REPT at the last speed update.
     */
    uint256[3] _rgtPerRftAtLastSpeedUpdate;

    /**
     * @dev The total amount of RGT distributed at the last speed update.
     */
    uint256 _rgtDistributedAtLastSpeedUpdate;

    /**
     * @dev Maps RariPool indexes to holder addresses to the quantity of RGT distributed per RSPT/RYPT/REPT at their last claim.
     */
    mapping (address => uint256)[3] _rgtPerRftAtLastDistribution;

    /**
     * @dev Throws if the distribution period has ended.
     */
    modifier beforeDistributionPeriodEnded() {
        require(block.number < distributionEndBlock, "The governance token distribution period has already ended.");
        _;
    }

    /**
     * @dev Updates RGT distribution speeds for each pool given one `pool` and its `newBalance` (only accessible by the RariFundManager corresponding to `pool`).
     * @param pool The pool whose balance should be refreshed.
     * @param newBalance The new balance of the pool to be refreshed.
     */
    function refreshDistributionSpeeds(RariPool pool, uint256 newBalance) external enabled {
        require(msg.sender == address(rariFundManagers[uint8(pool)]), "Caller is not the fund manager corresponding to this pool.");
        if (block.number >= distributionEndBlock) return;
        storeRgtDistributedPerRft();
        _fundBalancesCache[uint8(pool)] = newBalance;
    }

    /**
     * @notice Updates RGT distribution speeds for each pool given one `pool` whose balance should be refreshed.
     * @param pool The pool whose balance should be refreshed.
     */
    function refreshDistributionSpeeds(RariPool pool) external enabled beforeDistributionPeriodEnded {
        storeRgtDistributedPerRft();
        _fundBalancesCache[uint8(pool)] = rariFundManagers[uint8(pool)].getFundBalance();
    }

    /**
     * @notice Updates RGT distribution speeds for each pool.
     */
    function refreshDistributionSpeeds() external enabled beforeDistributionPeriodEnded {
        storeRgtDistributedPerRft();
        for (uint256 i = 0; i < 3; i++) _fundBalancesCache[i] = rariFundManagers[i].getFundBalance();
    }
    
    /**
     * @dev Chainlink price feed for ETH/USD.
     */
    AggregatorV3Interface private _ethUsdPriceFeed;

    /**
     * @dev Retrives the latest ETH/USD price.
     */
    function getEthUsdPrice() public view returns (uint256) {
        (, int256 price, , , ) = _ethUsdPriceFeed.latestRoundData();
        return price >= 0 ? uint256(price) : 0;
    }

    /**
     * @dev Stores the latest quantity of RGT distributed per RFT for all pools (so speeds can be updated immediately afterwards).
     */
    function storeRgtDistributedPerRft() internal {
        uint256 rgtDistributed = getRgtDistributed(block.number);
        uint256 rgtToDistribute = rgtDistributed.sub(_rgtDistributedAtLastSpeedUpdate);
        if (rgtToDistribute <= 0) return;
        uint256 ethFundBalanceUsd = _fundBalancesCache[2] > 0 ? _fundBalancesCache[2].mul(getEthUsdPrice()).div(1e8) : 0;
        uint256 fundBalanceSum = 0;
        for (uint256 i = 0; i < 3; i++) fundBalanceSum = fundBalanceSum.add(i == 2 ? ethFundBalanceUsd : _fundBalancesCache[i]);
        if (fundBalanceSum <= 0) return;
        _rgtDistributedAtLastSpeedUpdate = rgtDistributed;

        for (uint256 i = 0; i < 3; i++) {
            uint256 totalSupply = rariFundTokens[i].totalSupply();
            if (totalSupply > 0) _rgtPerRftAtLastSpeedUpdate[i] = _rgtPerRftAtLastSpeedUpdate[i].add(rgtToDistribute.mul(i == 2 ? ethFundBalanceUsd : _fundBalancesCache[i]).div(fundBalanceSum).mul(1e18).div(totalSupply));
        }
    }

    /**
     * @dev Gets RGT distributed per RFT for all pools.
     */
    function getRgtDistributedPerRft() internal view returns (uint256[3] memory rgtPerRftByPool) {
        uint256 rgtDistributed = getRgtDistributed(block.number);
        uint256 rgtToDistribute = rgtDistributed.sub(_rgtDistributedAtLastSpeedUpdate);
        if (rgtToDistribute <= 0) return _rgtPerRftAtLastSpeedUpdate;
        uint256 ethFundBalanceUsd = _fundBalancesCache[2] > 0 ? _fundBalancesCache[2].mul(getEthUsdPrice()).div(1e8) : 0;
        uint256 fundBalanceSum = 0;
        for (uint256 i = 0; i < 3; i++) fundBalanceSum = fundBalanceSum.add(i == 2 ? ethFundBalanceUsd : _fundBalancesCache[i]);
        if (fundBalanceSum <= 0) return _rgtPerRftAtLastSpeedUpdate;

        for (uint256 i = 0; i < 3; i++) {
            uint256 totalSupply = rariFundTokens[i].totalSupply();
            rgtPerRftByPool[i] = totalSupply > 0 ? _rgtPerRftAtLastSpeedUpdate[i].add(rgtToDistribute.mul(i == 2 ? ethFundBalanceUsd : _fundBalancesCache[i]).div(fundBalanceSum).mul(1e18).div(totalSupply)) : _rgtPerRftAtLastSpeedUpdate[i];
        }
    }

    /**
     * @dev Maps holder addresses to the quantity of RGT distributed to each.
     */
    mapping (address => uint256) _rgtDistributedByHolder;

    /**
     * @dev Maps holder addresses to the quantity of RGT claimed by each.
     */
    mapping (address => uint256) _rgtClaimedByHolder;

    /**
     * @dev Distributes all undistributed RGT earned by `holder` in `pool` (without reverting if no RGT is available to distribute).
     * @param holder The holder of RSPT, RYPT, or REPT whose RGT is to be distributed.
     * @param pool The Rari pool for which to distribute RGT.
     * @return The quantity of RGT distributed.
     */
    function distributeRgt(address holder, RariPool pool) external enabled returns (uint256) {
        // Get RFT balance of this holder
        uint256 rftBalance = rariFundTokens[uint8(pool)].balanceOf(holder);
        if (rftBalance <= 0) return 0;

        // Store RGT distributed per RFT
        storeRgtDistributedPerRft();

        // Get undistributed RGT
        uint256 undistributedRgt = _rgtPerRftAtLastSpeedUpdate[uint8(pool)].sub(_rgtPerRftAtLastDistribution[uint8(pool)][holder]).mul(rftBalance).div(1e18);
        if (undistributedRgt <= 0) return 0;

        // Distribute RGT
        _rgtPerRftAtLastDistribution[uint8(pool)][holder] = _rgtPerRftAtLastSpeedUpdate[uint8(pool)];
        _rgtDistributedByHolder[holder] = _rgtDistributedByHolder[holder].add(undistributedRgt);
        return undistributedRgt;
    }

    /**
     * @dev Distributes all undistributed RGT earned by `holder` in all pools (without reverting if no RGT is available to distribute).
     * @param holder The holder of RSPT, RYPT, and/or REPT whose RGT is to be distributed.
     * @return The quantity of RGT distributed.
     */
    function distributeRgt(address holder) internal enabled returns (uint256) {
        // Store RGT distributed per RFT
        storeRgtDistributedPerRft();

        // Get undistributed RGT
        uint256 undistributedRgt = 0;

        for (uint256 i = 0; i < 3; i++) {
            // Get RFT balance of this holder in this pool
            uint256 rftBalance = rariFundTokens[i].balanceOf(holder);
            if (rftBalance <= 0) continue;

            // Add undistributed RGT
            undistributedRgt += _rgtPerRftAtLastSpeedUpdate[i].sub(_rgtPerRftAtLastDistribution[i][holder]).mul(rftBalance).div(1e18);
        }

        if (undistributedRgt <= 0) return 0;

        // Add undistributed to distributed
        for (uint256 i = 0; i < 3; i++) if (rariFundTokens[i].balanceOf(holder) > 0) _rgtPerRftAtLastDistribution[i][holder] = _rgtPerRftAtLastSpeedUpdate[i];
        _rgtDistributedByHolder[holder] = _rgtDistributedByHolder[holder].add(undistributedRgt);
        return undistributedRgt;
    }

    /**
     * @dev Stores the RGT distributed per RSPT/RYPT/REPT right before `holder`'s first incoming RSPT/RYPT/REPT transfer since having a zero balance.
     * @param holder The holder of RSPT, RYPT, and/or REPT.
     * @param pool The Rari pool of the pool token.
     */
    function beforeFirstPoolTokenTransferIn(address holder, RariPool pool) external enabled {
        require(rariFundTokens[uint8(pool)].balanceOf(holder) == 0, "Pool token balance is not equal to 0.");
        storeRgtDistributedPerRft();
        _rgtPerRftAtLastDistribution[uint8(pool)][holder] = _rgtPerRftAtLastSpeedUpdate[uint8(pool)];
    }

    /**
     * @dev Returns the quantity of undistributed RGT earned by `holder` via liquidity mining across all pools.
     * @param holder The holder of RSPT, RYPT, or REPT.
     * @return The quantity of unclaimed RGT.
     */
    function getUndistributedRgt(address holder) internal view returns (uint256) {
        // Get RGT distributed per RFT
        uint256[3] memory rgtPerRftByPool = getRgtDistributedPerRft();

        // Get undistributed RGT
        uint256 undistributedRgt = 0;

        for (uint256 i = 0; i < 3; i++) {
            // Get RFT balance of this holder in this pool
            uint256 rftBalance = rariFundTokens[i].balanceOf(holder);
            if (rftBalance <= 0) continue;

            // Add undistributed RGT
            undistributedRgt += rgtPerRftByPool[i].sub(_rgtPerRftAtLastDistribution[i][holder]).mul(rftBalance).div(1e18);
        }

        return undistributedRgt;
    }

    /**
     * @notice Returns the quantity of unclaimed RGT earned by `holder` via liquidity mining across all pools.
     * @param holder The holder of RSPT, RYPT, or REPT.
     * @return The quantity of unclaimed RGT.
     */
    function getUnclaimedRgt(address holder) external view returns (uint256) {
        return _rgtDistributedByHolder[holder].sub(_rgtClaimedByHolder[holder]).add(getUndistributedRgt(holder));
    }

    /**
     * @notice Returns the public RGT claim fee for users during liquidity mining (scaled by 1e18) at `blockNumber`.
     */
    function getPublicRgtClaimFee(uint256 blockNumber) public view returns (uint256) {
        if (blockNumber <= distributionStartBlock) return 0.33e18;
        if (blockNumber >= distributionEndBlock) return 0;
        return uint256(0.33e18).mul(distributionEndBlock.sub(blockNumber)).div(DISTRIBUTION_PERIOD);
    }

    /**
     * @dev Event emitted when `claimed` RGT is claimed by `holder`.
     */
    event Claim(address holder, uint256 claimed, uint256 transferred, uint256 burned);

    /**
     * @notice Claims `amount` unclaimed RGT earned by `msg.sender` in all pools.
     * @param amount The amount of RGT to claim.
     */
    function claimRgt(uint256 amount) public enabled {
        // Distribute RGT to holder
        distributeRgt(msg.sender);

        // Get unclaimed RGT
        uint256 unclaimedRgt = _rgtDistributedByHolder[msg.sender].sub(_rgtClaimedByHolder[msg.sender]);
        require(amount <= unclaimedRgt, "Claim amount cannot be greater than unclaimed RGT.");

        // Claim RGT
        uint256 burnRgt = amount.mul(getPublicRgtClaimFee(block.number)).div(1e18);
        uint256 transferRgt = amount.sub(burnRgt);
        _rgtClaimedByHolder[msg.sender] = _rgtClaimedByHolder[msg.sender].add(amount);
        require(rariGovernanceToken.transfer(msg.sender, transferRgt), "Failed to transfer RGT from liquidity mining reserve.");
        rariGovernanceToken.burn(burnRgt);
        emit Claim(msg.sender, amount, transferRgt, burnRgt);
    }

    /**
     * @notice Claims all unclaimed RGT earned by `msg.sender` in all pools.
     * @return The quantity of RGT claimed.
     */
    function claimAllRgt() public enabled returns (uint256) {
        // Distribute RGT to holder
        distributeRgt(msg.sender);

        // Get unclaimed RGT
        uint256 unclaimedRgt = _rgtDistributedByHolder[msg.sender].sub(_rgtClaimedByHolder[msg.sender]);
        require(unclaimedRgt > 0, "Unclaimed RGT not greater than 0.");

        // Claim RGT
        uint256 burnRgt = unclaimedRgt.mul(getPublicRgtClaimFee(block.number)).div(1e18);
        uint256 transferRgt = unclaimedRgt.sub(burnRgt);
        _rgtClaimedByHolder[msg.sender] = _rgtClaimedByHolder[msg.sender].add(unclaimedRgt);
        require(rariGovernanceToken.transfer(msg.sender, transferRgt), "Failed to transfer RGT from liquidity mining reserve.");
        rariGovernanceToken.burn(burnRgt);
        emit Claim(msg.sender, unclaimedRgt, transferRgt, burnRgt);
        return unclaimedRgt;
    }

    /**
     * @dev Forwards all RGT to a new RariGovernanceTokenDistributor contract.
     * @param newContract The new RariGovernanceTokenDistributor contract.
     */
    function upgrade(address newContract) external onlyOwner {
        require(disabled, "This governance token distributor contract must be disabled before it can be upgraded.");
        rariGovernanceToken.transfer(newContract, rariGovernanceToken.balanceOf(address(this)));
    }

    /**
     * @dev Sets the ETH/USD price feed if not initialized due to upgrade.
     */
    function setEthUsdPriceFeed() external onlyOwner {
        _ethUsdPriceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
    }
}

/**
 * COPYRIGHT © 2020 RARI CAPITAL, INC. ALL RIGHTS RESERVED.
 * Anyone is free to integrate the public (i.e., non-administrative) application programming interfaces (APIs) of the official Ethereum smart contract instances deployed by Rari Capital, Inc. in any application (commercial or noncommercial and under any license), provided that the application does not abuse the APIs or act against the interests of Rari Capital, Inc.
 * Anyone is free to study, review, and analyze the source code contained in this package.
 * Reuse (including deployment of smart contracts other than private testing on a private network), modification, redistribution, or sublicensing of any source code contained in this package is not permitted without the explicit permission of David Lucid of Rari Capital, Inc.
 * No one is permitted to use the software for any purpose other than those allowed by this license.
 * This license is liable to change at any time at the sole discretion of David Lucid of Rari Capital, Inc.
 */

pragma solidity 0.5.17;

import "./IRariFundToken.sol";

/**
 * @title IRariFundManager
 * @author David Lucid <[email protected]> (https://github.com/davidlucid)
 * @notice IRariFundManager is a simple interface for RariFundManager used by RariGovernanceTokenDistributor.
 */
interface IRariFundManager {
    /**
     * @dev Contract of the RariFundToken.
     */
    function rariFundToken() external returns (IRariFundToken);

    /**
     * @notice Returns the fund's total investor balance (all RFT holders' funds but not unclaimed fees) of all currencies in USD (scaled by 1e18).
     * @dev Ideally, we can add the `view` modifier, but Compound's `getUnderlyingBalance` function (called by `getRawFundBalance`) potentially modifies the state.
     */
    function getFundBalance() external returns (uint256);

    /**
     * @notice Deposits funds to the Rari Stable Pool in exchange for RFT.
     * You may only deposit currencies accepted by the fund (see `isCurrencyAccepted(string currencyCode)`).
     * Please note that you must approve RariFundManager to transfer at least `amount`.
     * @param currencyCode The currency code of the token to be deposited.
     * @param amount The amount of tokens to be deposited.
     */
    function deposit(string calldata currencyCode, uint256 amount) external;

    /**
     * @notice Withdraws funds from the Rari Stable Pool in exchange for RFT.
     * You may only withdraw currencies held by the fund (see `getRawFundBalance(string currencyCode)`).
     * Please note that you must approve RariFundManager to burn of the necessary amount of RFT.
     * @param currencyCode The currency code of the token to be withdrawn.
     * @param amount The amount of tokens to be withdrawn.
     */
    function withdraw(string calldata currencyCode, uint256 amount) external;
}

/**
 * COPYRIGHT © 2020 RARI CAPITAL, INC. ALL RIGHTS RESERVED.
 * Anyone is free to integrate the public (i.e., non-administrative) application programming interfaces (APIs) of the official Ethereum smart contract instances deployed by Rari Capital, Inc. in any application (commercial or noncommercial and under any license), provided that the application does not abuse the APIs or act against the interests of Rari Capital, Inc.
 * Anyone is free to study, review, and analyze the source code contained in this package.
 * Reuse (including deployment of smart contracts other than private testing on a private network), modification, redistribution, or sublicensing of any source code contained in this package is not permitted without the explicit permission of David Lucid of Rari Capital, Inc.
 * No one is permitted to use the software for any purpose other than those allowed by this license.
 * This license is liable to change at any time at the sole discretion of David Lucid of Rari Capital, Inc.
 */

pragma solidity 0.5.17;

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";

/**
 * @title IRariFundToken
 * @author David Lucid <[email protected]> (https://github.com/davidlucid)
 * @notice IRariFundToken is a simple interface for IRariFundToken used by Rari Governance.
 */
contract IRariFundToken is IERC20 {
    /*
     * @notice Destroys `amount` tokens from the caller, reducing the total supply.
     * @dev Claims RGT earned by `account` beforehand (so RariGovernanceTokenDistributor can continue distributing RGT considering the new RSPT balance of the caller).
     */
    function burn(uint256 amount) external;

    /**
     * @dev Sets or upgrades the RariGovernanceTokenDistributor of the RariFundToken. Caller must have the {MinterRole}.
     * @param newContract The address of the new RariGovernanceTokenDistributor contract.
     * @param force Boolean indicating if we should not revert on validation error.
     */
    function setGovernanceTokenDistributor(address payable newContract, bool force) external;
}

pragma solidity >=0.5.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

pragma solidity ^0.5.0;

import "@openzeppelin/upgrades/contracts/Initializable.sol";

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
contract Context is Initializable {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.5.0;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

pragma solidity ^0.5.0;

import "@openzeppelin/upgrades/contracts/Initializable.sol";

import "../../GSN/Context.sol";
import "../Roles.sol";

contract PauserRole is Initializable, Context {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    function initialize(address sender) public initializer {
        if (!isPauser(sender)) {
            _addPauser(sender);
        }
    }

    modifier onlyPauser() {
        require(isPauser(_msgSender()), "PauserRole: caller does not have the Pauser role");
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(_msgSender());
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }

    uint256[50] private ______gap;
}

pragma solidity ^0.5.0;

import "@openzeppelin/upgrades/contracts/Initializable.sol";

import "../GSN/Context.sol";
import "../access/roles/PauserRole.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is Initializable, Context, PauserRole {
    /**
     * @dev Emitted when the pause is triggered by a pauser (`account`).
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by a pauser (`account`).
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state. Assigns the Pauser role
     * to the deployer.
     */
    function initialize(address sender) public initializer {
        PauserRole.initialize(sender);

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
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Called by a pauser to pause, triggers stopped state.
     */
    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Called by a pauser to unpause, returns to normal state.
     */
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    uint256[50] private ______gap;
}

pragma solidity ^0.5.0;

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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.5.0;

import "@openzeppelin/upgrades/contracts/Initializable.sol";

import "../GSN/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Initializable, Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function initialize(address sender) public initializer {
        _owner = sender;
        emit OwnershipTransferred(address(0), _owner);
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    uint256[50] private ______gap;
}

pragma solidity ^0.5.0;

import "@openzeppelin/upgrades/contracts/Initializable.sol";

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
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
contract ERC20 is Initializable, Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
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
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
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
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
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
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
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
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

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
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

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
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

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
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }

    uint256[50] private ______gap;
}

pragma solidity ^0.5.0;

import "@openzeppelin/upgrades/contracts/Initializable.sol";

import "../../GSN/Context.sol";
import "./ERC20.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
contract ERC20Burnable is Initializable, Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev See {ERC20-_burnFrom}.
     */
    function burnFrom(address account, uint256 amount) public {
        _burnFrom(account, amount);
    }

    uint256[50] private ______gap;
}

pragma solidity ^0.5.0;

import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "./IERC20.sol";

/**
 * @dev Optional functions from the ERC20 standard.
 */
contract ERC20Detailed is Initializable, IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    function initialize(string memory name, string memory symbol, uint8 decimals) public initializer {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
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
     * Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    uint256[50] private ______gap;
}

pragma solidity ^0.5.0;

import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "./ERC20.sol";
import "../../lifecycle/Pausable.sol";

/**
 * @title Pausable token
 * @dev ERC20 with pausable transfers and allowances.
 *
 * Useful if you want to stop trades until the end of a crowdsale, or have
 * an emergency switch for freezing all token transfers in the event of a large
 * bug.
 */
contract ERC20Pausable is Initializable, ERC20, Pausable {
    function initialize(address sender) public initializer {
        Pausable.initialize(sender);
    }

    function transfer(address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transferFrom(from, to, value);
    }

    function approve(address spender, uint256 value) public whenNotPaused returns (bool) {
        return super.approve(spender, value);
    }

    function increaseAllowance(address spender, uint256 addedValue) public whenNotPaused returns (bool) {
        return super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public whenNotPaused returns (bool) {
        return super.decreaseAllowance(spender, subtractedValue);
    }

    uint256[50] private ______gap;
}

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

pragma solidity >=0.4.24 <0.7.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

