// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./util/OwnableUpgradeable.sol";
import "./interfaces/ITokenBaseDeployer.sol";
import "./interfaces/INFTBaseDeployer.sol";
import "./interfaces/IFixedPeriodDeployer.sol";
import "./interfaces/IFixedPriceDeployer.sol";

contract Factory is OwnableUpgradeable {
  uint256 public immutable COOLDOWN_SECONDS = 2 days;

  /// @notice Seconds available to operate once the cooldown period is fullfilled
  uint256 public immutable OPERATE_WINDOW = 1 days;

  address private tokenBaseDeployer; // staking erc20 tokens to mint PASS
  address private nftBaseDeployer; // staking erc721 tokens to mint PASS
  address private fixedPeriodDeployer; // pay erc20 tokens to mint PASS in a fixed period with linearly decreasing price
  address private fixedPriceDeployer; // pay erc20 tokens to mint PASS with fixed price

  uint256 public cooldownStartTimestamp;
  address payable public platform; // The PASS platform commission account
  uint256 public platformRate; // The PASS platform commission rate in pph

  constructor(
    address _tokenBaseDeployer,
    address _nftBaseDeployer,
    address _fixedPeriodDeployer,
    address _fixedPriceDeployer,
    address payable _platform,
    uint256 _platformRate
  ) {
    __Ownable_init(msg.sender);
    tokenBaseDeployer = _tokenBaseDeployer;
    nftBaseDeployer = _nftBaseDeployer;
    fixedPeriodDeployer = _fixedPeriodDeployer;
    fixedPriceDeployer = _fixedPriceDeployer;
    _setPlatformParms(_platform, _platformRate);
  }

  event TokenBaseDeploy(
    address indexed _addr, // address of deployed NFT PASS contract
    string _name, // name of PASS
    string _symbol, // symbol of PASS
    string _bURI, // baseuri of NFT PASS
    address _erc20, // address of staked erc20 tokens
    uint256 _rate // staking rate of erc20 tokens/PASS
  );
  event NFTBaseDeploy(
    address indexed _addr,
    string _name,
    string _symbol,
    string _bURI,
    address _erc721 // address of staked erc721 tokens
  );
  event FixedPeriodDeploy(
    address indexed _addr,
    string _name,
    string _symbol,
    string _bURI,
    address _erc20, // payment erc20 tokens
    address _platform,
    address _receivingAddress, // creator's receivingAddress account to receive erc20 tokens
    uint256 _initialRate, // initial exchange rate of erc20 tokens/PASS
    uint256 _startTime, // start time of sales period
    uint256 _endTime, // start time of sales
    uint256 _maxSupply, // maximum supply of PASS
    uint256 _platformRate
  );

  event FixedPriceDeploy(
    address indexed _addr,
    string _name,
    string _symbol,
    string _bURI,
    address _erc20, // payment erc20 tokens
    address _platform,
    address _receivingAddress,
    uint256 _rate,
    uint256 _maxSupply,
    uint256 _platformRate
  );

  event SetPlatformParms(address _platform, uint256 _platformRate);
  event SetPlatformParmsUnlock(uint256 cooldownStartTimestamp);

  // unlock setPlatformParms function
  function setPlatformParmsUnlock() public onlyOwner {
    cooldownStartTimestamp = block.timestamp;
    emit SetPlatformParmsUnlock(block.timestamp);
  }

  // set the platform account and commission rate, only operable by contract owner, _platformRate is in pph
  function setPlatformParms(address payable _platform, uint256 _platformRate)
    public
    onlyOwner
  {
    require(
      block.timestamp > cooldownStartTimestamp + COOLDOWN_SECONDS,
      "INSUFFICIENT_COOLDOWN"
    );
    require(
      block.timestamp - (cooldownStartTimestamp + COOLDOWN_SECONDS) <=
        OPERATE_WINDOW,
      "OPERATE_WINDOW_FINISHED"
    );

    _setPlatformParms(_platform, _platformRate);

    // clear cooldown after changeBeneficiary
    if (cooldownStartTimestamp != 0) {
      cooldownStartTimestamp = 0;
    }
  }

  // set up the platform parameters internal
  function _setPlatformParms(address payable _platform, uint256 _platformRate)
    internal
  {
    require(_platform != address(0), "Curve: platform address is zero");
    require(_platformRate <= 100, "Curve: wrong rate");

    platform = _platform;
    platformRate = _platformRate;

    emit SetPlatformParms(_platform, _platformRate);
  }

  function tokenBaseDeploy(
    string memory _name,
    string memory _symbol,
    string memory _bURI,
    address _erc20,
    uint256 _rate
  ) public {
    ITokenBaseDeployer factory = ITokenBaseDeployer(tokenBaseDeployer);
    //return the address of deployed NFT PASS contract
    address addr = factory.deployTokenBase(
      _name,
      _symbol,
      _bURI,
      _erc20,
      _rate
    );
    emit TokenBaseDeploy(addr, _name, _symbol, _bURI, _erc20, _rate);
  }

  function nftBaseDeploy(
    string memory _name,
    string memory _symbol,
    string memory _bURI,
    address _erc721
  ) public {
    INFTBaseDeployer factory = INFTBaseDeployer(nftBaseDeployer);
    address addr = factory.deployNFTBase(_name, _symbol, _bURI, _erc721);
    emit NFTBaseDeploy(addr, _name, _symbol, _bURI, _erc721);
  }

  function fixedPeriodDeploy(
    string memory _name,
    string memory _symbol,
    string memory _bURI,
    address _erc20,
    address payable _receivingAddress,
    uint256 _initialRate,
    uint256 _startTime,
    uint256 _endTime,
    uint256 _maxSupply
  ) public {
    address addr = IFixedPeriodDeployer(fixedPeriodDeployer).deployFixedPeriod(
      _name,
      _symbol,
      _bURI,
      _erc20,
      platform,
      _receivingAddress,
      _initialRate,
      _startTime,
      _endTime,
      _maxSupply,
      platformRate
    );
    emit FixedPeriodDeploy(
      addr,
      _name,
      _symbol,
      _bURI,
      _erc20,
      platform,
      _receivingAddress,
      _initialRate,
      _startTime,
      _endTime,
      _maxSupply,
      platformRate
    );
  }

  function fixedPriceDeploy(
    string memory _name,
    string memory _symbol,
    string memory _bURI,
    address _erc20,
    address payable _receivingAddress,
    uint256 _rate,
    uint256 _maxSupply
  ) public {
    IFixedPriceDeployer factory = IFixedPriceDeployer(fixedPriceDeployer);
    address addr = factory.deployFixedPrice(
      _name,
      _symbol,
      _bURI,
      _erc20,
      platform,
      _receivingAddress,
      _rate,
      _maxSupply,
      platformRate
    );
    emit FixedPriceDeploy(
      addr,
      _name,
      _symbol,
      _bURI,
      _erc20,
      platform,
      _receivingAddress,
      _rate,
      _maxSupply,
      platformRate
    );
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  function __Ownable_init(address newOwner) internal initializer {
    _setOwner(newOwner);
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
    require(owner() == msg.sender, "Ownable: caller is not the owner");
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
pragma solidity ^0.8.4;

interface ITokenBaseDeployer {
    function deployTokenBase(
        string memory _name,
        string memory _symbol,
        string memory _bURI,
        address _erc20,
        uint256 _rate
    ) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface INFTBaseDeployer {
    function deployNFTBase(
        string memory _name,
        string memory _symbol,
        string memory _bURI,
        address _erc721
    ) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IFixedPeriodDeployer {
  function deployFixedPeriod(
    string memory _name,
    string memory _symbol,
    string memory _bURI,
    address _erc20,
    address payable _platform,
    address payable _receivingAddress,
    uint256 _initialRate,
    uint256 _startTime,
    uint256 _termOfValidity,
    uint256 _maxSupply,
    uint256 _platformRate
  ) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IFixedPriceDeployer {
  function deployFixedPrice(
    string memory _name,
    string memory _symbol,
    string memory _bURI,
    address _erc20,
    address payable _platform,
    address payable _receivingAddress,
    uint256 _rate,
    uint256 _maxSupply,
    uint256 _platformRate
  ) external returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}