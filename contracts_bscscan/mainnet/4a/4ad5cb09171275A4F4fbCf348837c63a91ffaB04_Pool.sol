// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './IPool.sol';
import './PoolStorage.sol';

contract Pool is PoolStorage {

    function setImplementation(address newImplementation) external _onlyAdmin_ {
        require(
            IPool(newImplementation).nameId() == keccak256(abi.encodePacked('PoolImplementation')),
            'Pool.setImplementation: not pool implementation'
        );
        implementation = newImplementation;
        emit NewImplementation(newImplementation);
    }

    function setProtocolFeeCollector(address newProtocolFeeCollector) external _onlyAdmin_ {
        protocolFeeCollector = newProtocolFeeCollector;
        emit NewProtocolFeeCollector(newProtocolFeeCollector);
    }

    fallback() external payable {
        _delegate();
    }

    receive() external payable {

    }

    function _delegate() internal {
        address imp = implementation;
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), imp, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '../utils/INameVersion.sol';
import '../utils/IAdmin.sol';

interface IPool is INameVersion, IAdmin {

    function implementation() external view returns (address);

    function protocolFeeCollector() external view returns (address);

    function liquidity() external view returns (int256);

    function lpsPnl() external view returns (int256);

    function cumulativePnlPerLiquidity() external view returns (int256);

    function protocolFeeAccrued() external view returns (int256);

    function setImplementation(address newImplementation) external;

    function addMarket(address market) external;

    function approveSwapper(address underlying) external;

    function collectProtocolFee() external;

    function claimVenusLp(address account) external;

    function claimVenusTrader(address account) external;

    struct OracleSignature {
        bytes32 oracleSymbolId;
        uint256 timestamp;
        uint256 value;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    function addLiquidity(address underlying, uint256 amount, OracleSignature[] memory oracleSignatures) external payable;

    function removeLiquidity(address underlying, uint256 amount, OracleSignature[] memory oracleSignatures) external;

    function addMargin(address underlying, uint256 amount, OracleSignature[] memory oracleSignatures) external payable;

    function removeMargin(address underlying, uint256 amount, OracleSignature[] memory oracleSignatures) external;

    function trade(string memory symbolName, int256 tradeVolume, OracleSignature[] memory oracleSignatures) external;

    function liquidate(uint256 pTokenId, OracleSignature[] memory oracleSignatures) external;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '../utils/Admin.sol';

abstract contract PoolStorage is Admin {

    // admin will be truned in to Timelock after deployment

    event NewImplementation(address newImplementation);

    event NewProtocolFeeCollector(address newProtocolFeeCollector);

    bool internal _mutex;

    modifier _reentryLock_() {
        require(!_mutex, 'Pool: reentry');
        _mutex = true;
        _;
        _mutex = false;
    }

    address public implementation;

    address public protocolFeeCollector;

    // underlying => vToken, supported markets
    mapping (address => address) public markets;

    struct LpInfo {
        address vault;
        int256 amountB0;
        int256 liquidity;
        int256 cumulativePnlPerLiquidity;
    }

    // lTokenId => LpInfo
    mapping (uint256 => LpInfo) public lpInfos;

    struct TdInfo {
        address vault;
        int256 amountB0;
    }

    // pTokenId => TdInfo
    mapping (uint256 => TdInfo) public tdInfos;

    int256 public liquidity;

    int256 public lpsPnl;

    int256 public cumulativePnlPerLiquidity;

    int256 public protocolFeeAccrued;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface INameVersion {

    function nameId() external view returns (bytes32);

    function versionId() external view returns (bytes32);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IAdmin {

    event NewAdmin(address indexed newAdmin);

    function admin() external view returns (address);

    function setAdmin(address newAdmin) external;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './IAdmin.sol';

abstract contract Admin is IAdmin {

    address public admin;

    modifier _onlyAdmin_() {
        require(msg.sender == admin, 'Admin: only admin');
        _;
    }

    constructor () {
        admin = msg.sender;
        emit NewAdmin(admin);
    }

    function setAdmin(address newAdmin) external _onlyAdmin_ {
        admin = newAdmin;
        emit NewAdmin(newAdmin);
    }

}