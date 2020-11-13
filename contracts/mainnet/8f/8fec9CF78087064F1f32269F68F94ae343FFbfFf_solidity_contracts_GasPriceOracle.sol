/**
▓▓▌ ▓▓ ▐▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄
▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
  ▓▓▓▓▓▓    ▓▓▓▓▓▓▓▀    ▐▓▓▓▓▓▓    ▐▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
  ▓▓▓▓▓▓▄▄▓▓▓▓▓▓▓▀      ▐▓▓▓▓▓▓▄▄▄▄         ▓▓▓▓▓▓▄▄▄▄         ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
  ▓▓▓▓▓▓▓▓▓▓▓▓▓▀        ▐▓▓▓▓▓▓▓▓▓▓         ▓▓▓▓▓▓▓▓▓▓▌        ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
  ▓▓▓▓▓▓▀▀▓▓▓▓▓▓▄       ▐▓▓▓▓▓▓▀▀▀▀         ▓▓▓▓▓▓▀▀▀▀         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀
  ▓▓▓▓▓▓   ▀▓▓▓▓▓▓▄     ▐▓▓▓▓▓▓     ▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌
▓▓▓▓▓▓▓▓▓▓ █▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓

                           Trust math, not hardware.
*/

pragma solidity 0.5.17;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";

/// @dev Interface expected to be implemented by contracts added as a gas price
/// oracle consumers. Consumers are notified by GasPriceOracle every time gas
/// price change is finalized by calling their refreshGasPrice function. Each
/// consumer may decide to pull the new value from the oracle immediatelly or
/// at the moment right for the consumer.
/// Consumers must be trusted contracts whose refreshGasPrice must always
/// succeed and never consume excessive gas.
interface GasPriceOracleConsumer {
    function refreshGasPrice() external;
}

/// @notice Oracle presenting the current gas price. The oracle is manually
/// updated by its owner.
contract GasPriceOracle is Ownable {
    using SafeMath for uint256;

    event GasPriceUpdated(uint256 newValue);

    uint256 public constant governanceDelay = 1 hours; 

    uint256 public gasPrice;

    uint256 public newGasPrice;
    uint256 public gasPriceChangeInitiated;

    address[] public consumerContracts;

    modifier onlyAfterGovernanceDelay {
        require(gasPriceChangeInitiated > 0, "Change not initiated");
        require(
            block.timestamp.sub(gasPriceChangeInitiated) >= governanceDelay,
            "Governance delay has not elapsed"
        );
        _;
    }

    /// @notice Initialize the gas price update. Change is finalized after
    /// the governance delay elapses.
    /// @param _newGasPrice New gas price in wei.
    function beginGasPriceUpdate(uint256 _newGasPrice) public onlyOwner {
        newGasPrice = _newGasPrice;
        gasPriceChangeInitiated = block.timestamp;
    }

    /// @notice Finalizes the gas price update. Finalization may happen only
    /// after the governance delay elapses.
    function finalizeGasPriceUpdate() public onlyAfterGovernanceDelay {
        gasPrice = newGasPrice;

        newGasPrice = 0;
        gasPriceChangeInitiated = 0;

        emit GasPriceUpdated(gasPrice);
        
        for (uint256 i = 0; i < consumerContracts.length; i++) {
            GasPriceOracleConsumer(consumerContracts[i]).refreshGasPrice();
        }
    }

    /// @notice Adds a new consumer contract to the oracle. Consumer contract is
    /// expected to implement GasPriceOracleConsumer interface and receives
    /// a notifcation every time gas price update is finalized.
    /// @param consumerContract The new consumer contract to add to the oracle.
    function addConsumerContract(address consumerContract) public onlyOwner {
        consumerContracts.push(consumerContract);
    }

    /// @notice Removes consumer contract from the oracle by its index.
    /// @param index Index of the consumer contract to be removed.
    function removeConsumerContract(uint256 index) public onlyOwner {
        require(index < consumerContracts.length, "Invalid index");
        consumerContracts[index] = consumerContracts[consumerContracts.length - 1];
        consumerContracts.length--;
    }

    /// @notice Returns all consumer contracts currently registered in the
    /// oracle.
    function getConsumerContracts() public view returns (address[] memory) {
        return consumerContracts;
    }
}