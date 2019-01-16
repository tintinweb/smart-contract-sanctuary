pragma solidity 0.4.24;

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

// File: openzeppelin-solidity/contracts/ownership/Claimable.sol

/**
 * @title Claimable
 * @dev Extension for the Ownable contract, where the ownership needs to be claimed.
 * This allows the new owner to accept the transfer.
 */
contract Claimable is Ownable {
  address public pendingOwner;

  /**
   * @dev Modifier throws if called by any account other than the pendingOwner.
   */
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

  /**
   * @dev Allows the current owner to set the pendingOwner address.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    pendingOwner = newOwner;
  }

  /**
   * @dev Allows the pendingOwner address to finalize the transfer.
   */
  function claimOwnership() public onlyPendingOwner {
    emit OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}

// File: contracts/utils/Adminable.sol

contract Adminable is Claimable {
    address[] public adminArray;

    struct AdminInfo {
        bool valid;
        uint index;
    }

    mapping(address => AdminInfo) public adminTable;

    event AdminAccepted(address indexed admin);
    event AdminRejected(address indexed admin);

    /**
     * @dev Throws if called by any account other than one of the administrators.
     */
    modifier onlyAdmin() {
        require(adminTable[msg.sender].valid);
        _;
    }

    /**
     * @dev Accept a new administrator.
     * @param admin The administrator&#39;s address.
     */
    function accept(address admin) external onlyOwner {
        require(admin != address(0));
        AdminInfo storage adminInfo = adminTable[admin];
        require(!adminInfo.valid);
        adminInfo.valid = true;
        adminInfo.index = adminArray.length;
        adminArray.push(admin);
        emit AdminAccepted(admin);
    }

    /**
     * @dev Reject an existing administrator.
     * @param admin The administrator&#39;s address.
     */
    function reject(address admin) external onlyOwner {
        AdminInfo storage adminInfo = adminTable[admin];
        require(adminInfo.index < adminArray.length);
        require(admin == adminArray[adminInfo.index]);
        address lastAdmin = adminArray[adminArray.length - 1];
        adminTable[lastAdmin].index = adminInfo.index;
        adminArray[adminInfo.index] = lastAdmin;
        adminArray.length -= 1;
        delete adminTable[admin];
        emit AdminRejected(admin);
    }

    /**
     * @dev Get an array of all the administrators.
     * @return An array of all the administrators.
     */
    function getAdminArray() external view returns (address[]) {
        return adminArray;
    }

    /**
     * @dev Get the total number of administrators.
     * @return The total number of administrators.
     */
    function getAdminCount() external view returns (uint) {
        return adminArray.length;
    }
}

// File: contracts/authorization/interfaces/IAuthorizationDataSource.sol

interface IAuthorizationDataSource {
    function isAuthorized(address wallet) external view returns (bool);
    function isRestricted(address wallet) external view returns (bool);
    function tradingClass(address wallet) external view returns (uint);
}

// File: contracts\authorization\AuthorizationDataSource.sol

contract AuthorizationDataSource is IAuthorizationDataSource, Adminable {
    uint public walletCount;

    struct WalletInfo {
        uint sequenceNum;
        bool isAuthorized;
        bool isRestricted;
        uint tradingClass;
    }

    mapping(address => WalletInfo) public walletTable;

    event WalletSaved(address indexed wallet);
    event WalletDeleted(address indexed wallet);
    event WalletNotSaved(address indexed wallet);
    event WalletNotDeleted(address indexed wallet);

    function isAuthorized(address wallet) external view returns (bool) {
        return walletTable[wallet].isAuthorized;
    }

    function isRestricted(address wallet) external view returns (bool) {
        return walletTable[wallet].isRestricted;
    }

    function tradingClass(address wallet) external view returns (uint) {
        return walletTable[wallet].tradingClass;
    }

    function upsertOne(address wallet, uint sequenceNum, bool isAuthorizedVal, bool isRestrictedVal, uint tradingClassVal) external onlyAdmin {
        _upsert(wallet, sequenceNum, isAuthorizedVal, isRestrictedVal, tradingClassVal);
    }

    function removeOne(address wallet) external onlyAdmin {
        _remove(wallet);
    }

    function upsertAll(address[] wallets, uint sequenceNum, bool isAuthorizedVal, bool isRestrictedVal, uint tradingClassVal) external onlyAdmin {
        for (uint i = 0; i < wallets.length; i++)
            _upsert(wallets[i], sequenceNum, isAuthorizedVal, isRestrictedVal, tradingClassVal);
    }

    function removeAll(address[] wallets) external onlyAdmin {
        for (uint i = 0; i < wallets.length; i++)
            _remove(wallets[i]);
    }

    /**
     * @dev Insert or update a wallet.
     * @param wallet The wallet&#39;s address.
     * @param sequenceNum The operation&#39;s sequence-number.
     * @param isAuthorizedVal An indication of whether or not the wallet is authorized.
     * @param isRestrictedVal An indication of whether or not the wallet is restricted.
     * @param tradingClassVal The wallet&#39;s trading-class ID.
     */
    function _upsert(address wallet, uint sequenceNum, bool isAuthorizedVal, bool isRestrictedVal, uint tradingClassVal) private {
        require(wallet != address(0));
        WalletInfo storage walletInfo = walletTable[wallet];
        if (walletInfo.sequenceNum < sequenceNum) {
            if (walletInfo.sequenceNum == 0)
                walletCount += 1;
            walletInfo.sequenceNum = sequenceNum;
            walletInfo.isAuthorized = isAuthorizedVal;
            walletInfo.isRestricted = isRestrictedVal;
            walletInfo.tradingClass = tradingClassVal;
            emit WalletSaved(wallet);
        }
        else {
            emit WalletNotSaved(wallet);
        }
    }

    /**
     * @dev Remove a wallet.
     * @param wallet The wallet&#39;s address.
     */
    function _remove(address wallet) private {
        require(wallet != address(0));
        WalletInfo storage walletInfo = walletTable[wallet];
        if (walletInfo.sequenceNum > 0) {
            walletCount -= 1;
            delete walletTable[wallet];
            emit WalletDeleted(wallet);
        }
        else {
            emit WalletNotDeleted(wallet);
        }
    }
}