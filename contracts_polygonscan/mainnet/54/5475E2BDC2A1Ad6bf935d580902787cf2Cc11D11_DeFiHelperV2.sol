/**
 *Submitted for verification at polygonscan.com on 2021-11-28
*/

/** 
 *  SourceUnit: /home/derek/projects/ATSLTD/fraktalFinancial/fraktal-defi/contracts/DeFiHelperV2.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

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
     * ////IMPORTANT: Beware that changing an allowance with this method brings the risk
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




/** 
 *  SourceUnit: /home/derek/projects/ATSLTD/fraktalFinancial/fraktal-defi/contracts/DeFiHelperV2.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: UNLICENSED

pragma solidity ^0.8.0;

////import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMyERC20 is IERC20 {
  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function decimals() external view returns (uint8);  
}




/** 
 *  SourceUnit: /home/derek/projects/ATSLTD/fraktalFinancial/fraktal-defi/contracts/DeFiHelperV2.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}




/** 
 *  SourceUnit: /home/derek/projects/ATSLTD/fraktalFinancial/fraktal-defi/contracts/DeFiHelperV2.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

////import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}




/** 
 *  SourceUnit: /home/derek/projects/ATSLTD/fraktalFinancial/fraktal-defi/contracts/DeFiHelperV2.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}




/** 
 *  SourceUnit: /home/derek/projects/ATSLTD/fraktalFinancial/fraktal-defi/contracts/DeFiHelperV2.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

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




/** 
 *  SourceUnit: /home/derek/projects/ATSLTD/fraktalFinancial/fraktal-defi/contracts/DeFiHelperV2.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}




/** 
 *  SourceUnit: /home/derek/projects/ATSLTD/fraktalFinancial/fraktal-defi/contracts/DeFiHelperV2.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: UNLICENSED
pragma solidity ^0.8;

////import "../interfaces/IMyERC20.sol";

library Utils {
  struct TokenInfo {
    string name;
    string symbol;
    address _address;
    uint decimals;
    uint totalSupply;
  }
  struct Token {
    address _address;
    TokenType _type;
    bool isBlacklisted;
  }


  struct Contract {
    string name;
    address _address;
    string[] categories;
  }

  struct User {
    address _address;
    uint startBlock;
  }
  enum TokenType {GENERIC, LP, CUSTOM}

 // ////import "@uniswap/lib/contracts/libraries/Babylonian.sol";
  function sqrt(uint y) internal pure returns (uint z) {
    if (y > 3) {
      z = y;
      uint x = y / 2 + 1;
      while (x < z) {
        z = x;
        x = (y / x + x) / 2;
      }
    } else if (y != 0) {
      z = 1;
    }
    // else z = 0 (default value)
  }

  address constant ZERO_ADDRESS = address(0);
  function calculateFee1000 (uint amount, uint pct) internal pure returns(uint) {
    uint fee = ((amount * pct) / (1000 - pct)) + 1;
    return fee;
  }

  function calculateFee10000 (uint amount, uint pct) internal pure returns(uint) {
    uint fee = ((amount * pct) / (10000 - pct)) + 1;
    return fee;
  }

  function feeFromBps (uint amount, uint points) internal pure returns(uint fee) {
    fee = (amount * points) / 10000;
  }
  function _toLower(string memory str) internal pure returns (string memory) {
    bytes memory bStr = bytes(str);
    bytes memory bLower = new bytes(bStr.length);
    for (uint i = 0; i < bStr.length; i++) {
      // Uppercase character...
      if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
          // So we add 32 to make it lowercase
        bLower[i] = bytes1(uint8(bStr[i]) + 32);
      } else {
          bLower[i] = bStr[i];
      }
    }
    return string(bLower);
  }
  function _toUpper(string memory str) internal pure returns (string memory) {
    bytes memory bStr = bytes(str);
    bytes memory bLower = new bytes(bStr.length);
    for (uint i = 0; i < bStr.length; i++) {
      // Uppercase character...
      if ((uint8(bStr[i]) >= 97) && (uint8(bStr[i]) <= 112)) {
          // So we add 32 to make it lowercase
        bLower[i] = bytes1(uint8(bStr[i]) - 32);
      } else {
          bLower[i] = bStr[i];
      }
    }
    return string(bLower);
  }

  function _stringCompare (string memory str0, string memory str1) internal pure returns(bool) {
    return keccak256(abi.encodePacked(str0)) == keccak256(abi.encodePacked(str1));
  }
  function _stringConcat (string memory str0, string memory str1) internal pure returns(string memory) {
    return string(abi.encodePacked(str0, str1));

  }
  function _stringToBytes32(string memory source) internal pure returns (bytes32 result) {
    // require(bytes(source).length <= 32); // causes error
    // but string have to be max 32 chars
    // https://ethereum.stackexchange.com/questions/9603/understanding-mload-assembly-function
    // http://solidity.readthedocs.io/en/latest/assembly.html
    assembly {
      result := mload(add(source, 32))
    }
  }//

  function toAsciiString(address x) internal pure returns (string memory) {
    bytes memory s = new bytes(40);
    for (uint i = 0; i < 20; i++) {
        bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
        bytes1 hi = bytes1(uint8(b) / 16);
        bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
        s[2*i] = char(hi);
        s[2*i+1] = char(lo);            
    }
    return string(s);
  }

  function char(bytes1 b) internal pure returns (bytes1 c) {
      if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
      else return bytes1(uint8(b) + 0x57);
  }
  function balanceOf (address _user) internal view returns(uint balance) {
    balance = address(_user).balance;
  }
  function balanceOf (address _user, address _token) internal view returns(uint balance) {
    balance = IMyERC20(_token).balanceOf(_user);
  }
  function _getTokenInfo (IMyERC20 _token) internal view returns(TokenInfo memory token) {
    token = TokenInfo(_token.name(), _token.symbol(), address(_token), _token.decimals(), _token.totalSupply());
    return token;
  }
  function getTokenInfo (IMyERC20[] memory _tokens) internal view returns(TokenInfo[] memory tokens) {
    uint tokensLen = _tokens.length;
    tokens = new TokenInfo[](tokensLen);
    IMyERC20 token;
    uint i;
    for (i = 0; i < tokensLen; i++) {
      token = _tokens[i];
      tokens[i] = TokenInfo(token.name(), token.symbol(), address(token), token.decimals(), token.totalSupply());
    }
  }
  function getMultiBalances (address[] memory _tokens) internal view returns(TokenInfo[] memory tokens, uint[] memory balances, uint ETH_BALANCE) {
    tokens = new TokenInfo[](_tokens.length);
    balances = new uint[](_tokens.length);
    address _user = msg.sender;
    for(uint i = 0; i < _tokens.length; i++) {
      tokens[i] = _getTokenInfo(IMyERC20(_tokens[i]));
      balances[i] = balanceOf(_user, _tokens[i]);
    }

    ETH_BALANCE = balanceOf(_user);
  }
  function getMultiBalances (address[] memory _tokens, address _user) internal view returns(
    TokenInfo[] memory tokens,
    uint[] memory balances,
    uint ETH_BALANCE
  ) {
    tokens = new TokenInfo[](_tokens.length);
    balances = new uint[](_tokens.length);

    for(uint i = 0; i < _tokens.length; i++) {
      tokens[i] = _getTokenInfo(IMyERC20(_tokens[i]));
      balances[i] = balanceOf(_user, _tokens[i]);
    }

    ETH_BALANCE = balanceOf(_user);
  }
}



/** 
 *  SourceUnit: /home/derek/projects/ATSLTD/fraktalFinancial/fraktal-defi/contracts/DeFiHelperV2.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: UNLICENSED
pragma solidity ^0.8.4;


/**
 * @dev Interface of the ERC2612 standard as defined in the EIP.
 *
 * Adds the {permit} method, which can be used to change one's
 * {IERC20-allowance} without having to send a transaction, by signing a
 * message. This allows users to spend tokens without having to hold Ether.
 *
 * See https://eips.ethereum.org/EIPS/eip-2612.
 */

