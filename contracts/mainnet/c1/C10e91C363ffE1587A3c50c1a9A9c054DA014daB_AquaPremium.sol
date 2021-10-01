// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IAquaPremium {
    function getAquaPremium() external view returns (uint256);

    function calculatePremium(
        uint256 initiationTimestamp,
        uint256 initialPremium,
        uint256 aquaPoolPremium,
        uint256 aquaAmount
    ) external view returns (uint256, uint256);
}

contract AquaPremium is IAquaPremium {
    uint256 public aquaPremium;
    address public timelockContract;

    modifier isTimelockContract() {
        require(msg.sender == timelockContract, "AQUA PREMIUM :: NOT TIMELOCK CONTRACT");
        _;
    }

    event PremiumUpdated(uint256 oldPremium, uint256 newPremium);

    constructor(uint256 initialAquaPremium, address timelockContractAddress) {
        aquaPremium = initialAquaPremium; // 2500
        timelockContract = timelockContractAddress;
    }

    function updateAquaPremium(uint256 newAquaPremium) external isTimelockContract {
        emit PremiumUpdated(aquaPremium, newAquaPremium);
        _updateAquaPremium(newAquaPremium);
    }

    function _updateAquaPremium(uint256 newAquaPremium) internal {
        aquaPremium = newAquaPremium;
    }

    function getAquaPremium() external view override returns (uint256) {
        return aquaPremium;
    }

    function calculatePremium(
        /* not used in this version of the AquaPremium */
        uint256 initiationTimestamp,
        /* not used in this version of the AquaPremium */
        uint256 initialPremium,
        uint256 aquaPoolPremium,
        uint256 aquaAmount
    ) external view override returns (uint256, uint256) {
        if (aquaPoolPremium == 0) {
            return ((aquaAmount * aquaPremium) / 10000, aquaPremium);
        } else {
            return ((aquaAmount * aquaPoolPremium) / 10000, aquaPoolPremium);
        }
    }
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}