// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '../interface/IVolatilityOracle.sol';

contract VolatilityOracleOffChain is IVolatilityOracle {

    string  public symbol;
    address public signatory;
    //uint256 public delayAllowance;

    uint256 public timestamp;
    uint256 public volatility;

    constructor (string memory symbol_, address signatory_) {
        symbol = symbol_;
        signatory = signatory_;
        //delayAllowance = delayAllowance_;
    }

    // function setDelayAllowance(uint256 delayAllowance_) external {
    //     require(msg.sender == signatory, 'only signatory');
    //     delayAllowance = delayAllowance_;
    // }

    function getVolatility() external override view returns (uint256) {
        //require(block.timestamp - timestamp < delayAllowance, 'volatility expired');
        return volatility;
    }

    // update oracle volatility using off chain signed volatility
    // the signature must be verified in order for the volatility to be updated
    function updateVolatility(uint256 timestamp_, uint256 volatility_, uint8 v_, bytes32 r_, bytes32 s_) external override {
        require(msg.sender == signatory, 'only signatory');
        if (timestamp_ > timestamp) {
                timestamp = timestamp_;
                volatility = volatility_;
        }
                
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IVolatilityOracle {

    function getVolatility() external view returns (uint256);

    function updateVolatility(uint256 timestamp_, uint256 volatility_, uint8 v_, bytes32 r_, bytes32 s_) external;

}

{
  "optimizer": {
    "enabled": true,
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