interface IERC3156FlashBorrower {

    /**
     * @dev Receive a flash loan.
     * @param initiator The initiator of the loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param fee The additional amount of tokens to repay.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     * @return The keccak256 hash of "ERC3156FlashBorrower.onFlashLoan"
     */
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}

interface IERC2612 {
    /**
     * @dev Sets `value` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
     *
     * ////IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be `address(0)`.
     * - `spender` cannot be `address(0)`.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use `owner`'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    /**
     * @dev Returns the current ERC2612 nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases `owner`'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);
    
    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by EIP712.
     */
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}
// ////import "./IERC3156FlashBorrower.sol";


interface IERC3156FlashLender {

    /**
     * @dev The amount of currency available to be lended.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(
        address token
    ) external view returns (uint256);

    /**
     * @dev The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(
        address token,
        uint256 amount
    ) external view returns (uint256);

    /**
     * @dev Initiate a flash loan.
     * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     */
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}

// Copyright (C) 2015, 2016, 2017 Dapphub
// Adapted by Ethereum Community 2021

////import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
// ////import "./IERC2612.sol";
// ////import "./IERC3156FlashLender.sol";

/// @dev Wrapped Ether v10 (WETH10) is an Ether (ETH) ERC-20 wrapper. You can `deposit` ETH and obtain a WETH10 balance which can then be operated as an ERC-20 token. You can
/// `withdraw` ETH from WETH10, which will then burn WETH10 token in your wallet. The amount of WETH10 token in any wallet is always identical to the
/// balance of ETH deposited minus the ETH withdrawn with that specific wallet.
interface IWETH10 is IERC20, IERC2612, IERC3156FlashLender {

