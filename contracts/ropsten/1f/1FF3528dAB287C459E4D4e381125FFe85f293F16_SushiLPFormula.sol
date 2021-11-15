// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../lib/VotingPowerFormula.sol";

/**
 * @title SushiLPFormula
 * @dev Convert Sushi LP tokens to voting power
 */
contract SushiLPFormula is VotingPowerFormula {

    /// @notice Current owner of this contract
    address public owner;

    /// @notice Conversion rate of token to voting power (measured in bips: 10,000 bips = 1%)
    uint32 public conversionRate;

    /// @notice Event emitted when the owner of the contract is updated
    event ChangedOwner(address indexed oldOwner, address indexed newOwner);

    /// @notice Event emitted when the conversion rate of the contract is changed
    event ConversionRateChanged(uint32 oldRate, uint32 newRate);

    /// @notice only owner can call function
    modifier onlyOwner {
        require(msg.sender == owner, "not owner");
        _;
    }

    /**
     * @notice Construct a new voting power formula contract
     * @param _owner contract owner
     * @param _cvrRate the conversion rate in bips
     */
    constructor(address _owner, uint32 _cvrRate) {
        owner = _owner;
        emit ChangedOwner(address(0), owner);

        conversionRate = _cvrRate;
        emit ConversionRateChanged(uint32(0), conversionRate);
    }

    /**
     * @notice Convert token amount to voting power
     * @param amount token amount
     * @return voting power amount
     */
    function convertTokensToVotingPower(uint256 amount) external view override returns (uint256) {
        return amount * conversionRate / 1000000;
    }

    /**
     * @notice Set conversion rate of contract
     * @param newConversionRate New conversion rate
     */
    function setConversionRate(uint32 newConversionRate) external onlyOwner {
        emit ConversionRateChanged(conversionRate, newConversionRate);
        conversionRate = newConversionRate;
    }

    /**
     * @notice Change owner of contract
     * @param newOwner New owner address
     */
    function changeOwner(address newOwner) external onlyOwner {
        emit ChangedOwner(owner, newOwner);
        owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract VotingPowerFormula {
   function convertTokensToVotingPower(uint256 amount) external view virtual returns (uint256);
}

