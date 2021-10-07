/**
 *Submitted for verification at arbiscan.io on 2021-09-25
*/

// File: contracts/lib/InitializableOwnable.sol

/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.6.9;
pragma experimental ABIEncoderV2;

/**
 * @title Ownable
 * @author DODO Breeder
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
        require(!_INITIALIZED_, "DODO_INITIALIZED");
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

// File: contracts/DODOVendingMachine/intf/IDVM.sol


interface IDVM {
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

    function _BASE_TOKEN_() external returns (address);

    function _QUOTE_TOKEN_() external returns (address);

    function _MT_FEE_RATE_MODEL_() external returns (address);

    function getVaultReserve() external returns (uint256 baseReserve, uint256 quoteReserve);

    function sellBase(address to) external returns (uint256);

    function sellQuote(address to) external returns (uint256);

    function buyShares(address to) external returns (uint256,uint256,uint256);

    function addressToShortString(address _addr) external pure returns (string memory);

    function getMidPrice() external view returns (uint256 midPrice);

    function sellShares(
        uint256 shareAmount,
        address to,
        uint256 baseMinAmount,
        uint256 quoteMinAmount,
        bytes calldata data,
        uint256 deadline
    ) external  returns (uint256 baseAmount, uint256 quoteAmount);

}

// File: contracts/GeneralizedFragment/intf/IFragment.sol



interface IFragment {

    function init(
      address dvm, 
      address vaultPreOwner,
      address collateralVault,
      uint256 totalSupply, 
      uint256 ownerRatio,
      uint256 buyoutTimestamp,
      address defaultMaintainer,
      address buyoutModel,
      uint256 distributionRatio,
      string memory fragSymbol
    ) external;

    function buyout(address newVaultOwner) external;

    function redeem(address to) external;

    function _QUOTE_() external view returns (address);

    function _COLLATERAL_VAULT_() external view returns (address);

    function _DVM_() external view returns (address);

    function totalSupply() external view returns (uint256);
}

// File: contracts/Factory/Registries/DODONFTRegistry.sol



interface IDODONFTRegistry {
    function addRegistry(
        address vault,
        address fragment, 
        address quoteToken,
        address dvm
    ) external;

    function removeRegistry(address fragment) external;
}

/**
 * @title DODONFT Registry
 * @author DODO Breeder
 *
 * @notice Register DODONFT Pools 
 */
contract DODONFTRegistry is InitializableOwnable, IDODONFTRegistry {

    mapping (address => bool) public isAdminListed;
    
    // ============ Registry ============
    // Vault -> Frag
    mapping(address => address) public _VAULT_FRAG_REGISTRY_;

    // base -> quote -> DVM address list
    mapping(address => mapping(address => address[])) public _REGISTRY_;

    // ============ Events ============

    event NewRegistry(
        address vault,
        address fragment,
        address dvm
    );

    event RemoveRegistry(address fragment);


    // ============ Admin Operation Functions ============

    function addRegistry(
        address vault,
        address fragment, 
        address quoteToken,
        address dvm
    ) override external {
        require(isAdminListed[msg.sender], "ACCESS_DENIED");
        _VAULT_FRAG_REGISTRY_[vault] = fragment;
        _REGISTRY_[fragment][quoteToken].push(dvm);
        emit NewRegistry(vault, fragment, dvm);
    }

    function removeRegistry(address fragment) override external {
        require(isAdminListed[msg.sender], "ACCESS_DENIED");
        address vault = IFragment(fragment)._COLLATERAL_VAULT_();
        address dvm = IFragment(fragment)._DVM_();

        _VAULT_FRAG_REGISTRY_[vault] = address(0);

        address quoteToken = IDVM(dvm)._QUOTE_TOKEN_();
        address[] memory registryList = _REGISTRY_[fragment][quoteToken];
        for (uint256 i = 0; i < registryList.length; i++) {
            if (registryList[i] == dvm) {
                if(i != registryList.length - 1) {
                    _REGISTRY_[fragment][quoteToken][i] = _REGISTRY_[fragment][quoteToken][registryList.length - 1];
                }                
                _REGISTRY_[fragment][quoteToken].pop();
                break;
            }
        }

        emit RemoveRegistry(fragment);
    }

    function addAdminList (address contractAddr) external onlyOwner {
        isAdminListed[contractAddr] = true;
    }

    function removeAdminList (address contractAddr) external onlyOwner {
        isAdminListed[contractAddr] = false;
    }

    function getDODOPool(address baseToken, address quoteToken)
        external
        view
        returns (address[] memory pools)
    {
        return _REGISTRY_[baseToken][quoteToken];
    }

    function getDODOPoolBidirection(address token0, address token1)
        external
        view
        returns (address[] memory baseToken0Pool, address[] memory baseToken1Pool)
    {
        return (_REGISTRY_[token0][token1], _REGISTRY_[token1][token0]);
    }
}