/**
 *Submitted for verification at polygonscan.com on 2022-01-12
*/

// Verified by Darwinia Network

// hevm: flattened sources of src/CraftBase.sol

pragma solidity >=0.4.23 >=0.4.24 <0.8.0 >=0.6.0 <0.8.0 >=0.6.2 <0.8.0 >=0.6.7 <0.7.0;
pragma experimental ABIEncoderV2;

////// lib/ds-auth/src/auth.sol
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

/* pragma solidity >=0.4.23; */

interface DSAuthority {
    function canCall(
        address src, address dst, bytes4 sig
    ) external view returns (bool);
}

contract DSAuthEvents {
    event LogSetAuthority (address indexed authority);
    event LogSetOwner     (address indexed owner);
}

contract DSAuth is DSAuthEvents {
    DSAuthority  public  authority;
    address      public  owner;

    constructor() public {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);
    }

    function setOwner(address owner_)
        public
        auth
    {
        owner = owner_;
        emit LogSetOwner(owner);
    }

    function setAuthority(DSAuthority authority_)
        public
        auth
    {
        authority = authority_;
        emit LogSetAuthority(address(authority));
    }

    modifier auth {
        require(isAuthorized(msg.sender, msg.sig), "ds-auth-unauthorized");
        _;
    }

    function isAuthorized(address src, bytes4 sig) internal view returns (bool) {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            return true;
        } else if (authority == DSAuthority(address(0))) {
            return false;
        } else {
            return authority.canCall(src, address(this), sig);
        }
    }
}

////// lib/ds-stop/lib/ds-note/src/note.sol
/// note.sol -- the `note' modifier, for logging calls as events

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

/* pragma solidity >=0.4.23; */

contract DSNote {
    event LogNote(
        bytes4   indexed  sig,
        address  indexed  guy,
        bytes32  indexed  foo,
        bytes32  indexed  bar,
        uint256           wad,
        bytes             fax
    ) anonymous;

    modifier note {
        bytes32 foo;
        bytes32 bar;
        uint256 wad;

        assembly {
            foo := calldataload(4)
            bar := calldataload(36)
            wad := callvalue()
        }

        _;

        emit LogNote(msg.sig, msg.sender, foo, bar, wad, msg.data);
    }
}

////// lib/ds-stop/src/stop.sol
/// stop.sol -- mixin for enable/disable functionality

// Copyright (C) 2017  DappHub, LLC

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

/* pragma solidity >=0.4.23; */

/* import "ds-auth/auth.sol"; */
/* import "ds-note/note.sol"; */

contract DSStop is DSNote, DSAuth {
    bool public stopped;

    modifier stoppable {
        require(!stopped, "ds-stop-is-stopped");
        _;
    }
    function stop() public auth note {
        stopped = true;
    }
    function start() public auth note {
        stopped = false;
    }

}

////// lib/zeppelin-solidity/contracts/introspection/IERC165.sol

/* pragma solidity >=0.6.0 <0.8.0; */

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

////// lib/zeppelin-solidity/contracts/utils/Address.sol

/* pragma solidity >=0.6.2 <0.8.0; */

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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

////// lib/zeppelin-solidity/contracts/proxy/Initializable.sol

// solhint-disable-next-line compiler-version
/* pragma solidity >=0.4.24 <0.8.0; */

/* import "../utils/Address.sol"; */

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
        return !Address.isContract(address(this));
    }
}

////// lib/zeppelin-solidity/contracts/token/ERC1155/IERC1155.sol

/* pragma solidity >=0.6.2 <0.8.0; */

/* import "../../introspection/IERC165.sol"; */

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

////// lib/zeppelin-solidity/contracts/token/ERC20/IERC20.sol

/* pragma solidity >=0.6.0 <0.8.0; */

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

////// lib/zeppelin-solidity/contracts/token/ERC721/IERC721.sol

