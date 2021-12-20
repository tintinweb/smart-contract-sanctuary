/**
 *Submitted for verification at polygonscan.com on 2021-12-20
*/

// SPDX-License-Identifier: MIT
// File: contracts/Address.sol



pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// File: contracts/Displayable.sol



pragma solidity ^0.8.0;

contract Displayable {
  function bytes32ToString(bytes32 x) public pure returns (string memory) {
    bytes memory bytesString = new bytes(32);
    uint256 charCount = 0;
    for (uint256 i = 0; i < 32; i++) {
      if (x[i] != 0) {
        bytesString[charCount] = x[i];
        charCount++;
      }
    }
    bytes memory bytesStringTrimmed = new bytes(charCount);
    for (uint256 j = 0; j < charCount; j++) {
      bytesStringTrimmed[j] = bytesString[j];
    }
    return string(bytesStringTrimmed);
  }
}
// File: contracts/IStorable.sol



pragma solidity ^0.8.0;

interface IStorable {
  function getLedgerNameHash() external view returns (bytes32);
  function getStorageNameHash() external view returns (bytes32);
}
// File: contracts/Configurable.sol



pragma solidity ^0.8.0;

interface Configurable {
  function configureFromStorage() external returns (bool);
}
// File: contracts/ITokenLedger.sol



pragma solidity ^0.8.0;

interface ITokenLedger {
  function mintTokens(uint256 amount) external;
  function transfer(address sender, address reciever, uint256 amount) external;
  function creditAccount(address account, uint256 amount) external;
  function debitAccount(address account, uint256 amount) external;
  function totalTokens() external view returns (uint256);
  function totalInCirculation() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
}
// File: contracts/Context.sol



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
// File: contracts/Ownable.sol



pragma solidity ^0.8.0;


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
// File: contracts/Administratable.sol



pragma solidity ^0.8.0;


contract Administratable is Ownable{
  
  address[] tempAddrArray;
  address[] public adminsForIndex;
  address[] public superAdminsForIndex;
  mapping (address => bool) public admins;
  mapping (address => bool) public superAdmins;
  mapping (address => bool) private processedAdmin;
  mapping (address => bool) private processedSuperAdmin;

  event AddAdmin(address indexed admin);
  event RemoveAdmin(address indexed admin);
  event AddSuperAdmin(address indexed admin);
  event RemoveSuperAdmin(address indexed admin);
  
  constructor() {
    _addSuperAdmin(msg.sender);
    emit AddSuperAdmin(msg.sender);
  }

  modifier onlyAdmins {
    require(msg.sender == owner() || superAdmins[msg.sender] || admins[msg.sender], "This function is for admins only");
    _;
  }

  modifier onlySuperAdmins {
    require(msg.sender == owner() || superAdmins[msg.sender], "This function is for super admins only");
    _;
  }

  function addSuperAdmin(address admin) public onlySuperAdmins {
    _addSuperAdmin(admin);

    emit AddSuperAdmin(admin);
  }

  function removeSuperAdmin(address admin) public onlySuperAdmins {
    require(admin != address(0), "the burn address is not a valid input for this function");
    require(superAdmins[admin], "This address is not a super admin");
    superAdmins[admin] = false;
    superAdminsForIndex = removeAddrFromArray(admin, superAdminsForIndex);

    emit RemoveSuperAdmin(admin);
  }

  function addAdmin(address admin) public onlySuperAdmins {
    require(admin != address(0), "the burn address is not a valid input for this function");
    admins[admin] = true;
    if (!processedAdmin[admin]) {
      adminsForIndex.push(admin);
      processedAdmin[admin] = true;
    }

    emit AddAdmin(admin);
  }

  function removeAdmin(address admin) public onlySuperAdmins {
    require(admin != address(0), "the burn address is not a valid input for this function");
    require(admins[admin], "This address is not an admin");
    admins[admin] = false;
    adminsForIndex = removeAddrFromArray(admin, adminsForIndex);

    emit RemoveAdmin(admin);
  }

  function totalSuperAdminsMapping() public view returns (uint256) {
    return superAdminsForIndex.length;
  }

  function totalAdminsMapping() public view returns (uint256) {
    return adminsForIndex.length;
  }

  function _addSuperAdmin(address admin) internal {
    require(admin != address(0), "the burn address is not a valid input for this function");
    superAdmins[admin] = true;
    if (!processedSuperAdmin[admin]) {
      superAdminsForIndex.push(admin);
      processedSuperAdmin[admin] = true;
    }
  }

  function removeAddrFromArray(address addr, address[] storage _array) internal returns(address[] memory) {

    tempAddrArray = new address[](16);

    for (uint i = 0; i < _array.length; i++){
        if(_array[i] != addr)
            tempAddrArray.push(_array[i]);
    }

    return tempAddrArray;
  }
}
// File: contracts/ERC20.sol



pragma solidity ^0.8.0;

interface ERC20 {
  function allowance(address owner, address spender) external view returns (uint256);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function totalSupply() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function burn(uint256 amount) external returns (bool);
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
// File: contracts/SafeMath.sol



pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}
// File: contracts/GCoinLedger.sol



pragma solidity ^0.8.0;




