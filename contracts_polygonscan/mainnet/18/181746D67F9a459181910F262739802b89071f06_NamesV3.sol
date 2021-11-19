// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./Base64.sol";

interface rarity_manifested {
    function getApproved(uint) external view returns (address);
    function ownerOf(uint) external view returns (address);
    function level(uint) external view returns (uint);
    function class(uint) external view returns (uint);
    function classes(uint id) external pure returns (string memory);
}

contract NamesV3 is Ownable {
  using SafeERC20 for IERC20;

  uint256 public next_name_id = 1;

  rarity_manifested immutable rm;
  
  IERC20 public buyToken;  
  uint256 public buyTokenPrice;
  // after finalized = true, buyToken and buyTokenPrice can't be updated by owner
  bool public finalized;

  mapping(uint256 => uint256) public summoner_to_name_id; // summoner => nameId
  mapping(uint256 => string) public names;  // nameId => name
  mapping(uint256 => uint256) public name_id_to_summoner; // nameId => summoner
  mapping(string => bool) private _is_name_claimed;

  event NameClaimed(address indexed owner, uint256 indexed summoner, string name, uint256 name_id);
  event NameUpdated(uint256 indexed name_id, string old_name, string new_name);

  constructor(
    rarity_manifested _rarity_manifested, 
    IERC20 _buyToken,
    uint256 _buyTokenPrice
  ) {
    rm = _rarity_manifested;
    buyToken = _buyToken;
    buyTokenPrice = _buyTokenPrice;
  }

  modifier checkFinalized {
    require(!finalized, "Finalized!");
    _;
  }

  // --- External Mutative Functions ---

  // @dev Claim a name for a summoner. User must have approved required buyToken
  function claim (string memory name, uint256 summoner) external returns (uint256 name_id) {
    require(_isApprovedOrOwner(summoner), '!owner');
    require(validate_name(name), 'invalid name');
    string memory lower_name = to_lower(name);
    require(!_is_name_claimed[lower_name], 'name taken');
    
    buyToken.safeTransferFrom(msg.sender, address(this), buyTokenPrice);

    name_id = next_name_id;
    next_name_id++;
    names[name_id] = name;
    _is_name_claimed[lower_name] = true;
    
    summoner_to_name_id[summoner] = name_id;
    name_id_to_summoner[name_id] = summoner;

    emit NameClaimed(msg.sender, summoner, name, name_id);
  }

  // @dev Change the capitalization (as it is unique).
  //      Can't change the name.
  function update_capitalization(uint256 name_id, string memory new_name) public {
    require(_isApprovedOrOwnerOfName(name_id), "!owner or approved name");
    require(validate_name(new_name), 'invalid name');
    string memory name = names[name_id];
    require(keccak256(abi.encodePacked(to_lower(name))) == keccak256(abi.encodePacked(to_lower(new_name))), 'name different');
    names[name_id] = new_name;
    emit NameUpdated(name_id, name, new_name);
  }

  // --- External View Functions ---

  function summoner_name(uint256 summoner) public view returns (string memory name){
    name = names[summoner_to_name_id[summoner]];
  }

  function is_name_claimed(string memory name) external view returns(bool is_claimed) {
    is_claimed = _is_name_claimed[to_lower(name)];
  }

  function tokenURI(uint256 name_id) public view returns (string memory output) {
    uint summoner = name_id_to_summoner[name_id];
    output = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';
    if (summoner > 0) {
        output = string(abi.encodePacked(output, "Level ", toString(rm.level(summoner)), ' ', rm.classes(rm.class(summoner)), '</text><text x="10" y="40" class="base">'));
    }
    output = string(abi.encodePacked(output, names[name_id], '</text></svg>'));
    output = string(abi.encodePacked('data:application/json;base64,', Base64.encode(bytes(string(abi.encodePacked('{"name": "', names[name_id], '", "description": "Rarity ERC721 names for summoners.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))))));
  }

  // --- Internal View functions ---

  // check if msg.sender has control over this summoner id
  function _isApprovedOrOwner(uint256 _summoner) internal view returns (bool) {
    return rm.getApproved(_summoner) == msg.sender || rm.ownerOf(_summoner) == msg.sender;
  }

  // check if msg.sender has control over this name id
  function _isApprovedOrOwnerOfName(uint256 _name_id) internal view returns (bool) {
    uint256 summonerId = name_id_to_summoner[_name_id];
    return _isApprovedOrOwner(summonerId);
  }

  // @dev Check if the name string is valid (Alphanumeric and spaces without leading or trailing space)
  function validate_name(string memory str) internal pure returns (bool){
    bytes memory b = bytes(str);
    if(b.length < 1) return false;
    if(b.length > 25) return false; // Cannot be longer than 25 characters
    if(b[0] == 0x20) return false; // Leading space
    if (b[b.length - 1] == 0x20) return false; // Trailing space

    bytes1 last_char = b[0];

    for (uint i; i<b.length; i++){
      bytes1 char = b[i];

      if (char == 0x20 && last_char == 0x20) return false; // Cannot contain continous spaces

      if (
        !(char >= 0x30 && char <= 0x39) && //9-0
        !(char >= 0x41 && char <= 0x5A) && //A-Z
        !(char >= 0x61 && char <= 0x7A) && //a-z
        !(char == 0x20) //space
      )
        return false;

      last_char = char;
    }

    return true;
  }

  // @dev Converts the string to lowercase
  function to_lower(string memory str) internal pure returns (string memory){
    bytes memory b_str = bytes(str);
    bytes memory b_lower = new bytes(b_str.length);
    for (uint i = 0; i < b_str.length; i++) {
        // Uppercase character
        if ((uint8(b_str[i]) >= 65) && (uint8(b_str[i]) <= 90)) {
            b_lower[i] = bytes1(uint8(b_str[i]) + 32);
        } else {
            b_lower[i] = b_str[i];
        }
    }
    return string(b_lower);
  }

  function toString(int value) internal pure returns (string memory) {
    string memory _string = '';
    if (value < 0) {
        _string = '-';
        value = value * -1;
    }
    return string(abi.encodePacked(_string, toString(uint(value))));
  }

  function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

    if (value == 0) {
        return "0";
    }
    uint256 temp = value;
    uint256 digits;
    while (temp != 0) {
        digits++;
        temp /= 10;
    }
    bytes memory buffer = new bytes(digits);
    while (value != 0) {
        digits -= 1;
        buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
        value /= 10;
    }
    return string(buffer);
  }

  // --- Admin functions ---
  
  function withdrawFunds(IERC20 token) external onlyOwner {
    uint256 tokenBalance = token.balanceOf(address(this));

    token.safeTransfer(msg.sender, tokenBalance);
  }

  function setBuyToken(IERC20 _buyToken) external onlyOwner checkFinalized {
    buyToken = _buyToken;
  }

  function setBuyTokenPrice(uint256 _buyTokenPrice) external onlyOwner checkFinalized {
    buyTokenPrice = _buyTokenPrice;
  }

  function setBuyTokenAndPrice(IERC20 _buyToken, uint256 _buyTokenPrice) external onlyOwner checkFinalized {
    buyToken = _buyToken;
    buyTokenPrice = _buyTokenPrice;
  }

  function finalizeBuyToken() external onlyOwner {
    finalized = true;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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
pragma solidity 0.8.7;

/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
  bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

  /// @notice Encodes some bytes to the base64 representation
  function encode(bytes memory data) internal pure returns (string memory) {
      uint256 len = data.length;
      if (len == 0) return "";

      // multiply by 4/3 rounded up
      uint256 encodedLen = 4 * ((len + 2) / 3);

      // Add some extra buffer at the end
      bytes memory result = new bytes(encodedLen + 32);

      bytes memory table = TABLE;

      assembly {
          let tablePtr := add(table, 1)
          let resultPtr := add(result, 32)

          for {
              let i := 0
          } lt(i, len) {

          } {
              i := add(i, 3)
              let input := and(mload(add(data, i)), 0xffffff)

              let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
              out := shl(8, out)
              out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
              out := shl(8, out)
              out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
              out := shl(8, out)
              out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
              out := shl(224, out)

              mstore(resultPtr, out)

              resultPtr := add(resultPtr, 4)
          }

          switch mod(len, 3)
          case 1 {
              mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
          }
          case 2 {
              mstore(sub(resultPtr, 1), shl(248, 0x3d))
          }

          mstore(result, encodedLen)
      }

      return string(result);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

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
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

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