    /// @dev Returns current amount of flash-minted WETH10 token.
    function flashMinted() external view returns(uint256);

    /// @dev `msg.value` of ETH sent to this contract grants caller account a matching increase in WETH10 token balance.
    /// Emits {Transfer} event to reflect WETH10 token mint of `msg.value` from `address(0)` to caller account.
    function deposit() external payable;

    /// @dev `msg.value` of ETH sent to this contract grants `to` account a matching increase in WETH10 token balance.
    /// Emits {Transfer} event to reflect WETH10 token mint of `msg.value` from `address(0)` to `to` account.
    function depositTo(address to) external payable;

    /// @dev Burn `value` WETH10 token from caller account and withdraw matching ETH to the same.
    /// Emits {Transfer} event to reflect WETH10 token burn of `value` to `address(0)` from caller account. 
    /// Requirements:
    ///   - caller account must have at least `value` balance of WETH10 token.
    function withdraw(uint256 value) external;

    /// @dev Burn `value` WETH10 token from caller account and withdraw matching ETH to account (`to`).
    /// Emits {Transfer} event to reflect WETH10 token burn of `value` to `address(0)` from caller account.
    /// Requirements:
    ///   - caller account must have at least `value` balance of WETH10 token.
    function withdrawTo(address payable to, uint256 value) external;

    /// @dev Burn `value` WETH10 token from account (`from`) and withdraw matching ETH to account (`to`).
    /// Emits {Approval} event to reflect reduced allowance `value` for caller account to spend from account (`from`),
    /// unless allowance is set to `type(uint256).max`
    /// Emits {Transfer} event to reflect WETH10 token burn of `value` to `address(0)` from account (`from`).
    /// Requirements:
    ///   - `from` account must have at least `value` balance of WETH10 token.
    ///   - `from` account must have approved caller to spend at least `value` of WETH10 token, unless `from` and caller are the same account.
    function withdrawFrom(address from, address payable to, uint256 value) external;