contract GCoinLedger is ITokenLedger, Administratable {
  using SafeMath for uint256;

  /* BEGIN VARIABLES */
  uint256 private _totalInCirculation; // warning this does not take into account unvested nor vested-unreleased tokens into consideration
  uint256 private _totalTokens;
  mapping (address => uint256) private _balanceOf;
  /* END VARIABLES */

  function transfer(address sender, address recipient, uint256 amount) external override onlyAdmins {
    require(sender != address(0), "the burn address is not a valid input for sender");
    require(recipient != address(0), "the burn address is not a valid input for recipient");
    require(_balanceOf[sender] >= amount, "insufficient balance");

    _balanceOf[sender] = _balanceOf[sender].sub(amount);
    _balanceOf[recipient] = _balanceOf[recipient].add(amount);
  }

  function creditAccount(address account, uint256 amount) external override onlyAdmins { // remove tokens
    require(account != address(0), "the burn address is not a valid input for this function");
    require(_balanceOf[account] >= amount, "insufficient balance");

    _totalInCirculation = _totalInCirculation.sub(amount);
    _balanceOf[account] = _balanceOf[account].sub(amount);
  }

  function debitAccount(address account, uint256 amount) external override onlyAdmins { // add tokens
    require(account != address(0));
    _totalInCirculation = _totalInCirculation.add(amount);
    _balanceOf[account] = _balanceOf[account].add(amount);
  }

  function totalTokens() external view override returns (uint256) {
    return _totalTokens;
  }

  function totalInCirculation() external view override returns (uint256) {
    return _totalInCirculation;
  }

  function balanceOf(address account) external view override returns (uint256) {
    return _balanceOf[account];
  }

  function mintTokens(uint256 amount) external override onlyAdmins {
    _totalTokens = _totalTokens.add(amount);
  }
}
// File: contracts/ExternalStorage.sol



pragma solidity ^0.8.0;



contract ExternalStorage is Administratable {
  using SafeMath for uint256;

  mapping(bytes32 => address[]) public primaryLedgerEntryForIndex;
  mapping(bytes32 => mapping(address => address[])) public secondaryLedgerEntryForIndex;
  mapping(bytes32 => address[]) public ledgerEntryForIndex;
  mapping(bytes32 => address[]) public booleanMapEntryForIndex;

  mapping(bytes32 => mapping(address => mapping(address => uint256))) private MultiLedgerStorage;
  mapping(bytes32 => mapping(address => bool)) private ledgerPrimaryEntries;
  mapping(bytes32 => mapping(address => mapping(address => bool))) private ledgerSecondaryEntries;
  mapping(bytes32 => mapping(address => uint256)) private LedgerStorage;
  mapping(bytes32 => mapping(address => bool)) private ledgerAccounts;
  mapping(bytes32 => mapping(address => bool)) private BooleanMapStorage;
  mapping(bytes32 => mapping(address => bool)) private booleanMapAccounts;
  mapping(bytes32 => uint256) private UIntStorage;
  mapping(bytes32 => bytes32) private Bytes32Storage;
  mapping(bytes32 => address) private AddressStorage;
  mapping(bytes32 => bytes) private BytesStorage;
  mapping(bytes32 => bool) private BooleanStorage;
  mapping(bytes32 => int256) private IntStorage;

  function getMultiLedgerValue(string memory record, address primaryAddress, address secondaryAddress) external view returns (uint256) {
    return MultiLedgerStorage[keccak256(abi.encodePacked(record))][primaryAddress][secondaryAddress];
  }

  function primaryLedgerCount(string memory record) external view returns (uint256) {
    return primaryLedgerEntryForIndex[keccak256(abi.encodePacked(record))].length;
  }

  function secondaryLedgerCount(string memory record, address primaryAddress) external view returns (uint256) {
    return secondaryLedgerEntryForIndex[keccak256(abi.encodePacked(record))][primaryAddress].length;
  }

  function setMultiLedgerValue(string memory record, address primaryAddress, address secondaryAddress, uint256 value) external onlyAdmins {
    bytes32 hash = keccak256(abi.encodePacked(record));
    if (!ledgerSecondaryEntries[hash][primaryAddress][secondaryAddress]) {
      secondaryLedgerEntryForIndex[hash][primaryAddress].push(secondaryAddress);
      ledgerSecondaryEntries[hash][primaryAddress][secondaryAddress] = true;

      if (!ledgerPrimaryEntries[hash][primaryAddress]) {
        primaryLedgerEntryForIndex[hash].push(primaryAddress);
        ledgerPrimaryEntries[hash][primaryAddress] = true;
      }
    }

    MultiLedgerStorage[hash][primaryAddress][secondaryAddress] = value;
  }

  function getLedgerValue(string memory record, address _address) external view returns (uint256) {
    return LedgerStorage[keccak256(abi.encodePacked(record))][_address];
  }

  function getLedgerCount(string memory record) external view returns (uint256) {
    return ledgerEntryForIndex[keccak256(abi.encodePacked(record))].length;
  }

  function setLedgerValue(string memory record, address _address, uint256 value) external onlyAdmins {
    bytes32 hash = keccak256(abi.encodePacked(record));
    if (!ledgerAccounts[hash][_address]) {
      ledgerEntryForIndex[hash].push(_address);
      ledgerAccounts[hash][_address] = true;
    }

    LedgerStorage[hash][_address] = value;
  }

  function getBooleanMapValue(string memory record, address _address) external view returns (bool) {
    return BooleanMapStorage[keccak256(abi.encodePacked(record))][_address];
  }

  function getBooleanMapCount(string memory record) external view returns (uint256) {
    return booleanMapEntryForIndex[keccak256(abi.encodePacked(record))].length;
  }

  function setBooleanMapValue(string memory record, address _address, bool value) external onlyAdmins {
    bytes32 hash = keccak256(abi.encodePacked(record));
    if (!booleanMapAccounts[hash][_address]) {
      booleanMapEntryForIndex[hash].push(_address);
      booleanMapAccounts[hash][_address] = true;
    }

    BooleanMapStorage[hash][_address] = value;
  }

  function getUIntValue(string memory record) external view returns (uint256) {
    return UIntStorage[keccak256(abi.encodePacked(record))];
  }

  function setUIntValue(string memory record, uint256 value) external onlyAdmins {
    UIntStorage[keccak256(abi.encodePacked(record))] = value;
  }

  function getBytes32Value(string memory record) external view returns (bytes32) {
    return Bytes32Storage[keccak256(abi.encodePacked(record))];
  }

  function setBytes32Value(string memory record, bytes32 value) external onlyAdmins {
    Bytes32Storage[keccak256(abi.encodePacked(record))] = value;
  }

  function getAddressValue(string memory record) external view returns (address) {
    return AddressStorage[keccak256(abi.encodePacked(record))];
  }

  function setAddressValue(string memory record, address value) external onlyAdmins {
    AddressStorage[keccak256(abi.encodePacked(record))] = value;
  }

  function getBytesValue(string memory record) external view returns (bytes memory) {
    return BytesStorage[keccak256(abi.encodePacked(record))];
  }

  function setBytesValue(string memory record, bytes memory value) external onlyAdmins {
    BytesStorage[keccak256(abi.encodePacked(record))] = value;
  }

  function getBooleanValue(string memory record) external view returns (bool) {
    return BooleanStorage[keccak256(abi.encodePacked(record))];
  }

  function setBooleanValue(string memory record, bool value) external onlyAdmins {
    BooleanStorage[keccak256(abi.encodePacked(record))] = value;
  }

  function getIntValue(string memory record) external view returns (int256) {
    return IntStorage[keccak256(abi.encodePacked(record))];
  }

  function setIntValue(string memory record, int256 value) external onlyAdmins {
    IntStorage[keccak256(abi.encodePacked(record))] = value;
  }
}
// File: contracts/CstLibrary.sol



