// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './IOracleOffChain.sol';
import '../utils/NameVersion.sol';

contract OracleOffChain is IOracleOffChain, NameVersion {

    string  public symbol;
    bytes32 public immutable symbolId;
    address public immutable signer;
    uint256 public immutable delayAllowance;

    uint256 public timestamp;
    uint256 public value;

    constructor (string memory symbol_, address signer_, uint256 delayAllowance_) NameVersion('OracleOffChain', '3.0.1') {
        symbol = symbol_;
        symbolId = keccak256(abi.encodePacked(symbol_));
        signer = signer_;
        delayAllowance = delayAllowance_;
    }

    function getValue() external view returns (uint256 val) {
        if (block.timestamp >= timestamp + delayAllowance) {
            revert(string(abi.encodePacked(
                bytes('OracleOffChain.getValue: '), bytes(symbol), bytes(' expired')
            )));
        }
        require((val = value) != 0, 'OracleOffChain.getValue: 0');
    }

    function updateValue(
        uint256 timestamp_,
        uint256 value_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) external returns (bool)
    {
        uint256 lastTimestamp = timestamp;
        if (timestamp_ > lastTimestamp) {
            if (v_ == 27 || v_ == 28) {
                bytes32 message = keccak256(abi.encodePacked(symbolId, timestamp_, value_));
                bytes32 hash = keccak256(abi.encodePacked('\x19Ethereum Signed Message:\n32', message));
                address signatory = ecrecover(hash, v_, r_, s_);
                if (signatory == signer) {
                    timestamp = timestamp_;
                    value = value_;
                    emit NewValue(timestamp_, value_);
                    return true;
                }
            }
        }
        return false;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './IOracle.sol';

interface IOracleOffChain is IOracle {

    event NewValue(uint256 indexed timestamp, uint256 indexed value);

    function signer() external view returns (address);

    function delayAllowance() external view returns (uint256);

    function updateValue(
        uint256 timestamp,
        uint256 value,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (bool);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './INameVersion.sol';

/**
 * @dev Convenience contract for name and version information
 */
abstract contract NameVersion is INameVersion {

    bytes32 public immutable nameId;
    bytes32 public immutable versionId;

    constructor (string memory name, string memory version) {
        nameId = keccak256(abi.encodePacked(name));
        versionId = keccak256(abi.encodePacked(version));
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '../utils/INameVersion.sol';

interface IOracle is INameVersion {

    function symbol() external view returns (string memory);

    function symbolId() external view returns (bytes32);

    function timestamp() external view returns (uint256);

    function value() external view returns (uint256);

    function getValue() external view returns (uint256);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface INameVersion {

    function nameId() external view returns (bytes32);

    function versionId() external view returns (bytes32);

}