    /// @dev `msg.value` of ETH sent to this contract grants `to` account a matching increase in WETH10 token balance,
    /// after which a call is executed to an ERC677-compliant contract with the `data` parameter.
    /// Emits {Transfer} event.
    /// Returns boolean value indicating whether operation succeeded.
    /// For more information on {transferAndCall} format, see https://github.com/ethereum/EIPs/issues/677.
    function depositToAndCall(address to, bytes calldata data) external payable returns (bool);

    /// @dev Sets `value` as allowance of `spender` account over caller account's WETH10 token,
    /// after which a call is executed to an ERC677-compliant contract with the `data` parameter.
    /// Emits {Approval} event.
    /// Returns boolean value indicating whether operation succeeded.
    /// For more information on {approveAndCall} format, see https://github.com/ethereum/EIPs/issues/677.
    function approveAndCall(address spender, uint256 value, bytes calldata data) external returns (bool);

    /// @dev Moves `value` WETH10 token from caller's account to account (`to`), 
    /// after which a call is executed to an ERC677-compliant contract with the `data` parameter.
    /// A transfer to `address(0)` triggers an ETH withdraw matching the sent WETH10 token in favor of caller.
    /// Emits {Transfer} event.
    /// Returns boolean value indicating whether operation succeeded.
    /// Requirements:
    ///   - caller account must have at least `value` WETH10 token.
    /// For more information on {transferAndCall} format, see https://github.com/ethereum/EIPs/issues/677.
    function transferAndCall(address to, uint value, bytes calldata data) external returns (bool);
}

interface IWETH is IWETH10 {}