pragma solidity ^0.8.0;



library CstLibrary {
  using SafeMath for uint256;

  function getTokenName(address _storage) public view returns(bytes32) {
    return ExternalStorage(_storage).getBytes32Value("cstTokenName");
  }

  function setTokenName(address _storage, bytes32 tokenName) public {
    ExternalStorage(_storage).setBytes32Value("cstTokenName", tokenName);
  }

  function getTokenSymbol(address _storage) public view returns(bytes32) {
    return ExternalStorage(_storage).getBytes32Value("cstTokenSymbol");
  }

  function setTokenSymbol(address _storage, bytes32 tokenName) public {
    ExternalStorage(_storage).setBytes32Value("cstTokenSymbol", tokenName);
  }

  function getBuyPrice(address _storage) public view returns(uint256) {
    return ExternalStorage(_storage).getUIntValue("cstBuyPrice");
  }

  function setBuyPrice(address _storage, uint256 value) public {
    ExternalStorage(_storage).setUIntValue("cstBuyPrice", value);
  }

  function getCirculationCap(address _storage) public view returns(uint256) {
    return ExternalStorage(_storage).getUIntValue("cstCirculationCap");
  }

  function setCirculationCap(address _storage, uint256 value) public {
    ExternalStorage(_storage).setUIntValue("cstCirculationCap", value);
  }

  function getBalanceLimit(address _storage) public view returns(uint256) {
    return ExternalStorage(_storage).getUIntValue("cstBalanceLimit");
  }

  function setBalanceLimit(address _storage, uint256 value) public {
    ExternalStorage(_storage).setUIntValue("cstBalanceLimit", value);
  }

  function getFoundation(address _storage) public view returns(address) {
    return ExternalStorage(_storage).getAddressValue("cstFoundation");
  }

  function setFoundation(address _storage, address value) public {
    ExternalStorage(_storage).setAddressValue("cstFoundation", value);
  }

  function getAllowance(address _storage, address account, address spender) public view returns (uint256) {
    return ExternalStorage(_storage).getMultiLedgerValue("cstAllowance", account, spender);
  }

  function setAllowance(address _storage, address account, address spender, uint256 allowance) public {
    ExternalStorage(_storage).setMultiLedgerValue("cstAllowance", account, spender, allowance);
  }

  function getCustomBuyerLimit(address _storage, address buyer) public view returns (uint256) {
    return ExternalStorage(_storage).getLedgerValue("cstCustomBuyerLimit", buyer);
  }

  function setCustomBuyerLimit(address _storage, address buyer, uint256 value) public {
    ExternalStorage(_storage).setLedgerValue("cstCustomBuyerLimit", buyer, value);
  }

  function getCustomBuyerForIndex(address _storage, uint256 index) public view returns (address) {
    return ExternalStorage(_storage).ledgerEntryForIndex(keccak256("cstCustomBuyerLimit"), index);
  }

  function getCustomBuyerMappingCount(address _storage) public view returns(uint256) {
    return ExternalStorage(_storage).getLedgerCount("cstCustomBuyerLimit");
  }

  function getApprovedBuyer(address _storage, address buyer) public view returns (bool) {
    return ExternalStorage(_storage).getBooleanMapValue("cstApprovedBuyer", buyer);
  }

  function setApprovedBuyer(address _storage, address buyer, bool value) public {
    ExternalStorage(_storage).setBooleanMapValue("cstApprovedBuyer", buyer, value);
  }

  function getApprovedBuyerForIndex(address _storage, uint256 index) public view returns (address) {
    return ExternalStorage(_storage).booleanMapEntryForIndex(keccak256("cstApprovedBuyer"), index);
  }

  function getApprovedBuyerMappingCount(address _storage) public view returns(uint256) {
    return ExternalStorage(_storage).getBooleanMapCount("cstApprovedBuyer");
  }

  function getTotalUnvestedAndUnreleasedTokens(address _storage) public view returns(uint256) {
    return ExternalStorage(_storage).getUIntValue("cstUnvestedAndUnreleasedTokens");
  }

  function setTotalUnvestedAndUnreleasedTokens(address _storage, uint256 value) public {
    ExternalStorage(_storage).setUIntValue("cstUnvestedAndUnreleasedTokens", value);
  }

  function vestingMappingSize(address _storage) public view returns(uint256) {
    return ExternalStorage(_storage).getLedgerCount("cstFullyVestedAmount");
  }

  function vestingBeneficiaryForIndex(address _storage, uint256 index) public view returns(address) {
    return ExternalStorage(_storage).ledgerEntryForIndex(keccak256("cstFullyVestedAmount"), index);
  }

  function releasableAmount(address _storage, address beneficiary) public view returns (uint256) {
    uint256 releasedAmount = getVestingReleasedAmount(_storage, beneficiary);
    return vestedAvailableAmount(_storage, beneficiary).sub(releasedAmount);
  }

  function vestedAvailableAmount(address _storage, address beneficiary) public view returns (uint256) {
    uint256 start = getVestingStart(_storage, beneficiary);
    uint256 fullyVestedAmount = getFullyVestedAmount(_storage, beneficiary);

    if (start == 0 || fullyVestedAmount == 0) {
      return 0;
    }

    uint256 duration = getVestingDuration(_storage, beneficiary);
    if (duration == 0) {
      return 0;
    }
    uint256 cliff = getVestingCliff(_storage, beneficiary);
    uint256 revokeDate = getVestingRevokeDate(_storage, beneficiary);

    if (block.timestamp < cliff || (revokeDate > 0 && revokeDate <= cliff)) {
      return 0;
    } else if (revokeDate > 0 && revokeDate > cliff) {
      return fullyVestedAmount.mul(revokeDate.sub(start)).div(duration);
    } else if (block.timestamp >= start.add(duration)) {
      return fullyVestedAmount;
    } else {
      return fullyVestedAmount.mul(block.timestamp.sub(start)).div(duration);
    }
  }

  function vestedAmount(address _storage, address beneficiary) public view returns (uint256) {
    uint256 start = getVestingStart(_storage, beneficiary);
    uint256 fullyVestedAmount = getFullyVestedAmount(_storage, beneficiary);

    if (start == 0 || fullyVestedAmount == 0) {
      return 0;
    }

    uint256 duration = getVestingDuration(_storage, beneficiary);
    if (duration == 0) {
      return 0;
    }

    uint256 revokeDate = getVestingRevokeDate(_storage, beneficiary);

    if (block.timestamp <= start) {
      return 0;
    } else if (revokeDate > 0) {
      return fullyVestedAmount.mul(revokeDate.sub(start)).div(duration);
    } else if (block.timestamp >= start.add(duration)) {
      return fullyVestedAmount;
    } else {
      return fullyVestedAmount.mul(block.timestamp.sub(start)).div(duration);
    }
  }

  function canGrantVestedTokens(address _storage, address beneficiary) public view returns (bool) {
    uint256 existingFullyVestedAmount = getFullyVestedAmount(_storage, beneficiary);
    if (existingFullyVestedAmount == 0) {
      return true;
    }

    uint256 existingVestedAmount = vestedAvailableAmount(_storage, beneficiary);
    uint256 existingReleasedAmount = getVestingReleasedAmount(_storage, beneficiary);
    uint256 revokeDate = getVestingRevokeDate(_storage, beneficiary);

    if (revokeDate > 0 ||
        (existingVestedAmount == existingFullyVestedAmount &&
        existingReleasedAmount == existingFullyVestedAmount)) {
      return true;
    }

    return false;
  }

  function canRevokeVesting(address _storage, address beneficiary) public view returns (bool) {
    bool isRevocable = getVestingRevocable(_storage, beneficiary);
    uint256 revokeDate = getVestingRevokeDate(_storage, beneficiary);
    uint256 start = getVestingStart(_storage, beneficiary);
    uint256 duration = getVestingDuration(_storage, beneficiary);

    return start > 0 &&
           isRevocable &&
           revokeDate == 0 &&
           block.timestamp < start.add(duration);
  }

  function revokeVesting(address _storage, address beneficiary) public {
    require(canRevokeVesting(_storage, beneficiary));

    uint256 totalUnvestedAndUnreleasedAmount = getTotalUnvestedAndUnreleasedTokens(_storage);
    uint256 unvestedAmount = getFullyVestedAmount(_storage, beneficiary).sub(vestedAvailableAmount(_storage, beneficiary));

    setVestingRevokeDate(_storage, beneficiary, block.timestamp);
    setTotalUnvestedAndUnreleasedTokens(_storage, totalUnvestedAndUnreleasedAmount.sub(unvestedAmount));
  }

  function getVestingSchedule(address _storage, address _beneficiary) public
                                                                      view returns (uint256 startDate,
                                                                                        uint256 cliffDate,
                                                                                        uint256 durationSec,
                                                                                        uint256 fullyVestedAmount,
                                                                                        uint256 releasedAmount,
                                                                                        uint256 revokeDate,
                                                                                        bool isRevocable) {
    startDate         = getVestingStart(_storage, _beneficiary);
    cliffDate         = getVestingCliff(_storage, _beneficiary);
    durationSec       = getVestingDuration(_storage, _beneficiary);
    fullyVestedAmount = getFullyVestedAmount(_storage, _beneficiary);
    releasedAmount    = getVestingReleasedAmount(_storage, _beneficiary);
    revokeDate        = getVestingRevokeDate(_storage, _beneficiary);
    isRevocable       = getVestingRevocable(_storage, _beneficiary);
  }

  function setVestingSchedule(address _storage,
                              address beneficiary,
                              uint256 fullyVestedAmount,
                              uint256 startDate,
                              uint256 cliffDate,
                              uint256 duration,
                              bool isRevocable) public {
    require(canGrantVestedTokens(_storage, beneficiary));

    uint256 totalUnvestedAndUnreleasedAmount = getTotalUnvestedAndUnreleasedTokens(_storage);
    setTotalUnvestedAndUnreleasedTokens(_storage, totalUnvestedAndUnreleasedAmount.add(fullyVestedAmount));

    ExternalStorage(_storage).setLedgerValue("cstVestingStart", beneficiary, startDate);
    ExternalStorage(_storage).setLedgerValue("cstVestingCliff", beneficiary, cliffDate);
    ExternalStorage(_storage).setLedgerValue("cstVestingDuration", beneficiary, duration);
    ExternalStorage(_storage).setLedgerValue("cstFullyVestedAmount", beneficiary, fullyVestedAmount);
    ExternalStorage(_storage).setBooleanMapValue("cstVestingRevocable", beneficiary, isRevocable);

    setVestingRevokeDate(_storage, beneficiary, 0);
    setVestingReleasedAmount(_storage, beneficiary, 0);
  }

  function releaseVestedTokens(address _storage, address beneficiary) public {
    uint256 unreleased = releasableAmount(_storage, beneficiary);
    uint256 releasedAmount = getVestingReleasedAmount(_storage, beneficiary);
    uint256 totalUnvestedAndUnreleasedAmount = getTotalUnvestedAndUnreleasedTokens(_storage);

    releasedAmount = releasedAmount.add(unreleased);
    setVestingReleasedAmount(_storage, beneficiary, releasedAmount);
    setTotalUnvestedAndUnreleasedTokens(_storage, totalUnvestedAndUnreleasedAmount.sub(unreleased));
  }

  function getVestingStart(address _storage, address beneficiary) public view returns(uint256) {
    return ExternalStorage(_storage).getLedgerValue("cstVestingStart", beneficiary);
  }

  function getVestingCliff(address _storage, address beneficiary) public view returns(uint256) {
    return ExternalStorage(_storage).getLedgerValue("cstVestingCliff", beneficiary);
  }

  function getVestingDuration(address _storage, address beneficiary) public view returns(uint256) {
    return ExternalStorage(_storage).getLedgerValue("cstVestingDuration", beneficiary);
  }

  function getFullyVestedAmount(address _storage, address beneficiary) public view returns(uint256) {
    return ExternalStorage(_storage).getLedgerValue("cstFullyVestedAmount", beneficiary);
  }

  function getVestingRevocable(address _storage, address beneficiary) public view returns(bool) {
    return ExternalStorage(_storage).getBooleanMapValue("cstVestingRevocable", beneficiary);
  }

  function setVestingReleasedAmount(address _storage, address beneficiary, uint256 value) public {
    ExternalStorage(_storage).setLedgerValue("cstVestingReleasedAmount", beneficiary, value);
  }

  function getVestingReleasedAmount(address _storage, address beneficiary) public view returns(uint256) {
    return ExternalStorage(_storage).getLedgerValue("cstVestingReleasedAmount", beneficiary);
  }

  function setVestingRevokeDate(address _storage, address beneficiary, uint256 value) public {
    ExternalStorage(_storage).setLedgerValue("cstVestingRevokeDate", beneficiary, value);
  }

  function getVestingRevokeDate(address _storage, address beneficiary) public view returns(uint256) {
    return ExternalStorage(_storage).getLedgerValue("cstVestingRevokeDate", beneficiary);
  }

  function getRewardsContractHash(address _storage) public view returns (bytes32) {
    return ExternalStorage(_storage).getBytes32Value("cstRewardsContractHash");
  }

  function setRewardsContractHash(address _storage, bytes32 rewardsContractHash) public {
    ExternalStorage(_storage).setBytes32Value("cstRewardsContractHash", rewardsContractHash);
  }

}
// File: contracts/Freezable.sol



