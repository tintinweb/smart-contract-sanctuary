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
 * @title GuardianUtils
 * @notice Bundles guardian read logic.
 */
library GuardianUtils {
    /**
    * @notice Checks if an address is a guardian or an account authorised to sign on behalf of a smart-contract guardian
    * given a list of guardians.
    * @param _guardians the list of guardians
    * @param _guardian the address to test
    * @return true and the list of guardians minus the found guardian upon success, false and the original list of guardians if not found.
    */
    function isGuardianOrGuardianSigner(address[] memory _guardians, address _guardian) internal view returns (bool, address[] memory) {
        if (_guardians.length == 0 || _guardian == address(0)) {
            return (false, _guardians);
        }
        bool isFound = false;
        address[] memory updatedGuardians = new address[](_guardians.length - 1);
        uint256 index = 0;
        for (uint256 i = 0; i < _guardians.length; i++) {
            if (!isFound) {
                // check if _guardian is an account guardian
                if (_guardian == _guardians[i]) {
                    isFound = true;
                    continue;
                }
                // check if _guardian is the owner of a smart contract guardian
                if (isContract(_guardians[i]) && isGuardianOwner(_guardians[i], _guardian)) {
                    isFound = true;
                    continue;
                }
            }
            if (index < updatedGuardians.length) {
                updatedGuardians[index] = _guardians[i];
                index++;
            }
        }
        return isFound ? (true, updatedGuardians) : (false, _guardians);
    }
   /**
    * @notice Checks if an address is a contract.
    * @param _addr The address.
    */
    function isContract(address _addr) internal view returns (bool) {
        uint32 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }
    /**
    * @notice Checks if an address is the owner of a guardian contract.
    * The method does not revert if the call to the owner() method consumes more then 5000 gas.
    * @param _guardian The guardian contract
    * @param _owner The owner to verify.
    */
    function isGuardianOwner(address _guardian, address _owner) internal view returns (bool) {
        address owner = address(0);
        bytes4 sig = bytes4(keccak256("owner()"));
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr,sig)
            let result := staticcall(5000, _guardian, ptr, 0x20, ptr, 0x20)
            if eq(result, 1) {
                owner := mload(ptr)
            }
        }
        return owner == _owner;
    }
}
/**
 * @title ITokenPriceRegistry
 * @notice TokenPriceRegistry interface
 */
