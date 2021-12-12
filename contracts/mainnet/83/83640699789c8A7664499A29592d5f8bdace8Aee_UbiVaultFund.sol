//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

// https://etherscan.io/address/0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2
interface IWETH {
  function deposit() payable external;
  function balanceOf(address guy) external returns (uint256);
  function approve(address guy, uint256 wad) external returns (bool);
}

// https://etherscan.io/address/0x2147935d9739da4e691b8ae2e1437492a394ebf5
interface IUbiVault {
  function deposit(uint256 wethAmount) external returns (uint256);
  function withdraw() external returns (uint256);
}

/**
  To deposit, simply send ETH to the contract address. The ETH will collect
  in the contract until anyone calls the deposit() function to put the ETH
  into the vault. Only the admin can call withdraw(), this is needed for
  rare vault maintenance.
 */
contract UbiVaultFund is Initializable {
  IWETH public weth;
  IUbiVault public ubiVault;
  address public admin;

  modifier onlyByAdmin() {
    require(admin == msg.sender, "The caller is not the admin.");
    _;
  }

  // This contract is upgradeable but should be managed by the same entity that governs the UBI
  // contract and only should be modified by UIP.
  function initialize(address _admin, IWETH _weth, IUbiVault _ubiVault) public initializer {
    weth = _weth;
    ubiVault = _ubiVault;
    admin = _admin;
    weth.approve(address(ubiVault), type(uint256).max);
  }

  // Allows ETH to be sent to the contract.
  receive() external payable {}

  // Anyone can call this to gas a deposit when enough ETH has collected in the contract.
  function deposit() public {
    uint256 ethBalance = address(this).balance;
    if (ethBalance > 0) {
      (bool success, ) = address(weth).call{value: ethBalance}(abi.encodeWithSignature("deposit()"));
      require(success, "Failed to convert to WETH");
    }
    uint256 wethBalance = weth.balanceOf(address(this));
    require(wethBalance > 0, "No WETH to deposit.");
    ubiVault.deposit(wethBalance);
  }

  // The admin can use this method as part of rare vault maintenance.
  // Note: this withdraws from the vault to the contract, not to the caller.
  function withdraw() public onlyByAdmin {
    ubiVault.withdraw();
  }

  function setAdmin(address _admin) public onlyByAdmin {
    admin = _admin;
  }

  function setUbiVault(IUbiVault _ubiVault) public onlyByAdmin {
    ubiVault = _ubiVault;
  }
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