pragma solidity ^0.8.0;



contract Freezable is Administratable {
  using SafeMath for uint256;

  bool public frozenToken;
  address[] public frozenAccountForIndex;
  mapping (address => bool) public frozenAccount;
  mapping (address => bool) private processedAccount;

  event FrozenFunds(address indexed target, bool frozen);
  event FrozenToken(bool frozen);

  modifier unlessFrozen {
    require(!frozenToken, "the token is currently frozen");
    require(!frozenAccount[msg.sender], "Your token(s) have been forzen");
    _;
  }

  function freezeAccount(address target, bool freeze) public onlySuperAdmins {
    frozenAccount[target] = freeze;
    if (!processedAccount[target]) {
      frozenAccountForIndex.push(target);
      processedAccount[target] = true;
    }
    emit FrozenFunds(target, freeze);
  }

  function freezeToken(bool freeze) public onlySuperAdmins {
    frozenToken = freeze;
    emit FrozenToken(frozenToken);
  }

  function totalFrozenAccountsMapping() public view returns(uint256) {
    return frozenAccountForIndex.length;
  }

}
// File: contracts/Registry.sol



pragma solidity ^0.8.0;









contract Registry is Administratable {
  using SafeMath for uint256;

  /* BEGIN VARIABLES */
  mapping(bytes32 => address) public storageForHash;
  mapping(bytes32 => address) public contractForHash;
  mapping(bytes32 => bytes32) public hashForNamehash;
  mapping(bytes32 => bytes32) public namehashForHash;
  string[] public contractNameForIndex;
  /* END VARIABLES */

  event ContractRegistered(address indexed _contract, string _name, bytes32 namehash);
  event StorageAdded(address indexed storageAddress, string name);
  event StorageRemoved(address indexed storageAddress, string name);
  event AddrChanged(bytes32 indexed node, address a);

  function setNamehash(string memory contractName, bytes32 namehash) external onlySuperAdmins returns (bool) {
    require(namehash != 0x0, "namehash can not be empty");

    bytes32 hash = keccak256(abi.encodePacked(contractName));
    address contractAddress = contractForHash[hash];

    require(contractAddress != address(0x0), "the burn address is not a valid input for contract address");
    require(hashForNamehash[namehash] == 0x0, "namehash have been used");

    hashForNamehash[namehash] = hash;
    namehashForHash[hash] = namehash;

    emit AddrChanged(namehash, contractAddress);

    return true;
  }

  function register(string memory name, address contractAddress, bytes32 namehash) external onlySuperAdmins returns (bool) {
    bytes32 hash = keccak256(abi.encodePacked(name));
    require(bytes(name).length > 0, "name can not be empty");
    require(contractAddress != address(0x0), "the burn address is not a valid input for contract address");
    require(contractForHash[hash] == address(0x0), "This contract address have been registered");
    require(hashForNamehash[namehash] == 0x0, "namehash have been used");

    contractNameForIndex.push(name);
    contractForHash[hash] = contractAddress;

    if (namehash != 0x0) {
      hashForNamehash[namehash] = hash;
      namehashForHash[hash] = namehash;
    }

    address storageAddress = storageForHash[IStorable(contractAddress).getStorageNameHash()];
    address ledgerAddress = storageForHash[IStorable(contractAddress).getLedgerNameHash()];

    if (storageAddress != address(0x0)) {
      ExternalStorage(storageAddress).addAdmin(contractAddress);
    }
    if (ledgerAddress != address(0x0)) {
      GCoinLedger(ledgerAddress).addAdmin(contractAddress);
    }

    Configurable(contractAddress).configureFromStorage();

    emit ContractRegistered(contractAddress, name, namehash);

    if (namehash != 0x0) {
      emit AddrChanged(namehash, contractAddress);
    }

    return true;
  }

  function addStorage(string memory name, address storageAddress) external onlySuperAdmins {
    require(storageAddress != address(0), "the burn address is not a valid input for storage address");
    bytes32 hash = keccak256(abi.encodePacked(name));
    storageForHash[hash] = storageAddress;

    emit StorageAdded(storageAddress, name);
  }

  function removeStorage(string memory name) public onlySuperAdmins {
    bytes32 hash = keccak256(abi.encodePacked(name));
    address storageAddress = storageForHash[hash];
    delete storageForHash[hash];

    emit StorageRemoved(storageAddress, name);
  }

  function getStorage(string memory name) public view returns (address) {
    return storageForHash[keccak256(abi.encodePacked(name))];
  }

  function addr(bytes32 node) public view returns (address) {
    return contractForHash[hashForNamehash[node]];
  }

  function numContracts() public view returns(uint256) {
    return contractNameForIndex.length;
  }

  function getContractHash(string memory name) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(name));
  }
}
// File: contracts/GCoin.sol