interface ITokenPriceRegistry {
    function getTokenPrice(address _token) external view returns (uint184 _price);
    function isTokenTradable(address _token) external view returns (bool _isTradable);
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
 * @title RelayerManager
 * @notice Feature to execute transactions signed by ETH-less accounts and sent by a relayer.
 * @author Julien Niset <julien@argent.xyz>, Olivier VDB <olivier@argent.xyz>
 */
contract RelayerManager is BaseFeature {
    bytes32 constant NAME = "RelayerManager";
    uint256 constant internal BLOCKBOUND = 10000;
    using SafeMath for uint256;
    mapping (address => RelayerConfig) public relayer;
    // The storage of the limit
    ILimitStorage public limitStorage;
    // The Token price storage
    ITokenPriceRegistry public tokenPriceRegistry;
    // The Guardian storage
    IGuardianStorage public guardianStorage;
    struct RelayerConfig {
        uint256 nonce;
        mapping (bytes32 => bool) executedTx;
    }
    // Used to avoid stack too deep error
    struct StackExtension {
        uint256 requiredSignatures;
        OwnerSignature ownerSignatureRequirement;
        bytes32 signHash;
        bool success;
        bytes returnData;
    }
    event TransactionExecuted(address indexed wallet, bool indexed success, bytes returnData, bytes32 signedHash);
    event Refund(address indexed wallet, address indexed refundAddress, address refundToken, uint256 refundAmount);
    /* ***************** External methods ************************* */
    constructor(
        ILockStorage _lockStorage,
        IGuardianStorage _guardianStorage,
        ILimitStorage _limitStorage,
        ITokenPriceRegistry _tokenPriceRegistry,
        IVersionManager _versionManager
    )
        BaseFeature(_lockStorage, _versionManager, NAME)
        public
    {
        limitStorage = _limitStorage;
        tokenPriceRegistry = _tokenPriceRegistry;
        guardianStorage = _guardianStorage;
    }
    /**
    * @notice Executes a relayed transaction.
    * @param _wallet The target wallet.
    * @param _feature The target feature.
    * @param _data The data for the relayed transaction
    * @param _nonce The nonce used to prevent replay attacks.
    * @param _signatures The signatures as a concatenated byte array.
    * @param _gasPrice The gas price to use for the gas refund.
    * @param _gasLimit The gas limit to use for the gas refund.
    * @param _refundToken The token to use for the gas refund.
    * @param _refundAddress The address refunded to prevent front-running.
    */
    function execute(
        address _wallet,
        address _feature,
        bytes calldata _data,
        uint256 _nonce,
        bytes calldata _signatures,
        uint256 _gasPrice,
        uint256 _gasLimit,
        address _refundToken,
        address _refundAddress
    )
        external
        returns (bool)
    {
        uint startGas = gasleft();
        require(startGas >= _gasLimit, "RM: not enough gas provided");
        require(verifyData(_wallet, _data), "RM: Target of _data != _wallet");
        require(isFeatureAuthorisedInVersionManager(_wallet, _feature), "RM: feature not authorised");
        StackExtension memory stack;
        (stack.requiredSignatures, stack.ownerSignatureRequirement) = IFeature(_feature).getRequiredSignatures(_wallet, _data);
        require(stack.requiredSignatures > 0 || stack.ownerSignatureRequirement == OwnerSignature.Anyone, "RM: Wrong signature requirement");
        require(stack.requiredSignatures * 65 == _signatures.length, "RM: Wrong number of signatures");
        stack.signHash = getSignHash(
            address(this),
            _feature,
            0,
            _data,
            _nonce,
            _gasPrice,
            _gasLimit,
            _refundToken,
            _refundAddress);
        require(checkAndUpdateUniqueness(
            _wallet,
            _nonce,
            stack.signHash,
            stack.requiredSignatures,
            stack.ownerSignatureRequirement), "RM: Duplicate request");
        require(validateSignatures(_wallet, stack.signHash, _signatures, stack.ownerSignatureRequirement), "RM: Invalid signatures");
        (stack.success, stack.returnData) = _feature.call(_data);
        // only refund when approved by owner and positive gas price
        if (_gasPrice > 0 && stack.ownerSignatureRequirement == OwnerSignature.Required) {
            refund(
                _wallet,
                startGas,
                _gasPrice,
                _gasLimit,
                _refundToken,
                _refundAddress,
                stack.requiredSignatures);
        }
        emit TransactionExecuted(_wallet, stack.success, stack.returnData, stack.signHash);
        return stack.success;
    }
    /**
    * @notice Gets the current nonce for a wallet.
    * @param _wallet The target wallet.
    */
    function getNonce(address _wallet) external view returns (uint256 nonce) {
        return relayer[_wallet].nonce;
    }
    /**
    * @notice Checks if a transaction identified by its sign hash has already been executed.
    * @param _wallet The target wallet.
    * @param _signHash The sign hash of the transaction.
    */
    function isExecutedTx(address _wallet, bytes32 _signHash) external view returns (bool executed) {
        return relayer[_wallet].executedTx[_signHash];
    }
    /* ***************** Internal & Private methods ************************* */
    /**
    * @notice Generates the signed hash of a relayed transaction according to ERC 1077.
    * @param _from The starting address for the relayed transaction (should be the relayer module)
    * @param _to The destination address for the relayed transaction (should be the target module)
    * @param _value The value for the relayed transaction.
    * @param _data The data for the relayed transaction which includes the wallet address.
    * @param _nonce The nonce used to prevent replay attacks.
    * @param _gasPrice The gas price to use for the gas refund.
    * @param _gasLimit The gas limit to use for the gas refund.
    * @param _refundToken The token to use for the gas refund.
    * @param _refundAddress The address refunded to prevent front-running.
    */
    function getSignHash(
        address _from,
        address _to,
        uint256 _value,
        bytes memory _data,
        uint256 _nonce,
        uint256 _gasPrice,
        uint256 _gasLimit,
        address _refundToken,
        address _refundAddress
    )
        internal
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(
                    byte(0x19),
                    byte(0),
                    _from,
                    _to,
                    _value,
                    _data,
                    getChainId(),
                    _nonce,
                    _gasPrice,
                    _gasLimit,
                    _refundToken,
                    _refundAddress))
        ));
    }
    /**
    * @notice Checks if the relayed transaction is unique. If yes the state is updated.
    * For actions requiring 1 signature by the owner we use the incremental nonce.
    * For all other actions we check/store the signHash in a mapping.
    * @param _wallet The target wallet.
    * @param _nonce The nonce.
    * @param _signHash The signed hash of the transaction.
    * @param requiredSignatures The number of signatures required.
    * @param ownerSignatureRequirement The wallet owner signature requirement.
    * @return true if the transaction is unique.
    */
    function checkAndUpdateUniqueness(
        address _wallet,
        uint256 _nonce,
        bytes32 _signHash,
        uint256 requiredSignatures,
        OwnerSignature ownerSignatureRequirement
    )
        internal
        returns (bool)
    {
        if (requiredSignatures == 1 && ownerSignatureRequirement == OwnerSignature.Required) {
            // use the incremental nonce
            if (_nonce <= relayer[_wallet].nonce) {
                return false;
            }
            uint256 nonceBlock = (_nonce & 0xffffffffffffffffffffffffffffffff00000000000000000000000000000000) >> 128;
            if (nonceBlock > block.number + BLOCKBOUND) {
                return false;
            }
            relayer[_wallet].nonce = _nonce;
            return true;
        } else {
            // use the txHash map
            if (relayer[_wallet].executedTx[_signHash] == true) {
                return false;
            }
            relayer[_wallet].executedTx[_signHash] = true;
            return true;
        }
    }
    /**
    * @notice Validates the signatures provided with a relayed transaction.
    * The method MUST throw if one or more signatures are not valid.
    * @param _wallet The target wallet.
    * @param _signHash The signed hash representing the relayed transaction.
    * @param _signatures The signatures as a concatenated byte array.
    * @param _option An enum indicating whether the owner is required, optional or disallowed.
    * @return A boolean indicating whether the signatures are valid.
    */
    function validateSignatures(
        address _wallet,
        bytes32 _signHash,
        bytes memory _signatures,
        OwnerSignature _option
    )
        internal
        view
        returns (bool)
    {
        if (_signatures.length == 0) {
            return true;
        }
        address lastSigner = address(0);
        address[] memory guardians;
        if (_option != OwnerSignature.Required || _signatures.length > 65) {
            guardians = guardianStorage.getGuardians(_wallet); // guardians are only read if they may be needed
        }
        bool isGuardian;
        for (uint256 i = 0; i < _signatures.length / 65; i++) {
            address signer = Utils.recoverSigner(_signHash, _signatures, i);
            if (i == 0) {
                if (_option == OwnerSignature.Required) {
                    // First signer must be owner
                    if (isOwner(_wallet, signer)) {
                        continue;
                    }
                    return false;
                } else if (_option == OwnerSignature.Optional) {
                    // First signer can be owner
                    if (isOwner(_wallet, signer)) {
                        continue;
                    }
                }
            }
            if (signer <= lastSigner) {
                return false; // Signers must be different
            }
            lastSigner = signer;
            (isGuardian, guardians) = GuardianUtils.isGuardianOrGuardianSigner(guardians, signer);
            if (!isGuardian) {
                return false;
            }
        }
        return true;
    }
    /**
    * @notice Refunds the gas used to the Relayer.
    * @param _wallet The target wallet.
    * @param _startGas The gas provided at the start of the execution.
    * @param _gasPrice The gas price for the refund.
    * @param _gasLimit The gas limit for the refund.
    * @param _refundToken The token to use for the gas refund.
    * @param _refundAddress The address refunded to prevent front-running.
    * @param _requiredSignatures The number of signatures required.
    */
    function refund(
        address _wallet,
        uint _startGas,
        uint _gasPrice,
        uint _gasLimit,
        address _refundToken,
        address _refundAddress,
        uint256 _requiredSignatures
    )
        internal
    {
        address refundAddress = _refundAddress == address(0) ? msg.sender : _refundAddress;
        uint256 refundAmount;
        // skip daily limit when approved by guardians (and signed by owner)
        if (_requiredSignatures > 1) {
            uint256 gasConsumed = _startGas.sub(gasleft()).add(30000);
            refundAmount = Utils.min(gasConsumed, _gasLimit).mul(_gasPrice);
        } else {
            uint256 gasConsumed = _startGas.sub(gasleft()).add(40000);
            refundAmount = Utils.min(gasConsumed, _gasLimit).mul(_gasPrice);
            uint256 ethAmount = (_refundToken == ETH_TOKEN) ? refundAmount : LimitUtils.getEtherValue(tokenPriceRegistry, refundAmount, _refundToken);
            require(LimitUtils.checkAndUpdateDailySpent(limitStorage, versionManager, _wallet, ethAmount), "RM: refund is above daily limit");
        }
        // refund in ETH or ERC20
        if (_refundToken == ETH_TOKEN) {
            invokeWallet(_wallet, refundAddress, refundAmount, EMPTY_BYTES);
        } else {
            bytes memory methodData = abi.encodeWithSignature("transfer(address,uint256)", refundAddress, refundAmount);
		    bytes memory transferSuccessBytes = invokeWallet(_wallet, _refundToken, 0, methodData);
            // Check token refund is successful, when `transfer` returns a success bool result
            if (transferSuccessBytes.length > 0) {
                require(abi.decode(transferSuccessBytes, (bool)), "RM: Refund transfer failed");
            }
        }
        emit Refund(_wallet, refundAddress, _refundToken, refundAmount);
    }
   /**
    * @notice Returns the current chainId
    * @return chainId the chainId
    */
    function getChainId() private pure returns (uint256 chainId) {
        // solhint-disable-next-line no-inline-assembly
        assembly { chainId := chainid() }
    }
}