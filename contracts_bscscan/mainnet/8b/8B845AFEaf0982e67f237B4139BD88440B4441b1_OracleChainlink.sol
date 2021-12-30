// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './IOracle.sol';
import '../library/SafeMath.sol';
import '../utils/NameVersion.sol';

contract OracleChainlink is IOracle, NameVersion {

    using SafeMath for int256;

    string  public symbol;
    bytes32 public immutable symbolId;

    IChainlinkFeed public immutable feed;
    uint256 public immutable feedDecimals;

    constructor (string memory symbol_, address feed_) NameVersion('OracleChainlink', '3.0.1') {
        symbol = symbol_;
        symbolId = keccak256(abi.encodePacked(symbol_));
        feed = IChainlinkFeed(feed_);
        feedDecimals = IChainlinkFeed(feed_).decimals();
    }

    function timestamp() external view returns (uint256) {
        return feed.latestTimestamp();
    }

    function value() public view returns (uint256 val) {
        val = feed.latestAnswer().itou();
        if (feedDecimals != 18) {
            val *= 10 ** (18 - feedDecimals);
        }
    }

    function getValue() external view returns (uint256 val) {
        require((val = value()) != 0, 'OracleChainlink.getValue: 0');
    }

}

interface IChainlinkFeed {
    function decimals() external view returns (uint8);
    function latestTimestamp() external view returns (uint256);
    function latestAnswer() external view returns (int256);
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

library SafeMath {

    uint256 constant UMAX = 2 ** 255 - 1;
    int256  constant IMIN = -2 ** 255;

    function utoi(uint256 a) internal pure returns (int256) {
        require(a <= UMAX, 'SafeMath.utoi: overflow');
        return int256(a);
    }

    function itou(int256 a) internal pure returns (uint256) {
        require(a >= 0, 'SafeMath.itou: underflow');
        return uint256(a);
    }

    function abs(int256 a) internal pure returns (int256) {
        require(a != IMIN, 'SafeMath.abs: overflow');
        return a >= 0 ? a : -a;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function max(int256 a, int256 b) internal pure returns (int256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a <= b ? a : b;
    }

    function min(int256 a, int256 b) internal pure returns (int256) {
        return a <= b ? a : b;
    }

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

interface INameVersion {

    function nameId() external view returns (bytes32);

    function versionId() external view returns (bytes32);

}