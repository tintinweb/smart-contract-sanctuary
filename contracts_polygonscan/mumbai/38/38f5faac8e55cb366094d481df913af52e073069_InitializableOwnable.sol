/**
 *Submitted for verification at polygonscan.com on 2021-08-26
*/

// File: contracts/lib/InitializableOwnable.sol

/*

    Copyright 2021
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.6.9;
pragma experimental ABIEncoderV2;

/**
 * @title Ownable
 * @author Murciano207
 *
 * @notice Ownership related functions
 */
contract InitializableOwnable {
    address public _OWNER_;
    address public _NEW_OWNER_;
    bool internal _INITIALIZED_;

    // ============ Events ============

    event OwnershipTransferPrepared(address indexed previousOwner, address indexed newOwner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // ============ Modifiers ============

    modifier notInitialized() {
        require(!_INITIALIZED_, "Spook_INITIALIZED");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == _OWNER_, "NOT_OWNER");
        _;
    }

    // ============ Functions ============

    function initOwner(address newOwner) public notInitialized {
        _INITIALIZED_ = true;
        _OWNER_ = newOwner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        emit OwnershipTransferPrepared(_OWNER_, newOwner);
        _NEW_OWNER_ = newOwner;
    }

    function claimOwnership() public {
        require(msg.sender == _NEW_OWNER_, "INVALID_CLAIM");
        emit OwnershipTransferred(_OWNER_, _NEW_OWNER_);
        _OWNER_ = _NEW_OWNER_;
        _NEW_OWNER_ = address(0);
    }
}

// File: contracts/lib/SpookFactory.sol


interface ICloneFactory {
    function clone(address prototype) external returns (address proxy);
}

// introduction of proxy mode design: https://docs.openzeppelin.com/upgrades/2.8/
// minimum implementation of transparent proxy: https://eips.ethereum.org/EIPS/eip-1167

contract SpookFactory is ICloneFactory {
    function clone(address prototype) external override returns (address proxy) {
        bytes20 targetBytes = bytes20(prototype);
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(
                add(clone, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            proxy := create(0, clone, 0x37)
        }
        return proxy;
    }
}

// File: contracts/SpookStablePool/intf/ISpookSP.sol

interface ISpookSP {
    function init(
        address maintainer,
        address baseTokenAddress,
        address quoteTokenAddress,
        uint256 lpFeeRate,
        address mtFeeRateModel,
        uint256 i,
        uint256 k,
        bool isOpenTWAP
    ) external;

    function _BASE_TOKEN_() external view returns (address);

    function _QUOTE_TOKEN_() external view returns (address);

    function _I_() external view returns (uint256);

    function _MT_FEE_RATE_MODEL_() external view returns (address);

    function getVaultReserve() external view returns (uint256 baseReserve, uint256 quoteReserve);

    function sellBase(address to) external returns (uint256);

    function sellQuote(address to) external returns (uint256);

    function buyShares(address to) external returns (uint256,uint256,uint256);
}

// File: contracts/Factory/SpookStablePoolFactory.sol


interface ISpookStablePoolFactory {
    function createSpookStablePool(
        address baseToken,
        address quoteToken,
        uint256 lpFeeRate,
        uint256 i,
        uint256 k,
        bool isOpenTWAP
    ) external returns (address newStablePool);
}

/**
 * @title Spook StablePool Factory
 * @author Murciano207
 *
 * @notice Create And Register Spook Stable Pools
 */
contract SpookStablePoolFactory is InitializableOwnable {
    // ============ Templates ============

    address public immutable _CLONE_FACTORY_;
    address public immutable _DEFAULT_MAINTAINER_;
    address public immutable _DEFAULT_MT_FEE_RATE_MODEL_;
    address public _SpookSP_TEMPLATE_;

    // ============ Registry ============

    // base -> quote -> SpookSP address list
    mapping(address => mapping(address => address[])) public _REGISTRY_;
    // creator -> SpookSP address list
    mapping(address => address[]) public _USER_REGISTRY_;

    // ============ Events ============

    event NewSpookSP(address baseToken, address quoteToken, address creator, address SpookSP);

    event RemoveSpookSP(address SpookSP);

    // ============ Functions ============

    constructor(
        address cloneFactory,
        address SpookSPTemplate,
        address defaultMaintainer,
        address defaultMtFeeRateModel
    ) public {
        _CLONE_FACTORY_ = cloneFactory;
        _SpookSP_TEMPLATE_ = SpookSPTemplate;
        _DEFAULT_MAINTAINER_ = defaultMaintainer;
        _DEFAULT_MT_FEE_RATE_MODEL_ = defaultMtFeeRateModel;
    }

    function createSpookStablePool(
        address baseToken,
        address quoteToken,
        uint256 lpFeeRate,
        uint256 i,
        uint256 k,
        bool isOpenTWAP
    ) external returns (address newStablePool) {
        newStablePool = ICloneFactory(_CLONE_FACTORY_).clone(_SpookSP_TEMPLATE_);
        {
            ISpookSP(newStablePool).init(
                _DEFAULT_MAINTAINER_,
                baseToken,
                quoteToken,
                lpFeeRate,
                _DEFAULT_MT_FEE_RATE_MODEL_,
                i,
                k,
                isOpenTWAP
            );
        }
        _REGISTRY_[baseToken][quoteToken].push(newStablePool);
        _USER_REGISTRY_[tx.origin].push(newStablePool);
        emit NewSpookSP(baseToken, quoteToken, tx.origin, newStablePool);
    }

    // ============ Admin Operation Functions ============

    function updateSpookSPTemplate(address _newSpookSPTemplate) external onlyOwner {
        _SpookSP_TEMPLATE_ = _newSpookSPTemplate;
    }

    function addPoolByMurciano207(
        address creator,
        address baseToken,
        address quoteToken,
        address pool
    ) external onlyOwner {
        _REGISTRY_[baseToken][quoteToken].push(pool);
        _USER_REGISTRY_[creator].push(pool);
        emit NewSpookSP(baseToken, quoteToken, creator, pool);
    }

    function removePoolByMurciano207(
        address creator,
        address baseToken,
        address quoteToken,
        address pool
    ) external onlyOwner {
        address[] memory registryList = _REGISTRY_[baseToken][quoteToken];
        for (uint256 i = 0; i < registryList.length; i++) {
            if (registryList[i] == pool) {
                registryList[i] = registryList[registryList.length - 1];
                break;
            }
        }
        _REGISTRY_[baseToken][quoteToken] = registryList;
        _REGISTRY_[baseToken][quoteToken].pop();
        address[] memory userRegistryList = _USER_REGISTRY_[creator];
        for (uint256 i = 0; i < userRegistryList.length; i++) {
            if (userRegistryList[i] == pool) {
                userRegistryList[i] = userRegistryList[userRegistryList.length - 1];
                break;
            }
        }
        _USER_REGISTRY_[creator] = userRegistryList;
        _USER_REGISTRY_[creator].pop();
        emit RemoveSpookSP(pool);
    }

    // ============ View Functions ============

    function getSpookPool(address baseToken, address quoteToken)
        external
        view
        returns (address[] memory machines)
    {
        return _REGISTRY_[baseToken][quoteToken];
    }

    function getSpookPoolBidirection(address token0, address token1)
        external
        view
        returns (address[] memory baseToken0Machines, address[] memory baseToken1Machines)
    {
        return (_REGISTRY_[token0][token1], _REGISTRY_[token1][token0]);
    }

    function getSpookPoolByUser(address user) external view returns (address[] memory machines) {
        return _USER_REGISTRY_[user];
    }
}