/* pragma solidity >=0.6.2 <0.8.0; */

/* import "../../introspection/IERC165.sol"; */

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

////// src/interfaces/ICodexEquipment.sol
/* pragma solidity ^0.6.7; */
/* pragma experimental ABIEncoderV2; */

interface ICodexEquipment {
    struct equipment {
        uint256 id;
        uint256[] materials;
        uint256[] mcosts;
        uint256 ecost;
        uint256 srate;
        string name;
    }

    struct formula {
        bytes32 minor;
        uint256 cost;
        uint256 srate;
        uint256 lrate;
    }

    function obj_by_rarity(uint rarity) external pure returns (equipment memory _e);
    function formula_by_class(uint id) external pure returns (formula memory _f);
}

////// src/interfaces/ICodexPrefer.sol
/* pragma solidity ^0.6.7; */

interface ICodexPrefer {
    function getPrefer(bytes32 minor, address token) external view returns (uint256);
    function getElement(bytes32 minor, uint256 prefer) external view returns (address);
}

////// src/interfaces/ICodexRandom.sol
/* pragma solidity ^0.6.7; */

interface ICodexRandom {
    function d100(uint _s) external view returns (uint);
}

////// src/interfaces/IMaterial.sol
/* pragma solidity ^0.6.7; */

interface IMaterial {
    function mintObject(address account, uint128 id, uint256 amount, bytes calldata data) external returns(uint256);
    function encode(uint128 id) external view returns (uint256);
}

////// src/interfaces/IObjectOwnership.sol
/* pragma solidity ^0.6.7; */

interface IObjectOwnership {
    function mintObject(address _to, uint128 _objectId) external returns (uint256 _tokenId);
    function burn(address _to, uint256 _tokenId) external;
}

////// src/interfaces/IRevenuePool.sol
/* pragma solidity ^0.6.7; */

interface IRevenuePool {
    function reward(address _token, uint256 _value, address _buyer) external;
    function settleToken(address _tokenAddress) external;
}

////// src/interfaces/ISettingsRegistry.sol
/* pragma solidity ^0.6.7; */

interface ISettingsRegistry {
    function uintOf(bytes32 _propertyName) external view returns (uint256);
    function addressOf(bytes32 _propertyName) external view returns (address);
}

////// src/CraftBase.sol
/* pragma solidity ^0.6.7; */
/* pragma experimental ABIEncoderV2; */

/* import "zeppelin-solidity/proxy/Initializable.sol"; */
/* import "zeppelin-solidity/token/ERC1155/IERC1155.sol"; */
/* import "zeppelin-solidity/token/ERC721/IERC721.sol"; */
/* import "zeppelin-solidity/token/ERC20/IERC20.sol"; */
/* import "ds-stop/stop.sol"; */
/* import "./interfaces/ISettingsRegistry.sol"; */
/* import "./interfaces/IObjectOwnership.sol"; */
/* import "./interfaces/ICodexEquipment.sol"; */
/* import "./interfaces/ICodexRandom.sol"; */
/* import "./interfaces/ICodexPrefer.sol"; */
/* import "./interfaces/IRevenuePool.sol"; */
/* import "./interfaces/IMaterial.sol"; */

