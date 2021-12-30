// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './IOracle.sol';
import '../token/IERC20.sol';
import '../utils/NameVersion.sol';

contract OracleWoo is IOracle, NameVersion {

    string  public symbol;
    bytes32 public immutable symbolId;

    IWooracleV1 public immutable feed;
    uint256 public immutable baseDecimals;
    uint256 public immutable quoteDecimals;

    constructor (string memory symbol_, address feed_) NameVersion('OracleWoo', '3.0.1') {
        symbol = symbol_;
        symbolId = keccak256(abi.encodePacked(symbol_));
        feed = IWooracleV1(feed_);
        baseDecimals = IERC20(IWooracleV1(feed_)._BASE_TOKEN_()).decimals();
        quoteDecimals = IERC20(IWooracleV1(feed_)._QUOTE_TOKEN_()).decimals();
    }

    function timestamp() external pure returns (uint256) {
        revert('OracleWoo.timestamp: no timestamp');
    }

    function value() public view returns (uint256 val) {
        val = feed._I_();
        if (baseDecimals != quoteDecimals) {
            val = val * (10 ** baseDecimals) / (10 ** quoteDecimals);
        }
    }

    function getValue() external view returns (uint256 val) {
        require((val = value()) != 0, 'OracleWoo.getValue: 0');
    }

}

interface IWooracleV1 {
    function _BASE_TOKEN_() external view returns (address);
    function _QUOTE_TOKEN_() external view returns (address);
    function _I_() external view returns (uint256);
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

interface IERC20 {

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    event Transfer(address indexed from, address indexed to, uint256 amount);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);

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