/** 
 *  SourceUnit: /home/derek/projects/ATSLTD/fraktalFinancial/fraktal-defi/contracts/DeFiHelperV2.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

////import "./IAccessControl.sol";
////import "../utils/Context.sol";
////import "../utils/Strings.sol";
////import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}




/** 
 *  SourceUnit: /home/derek/projects/ATSLTD/fraktalFinancial/fraktal-defi/contracts/DeFiHelperV2.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

////import "../utils/Context.sol";

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




/** 
 *  SourceUnit: /home/derek/projects/ATSLTD/fraktalFinancial/fraktal-defi/contracts/DeFiHelperV2.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: UNLICENSED

pragma solidity ^0.8.4;

////import "@openzeppelin/contracts/access/Ownable.sol";
////import "@openzeppelin/contracts/access/AccessControl.sol";
////import "./interfaces/IWETH.sol";
////import "./libraries/Utils.sol";


contract DataStore is AccessControl, Ownable {
  event AddedContract(uint indexed id, string indexed name, address indexed _address, string[] catgories);
  event AddedCategory(uint indexed id, string indexed category);
  event AddedToken(address indexed _token, Utils.TokenType indexed _type, bool indexed isBlacklisted);
  event AddedUser (address user, uint startBlock);


  Utils.Contract[] public contracts;
  Utils.Token[] public tokens;
  Utils.User[] users;
  string[] public contractCategories;

  IWETH public WETH;
  constructor (address _weth) {
    WETH = IWETH(_weth);
  }

  function _hasContract (address _address) internal view returns(bool hasContract) {
    hasContract = false;
    uint contractsLen = contracts.length;
    uint i;

    if (contractsLen == 0) {
      return hasContract;
    }
    for (i = 0; i < contractsLen; i++) {
      if (contracts[i]._address == _address) {
        hasContract = true;
        return hasContract;

      }
    }
    return hasContract;

  }

  function getContract (uint _id) external view returns(Utils.Contract memory _contract) {
    return contracts[_id];
  }

  function addContract (string memory name, address _address, string[] memory categories) external {
    require(!Utils._stringCompare(name, ""), "Name field is empty");
    require(_address != Utils.ZERO_ADDRESS, "Attempting to add ZERO_ADDRESS");
    require(!_hasContract(_address), "Contract already exists");

    for (uint i = 0; i < categories.length; i++) {
      this.addCategory(categories[i]);
    }
    contracts.push(Utils.Contract(name, _address, categories));
    emit AddedContract(contracts.length, name, _address, categories);
  }

  function contractsLength () external view returns(uint256 count) {
    count = contracts.length;
    return count;
  }

  function _hasCategory (string memory category) internal view returns(bool hasCat) {
    hasCat = false;
    uint catLen = contractCategories.length;
    if (catLen == 0) {
      return hasCat;
    }
    for (uint i = 0; i < catLen; i++) {
      if (
        Utils._stringCompare(
          Utils._toLower(category),
          Utils._toLower(contractCategories[i])
        ) 
      ) {
        hasCat = true;
        return hasCat;
      }
    }
    return hasCat;
  }

  function addCategory (string memory category) external  {
    require(!Utils._stringCompare(category, ""), "Category field is empty");
    require(!_hasCategory(category), "Category already exists");
    contractCategories.push(category);
    emit AddedCategory(contractCategories.length, category);
  }
  
  function addToken (address _token, Utils.TokenType _type, bool isBlacklisted) external {
    require (!this.tokenExists(_token), 'Token Exists');
    tokens.push(Utils.Token(_token, _type, isBlacklisted));
    emit AddedToken(_token, _type, isBlacklisted);
  }
  function getTokenByAddress (address _address) external view returns(uint token) {
    uint tokenCount = tokens.length;
    if (tokenCount == 0) return token;
    uint i;
    for (i = 0; i < tokenCount; i++) {
      if (tokens[i]._address == _address) {
        token = i;
        return token;
      }
    }
    return token;
  }
  function tokenExists (address _address) external view returns(bool exists) {
    uint tokenCount = tokens.length;
    exists = false;
    if (tokenCount == 0) return exists;
    uint i;
    for (i = 0; i < tokenCount; i++) {
      if (tokens[i]._address == _address) {
        exists = true;
        return exists;
      }
    }
    return exists;
  }
  function tokensLength () external view returns(uint _tokensLength) {
    _tokensLength = tokens.length;
    return _tokensLength;
  }
  function blacklistToken (address _address) external {
    uint tokenId = this.getTokenByAddress(_address);
    tokens[tokenId].isBlacklisted = true;
  }
  function whitelistToken (address _address) external {
    uint tokenId = this.getTokenByAddress(_address);
    tokens[tokenId].isBlacklisted = false;

  }
  function _addUser(address user) internal returns(bool success) {
    
    if (this.userExists(user)) return success;
    users.push(Utils.User(user, block.number));
    emit AddedUser(user, block.number);
  }
  function addUser(address user) external returns(bool success) {
    return _addUser(user);
  }
  function userExists (address user) external view returns(bool exists) {
    uint usersCount = users.length;
    exists = false;
    if (usersCount == 0) return exists;
    uint i;
    for (i = 0; i < usersCount; i++) {
      if (users[i]._address == user) {
        exists = true;
        return exists;
      }
    }
    return exists;
  }

}



/** 
 *  SourceUnit: /home/derek/projects/ATSLTD/fraktalFinancial/fraktal-defi/contracts/DeFiHelperV2.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: UNLICENSED
pragma solidity ^0.8.0;

interface IUniswapV2Callee {
  function uniswapV2Call(
    address sender,
    uint256 amount0,
    uint256 amount1,
    bytes calldata data
  ) external;
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Router02 {
  function factory() external pure returns (address);
  function WETH() external pure returns (address);

  function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
  function getAmountsIn(uint amountOut, address[] memory path) external view returns (uint[] memory amounts);
  function addLiquidity(
    address tokenA,
    address tokenB,
    uint amountADesired,
    uint amountBDesired,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
  ) external returns (uint amountA, uint amountB, uint liquidity);
  function addLiquidityETH(
    address token,
    uint amountTokenDesired,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline
  ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint liquidity,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
  ) external returns (uint amountA, uint amountB);

  function removeLiquidityETH(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline
  ) external returns (uint amountToken, uint amountETH);

  function swapExactTokensForTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);
  function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

  function swapExactTokensForETH(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  )
    external
    returns (uint[] memory amounts);
}

interface IUniswapV2Factory  {

  function getPair(address tokenA, address tokenB) external view returns (address pair);
  function allPairs(uint) external view returns (address pair);
  function allPairsLength() external view returns (uint);

  function createPair(address tokenA, address tokenB) external returns (address pair);

}


/** 
 *  SourceUnit: /home/derek/projects/ATSLTD/fraktalFinancial/fraktal-defi/contracts/DeFiHelperV2.sol
*/

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: UNLICENSED
pragma solidity ^0.8;
pragma abicoder v2;