contract CraftBase is Initializable, DSStop {
    event Crafted(address to, uint256 tokenId, uint256 obj_id, uint256 rarity, uint256 prefer, uint256 timestamp);
    event Enchanced(uint256 id, uint8 class, uint256 timestamp);
    event Disenchanted(uint256 id, uint8 class, uint256 timestamp);

    bytes32 private constant CONTRACT_MATERIAL = "CONTRACT_MATERIAL";
    bytes32 private constant CONTRACT_LAND_BASE = "CONTRACT_LAND_BASE";
    bytes32 private constant CONTRACT_SWORD_CODEX = "CONTRACT_SWORD_CODEX";
    bytes32 private constant CONTRACT_SHIELD_CODEX = "CONTRACT_SHIELD_CODEX";
    bytes32 private constant CONTRACT_RANDOM_CODEX = "CONTRACT_RANDOM_CODEX";
    bytes32 private constant CONTRACT_PREFER_CODEX = "CONTRACT_PREFER_CODEX";
    bytes32 private constant CONTRACT_OBJECT_OWNERSHIP = "CONTRACT_OBJECT_OWNERSHIP";
    bytes32 private constant CONTRACT_RING_ERC20_TOKEN = "CONTRACT_RING_ERC20_TOKEN";
    bytes32 private constant CONTRACT_REVENUE_POOL = "CONTRACT_REVENUE_POOL";
    bytes32 private constant CONTRACT_METADATA_TELLER = "CONTRACT_METADATA_TELLER";
    bytes32 private constant CONTRACT_ELEMENT_TOKEN = "CONTRACT_ELEMENT_TOKEN";
    bytes4 private constant _SELECTOR_TRANSFERFROM = bytes4(keccak256(bytes("transferFrom(address,address,uint256)")));

    struct Attr {
        uint8 obj_id;
        uint8 rarity;
        uint8 class;
        uint8 prefer;
    }

    /*** STORAGE ***/
    ISettingsRegistry public registry;
    uint256 public lastEquipmentId;
    mapping(uint256 => Attr) public attrs;

    modifier isHuman() {
        require(msg.sender == tx.origin, "robot is not permitted");
        _;
    }

    function initialize(address _registry) public initializer {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);

        registry = ISettingsRegistry(_registry);
    }

    function _pay_materails(uint256[] memory materials, uint256[] memory mcosts) private {
        address m = registry.addressOf(CONTRACT_MATERIAL);
        uint256[] memory ids = new uint256[](materials.length);
        for (uint256 i = 0; i < materials.length; ++i) {
            ids[i] = IMaterial(m).encode(uint128(materials[i]));
        }
        IERC1155(m).safeBatchTransferFrom(msg.sender, address(this), ids, mcosts, "");
    }

    function _craft_check(uint _srate, uint _offset) private view returns (bool) {
        address random = registry.addressOf(CONTRACT_RANDOM_CODEX);
        return ICodexRandom(random).d100(lastEquipmentId + _offset) < _srate;
    }

    function _pay_element(address element, uint256 value) private returns (uint8 prefer) {
        prefer = uint8(ICodexPrefer(registry.addressOf(CONTRACT_PREFER_CODEX)).getPrefer(CONTRACT_ELEMENT_TOKEN, element));
        require(prefer > 0, "!prefer");
        require(IERC20(element).transferFrom(msg.sender, address(this), value));
    }

    function _craft_obj(address _to, uint8 _obj_id, uint8 _rarity, uint8 _prefer) private returns (uint) {
        require(lastEquipmentId < uint128(-1), "overflow");
        lastEquipmentId += 1;
        uint256 tokenId = IObjectOwnership(registry.addressOf(CONTRACT_OBJECT_OWNERSHIP)).mintObject(_to, uint128(lastEquipmentId));
        attrs[tokenId] = Attr(_obj_id, _rarity, 0, _prefer);
        emit Crafted(_to, tokenId, _obj_id, _rarity, _prefer, block.timestamp);
        return tokenId;
    }

    function _increase_class(uint id) private {
        attrs[id].class += 1;
        emit Enchanced(id, attrs[id].class, block.timestamp);
    }

    function _decrease_class(uint id) private {
        attrs[id].class -= 1;
        emit Disenchanted(id, attrs[id].class, block.timestamp);
    }

    function craft_batch(uint8[] calldata _obj_ids, uint8[] calldata _raritys, address[] calldata _elements) external {
        require(_obj_ids.length == _raritys.length, "!len");
        require(_obj_ids.length == _elements.length, "!len");
        for(uint i=0; i< _obj_ids.length; i++) {
            _craft(_obj_ids[i], _raritys[i], _elements[i], i);
        }
    }

    // crafting
    function craft(uint8 _obj_id, uint8 _rarity, address _element) public stoppable isHuman returns (bool crafted, uint tokenId) {
        return _craft(_obj_id, _rarity, _element, 0);
    }

    function _craft(uint8 _obj_id, uint8 _rarity, address _element, uint256 offset) private returns (bool crafted, uint tokenId) {
        require(isValid(_obj_id, _rarity), "!valid");
        ICodexEquipment.equipment memory e = get_obj(_obj_id, _rarity);
        _pay_materails(e.materials, e.mcosts);
        uint8 prefer = _pay_element(_element, e.ecost);
        crafted = _craft_check(e.srate, offset);
        if (crafted) {
            tokenId = _craft_obj(msg.sender, _obj_id, _rarity, prefer);
        }
    }

    function isValid(uint _obj_id, uint _rarity) public pure returns (bool) {
        return (1 <= _obj_id && _obj_id <= 2 && _rarity >=1 && _rarity <=3);
    }

    function get_obj(uint _obj_id, uint _rarity) public view returns (ICodexEquipment.equipment memory _e) {
        if (_obj_id == 1) {
            _e = ICodexEquipment(registry.addressOf(CONTRACT_SWORD_CODEX)).obj_by_rarity(_rarity);
        } else if (_obj_id == 2) {
            _e = ICodexEquipment(registry.addressOf(CONTRACT_SHIELD_CODEX)).obj_by_rarity(_rarity);
        }
    }

    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure returns(bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata) external pure returns(bytes4) {
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }

    function getMetaData(uint id) external view returns (uint, uint, uint, uint) {
        Attr memory attr = attrs[id];
        return (attr.obj_id, attr.rarity, attr.class, attr.prefer);
    }

    function isValidClass(uint class) public pure returns (bool) {
        return (0 <= class && class <=1);
    }

    // enchanting
    function enchant(uint id, address _token) external stoppable returns (bool) {
        require(msg.sender == IERC721(registry.addressOf(CONTRACT_OBJECT_OWNERSHIP)).ownerOf(id), "!owner");
        Attr memory attr = attrs[id];
        require(isValidClass(attr.class), "!valid");
        ICodexEquipment.formula memory fml = get_formula(attr.obj_id, attr.class);
        uint8 prefer = uint8(ICodexPrefer(registry.addressOf(CONTRACT_PREFER_CODEX)).getPrefer(fml.minor, _token));
        require(prefer > 0, "!prefer");
        require(attr.prefer == prefer, "!ele");
        _increase_class(id);
        require(IERC20(_token).transferFrom(msg.sender, address(this), fml.cost));
    }

    function disenchant(uint256 id) external stoppable returns (bool) {
        require(msg.sender == IERC721(registry.addressOf(CONTRACT_OBJECT_OWNERSHIP)).ownerOf(id), "!owner");
        Attr memory attr = attrs[id];
        require(attr.class > 0, "!class");
        ICodexEquipment.formula memory fml = get_formula(attr.obj_id, attr.class - 1);
        address ele = ICodexPrefer(registry.addressOf(CONTRACT_PREFER_CODEX)).getElement(fml.minor, attr.prefer);
        _decrease_class(id);
        uint256 value = fml.cost * fml.lrate / 100;
        require(IERC20(ele).transfer(msg.sender, value));
    }

    function get_formula(uint _obj_id, uint _class) public view returns (ICodexEquipment.formula memory _f) {
        if (_obj_id == 1) {
            _f = ICodexEquipment(registry.addressOf(CONTRACT_SWORD_CODEX)).formula_by_class(_class);
        } else if (_obj_id == 2) {
            _f = ICodexEquipment(registry.addressOf(CONTRACT_SHIELD_CODEX)).formula_by_class(_class);
        }
    }
}