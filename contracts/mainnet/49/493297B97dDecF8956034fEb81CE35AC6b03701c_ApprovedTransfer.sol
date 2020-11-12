/**
 *Submitted for verification at Etherscan.io on 2020-11-03
*/

pragma experimental ABIEncoderV2;
// File: contracts/modules/common/Utils.sol
// Copyright (C) 2020  Argent Labs Ltd. <https://argent.xyz>
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
// SPDX-License-Identifier: GPL-3.0-only
/**
 * @title Utils
 * @notice Common utility methods used by modules.
 */
library Utils {
    /**
    * @notice Helper method to recover the signer at a given position from a list of concatenated signatures.
    * @param _signedHash The signed hash
    * @param _signatures The concatenated signatures.
    * @param _index The index of the signature to recover.
    */
    function recoverSigner(bytes32 _signedHash, bytes memory _signatures, uint _index) internal pure returns (address) {
        uint8 v;
        bytes32 r;
        bytes32 s;
        // we jump 32 (0x20) as the first slot of bytes contains the length
        // we jump 65 (0x41) per signature
        // for v we load 32 bytes ending with v (the first 31 come from s) then apply a mask
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(_signatures, add(0x20,mul(0x41,_index))))
            s := mload(add(_signatures, add(0x40,mul(0x41,_index))))
            v := and(mload(add(_signatures, add(0x41,mul(0x41,_index)))), 0xff)
        }
        require(v == 27 || v == 28);
        address recoveredAddress = ecrecover(_signedHash, v, r, s);
        require(recoveredAddress != address(0), "Utils: ecrecover returned 0");
        return recoveredAddress;
    }
    /**
    * @notice Helper method to parse data and extract the method signature.
    */
    function functionPrefix(bytes memory _data) internal pure returns (bytes4 prefix) {
        require(_data.length >= 4, "RM: Invalid functionPrefix");
        // solhint-disable-next-line no-inline-assembly
        assembly {
            prefix := mload(add(_data, 0x20))
        }
    }
    /**
    * @notice Returns ceil(a / b).
    */
    function ceil(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        if (a % b == 0) {
            return c;
        } else {
            return c + 1;
        }
    }
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a < b) {
            return a;
        }
        return b;
    }
}
// File: @openzeppelin/contracts/math/SafeMath.sol
/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }
    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
/**
 * @title ILimitStorage
 * @notice LimitStorage interface
 */
interface ILimitStorage {
    struct Limit {
        // the current limit
        uint128 current;
        // the pending limit if any
        uint128 pending;
        // when the pending limit becomes the current limit
        uint64 changeAfter;
    }
    struct DailySpent {
        // The amount already spent during the current period
        uint128 alreadySpent;
        // The end of the current period
        uint64 periodEnd;
    }
    function setLimit(address _wallet, Limit memory _limit) external;
    function getLimit(address _wallet) external view returns (Limit memory _limit);
    function setDailySpent(address _wallet, DailySpent memory _dailySpent) external;
    function getDailySpent(address _wallet) external view returns (DailySpent memory _dailySpent);
    function setLimitAndDailySpent(address _wallet, Limit memory _limit, DailySpent memory _dailySpent) external;
    function getLimitAndDailySpent(address _wallet) external view returns (Limit memory _limit, DailySpent memory _dailySpent);
}
/**
 * @title ITokenPriceRegistry
 * @notice TokenPriceRegistry interface
 */
interface ITokenPriceRegistry {
    function getTokenPrice(address _token) external view returns (uint184 _price);
    function isTokenTradable(address _token) external view returns (bool _isTradable);
}

pragma solidity >=0.5.4 <0.7.0;
/**
 * @title IVersionManager
 * @notice Interface for the VersionManager module.
 * @author Olivier VDB - <olivier@argent.xyz>
 */
