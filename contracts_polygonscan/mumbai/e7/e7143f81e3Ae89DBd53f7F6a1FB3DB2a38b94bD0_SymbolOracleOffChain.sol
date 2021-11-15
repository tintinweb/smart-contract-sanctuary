// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '../interface/IOracleWithUpdate.sol';
import "../governance/IProtocolParameters.sol";

contract SymbolOracleOffChain is IOracleWithUpdate {

    address public immutable signatory;
    IProtocolParameters private _protocolParameters;

    uint256 public timestamp;
    uint256 public price;

    constructor (address signatory_, address protocolParameters_) {
        signatory = signatory_;
         _protocolParameters = IProtocolParameters(protocolParameters_);
    }

    function getPrice() external override view returns (uint256) {
        require(block.timestamp - timestamp <= 
                 _protocolParameters.oracleDelay(), 'price expired');
        return price;
    }

    // update oracle price using off chain signed price
    // the signature must be verified in order for the price to be updated
    function updatePrice(address address_, uint256 timestamp_, uint256 price_, uint8 v_, bytes32 r_, bytes32 s_) external override {
        uint256 lastTimestamp = timestamp;
        if (timestamp_ > lastTimestamp) {
            if (v_ == 27 || v_ == 28) {
                bytes32 message = keccak256(abi.encodePacked(address_, timestamp_, price_));
                bytes32 hash = keccak256(abi.encodePacked('\x19Ethereum Signed Message:\n32', message));
                address signer = ecrecover(hash, v_, r_, s_);
                if (signer == signatory) {
                    timestamp = timestamp_;
                    price = price_;
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IOracleWithUpdate {
    function getPrice() external returns (uint256);

    function updatePrice(
        address address_,
        uint256 timestamp,
        uint256 price,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IProtocolParameters {
    function minPoolMarginRatio() external view returns (int256);

    function minInitialMarginRatio() external view returns (int256);

    function minMaintenanceMarginRatio() external view returns (int256);

    function minLiquidationReward() external view returns (int256);

    function maxLiquidationReward() external view returns (int256);

    function liquidationCutRatio() external view returns (int256);

    function protocolFeeCollectRatio() external view returns (int256);

    function symbolOracleAddress() external view returns (address);

    function symbolMultiplier() external view returns (int256);

    function symbolFeeRatio() external view returns (int256);

    function symbolFundingRateCoefficient() external view returns (int256);

    function oracleDelay() external view returns (uint256);
}

