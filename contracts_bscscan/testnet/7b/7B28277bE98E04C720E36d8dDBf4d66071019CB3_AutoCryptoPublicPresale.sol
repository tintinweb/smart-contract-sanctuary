/**
 * Website: autocrypto.ai
 * International Telegram: t.me/AutoCryptoInternational
 * Spanish Telegram: t.me/AutoCryptoSpain
 * Starred Calls Telegram: t.me/AutoCryptoStarredCalls
 * Discord: discord.gg/autocrypto
 */

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/**
 * @notice Interface for AutoCrypto presales contracts. {releaseToken} will gather the contributed BNB.
*/
interface Presale {
    function getContributors() external returns (address[] memory, uint[] memory);
}

/** 
 * @notice Interface for an ERC20 standar Token that will be used to
 * transfer AU tokens to the contributors of the private presale.
 */
interface IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
    
    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint amount) external returns (bool);
}

/**
 * @notice Interface for the AutoCrypto Antibot created exclusively for this presale
 */
interface AntiBot {
    function checkBot(bytes32 m, bytes calldata s) external;
}

/**
 * @title AutoCrypto Public Presale
 * @author AutoCrypto
 * @notice This contracts allows whitelisted users to buy AutoCrypto token
 * from October 4th 16:00 UTC until the token is released or hardcap is reached.
 * Contributors to the previous presale can buy during the first hour through
 * a whitelist, allowing them to buy the same amount as they did before.
 * Tokens will be claimable at the same time of the release.
 *
 * The admin account is the one that deploys the contract. This cannot be changed.
 *
 * This presale has a hardcap of 1000 BNB, with a minimum contribution of 0.1 BNB and
 * a maximum of 2 BNB.
 * 
 * With the release of the token, a 80% of the total contribution will be instantly added
 * to the liquidity through the token contract. A 20% will be transferred to the project
 * wallet, which will be used to maintain the servers and services provided in the AutoCrypto
 * community (eg. website, telegram bots, discord bots, AI).
 */
