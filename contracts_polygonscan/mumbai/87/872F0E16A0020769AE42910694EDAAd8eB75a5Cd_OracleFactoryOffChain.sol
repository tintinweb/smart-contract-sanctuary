// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './OracleOffChain.sol';
import './VolatilityOracleOffChain.sol';

contract OracleFactoryOffChain {

    event CreateOracleOffChain(string symbol, address signer, uint256 delayAllowance, address oracle);

    event CreateVolatilityOracleOffChain(string symbol, address signer, uint256 delayAllowance, address oracle);

    // symbol => oracle
    mapping (string => address) _oracles;
    // symbol => volatilityOracle
    mapping (string => address) _volatilityOracles;

    function getOracle(string memory symbol) external view returns (address) {
        return _oracles[symbol];
    }

    function getVolatilityOracle(string memory symbol) external view returns (address) {
        return _volatilityOracles[symbol];
    }

    function createOracle(string memory symbol, address signer, uint256 delayAllowance) external returns (address) {
        address oracle = address(new OracleOffChain(symbol, signer, delayAllowance));
        _oracles[symbol] = oracle;
        emit CreateOracleOffChain(symbol, signer, delayAllowance, oracle);
        return oracle;
    }

    function createVolatilityOracle(string memory symbol, address signer, uint256 delayAllowance) external returns (address) {
        address oracle = address(new VolatilityOracleOffChain(symbol, signer, delayAllowance));
        _volatilityOracles[symbol] = oracle;
        emit CreateVolatilityOracleOffChain(symbol, signer, delayAllowance, oracle);
        return oracle;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

contract OracleOffChain {

    string  public symbol;
    address public signer;
    uint256 public delayAllowance;

    uint256 public timestamp;
    uint256 public price;

    constructor (string memory symbol_, address signer_, uint256 delayAllowance_) {
        symbol = symbol_;
        signer = signer_;
        delayAllowance = delayAllowance_;
    }

    function setSigner(address signer_) external {
        require(msg.sender == signer, 'only signer');
        signer = signer_;
    }

    function setDelayAllowance(uint256 delayAllowance_) external {
        require(msg.sender == signer, 'only signer');
        delayAllowance = delayAllowance_;
    }

    function getPrice() external view returns (uint256) {
        require(block.timestamp - timestamp < delayAllowance, 'price expired');
        return price;
    }

    // update oracle price using off chain signed price
    // the signature must be verified in order for the price to be updated
    function updatePrice(uint256 timestamp_, uint256 price_, uint8 v_, bytes32 r_, bytes32 s_) external {
        uint256 lastTimestamp = timestamp;
        if (timestamp_ > lastTimestamp) {
            if (v_ == 27 || v_ == 28) {
                bytes32 message = keccak256(abi.encodePacked(symbol, timestamp_, price_));
                bytes32 hash = keccak256(abi.encodePacked('\x19Ethereum Signed Message:\n32', message));
                address signatory = ecrecover(hash, v_, r_, s_);
                if (signatory == signer) {
                    timestamp = timestamp_;
                    price = price_;
                }
            }
        }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

contract VolatilityOracleOffChain {

    string  public symbol;
    address public signer;
    uint256 public delayAllowance;

    uint256 public timestamp;
    uint256 public volatility;

    constructor (string memory symbol_, address signer_, uint256 delayAllowance_) {
        symbol = symbol_;
        signer = signer_;
        delayAllowance = delayAllowance_;
    }

    function setSigner(address signer_) external {
        require(msg.sender == signer, 'only signer');
        signer = signer_;
    }

    function setDelayAllowance(uint256 delayAllowance_) external {
        require(msg.sender == signer, 'only signer');
        delayAllowance = delayAllowance_;
    }

    function getVolatility() external view returns (uint256) {
        require(block.timestamp - timestamp < delayAllowance, 'volatility expired');
        return volatility;
    }

    // update oracle volatility using off chain signed volatility
    // the signature must be verified in order for the volatility to be updated
    function updateVolatility(uint256 timestamp_, uint256 volatility_, uint8 v_, bytes32 r_, bytes32 s_) external {
        uint256 lastTimestamp = timestamp;
        if (timestamp_ > lastTimestamp) {
            if (v_ == 27 || v_ == 28) {
                bytes32 message = keccak256(abi.encodePacked(symbol, timestamp_, volatility_));
                bytes32 hash = keccak256(abi.encodePacked('\x19Ethereum Signed Message:\n32', message));
                address signatory = ecrecover(hash, v_, r_, s_);
                if (signatory == signer) {
                    timestamp = timestamp_;
                    volatility = volatility_;
                }
            }
        }
    }

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