pragma solidity ^0.8.0;













contract GCoin is ERC20,
                  Freezable,
                  Displayable,
                  Configurable,
                  IStorable {

  using SafeMath for uint256;
  using CstLibrary for address;

  /* BEGIN VARIABLES */
  uint256 public constant TOKEN_MAX_CAP = 150_000_000*1e18; // 150 million * 10^18

  ITokenLedger public tokenLedger;
  string public storageName;
  string public ledgerName;
  address public externalStorage;
  address public registry;
  bool public haltPurchase;
  uint256 public contributionMinimum;
  /* END VARIABLES */

  event Mint(uint256 amountMinted);
  event WhiteList(address indexed buyer, uint256 holdCap);
  event RemoveWhitelistedBuyer(address indexed buyer);
  event ConfigChanged(uint256 buyPrice, uint256 circulationCap, uint256 balanceLimit);
  event VestedTokenGrant(address indexed beneficiary, uint256 startDate, uint256 cliffDate, uint256 durationSec, uint256 fullyVestedAmount, bool isRevocable);
  event VestedTokenRevocation(address indexed beneficiary);
  event VestedTokenRelease(address indexed beneficiary, uint256 amount);
  event StorageUpdated(address storageAddress, address ledgerAddress);
  event FoundationDeposit(uint256 amount);
  event FoundationWithdraw(uint256 amount);
  event PurchaseHalted();
  event PurchaseResumed();

  modifier onlyFoundation {
    address foundation = externalStorage.getFoundation();
    require(foundation != address(0));
    require(msg.sender != owner() && msg.sender != foundation);
    _;
  }

  modifier initStorage {
    address ledgerAddress = Registry(registry).getStorage(ledgerName);
    address storageAddress = Registry(registry).getStorage(storageName);

    tokenLedger = ITokenLedger(ledgerAddress);
    externalStorage = storageAddress;
    _;
  }

  function initialize(address _registry, string memory _storageName, string memory _ledgerName) public onlySuperAdmins {
    _initialize(_registry, _storageName, _ledgerName);
  }

  function _initialize(address _registry, string memory _storageName, string memory _ledgerName) internal {
    require(_registry != address(0));
    require(registry == address(0));

    storageName = _storageName;
    ledgerName = _ledgerName;
    registry = _registry;

    addSuperAdmin(registry);

    emit Transfer(address(0), address(this), 0); // create ERC-20 signature for etherscan.io
  }

  function configure(bytes32 _tokenName,
                     bytes32 _tokenSymbol,
                     uint256 _buyPrice,
                     uint256 _circulationCap,
                     uint256 _balanceLimit,
                     address _foundation) public onlySuperAdmins initStorage returns (bool) {

    uint256 __buyPrice = externalStorage.getBuyPrice();
    if (__buyPrice > 0 && __buyPrice != _buyPrice) {
      require(frozenToken);
    }

    externalStorage.setTokenName(_tokenName);
    externalStorage.setTokenSymbol(_tokenSymbol);
    externalStorage.setBuyPrice(_buyPrice);
    externalStorage.setCirculationCap(_circulationCap);
    externalStorage.setFoundation(_foundation);
    externalStorage.setBalanceLimit(_balanceLimit);

    emit ConfigChanged(_buyPrice, _circulationCap, _balanceLimit);

    return true;
  }

  function buy() external payable unlessFrozen returns (uint256) {
    require(!haltPurchase, "the buy function is currently paused");
    require(externalStorage.getApprovedBuyer(msg.sender));

    uint256 _buyPriceTokensPerWei = externalStorage.getBuyPrice();
    uint256 _circulationCap = externalStorage.getCirculationCap();
    require(msg.value > 0, "amount of matic sent must be greater than zero");
    require(_buyPriceTokensPerWei > 0, "the price of the token must be set up");
    require(_circulationCap > 0, "the circulation cap of the token must be set up");

    uint256 amount = msg.value.mul(_buyPriceTokensPerWei);
    require(totalInCirculation().add(amount) <= _circulationCap, "You purchase will exceed the circulation cap of the token");
    require(amount <= tokensAvailable(), "You are trying to purchase more than the available tokens");

    uint256 balanceLimit;
    uint256 buyerBalance = tokenLedger.balanceOf(msg.sender);
    uint256 customLimit = externalStorage.getCustomBuyerLimit(msg.sender);
    require(contributionMinimum == 0 || buyerBalance.add(amount) >= contributionMinimum, "You are trying to purchase too few tokens");

    if (customLimit > 0) {
      balanceLimit = customLimit;
    } else {
      balanceLimit = externalStorage.getBalanceLimit();
    }

    require(balanceLimit > 0 && balanceLimit >= buyerBalance.add(amount), "You are trying to purchase more than your allocation");

    tokenLedger.debitAccount(msg.sender, amount);
    emit Transfer(address(this), msg.sender, amount);

    return amount;
  }

  function getLedgerNameHash() external override view returns (bytes32) {
    return keccak256(abi.encodePacked(ledgerName));
  }

  function getStorageNameHash() external override view returns (bytes32) {
    return keccak256(abi.encodePacked(storageName));
  }

  function configureFromStorage() public override onlySuperAdmins returns (bool) {
    address ledgerAddress = Registry(registry).getStorage(ledgerName);
    address storageAddress = Registry(registry).getStorage(storageName);

    tokenLedger = ITokenLedger(ledgerAddress);
    externalStorage = storageAddress;
    return true;
  }

  function updateStorage(string memory newStorageName, string memory newLedgerName) public onlySuperAdmins returns (bool) {
    require(frozenToken);

    storageName = newStorageName;
    ledgerName = newLedgerName;

    address ledgerAddress = Registry(registry).getStorage(ledgerName);
    address storageAddress = Registry(registry).getStorage(storageName);
    
    tokenLedger = ITokenLedger(ledgerAddress);
    externalStorage = storageAddress;
    emit StorageUpdated(storageAddress, ledgerAddress);
    return true;
  }

  function transfer(address recipient, uint256 amount) public override unlessFrozen returns (bool) {
    require(!frozenAccount[recipient]);

    tokenLedger.transfer(msg.sender, recipient, amount);
    emit Transfer(msg.sender, recipient, amount);

    return true;
  }

  function burn(uint256 amount) public override unlessFrozen returns (bool) {
      uint256 accountBalance = tokenLedger.balanceOf(msg.sender);
      require(accountBalance >= amount);
      tokenLedger.transfer(msg.sender, address(0), amount);
      emit Transfer(msg.sender, address(0), amount);
      return true;
  }

  function mintTokens(uint256 mintedAmount) public onlySuperAdmins returns (bool) {
    require(mintedAmount.add(totalSupply()) <= TOKEN_MAX_CAP);
    require(mintedAmount > 0);

    tokenLedger.mintTokens(mintedAmount);

    emit Mint(mintedAmount);
    emit Transfer(address(0), address(this), mintedAmount);

    return true;
  }

  function grantTokens(address recipient, uint256 amount) public onlySuperAdmins returns (bool) {
    require(haltPurchase);
    require(!frozenAccount[recipient]);

    uint256 _circulationCap = externalStorage.getCirculationCap();
    require(totalInCirculation().add(amount) <= _circulationCap);
    // assert the granted tokens doesnt exceed the totalSupply minus the fully vested amount of vesting tokens
    require(amount <= tokensAvailable());

    tokenLedger.debitAccount(recipient, amount);
    emit Transfer(address(this), recipient, amount);

    return true;
  }

  function setHaltPurchase(bool _haltPurchase) public onlySuperAdmins returns (bool) {
    haltPurchase = _haltPurchase;

    if (_haltPurchase) {
      emit PurchaseHalted();
    } else {
      emit PurchaseResumed();
    }
    return true;
  }

  // intentionally allowing this to work when token is frozen as foundation is a form of a super admin
  function foundationWithdraw(uint256 amount) public onlyFoundation returns (bool) {
    Address.sendValue(payable(msg.sender), amount);

    emit FoundationWithdraw(amount);
    return true;
  }

  function foundationDeposit() public payable unlessFrozen returns (bool) {
    emit FoundationDeposit(msg.value);

    return true;
  }

  function transferFrom(address from, address to, uint256 value) public override unlessFrozen returns (bool) {
    require(!frozenAccount[from], "You account have been forzen");
    require(!frozenAccount[to], "The address you are trying to send to is forzen");
    require(from != msg.sender, "You can only transfer from your current wallet");

    uint256 allowanceValue = allowance(from, msg.sender);
    require(allowanceValue >= value, "The value you are trying to transfer is greater than your allowance");

    tokenLedger.transfer(from, to, value);
    externalStorage.setAllowance(from, msg.sender, allowanceValue.sub(value));

    emit Transfer(from, to, value);
    return true;
  }

  /* Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   *
   * Please use `increaseApproval` or `decreaseApproval` instead.
   */
  function approve(address spender, uint256 value) public override unlessFrozen returns (bool) {
    return _approve(spender, value);
  }

  function increaseApproval(address spender, uint256 addedValue) public unlessFrozen returns (bool) {
    return _approve(spender, externalStorage.getAllowance(msg.sender, spender).add(addedValue));
  }

  function decreaseApproval(address spender, uint256 subtractedValue) public unlessFrozen returns (bool) {
    uint256 oldValue = externalStorage.getAllowance(msg.sender, spender);

    if (subtractedValue > oldValue) {
      return _approve(spender, 0);
    } else {
      return _approve(spender, oldValue.sub(subtractedValue));
    }
  }

  function grantVestedTokens(address beneficiary,
                             uint256 fullyVestedAmount,
                             uint256 startDate, // 0 indicates start "now"
                             uint256 cliffSec,
                             uint256 durationSec,
                             bool isRevocable) public onlySuperAdmins returns(bool) {

    uint256 _circulationCap = externalStorage.getCirculationCap();

    require(beneficiary != address(0));
    require(!frozenAccount[beneficiary]);
    require(durationSec >= cliffSec);
    require(totalInCirculation().add(fullyVestedAmount) <= _circulationCap);
    require(fullyVestedAmount <= tokensAvailable());

    uint256 _startDate = startDate;
    if (_startDate == 0) {
      _startDate = block.timestamp;
    }

    uint256 cliffDate = _startDate.add(cliffSec);

    externalStorage.setVestingSchedule(beneficiary,
                                       fullyVestedAmount,
                                       _startDate,
                                       cliffDate,
                                       durationSec,
                                       isRevocable);

    emit VestedTokenGrant(beneficiary, _startDate, cliffDate, durationSec, fullyVestedAmount, isRevocable);

    return true;
  }

  function revokeVesting(address beneficiary) public onlySuperAdmins returns (bool) {
    require(beneficiary != address(0));
    externalStorage.revokeVesting(beneficiary);

    emit VestedTokenRevocation(beneficiary);

    return true;
  }

  function releaseVestedTokens() public unlessFrozen returns (bool) {
    return releaseVestedTokensForBeneficiary(msg.sender);
  }

  function releaseVestedTokensForBeneficiary(address beneficiary) public unlessFrozen returns (bool) {
    require(beneficiary != address(0));
    require(!frozenAccount[beneficiary]);

    uint256 unreleased = releasableAmount(beneficiary);

    if (unreleased == 0) { return true; }

    externalStorage.releaseVestedTokens(beneficiary);

    tokenLedger.debitAccount(beneficiary, unreleased);
    emit Transfer(address(this), beneficiary, unreleased);

    emit VestedTokenRelease(beneficiary, unreleased);

    return true;
  }

  function setCustomBuyer(address buyer, uint256 balanceLimit) public onlySuperAdmins returns (bool) {
    require(buyer != address(0));
    externalStorage.setCustomBuyerLimit(buyer, balanceLimit);
    addBuyer(buyer);

    return true;
  }

  function setContributionMinimum(uint256 _contributionMinimum) public onlySuperAdmins returns (bool) {
    contributionMinimum = _contributionMinimum;
    return true;
  }

  function addBuyer(address buyer) public onlySuperAdmins returns (bool) {
    require(buyer != address(0));
    externalStorage.setApprovedBuyer(buyer, true);

    uint256 balanceLimit = externalStorage.getCustomBuyerLimit(buyer);
    if (balanceLimit == 0) {
      balanceLimit = externalStorage.getBalanceLimit();
    }

    emit WhiteList(buyer, balanceLimit);

    return true;
  }

  function removeBuyer(address buyer) public onlySuperAdmins returns (bool) {
    require(buyer != address(0));
    externalStorage.setApprovedBuyer(buyer, false);

    emit RemoveWhitelistedBuyer(buyer);
    return true;
  }

  function name() public view returns(string memory) {
    return bytes32ToString(externalStorage.getTokenName());
  }

  function symbol() public view returns(string memory) {
    return bytes32ToString(externalStorage.getTokenSymbol());
  }

  function totalInCirculation() public view returns(uint256) {
    return tokenLedger.totalInCirculation().add(totalUnvestedAndUnreleasedTokens());
  }

  function gcoinbalanceLimit() public view returns(uint256) {
    return externalStorage.getBalanceLimit();
  }

  function buyPrice() public view returns(uint256) {
    return externalStorage.getBuyPrice();
  }

  function circulationCap() public view returns(uint256) {
    return externalStorage.getCirculationCap();
  }

  function totalSupply() public override view returns(uint256) {
    return tokenLedger.totalTokens();
  }

  function tokensAvailable() public view returns(uint256) {
    return totalSupply().sub(totalInCirculation());
  }

  function balanceOf(address account) public override view returns (uint256) {
    address thisAddress = address(this);
    if (thisAddress == account) {
      return tokensAvailable();
    } else {
      return tokenLedger.balanceOf(account);
    }
  }

  function allowance(address _caller, address _spender) public override view returns (uint256) {
    return externalStorage.getAllowance(_caller, _spender);
  }

  function releasableAmount(address beneficiary) public view returns (uint256) {
    return externalStorage.releasableAmount(beneficiary);
  }

  function totalUnvestedAndUnreleasedTokens() public view returns (uint256) {
    return externalStorage.getTotalUnvestedAndUnreleasedTokens();
  }

  function vestingMappingSize() public view returns (uint256) {
    return externalStorage.vestingMappingSize();
  }

  function vestingBeneficiaryForIndex(uint256 index) public view returns (address) {
    return externalStorage.vestingBeneficiaryForIndex(index);
  }

  function vestingSchedule(address _beneficiary) public
                                                 view returns (uint256 startDate,
                                                               uint256 cliffDate,
                                                               uint256 durationSec,
                                                               uint256 fullyVestedAmount,
                                                               uint256 vestedAmount,
                                                               uint256 vestedAvailableAmount,
                                                               uint256 releasedAmount,
                                                               uint256 revokeDate,
                                                               bool isRevocable) {
    (
      startDate,
      cliffDate,
      durationSec,
      fullyVestedAmount,
      releasedAmount,
      revokeDate,
      isRevocable
    ) =  externalStorage.getVestingSchedule(_beneficiary);

    vestedAmount = externalStorage.vestedAmount(_beneficiary);
    vestedAvailableAmount = externalStorage.vestedAvailableAmount(_beneficiary);
  }

  function totalCustomBuyersMapping() public view returns (uint256) {
    return externalStorage.getCustomBuyerMappingCount();
  }

  function customBuyerLimit(address buyer) public view returns (uint256) {
    return externalStorage.getCustomBuyerLimit(buyer);
  }

  function customBuyerForIndex(uint256 index) public view returns (address) {
    return externalStorage.getCustomBuyerForIndex(index);
  }

  function totalBuyersMapping() public view returns (uint256) {
    return externalStorage.getApprovedBuyerMappingCount();
  }

  function approvedBuyer(address buyer) public view returns (bool) {
    return externalStorage.getApprovedBuyer(buyer);
  }

  function approvedBuyerForIndex(uint256 index) public view returns (address) {
    return externalStorage.getApprovedBuyerForIndex(index);
  }

  function _approve(address spender, uint256 value) internal unlessFrozen returns(bool) {
    require(spender != address(0), "the burn address is not a valid input for this function");
    require(!frozenAccount[spender], "the address you are trying to approve for is forzen");
    require(msg.sender != spender, "you can only call this function for your current address");

    externalStorage.setAllowance(msg.sender, spender, value);

    emit Approval(msg.sender, spender, value);
    return true;
  }
}