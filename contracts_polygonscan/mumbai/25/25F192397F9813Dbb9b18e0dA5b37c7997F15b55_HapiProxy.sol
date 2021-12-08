// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract HapiProxy is Ownable {
  mapping(address => uint8) private _reporters;

  enum Category {
    None,
    // Wallet service - custodial or mixed wallets
    WalletService,
    // Merchant service
    MerchantService,
    // Mining pool
    MiningPool,
    // Low risk exchange - Exchange with high KYC standards
    LowRiskExchange,
    // Medium eisk exchange
    MediumRiskExchange,
    // DeFi application
    DeFi,
    // OTC Broker
    OTCBroker,
    // Cryptocurrency ATM
    ATM,
    // Gambling
    Gambling,
    // Illicit organization
    IllicitOrganization,
    // Mixer
    Mixer,
    // Darknet market or service
    DarknetService,
    // Scam
    Scam,
    // Ransomware
    Ransomware,
    // Theft - stolen funds
    Theft,
    // Counterfeit - fake assets
    Counterfeit,
    // Terrorist financing
    TerroristFinancing,
    // Sanctions
    Sanctions,
    // Child abuse and porn materials
    ChildAbuse
  }

  struct AddressInfo {
    Category category;
    uint8 risk;
  }

  mapping(address => AddressInfo) private _addresses;
  uint8 private constant _MAX_RISK = 10;

  event CreateReporter(address reporterAddress_, uint8 permissionLevel_);
  event UpdateReporter(address reporterAddress_, uint8 permissionLevel_);
  event CreateAddress(address address_, Category category_, uint8 risk_);
  event UpdateAddress(address address_, Category category_, uint8 risk_);

  constructor() {}

  modifier minReporterLevel1 {
    require(_reporters[msg.sender] >= 1, "HapiProxy: Reporter permission level is less than 1");
    _;
  }

  modifier minReporterLevel2 {
    require(_reporters[msg.sender] >= 2, "HapiProxy: Reporter permission level is less than 2");
    _;
  }

  function createReporter(address reporterAddress_, uint8 permissionLevel_) external onlyOwner returns (bool success) {
    require(reporterAddress_ != address(0), "HapiProxy: Invalid address");
    require(_reporters[reporterAddress_] == 0, "HapiProxy: Reporter already exists");
    require(permissionLevel_ > 0 && permissionLevel_ <= 2, "HapiProxy: Invalid permission level");
    
    _reporters[reporterAddress_] = permissionLevel_;

    emit CreateReporter(reporterAddress_, permissionLevel_);
    return true;
  }

  function updateReporter(address reporterAddress_, uint8 permissionLevel_) external onlyOwner returns (bool success) {
    require(reporterAddress_ != address(0), "HapiProxy: Invalid address");
    require(_reporters[reporterAddress_] != 0, "HapiProxy: Reporter does not exist");
    require(permissionLevel_ > 0 && permissionLevel_ <= 2, "HapiProxy: Invalid permission level");
    require(_reporters[reporterAddress_] != permissionLevel_, "HapiProxy: Invalid params");

    _reporters[reporterAddress_] = permissionLevel_;

    emit UpdateReporter(reporterAddress_, permissionLevel_);
    return true;
  }

  function createAddress(address address_, Category category_, uint8 risk_) external minReporterLevel1 returns (bool success) {
    require(address_ != address(0), "HapiProxy: Invalid address");
    require(risk_ <= _MAX_RISK, "HapiProxy: Invalid risk");

    AddressInfo storage _address = _addresses[address_];
    require(_address.category == Category.None, "HapiProxy: Address already exists");
    
    _address.category = category_;
    _address.risk = risk_;

    emit CreateAddress(address_, category_, risk_);
    return true;
  }

  function updateAddress(address address_, Category category_, uint8 risk_) external minReporterLevel2 returns (bool success) {
    require(address_ != address(0), "HapiProxy: Invalid address");
    require(risk_ <= _MAX_RISK, "HapiProxy: Invalid risk");

    AddressInfo storage _address = _addresses[address_];
    require(_address.category != Category.None, "HapiProxy: Address does not exist");
    require(_address.category != category_ || _address.risk != risk_, "HapiProxy: Invalid params");

    _address.category = category_;
    _address.risk = risk_;

    emit UpdateAddress(address_, category_, risk_);
    return true;
  }

  function getAddress(address address_) external view returns (Category category, uint8 risk) {
    AddressInfo storage _addressInfo = _addresses[address_];
    return (_addressInfo.category, _addressInfo.risk);
  }

  function getReporter(address reporterAddress_) external view returns (uint8 permissionLevel) {
    return _reporters[reporterAddress_];
  }
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
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
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
        return msg.data;
    }
}