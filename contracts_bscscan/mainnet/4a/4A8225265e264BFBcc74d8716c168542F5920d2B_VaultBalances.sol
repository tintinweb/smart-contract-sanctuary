// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol";
import "../reva/interfaces/IReVault.sol";
import "./interfaces/IACryptoSFarm.sol";
import "./interfaces/IAutoFarmStratX.sol";
import "../vaults/IACryptoSVault.sol";
import "../vaults/IBunnyVault.sol";
import "../vaults/IAutoFarm.sol";
import "../vaults/IBeefyVault.sol";

contract VaultBalances is OwnableUpgradeable {
    using SafeMath for uint;

    IReVault private constant revault = IReVault(0x2642fa04bd1f7250be6539c5bDa36335333d9Ccd);

    // mapping vault id to vault type, following
    //enum VaultTypes { Acryptos, Bunny, Auto, Beefy }
    mapping (uint => uint8) public vaultTypes;

    mapping (uint => uint) public autofarmPids;

    function initialize(
    ) external initializer {
        __Ownable_init();
    }

    function getUserVaultBalance(address user, uint vid) public view returns (uint) {
        uint8 vaultType = vaultTypes[vid];
        //enum VaultTypes { Acryptos, Bunny, Auto, Beefy }
        if (vaultType == 0) {
            return getUserAcryptosVaultBalance(user, vid);
        } else if (vaultType == 1) {
            return getUserBunnyVaultBalance(user, vid);
        } else if (vaultType == 2) {
            uint pid = autofarmPids[vid];
            return getUserAutoVaultBalance(user, vid, pid);
        } else if (vaultType == 3) {
            return getUserBeefyVaultBalance(user, vid);
        }
    }

    function getUserAcryptosVaultBalance(address user, uint vid) public view returns (uint) {
        address userProxyContract = revault.userProxyContractAddress(user);
        (address farmAddress, address farmTokenAddress) = revault.vaultFarmInfo(vid);
        (address vaultAddress,,) = revault.vaults(vid);
        (uint farmBalance,,,) = IACryptoSFarm(farmAddress).userInfo(farmTokenAddress, userProxyContract);
        uint pricePerShare = IACryptoSVault(vaultAddress).getPricePerFullShare();
        return farmBalance.mul(pricePerShare).div(1e18);
    }

    function getUserBunnyVaultBalance(address user, uint vid) public view returns (uint) {
        address userProxyContract = revault.userProxyContractAddress(user);
        (address vaultAddress,,) = revault.vaults(vid);
        uint balance = IBunnyVault(vaultAddress).balanceOf(userProxyContract);
        return balance;
    }

    function getUserAutoVaultBalance(address user, uint vid, uint pid) public view returns (uint) {
        address userProxyContract = revault.userProxyContractAddress(user);
        (address vaultAddress,,) = revault.vaults(vid);
        (uint shares,) = IAutoFarm(vaultAddress).userInfo(pid, userProxyContract);
        (,,,,address strategyAddress) = IAutoFarm(vaultAddress).poolInfo(pid);
        uint wantLockedTotal = IAutoFarmStratX(strategyAddress).wantLockedTotal();
        uint sharesTotal = IAutoFarmStratX(strategyAddress).sharesTotal();
        uint balance = shares.mul(wantLockedTotal).div(sharesTotal);
        return balance;
    }

    function getUserBeefyVaultBalance(address user, uint vid) public view returns (uint) {
        address userProxyContract = revault.userProxyContractAddress(user);
        (address vaultAddress,,) = revault.vaults(vid);
        uint pricePerFullShare = IBeefyVault(vaultAddress).getPricePerFullShare();
        uint sharesBalance = IBeefyVault(vaultAddress).balanceOf(userProxyContract);
        uint balance = sharesBalance.mul(pricePerFullShare).div(1e18);
        return balance;
    }

    function setVaultTypes(uint[] memory vids, uint8[] memory types) public onlyOwner {
        for (uint i = 0; i < vids.length; i++) {
            vaultTypes[vids[i]] = types[i];
        }
    }

    function setAutoPids(uint[] memory vids, uint[] memory pids) public onlyOwner {
        for (uint i = 0; i < vids.length; i++) {
            autofarmPids[vids[i]] = pids[i];
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.0;

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
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
     *
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
        require(c / a == b, 'SafeMath: multiplication overflow');

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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
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
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, 'SafeMath: modulo by zero');
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
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IReVault {
    function depositToVaultFor(uint _amount, uint _vid, bytes calldata _depositPayload, address _user) external payable;
    function depositToVaultAndFarmFor(
        uint _amount,
        uint _vid,
        bytes calldata _depositVaultPayload,
        bytes calldata _depositFarmPayload,
        address _user
    ) external payable;
    function userProxyContractAddress(address user) external view returns (address);
    function vaults(uint id) external view returns (address, address, address);
    function vaultFarmInfo(uint id) external view returns (address, address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IACryptoSFarm {
    function harvest(address _lpToken) external;
    function deposit(address _lpToken, uint _amount) external;
    function withdraw(address _lpToken, uint _amount) external;
    function userInfo(address _lpToken, address _user) external view returns (uint, uint, uint, uint);
    function harvestFee() external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IAutoFarmStratX {

    function controllerFee() external view returns (uint256);
    function controllerFeeMax() external view returns (uint256);
    function controllerFeeUL() external view returns (uint256);

    function entranceFeeFactor() external view returns (uint256);
    function entranceFeeFactorMax() external view returns (uint256);
    function entranceFeeFactorLL() external view returns (uint256);

    function wantLockedTotal() external view returns (uint256);
    function sharesTotal() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IACryptoSVault {
    function approve(address _to, uint256 _amount) external;
    function deposit(uint256 _amount) external;
    function depositAll() external;
    function depositETH() external payable;
    function withdraw(uint256 _shares) external;
    function withdrawAll() external;
    function withdrawETH(uint256 _shares) external;
    function withdrawAllETH() external;
    function getPricePerFullShare() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

// vault that controls a single token
interface IBunnyVault {

    // Read

    function keeper() external view returns (address);

    function balanceOf(address _account) external view returns (uint256);

    function depositedAt(address _account) external view returns (uint256);

    function minter() external view returns (address);

    function principalOf(address _account) external view returns (uint256);

    function sharesOf(address _account) external view returns (uint256);

    function earned(address _account) external view returns (uint256);

    function withdrawableBalanceOf(address _account) external view returns (uint256);

    function balance() external view returns (uint256);

    function totalShares() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    // for tests, callable only by keeper
    function harvest() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IAutoFarm {

    struct UserInfo {
        uint256 shares;        // How many LP tokens the user has provided
        uint256 rewardDebt;    // How much pending AUTO the user is entitled to
    }

    struct PoolInfo {
        address want;               // Address of want token
        uint256 allocPoint;         // How many allocation points assigned to this pool. AUTO to distribute per block.
        uint256 lastRewardBlock;    // Last block number that AUTO distribution occurs
        uint256 accAUTOPerShare;    // Accumulated AUTO per share, times 1e12
        address strat;              // Strategy address that will auto compound want tokens
    }

    function totalAllocPoint() external view returns (uint256);

    function userInfo(uint _pid, address _userAddress) external view returns (uint256, uint256);

    function poolInfo(uint _pid) external view returns (address, uint256, uint256, uint256, address);

    function poolLength() external view returns (uint256);

    function deposit(uint256 _pid, uint256 _wantAmt) external;

    function withdrawAll(uint256 _pid) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function pendingAUTO(uint256 _pid, address _userAddress) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

// vault that controls a single token
interface IBeefyVault {

    function strategy() external view returns (address);

    function withdrawAll() external;

    function withdrawAllBNB() external;

    function depositAll() external;

    function withdraw(uint256 _shares) external;

    function withdrawBNB(uint256 _shares) external;

    function deposit(uint256 _amount) external;

    function depositBNB() external payable;

    function balanceOf(address account) external view returns (uint256);

    function balance() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function getPricePerFullShare() external view returns (uint256);

    function earn() external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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