////import "./interfaces/IWETH.sol";
////import "./interfaces/IUniswapV2.sol";
////import "./libraries/Utils.sol";
// ////import "hardhat/console.sol";
////import "./DataStore.sol";


contract DeFiHelperV2 is DataStore {
  struct BestPrice {
    address _router;
    address _pairAddress;
    uint amountIn;
    uint amountOut;
  }

  struct TokenToLiquidityHelper {
    address _router;
    address[] _routers;
    address _to;
    address _baseToken;
    address _token0;
    address _token1;
    address[] _path;    
    uint _amtBaseToken;
    uint _bps;
    uint deadline;
    uint[] _t0Amounts;
    uint[] _t1Amounts;
    uint tradeAmount;
  }

  struct LiquidityHelper {
    address _router;
    address _token0;
    address _token1;
    uint _amount0;
    uint _amount1;
    uint _amount0Min;
    uint _amount1Min;
    address _to;
    uint deadline;

  }

  constructor (address _weth) DataStore(_weth) {
    WETH = IWETH(_weth);
  }
  receive () external payable {}
  fallback () external payable {}
  function getPairAddress (address _router, address _token0, address _token1) 
  external view returns (address pairAddress) {
    pairAddress = IUniswapV2Factory(IUniswapV2Router02(_router).factory()).getPair(_token0, _token1);
  }

  function _getBestPrice (
    address[] memory _routers,
    address _tokenIn,
    address _tokenOut,
    uint amount
  ) internal view returns(BestPrice[] memory prices){
    // console.log("func: getBestPrice");
    uint numRouters = _routers.length;
    uint i = 0;
    prices = new BestPrice[](numRouters);
    address[] memory path = new address[](2);

    path[0] = _tokenIn;
    path[1] = _tokenOut;

    for (i = 0; i < numRouters; i++) {
      address _pairAddress = this.getPairAddress(_routers[i], _tokenIn, _tokenOut);

      if (_pairAddress == address(0)) {

        prices[i] = BestPrice(_routers[i], _pairAddress,  0, 0);
      } else {

        uint[] memory amounts = IUniswapV2Router02(_routers[i]).getAmountsOut(amount, path);
        prices[i] = BestPrice(_routers[i], _pairAddress,  amounts[0], amounts[1]);
      }
      
    }
  }

  function _getRouters () internal view returns (Utils.Contract[] memory _routers) {
    uint i = 0;
    uint contractCount = contracts.length;
    uint numRouters;
    for (i; i < contractCount; i++) {
      // Utils.Contract = contracts[i];
      string[] memory categories = contracts[i].categories;
      uint catLen = categories.length;
      uint c = 0;
      for (c; c < catLen; c++) {
        if (Utils._stringCompare(
          Utils._toLower('router'),
          Utils._toLower(categories[c])
        )) numRouters++;
      }
    }
    _routers = new Utils.Contract[](numRouters);

    for (i; i < contractCount; i++) {
      // Utils.Contract = contracts[i];
      string[] memory categories = contracts[i].categories;
      uint catLen = categories.length;
      uint c = 0;
      for (c; c < catLen; c++) {
        if (Utils._stringCompare(
          Utils._toLower('router'),
          Utils._toLower(categories[c])
        )) _routers[i] = contracts[i];
      }
    }
  }
  function _getContractAddresses (Utils.Contract[] memory _contracts) internal view returns (address[] memory _addresses) {
    uint contractLen = _contracts.length;
    uint i = 0;
    _addresses = new address[](contractLen);

    for (i; i < contractLen; i++) {
      _addresses[i] = contracts[i]._address;
    }
  }

  function getBestPrice (
    address _tokenIn,
    address _tokenOut,
    uint amount
  ) external view returns(BestPrice[] memory prices){
    Utils.Contract[] memory routerContracts = _getRouters();
    address[] memory _routers = _getContractAddresses(routerContracts);
    prices = _getBestPrice (
      _routers,
      _tokenIn,
      _tokenOut,
      amount
    );
  }
  function getBestPrice (
    address[] memory _routers,
    address _tokenIn,
    address _tokenOut,
    uint amount
  ) external view returns(BestPrice[] memory prices){
    prices = _getBestPrice (
      _routers,
      _tokenIn,
      _tokenOut,
      amount
    );
  }
  function tokenToLiquidity (
    TokenToLiquidityHelper memory _lpHelper

  ) external payable returns(uint amount0, uint amount1, uint liquidity){
    _lpHelper.tradeAmount = _lpHelper._amtBaseToken / 2;

    require(_lpHelper._token0 != _lpHelper._token1, "LIQUIDTY_ERROR::DUPLICATE_TOKENS");
    // If the _baseToken is ETH (chain token), deposit to WETH
    if (_lpHelper._baseToken == Utils.ZERO_ADDRESS) {
      require(msg.value >= _lpHelper._amtBaseToken, "INSUFFICIENT ETH AMOUNT");
      _lpHelper._baseToken = address(WETH);
      WETH.deposit{value: _lpHelper._amtBaseToken}();
    }
    
    
      _lpHelper._path[0] = _lpHelper._baseToken;
      _lpHelper._path[1] = _lpHelper._token0;
      {
        _lpHelper._t0Amounts = this.swap(_lpHelper._routers, _lpHelper.tradeAmount, _lpHelper._bps, _lpHelper._path, address(this), _lpHelper.deadline);
      }
      _lpHelper._path[1] = _lpHelper. _token1;
      {
        _lpHelper._t1Amounts = this.swap(_lpHelper._routers, _lpHelper.tradeAmount, _lpHelper._bps, _lpHelper._path, address(this), _lpHelper.deadline);
      }
      IERC20(_lpHelper._token0).approve(_lpHelper._router, _lpHelper._t0Amounts[1]);
      IERC20(_lpHelper._token1).approve(_lpHelper._router, _lpHelper._t1Amounts[1]);
    
    {

        (uint _amount0, uint _amount1, uint _liquidity) = addLiquidity (
          LiquidityHelper(
            _lpHelper._router,
            _lpHelper._token0,
            _lpHelper._token1,
            _lpHelper._t0Amounts[0],
            _lpHelper._t1Amounts[0],
            0,
            0,
            _lpHelper._to,
            _lpHelper.deadline
          )
        ); 
        amount0 = _amount0;
        amount1 = _amount1;
        liquidity = _liquidity;

    }
  }

  function _addLiquidity (
    LiquidityHelper memory _lpHelper
  ) internal returns (uint amount0, uint amount1, uint liquidity) {


    (uint _amount0, uint _amount1, uint _liquidity) = IUniswapV2Router02(_lpHelper._router).addLiquidity(
      _lpHelper._token0,
      _lpHelper._token1,
      _lpHelper._amount0,
      _lpHelper._amount1,
      _lpHelper._amount0Min,
      _lpHelper._amount1Min,
      _lpHelper._to,
      _lpHelper.deadline
    );
    amount0 = _amount0;
    amount1 = _amount1;
    liquidity = _liquidity;
  }

  function addLiquidity (
    LiquidityHelper memory _lpHelper
  ) public payable returns (uint amount0, uint amount1, uint liquidity) {

    require(_lpHelper._token0 != _lpHelper._token1, "SWAP_ERROR::DUPLICATE_TOKENS");
    if (_lpHelper._token0 == Utils.ZERO_ADDRESS) {
      require(msg.value >= _lpHelper._amount0, "INSUFFICIENT ETH AMOUNT");
      _lpHelper._token0 = address(WETH);
      WETH.deposit{value: _lpHelper._amount0}();
    } else {
      if (msg.sender == address(this)) IERC20(_lpHelper._token0).transferFrom(msg.sender, address(this), _lpHelper._amount0);
    }
    if (_lpHelper._token1 == Utils.ZERO_ADDRESS) {
      require(msg.value >= _lpHelper._amount1, "INSUFFICIENT ETH AMOUNT");
      _lpHelper._token1 = address(WETH);
      WETH.deposit{value: _lpHelper._amount1}();
    } else {
      if (msg.sender == address(this)) IERC20(_lpHelper._token1).transferFrom(msg.sender, address(this), _lpHelper._amount1);
    }
    {

      (uint _amount0, uint _amount1, uint _liquidity) = _addLiquidity (
        _lpHelper
      );
      amount0 = _amount0;
      amount1 = _amount1;
      liquidity = _liquidity;

    }
    if (amount0 < _lpHelper._amount0) {
      require(IERC20(_lpHelper._token0).transfer(msg.sender, _lpHelper._amount0 - amount0));
    }
    if (amount1 < _lpHelper._amount1) {
      require(IERC20(_lpHelper._token1).transfer(msg.sender, _lpHelper._amount1 - amount1));
    }

  }
  function swap (
    address[] memory _routers,
    uint amountIn, 
    uint _bps,
    address[] memory path,
    address _to,
    uint deadline
  ) external payable returns(uint[] memory amounts) {
    bool returnsETH = false;
    require(path[0] != path[1], "SWAP_ERROR::DUPLICATE_TOKENS");
    if (path[0] == Utils.ZERO_ADDRESS) {
      require(msg.value >= amountIn, "INSUFFICIENT ETH AMOUNT");
      path[0] = address(WETH);
      WETH.deposit{value: amountIn}();
    } else {
      if (msg.sender != address(this)) IERC20(path[0]).transferFrom(msg.sender, address(this), amountIn);
    }
    if (path[1] == Utils.ZERO_ADDRESS) {
      returnsETH = true;
      path[1] = address(WETH);
    }

    BestPrice[] memory prices = this.getBestPrice(_routers, path[0], path[1], amountIn);

    uint priceId;
    uint bestPrice;

    for (uint i = 0; i < prices.length; i++) {
      if (prices[i].amountOut > bestPrice) {
        priceId = i;
        bestPrice = prices[i].amountOut;
      }
    }
    // console.log("bestPrice", bestPrice, priceId);
    uint amountOutMin = bestPrice - Utils.feeFromBps(bestPrice, _bps);
    // console.log("amountOutMin", amountOutMin);
    IERC20(path[0]).approve(_routers[priceId], amountIn);
    amounts = IUniswapV2Router02(
      _routers[priceId]
    ).swapExactTokensForTokens(
      amountIn,
      amountOutMin,
      path,
      address(this),
      deadline
    );
    // console.log("swapped amount", amounts[0], amounts[1], IERC20(path[1]).balanceOf(address(this)));
    if (returnsETH) {
      WETH.withdrawTo(payable(_to), amounts[1]);
    } else {
      require(IERC20(path[1]).transfer(_to, amounts[1]));
    }
    
  }


}