interface IVersionManager {
    /**
     * @notice Returns true if the feature is authorised for the wallet
     * @param _wallet The target wallet.
     * @param _feature The feature.
     */
    function isFeatureAuthorised(address _wallet, address _feature) external view returns (bool);
    /**
     * @notice Lets a feature (caller) invoke a wallet.
     * @param _wallet The target wallet.
     * @param _to The target address for the transaction.
     * @param _value The value of the transaction.
     * @param _data The data of the transaction.
     */
    function checkAuthorisedFeatureAndInvokeWallet(
        address _wallet,
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external returns (bytes memory _res);
    /* ******* Backward Compatibility with old Storages and BaseWallet *************** */
    /**
     * @notice Sets a new owner for the wallet.
     * @param _newOwner The new owner.
     */
    function setOwner(address _wallet, address _newOwner) external;
    /**
     * @notice Lets a feature write data to a storage contract.
     * @param _wallet The target wallet.
     * @param _storage The storage contract.
     * @param _data The data of the call
     */
    function invokeStorage(address _wallet, address _storage, bytes calldata _data) external;
    /**
     * @notice Upgrade a wallet to a new version.
     * @param _wallet the wallet to upgrade
     * @param _toVersion the new version
     */
    function upgradeWallet(address _wallet, uint256 _toVersion) external;
}

/**
 * @title LimitUtils
 * @notice Helper library to manage the daily limit and interact with a contract implementing the ILimitStorage interface.
 * @author Julien Niset - <julien@argent.xyz>
 */
library LimitUtils {
    // large limit when the limit can be considered disabled
    uint128 constant internal LIMIT_DISABLED = uint128(-1);
    using SafeMath for uint256;
    // *************** Internal Functions ********************* //
    /**
     * @notice Changes the daily limit (expressed in ETH).
     * Decreasing the limit is immediate while increasing the limit is pending for the security period.
     * @param _lStorage The storage contract.
     * @param _versionManager The version manager.
     * @param _wallet The target wallet.
     * @param _targetLimit The target limit.
     * @param _securityPeriod The security period.
     */
    function changeLimit(
        ILimitStorage _lStorage,
        IVersionManager _versionManager,
        address _wallet,
        uint256 _targetLimit,
        uint256 _securityPeriod
    )
        internal
        returns (ILimitStorage.Limit memory)
    {
        ILimitStorage.Limit memory limit = _lStorage.getLimit(_wallet);
        uint256 currentLimit = currentLimit(limit);
        ILimitStorage.Limit memory newLimit;
        if (_targetLimit <= currentLimit) {
            uint128 targetLimit = safe128(_targetLimit);
            newLimit = ILimitStorage.Limit(targetLimit, targetLimit, safe64(block.timestamp));
        } else {
            newLimit = ILimitStorage.Limit(safe128(currentLimit), safe128(_targetLimit), safe64(block.timestamp.add(_securityPeriod)));
        }
        setLimit(_versionManager, _lStorage, _wallet, newLimit);
        return newLimit;
    }
     /**
     * @notice Disable the daily limit.
     * The change is pending for the security period.
     * @param _lStorage The storage contract.
     * @param _versionManager The version manager.
     * @param _wallet The target wallet.
     * @param _securityPeriod The security period.
     */
    function disableLimit(
        ILimitStorage _lStorage,
        IVersionManager _versionManager,
        address _wallet,
        uint256 _securityPeriod
    )
        internal
    {
        changeLimit(_lStorage, _versionManager, _wallet, LIMIT_DISABLED, _securityPeriod);
    }
    /**
    * @notice Returns whether the daily limit is disabled for a wallet.
    * @param _wallet The target wallet.
    * @return _limitDisabled true if the daily limit is disabled, false otherwise.
    */
    function isLimitDisabled(ILimitStorage _lStorage, address _wallet) internal view returns (bool) {
        ILimitStorage.Limit memory limit = _lStorage.getLimit(_wallet);
        uint256 currentLimit = currentLimit(limit);
        return (currentLimit == LIMIT_DISABLED);
    }
    /**
    * @notice Checks if a transfer is within the limit. If yes the daily spent is updated.
    * @param _lStorage The storage contract.
    * @param _versionManager The Version Manager.
    * @param _wallet The target wallet.
    * @param _amount The amount for the transfer
    * @return true if the transfer is withing the daily limit.
    */
    function checkAndUpdateDailySpent(
        ILimitStorage _lStorage,
        IVersionManager _versionManager,
        address _wallet,
        uint256 _amount
    )
        internal
        returns (bool)
    {
        (ILimitStorage.Limit memory limit, ILimitStorage.DailySpent memory dailySpent) = _lStorage.getLimitAndDailySpent(_wallet);
        uint256 currentLimit = currentLimit(limit);
        if (_amount == 0 || currentLimit == LIMIT_DISABLED) {
            return true;
        }
        ILimitStorage.DailySpent memory newDailySpent;
        if (dailySpent.periodEnd <= block.timestamp && _amount <= currentLimit) {
            newDailySpent = ILimitStorage.DailySpent(safe128(_amount), safe64(block.timestamp + 24 hours));
            setDailySpent(_versionManager, _lStorage, _wallet, newDailySpent);
            return true;
        } else if (dailySpent.periodEnd > block.timestamp && _amount.add(dailySpent.alreadySpent) <= currentLimit) {
            newDailySpent = ILimitStorage.DailySpent(safe128(_amount.add(dailySpent.alreadySpent)), safe64(dailySpent.periodEnd));
            setDailySpent(_versionManager, _lStorage, _wallet, newDailySpent);
            return true;
        }
        return false;
    }
    /**
    * @notice Helper method to Reset the daily consumption.
    * @param _versionManager The Version Manager.
    * @param _wallet The target wallet.
    */
    function resetDailySpent(IVersionManager _versionManager, ILimitStorage limitStorage, address _wallet) internal {
        setDailySpent(_versionManager, limitStorage, _wallet, ILimitStorage.DailySpent(uint128(0), uint64(0)));
    }
    /**
    * @notice Helper method to get the ether value equivalent of a token amount.
    * @notice For low value amounts of tokens we accept this to return zero as these are small enough to disregard.
    * Note that the price stored for tokens = price for 1 token (in ETH wei) * 10^(18-token decimals).
    * @param _amount The token amount.
    * @param _token The address of the token.
    * @return The ether value for _amount of _token.
    */
    function getEtherValue(ITokenPriceRegistry _priceRegistry, uint256 _amount, address _token) internal view returns (uint256) {
        uint256 price = _priceRegistry.getTokenPrice(_token);
        uint256 etherValue = price.mul(_amount).div(10**18);
        return etherValue;
    }
    /**
    * @notice Helper method to get the current limit from a Limit struct.
    * @param _limit The limit struct
    */
    function currentLimit(ILimitStorage.Limit memory _limit) internal view returns (uint256) {
        if (_limit.changeAfter > 0 && _limit.changeAfter < block.timestamp) {
            return _limit.pending;
        }
        return _limit.current;
    }
    function safe128(uint256 _num) internal pure returns (uint128) {
        require(_num < 2**128, "LU: more then 128 bits");
        return uint128(_num);
    }
    function safe64(uint256 _num) internal pure returns (uint64) {
        require(_num < 2**64, "LU: more then 64 bits");
        return uint64(_num);
    }
    // *************** Storage invocations in VersionManager ********************* //
    function setLimit(
        IVersionManager _versionManager,
        ILimitStorage _lStorage,
        address _wallet, 
        ILimitStorage.Limit memory _limit
    ) internal {
        _versionManager.invokeStorage(
            _wallet,
            address(_lStorage),
            abi.encodeWithSelector(_lStorage.setLimit.selector, _wallet, _limit)
        );
    }
    function setDailySpent(
        IVersionManager _versionManager,
        ILimitStorage _lStorage,
        address _wallet, 
        ILimitStorage.DailySpent memory _dailySpent
    ) private {
        _versionManager.invokeStorage(
            _wallet,
            address(_lStorage),
            abi.encodeWithSelector(_lStorage.setDailySpent.selector, _wallet, _dailySpent)
        );
    }
}

pragma solidity >=0.5.4 <0.7.0;
/**
 * @title IWallet
 * @notice Interface for the BaseWallet
 */
interface IWallet {
    /**
     * @notice Returns the wallet owner.
     * @return The wallet owner address.
     */
    function owner() external view returns (address);
    /**
     * @notice Returns the number of authorised modules.
     * @return The number of authorised modules.
     */
    function modules() external view returns (uint);
    /**
     * @notice Sets a new owner for the wallet.
     * @param _newOwner The new owner.
     */
    function setOwner(address _newOwner) external;
    /**
     * @notice Checks if a module is authorised on the wallet.
     * @param _module The module address to check.
     * @return `true` if the module is authorised, otherwise `false`.
     */
    function authorised(address _module) external view returns (bool);
    /**
     * @notice Returns the module responsible for a static call redirection.
     * @param _sig The signature of the static call.
     * @return the module doing the redirection
     */
    function enabled(bytes4 _sig) external view returns (address);
    /**
     * @notice Enables/Disables a module.
     * @param _module The target module.
     * @param _value Set to `true` to authorise the module.
     */
    function authoriseModule(address _module, bool _value) external;
    /**
    * @notice Enables a static method by specifying the target module to which the call must be delegated.
    * @param _module The target module.
    * @param _method The static method signature.
    */
    function enableStaticCall(address _module, bytes4 _method) external;
}

pragma solidity >=0.5.4 <0.7.0;
/**
 * @title IModuleRegistry
 * @notice Interface for the registry of authorised modules.
 */
interface IModuleRegistry {
    function registerModule(address _module, bytes32 _name) external;
    function deregisterModule(address _module) external;
    function registerUpgrader(address _upgrader, bytes32 _name) external;
    function deregisterUpgrader(address _upgrader) external;
    function recoverToken(address _token) external;
    function moduleInfo(address _module) external view returns (bytes32);
    function upgraderInfo(address _upgrader) external view returns (bytes32);
    function isRegisteredModule(address _module) external view returns (bool);
    function isRegisteredModule(address[] calldata _modules) external view returns (bool);
    function isRegisteredUpgrader(address _upgrader) external view returns (bool);
}

pragma solidity >=0.5.4 <0.7.0;
interface ILockStorage {
    function isLocked(address _wallet) external view returns (bool);
    function getLock(address _wallet) external view returns (uint256);
    function getLocker(address _wallet) external view returns (address);
    function setLock(address _wallet, address _locker, uint256 _releaseAfter) external;
}
pragma solidity >=0.5.4 <0.7.0;
/**
 * @title IFeature
 * @notice Interface for a Feature.
 * @author Julien Niset - <julien@argent.xyz>, Olivier VDB - <olivier@argent.xyz>
 */
interface IFeature {
    enum OwnerSignature {
        Anyone,             // Anyone
        Required,           // Owner required
        Optional,           // Owner and/or guardians
        Disallowed          // guardians only
    }
    /**
    * @notice Utility method to recover any ERC20 token that was sent to the Feature by mistake.
    * @param _token The token to recover.
    */
    function recoverToken(address _token) external;
    /**
     * @notice Inits a Feature for a wallet by e.g. setting some wallet specific parameters in storage.
     * @param _wallet The wallet.
     */
    function init(address _wallet) external;
    /**
     * @notice Helper method to check if an address is an authorised feature of a target wallet.
     * @param _wallet The target wallet.
     * @param _feature The address.
     */
    function isFeatureAuthorisedInVersionManager(address _wallet, address _feature) external view returns (bool);
    /**
    * @notice Gets the number of valid signatures that must be provided to execute a
    * specific relayed transaction.
    * @param _wallet The target wallet.
    * @param _data The data of the relayed transaction.
    * @return The number of required signatures and the wallet owner signature requirement.
    */
    function getRequiredSignatures(address _wallet, bytes calldata _data) external view returns (uint256, OwnerSignature);
    /**
    * @notice Gets the list of static call signatures that this feature responds to on behalf of wallets
    */
    function getStaticCallSignatures() external view returns (bytes4[] memory);
}
// File: lib/other/ERC20.sol
pragma solidity >=0.5.4 <0.7.0;
/**
 * ERC20 contract interface.
 */
interface ERC20 {
    function totalSupply() external view returns (uint);
    function decimals() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
}
/**
 * @title BaseFeature
 * @notice Base Feature contract that contains methods common to all Feature contracts.
 * @author Julien Niset - <julien@argent.xyz>, Olivier VDB - <olivier@argent.xyz>
 */
contract BaseFeature is IFeature {
    // Empty calldata
    bytes constant internal EMPTY_BYTES = "";
    // Mock token address for ETH
    address constant internal ETH_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    // The address of the Lock storage
    ILockStorage internal lockStorage;
    // The address of the Version Manager
    IVersionManager internal versionManager;
    event FeatureCreated(bytes32 name);
    /**
     * @notice Throws if the wallet is locked.
     */
    modifier onlyWhenUnlocked(address _wallet) {
        require(!lockStorage.isLocked(_wallet), "BF: wallet locked");
        _;
    }
    /**
     * @notice Throws if the sender is not the VersionManager.
     */
    modifier onlyVersionManager() {
        require(msg.sender == address(versionManager), "BF: caller must be VersionManager");
        _;
    }
    /**
     * @notice Throws if the sender is not the owner of the target wallet.
     */
    modifier onlyWalletOwner(address _wallet) {
        require(isOwner(_wallet, msg.sender), "BF: must be wallet owner");
        _;
    }
    /**
     * @notice Throws if the sender is not an authorised feature of the target wallet.
     */
    modifier onlyWalletFeature(address _wallet) {
        require(versionManager.isFeatureAuthorised(_wallet, msg.sender), "BF: must be a wallet feature");
        _;
    }
    /**
     * @notice Throws if the sender is not the owner of the target wallet or the feature itself.
     */
    modifier onlyWalletOwnerOrFeature(address _wallet) {
        // Wrapping in an internal method reduces deployment cost by avoiding duplication of inlined code
        verifyOwnerOrAuthorisedFeature(_wallet, msg.sender);
        _;
    }
    constructor(
        ILockStorage _lockStorage,
        IVersionManager _versionManager,
        bytes32 _name
    ) public {
        lockStorage = _lockStorage;
        versionManager = _versionManager;
        emit FeatureCreated(_name);
    }
    /**
    * @inheritdoc IFeature
    */
    function recoverToken(address _token) external virtual override {
        uint total = ERC20(_token).balanceOf(address(this));
        _token.call(abi.encodeWithSelector(ERC20(_token).transfer.selector, address(versionManager), total));
    }
    /**
     * @notice Inits the feature for a wallet by doing nothing.
     * @dev !! Overriding methods need make sure `init()` can only be called by the VersionManager !!
     * @param _wallet The wallet.
     */
    function init(address _wallet) external virtual override  {}
    /**
     * @inheritdoc IFeature
     */
    function getRequiredSignatures(address, bytes calldata) external virtual view override returns (uint256, OwnerSignature) {
        revert("BF: disabled method");
    }
    /**
     * @inheritdoc IFeature
     */
    function getStaticCallSignatures() external virtual override view returns (bytes4[] memory _sigs) {}
    /**
     * @inheritdoc IFeature
     */
    function isFeatureAuthorisedInVersionManager(address _wallet, address _feature) public override view returns (bool) {
        return versionManager.isFeatureAuthorised(_wallet, _feature);
    }
    /**
    * @notice Checks that the wallet address provided as the first parameter of _data matches _wallet
    * @return false if the addresses are different.
    */
    function verifyData(address _wallet, bytes calldata _data) internal pure returns (bool) {
        require(_data.length >= 36, "RM: Invalid dataWallet");
        address dataWallet = abi.decode(_data[4:], (address));
        return dataWallet == _wallet;
    }
     /**
     * @notice Helper method to check if an address is the owner of a target wallet.
     * @param _wallet The target wallet.
     * @param _addr The address.
     */
    function isOwner(address _wallet, address _addr) internal view returns (bool) {
        return IWallet(_wallet).owner() == _addr;
    }
    /**
     * @notice Verify that the caller is an authorised feature or the wallet owner.
     * @param _wallet The target wallet.
     * @param _sender The caller.
     */
    function verifyOwnerOrAuthorisedFeature(address _wallet, address _sender) internal view {
        require(isFeatureAuthorisedInVersionManager(_wallet, _sender) || isOwner(_wallet, _sender), "BF: must be owner or feature");
    }
    /**
     * @notice Helper method to invoke a wallet.
     * @param _wallet The target wallet.
     * @param _to The target address for the transaction.
     * @param _value The value of the transaction.
     * @param _data The data of the transaction.
     */
    function invokeWallet(address _wallet, address _to, uint256 _value, bytes memory _data)
        internal
        returns (bytes memory _res) 
    {
        _res = versionManager.checkAuthorisedFeatureAndInvokeWallet(_wallet, _to, _value, _data);
    }
}
/**
 * @title BaseTransfer
 * @notice Contains common methods to transfer tokens or call third-party contracts.
 * @author Olivier VDB - <olivier@argent.xyz>
 */
abstract contract BaseTransfer is BaseFeature {
    // The address of the WETH token
    address public wethToken;
    // *************** Events *************************** //
    event Transfer(address indexed wallet, address indexed token, uint256 indexed amount, address to, bytes data);
    event Approved(address indexed wallet, address indexed token, uint256 amount, address spender);
    event CalledContract(address indexed wallet, address indexed to, uint256 amount, bytes data);
    event ApprovedAndCalledContract(
        address indexed wallet,
        address indexed to,
        address spender,
        address indexed token,
        uint256 amountApproved,
        uint256 amountSpent,
        bytes data
    );
    event LimitChanged(address indexed wallet, uint indexed newLimit, uint64 indexed startAfter);
    // *************** Constructor ********************** //
    constructor(address _wethToken) public {
        wethToken = _wethToken;
    }
    // *************** Internal Functions ********************* //
    /**
    * @notice Make sure a contract call is not trying to call a module, a feature, or the wallet itself.
    * @param _wallet The target wallet.
    * @param _contract The address of the contract.
     */
    modifier onlyAuthorisedContractCall(address _wallet, address _contract) {
        require(
            _contract != _wallet && // not calling the wallet
            !IWallet(_wallet).authorised(_contract) && // not calling an authorised module
            !versionManager.isFeatureAuthorised(_wallet, _contract), // not calling an authorised feature
            "BT: Forbidden contract"
        );
        _;
    }
    /**
    * @notice Helper method to transfer ETH or ERC20 for a wallet.
    * @param _wallet The target wallet.
    * @param _token The ERC20 address.
    * @param _to The recipient.
    * @param _value The amount of ETH to transfer
    * @param _data The data to *log* with the transfer.
    */
    function doTransfer(address _wallet, address _token, address _to, uint256 _value, bytes memory _data) internal {
        if (_token == ETH_TOKEN) {
            invokeWallet(_wallet, _to, _value, EMPTY_BYTES);
        } else {
            bytes memory methodData = abi.encodeWithSignature("transfer(address,uint256)", _to, _value);
            bytes memory transferSuccessBytes = invokeWallet(_wallet, _token, 0, methodData);
            // Check transfer is successful, when `transfer` returns a success bool result
            if (transferSuccessBytes.length > 0) {
                require(abi.decode(transferSuccessBytes, (bool)), "RM: Transfer failed");
            }
        }
        emit Transfer(_wallet, _token, _value, _to, _data);
    }
    /**
    * @notice Helper method to approve spending the ERC20 of a wallet.
    * @param _wallet The target wallet.
    * @param _token The ERC20 address.
    * @param _spender The spender address.
    * @param _value The amount of token to transfer.
    */
    function doApproveToken(address _wallet, address _token, address _spender, uint256 _value) internal {
        bytes memory methodData = abi.encodeWithSignature("approve(address,uint256)", _spender, _value);
        invokeWallet(_wallet, _token, 0, methodData);
        emit Approved(_wallet, _token, _value, _spender);
    }
    /**
    * @notice Helper method to call an external contract.
    * @param _wallet The target wallet.
    * @param _contract The contract address.
    * @param _value The ETH value to transfer.
    * @param _data The method data.
    */
    function doCallContract(address _wallet, address _contract, uint256 _value, bytes memory _data) internal {
        invokeWallet(_wallet, _contract, _value, _data);
        emit CalledContract(_wallet, _contract, _value, _data);
    }
    /**
    * @notice Helper method to approve a certain amount of token and call an external contract.
    * The address that spends the _token and the address that is called with _data can be different.
    * @param _wallet The target wallet.
    * @param _token The ERC20 address.
    * @param _proxy The address to approve.
    * @param _amount The amount of tokens to transfer.
    * @param _contract The contract address.
    * @param _data The method data.
    */
    function doApproveTokenAndCallContract(
        address _wallet,
        address _token,
        address _proxy,
        uint256 _amount,
        address _contract,
        bytes memory _data
    )
        internal
    {
        // Ensure there is sufficient balance of token before we approve
        uint256 balance = ERC20(_token).balanceOf(_wallet);
        require(balance >= _amount, "BT: insufficient balance");
        uint256 existingAllowance = ERC20(_token).allowance(_wallet, _proxy);
        uint256 totalAllowance = SafeMath.add(existingAllowance, _amount);
        // Approve the desired amount plus existing amount. This logic allows for potential gas saving later
        // when restoring the original approved amount, in cases where the _proxy uses the exact approved _amount.
        bytes memory methodData = abi.encodeWithSignature("approve(address,uint256)", _proxy, totalAllowance);
        invokeWallet(_wallet, _token, 0, methodData);
        invokeWallet(_wallet, _contract, 0, _data);
        // Calculate the approved amount that was spent after the call
        uint256 unusedAllowance = ERC20(_token).allowance(_wallet, _proxy);
        uint256 usedAllowance = SafeMath.sub(totalAllowance, unusedAllowance);
        // Ensure the amount spent does not exceed the amount approved for this call
        require(usedAllowance <= _amount, "BT: insufficient amount for call");
        if (unusedAllowance != existingAllowance) {
            // Restore the original allowance amount if the amount spent was different (can be lower).
            methodData = abi.encodeWithSignature("approve(address,uint256)", _proxy, existingAllowance);
            invokeWallet(_wallet, _token, 0, methodData);
        }
        emit ApprovedAndCalledContract(
            _wallet,
            _contract,
            _proxy,
            _token,
            _amount,
            usedAllowance,
            _data);
    }
    /**
    * @notice Helper method to wrap ETH into WETH, approve a certain amount of WETH and call an external contract.
    * The address that spends the WETH and the address that is called with _data can be different.
    * @param _wallet The target wallet.
    * @param _proxy The address to approves.
    * @param _amount The amount of tokens to transfer.
    * @param _contract The contract address.
    * @param _data The method data.
    */
    function doApproveWethAndCallContract(
        address _wallet,
        address _proxy,
        uint256 _amount,
        address _contract,
        bytes memory _data
    )
        internal
    {
        uint256 wethBalance = ERC20(wethToken).balanceOf(_wallet);
        if (wethBalance < _amount) {
            // Wrap ETH into WETH
            invokeWallet(_wallet, wethToken, _amount - wethBalance, abi.encodeWithSignature("deposit()"));
        }
        doApproveTokenAndCallContract(_wallet, wethToken, _proxy, _amount, _contract, _data);
    }
}

pragma solidity >=0.5.4 <0.7.0;
interface IGuardianStorage {
    /**
     * @notice Lets an authorised module add a guardian to a wallet.
     * @param _wallet The target wallet.
     * @param _guardian The guardian to add.
     */
    function addGuardian(address _wallet, address _guardian) external;
    /**
     * @notice Lets an authorised module revoke a guardian from a wallet.
     * @param _wallet The target wallet.
     * @param _guardian The guardian to revoke.
     */
    function revokeGuardian(address _wallet, address _guardian) external;
    /**
     * @notice Checks if an account is a guardian for a wallet.
     * @param _wallet The target wallet.
     * @param _guardian The account.
     * @return true if the account is a guardian for a wallet.
     */
    function isGuardian(address _wallet, address _guardian) external view returns (bool);
    function isLocked(address _wallet) external view returns (bool);
    function getLock(address _wallet) external view returns (uint256);
    function getLocker(address _wallet) external view returns (address);
    function setLock(address _wallet, uint256 _releaseAfter) external;
    function getGuardians(address _wallet) external view returns (address[] memory);
    function guardianCount(address _wallet) external view returns (uint256);
}

/**
 * @title ApprovedTransfer
 * @notice Feature to transfer tokens (ETH or ERC20) or call third-party contracts with the approval of guardians.
 * @author Julien Niset - <julien@argent.xyz>
 */
contract ApprovedTransfer is BaseTransfer {
    bytes32 constant NAME = "ApprovedTransfer";
    // The guardian storage
    IGuardianStorage public guardianStorage;
    // The limit storage
    ILimitStorage public limitStorage;
    constructor(
        ILockStorage _lockStorage,
        IGuardianStorage _guardianStorage,
        ILimitStorage _limitStorage,
        IVersionManager _versionManager,
        address _wethToken
    )
        BaseFeature(_lockStorage, _versionManager, NAME)
        BaseTransfer(_wethToken)
        public
    {
        guardianStorage = _guardianStorage;
        limitStorage = _limitStorage;
    }
    /**
    * @notice Transfers tokens (ETH or ERC20) from a wallet.
    * @param _wallet The target wallet.
    * @param _token The address of the token to transfer.
    * @param _to The destination address
    * @param _amount The amount of token to transfer
    * @param _data  The data for the transaction (only for ETH transfers)
    */
    function transferToken(
        address _wallet,
        address _token,
        address _to,
        uint256 _amount,
        bytes calldata _data
    )
        external
        onlyWalletFeature(_wallet)
        onlyWhenUnlocked(_wallet)
    {
        doTransfer(_wallet, _token, _to, _amount, _data);
        LimitUtils.resetDailySpent(versionManager, limitStorage, _wallet);
    }
    /**
    * @notice Call a contract.
    * @param _wallet The target wallet.
    * @param _contract The address of the contract.
    * @param _value The amount of ETH to transfer as part of call
    * @param _data The encoded method data
    */
    function callContract(
        address _wallet,
        address _contract,
        uint256 _value,
        bytes calldata _data
    )
        external
        onlyWalletFeature(_wallet)
        onlyWhenUnlocked(_wallet)
        onlyAuthorisedContractCall(_wallet, _contract)
    {
        doCallContract(_wallet, _contract, _value, _data);
        LimitUtils.resetDailySpent(versionManager, limitStorage, _wallet);
    }
    /**
    * @notice Lets the owner do an ERC20 approve followed by a call to a contract.
    * The address to approve may be different than the contract to call.
    * We assume that the contract does not require ETH.
    * @param _wallet The target wallet.
    * @param _token The token to approve.
    * @param _spender The address to approve.
    * @param _amount The amount of ERC20 tokens to approve.
    * @param _contract The contract to call.
    * @param _data The encoded method data
    */
    function approveTokenAndCallContract(
        address _wallet,
        address _token,
        address _spender,
        uint256 _amount,
        address _contract,
        bytes calldata _data
    )
        external
        onlyWalletFeature(_wallet)
        onlyWhenUnlocked(_wallet)
        onlyAuthorisedContractCall(_wallet, _contract)
    {
        doApproveTokenAndCallContract(_wallet, _token, _spender, _amount, _contract, _data);
        LimitUtils.resetDailySpent(versionManager, limitStorage, _wallet);
    }
    /**
     * @notice Changes the daily limit. The change is immediate.
     * @param _wallet The target wallet.
     * @param _newLimit The new limit.
     */
    function changeLimit(address _wallet, uint256 _newLimit) external onlyWalletFeature(_wallet) onlyWhenUnlocked(_wallet) {
        uint128 targetLimit = LimitUtils.safe128(_newLimit);
        ILimitStorage.Limit memory newLimit = ILimitStorage.Limit(targetLimit, targetLimit, LimitUtils.safe64(block.timestamp));
        ILimitStorage.DailySpent memory resetDailySpent = ILimitStorage.DailySpent(uint128(0), uint64(0));
        setLimitAndDailySpent(_wallet, newLimit, resetDailySpent);
        emit LimitChanged(_wallet, _newLimit, newLimit.changeAfter);
    }
    /**
    * @notice Resets the daily spent amount.
    * @param _wallet The target wallet.
    */
    function resetDailySpent(address _wallet) external onlyWalletFeature(_wallet) onlyWhenUnlocked(_wallet) {
        LimitUtils.resetDailySpent(versionManager, limitStorage, _wallet);
    }
    /**
    * @notice lets the owner wrap ETH into WETH, approve the WETH and call a contract.
    * The address to approve may be different than the contract to call.
    * We assume that the contract does not require ETH.
    * @param _wallet The target wallet.
    * @param _spender The address to approve.
    * @param _amount The amount of ERC20 tokens to approve.
    * @param _contract The contract to call.
    * @param _data The encoded method data
    */
    function approveWethAndCallContract(
        address _wallet,
        address _spender,
        uint256 _amount,
        address _contract,
        bytes calldata _data
    )
        external
        onlyWalletFeature(_wallet)
        onlyWhenUnlocked(_wallet)
        onlyAuthorisedContractCall(_wallet, _contract)
    {
        doApproveWethAndCallContract(_wallet, _spender, _amount, _contract, _data);
        LimitUtils.resetDailySpent(versionManager, limitStorage, _wallet);
    }
    /**
     * @inheritdoc IFeature
     */
    function getRequiredSignatures(address _wallet, bytes calldata) external view override returns (uint256, OwnerSignature) {
        // owner  + [n/2] guardians
        uint numberOfGuardians = Utils.ceil(guardianStorage.guardianCount(_wallet), 2);
        require(numberOfGuardians > 0, "AT: no guardians set on wallet");
        uint numberOfSignatures = 1 + numberOfGuardians;
        return (numberOfSignatures, OwnerSignature.Required);
    }
    // *************** Internal Functions ********************* //
    function setLimitAndDailySpent(
        address _wallet,
        ILimitStorage.Limit memory _limit,
        ILimitStorage.DailySpent memory _dailySpent
    ) internal {
        versionManager.invokeStorage(
            _wallet,
            address(limitStorage),
            abi.encodeWithSelector(limitStorage.setLimitAndDailySpent.selector, _wallet, _limit, _dailySpent)
        );
    }
}