contract AutoCryptoPublicPresale is Initializable, UUPSUpgradeable {
    using AddressUpgradeable for address;
    using AddressUpgradeable for address payable;

    event TokenSet(address tokenAddress);
    event Claim(address contributor, uint amount);
    event Refund(address contributor, uint amount);
    event Contribute(address contributor, uint amount);

    /**
     * @notice This struc will store the contribution of each user who participates.
     * The index is used to keep track of the user in the arrays `contributors`
     * and `contributions`.
     */
    struct Contributor {
        uint index;
        uint contribution;
        bool claimed;
    }

    address private _admin;
    AntiBot private antiBot;

    mapping(address => uint) private prevContributor;
    mapping(address => Contributor) private contributor;

    address[] private contributors;
    uint[] private contributions;
    uint public totalContribution;
    uint public presaleRate;

    IERC20 public token;
    uint public minContribution;
    uint public maxContribution;
    uint public hardCap;
    uint public startTime;
    uint public whitelistEndTime;

    uint public liquidityDistribution;
    uint public projectDistribution;
    address public projectWallet;

    bool public released;
    bool public presaleCancelled;

    /**
     * @dev Throws if called by any account other than the admin.
     */
    modifier onlyAdmin() {
        require(msg.sender == _admin, "AutoCrypto: Access denied");
        _;
    }

    function initialize(address _antiBot) public initializer {
        _admin = msg.sender;
        antiBot = AntiBot(_antiBot);

        minContribution = 1 ether / 10;
        maxContribution = 2 ether;
        hardCap = 1000 ether;
        presaleRate = 44_000;
        // startTime = 1_634_475_600; // October 17th, 13:00 UTC
        // whitelistEndTime = 1_634_479_200; // October 17th, 14:00 UTC
        startTime = 1634410800; // October 16th, 21:00 UTC+2
        whitelistEndTime = 1634410800; // October 16th, 21:00 UTC+2

        liquidityDistribution = 85;
        projectDistribution = 15;

        projectWallet = 0x41B297Af3e52F12C25442d8B542463bEb80B22BF;
    }

    /**
     * @dev Function to authorize an upgrade to the proxy.
     */
    function _authorizeUpgrade(address) internal override onlyAdmin {}

    /**
     * @return The contribution of a given address.
     */
    function getContribution(address _contributor) public view returns (uint) {
        return contributor[_contributor].contribution;
    }

    /**
     * @return The maximum contribution available for a given address.
     */
    function getMaxContribution(address _contributor) public view returns (uint) {
        if (block.timestamp <= whitelistEndTime){
            return prevContributor[_contributor] - getContribution(msg.sender);
        }
        return maxContribution - getContribution(msg.sender);
    }

    /**
     * @return Two arrays with the wallets of the contributors and their contribution in wei.
     */
    function getContributors() public view returns (address[] memory, uint[] memory) {
        return (contributors, contributions);
    }

    /**
     * @dev Add all investor who participated in the previous presale to whitelist.
     */
    function setContributorsPrevPresale() public  {
        (address[] memory user, uint[] memory contribution) = Presale(0xB402213B49E9D0cEC839e325525e9569460Cfe17).getContributors();
        for (uint i = 0; i < user.length; i++) {
            prevContributor[user[i]] = contribution[i];
        }
    }

    /**
     * @dev Check all the requirements (eg. the presale has started, the contribution is
     * between the limits) and then stores the user's contribution.
     *
     * The only interaction with an external contract is here. `antibot` is a contract
     * deployed by AutoCrypto which serves the only purpose of stopping bots from buying
     * in this presale.
     *
     * Emits a {Contribute} event.
     */
    function contribute(bytes32 m, bytes calldata s) public payable {
        require(block.timestamp >= startTime, "AutoCrypto: Presale has not started");
        require(totalContribution + msg.value <= hardCap, "AutoCrypto: Hardcap reached");
        require(contributor[msg.sender].contribution + msg.value >= minContribution, "AutoCrypto: Contribution is below minimum");
        require(contributor[msg.sender].contribution + msg.value <= maxContribution, "AutoCrypto: Contribution is above maximum");

        if(block.timestamp <= whitelistEndTime) {
            require(prevContributor[msg.sender] > 0, "AutoCrypto: You didn't contribute in our previous presale");
            require(contributor[msg.sender].contribution + msg.value <= prevContributor[msg.sender], "AutoCrypto: Contribution is above your previous contribution");
        }

        antiBot.checkBot(m, s);

        if (contributor[msg.sender].contribution == 0) {
            contributor[msg.sender].contribution = msg.value;
            contributor[msg.sender].index = contributors.length;
            contributors.push(msg.sender);
            contributions.push(msg.value);
        } else {
            contributor[msg.sender].contribution += msg.value;
            contributions[contributor[msg.sender].index] = contributor[msg.sender].contribution;
        }
        totalContribution += msg.value;
        emit Contribute(msg.sender, msg.value);
    }

    /**
     * @dev Sets the AU token address.
     * For safety reasons, the token can only be set once and this must be done before
     * the release of the token on October 15th at 15:00 UTC.
     *
     * This is done in order to require the token balance to equal to the hardcap
     * multiplied by the rate (44,000) and thus guaranteeing that any contributor can
     * claim their tokens after the release.
     *
     * Emits a {RemoveWhitelisted} event
     */
    function setTokenAddress(address tokenAddress) public onlyAdmin {
        require(tokenAddress != address(0), "AutoCrypto: Zero address");
        token = IERC20(tokenAddress);
        require(token.balanceOf(address(this)) >= hardCap * presaleRate, "AutoCrypto: Insuficient tokens");
        require(bytes(token.name()).length == bytes("AutoCrypto").length && bytes(token.symbol()).length == bytes("AU").length, "AutoCrypto: This is not AutoCrypto");
        emit TokenSet(tokenAddress);
    }

    /**
     * @dev Refunds 100% of the contributed amount in case the function {setTokenAddress}
     * has not been called, meaning that the token has not been released or if the presale
     * has not been cancelled manually.
     *
     * This is a safety measure that guarantees all of the invested amount to the contributor.
     * This function can also be called if presale is cancelled manually through the function {cancelPresale}.
     *
     * Emits a {Refund} event.
     */
    function refund() public {
        uint contribution = contributor[msg.sender].contribution;
        require(presaleCancelled, "AutoCrypto: Presale is not cancelled");
        require(contribution > 0, "AutoCrypto: You haven't contributed");
        contributor[msg.sender].contribution = 0;
        payable(msg.sender).sendValue(contribution);

        emit Refund(msg.sender, contribution);
    }

    /**
     * @dev Any contributor can claim their AU tokens once the token is released on October 15th at 15:00 UTC.
     * Each claim will receive an amount of tokens following the rate of 1 BNB = 44,000 AU.
     * This requires the presale to be successful (reaching the softcap).
     *
     * Emits a {Claim} event.
     */
    function claim() public {
        require(!contributor[msg.sender].claimed, "AutoCrypto: Already claimed");
        require(released, "AutoCrypto: Token has not been released");
        uint contribution = contributor[msg.sender].contribution;
        require(contribution > 0, "AutoCrypto: You haven't contributed");
        contributor[msg.sender].claimed = true;
        uint amount = contribution * presaleRate * 10 ** token.decimals() / 1 ether;
        token.transfer(msg.sender, amount);

        emit Claim(msg.sender, amount);
    }

    /**
     * @dev Transfer 80% of the total contribution to the token contract, which will be added 
     * to the liquidity instantly, and the remaining 20% will be sent to the project wallet.
     *
     * This function can only be called by the token contract.
     */
    function releaseToken() public {
        require(msg.sender == address(token), "AutoCrypto: Access denied");
        require(!released, "AutoCrypto: Already released");
        released = true;
        
        payable(projectWallet).sendValue(totalContribution * projectDistribution / 100);
        payable(msg.sender).sendValue(address(this).balance);
    }

    /**
     * @dev Cancel the current presale created by this contract. This function allows any
     * contributor to ask for a refund through the function {refund}.
     */
    function cancelPresale() public onlyAdmin() {
        presaleCancelled = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal initializer {
        __ERC1967Upgrade_init_unchained();
        __UUPSUpgradeable_init_unchained();
    }

    function __UUPSUpgradeable_init_unchained() internal initializer {
    }
    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, bytes(""), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal initializer {
        __ERC1967Upgrade_init_unchained();
    }

    function __ERC1967Upgrade_init_unchained() internal initializer {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlotUpgradeable.BooleanSlot storage rollbackTesting = StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            _functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature("upgradeTo(address)", oldImplementation)
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _upgradeTo(newImplementation);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}