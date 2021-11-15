// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./UpgradeabilityProxy.sol";

/**
 * @title AdminUpgradeabilityProxy
 * @dev This contract combines an upgradeability proxy with an authorization
 * mechanism for administrative tasks.
 * All external functions in this contract must be guarded by the
 * `ifAdmin` modifier. See ethereum/solidity#3864 for a Solidity
 * feature proposal that would enable this to be done automatically.
 */
contract AdminUpgradeabilityProxy is UpgradeabilityProxy {
    /**
     * Contract constructor.
     * @param _logic address of the initial implementation.
     * @param _admin Address of the proxy administrator.
     * @param _data Data to send as msg.data to the implementation to initialize the proxied contract.
     * It should include the signature and the parameters of the function to be called, as described in
     * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
     * This parameter is optional, if no data is given the initialization call to proxied contract will be skipped.
     */
    constructor(
        address _logic,
        address _admin,
        bytes memory _data
    ) public payable UpgradeabilityProxy(_logic, _data) {
        assert(
            ADMIN_SLOT == bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1)
        );
        _setAdmin(_admin);
    }

    /**
     * @dev Emitted when the administration has been transferred.
     * @param previousAdmin Address of the previous admin.
     * @param newAdmin Address of the new admin.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */

    bytes32
        internal constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Modifier to check whether the `msg.sender` is the admin.
     * If it is, it will run the function. Otherwise, it will delegate the call
     * to the implementation.
     */
    modifier ifAdmin() {
        if (msg.sender == _admin()) {
            _;
        } else {
            _fallback();
        }
    }

    /**
     * @return The address of the proxy admin.
     */
    function admin() external ifAdmin returns (address) {
        return _admin();
    }

    /**
     * @return The address of the implementation.
     */
    function implementation() external ifAdmin returns (address) {
        return _implementation();
    }

    /**
     * @dev Changes the admin of the proxy.
     * Only the current admin can call this function.
     * @param newAdmin Address to transfer proxy administration to.
     */
    function changeAdmin(address newAdmin) external ifAdmin {
        require(
            newAdmin != address(0),
            "Cannot change the admin of a proxy to the zero address"
        );
        emit AdminChanged(_admin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev Upgrade the backing implementation of the proxy.
     * Only the admin can call this function.
     * @param newImplementation Address of the new implementation.
     */
    function upgradeTo(address newImplementation) external ifAdmin {
        _upgradeTo(newImplementation);
    }

    /**
     * @dev Upgrade the backing implementation of the proxy and call a function
     * on the new implementation.
     * This is useful to initialize the proxied contract.
     * @param newImplementation Address of the new implementation.
     * @param data Data to send as msg.data in the low level call.
     * It should include the signature and the parameters of the function to be called, as described in
     * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
     */
    function upgradeToAndCall(address newImplementation, bytes calldata data)
        external
        payable
        ifAdmin
    {
        _upgradeTo(newImplementation);
        (bool success, ) = newImplementation.delegatecall(data);
        require(success);
    }

    /**
     * @return adm The admin slot.
     */
    function _admin() internal view returns (address adm) {
        bytes32 slot = ADMIN_SLOT;
        assembly {
            adm := sload(slot)
        }
    }

    /**
     * @dev Sets the address of the proxy admin.
     * @param newAdmin Address of the new proxy admin.
     */
    function _setAdmin(address newAdmin) internal {
        bytes32 slot = ADMIN_SLOT;

        assembly {
            sstore(slot, newAdmin)
        }
    }

    /**
     * @dev Only fall back when the sender is not the admin.
     */
    function _willFallback() internal virtual override {
        require(
            msg.sender != _admin(),
            "Cannot call fallback function from the proxy admin"
        );
        super._willFallback();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import './Proxy.sol';
import '@openzeppelin/contracts/utils/Address.sol';

/**
 * @title UpgradeabilityProxy
 * @dev This contract implements a proxy that allows to change the
 * implementation address to which it will delegate.
 * Such a change is called an implementation upgrade.
 */
contract UpgradeabilityProxy is Proxy {
  /**
   * @dev Contract constructor.
   * @param _logic Address of the initial implementation.
   * @param _data Data to send as msg.data to the implementation to initialize the proxied contract.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   * This parameter is optional, if no data is given the initialization call to proxied contract will be skipped.
   */
  constructor(address _logic, bytes memory _data) public payable {
    assert(IMPLEMENTATION_SLOT == bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1));
    _setImplementation(_logic);
    if(_data.length > 0) {
      (bool success,) = _logic.delegatecall(_data);
      require(success);
    }
  }  

  /**
   * @dev Emitted when the implementation is upgraded.
   * @param implementation Address of the new implementation.
   */
  event Upgraded(address indexed implementation);

  /**
   * @dev Storage slot with the address of the current implementation.
   * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
   * validated in the constructor.
   */
  bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

  /**
   * @dev Returns the current implementation.
   * @return impl Address of the current implementation
   */
  function _implementation() internal override view returns (address impl) {
    bytes32 slot = IMPLEMENTATION_SLOT;
    assembly {
      impl := sload(slot)
    }
  }

  /**
   * @dev Upgrades the proxy to a new implementation.
   * @param newImplementation Address of the new implementation.
   */
  function _upgradeTo(address newImplementation) internal {
    _setImplementation(newImplementation);
    emit Upgraded(newImplementation);
  }

  /**
   * @dev Sets the implementation address of the proxy.
   * @param newImplementation Address of the new implementation.
   */
  function _setImplementation(address newImplementation) internal {
    require(Address.isContract(newImplementation), "Cannot set a proxy implementation to a non-contract address");

    bytes32 slot = IMPLEMENTATION_SLOT;

    assembly {
      sstore(slot, newImplementation)
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @title Proxy
 * @dev Implements delegation of calls to other contracts, with proper
 * forwarding of return values and bubbling of failures.
 * It defines a fallback function that delegates all calls to the address
 * returned by the abstract _implementation() internal function.
 */
abstract contract Proxy {
    /**
     * @dev Fallback function.
     * Implemented entirely in `_fallback`.
     */
    fallback() external payable {
        _fallback();
    }

    /**
     * @dev Receive function.
     * Implemented entirely in `_fallback`.
     */
    receive() external payable {
        _fallback();
    }

    /**
     * @return The Address of the implementation.
     */
    function _implementation() internal virtual view returns (address);

    /**
     * @dev Delegates execution to an implementation contract.
     * This is a low level function that doesn't return to its internal call site.
     * It will return to the external caller whatever the implementation returns.
     * @param implementation Address to delegate.
     */
    function _delegate(address implementation) internal {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(
                gas(),
                implementation,
                0,
                calldatasize(),
                0,
                0
            )

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
                // delegatecall returns 0 on error.
                case 0 {
                    revert(0, returndatasize())
                }
                default {
                    return(0, returndatasize())
                }
        }
    }

    /**
     * @dev Function that is run as the first thing in the fallback function.
     * Can be redefined in derived contracts to add functionality.
     * Redefinitions must call super._willFallback().
     */
    function _willFallback() internal virtual {}

    /**
     * @dev fallback implementation.
     * Extracted to enable manual triggering.
     */
    function _fallback() internal {
        _willFallback();
        _delegate(_implementation());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

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
        // This method relies in extcodesize, which returns 0 for contracts in
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../../GSN/Context.sol";
import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./IERC721Enumerable.sol";
import "./IERC721Receiver.sol";
import "../../introspection/ERC165.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";
import "../../utils/EnumerableSet.sol";
import "../../utils/EnumerableMap.sol";
import "../../utils/Strings.sol";

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata, IERC721Enumerable {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using Strings for uint256;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from holder address to their (enumerable) set of owned tokens
    mapping (address => EnumerableSet.UintSet) private _holderTokens;

    // Enumerable mapping from token ids to their owners
    EnumerableMap.UintToAddressMap private _tokenOwners;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

    // Base URI
    string private _baseURI;

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c5 ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    /*
     *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
     *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     */
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");

        return _holderTokens[owner].length();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return _tokenOwners.get(tokenId, "ERC721: owner query for nonexistent token");
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];

        // If there is no base URI, return the token URI.
        if (bytes(_baseURI).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(_baseURI, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(_baseURI, tokenId.toString()));
    }

    /**
    * @dev Returns the base URI set via {_setBaseURI}. This will be
    * automatically added as a prefix in {tokenURI} to each token's URI, or
    * to the token ID if no specific URI is set for that token ID.
    */
    function baseURI() public view returns (string memory) {
        return _baseURI;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256) {
        return _holderTokens[owner].at(index);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        // _tokenOwners are indexed by tokenIds, so .length() returns the number of tokenIds
        return _tokenOwners.length();
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view override returns (uint256) {
        (uint256 tokenId, ) = _tokenOwners.at(index);
        return tokenId;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _tokenOwners.contains(tokenId);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     d*
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }

        _holderTokens[owner].remove(tokenId);

        _tokenOwners.remove(tokenId);

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _holderTokens[from].remove(tokenId);
        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI},
     * or to the token ID if {tokenURI} is empty.
     */
    function _setBaseURI(string memory baseURI_) internal virtual {
        _baseURI = baseURI_;
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }
        bytes memory returndata = to.functionCall(abi.encodeWithSelector(
            IERC721Receiver(to).onERC721Received.selector,
            _msgSender(),
            from,
            tokenId,
            _data
        ), "ERC721: transfer to non ERC721Receiver implementer");
        bytes4 retval = abi.decode(returndata, (bytes4));
        return (retval == _ERC721_RECEIVED);
    }

    function _approve(address to, uint256 tokenId) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "../../introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
    external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
     *
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.0.0, only sets of type `address` (`AddressSet`) and `uint256`
 * (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * As of v3.0.0, only maps of type `uint256 -> address` (`UintToAddressMap`) are
 * supported.
 */
library EnumerableMap {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {
        // Storage of map keys and values
        MapEntry[] _entries;

        // Position of the entry defined by a key in the `entries` array, plus 1
        // because index 0 means a key is not in the map.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(Map storage map, bytes32 key, bytes32 value) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) { // Equivalent to !contains(map, key)
            map._entries.push(MapEntry({ _key: key, _value: value }));
            // The entry is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            map._entries[keyIndex - 1]._value = value;
            return false;
        }
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, bytes32 key) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) { // Equivalent to contains(map, key)
            // To delete a key-value pair from the _entries array in O(1), we swap the entry to delete with the last one
            // in the array, and then remove the last entry (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = map._entries.length - 1;

            // When the entry to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            MapEntry storage lastEntry = map._entries[lastIndex];

            // Move the last entry to the index where the entry to delete is
            map._entries[toDeleteIndex] = lastEntry;
            // Update the index for the moved entry
            map._indexes[lastEntry._key] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved entry was stored
            map._entries.pop();

            // Delete the index for the deleted slot
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._indexes[key] != 0;
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }

   /**
    * @dev Returns the key-value pair stored at position `index` in the map. O(1).
    *
    * Note that there are no guarantees on the ordering of entries inside the
    * array, and it may change when more entries are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        require(map._entries.length > index, "EnumerableMap: index out of bounds");

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        return _get(map, key, "EnumerableMap: nonexistent key");
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     */
    function _get(Map storage map, bytes32 key, string memory errorMessage) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, errorMessage); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(UintToAddressMap storage map, uint256 key, address value) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

   /**
    * @dev Returns the element stored at position `index` in the set. O(1).
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint256(value)));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint256(_get(map._inner, bytes32(key))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     */
    function get(UintToAddressMap storage map, uint256 key, string memory errorMessage) internal view returns (address) {
        return address(uint256(_get(map._inner, bytes32(key), errorMessage)));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev String operations.
 */
library Strings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
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
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = byte(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./ERC721.sol";
import "../../utils/Pausable.sol";

/**
 * @dev ERC721 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC721Pausable is ERC721, Pausable {
    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        require(!paused(), "ERC721Pausable: token transfer while paused");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../GSN/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./ERC1155.sol";
import "../../utils/Pausable.sol";

/**
 * @dev ERC1155 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 *
 * _Available since v3.1._
 */
abstract contract ERC1155Pausable is ERC1155, Pausable {
    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        internal virtual override
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        require(!paused(), "ERC1155Pausable: token transfer while paused");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./IERC1155.sol";
import "./IERC1155MetadataURI.sol";
import "./IERC1155Receiver.sol";
import "../../GSN/Context.sol";
import "../../introspection/ERC165.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 *
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using SafeMath for uint256;
    using Address for address;

    // Mapping from token ID to account balances
    mapping (uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping (address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /*
     *     bytes4(keccak256('balanceOf(address,uint256)')) == 0x00fdd58e
     *     bytes4(keccak256('balanceOfBatch(address[],uint256[])')) == 0x4e1273f4
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,uint256,bytes)')) == 0xf242432a
     *     bytes4(keccak256('safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)')) == 0x2eb2c2d6
     *
     *     => 0x00fdd58e ^ 0x4e1273f4 ^ 0xa22cb465 ^
     *        0xe985e9c5 ^ 0xf242432a ^ 0x2eb2c2d6 == 0xd9b67a26
     */
    bytes4 private constant _INTERFACE_ID_ERC1155 = 0xd9b67a26;

    /*
     *     bytes4(keccak256('uri(uint256)')) == 0x0e89341c
     */
    bytes4 private constant _INTERFACE_ID_ERC1155_METADATA_URI = 0x0e89341c;

    /**
     * @dev See {_setURI}.
     */
    constructor (string memory uri) public {
        _setURI(uri);

        // register the supported interfaces to conform to ERC1155 via ERC165
        _registerInterface(_INTERFACE_ID_ERC1155);

        // register the supported interfaces to conform to ERC1155MetadataURI via ERC165
        _registerInterface(_INTERFACE_ID_ERC1155_METADATA_URI);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) external view override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    )
        public
        view
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            require(accounts[i] != address(0), "ERC1155: batch balance query for the zero address");
            batchBalances[i] = _balances[ids[i]][accounts[i]];
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(_msgSender() != operator, "ERC1155: setting approval status for self");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        public
        virtual
        override
    {
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][from] = _balances[id][from].sub(amount, "ERC1155: insufficient balance for transfer");
        _balances[id][to] = _balances[id][to].add(amount);

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        public
        virtual
        override
    {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            _balances[id][from] = _balances[id][from].sub(
                amount,
                "ERC1155: insufficient balance for transfer"
            );
            _balances[id][to] = _balances[id][to].add(amount);
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(address account, uint256 id, uint256 amount, bytes memory data) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][account] = _balances[id][account].add(amount);
        emit TransferSingle(operator, address(0), account, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), account, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] = amounts[i].add(_balances[ids[i]][to]);
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function _burn(address account, uint256 id, uint256 amount) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        _balances[id][account] = _balances[id][account].sub(
            amount,
            "ERC1155: burn amount exceeds balance"
        );

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(address account, uint256[] memory ids, uint256[] memory amounts) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint i = 0; i < ids.length; i++) {
            _balances[ids[i]][account] = _balances[ids[i]][account].sub(
                amounts[i],
                "ERC1155: burn amount exceeds balance"
            );
        }

        emit TransferBatch(operator, account, address(0), ids, amounts);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        internal virtual
    { }

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        private
    {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver(to).onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        private
    {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (bytes4 response) {
                if (response != IERC1155Receiver(to).onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "../../introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "./IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../../introspection/IERC165.sol";

/**
 * _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {

    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        returns(bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        returns(bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./ERC1155.sol";

/**
 * @dev Extension of {ERC1155} that allows token holders to destroy both their
 * own tokens and those that they have been approved to use.
 *
 * _Available since v3.1._
 */
abstract contract ERC1155Burnable is ERC1155 {
    function burn(address account, uint256 id, uint256 value) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burn(account, id, value);
    }

    function burnBatch(address account, uint256[] memory ids, uint256[] memory values) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burnBatch(account, ids, values);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../access/AccessControl.sol";
import "../GSN/Context.sol";
import "../token/ERC1155/ERC1155.sol";
import "../token/ERC1155/ERC1155Burnable.sol";
import "../token/ERC1155/ERC1155Pausable.sol";

/**
 * @dev {ERC1155} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to other accounts.
 */
contract ERC1155PresetMinterPauser is Context, AccessControl, ERC1155Burnable, ERC1155Pausable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE`, and `PAUSER_ROLE` to the account that
     * deploys the contract.
     */
    constructor(string memory uri) public ERC1155(uri) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
    }

    /**
     * @dev Creates `amount` new tokens for `to`, of token type `id`.
     *
     * See {ERC1155-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, uint256 id, uint256 amount, bytes memory data) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC1155PresetMinterPauser: must have minter role to mint");

        _mint(to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] variant of {mint}.
     */
    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC1155PresetMinterPauser: must have minter role to mint");

        _mintBatch(to, ids, amounts, data);
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC1155Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC1155PresetMinterPauser: must have pauser role to pause");
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC1155Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC1155PresetMinterPauser: must have pauser role to unpause");
        _unpause();
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        internal virtual override(ERC1155, ERC1155Pausable)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../utils/EnumerableSet.sol";
import "../utils/Address.sol";
import "../GSN/Context.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
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
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

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
     * bearer except when using {_setupRole}.
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
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
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
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

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
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

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
    function renounceRole(bytes32 role, address account) public virtual {
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
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../access/AccessControl.sol";
import "../GSN/Context.sol";
import "../utils/Counters.sol";
import "../token/ERC721/ERC721.sol";
import "../token/ERC721/ERC721Burnable.sol";
import "../token/ERC721/ERC721Pausable.sol";

/**
 * @dev {ERC721} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *  - token ID and URI autogeneration
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to other accounts.
 */
contract ERC721PresetMinterPauserAutoId is Context, AccessControl, ERC721Burnable, ERC721Pausable {
    using Counters for Counters.Counter;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    Counters.Counter private _tokenIdTracker;

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` to the
     * account that deploys the contract.
     *
     * Token URIs will be autogenerated based on `baseURI` and their token IDs.
     * See {ERC721-tokenURI}.
     */
    constructor(string memory name, string memory symbol, string memory baseURI) public ERC721(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());

        _setBaseURI(baseURI);
    }

    /**
     * @dev Creates a new token for `to`. Its token ID will be automatically
     * assigned (and available on the emitted {IERC721-Transfer} event), and the token
     * URI autogenerated based on the base URI passed at construction.
     *
     * See {ERC721-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC721PresetMinterPauserAutoId: must have minter role to mint");

        // We cannot just use balanceOf to create the new tokenId because tokens
        // can be burned (destroyed), so we need a separate counter.
        _mint(to, _tokenIdTracker.current());
        _tokenIdTracker.increment();
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC721PresetMinterPauserAutoId: must have pauser role to pause");
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC721PresetMinterPauserAutoId: must have pauser role to unpause");
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../math/SafeMath.sol";

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library Counters {
    using SafeMath for uint256;

    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../../GSN/Context.sol";
import "./ERC721.sol";

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be irreversibly burned (destroyed).
 */
abstract contract ERC721Burnable is Context, ERC721 {
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }
}

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/presets/ERC721PresetMinterPauserAutoId.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT

contract TokenRecover is Ownable {
    /**
     * @dev Remember that only owner can call so be careful when use on contracts generated from other contracts.
     * @param tokenAddress The token contract address
     * @param tokenAmount Number of tokens to be sent
     */
    function recoverERC20(address tokenAddress, uint256 tokenAmount)
        public
        onlyOwner
    {
        IERC20(tokenAddress).transfer(owner(), tokenAmount);
    }
}

// Interface for our erc20 token
interface IMuseToken {
    function totalSupply() external view returns (uint256);

    function balanceOf(address tokenOwner)
        external
        view
        returns (uint256 balance);

    function allowance(address tokenOwner, address spender)
        external
        view
        returns (uint256 remaining);

    function transfer(address to, uint256 tokens)
        external
        returns (bool success);

    function approve(address spender, uint256 tokens)
        external
        returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) external returns (bool success);

    function mintingFinished() external view returns (bool);

    function mint(address to, uint256 amount) external;

    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
}

/*
 * Deployment checklist::
 *  1. Deploy all contracts
 *  2. Give minter role to the claiming contract
 *  3. Add objects (most basic cost 5 and give 1 day and 1 score)
 *  4.
 */

// ERC721,
contract VNFT is
    Ownable,
    ERC721PresetMinterPauserAutoId,
    TokenRecover,
    ERC1155Holder
{
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    IMuseToken public muse;

    struct VNFTObj {
        address token;
        uint256 id;
        uint256 standard; //the type
    }

    // Mapping from token ID to NFT struct details
    mapping(uint256 => VNFTObj) public vnftDetails;

    // max dev allocation is 10% of total supply
    uint256 public maxDevAllocation = 100000 * 10**18;
    uint256 public devAllocation = 0;

    // External NFTs
    struct NFTInfo {
        address token; // Address of LP token contract.
        bool active;
        uint256 standard; //the nft standard ERC721 || ERC1155
    }

    NFTInfo[] public supportedNfts;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    Counters.Counter private _itemIds;

    // how many tokens to burn every time the VNFT is given an accessory, the remaining goes to the community and devs
    uint256 public burnPercentage = 90;
    uint256 public giveLifePrice = 5 * 10**18;

    uint256 public fatalityPct = 60;

    bool public gameStopped = false;

    // mining tokens
    mapping(uint256 => uint256) public lastTimeMined;

    // VNFT properties
    mapping(uint256 => uint256) public timeUntilStarving;
    mapping(uint256 => uint256) public vnftScore;
    mapping(uint256 => uint256) public timeVnftBorn;

    // items/benefits for the VNFT could be anything in the future.
    mapping(uint256 => uint256) public itemPrice;
    mapping(uint256 => uint256) public itemPoints;
    mapping(uint256 => string) public itemName;
    mapping(uint256 => uint256) public itemTimeExtension;

    // mapping(uint256 => address) public careTaker;
    mapping(uint256 => mapping(address => address)) public careTaker;

    event BurnPercentageChanged(uint256 percentage);
    event ClaimedMiningRewards(uint256 who, address owner, uint256 amount);
    event VnftConsumed(uint256 nftId, address giver, uint256 itemId);
    event VnftMinted(address to);
    event VnftFatalized(uint256 nftId, address killer);
    event ItemCreated(uint256 id, string name, uint256 price, uint256 points);
    event LifeGiven(address forSupportedNFT, uint256 id);
    event Unwrapped(uint256 nftId);
    event CareTakerAdded(uint256 nftId, address _to);
    event CareTakerRemoved(uint256 nftId);

    constructor(address _museToken)
        public
        ERC721PresetMinterPauserAutoId(
            "VNFT",
            "VNFT",
            "https://gallery.verynify.io/api/"
        )
    {
        _setupRole(OPERATOR_ROLE, _msgSender());
        muse = IMuseToken(_museToken);
    }

    modifier notPaused() {
        require(!gameStopped, "Contract is paused");
        _;
    }

    modifier onlyOperator() {
        require(
            hasRole(OPERATOR_ROLE, _msgSender()),
            "Roles: caller does not have the OPERATOR role"
        );
        _;
    }

    modifier onlyMinter() {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "Roles: caller does not have the MINTER role"
        );
        _;
    }

    function contractURI() public pure returns (string memory) {
        return "https://gallery.verynifty.io/api";
    }

    // in case a bug happens or we upgrade to another smart contract
    function pauseGame(bool _pause) external onlyOperator {
        gameStopped = _pause;
    }

    function changeFatalityPct(uint256 _newpct) external onlyOperator {
        fatalityPct = _newpct;
    }

    // change how much to burn on each buy and how much goes to community.
    function changeBurnPercentage(uint256 percentage) external onlyOperator {
        require(percentage <= 100);
        burnPercentage = percentage;
        emit BurnPercentageChanged(burnPercentage);
    }

    function changeGiveLifePrice(uint256 _newPrice) external onlyOperator {
        giveLifePrice = _newPrice * 10**18;
    }

    function changeMaxDevAllocation(uint256 amount) external onlyOperator {
        maxDevAllocation = amount;
    }

    function itemExists(uint256 itemId) public view returns (bool) {
        if (bytes(itemName[itemId]).length > 0) {
            return true;
        }
    }

    // check that VNFT didn't starve
    function isVnftAlive(uint256 _nftId) public view returns (bool) {
        uint256 _timeUntilStarving = timeUntilStarving[_nftId];
        if (_timeUntilStarving != 0 && _timeUntilStarving >= block.timestamp) {
            return true;
        }
    }

    function getVnftScore(uint256 _nftId) public view returns (uint256) {
        return vnftScore[_nftId];
    }

    function getItemInfo(uint256 _itemId)
        public
        view
        returns (
            string memory _name,
            uint256 _price,
            uint256 _points,
            uint256 _timeExtension
        )
    {
        _name = itemName[_itemId];
        _price = itemPrice[_itemId];
        _timeExtension = itemTimeExtension[_itemId];
        _points = itemPoints[_itemId];
    }

    function getVnftInfo(uint256 _nftId)
        public
        view
        returns (
            uint256 _vNFT,
            bool _isAlive,
            uint256 _score,
            uint256 _level,
            uint256 _expectedReward,
            uint256 _timeUntilStarving,
            uint256 _lastTimeMined,
            uint256 _timeVnftBorn,
            address _owner,
            address _token,
            uint256 _tokenId,
            uint256 _fatalityReward
        )
    {
        _vNFT = _nftId;
        _isAlive = this.isVnftAlive(_nftId);
        _score = this.getVnftScore(_nftId);
        _level = this.level(_nftId);
        _expectedReward = this.getRewards(_nftId);
        _timeUntilStarving = timeUntilStarving[_nftId];
        _lastTimeMined = lastTimeMined[_nftId];
        _timeVnftBorn = timeVnftBorn[_nftId];
        _owner = this.ownerOf(_nftId);
        _token = vnftDetails[_nftId].token;
        _tokenId = vnftDetails[_nftId].id;
        _fatalityReward = getFatalityReward(_nftId);
    }

    function editCurves(
        uint256 _la,
        uint256 _lb,
        uint256 _ra,
        uint256 _rb
    ) external onlyOperator {
        la = _la;
        lb = _lb;
        ra = _ra;
        rb = _rb;
    }

    uint256 la = 2;
    uint256 lb = 2;
    uint256 ra = 6;
    uint256 rb = 7;

    // get the level the vNFT is on to calculate points
    function level(uint256 tokenId) external view returns (uint256) {
        // This is the formula L(x) = 2 * sqrt(x * 2)
        uint256 _score = vnftScore[tokenId].div(100);
        if (_score == 0) {
            return 1;
        }
        uint256 _level = sqrtu(_score.mul(la));
        return (_level.mul(lb));
    }

    // get the level the vNFT is on to calculate the token reward
    function getRewards(uint256 tokenId) external view returns (uint256) {
        // This is the formula to get token rewards R(level)=(level)*6/7+6
        uint256 _level = this.level(tokenId);
        if (_level == 1) {
            return 6 ether;
        }
        _level = _level.mul(1 ether).mul(ra).div(rb);
        return (_level.add(5 ether));
    }

    // edit specific item in case token goes up in value and the price for items gets to expensive for normal users.
    function editItem(
        uint256 _id,
        uint256 _price,
        uint256 _points,
        string calldata _name,
        uint256 _timeExtension
    ) external onlyOperator {
        itemPrice[_id] = _price;
        itemPoints[_id] = _points;
        itemName[_id] = _name;
        itemTimeExtension[_id] = _timeExtension;
    }

    //can mine once every 24 hours per token.
    function claimMiningRewards(uint256 nftId) external notPaused {
        require(isVnftAlive(nftId), "Your vNFT is dead, you can't mine");
        require(
            block.timestamp >= lastTimeMined[nftId].add(1 days) ||
                lastTimeMined[nftId] == 0,
            "Current timestamp is over the limit to claim the tokens"
        );
        require(
            ownerOf(nftId) == msg.sender ||
                careTaker[nftId][ownerOf(nftId)] == msg.sender,
            "You must own the vNFT to claim rewards"
        );

        //reset last start mined so can't remine and cheat
        lastTimeMined[nftId] = block.timestamp;
        uint256 _reward = this.getRewards(nftId);
        muse.mint(msg.sender, _reward);
        emit ClaimedMiningRewards(nftId, msg.sender, _reward);
    }

    // Buy accesory to the VNFT
    function buyAccesory(uint256 nftId, uint256 itemId) external notPaused {
        require(itemExists(itemId), "This item doesn't exist");
        uint256 amount = itemPrice[itemId];
        require(
            ownerOf(nftId) == msg.sender ||
                careTaker[nftId][ownerOf(nftId)] == msg.sender,
            "You must own the vNFT or be a care taker to buy items"
        );
        // require(isVnftAlive(nftId), "Your vNFT is dead");
        uint256 amountToBurn = amount.mul(burnPercentage).div(100);

        // recalculate time until starving
        timeUntilStarving[nftId] = block.timestamp.add(
            itemTimeExtension[itemId]
        );
        if (!isVnftAlive(nftId)) {
            vnftScore[nftId] = itemPoints[itemId];
        } else {
            vnftScore[nftId] = vnftScore[nftId].add(itemPoints[itemId]);
        }
        // burn 90% so they go back to community mining and staking, and send 10% to devs

        if (devAllocation <= maxDevAllocation) {
            devAllocation = devAllocation.add(amount.sub(amountToBurn));
            muse.transferFrom(msg.sender, address(this), amount);
            // burn 90% of token, 10% stay for dev and community fund
            muse.burn(amountToBurn);
        } else {
            muse.burnFrom(msg.sender, amount);
        }
        emit VnftConsumed(nftId, msg.sender, itemId);
    }

    function setBaseURI(string memory baseURI_) public onlyOperator {
        _setBaseURI(baseURI_);
    }

    function mint(address player) public override onlyMinter {
        //pet minted has 3 days until it starves at first
        timeUntilStarving[_tokenIds.current()] = block.timestamp.add(3 days);
        timeVnftBorn[_tokenIds.current()] = block.timestamp;

        vnftDetails[_tokenIds.current()] = VNFTObj(
            address(this),
            _tokenIds.current(),
            721
        );
        super._mint(player, _tokenIds.current());
        _tokenIds.increment();
        emit VnftMinted(msg.sender);
    }

    // kill starverd NFT and get fatalityPct of his points.
    function fatality(uint256 _deadId, uint256 _tokenId) external notPaused {
        require(
            !isVnftAlive(_deadId),
            "The vNFT has to be starved to claim his points"
        );
        vnftScore[_tokenId] = vnftScore[_tokenId].add(
            (vnftScore[_deadId].mul(fatalityPct).div(100))
        );
        vnftScore[_deadId] = 0;
        delete vnftDetails[_deadId];
        _burn(_deadId);
        emit VnftFatalized(_deadId, msg.sender);
    }

    // Check how much score you'll get by fatality someone.
    function getFatalityReward(uint256 _deadId) public view returns (uint256) {
        if (isVnftAlive(_deadId)) {
            return 0;
        } else {
            return (vnftScore[_deadId].mul(60).div(100));
        }
    }

    // add items/accessories
    function createItem(
        string calldata name,
        uint256 price,
        uint256 points,
        uint256 timeExtension
    ) external onlyOperator returns (bool) {
        _itemIds.increment();
        uint256 newItemId = _itemIds.current();
        itemName[newItemId] = name;
        itemPrice[newItemId] = price * 10**18;
        itemPoints[newItemId] = points;
        itemTimeExtension[newItemId] = timeExtension;
        emit ItemCreated(newItemId, name, price, points);
    }

    //  *****************************
    //  LOGIC FOR EXTERNAL NFTS
    //  ****************************
    // support an external nft to mine rewards and play
    function addNft(address _nftToken, uint256 _type) public onlyOperator {
        supportedNfts.push(
            NFTInfo({token: _nftToken, active: true, standard: _type})
        );
    }

    function supportedNftLength() external view returns (uint256) {
        return supportedNfts.length;
    }

    function updateSupportedNFT(
        uint256 index,
        bool _active,
        address _address
    ) public onlyOperator {
        supportedNfts[index].active = _active;
        supportedNfts[index].token = _address;
    }

    // aka WRAP: lets give life to your erc721 token and make it fun to mint $muse!
    function giveLife(
        uint256 index,
        uint256 _id,
        uint256 nftType
    ) external notPaused {
        uint256 amountToBurn = giveLifePrice.mul(burnPercentage).div(100);

        if (devAllocation <= maxDevAllocation) {
            devAllocation = devAllocation.add(giveLifePrice.sub(amountToBurn));
            muse.transferFrom(msg.sender, address(this), giveLifePrice);
            // burn 90% of token, 10% stay for dev and community fund
            muse.burn(amountToBurn);
        } else {
            muse.burnFrom(msg.sender, giveLifePrice);
        }

        if (nftType == 721) {
            IERC721(supportedNfts[index].token).transferFrom(
                msg.sender,
                address(this),
                _id
            );
        } else if (nftType == 1155) {
            IERC1155(supportedNfts[index].token).safeTransferFrom(
                msg.sender,
                address(this),
                _id,
                1, //the amount of tokens to transfer which always be 1
                "0x0"
            );
        }

        // mint a vNFT
        vnftDetails[_tokenIds.current()] = VNFTObj(
            supportedNfts[index].token,
            _id,
            nftType
        );

        timeUntilStarving[_tokenIds.current()] = block.timestamp.add(3 days);
        timeVnftBorn[_tokenIds.current()] = block.timestamp;

        super._mint(msg.sender, _tokenIds.current());
        _tokenIds.increment();
        emit LifeGiven(supportedNfts[index].token, _id);
    }

    // unwrap your vNFT if it is not dead, and get back your original NFT
    function unwrap(uint256 _vnftId) external {
        require(isVnftAlive(_vnftId), "Your vNFT is dead, you can't unwrap it");
        transferFrom(msg.sender, address(this), _vnftId);
        VNFTObj memory details = vnftDetails[_vnftId];
        timeUntilStarving[_vnftId] = 1;
        vnftScore[_vnftId] = 0;
        emit Unwrapped(_vnftId);
        _withdraw(details.id, details.token, msg.sender, details.standard);
    }

    // withdraw dead wrapped NFTs or send them to the burn address.
    function withdraw(
        uint256 _id,
        address _contractAddr,
        address _to,
        uint256 _type
    ) external onlyOperator {
        _withdraw(_id, _contractAddr, _to, _type);
    }

    function _withdraw(
        uint256 _id,
        address _contractAddr,
        address _to,
        uint256 _type
    ) internal {
        if (_type == 1155) {
            IERC1155(_contractAddr).safeTransferFrom(
                address(this),
                _to,
                _id,
                1,
                ""
            );
        } else if (_type == 721) {
            IERC721(_contractAddr).transferFrom(address(this), _to, _id);
        }
    }

    // add care taker so in the future if vNFTs are sent to tokenizing platforms like niftex we can whitelist and the previous owner could still mine and do interesting stuff.
    function addCareTaker(uint256 _tokenId, address _careTaker) external {
        require(
            hasRole(OPERATOR_ROLE, _msgSender()) ||
                ownerOf(_tokenId) == msg.sender,
            "Roles: caller does not have the OPERATOR role"
        );
        careTaker[_tokenId][msg.sender] = _careTaker;
        emit CareTakerAdded(_tokenId, _careTaker);
    }

    function clearCareTaker(uint256 _tokenId) external {
        require(
            hasRole(OPERATOR_ROLE, _msgSender()) ||
                ownerOf(_tokenId) == msg.sender,
            "Roles: caller does not have the OPERATOR role"
        );
        delete careTaker[_tokenId][msg.sender];
        emit CareTakerRemoved(_tokenId);
    }

    /**
     * Calculate sqrt (x) rounding down, where x is unsigned 256-bit integer
     * number.
     *
     * @param x unsigned 256-bit integer number
     * @return unsigned 128-bit integer number
     */
    function sqrtu(uint256 x) private pure returns (uint128) {
        if (x == 0) return 0;
        else {
            uint256 xx = x;
            uint256 r = 1;
            if (xx >= 0x100000000000000000000000000000000) {
                xx >>= 128;
                r <<= 64;
            }
            if (xx >= 0x10000000000000000) {
                xx >>= 64;
                r <<= 32;
            }
            if (xx >= 0x100000000) {
                xx >>= 32;
                r <<= 16;
            }
            if (xx >= 0x10000) {
                xx >>= 16;
                r <<= 8;
            }
            if (xx >= 0x100) {
                xx >>= 8;
                r <<= 4;
            }
            if (xx >= 0x10) {
                xx >>= 4;
                r <<= 2;
            }
            if (xx >= 0x8) {
                r <<= 1;
            }
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1; // Seven iterations should be enough
            uint256 r1 = x / r;
            return uint128(r < r1 ? r : r1);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./ERC1155Receiver.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../GSN/Context.sol";
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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./IERC1155Receiver.sol";
import "../../introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    constructor() public {
        _registerInterface(
            ERC1155Receiver(0).onERC1155Received.selector ^
            ERC1155Receiver(0).onERC1155BatchReceived.selector
        );
    }
}

pragma solidity ^0.6.0;

pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract TokenizeNFT is Ownable {
    using SafeMath for uint256;

    uint256 public currentRace = 0;
    uint256 public constant maxParticipants = 10;
    uint256 public minParticipant = 2;

    struct Participant {
        address nftContract;
        uint256 nftId;
        uint256 score;
        address payable add;
    }

    mapping(uint256 => Participant[]) public participants;
    mapping(uint256 => uint256) public raceParticipants;
    mapping(uint256 => uint256) public raceMaxScore;
    mapping(uint256 => uint256) public raceStart;
    mapping(address => uint256) public whitelist;
    uint256 public entryPrice = 1 ether / 10; //0.1 eth
    uint256 public raceDuration = 2 * 1 hours;

    address payable raceMaster = address(0);

    event raceEnded(uint256 prize, address winner);
    event participantEntered(uint256 bet, address who);

    constructor() public {}

    function settleRaceIfPossible() public {
        if (
            raceStart[currentRace] + raceDuration < now ||
            raceParticipants[currentRace] >= maxParticipants
        ) {
            uint256 maxScore = 0;
            address payable winner = address(0);
            // logic to distribute prize
            for (uint256 i; i < participants[currentRace].length; i++) {
                participants[currentRace][i].score = randomNumber(i, 100).mul(99 + whitelist[participants[currentRace][i].nftContract]).div(100); // Need to check this one more
                if (participants[currentRace][i].score > maxScore) {
                    winner = participants[currentRace][i].add;
                    maxScore = participants[currentRace][i].score;
                }
            }
            currentRace = currentRace.add(1);
            winner.transfer(participants[currentRace].length.mul(entryPrice).mul(95).div(100)); //Check reentrency
            raceMaster.transfer(participants[currentRace].length.mul(entryPrice).mul(5).div(100));
            //Emit race won event
            emit raceEnded(participants[currentRace].length.mul(entryPrice).mul(95).div(100), winner);
        }
    }

    function joinRace(address _tokenAddress, uint256 _tokenId, uint256 _tokenType) public payable {
        require(msg.value > entryPrice, "Not enough ETH to participate");
        require(whitelist[_tokenAddress] > 0, "This NFT is not whitelisted");
        if (_tokenType == 725) {
            require(IERC721(_tokenAddress).ownerOf(_tokenId) == msg.sender, "You don't own the NFT");
        } else if (_tokenType == 1155) {
            require(IERC1155(_tokenAddress).balanceOf(msg.sender, _tokenId) > 0, "You don't own the NFT");
        }
        // check if nft is not already registered
        participants[currentRace].push(Participant(_tokenAddress, _tokenId, 0, msg.sender));
        settleRaceIfPossible(); // this will launch the previous race if possible
        emit participantEntered(entryPrice, msg.sender);
    }

    function getRaceInfo(uint256 raceNumber)
        public
        view
        returns (uint256 _raceNumber, uint256 _participantsCount, Participant[maxParticipants] memory _participants)
    {
        _raceNumber = raceNumber;
        _participantsCount = participants[raceNumber].length;
         for (uint256 i; i < participants[raceNumber].length; i++) {
             _participants[i] = participants[raceNumber][i];
         }
    }

    /* generates a number from 0 to 2^n based on the last n blocks */
    function randomNumber(uint256 seed, uint256 max)
        public
        view
        returns (uint256 _randomNumber)
    {
        uint256 n = 0;
        for (uint256 i = 0; i < 2; i++) {
            if (
                uint256(
                    keccak256(
                        abi.encodePacked(blockhash(block.number - i - 1), seed)
                    )
                ) %
                    2 ==
                0
            ) n += 2**i;
        }
        return n % max;
    }

    function max(uint a, uint b) private pure returns (uint) {
        return a > b ? a : b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./ERC20.sol";
import "../../utils/Pausable.sol";

/**
 * @dev ERC20 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC20Pausable is ERC20, Pausable {
    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../access/AccessControl.sol";
import "../GSN/Context.sol";
import "../token/ERC20/ERC20.sol";
import "../token/ERC20/ERC20Burnable.sol";
import "../token/ERC20/ERC20Pausable.sol";

/**
 * @dev {ERC20} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to other accounts.
 */
contract ERC20PresetMinterPauser is Context, AccessControl, ERC20Burnable, ERC20Pausable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` to the
     * account that deploys the contract.
     *
     * See {ERC20-constructor}.
     */
    constructor(string memory name, string memory symbol) public ERC20(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
    }

    /**
     * @dev Creates `amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, uint256 amount) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have minter role to mint");
        _mint(to, amount);
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have pauser role to pause");
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have pauser role to unpause");
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override(ERC20, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../../GSN/Context.sol";
import "./ERC20.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/presets/ERC20PresetMinterPauser.sol";

contract MuseToken is ERC20PresetMinterPauser {
    // Cap at 1 million
    uint256 internal _cap = 1000000000 * 10**18;

    constructor() public ERC20PresetMinterPauser("Muse", "MUSE") {}

    /**
     * @dev Returns the cap on the token's total supply.
     */
    function cap() public view returns (uint256) {
        return _cap;
    }

    // change cap in case of decided by the community
    function changeCap(uint256 _newCap) external {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "ERC20PresetMinterPauser: must have minter role to mint"
        );
        _cap = _newCap;
    }

    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - minted tokens must not cause the total supply to go over the cap.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20PresetMinterPauser) {
        super._beforeTokenTransfer(from, to, amount);

        if (from == address(0)) {
            // When minting tokens
            require(
                totalSupply().add(amount) <= _cap,
                "ERC20Capped: cap exceeded"
            );
        }
    }
}

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/presets/ERC1155PresetMinterPauser.sol";

contract NiftyAddons is ERC1155PresetMinterPauser {
    constructor(string memory uri) public ERC1155PresetMinterPauser(uri) {}
}

/*pragma solidity ^0.6.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/presets/ERC20PresetMinterPauser.sol";
import "../interfaces/IMuseToken.sol";
import "../interfaces/IVNFT.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

contract TokenizeNFT is Ownable, ERC20PresetMinterPauser {
    using SafeMath for uint256;

    IVNFT public vnft;
    IMuseToken public muse;
    uint256 public premint;
    address public creator;
    uint256 public MAXTOKENS = 20;
    uint256 public defaultGem;
    uint256 public startSale;
    uint256 public totalDays = 100;

    uint256 public currentVNFT;

    constructor(
        IVNFT _vnft,
        IMuseToken _muse,
        string memory _tokenName,
        string memory _tokenSymbol,
        address _creator,
        uint256 _premint,
        uint256 _defaultGem
    ) public ERC20PresetMinterPauser(_tokenName, _tokenSymbol) {
        vnft = _vnft;
        muse = _muse;
        creator = _creator;
        premint = _premint * 1 ether;
        defaultGem = _defaultGem;
        if (premint > 0) {
            mint(_creator, premint);
        }
        startSale = now;
        muse.approve(address(vnft), MAX_INT);
        vnft.mint(address(this));
        currentVNFT = vnft.tokenOfOwnerByIndex(address(this), vnft.balanceOf(address(this)) - 1);
    }

    function join(address _to, uint256 _times) public {
        require(_times < MAXTOKENS, "Can't whale in");
        uint256 lastTimeMined = vnft.lastTimeMined(currentVNFT);
        muse.transferFrom(
            msg.sender,
            address(this),
            vnft.itemPrice(defaultGem) * _times
        );
        uint256 index = 0;
        while (index < _times) {
            vnft.buyAccesory(currentVNFT, defaultGem);
            index = index + 1;
        }
        if (lastTimeMined + 1 days < now) {
            vnft.claimMiningRewards(currentVNFT);
            tickets = 2;
        }
        mint(_to, getJoinReturn(_times));
    }

    function getMuseValue(uint256 _quantity) public view returns (uint256) {
        uint256 reward = totalSupply().div(_quantity);
        return reward;
    }

    function getJoinReturn(uint256 _times) public pure returns (uint256) {
        uint256 daysStarted = now.sub(startSale.div(1 days));
        if (daysStarted >= totalDays) // The reward starts at toalDay (100) and decrease from 1 token everyday
        {
            return 1 * _times * 1 ether;
        } else {
            return ((totalDays - daysStarted) * 1 ether * _times);
        }
    }

    function remove(address _to, uint256 _quantity) public {
        _burn(msg.sender, _quantity);
        muse.transfer(_to, getMuseValue(_quantity));
        if (totalSupply() == 0 && vnft.isVnftAlive(currentVNFT)) {
            vnft.safeTransferFrom(address(this), msg.sender, currentVNFT);
        }
    }

    function max(uint256 a, uint256 b) private pure returns (uint256) {
        return a > b ? a : b;
    }
}*/

/*pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/introspection/IERC165.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract Roles is AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR");

    constructor() public {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(OPERATOR_ROLE, _msgSender());
    }

    modifier onlyMinter() {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "Roles: caller does not have the MINTER role"
        );
        _;
    }

    modifier onlyOperator() {
        require(
            hasRole(OPERATOR_ROLE, _msgSender()),
            "Roles: caller does not have the OPERATOR role"
        );
        _;
    }
}

interface IERC721 is IERC165 {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function mint(address to) external;
}

// Stake to get vnfts
contract Pool is Roles {
    using SafeMath for uint256;

    IERC20 public token;
    IERC20 public poolToken;

    // min $muse amount required to stake
    uint256 public minStake = 5 * 10**18;

    uint256 public totalStaked;
    bool public gameStopped = false;

    mapping(address => uint256) public balance;
    mapping(address => uint256) public lastUpdateTime;
    mapping(address => uint256) public points;

    event Staked(address who, uint256 amount);
    event Withdrawal(address who, uint256 amount);
    event VnftMinted(address to);

    event StakeReqChanged(uint256 newAmount);
    event PriceOfvnftChanged(uint256 newAmount);

    constructor(address _token, address _poolToken) public {
        poolToken = IERC20(_poolToken);
        token = IERC20(_token);
    }

    modifier notPaused() {
        require(!gameStopped, "Contract is paused");
        _;
    }

    // in case a bug happens or we upgrade to another smart contract
    function pauseGame(bool _pause) external onlyOperator {
        gameStopped = _pause;
    }

    // changes stake requirement
    function changeStakeReq(uint256 _newAmount) external onlyOperator {
        minStake = _newAmount;
        emit StakeReqChanged(_newAmount);
    }

    function changePriceOfNFT(uint256 _newAmount) external onlyOperator {
        vnftPrice = _newAmount;
        emit PriceOfvnftChanged(_newAmount);
    }

    modifier updateReward(address account) {
        if (account != address(0)) {
            points[account] = earned(account);
            lastUpdateTime[account] = block.timestamp;
        }
        _;
    }

    //calculate how many points earned so far, this needs to give roughly 1 point a day per 5 tokens staked?.
    function earned(address account) public view returns (uint256) {
        uint256 blockTime = block.timestamp;
        return
            balance[account]
                .mul(blockTime.sub(lastUpdateTime[account]).mul(2314814814000))
                .div(1e18)
                .add(points[account]);
    }

    function stake(uint256 _amount)
        external
        updateReward(msg.sender)
        notPaused
    {
        require(
            _amount >= minStake,
            "You need to stake at least the min $muse"
        );

        // transfer tokens to this address to stake them
        totalStaked = totalStaked.add(_amount);
        balance[msg.sender] = balance[msg.sender].add(_amount);
        poolToken.transferFrom(msg.sender, address(this), _amount);
        emit Staked(msg.sender, _amount);
    }

    // withdraw part of your stake
    function withdraw(uint256 amount) internal updateReward(msg.sender) {
        require(amount > 0, "Amount can't be 0");
        require(totalStaked >= amount);
        points[msg.sender] = 0;
        lastUpdateTime[msg.sender] = 0;
        balance[msg.sender] = balance[msg.sender].sub(amount);
        totalStaked = totalStaked.sub(amount);
        // transfer erc20 back from the contract to the user
        poolToken.transfer(msg.sender, amount);
        emit Withdrawal(msg.sender, amount);
    }

    // withdraw all your amount staked
    function exit() external notPaused {
        withdraw(balance[msg.sender]);
    }

    //redeem a vNFT based on a set points price
    function redeem() public updateReward(msg.sender) notPaused {
        token.transfer(msg.sender, points[msg.sender]);
        points[msg.sender] = 0;
    }
}
*/

pragma solidity ^0.6.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/introspection/IERC165Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";

// @TODO DOn't Forget!!!
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155HolderUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/utils/EnumerableSetUpgradeable.sol";

import "../interfaces/IMuseToken.sol";
import "../interfaces/IVNFT.sol";

// SPDX-License-Identifier: MIT

// Extending IERC1155 with mint and burn
interface IERC1155 is IERC165Upgradeable {
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );

    event URI(string value, uint256 indexed id);

    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;

    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function mintBatch(
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;

    function burn(
        address account,
        uint256 id,
        uint256 value
    ) external;

    function burnBatch(
        address account,
        uint256[] calldata ids,
        uint256[] calldata values
    ) external;
}

contract VNFTx is Initializable, OwnableUpgradeable, ERC1155HolderUpgradeable {
    /* START V1  STORAGE */
    using SafeMathUpgradeable for uint256;

    bool paused;

    IVNFT public vnft;
    IMuseToken public muse;
    IERC1155 public addons;

    uint256 public artistPct;

    struct Addon {
        string _type;
        uint256 price;
        uint256 requiredhp;
        uint256 rarity;
        string artistName;
        address artistAddr;
        uint256 quantity;
        uint256 used;
    }

    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    mapping(uint256 => Addon) public addon;

    mapping(uint256 => EnumerableSetUpgradeable.UintSet) private addonsConsumed;
    EnumerableSetUpgradeable.UintSet lockedAddons;

    //nftid to rarity points
    mapping(uint256 => uint256) public rarity;
    mapping(uint256 => uint256) public challengesUsed;

    //!important, decides which gem score hp is based of
    uint256 public healthGemScore;
    uint256 public healthGemId;
    uint256 public healthGemPrice;
    uint256 public healthGemDays;

    // premium hp is the min requirement for premium features.
    uint256 public premiumHp;
    uint256 public hpMultiplier;
    uint256 public rarityMultiplier;
    uint256 public addonsMultiplier;
    //expected addons to be used for max hp
    uint256 public expectedAddons;
    //Expected rarity, this should be changed according to new addons introduced.
    uint256 expectedRarity;

    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _addonId;

    /* END V1 STORAGE */

    event BuyAddon(uint256 nftId, uint256 addon, address player);
    event CreateAddon(
        uint256 addonId,
        string _type,
        uint256 rarity,
        uint256 quantity
    );
    event EditAddon(
        uint256 addonId,
        string _type,
        uint256 price,
        uint256 _quantity
    );
    event AttachAddon(uint256 addonId, uint256 nftId);
    event RemoveAddon(uint256 addonId, uint256 nftId);

    constructor() public {}

    function initialize(
        IVNFT _vnft,
        IMuseToken _muse,
        IERC1155 _addons
    ) public initializer {
        vnft = _vnft;
        muse = _muse;
        addons = _addons;
        paused = false;
        artistPct = 5;
        healthGemScore = 100;
        healthGemId = 1;
        healthGemPrice = 13 * 10**18;
        healthGemDays = 1;
        premiumHp = 90;
        hpMultiplier = 70;
        rarityMultiplier = 15;
        addonsMultiplier = 15;
        expectedAddons = 10;
        expectedRarity = 300;
        OwnableUpgradeable.__Ownable_init();
    }

    modifier tokenOwner(uint256 _id) {
        require(
            vnft.ownerOf(_id) == msg.sender,
            "You must own the vNFT to use this feature"
        );
        _;
    }

    modifier notLocked(uint256 _id) {
        require(!lockedAddons.contains(_id), "This addon is locked");
        _;
    }

    modifier notPaused() {
        require(!paused, "Contract paused!");
        _;
    }

    // get how many addons a pet is using
    function addonsBalanceOf(uint256 _nftId) public view returns (uint256) {
        return addonsConsumed[_nftId].length();
    }

    // get a specific addon
    function addonsOfNftByIndex(uint256 _nftId, uint256 _index)
        public
        view
        returns (uint256)
    {
        return addonsConsumed[_nftId].at(_index);
    }

    function getHp(uint256 _nftId) public view returns (uint256) {
        // A vnft need to get at least x score every two days to be healthy
        uint256 currentScore = vnft.vnftScore(_nftId);
        uint256 timeBorn = vnft.timeVnftBorn(_nftId);
        uint256 daysLived = (now.sub(timeBorn)).div(1 days);

        // multiply by healthy gem divided by 2 (every 2 days)
        uint256 expectedScore = daysLived.mul(
            healthGemScore.div(healthGemDays)
        );

        // get # of addons used
        uint256 addonsUsed = addonsBalanceOf(_nftId);

        if (
            !vnft.isVnftAlive(_nftId) //not dead
        ) {
            return 0;
        } else if (daysLived < 1) {
            return 70;
        }
        // here we get the % they get from score, from rarity, from used and then return based on their multiplier
        uint256 fromScore = min(currentScore.mul(100).div(expectedScore), 100);
        uint256 fromRarity = min(
            rarity[_nftId].mul(100).div(expectedRarity),
            100
        );
        uint256 fromUsed = min(addonsUsed.mul(100).div(expectedAddons), 100);
        uint256 hp = (fromRarity.mul(rarityMultiplier))
            .add(fromScore.mul(hpMultiplier))
            .add(fromUsed.mul(addonsMultiplier));

        //return hp
        if (hp > 100) {
            return 100;
        } else {
            return hp.div(100);
        }
    }

    function getChallenges(uint256 _nftId) public view returns (uint256) {
        if (vnft.level(_nftId) <= challengesUsed[_nftId]) {
            return 0;
        }

        return vnft.level(_nftId).sub(challengesUsed[_nftId]);
    }

    function buyAddon(uint256 _nftId, uint256 addonId)
        public
        tokenOwner(_nftId)
        notPaused
    {
        Addon storage _addon = addon[addonId];

        require(
            getHp(_nftId) >= _addon.requiredhp,
            "Raise your HP to buy this addon"
        );
        require(
            // @TODO double check < or <=
            _addon.used < _addon.quantity,
            "Addon not available"
        );

        _addon.used = _addon.used.add(1);

        addonsConsumed[_nftId].add(addonId);

        rarity[_nftId] = rarity[_nftId].add(_addon.rarity);

        uint256 artistCut = _addon.price.mul(artistPct).div(100);

        muse.transferFrom(msg.sender, _addon.artistAddr, artistCut);
        muse.burnFrom(msg.sender, _addon.price.sub(artistCut));
        emit BuyAddon(_nftId, addonId, msg.sender);
    }

    function useAddon(uint256 _nftId, uint256 _addonID)
        public
        tokenOwner(_nftId)
        notPaused
    {
        require(
            !addonsConsumed[_nftId].contains(_addonID),
            "Pet already has this addon"
        );
        require(
            addons.balanceOf(msg.sender, _addonID) >= 1,
            "!own the addon to use it"
        );

        Addon storage _addon = addon[_addonID];

        require(
            getHp(_nftId) >= _addon.requiredhp,
            "Raise your HP to use this addon"
        );

        // _addon.used = _addon.used.add(1);

        addonsConsumed[_nftId].add(_addonID);

        rarity[_nftId] = rarity[_nftId].add(_addon.rarity);

        addons.safeTransferFrom(msg.sender, address(this), _addonID, 1, "0x0");
        emit AttachAddon(_addonID, _nftId);
    }

    function transferAddon(
        uint256 _nftId,
        uint256 _addonID,
        uint256 _toId
    ) external tokenOwner(_nftId) notLocked(_addonID) {
        Addon storage _addon = addon[_addonID];

        require(
            getHp(_toId) >= _addon.requiredhp,
            "Receiving vNFT with no enough HP"
        );
        emit RemoveAddon(_addonID, _nftId);
        emit AttachAddon(_addonID, _toId);

        addonsConsumed[_nftId].remove(_addonID);
        rarity[_nftId] = rarity[_nftId].sub(_addon.rarity);

        addonsConsumed[_toId].add(_addonID);
        rarity[_toId] = rarity[_toId].add(_addon.rarity);
    }

    function removeAddon(uint256 _nftId, uint256 _addonID)
        public
        tokenOwner(_nftId)
        notLocked(_addonID)
    {
        // maybe can take this out for gas and the .remove would throw if no addonid on user?
        require(
            addonsConsumed[_nftId].contains(_addonID),
            "Pet doesn't have this addon"
        );
        Addon storage _addon = addon[_addonID];
        rarity[_nftId] = rarity[_nftId].sub(_addon.rarity);

        addonsConsumed[_nftId].remove(_addonID);
        emit RemoveAddon(_addonID, _nftId);

        addons.safeTransferFrom(address(this), msg.sender, _addonID, 1, "0x0");
    }

    // this is in case a dead pet addons is stuck in contract, we can use for diff cases.
    function withdraw(uint256 _id, address _to) external onlyOwner {
        addons.safeTransferFrom(address(this), _to, _id, 1, "");
    }

    function createAddon(
        string calldata _type,
        uint256 price,
        uint256 _hp,
        uint256 _rarity,
        string calldata _artistName,
        address _artist,
        uint256 _quantity,
        bool _lock
    ) external onlyOwner {
        _addonId.increment();
        uint256 newAddonId = _addonId.current();

        addon[newAddonId] = Addon(
            _type,
            price,
            _hp,
            _rarity,
            _artistName,
            _artist,
            _quantity,
            0
        );
        addons.mint(address(this), newAddonId, _quantity, "");

        if (_lock) {
            lockAddon(newAddonId);
        }

        emit CreateAddon(newAddonId, _type, _rarity, _quantity);
    }

    function getVnftInfo(uint256 _nftId)
        public
        view
        returns (
            uint256 _vNFT,
            uint256 _rarity,
            uint256 _hp,
            uint256 _addonsCount,
            uint256[10] memory _addons
        )
    {
        _vNFT = _nftId;
        _rarity = rarity[_nftId];
        _hp = getHp(_nftId);
        _addonsCount = addonsBalanceOf(_nftId);
        uint256 index = 0; // NOT FOR @JULES THIS IS HIGHLY EXPERIMENTAL NEED TO TEST
        while (index < _addonsCount && index < 10) {
            _addons[index] = (addonsConsumed[_nftId].at(index));
            index = index + 1;
        }
    }

    function editAddon(
        uint256 _id,
        string calldata _type,
        uint256 price,
        uint256 _requiredhp,
        uint256 _rarity,
        string calldata _artistName,
        address _artist,
        uint256 _quantity,
        uint256 _used,
        bool _lock
    ) external onlyOwner {
        Addon storage _addon = addon[_id];
        _addon._type = _type;
        _addon.price = price * 10**18;
        _addon.requiredhp = _requiredhp;
        _addon.rarity = _rarity;
        _addon.artistName = _artistName;
        _addon.artistAddr = _artist;
        if (_quantity > _addon.quantity) {
            addons.mint(address(this), _id, _quantity.sub(_addon.quantity), "");
        } else if (_quantity < _addon.quantity) {
            addons.burn(address(this), _id, _addon.quantity - _quantity);
        }
        _addon.quantity = _quantity;
        _addon.used = _used;

        if (_lock) {
            lockAddon(_id);
        }

        emit EditAddon(_id, _type, price, _quantity);
    }

    function lockAddon(uint256 _id) public onlyOwner {
        lockedAddons.add(_id);
    }

    function unlockAddon(uint256 _id) public onlyOwner {
        lockedAddons.remove(_id);
    }

    function setArtistPct(uint256 _newPct) external onlyOwner {
        artistPct = _newPct;
    }

    function setHealthStrat(
        uint256 _score,
        uint256 _healthGemPrice,
        uint256 _healthGemId,
        uint256 _days,
        uint256 _hpMultiplier,
        uint256 _rarityMultiplier,
        uint256 _expectedAddons,
        uint256 _addonsMultiplier,
        uint256 _expectedRarity,
        uint256 _premiumHp
    ) external onlyOwner {
        healthGemScore = _score;
        healthGemPrice = _healthGemPrice;
        healthGemId = _healthGemId;
        healthGemDays = _days;
        hpMultiplier = _hpMultiplier;
        rarityMultiplier = _rarityMultiplier;
        expectedAddons = _expectedAddons;
        addonsMultiplier = _addonsMultiplier;
        expectedRarity = _expectedRarity;
        premiumHp = _premiumHp;
    }

    function pause(bool _paused) public onlyOwner {
        paused = _paused;
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.24 <0.7.0;


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
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../GSN/ContextUpgradeable.sol";
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
contract OwnableUpgradeable is Initializable, ContextUpgradeable {
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
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

pragma solidity ^0.6.0;

import "../math/SafeMathUpgradeable.sol";

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library CountersUpgradeable {
    using SafeMathUpgradeable for uint256;

    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
library SafeMathUpgradeable {
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
     *
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./ERC1155ReceiverUpgradeable.sol";
import "../../proxy/Initializable.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155HolderUpgradeable is Initializable, ERC1155ReceiverUpgradeable {
    function __ERC1155Holder_init() internal initializer {
        __ERC165_init_unchained();
        __ERC1155Receiver_init_unchained();
        __ERC1155Holder_init_unchained();
    }

    function __ERC1155Holder_init_unchained() internal initializer {
    }
    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.0.0, only sets of type `address` (`AddressSet`) and `uint256`
 * (`UintSet`) are supported.
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

pragma solidity ^0.6.0;

// Interface for our erc20 token
interface IMuseToken {
    function totalSupply() external view returns (uint256);

    function balanceOf(address tokenOwner)
        external
        view
        returns (uint256 balance);

    function allowance(address tokenOwner, address spender)
        external
        view
        returns (uint256 remaining);

    function transfer(address to, uint256 tokens)
        external
        returns (bool success);

    function approve(address spender, uint256 tokens)
        external
        returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) external returns (bool success);

    function mintingFinished() external view returns (bool);

    function mint(address to, uint256 amount) external;

    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
}

pragma solidity ^0.6.0;

// import "@openzeppelin/contracts/introspection/IERC165.sol";

interface IVNFT {
    // function ownerOf(uint256 _tokenId) external view returns (address _owner);

    function balanceOf(address owner) external view returns (uint256 balance);

    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256 id);

    function totalSupply() external view returns (uint256);

    function fatality(uint256 _deadId, uint256 _tokenId) external;

    function buyAccesory(uint256 nftId, uint256 itemId) external;

    function claimMiningRewards(uint256 nftId) external;

    function addCareTaker(uint256 _tokenId, address _careTaker) external;

    function careTaker(uint256 _tokenId, address _user)
        external
        view
        returns (address _careTaker);

    function ownerOf(uint256 _tokenId) external view returns (address _owner);

    function itemPrice(uint256 itemId) external view returns (uint256 _amount);

    function getRewards(uint256 tokenId) external view returns (uint256);

    function isVnftAlive(uint256 _nftId) external view returns (bool);

    function level(uint256 tokenId) external view returns (uint256);

    function timeUntilStarving(uint256 _tokenId)
        external
        view
        returns (uint256 _time);

    function lastTimeMined(uint256 _tokenId)
        external
        view
        returns (uint256 _time);

    function getVnftInfo(uint256 _nftId)
        external
        view
        returns (
            uint256 _vNFT,
            bool _isAlive,
            uint256 _score,
            uint256 _level,
            uint256 _expectedReward,
            uint256 _timeUntilStarving,
            uint256 _lastTimeMined,
            uint256 _timeVnftBorn,
            address _owner,
            address _token,
            uint256 _tokenId,
            uint256 _fatalityReward
        );

    function vnftScore(uint256 _tokenId) external view returns (uint256 _score);

    function vnftScore(
        uint256 _tokenId,
        address //TODO What is this one?
    ) external view returns (uint256 _score);

    function timeVnftBorn(uint256 _tokenId)
        external
        view
        returns (uint256 _born);

    function mint(address to) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
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

pragma solidity ^0.6.0;

import "./IERC1155ReceiverUpgradeable.sol";
import "../../introspection/ERC165Upgradeable.sol";
import "../../proxy/Initializable.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155ReceiverUpgradeable is Initializable, ERC165Upgradeable, IERC1155ReceiverUpgradeable {
    function __ERC1155Receiver_init() internal initializer {
        __ERC165_init_unchained();
        __ERC1155Receiver_init_unchained();
    }

    function __ERC1155Receiver_init_unchained() internal initializer {
        _registerInterface(
            ERC1155ReceiverUpgradeable(0).onERC1155Received.selector ^
            ERC1155ReceiverUpgradeable(0).onERC1155BatchReceived.selector
        );
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../../introspection/IERC165Upgradeable.sol";

/**
 * _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {

    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        returns(bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        returns(bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./IERC165Upgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
    uint256[49] private __gap;
}

pragma solidity ^0.6.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/introspection/IERC165Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";

// @TODO DOn't Forget!!!
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155HolderUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/utils/EnumerableSetUpgradeable.sol";

import "../interfaces/IMuseToken.sol";
import "../interfaces/IVNFT.sol";

// SPDX-License-Identifier: MIT

// Extending IERC1155 with mint and burn
interface IERC1155 is IERC165Upgradeable {
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );

    event URI(string value, uint256 indexed id);

    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;

    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function mintBatch(
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;

    function burn(
        address account,
        uint256 id,
        uint256 value
    ) external;

    function burnBatch(
        address account,
        uint256[] calldata ids,
        uint256[] calldata values
    ) external;
}

contract VNFTxV5 is
    Initializable,
    OwnableUpgradeable,
    ERC1155HolderUpgradeable
{
    /* START V1  STORAGE */
    using SafeMathUpgradeable for uint256;

    bool paused;

    IVNFT public vnft;
    IMuseToken public muse;
    IERC1155 public addons;

    uint256 public artistPct;

    struct Addon {
        string _type;
        uint256 price;
        uint256 requiredhp;
        uint256 rarity;
        string artistName;
        address artistAddr;
        uint256 quantity;
        uint256 used;
    }

    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    mapping(uint256 => Addon) public addon;

    mapping(uint256 => EnumerableSetUpgradeable.UintSet) private addonsConsumed;
    EnumerableSetUpgradeable.UintSet lockedAddons;

    //nftid to rarity points
    mapping(uint256 => uint256) public rarity;
    mapping(uint256 => uint256) public challengesUsed;

    //!important, decides which gem score hp is based of
    uint256 public healthGemScore;
    uint256 public healthGemId;
    uint256 public healthGemPrice;
    uint256 public healthGemDays;

    // premium hp is the min requirement for premium features.
    uint256 public premiumHp;
    uint256 public hpMultiplier;
    uint256 public rarityMultiplier;
    uint256 public addonsMultiplier;
    //expected addons to be used for max hp
    uint256 public expectedAddons;
    //Expected rarity, this should be changed according to new addons introduced.
    uint256 expectedRarity;

    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _addonId;

    /* END V1 STORAGE */

    uint256 cashbackPct;

    event BuyAddon(uint256 nftId, uint256 addon, address player);
    event CreateAddon(
        uint256 addonId,
        string _type,
        uint256 rarity,
        uint256 quantity
    );
    event EditAddon(
        uint256 addonId,
        string _type,
        uint256 price,
        uint256 _quantity
    );
    event AttachAddon(uint256 addonId, uint256 nftId);
    event RemoveAddon(uint256 addonId, uint256 nftId);

    /* EnD OF v3 Storage */

    mapping(uint256 => uint256) public hpLostOnBattle;
    mapping(uint256 => uint256) public timesAttacked;

    mapping(address => uint256) public toReceiveCashback;
    mapping(uint256 => uint256) private alreadyReceivedCashback;

    event Cashback(uint256 nft, uint256 amount);
    event Battle(uint256 winner, uint256 loser, uint256 museWon);

    /*
     ** END OF V4 STORAGE
     */

    mapping(uint256 => uint256) private petAlreadyReceivedCashback;

    constructor() public {}

    // function initialize(
    //     IVNFT _vnft,
    //     IMuseToken _muse,
    //     IERC1155 _addons
    // ) public initializer {
    //     vnft = _vnft;
    //     muse = _muse;
    //     addons = _addons;
    //     paused = false;
    //     artistPct = 5;
    //     healthGemScore = 100;
    //     healthGemId = 1;
    //     healthGemPrice = 13 * 10**18;
    //     healthGemDays = 1;
    //     premiumHp = 90;
    //     hpMultiplier = 70;
    //     rarityMultiplier = 15;
    //     addonsMultiplier = 15;
    //     expectedAddons = 10;
    //     expectedRarity = 300;
    //     OwnableUpgradeable.__Ownable_init();
    //     cashbackPct = 40;
    // }

    modifier tokenOwner(uint256 _id) {
        require(
            vnft.ownerOf(_id) == msg.sender,
            "3" //You must own the vNFT to use this feature
        );
        _;
    }

    modifier notLocked(uint256 _id) {
        require(!lockedAddons.contains(_id), "1"); //This addon is locked
        _;
    }

    modifier containsAddon(uint256 nftId, uint256 addonId) {
        require(addonsConsumed[nftId].contains(addonId), "fail");
        _;
    }
    modifier notPaused() {
        require(!paused, "2"); //Contract paused!
        _;
    }

    // get how many addons a pet is using
    function addonsBalanceOf(uint256 _nftId) public view returns (uint256) {
        return addonsConsumed[_nftId].length();
    }

    // get a specific addon
    function addonsOfNftByIndex(uint256 _nftId, uint256 _index)
        public
        view
        returns (uint256)
    {
        return addonsConsumed[_nftId].at(_index);
    }

    function getHp(uint256 _nftId) public view returns (uint256) {
        // A vnft need to get at least x score every two days to be healthy
        uint256 currentScore = vnft.vnftScore(_nftId);

        uint256 daysLived = getDaysLived(_nftId);

        // multiply by healthy gem divided by 2 (every 2 days)
        uint256 expectedScore = daysLived
            .mul(healthGemScore.div(healthGemDays))
            .add(hpLostOnBattle[_nftId]);

        // get # of addons used
        uint256 addonsUsed = addonsBalanceOf(_nftId);

        if (
            !vnft.isVnftAlive(_nftId) //not dead
        ) {
            return 0;
        } else if (daysLived < 1) {
            return 70;
        }
        // here we get the % they get from score, from rarity, from used and then return based on their multiplier
        uint256 fromScore = min(currentScore.mul(100).div(expectedScore), 100);
        uint256 fromRarity = min(
            rarity[_nftId].mul(100).div(expectedRarity),
            100
        );
        uint256 fromUsed = min(addonsUsed.mul(100).div(expectedAddons), 100);
        uint256 hp = (fromRarity.mul(rarityMultiplier))
            .add(fromScore.mul(hpMultiplier))
            .add(fromUsed.mul(addonsMultiplier));

        return min(hp.div(100), 100);
    }

    function getChallenges(uint256 _nftId) public view returns (uint256) {
        if (vnft.level(_nftId) <= challengesUsed[_nftId]) {
            return 0;
        }

        return vnft.level(_nftId).sub(challengesUsed[_nftId]);
    }

    function buyAddon(uint256 _nftId, uint256 addonId)
        public
        tokenOwner(_nftId)
        notPaused()
    {
        Addon storage _addon = addon[addonId];

        require(!addonsConsumed[_nftId].contains(addonId), "4"); // Pet already has this addon

        require(getHp(_nftId) >= _addon.requiredhp, "5"); // Pet already has this addon
        require(
            _addon.used < _addon.quantity &&
                addons.balanceOf(address(this), addonId) >= 1,
            "6"
        ); //Addon not available

        _addon.used = _addon.used.add(1);

        addonsConsumed[_nftId].add(addonId);

        rarity[_nftId] = rarity[_nftId].add(_addon.rarity);

        uint256 artistCut = _addon.price.mul(artistPct).div(100);

        muse.transferFrom(msg.sender, _addon.artistAddr, artistCut);
        muse.burnFrom(msg.sender, _addon.price.sub(artistCut));
        emit BuyAddon(_nftId, addonId, msg.sender);
    }

    function useAddon(uint256 _nftId, uint256 _addonID)
        public
        tokenOwner(_nftId)
        notPaused()
    {
        require(!addonsConsumed[_nftId].contains(_addonID), "4"); // Pet already has this addon
        require(addons.balanceOf(msg.sender, _addonID) >= 1, "7"); //own the addon to use it

        Addon storage _addon = addon[_addonID];

        require(getHp(_nftId) >= _addon.requiredhp, "8"); // Raise your HP to use this addon

        addonsConsumed[_nftId].add(_addonID);

        rarity[_nftId] = rarity[_nftId].add(_addon.rarity);

        addons.safeTransferFrom(msg.sender, address(this), _addonID, 1, "");
        emit AttachAddon(_addonID, _nftId);
    }

    function removeAddon(uint256 _nftId, uint256 _addonID)
        public
        tokenOwner(_nftId)
        notLocked(_addonID)
        containsAddon(_nftId, _addonID)
    {
        Addon storage _addon = addon[_addonID];
        rarity[_nftId] = rarity[_nftId].sub(_addon.rarity);

        addonsConsumed[_nftId].remove(_addonID);
        emit RemoveAddon(_addonID, _nftId);

        addons.safeTransferFrom(address(this), msg.sender, _addonID, 1, "");
    }

    function getDaysLived(uint256 _nftId) public view returns (uint256) {
        return (now - vnft.timeVnftBorn(_nftId)) / 1 days;
    }

    function getAttackInfo(uint256 _nftId, uint256 _opponent)
        public
        view
        returns (
            uint256 oponentHp,
            uint256 attackerHp,
            uint256 successPercent,
            uint256 estimatedReward
        )
    {
        oponentHp = getHp(_opponent);
        attackerHp = getHp(_nftId);
        // The percentage of attack is weighted between your HP and the pet HP
        // in the case where oponent as 20HP and attacker has 100
        // the chance of winning is 3 times your HP: 3*100 out of 320 (sum of both HP and attacker hp*3)
        successPercent = attackerHp.mul(3).mul(100).div(
            oponentHp.add(attackerHp.mul(3))
        );

        estimatedReward = vnft
            .level(_nftId)
            .add(vnft.level(_opponent))
            .mul(10)
            .div(100);
        if (estimatedReward <= 4) {
            estimatedReward = 4;
        }
    }

    // kill them all
    function battle(uint256 _nftId, uint256 _opponent)
        public
        tokenOwner(_nftId)
        containsAddon(_nftId, 4)
        notPaused()
    {
        (
            uint256 oponentHp,
            uint256 attackerHp,
            uint256 successPercent,

        ) = getAttackInfo(_nftId, _opponent);

        require(vnft.ownerOf(_opponent) != msg.sender, "A"); // Can't atack yourself

        // require x challenges and x hp or xx rarity for battles
        require(
            getChallenges(_nftId) >= 1 && attackerHp >= 70, //decide
            "D"
        ); // can't challenge

        require(timesAttacked[_opponent] <= 10, "E"); // This pet was attacked 10 times already

        // require opponent to be of certain threshold 30?
        require(oponentHp <= 90, "F"); // You can't attack this pet

        challengesUsed[_nftId] = challengesUsed[_nftId] + 1;
        timesAttacked[_opponent] = timesAttacked[_opponent] + 1;

        //decide winner
        uint256 loser;
        uint256 winner;

        if (randomNumber(_nftId + _opponent, 100) > successPercent) {
            loser = _nftId;
            winner = _opponent;
        } else {
            loser = _opponent;
            winner = _nftId;
        }

        // then do all calcs based on winner, could be opponent or nftid
        if (getHp(loser) < 20) {
            // need 6 health gem score more to to expected score
            hpLostOnBattle[loser] = hpLostOnBattle[loser].add(
                healthGemScore * 6
            );
        } else if (getHp(loser) >= 20) {
            // need 3 health gem score more to to expected score
            hpLostOnBattle[loser] = hpLostOnBattle[loser].add(
                healthGemScore * 3
            );
        }
        uint256 museWon = 0;
        if (winner == _nftId) {
            // get 15% of level in muse
            museWon = (vnft.level(winner).add(vnft.level(loser)).mul(10)) / 100;
            if (museWon <= 4) {
                museWon = 4;
            }
            muse.mint(vnft.ownerOf(winner), museWon * 10**18);
        }

        emit Battle(winner, loser, museWon);
    }

    function cashback(uint256 _nftId)
        external
        tokenOwner(_nftId)
        containsAddon(_nftId, 1)
        notPaused()
    {
        //    have premium hp
        require(getHp(_nftId) >= premiumHp, "H"); // Raise your hp to claim cashback
        // didn't get cashback in last 7 days or first time (0)
        require(
            (toReceiveCashback[msg.sender] <= block.timestamp &&
                petAlreadyReceivedCashback[_nftId] <= block.timestamp) ||
                (toReceiveCashback[msg.sender] == 0 &&
                    petAlreadyReceivedCashback[_nftId] == 0),
            "I"
        ); // You can't claim cahsback yet

        petAlreadyReceivedCashback[_nftId] = block.timestamp.add(7 days);

        uint256 currentScore = vnft.vnftScore(_nftId);

        uint256 daysLived = getDaysLived(_nftId);

        require(daysLived >= 14, "J"); // Lived at least 14 days for cashback

        uint256 expectedScore = daysLived.mul(
            healthGemScore.div(healthGemDays)
        );

        uint256 fromScore = min(currentScore.mul(100).div(expectedScore), 100);

        uint256 museSpent = healthGemPrice.mul(7).mul(fromScore).div(100);

        uint256 cashbackAmt = museSpent.mul(cashbackPct).div(100);

        muse.mint(msg.sender, cashbackAmt);

        alreadyReceivedCashback[_nftId] = alreadyReceivedCashback[_nftId].add(
            cashbackAmt
        );

        emit Cashback(_nftId, cashbackAmt);
    }

    // this is in case a dead pet addons is stuck in contract, we can use for diff cases.
    function withdraw(uint256 _id, address _to) external onlyOwner {
        addons.safeTransferFrom(address(this), _to, _id, 1, "");
    }

    function createAddon(
        string calldata _type,
        uint256 price,
        uint256 _hp,
        uint256 _rarity,
        string calldata _artistName,
        address _artist,
        uint256 _quantity,
        bool _lock
    ) external onlyOwner {
        _addonId.increment();
        uint256 newAddonId = _addonId.current();

        addon[newAddonId] = Addon(
            _type,
            price,
            _hp,
            _rarity,
            _artistName,
            _artist,
            _quantity,
            0
        );
        addons.mint(address(this), newAddonId, _quantity, "");

        if (_lock) {
            lockAddon(newAddonId);
        }

        emit CreateAddon(newAddonId, _type, _rarity, _quantity);
    }

    function getVnftInfo(uint256 _nftId)
        public
        view
        returns (
            uint256 _vNFT,
            uint256 _rarity,
            uint256 _hp,
            uint256 _addonsCount,
            uint256[10] memory _addons
        )
    {
        _vNFT = _nftId;
        _rarity = rarity[_nftId];
        _hp = getHp(_nftId);
        _addonsCount = addonsBalanceOf(_nftId);
        uint256 index = 0;
        while (index < _addonsCount && index < 10) {
            _addons[index] = (addonsConsumed[_nftId].at(index));
            index = index + 1;
        }
    }

    function editAddon(
        uint256 _id,
        string calldata _type,
        uint256 price,
        uint256 _requiredhp,
        uint256 _rarity,
        string calldata _artistName,
        address _artist,
        uint256 _quantity,
        uint256 _used,
        bool _lock
    ) external onlyOwner {
        Addon storage _addon = addon[_id];
        _addon._type = _type;
        _addon.price = price * 10**18;
        _addon.requiredhp = _requiredhp;
        _addon.rarity = _rarity;
        _addon.artistName = _artistName;
        _addon.artistAddr = _artist;
        if (_quantity > _addon.quantity) {
            addons.mint(address(this), _id, _quantity.sub(_addon.quantity), "");
        } else if (_quantity < _addon.quantity) {
            addons.burn(address(this), _id, _addon.quantity - _quantity);
        }
        _addon.quantity = _quantity;
        _addon.used = _used;

        if (_lock) {
            lockAddon(_id);
        }

        emit EditAddon(_id, _type, price, _quantity);
    }

    function lockAddon(uint256 _id) public onlyOwner {
        lockedAddons.add(_id);
    }

    function setHealthStrat(
        uint256 _score,
        uint256 _healthGemPrice,
        uint256 _healthGemId,
        uint256 _days,
        uint256 _hpMultiplier,
        uint256 _rarityMultiplier,
        uint256 _expectedAddons,
        uint256 _addonsMultiplier,
        uint256 _expectedRarity,
        uint256 _premiumHp,
        uint256 _cashbackPct
    ) external onlyOwner {
        healthGemScore = _score;
        healthGemPrice = _healthGemPrice;
        healthGemId = _healthGemId;
        healthGemDays = _days;
        hpMultiplier = _hpMultiplier;
        rarityMultiplier = _rarityMultiplier;
        expectedAddons = _expectedAddons;
        addonsMultiplier = _addonsMultiplier;
        expectedRarity = _expectedRarity;
        premiumHp = _premiumHp;
        cashbackPct = _cashbackPct;
    }

    function pause(bool _paused) public onlyOwner {
        paused = _paused;
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    /* generates a number from 0 to 2^n based on the last n blocks */
    function randomNumber(uint256 seed, uint256 max)
        public
        view
        returns (uint256 _randomNumber)
    {
        uint256 n = 0;
        for (uint256 i = 0; i < 5; i++) {
            n += uint256(
                keccak256(
                    abi.encodePacked(blockhash(block.number - i - 1), seed)
                )
            );
        }
        return (n * seed) % max;
    }
}

pragma solidity ^0.6.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/introspection/IERC165Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";

// @TODO DOn't Forget!!!
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155HolderUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/utils/EnumerableSetUpgradeable.sol";

import "../interfaces/IMuseToken.sol";
import "../interfaces/IVNFT.sol";

// SPDX-License-Identifier: MIT

// Extending IERC1155 with mint and burn
interface IERC1155 is IERC165Upgradeable {
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );

    event URI(string value, uint256 indexed id);

    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;

    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function mintBatch(
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;

    function burn(
        address account,
        uint256 id,
        uint256 value
    ) external;

    function burnBatch(
        address account,
        uint256[] calldata ids,
        uint256[] calldata values
    ) external;
}

contract VNFTxV4 is
    Initializable,
    OwnableUpgradeable,
    ERC1155HolderUpgradeable
{
    /* START V1  STORAGE */
    using SafeMathUpgradeable for uint256;

    bool paused;

    IVNFT public vnft;
    IMuseToken public muse;
    IERC1155 public addons;

    uint256 public artistPct;

    struct Addon {
        string _type;
        uint256 price;
        uint256 requiredhp;
        uint256 rarity;
        string artistName;
        address artistAddr;
        uint256 quantity;
        uint256 used;
    }

    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    mapping(uint256 => Addon) public addon;

    mapping(uint256 => EnumerableSetUpgradeable.UintSet) private addonsConsumed;
    EnumerableSetUpgradeable.UintSet lockedAddons;

    //nftid to rarity points
    mapping(uint256 => uint256) public rarity;
    mapping(uint256 => uint256) public challengesUsed;

    //!important, decides which gem score hp is based of
    uint256 public healthGemScore;
    uint256 public healthGemId;
    uint256 public healthGemPrice;
    uint256 public healthGemDays;

    // premium hp is the min requirement for premium features.
    uint256 public premiumHp;
    uint256 public hpMultiplier;
    uint256 public rarityMultiplier;
    uint256 public addonsMultiplier;
    //expected addons to be used for max hp
    uint256 public expectedAddons;
    //Expected rarity, this should be changed according to new addons introduced.
    uint256 expectedRarity;

    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _addonId;

    /* END V1 STORAGE */

    uint256 cashbackPct;

    event BuyAddon(uint256 nftId, uint256 addon, address player);
    event CreateAddon(
        uint256 addonId,
        string _type,
        uint256 rarity,
        uint256 quantity
    );
    event EditAddon(
        uint256 addonId,
        string _type,
        uint256 price,
        uint256 _quantity
    );
    event AttachAddon(uint256 addonId, uint256 nftId);
    event RemoveAddon(uint256 addonId, uint256 nftId);

    /* EnD OF v3 Storage */

    mapping(uint256 => uint256) public hpLostOnBattle;
    mapping(uint256 => uint256) public timesAttacked;

    mapping(address => uint256) public toReceiveCashback;
    mapping(uint256 => uint256) private alreadyReceivedCashback;

    event Cashback(uint256 nft, uint256 amount);
    event Battle(uint256 winner, uint256 loser, uint256 museWon);

    /*
     ** END OF V4 STORAGE
     */

    constructor() public {}

    modifier tokenOwner(uint256 _id) {
        require(
            vnft.ownerOf(_id) == msg.sender,
            "3" //You must own the vNFT to use this feature
        );
        _;
    }

    modifier notLocked(uint256 _id) {
        require(!lockedAddons.contains(_id), "1"); //This addon is locked
        _;
    }

    modifier containsAddon(uint256 nftId, uint256 addonId) {
        require(addonsConsumed[nftId].contains(addonId), "fail");
        _;
    }
    modifier notPaused() {
        require(!paused, "2"); //Contract paused!
        _;
    }

    // get how many addons a pet is using
    function addonsBalanceOf(uint256 _nftId) public view returns (uint256) {
        return addonsConsumed[_nftId].length();
    }

    // get a specific addon
    function addonsOfNftByIndex(uint256 _nftId, uint256 _index)
        public
        view
        returns (uint256)
    {
        return addonsConsumed[_nftId].at(_index);
    }

    function getHp(uint256 _nftId) public view returns (uint256) {
        // A vnft need to get at least x score every two days to be healthy
        uint256 currentScore = vnft.vnftScore(_nftId);

        uint256 daysLived = getDaysLived(_nftId);

        // multiply by healthy gem divided by 2 (every 2 days)
        uint256 expectedScore = daysLived
            .mul(healthGemScore.div(healthGemDays))
            .add(hpLostOnBattle[_nftId]);

        // get # of addons used
        uint256 addonsUsed = addonsBalanceOf(_nftId);

        if (
            !vnft.isVnftAlive(_nftId) //not dead
        ) {
            return 0;
        } else if (daysLived < 1) {
            return 70;
        }
        // here we get the % they get from score, from rarity, from used and then return based on their multiplier
        uint256 fromScore = min(currentScore.mul(100).div(expectedScore), 100);
        uint256 fromRarity = min(
            rarity[_nftId].mul(100).div(expectedRarity),
            100
        );
        uint256 fromUsed = min(addonsUsed.mul(100).div(expectedAddons), 100);
        uint256 hp = (fromRarity.mul(rarityMultiplier))
            .add(fromScore.mul(hpMultiplier))
            .add(fromUsed.mul(addonsMultiplier));

        return min(hp.div(100), 100);
    }

    function getChallenges(uint256 _nftId) public view returns (uint256) {
        if (vnft.level(_nftId) <= challengesUsed[_nftId]) {
            return 0;
        }

        return vnft.level(_nftId).sub(challengesUsed[_nftId]);
    }

    function buyAddon(uint256 _nftId, uint256 addonId)
        public
        tokenOwner(_nftId)
        notPaused()
    {
        Addon storage _addon = addon[addonId];

        require(!addonsConsumed[_nftId].contains(addonId), "4"); // Pet already has this addon

        require(getHp(_nftId) >= _addon.requiredhp, "5"); // Pet already has this addon
        require(
            _addon.used < _addon.quantity &&
                addons.balanceOf(address(this), addonId) >= 1,
            "6"
        ); //Addon not available

        _addon.used = _addon.used.add(1);

        addonsConsumed[_nftId].add(addonId);

        rarity[_nftId] = rarity[_nftId].add(_addon.rarity);

        uint256 artistCut = _addon.price.mul(artistPct).div(100);

        muse.transferFrom(msg.sender, _addon.artistAddr, artistCut);
        muse.burnFrom(msg.sender, _addon.price.sub(artistCut));
        emit BuyAddon(_nftId, addonId, msg.sender);
    }

    function useAddon(uint256 _nftId, uint256 _addonID)
        public
        tokenOwner(_nftId)
        notPaused()
    {
        require(!addonsConsumed[_nftId].contains(_addonID), "4"); // Pet already has this addon
        require(addons.balanceOf(msg.sender, _addonID) >= 1, "7"); //own the addon to use it

        Addon storage _addon = addon[_addonID];

        require(getHp(_nftId) >= _addon.requiredhp, "8"); // Raise your HP to use this addon

        addonsConsumed[_nftId].add(_addonID);

        rarity[_nftId] = rarity[_nftId].add(_addon.rarity);

        addons.safeTransferFrom(msg.sender, address(this), _addonID, 1, "");
        emit AttachAddon(_addonID, _nftId);
    }

    function removeAddon(uint256 _nftId, uint256 _addonID)
        public
        tokenOwner(_nftId)
        notLocked(_addonID)
        containsAddon(_nftId, _addonID)
    {
        Addon storage _addon = addon[_addonID];
        rarity[_nftId] = rarity[_nftId].sub(_addon.rarity);

        addonsConsumed[_nftId].remove(_addonID);
        emit RemoveAddon(_addonID, _nftId);

        addons.safeTransferFrom(address(this), msg.sender, _addonID, 1, "");
    }

    function getDaysLived(uint256 _nftId) public view returns (uint256) {
        return (now - vnft.timeVnftBorn(_nftId)) / 1 days;
    }

    function getAttackInfo(uint256 _nftId, uint256 _opponent)
        public
        view
        returns (
            uint256 oponentHp,
            uint256 attackerHp,
            uint256 successPercent,
            uint256 estimatedReward
        )
    {
        oponentHp = getHp(_opponent);
        attackerHp = getHp(_nftId);
        // The percentage of attack is weighted between your HP and the pet HP
        // in the case where oponent as 20HP and attacker has 100
        // the chance of winning is 3 times your HP: 3*100 out of 320 (sum of both HP and attacker hp*3)
        successPercent = attackerHp.mul(3).mul(100).div(
            oponentHp.add(attackerHp.mul(3))
        );

        estimatedReward = vnft
            .level(_nftId)
            .add(vnft.level(_opponent))
            .mul(10)
            .div(100);
        if (estimatedReward <= 4) {
            estimatedReward = 4;
        }
    }

    // kill them all
    function battle(uint256 _nftId, uint256 _opponent)
        public
        tokenOwner(_nftId)
        containsAddon(_nftId, 4)
        notPaused()
    {
        (
            uint256 oponentHp,
            uint256 attackerHp,
            uint256 successPercent,

        ) = getAttackInfo(_nftId, _opponent);

        require(vnft.ownerOf(_opponent) != msg.sender, "A"); // Can't atack yourself

        // require x challenges and x hp or xx rarity for battles
        require(
            getChallenges(_nftId) >= 1 && attackerHp >= 70, //decide
            "D"
        ); // can't challenge

        require(timesAttacked[_opponent] <= 10, "E"); // This pet was attacked 10 times already

        // require opponent to be of certain threshold 30?
        require(oponentHp <= 90, "F"); // You can't attack this pet

        challengesUsed[_nftId] = challengesUsed[_nftId] + 1;
        timesAttacked[_opponent] = timesAttacked[_opponent] + 1;

        //decide winner
        uint256 loser;
        uint256 winner;

        if (randomNumber(_nftId + _opponent, 100) > successPercent) {
            loser = _nftId;
            winner = _opponent;
        } else {
            loser = _opponent;
            winner = _nftId;
        }

        // then do all calcs based on winner, could be opponent or nftid
        if (getHp(loser) < 20) {
            // need 6 health gem score more to to expected score
            hpLostOnBattle[loser] = hpLostOnBattle[loser].add(
                healthGemScore * 6
            );
        } else if (getHp(loser) >= 20) {
            // need 3 health gem score more to to expected score
            hpLostOnBattle[loser] = hpLostOnBattle[loser].add(
                healthGemScore * 3
            );
        }
        uint256 museWon = 0;
        if (winner == _nftId) {
            // get 15% of level in muse
            museWon = (vnft.level(winner).add(vnft.level(loser)).mul(10)) / 100;
            if (museWon <= 4) {
                museWon = 4;
            }
            muse.mint(vnft.ownerOf(winner), museWon * 10**18);
        }

        emit Battle(winner, loser, museWon);
    }

    function cashback(uint256 _nftId)
        external
        tokenOwner(_nftId)
        containsAddon(_nftId, 1)
        notPaused()
    {
        //    have premium hp
        require(getHp(_nftId) >= premiumHp, "H"); // Raise your hp to claim cashback
        // didn't get cashback in last 7 days or first time (0)
        require(
            toReceiveCashback[msg.sender] <= block.timestamp ||
                toReceiveCashback[msg.sender] == 0,
            "I"
        ); // You can't claim cahsback yet

        toReceiveCashback[msg.sender] = block.timestamp.add(7 days);

        uint256 currentScore = vnft.vnftScore(_nftId);

        uint256 daysLived = getDaysLived(_nftId);

        require(daysLived >= 14, "J"); // Lived at least 14 days for cashback

        uint256 expectedScore = daysLived.mul(
            healthGemScore.div(healthGemDays)
        );

        uint256 fromScore = min(currentScore.mul(100).div(expectedScore), 100);

        uint256 museSpent = healthGemPrice.mul(7).mul(fromScore).div(100);

        uint256 cashbackAmt = museSpent.mul(cashbackPct).div(100);

        muse.mint(msg.sender, cashbackAmt);

        alreadyReceivedCashback[_nftId] = alreadyReceivedCashback[_nftId].add(
            cashbackAmt
        );

        emit Cashback(_nftId, cashbackAmt);
    }

    // this is in case a dead pet addons is stuck in contract, we can use for diff cases.
    function withdraw(uint256 _id, address _to) external onlyOwner {
        addons.safeTransferFrom(address(this), _to, _id, 1, "");
    }

    function createAddon(
        string calldata _type,
        uint256 price,
        uint256 _hp,
        uint256 _rarity,
        string calldata _artistName,
        address _artist,
        uint256 _quantity,
        bool _lock
    ) external onlyOwner {
        _addonId.increment();
        uint256 newAddonId = _addonId.current();

        addon[newAddonId] = Addon(
            _type,
            price,
            _hp,
            _rarity,
            _artistName,
            _artist,
            _quantity,
            0
        );
        addons.mint(address(this), newAddonId, _quantity, "");

        if (_lock) {
            lockAddon(newAddonId);
        }

        emit CreateAddon(newAddonId, _type, _rarity, _quantity);
    }

    function getVnftInfo(uint256 _nftId)
        public
        view
        returns (
            uint256 _vNFT,
            uint256 _rarity,
            uint256 _hp,
            uint256 _addonsCount,
            uint256[10] memory _addons
        )
    {
        _vNFT = _nftId;
        _rarity = rarity[_nftId];
        _hp = getHp(_nftId);
        _addonsCount = addonsBalanceOf(_nftId);
        uint256 index = 0;
        while (index < _addonsCount && index < 10) {
            _addons[index] = (addonsConsumed[_nftId].at(index));
            index = index + 1;
        }
    }

    function editAddon(
        uint256 _id,
        string calldata _type,
        uint256 price,
        uint256 _requiredhp,
        uint256 _rarity,
        string calldata _artistName,
        address _artist,
        uint256 _quantity,
        uint256 _used,
        bool _lock
    ) external onlyOwner {
        Addon storage _addon = addon[_id];
        _addon._type = _type;
        _addon.price = price * 10**18;
        _addon.requiredhp = _requiredhp;
        _addon.rarity = _rarity;
        _addon.artistName = _artistName;
        _addon.artistAddr = _artist;
        if (_quantity > _addon.quantity) {
            addons.mint(address(this), _id, _quantity.sub(_addon.quantity), "");
        } else if (_quantity < _addon.quantity) {
            addons.burn(address(this), _id, _addon.quantity - _quantity);
        }
        _addon.quantity = _quantity;
        _addon.used = _used;

        if (_lock) {
            lockAddon(_id);
        }

        emit EditAddon(_id, _type, price, _quantity);
    }

    function lockAddon(uint256 _id) public onlyOwner {
        lockedAddons.add(_id);
    }

    function setHealthStrat(
        uint256 _score,
        uint256 _healthGemPrice,
        uint256 _healthGemId,
        uint256 _days,
        uint256 _hpMultiplier,
        uint256 _rarityMultiplier,
        uint256 _expectedAddons,
        uint256 _addonsMultiplier,
        uint256 _expectedRarity,
        uint256 _premiumHp,
        uint256 _cashbackPct
    ) external onlyOwner {
        healthGemScore = _score;
        healthGemPrice = _healthGemPrice;
        healthGemId = _healthGemId;
        healthGemDays = _days;
        hpMultiplier = _hpMultiplier;
        rarityMultiplier = _rarityMultiplier;
        expectedAddons = _expectedAddons;
        addonsMultiplier = _addonsMultiplier;
        expectedRarity = _expectedRarity;
        premiumHp = _premiumHp;
        cashbackPct = _cashbackPct;
    }

    function pause(bool _paused) public onlyOwner {
        paused = _paused;
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    /* generates a number from 0 to 2^n based on the last n blocks */
    function randomNumber(uint256 seed, uint256 max)
        public
        view
        returns (uint256 _randomNumber)
    {
        uint256 n = 0;
        for (uint256 i = 0; i < 5; i++) {
            n += uint256(
                keccak256(
                    abi.encodePacked(blockhash(block.number - i - 1), seed)
                )
            );
        }
        return (n * seed) % max;
    }
}

pragma solidity ^0.6.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/introspection/IERC165Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";

// @TODO DOn't Forget!!!
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155HolderUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/utils/EnumerableSetUpgradeable.sol";

import "../interfaces/IMuseToken.sol";
import "../interfaces/IVNFT.sol";

// SPDX-License-Identifier: MIT

// Extending IERC1155 with mint and burn
interface IERC1155 is IERC165Upgradeable {
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );

    event URI(string value, uint256 indexed id);

    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;

    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function mintBatch(
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;

    function burn(
        address account,
        uint256 id,
        uint256 value
    ) external;

    function burnBatch(
        address account,
        uint256[] calldata ids,
        uint256[] calldata values
    ) external;
}

contract VNFTxV3 is
    Initializable,
    OwnableUpgradeable,
    ERC1155HolderUpgradeable
{
    /* START V1  STORAGE */
    using SafeMathUpgradeable for uint256;

    bool paused;

    IVNFT public vnft;
    IMuseToken public muse;
    IERC1155 public addons;

    uint256 public artistPct;

    struct Addon {
        string _type;
        uint256 price;
        uint256 requiredhp;
        uint256 rarity;
        string artistName;
        address artistAddr;
        uint256 quantity;
        uint256 used;
    }

    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    mapping(uint256 => Addon) public addon;

    mapping(uint256 => EnumerableSetUpgradeable.UintSet) private addonsConsumed;
    EnumerableSetUpgradeable.UintSet lockedAddons;

    //nftid to rarity points
    mapping(uint256 => uint256) public rarity;
    mapping(uint256 => uint256) public challengesUsed;

    //!important, decides which gem score hp is based of
    uint256 public healthGemScore;
    uint256 public healthGemId;
    uint256 public healthGemPrice;
    uint256 public healthGemDays;

    // premium hp is the min requirement for premium features.
    uint256 public premiumHp;
    uint256 public hpMultiplier;
    uint256 public rarityMultiplier;
    uint256 public addonsMultiplier;
    //expected addons to be used for max hp
    uint256 public expectedAddons;
    //Expected rarity, this should be changed according to new addons introduced.
    uint256 expectedRarity;

    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _addonId;

    /* END V1 STORAGE */

    event BuyAddon(uint256 nftId, uint256 addon, address player);
    event CreateAddon(
        uint256 addonId,
        string _type,
        uint256 rarity,
        uint256 quantity
    );
    event EditAddon(
        uint256 addonId,
        string _type,
        uint256 price,
        uint256 _quantity
    );
    event AttachAddon(uint256 addonId, uint256 nftId);
    event RemoveAddon(uint256 addonId, uint256 nftId);

    constructor() public {}

    modifier tokenOwner(uint256 _id) {
        require(
            vnft.ownerOf(_id) == msg.sender,
            "You must own the vNFT to use this feature"
        );
        _;
    }

    modifier notLocked(uint256 _id) {
        require(!lockedAddons.contains(_id), "This addon is locked");
        _;
    }

    modifier notPaused() {
        require(!paused, "Contract paused!");
        _;
    }

    // get how many addons a pet is using
    function addonsBalanceOf(uint256 _nftId) public view returns (uint256) {
        return addonsConsumed[_nftId].length();
    }

    // get a specific addon
    function addonsOfNftByIndex(uint256 _nftId, uint256 _index)
        public
        view
        returns (uint256)
    {
        return addonsConsumed[_nftId].at(_index);
    }

    function getHp(uint256 _nftId) public view returns (uint256) {
        // A vnft need to get at least x score every two days to be healthy
        uint256 currentScore = vnft.vnftScore(_nftId);
        uint256 timeBorn = vnft.timeVnftBorn(_nftId);
        uint256 daysLived = (now.sub(timeBorn)).div(1 days);

        // multiply by healthy gem divided by 2 (every 2 days)
        uint256 expectedScore = daysLived.mul(
            healthGemScore.div(healthGemDays)
        );

        // get # of addons used
        uint256 addonsUsed = addonsBalanceOf(_nftId);

        if (
            !vnft.isVnftAlive(_nftId) //not dead
        ) {
            return 0;
        } else if (daysLived < 1) {
            return 70;
        }
        // here we get the % they get from score, from rarity, from used and then return based on their multiplier
        uint256 fromScore = min(currentScore.mul(100).div(expectedScore), 100);
        uint256 fromRarity = min(
            rarity[_nftId].mul(100).div(expectedRarity),
            100
        );
        uint256 fromUsed = min(addonsUsed.mul(100).div(expectedAddons), 100);
        uint256 hp = (fromRarity.mul(rarityMultiplier))
            .add(fromScore.mul(hpMultiplier))
            .add(fromUsed.mul(addonsMultiplier));
        return min(hp.div(100), 100);
    }

    function getChallenges(uint256 _nftId) public view returns (uint256) {
        if (vnft.level(_nftId) <= challengesUsed[_nftId]) {
            return 0;
        }

        return vnft.level(_nftId).sub(challengesUsed[_nftId]);
    }

    function buyAddon(uint256 _nftId, uint256 addonId)
        public
        tokenOwner(_nftId)
        notPaused
    {
        Addon storage _addon = addon[addonId];

        require(
            getHp(_nftId) >= _addon.requiredhp,
            "Raise your HP to buy this addon"
        );
        require(
            // @TODO double check < or <=
            _addon.used < _addon.quantity &&
                addons.balanceOf(address(this), addonId) >= 1,
            "Addon not available"
        );

        _addon.used = _addon.used.add(1);

        addonsConsumed[_nftId].add(addonId);

        rarity[_nftId] = rarity[_nftId].add(_addon.rarity);

        uint256 artistCut = _addon.price.mul(artistPct).div(100);

        muse.transferFrom(msg.sender, _addon.artistAddr, artistCut);
        muse.burnFrom(msg.sender, _addon.price.sub(artistCut));
        emit BuyAddon(_nftId, addonId, msg.sender);
    }

    function useAddon(uint256 _nftId, uint256 _addonID)
        public
        tokenOwner(_nftId)
        notPaused
    {
        require(
            !addonsConsumed[_nftId].contains(_addonID),
            "Pet already has this addon"
        );
        require(
            addons.balanceOf(msg.sender, _addonID) >= 1,
            "!own the addon to use it"
        );

        Addon storage _addon = addon[_addonID];

        require(
            getHp(_nftId) >= _addon.requiredhp,
            "Raise your HP to use this addon"
        );

        addonsConsumed[_nftId].add(_addonID);

        rarity[_nftId] = rarity[_nftId].add(_addon.rarity);

        addons.safeTransferFrom(msg.sender, address(this), _addonID, 1, "");
        emit AttachAddon(_addonID, _nftId);
    }

    function transferAddon(
        uint256 _nftId,
        uint256 _addonID,
        uint256 _toId
    ) external tokenOwner(_nftId) notLocked(_addonID) {
        Addon storage _addon = addon[_addonID];

        require(
            getHp(_toId) >= _addon.requiredhp,
            "Receiving vNFT with no enough HP"
        );
        emit RemoveAddon(_addonID, _nftId);
        emit AttachAddon(_addonID, _toId);

        addonsConsumed[_nftId].remove(_addonID);
        rarity[_nftId] = rarity[_nftId].sub(_addon.rarity);

        addonsConsumed[_toId].add(_addonID);
        rarity[_toId] = rarity[_toId].add(_addon.rarity);
    }

    function removeAddon(uint256 _nftId, uint256 _addonID)
        public
        tokenOwner(_nftId)
        notLocked(_addonID)
    {
        // maybe can take this out for gas and the .remove would throw if no addonid on user?
        require(
            addonsConsumed[_nftId].contains(_addonID),
            "Pet doesn't have this addon"
        );
        Addon storage _addon = addon[_addonID];
        rarity[_nftId] = rarity[_nftId].sub(_addon.rarity);

        addonsConsumed[_nftId].remove(_addonID);
        emit RemoveAddon(_addonID, _nftId);

        addons.safeTransferFrom(address(this), msg.sender, _addonID, 1, "");
    }

    function removeMultiple(
        uint256[] calldata nftIds,
        uint256[] calldata addonIds
    ) external {
        for (uint256 i = 0; i < addonIds.length; i++) {
            removeAddon(nftIds[i], addonIds[i]);
        }
    }

    function useMultiple(uint256[] calldata nftIds, uint256[] calldata addonIds)
        external
    {
        for (uint256 i = 0; i < addonIds.length; i++) {
            useAddon(nftIds[i], addonIds[i]);
        }
    }

    function buyMultiple(uint256[] calldata nftIds, uint256[] calldata addonIds)
        external
    {
        for (uint256 i = 0; i < addonIds.length; i++) {
            useAddon(nftIds[i], addonIds[i]);
        }
    }

    // this is in case a dead pet addons is stuck in contract, we can use for diff cases.
    function withdraw(uint256 _id, address _to) external onlyOwner {
        addons.safeTransferFrom(address(this), _to, _id, 1, "");
    }

    function createAddon(
        string calldata _type,
        uint256 price,
        uint256 _hp,
        uint256 _rarity,
        string calldata _artistName,
        address _artist,
        uint256 _quantity,
        bool _lock
    ) external onlyOwner {
        _addonId.increment();
        uint256 newAddonId = _addonId.current();

        addon[newAddonId] = Addon(
            _type,
            price,
            _hp,
            _rarity,
            _artistName,
            _artist,
            _quantity,
            0
        );
        addons.mint(address(this), newAddonId, _quantity, "");

        if (_lock) {
            lockAddon(newAddonId);
        }

        emit CreateAddon(newAddonId, _type, _rarity, _quantity);
    }

    function getVnftInfo(uint256 _nftId)
        public
        view
        returns (
            uint256 _vNFT,
            uint256 _rarity,
            uint256 _hp,
            uint256 _addonsCount,
            uint256[10] memory _addons
        )
    {
        _vNFT = _nftId;
        _rarity = rarity[_nftId];
        _hp = getHp(_nftId);
        _addonsCount = addonsBalanceOf(_nftId);
        uint256 index = 0; // NOT FOR @JULES THIS IS HIGHLY EXPERIMENTAL NEED TO TEST
        while (index < _addonsCount && index < 10) {
            _addons[index] = (addonsConsumed[_nftId].at(index));
            index = index + 1;
        }
    }

    function editAddon(
        uint256 _id,
        string calldata _type,
        uint256 price,
        uint256 _requiredhp,
        uint256 _rarity,
        string calldata _artistName,
        address _artist,
        uint256 _quantity,
        uint256 _used,
        bool _lock
    ) external onlyOwner {
        Addon storage _addon = addon[_id];
        _addon._type = _type;
        _addon.price = price * 10**18;
        _addon.requiredhp = _requiredhp;
        _addon.rarity = _rarity;
        _addon.artistName = _artistName;
        _addon.artistAddr = _artist;
        if (_quantity > _addon.quantity) {
            addons.mint(address(this), _id, _quantity.sub(_addon.quantity), "");
        } else if (_quantity < _addon.quantity) {
            addons.burn(address(this), _id, _addon.quantity - _quantity);
        }
        _addon.quantity = _quantity;
        _addon.used = _used;

        if (_lock) {
            lockAddon(_id);
        }

        emit EditAddon(_id, _type, price, _quantity);
    }

    function lockAddon(uint256 _id) public onlyOwner {
        lockedAddons.add(_id);
    }

    function unlockAddon(uint256 _id) public onlyOwner {
        lockedAddons.remove(_id);
    }

    function setArtistPct(uint256 _newPct) external onlyOwner {
        artistPct = _newPct;
    }

    function setHealthStrat(
        uint256 _score,
        uint256 _healthGemPrice,
        uint256 _healthGemId,
        uint256 _days,
        uint256 _hpMultiplier,
        uint256 _rarityMultiplier,
        uint256 _expectedAddons,
        uint256 _addonsMultiplier,
        uint256 _expectedRarity,
        uint256 _premiumHp
    ) external onlyOwner {
        healthGemScore = _score;
        healthGemPrice = _healthGemPrice;
        healthGemId = _healthGemId;
        healthGemDays = _days;
        hpMultiplier = _hpMultiplier;
        rarityMultiplier = _rarityMultiplier;
        expectedAddons = _expectedAddons;
        addonsMultiplier = _addonsMultiplier;
        expectedRarity = _expectedRarity;
        premiumHp = _premiumHp;
    }

    function pause(bool _paused) public onlyOwner {
        paused = _paused;
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}

pragma solidity ^0.6.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/introspection/IERC165Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";

// @TODO DOn't Forget!!!
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155HolderUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/utils/EnumerableSetUpgradeable.sol";

import "../interfaces/IMuseToken.sol";
import "../interfaces/IVNFT.sol";

// SPDX-License-Identifier: MIT

// Extending IERC1155 with mint and burn
interface IERC1155 is IERC165Upgradeable {
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );

    event URI(string value, uint256 indexed id);

    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;

    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function mintBatch(
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;

    function burn(
        address account,
        uint256 id,
        uint256 value
    ) external;

    function burnBatch(
        address account,
        uint256[] calldata ids,
        uint256[] calldata values
    ) external;
}

contract VNFTxV2 is
    Initializable,
    OwnableUpgradeable,
    ERC1155HolderUpgradeable
{
    /* START V1  STORAGE */
    using SafeMathUpgradeable for uint256;

    bool paused;

    IVNFT public vnft;
    IMuseToken public muse;
    IERC1155 public addons;

    uint256 public artistPct;

    struct Addon {
        string _type;
        uint256 price;
        uint256 requiredhp;
        uint256 rarity;
        string artistName;
        address artistAddr;
        uint256 quantity;
        uint256 used;
    }

    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    mapping(uint256 => Addon) public addon;

    mapping(uint256 => EnumerableSetUpgradeable.UintSet) private addonsConsumed;
    EnumerableSetUpgradeable.UintSet lockedAddons;

    //nftid to rarity points
    mapping(uint256 => uint256) public rarity;
    mapping(uint256 => uint256) public challengesUsed;

    //!important, decides which gem score hp is based of
    uint256 public healthGemScore;
    uint256 public healthGemId;
    uint256 public healthGemPrice;
    uint256 public healthGemDays;

    // premium hp is the min requirement for premium features.
    uint256 public premiumHp;
    uint256 public hpMultiplier;
    uint256 public rarityMultiplier;
    uint256 public addonsMultiplier;
    //expected addons to be used for max hp
    uint256 public expectedAddons;
    //Expected rarity, this should be changed according to new addons introduced.
    uint256 expectedRarity;

    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _addonId;

    /* END V1 STORAGE */

    event BuyAddon(uint256 nftId, uint256 addon, address player);
    event CreateAddon(
        uint256 addonId,
        string _type,
        uint256 rarity,
        uint256 quantity
    );
    event EditAddon(
        uint256 addonId,
        string _type,
        uint256 price,
        uint256 _quantity
    );
    event AttachAddon(uint256 addonId, uint256 nftId);
    event RemoveAddon(uint256 addonId, uint256 nftId);

    constructor() public {}

    modifier tokenOwner(uint256 _id) {
        require(
            vnft.ownerOf(_id) == msg.sender,
            "You must own the vNFT to use this feature"
        );
        _;
    }

    modifier notLocked(uint256 _id) {
        require(!lockedAddons.contains(_id), "This addon is locked");
        _;
    }

    modifier notPaused() {
        require(!paused, "Contract paused!");
        _;
    }

    // get how many addons a pet is using
    function addonsBalanceOf(uint256 _nftId) public view returns (uint256) {
        return addonsConsumed[_nftId].length();
    }

    // get a specific addon
    function addonsOfNftByIndex(uint256 _nftId, uint256 _index)
        public
        view
        returns (uint256)
    {
        return addonsConsumed[_nftId].at(_index);
    }

    function getHp(uint256 _nftId) public view returns (uint256) {
        // A vnft need to get at least x score every two days to be healthy
        uint256 currentScore = vnft.vnftScore(_nftId);
        uint256 timeBorn = vnft.timeVnftBorn(_nftId);
        uint256 daysLived = (now.sub(timeBorn)).div(1 days);

        // multiply by healthy gem divided by 2 (every 2 days)
        uint256 expectedScore = daysLived.mul(
            healthGemScore.div(healthGemDays)
        );

        // get # of addons used
        uint256 addonsUsed = addonsBalanceOf(_nftId);

        if (
            !vnft.isVnftAlive(_nftId) //not dead
        ) {
            return 0;
        } else if (daysLived < 1) {
            return 70;
        }
         // here we get the % they get from score, from rarity, from used and then return based on their multiplier
        uint256 fromScore = min(currentScore.mul(100).div(expectedScore), 100);
        uint256 fromRarity = min(rarity[_nftId].mul(100).div(expectedRarity), 100);
        uint256 fromUsed = min(addonsUsed.mul(100).div(expectedAddons), 100);
        uint256 hp = (fromRarity.mul(rarityMultiplier))
            .add(fromScore.mul(hpMultiplier))
            .add(fromUsed.mul(addonsMultiplier));
        return min(hp.div(100), 100);
    }

    function getChallenges(uint256 _nftId) public view returns (uint256) {
        if (vnft.level(_nftId) <= challengesUsed[_nftId]) {
            return 0;
        }

        return vnft.level(_nftId).sub(challengesUsed[_nftId]);
    }

    function buyAddon(uint256 _nftId, uint256 addonId)
        public
        tokenOwner(_nftId)
        notPaused
    {
        Addon storage _addon = addon[addonId];

        require(
            getHp(_nftId) >= _addon.requiredhp,
            "Raise your HP to buy this addon"
        );
        require(
            // @TODO double check < or <=
            _addon.used < addons.balanceOf(address(this), addonId),
            "Addon not available"
        );

        _addon.used = _addon.used.add(1);

        addonsConsumed[_nftId].add(addonId);

        rarity[_nftId] = rarity[_nftId].add(_addon.rarity);

        uint256 artistCut = _addon.price.mul(artistPct).div(100);

        muse.transferFrom(msg.sender, _addon.artistAddr, artistCut);
        muse.burnFrom(msg.sender, _addon.price.sub(artistCut));
        emit BuyAddon(_nftId, addonId, msg.sender);
    }

    function useAddon(uint256 _nftId, uint256 _addonID)
        public
        tokenOwner(_nftId)
        notPaused
    {
        require(
            !addonsConsumed[_nftId].contains(_addonID),
            "Pet already has this addon"
        );
        require(
            addons.balanceOf(msg.sender, _addonID) >= 1,
            "!own the addon to use it"
        );

        Addon storage _addon = addon[_addonID];

        require(
            getHp(_nftId) >= _addon.requiredhp,
            "Raise your HP to use this addon"
        );

        _addon.used = _addon.used.add(1);

        addonsConsumed[_nftId].add(_addonID);

        rarity[_nftId] = rarity[_nftId].add(_addon.rarity);

        addons.safeTransferFrom(msg.sender, address(this), _addonID, 1, "0x0");
        emit AttachAddon(_addonID, _nftId);
    }

    function transferAddon(
        uint256 _nftId,
        uint256 _addonID,
        uint256 _toId
    ) external tokenOwner(_nftId) notLocked(_addonID) {
        Addon storage _addon = addon[_addonID];

        require(
            getHp(_toId) >= _addon.requiredhp,
            "Receiving vNFT with no enough HP"
        );
        emit RemoveAddon(_addonID, _nftId);
        emit AttachAddon(_addonID, _toId);

        addonsConsumed[_nftId].remove(_addonID);
        rarity[_nftId] = rarity[_nftId].sub(_addon.rarity);

        addonsConsumed[_toId].add(_addonID);
        rarity[_toId] = rarity[_toId].add(_addon.rarity);
    }

    function removeAddon(uint256 _nftId, uint256 _addonID)
        public
        tokenOwner(_nftId)
        notLocked(_addonID)
    {
        // maybe can take this out for gas and the .remove would throw if no addonid on user?
        require(
            addonsConsumed[_nftId].contains(_addonID),
            "Pet doesn't have this addon"
        );
        Addon storage _addon = addon[_addonID];
        rarity[_nftId] = rarity[_nftId].sub(_addon.rarity);

        addonsConsumed[_nftId].remove(_addonID);
        emit RemoveAddon(_addonID, _nftId);

        addons.safeTransferFrom(address(this), msg.sender, _addonID, 1, "0x0");
    }

    function removeMultiple(
        uint256[] calldata nftIds,
        uint256[] calldata addonIds
    ) external {
        for (uint256 i = 0; i < addonIds.length; i++) {
            removeAddon(nftIds[i], addonIds[i]);
        }
    }

    function useMultiple(uint256[] calldata nftIds, uint256[] calldata addonIds)
        external
    {
        for (uint256 i = 0; i < addonIds.length; i++) {
            useAddon(nftIds[i], addonIds[i]);
        }
    }

    function buyMultiple(uint256[] calldata nftIds, uint256[] calldata addonIds)
        external
    {
        for (uint256 i = 0; i < addonIds.length; i++) {
            useAddon(nftIds[i], addonIds[i]);
        }
    }

    // this is in case a dead pet addons is stuck in contract, we can use for diff cases.
    function withdraw(uint256 _id, address _to) external onlyOwner {
        addons.safeTransferFrom(address(this), _to, _id, 1, "");
    }

    function createAddon(
        string calldata _type,
        uint256 price,
        uint256 _hp,
        uint256 _rarity,
        string calldata _artistName,
        address _artist,
        uint256 _quantity,
        bool _lock
    ) external onlyOwner {
        _addonId.increment();
        uint256 newAddonId = _addonId.current();

        addon[newAddonId] = Addon(
            _type,
            price,
            _hp,
            _rarity,
            _artistName,
            _artist,
            _quantity,
            0
        );
        addons.mint(address(this), newAddonId, _quantity, "");

        if (_lock) {
            lockAddon(newAddonId);
        }

        emit CreateAddon(newAddonId, _type, _rarity, _quantity);
    }

    function getVnftInfo(uint256 _nftId)
        public
        view
        returns (
            uint256 _vNFT,
            uint256 _rarity,
            uint256 _hp,
            uint256 _addonsCount,
            uint256[10] memory _addons
        )
    {
        _vNFT = _nftId;
        _rarity = rarity[_nftId];
        _hp = getHp(_nftId);
        _addonsCount = addonsBalanceOf(_nftId);
        uint256 index = 0; // NOT FOR @JULES THIS IS HIGHLY EXPERIMENTAL NEED TO TEST
        while (index < _addonsCount && index < 10) {
            _addons[index] = (addonsConsumed[_nftId].at(index));
            index = index + 1;
        }
    }

    function editAddon(
        uint256 _id,
        string calldata _type,
        uint256 price,
        uint256 _requiredhp,
        uint256 _rarity,
        string calldata _artistName,
        address _artist,
        uint256 _quantity,
        uint256 _used,
        bool _lock
    ) external onlyOwner {
        Addon storage _addon = addon[_id];
        _addon._type = _type;
        _addon.price = price * 10**18;
        _addon.requiredhp = _requiredhp;
        _addon.rarity = _rarity;
        _addon.artistName = _artistName;
        _addon.artistAddr = _artist;
        if (_quantity > _addon.quantity) {
            addons.mint(address(this), _id, _quantity.sub(_addon.quantity), "");
        } else if (_quantity < _addon.quantity) {
            addons.burn(address(this), _id, _addon.quantity - _quantity);
        }
        _addon.quantity = _quantity;
        _addon.used = _used;

        if (_lock) {
            lockAddon(_id);
        }

        emit EditAddon(_id, _type, price, _quantity);
    }

    function lockAddon(uint256 _id) public onlyOwner {
        lockedAddons.add(_id);
    }

    function unlockAddon(uint256 _id) public onlyOwner {
        lockedAddons.remove(_id);
    }

    function setArtistPct(uint256 _newPct) external onlyOwner {
        artistPct = _newPct;
    }

    function setHealthStrat(
        uint256 _score,
        uint256 _healthGemPrice,
        uint256 _healthGemId,
        uint256 _days,
        uint256 _hpMultiplier,
        uint256 _rarityMultiplier,
        uint256 _expectedAddons,
        uint256 _addonsMultiplier,
        uint256 _expectedRarity,
        uint256 _premiumHp
    ) external onlyOwner {
        healthGemScore = _score;
        healthGemPrice = _healthGemPrice;
        healthGemId = _healthGemId;
        healthGemDays = _days;
        hpMultiplier = _hpMultiplier;
        rarityMultiplier = _rarityMultiplier;
        expectedAddons = _expectedAddons;
        addonsMultiplier = _addonsMultiplier;
        expectedRarity = _expectedRarity;
        premiumHp = _premiumHp;
    }

    function pause(bool _paused) public onlyOwner {
        paused = _paused;
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}

