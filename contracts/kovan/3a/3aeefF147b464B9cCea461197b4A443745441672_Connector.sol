// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import './libraries/Role.sol';
import './ConnectorStorage.sol';
import './interfaces/IConnector.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

/**
 * @title ELYFI Connector
 * @author ELYSIA
 * @notice ELYFI functions through continual interaction among the various participants.
 * In order to link the real assets and the blockchain, unlike the existing DeFi platform,
 * ELYFI has a group of participants in charge of actual legal contracts and maintenance.
 * 1. Collateral service providers are a group of users who sign a collateral contract with
 * a borrower who takes out a real asset-backed loan and borrows cryptocurrencies from the
 * Money Pool based on this contract.
 * 2. The council, such as legal service provider is a corporation that provides
 * legal services such as document review in the context of legal proceedings, consulting,
 * and the provision of documents necessary in the process of taking out loans secured by real assets,
 * In the future, the types of participant groups will be diversified and subdivided.
 * @dev Only admin can add or revoke roles of the ELYFI. The admin account of the connector is strictly
 * managed, and it is to be managed by governance of ELYFI.
 */
contract Connector is IConnector, ConnectorStorage, Ownable {
  constructor() {}

  function addCouncil(address account) external onlyOwner {
    _grantRole(Role.COUNCIL, account);
    emit NewCouncilAdded(account);
  }

  function addCollateralServiceProvider(address account) external onlyOwner {
    _grantRole(Role.CollateralServiceProvider, account);
    emit NewCollateralServiceProviderAdded(account);
  }

  function revokeCouncil(address account) external onlyOwner {
    _revokeRole(Role.COUNCIL, account);
    emit CouncilRevoked(account);
  }

  function revokeCollateralServiceProvider(address account) external onlyOwner {
    _revokeRole(Role.CollateralServiceProvider, account);
    emit CollateralServiceProviderRevoked(account);
  }

  function _grantRole(bytes32 role, address account) internal {
    _roles[role].participants[account] = true;
  }

  function _revokeRole(bytes32 role, address account) internal {
    _roles[role].participants[account] = false;
  }

  function _hasRole(bytes32 role, address account) internal view returns (bool) {
    return _roles[role].participants[account];
  }

  function isCollateralServiceProvider(address account) external view override returns (bool) {
    return _hasRole(Role.CollateralServiceProvider, account);
  }

  function isCouncil(address account) external view override returns (bool) {
    return _hasRole(Role.COUNCIL, account);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/**
 * @title ELYFI Role
 * @author ELYSIA
 */
library Role {
  bytes32 internal constant CollateralServiceProvider = 'CollateralServiceProvider';
  bytes32 internal constant COUNCIL = 'COUNCIL';
  bytes32 internal constant MONEYPOOL_ADMIN = 'MONEYPOOL_ADMIN';
}

import './interfaces/IMoneyPool.sol';

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/**
 * @title ELYFI Connector storage
 * @author ELYSIA
 */
contract ConnectorStorage {
  struct RoleData {
    mapping(address => bool) participants;
    bytes32 admin;
  }

  mapping(bytes32 => RoleData) internal _roles;

  IMoneyPool internal _moneyPool;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import '../libraries/DataStruct.sol';

interface IConnector {
  event NewCouncilAdded(address indexed account);
  event NewCollateralServiceProviderAdded(address indexed account);
  event CouncilRevoked(address indexed account);
  event CollateralServiceProviderRevoked(address indexed account);

  function isCollateralServiceProvider(address account) external view returns (bool);

  function isCouncil(address account) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import '../libraries/DataStruct.sol';

interface IMoneyPool {
  event NewReserve(
    address indexed asset,
    address lToken,
    address dToken,
    address interestModel,
    address tokenizer,
    uint256 moneyPoolFactor
  );

  event Deposit(address indexed asset, address indexed account, uint256 amount);

  event Withdraw(
    address indexed asset,
    address indexed account,
    address indexed to,
    uint256 amount
  );

  event Borrow(
    address indexed asset,
    address indexed collateralServiceProvider,
    address indexed borrower,
    uint256 tokenId,
    uint256 borrowAPY,
    uint256 borrowAmount
  );

  event Repay(
    address indexed asset,
    address indexed borrower,
    uint256 tokenId,
    uint256 userDTokenBalance,
    uint256 feeOnCollateralServiceProvider
  );

  event Liquidation(
    address indexed asset,
    address indexed borrower,
    uint256 tokenId,
    uint256 userDTokenBalance,
    uint256 feeOnCollateralServiceProvider
  );

  function deposit(
    address asset,
    address account,
    uint256 amount
  ) external;

  function withdraw(
    address asset,
    address account,
    uint256 amount
  ) external;

  function borrow(address asset, uint256 tokenID) external;

  function repay(address asset, uint256 tokenId) external;

  function liquidate(address asset, uint256 tokenId) external;

  function getLTokenInterestIndex(address asset) external view returns (uint256);

  function getReserveData(address asset) external view returns (DataStruct.ReserveData memory);

  function addNewReserve(
    address asset,
    address lToken,
    address dToken,
    address interestModel,
    address tokenizer,
    uint256 moneyPoolFactor_
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

library DataStruct {
  /**
    @notice The main reserve data struct.
   */
  struct ReserveData {
    uint256 moneyPoolFactor;
    uint256 lTokenInterestIndex;
    uint256 borrowAPY;
    uint256 depositAPY;
    uint256 totalDepositedAssetBondCount;
    uint256 lastUpdateTimestamp;
    address lTokenAddress;
    address dTokenAddress;
    address interestModelAddress;
    address tokenizerAddress;
    uint8 id;
    bool isPaused;
    bool isActivated;
  }

  /**
   * @notice The asset bond data struct.
   * @param ipfsHash The IPFS hash that contains the informations and contracts
   * between Collateral Service Provider and lender.
   * @param maturityTimestamp The amount of time measured in seconds that can elapse
   * before the NPL company liquidate the loan and seize the asset bond collateral.
   * @param borrower The address of the borrower.
   */
  struct AssetBondData {
    AssetBondState state;
    address borrower;
    address signer;
    address collateralServiceProvider;
    uint256 principal;
    uint256 debtCeiling;
    uint256 couponRate;
    uint256 interestRate;
    uint256 overdueInterestRate;
    uint256 loanStartTimestamp;
    uint256 collateralizeTimestamp;
    uint256 maturityTimestamp;
    uint256 liquidationTimestamp;
    string ipfsHash; // refactor : gas
    string signerOpinionHash;
  }

  /**
    @notice The states of asset bond
    * EMPTY: After
    * SETTLED:
    * CONFIRMED:
    * COLLATERALIZED:
    * MATURED:
    * REDEEMED:
    * NOT_PERFORMED:
   */
  enum AssetBondState {EMPTY, SETTLED, CONFIRMED, COLLATERALIZED, MATURED, REDEEMED, NOT_PERFORMED}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

{
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}