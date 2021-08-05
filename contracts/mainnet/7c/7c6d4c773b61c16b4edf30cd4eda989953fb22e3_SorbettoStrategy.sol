/**
 *Submitted for verification at Etherscan.io on 2021-06-28
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface ISorbettoStrategy {
    /// @notice Period of time that we observe for price slippage
    /// @return time in seconds
    function twapDuration() external view returns (uint32);

    /// @notice Maximum deviation of time waited avarage price in ticks
    function maxTwapDeviation() external view returns (int24);

    /// @notice Tick multuplier for base range calculation
    function tickRangeMultiplier() external view returns (int24);

    /// @notice The protocol's fee denominated in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function protocolFee() external view returns (uint24);

    /// @notice The price impact percentage during swap denominated in hundredths of a bip, i.e. 1e-6
    /// @return The max price impact percentage
    function priceImpactPercentage() external view returns (uint24);
}

/// @title Permissioned Sorbetto variables
/// @notice Contains Sorbetto variables that may only be called by the governance
contract SorbettoStrategy is ISorbettoStrategy {

    // Address of the Sorbetto's strategy owner
    address public governance;
    // Pending to claim ownership address
    address public pendingGovernance;

    /// @inheritdoc ISorbettoStrategy
    uint32 public override twapDuration;
    /// @inheritdoc ISorbettoStrategy
    int24 public override maxTwapDeviation;
    /// @inheritdoc ISorbettoStrategy
    int24 public override tickRangeMultiplier;
    /// @inheritdoc ISorbettoStrategy
    uint24 public override protocolFee;
    /// @inheritdoc ISorbettoStrategy
    uint24 public override priceImpactPercentage;
    
    
    /**
     * @param _twapDuration TWAP duration in seconds for rebalance check
     * @param _maxTwapDeviation Max deviation from TWAP during rebalance
     * @param _tickRangeMultiplier Used to determine base order range
     * @param _protocolFee  The protocol's fee in hundredths of a bip, i.e. 1e-6
     * @param _priceImpactPercentage The price impact percentage during swap in hundredths of a bip, i.e. 1e-6
     */
    constructor(
        uint32 _twapDuration,
        int24 _maxTwapDeviation,
        int24 _tickRangeMultiplier,
        uint24 _protocolFee,
        uint24 _priceImpactPercentage
    ) {
        twapDuration = _twapDuration;
        maxTwapDeviation = _maxTwapDeviation;
        tickRangeMultiplier = _tickRangeMultiplier;
        protocolFee = _protocolFee;
        priceImpactPercentage = _priceImpactPercentage;
        governance = msg.sender;

        require(_maxTwapDeviation >= 0, "maxTwapDeviation");
        require(_twapDuration > 0, "twapDuration");
        require(_protocolFee < 1e6 && _protocolFee > 0, "PF");
        require(_priceImpactPercentage < 1e6 && _priceImpactPercentage > 0, "PIP");
    }

    modifier onlyGovernance {
        require(msg.sender == governance, "NOT ALLOWED");
        _;
    }

    function setTwapDuration(uint32 _twapDuration) external onlyGovernance {
        require(_twapDuration > 0, "twapDuration");
        twapDuration = _twapDuration;
    }

    function setMaxTwapDeviation(int24 _maxTwapDeviation) external onlyGovernance {
        require(_maxTwapDeviation > 0, "PF");
        maxTwapDeviation = _maxTwapDeviation;
    }

    function setTickRange(int24 _tickRangeMultiplier) external onlyGovernance {
        tickRangeMultiplier = _tickRangeMultiplier;
    }

    function setProtocolFee(uint16 _protocolFee) external onlyGovernance {
        require(_protocolFee < 1e6 && _protocolFee > 0, "PF");
        protocolFee = _protocolFee;
    }

    function setPriceImpact(uint16 _priceImpactPercentage) external onlyGovernance {
        require(_priceImpactPercentage < 1e6 && _priceImpactPercentage > 0, "PIP");
        priceImpactPercentage = _priceImpactPercentage;
    }

    
     /**
     * @notice `setGovernance()` should be called by the existing governance
     * address prior to calling this function.
     */
    function setGovernance(address _governance) external onlyGovernance {
        pendingGovernance = _governance;
    }

    /**
     * @notice Governance address is not updated until the new governance
     * address has called `acceptGovernance()` to accept this responsibility.
     */
    function acceptGovernance() external {
        require(msg.sender == pendingGovernance, "PG");
        governance = msg.sender;
    }
}