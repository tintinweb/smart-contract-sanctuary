// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";

import "./abstracts/fujiERC1155/FujiBaseERC1155.sol";
import "./abstracts/fujiERC1155/F1155Manager.sol";
import "./abstracts/claimable/ClaimableUpgradeable.sol";
import "./interfaces/IFujiERC1155.sol";
import "./libraries/WadRayMath.sol";
import "./libraries/Errors.sol";

contract FujiERC1155 is IFujiERC1155, FujiBaseERC1155, F1155Manager {
  using WadRayMath for uint256;

  // FujiERC1155 Asset ID Mapping

  // AssetType => asset reference address => ERC1155 Asset ID
  mapping(AssetType => mapping(address => uint256)) public assetIDs;

  // Control mapping that returns the AssetType of an AssetID
  mapping(uint256 => AssetType) public assetIDtype;

  uint64 public override qtyOfManagedAssets;

  // Asset ID  Liquidity Index mapping
  // AssetId => Liquidity index for asset ID
  mapping(uint256 => uint256) public indexes;

  function initialize() external initializer {
    __ERC165_init();
    __Context_init();
    __Climable_init();
  }

  /**
   * @dev Updates Index of AssetID
   * @param _assetID: ERC1155 ID of the asset which state will be updated.
   * @param newBalance: Amount
   **/
  function updateState(uint256 _assetID, uint256 newBalance) external override onlyPermit {
    uint256 total = totalSupply(_assetID);

    if (newBalance > 0 && total > 0 && newBalance > total) {
      uint256 diff = newBalance - total;

      uint256 amountToIndexRatio = (diff.wadToRay()).rayDiv(total.wadToRay());

      uint256 result = amountToIndexRatio + WadRayMath.ray();

      result = result.rayMul(indexes[_assetID]);
      require(result <= type(uint128).max, Errors.VL_INDEX_OVERFLOW);

      indexes[_assetID] = uint128(result);

      // TODO: calculate interest rate for a fujiOptimizer Fee.
    }
  }

  /**
   * @dev Returns the total supply of Asset_ID with accrued interest.
   * @param _assetID: ERC1155 ID of the asset which state will be updated.
   **/
  function totalSupply(uint256 _assetID) public view virtual override returns (uint256) {
    // TODO: include interest accrued by Fuji OptimizerFee

    return super.totalSupply(_assetID).rayMul(indexes[_assetID]);
  }

  /**
   * @dev Returns the scaled total supply of the token ID. Represents sum(token ID Principal /index)
   * @param _assetID: ERC1155 ID of the asset which state will be updated.
   **/
  function scaledTotalSupply(uint256 _assetID) public view virtual returns (uint256) {
    return super.totalSupply(_assetID);
  }

  /**
   * @dev Returns the principal + accrued interest balance of the user
   * @param _account: address of the User
   * @param _assetID: ERC1155 ID of the asset which state will be updated.
   **/
  function balanceOf(address _account, uint256 _assetID)
    public
    view
    override(FujiBaseERC1155, IFujiERC1155)
    returns (uint256)
  {
    uint256 scaledBalance = super.balanceOf(_account, _assetID);

    if (scaledBalance == 0) {
      return 0;
    }

    // TODO: include interest accrued by Fuji OptimizerFee
    return scaledBalance.rayMul(indexes[_assetID]);
  }

  /**
   * @dev Returns Scaled Balance of the user (e.g. balance/index)
   * @param _account: address of the User
   * @param _assetID: ERC1155 ID of the asset which state will be updated.
   **/
  function scaledBalanceOf(address _account, uint256 _assetID)
    public
    view
    virtual
    returns (uint256)
  {
    return super.balanceOf(_account, _assetID);
  }

  /**
   * @dev Mints tokens for Collateral and Debt receipts for the Fuji Protocol
   * Emits a {TransferSingle} event.
   * Requirements:
   * - `_account` cannot be the zero address.
   * - If `account` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
   * acceptance magic value.
   * - `_amount` should be in WAD
   */
  function mint(
    address _account,
    uint256 _id,
    uint256 _amount,
    bytes memory _data
  ) external override onlyPermit {
    require(_account != address(0), Errors.VL_ZERO_ADDR_1155);

    address operator = _msgSender();

    uint256 accountBalance = _balances[_id][_account];
    uint256 assetTotalBalance = _totalSupply[_id];
    uint256 amountScaled = _amount.rayDiv(indexes[_id]);

    require(amountScaled != 0, Errors.VL_INVALID_MINT_AMOUNT);

    _balances[_id][_account] = accountBalance + amountScaled;
    _totalSupply[_id] = assetTotalBalance + amountScaled;

    emit TransferSingle(operator, address(0), _account, _id, _amount);

    _doSafeTransferAcceptanceCheck(operator, address(0), _account, _id, _amount, _data);
  }

  /**
   * @dev [Batched] version of {mint}.
   * Requirements:
   * - `_ids` and `_amounts` must have the same length.
   * - If `_to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
   * acceptance magic value.
   */
  function mintBatch(
    address _to,
    uint256[] memory _ids,
    uint256[] memory _amounts,
    bytes memory _data
  ) external onlyPermit {
    require(_to != address(0), Errors.VL_ZERO_ADDR_1155);
    require(_ids.length == _amounts.length, Errors.VL_INPUT_ERROR);

    address operator = _msgSender();

    uint256 accountBalance;
    uint256 assetTotalBalance;
    uint256 amountScaled;

    for (uint256 i = 0; i < _ids.length; i++) {
      accountBalance = _balances[_ids[i]][_to];
      assetTotalBalance = _totalSupply[_ids[i]];

      amountScaled = _amounts[i].rayDiv(indexes[_ids[i]]);

      require(amountScaled != 0, Errors.VL_INVALID_MINT_AMOUNT);

      _balances[_ids[i]][_to] = accountBalance + amountScaled;
      _totalSupply[_ids[i]] = assetTotalBalance + amountScaled;
    }

    emit TransferBatch(operator, address(0), _to, _ids, _amounts);

    _doSafeBatchTransferAcceptanceCheck(operator, address(0), _to, _ids, _amounts, _data);
  }

  /**
   * @dev Destroys `_amount` receipt tokens of token type `_id` from `account` for the Fuji Protocol
   * Requirements:
   * - `account` cannot be the zero address.
   * - `account` must have at least `_amount` tokens of token type `_id`.
   * - `_amount` should be in WAD
   */
  function burn(
    address _account,
    uint256 _id,
    uint256 _amount
  ) external override onlyPermit {
    require(_account != address(0), Errors.VL_ZERO_ADDR_1155);

    address operator = _msgSender();

    uint256 accountBalance = _balances[_id][_account];
    uint256 assetTotalBalance = _totalSupply[_id];

    uint256 amountScaled = _amount.rayDiv(indexes[_id]);

    require(amountScaled != 0 && accountBalance >= amountScaled, Errors.VL_INVALID_BURN_AMOUNT);

    _balances[_id][_account] = accountBalance - amountScaled;
    _totalSupply[_id] = assetTotalBalance - amountScaled;

    emit TransferSingle(operator, _account, address(0), _id, _amount);
  }

  /**
   * @dev [Batched] version of {burn}.
   * Requirements:
   * - `_ids` and `_amounts` must have the same length.
   */
  function burnBatch(
    address _account,
    uint256[] memory _ids,
    uint256[] memory _amounts
  ) external onlyPermit {
    require(_account != address(0), Errors.VL_ZERO_ADDR_1155);
    require(_ids.length == _amounts.length, Errors.VL_INPUT_ERROR);

    address operator = _msgSender();

    uint256 accountBalance;
    uint256 assetTotalBalance;
    uint256 amountScaled;

    for (uint256 i = 0; i < _ids.length; i++) {
      uint256 amount = _amounts[i];

      accountBalance = _balances[_ids[i]][_account];
      assetTotalBalance = _totalSupply[_ids[i]];

      amountScaled = _amounts[i].rayDiv(indexes[_ids[i]]);

      require(amountScaled != 0 && accountBalance >= amountScaled, Errors.VL_INVALID_BURN_AMOUNT);

      _balances[_ids[i]][_account] = accountBalance - amount;
      _totalSupply[_ids[i]] = assetTotalBalance - amount;
    }

    emit TransferBatch(operator, _account, address(0), _ids, _amounts);
  }

  //Getter Functions

  /**
   * @dev Getter Function for the Asset ID locally managed
   * @param _type: enum AssetType, 0 = Collateral asset, 1 = debt asset
   * @param _addr: Reference Address of the Asset
   */
  function getAssetID(AssetType _type, address _addr) external view override returns (uint256 id) {
    id = assetIDs[_type][_addr];
    require(id <= qtyOfManagedAssets, Errors.VL_INVALID_ASSETID_1155);
  }

  //Setter Functions

  /**
   * @dev Sets a new URI for all token types, by relying on the token type ID
   */
  function setURI(string memory _newUri) public onlyOwner {
    _uri = _newUri;
  }

  /**
   * @dev Adds and initializes liquidity index of a new asset in FujiERC1155
   * @param _type: enum AssetType, 0 = Collateral asset, 1 = debt asset
   * @param _addr: Reference Address of the Asset
   */
  function addInitializeAsset(AssetType _type, address _addr)
    external
    override
    onlyPermit
    returns (uint64)
  {
    require(assetIDs[_type][_addr] == 0, Errors.VL_ASSET_EXISTS);

    assetIDs[_type][_addr] = qtyOfManagedAssets;
    assetIDtype[qtyOfManagedAssets] = _type;

    //Initialize the liquidity Index
    indexes[qtyOfManagedAssets] = WadRayMath.ray();
    qtyOfManagedAssets++;

    return qtyOfManagedAssets - 1;
  }
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

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/IERC1155MetadataURIUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "../../libraries/Errors.sol";

/**
 *
 * @dev Implementation of the Base ERC1155 multi-token standard functions
 * for Fuji Protocol control of User collaterals and borrow debt positions.
 * Originally based on Openzeppelin
 *
 */

abstract contract FujiBaseERC1155 is IERC1155Upgradeable, ERC165Upgradeable, ContextUpgradeable {
  using Address for address;

  // Mapping from token ID to account balances
  mapping(uint256 => mapping(address => uint256)) internal _balances;

  // Mapping from account to operator approvals
  mapping(address => mapping(address => bool)) internal _operatorApprovals;

  // Mapping from token ID to totalSupply
  mapping(uint256 => uint256) internal _totalSupply;

  //URI for all token types by relying on ID substitution
  //https://token.fujiDao.org/{id}.json
  string internal _uri;

  /**
   * @return The total supply of a token id
   **/
  function totalSupply(uint256 id) public view virtual returns (uint256) {
    return _totalSupply[id];
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC165Upgradeable, IERC165Upgradeable)
    returns (bool)
  {
    return
      interfaceId == type(IERC1155Upgradeable).interfaceId ||
      interfaceId == type(IERC1155MetadataURIUpgradeable).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  /**
   * @dev See {IERC1155MetadataURI-uri}.
   * Clients calling this function must replace the `\{id\}` substring with the
   * actual token type ID.
   */
  function uri(uint256) public view virtual returns (string memory) {
    return _uri;
  }

  /**
   * @dev See {IERC1155-balanceOf}.
   * Requirements:
   * - `account` cannot be the zero address.
   */
  function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
    require(account != address(0), Errors.VL_ZERO_ADDR_1155);
    return _balances[id][account];
  }

  /**
   * @dev See {IERC1155-balanceOfBatch}.
   * Requirements:
   * - `accounts` and `ids` must have the same length.
   */
  function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
    public
    view
    override
    returns (uint256[] memory)
  {
    require(accounts.length == ids.length, Errors.VL_INPUT_ERROR);

    uint256[] memory batchBalances = new uint256[](accounts.length);

    for (uint256 i = 0; i < accounts.length; ++i) {
      batchBalances[i] = balanceOf(accounts[i], ids[i]);
    }

    return batchBalances;
  }

  /**
   * @dev See {IERC1155-setApprovalForAll}.
   */
  function setApprovalForAll(address operator, bool approved) public virtual override {
    require(_msgSender() != operator, Errors.VL_INPUT_ERROR);

    _operatorApprovals[_msgSender()][operator] = approved;
    emit ApprovalForAll(_msgSender(), operator, approved);
  }

  /**
   * @dev See {IERC1155-isApprovedForAll}.
   */
  function isApprovedForAll(address account, address operator)
    public
    view
    virtual
    override
    returns (bool)
  {
    return _operatorApprovals[account][operator];
  }

  /**
   * @dev See {IERC1155-safeTransferFrom}.
   */
  function safeTransferFrom(
    address, // from
    address, // to
    uint256, // id
    uint256, // amount
    bytes memory // data
  ) public virtual override {
    revert(Errors.VL_ERC1155_NOT_TRANSFERABLE);
  }

  /**
   * @dev See {IERC1155-safeBatchTransferFrom}.
   */
  function safeBatchTransferFrom(
    address, // from
    address, // to
    uint256[] memory, // ids
    uint256[] memory, // amounts
    bytes memory //  data
  ) public virtual override {
    revert(Errors.VL_ERC1155_NOT_TRANSFERABLE);
  }

  function _doSafeTransferAcceptanceCheck(
    address operator,
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) internal {
    if (to.isContract()) {
      try
        IERC1155ReceiverUpgradeable(to).onERC1155Received(operator, from, id, amount, data)
      returns (bytes4 response) {
        if (response != IERC1155ReceiverUpgradeable(to).onERC1155Received.selector) {
          revert(Errors.VL_RECEIVER_REJECT_1155);
        }
      } catch Error(string memory reason) {
        revert(reason);
      } catch {
        revert(Errors.VL_RECEIVER_CONTRACT_NON_1155);
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
  ) internal {
    if (to.isContract()) {
      try
        IERC1155ReceiverUpgradeable(to).onERC1155BatchReceived(operator, from, ids, amounts, data)
      returns (bytes4 response) {
        if (response != IERC1155ReceiverUpgradeable(to).onERC1155BatchReceived.selector) {
          revert(Errors.VL_RECEIVER_REJECT_1155);
        }
      } catch Error(string memory reason) {
        revert(reason);
      } catch {
        revert(Errors.VL_RECEIVER_CONTRACT_NON_1155);
      }
    }
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
  ) internal virtual {}

  function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
    uint256[] memory array = new uint256[](1);
    array[0] = element;

    return array;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";

import "./FujiBaseERC1155.sol";
import "../claimable/ClaimableUpgradeable.sol";
import "../../interfaces/IFujiERC1155.sol";
import "../../libraries/WadRayMath.sol";
import "../../libraries/Errors.sol";

abstract contract F1155Manager is ClaimableUpgradeable {
  using Address for address;

  // Controls for Mint-Burn Operations
  mapping(address => bool) public addrPermit;

  modifier onlyPermit() {
    require(addrPermit[_msgSender()] || msg.sender == owner(), Errors.VL_NOT_AUTHORIZED);
    _;
  }

  function setPermit(address _address, bool _permit) public onlyOwner {
    require((_address).isContract(), Errors.VL_NOT_A_CONTRACT);
    addrPermit[_address] = _permit;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract ClaimableUpgradeable is Initializable, ContextUpgradeable {
  address private _owner;
  address public pendingOwner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  event NewPendingOwner(address indexed owner);

  function __Climable_init() internal initializer {
    __Context_init_unchained();
    __Climable_init_unchained();
  }

  function __Climable_init_unchained() internal initializer {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  function owner() public view virtual returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(_msgSender() == owner(), "Ownable: caller is not the owner");
    _;
  }

  modifier onlyPendingOwner() {
    require(_msgSender() == pendingOwner);
    _;
  }

  function renounceOwnership() public virtual onlyOwner {
    emit OwnershipTransferred(owner(), address(0));
    _owner = address(0);
  }

  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(pendingOwner == address(0));
    pendingOwner = newOwner;
    emit NewPendingOwner(newOwner);
  }

  function cancelTransferOwnership() public onlyOwner {
    require(pendingOwner != address(0));
    delete pendingOwner;
    emit NewPendingOwner(address(0));
  }

  function claimOwnership() public onlyPendingOwner {
    emit OwnershipTransferred(owner(), pendingOwner);
    _owner = pendingOwner;
    delete pendingOwner;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IFujiERC1155 {
  //Asset Types
  enum AssetType {
    //uint8 = 0
    collateralToken,
    //uint8 = 1
    debtToken
  }

  //General Getter Functions

  function getAssetID(AssetType _type, address _assetAddr) external view returns (uint256);

  function qtyOfManagedAssets() external view returns (uint64);

  function balanceOf(address _account, uint256 _id) external view returns (uint256);

  // function splitBalanceOf(address account,uint256 _AssetID) external view  returns (uint256,uint256);

  // function balanceOfBatchType(address account, AssetType _Type) external view returns (uint256);

  //Permit Controlled  Functions
  function mint(
    address _account,
    uint256 _id,
    uint256 _amount,
    bytes memory _data
  ) external;

  function burn(
    address _account,
    uint256 _id,
    uint256 _amount
  ) external;

  function updateState(uint256 _assetID, uint256 _newBalance) external;

  function addInitializeAsset(AssetType _type, address _addr) external returns (uint64);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import { Errors } from "./Errors.sol";

/**
 * @title WadRayMath library
 * @author Aave
 * @dev Provides mul and div function for wads (decimal numbers with 18 digits precision) and rays (decimals with 27 digits)
 **/

library WadRayMath {
  uint256 internal constant _WAD = 1e18;
  uint256 internal constant _HALF_WAD = _WAD / 2;

  uint256 internal constant _RAY = 1e27;
  uint256 internal constant _HALF_RAY = _RAY / 2;

  uint256 internal constant _WAD_RAY_RATIO = 1e9;

  /**
   * @return One ray, 1e27
   **/
  function ray() internal pure returns (uint256) {
    return _RAY;
  }

  /**
   * @return One wad, 1e18
   **/

  function wad() internal pure returns (uint256) {
    return _WAD;
  }

  /**
   * @return Half ray, 1e27/2
   **/
  function halfRay() internal pure returns (uint256) {
    return _HALF_RAY;
  }

  /**
   * @return Half ray, 1e18/2
   **/
  function halfWad() internal pure returns (uint256) {
    return _HALF_WAD;
  }

  /**
   * @dev Multiplies two wad, rounding half up to the nearest wad
   * @param a Wad
   * @param b Wad
   * @return The result of a*b, in wad
   **/
  function wadMul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0 || b == 0) {
      return 0;
    }

    require(a <= (type(uint256).max - _HALF_WAD) / b, Errors.MATH_MULTIPLICATION_OVERFLOW);

    return (a * b + _HALF_WAD) / _WAD;
  }

  /**
   * @dev Divides two wad, rounding half up to the nearest wad
   * @param a Wad
   * @param b Wad
   * @return The result of a/b, in wad
   **/
  function wadDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, Errors.MATH_DIVISION_BY_ZERO);
    uint256 halfB = b / 2;

    require(a <= (type(uint256).max - halfB) / _WAD, Errors.MATH_MULTIPLICATION_OVERFLOW);

    return (a * _WAD + halfB) / b;
  }

  /**
   * @dev Multiplies two ray, rounding half up to the nearest ray
   * @param a Ray
   * @param b Ray
   * @return The result of a*b, in ray
   **/
  function rayMul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0 || b == 0) {
      return 0;
    }

    require(a <= (type(uint256).max - _HALF_RAY) / b, Errors.MATH_MULTIPLICATION_OVERFLOW);

    return (a * b + _HALF_RAY) / _RAY;
  }

  /**
   * @dev Divides two ray, rounding half up to the nearest ray
   * @param a Ray
   * @param b Ray
   * @return The result of a/b, in ray
   **/
  function rayDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, Errors.MATH_DIVISION_BY_ZERO);
    uint256 halfB = b / 2;

    require(a <= (type(uint256).max - halfB) / _RAY, Errors.MATH_MULTIPLICATION_OVERFLOW);

    return (a * _RAY + halfB) / b;
  }

  /**
   * @dev Casts ray down to wad
   * @param a Ray
   * @return a casted to wad, rounded half up to the nearest wad
   **/
  function rayToWad(uint256 a) internal pure returns (uint256) {
    uint256 halfRatio = _WAD_RAY_RATIO / 2;
    uint256 result = halfRatio + a;
    require(result >= halfRatio, Errors.MATH_ADDITION_OVERFLOW);

    return result / _WAD_RAY_RATIO;
  }

  /**
   * @dev Converts wad up to ray
   * @param a Wad
   * @return a converted in ray
   **/
  function wadToRay(uint256 a) internal pure returns (uint256) {
    uint256 result = a * _WAD_RAY_RATIO;
    require(result / _WAD_RAY_RATIO == a, Errors.MATH_MULTIPLICATION_OVERFLOW);
    return result;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

/**
 * @title Errors library
 * @author Fuji
 * @notice Defines the error messages emitted by the different contracts of the Aave protocol
 * @dev Error messages prefix glossary:
 *  - VL = Validation Logic 100 series
 *  - MATH = Math libraries 200 series
 *  - RF = Refinancing 300 series
 *  - VLT = vault 400 series
 *  - SP = Special 900 series
 */
library Errors {
  //Errors
  string public constant VL_INDEX_OVERFLOW = "100"; // index overflows uint128
  string public constant VL_INVALID_MINT_AMOUNT = "101"; //invalid amount to mint
  string public constant VL_INVALID_BURN_AMOUNT = "102"; //invalid amount to burn
  string public constant VL_AMOUNT_ERROR = "103"; //Input value >0, and for ETH msg.value and amount shall match
  string public constant VL_INVALID_WITHDRAW_AMOUNT = "104"; //Withdraw amount exceeds provided collateral, or falls undercollaterized
  string public constant VL_INVALID_BORROW_AMOUNT = "105"; //Borrow amount does not meet collaterization
  string public constant VL_NO_DEBT_TO_PAYBACK = "106"; //Msg sender has no debt amount to be payback
  string public constant VL_MISSING_ERC20_ALLOWANCE = "107"; //Msg sender has not approved ERC20 full amount to transfer
  string public constant VL_USER_NOT_LIQUIDATABLE = "108"; //User debt position is not liquidatable
  string public constant VL_DEBT_LESS_THAN_AMOUNT = "109"; //User debt is less than amount to partial close
  string public constant VL_PROVIDER_ALREADY_ADDED = "110"; // Provider is already added in Provider Array
  string public constant VL_NOT_AUTHORIZED = "111"; //Not authorized
  string public constant VL_INVALID_COLLATERAL = "112"; //There is no Collateral, or Collateral is not in active in vault
  string public constant VL_NO_ERC20_BALANCE = "113"; //User does not have ERC20 balance
  string public constant VL_INPUT_ERROR = "114"; //Check inputs. For ERC1155 batch functions, array sizes should match.
  string public constant VL_ASSET_EXISTS = "115"; //Asset intended to be added already exists in FujiERC1155
  string public constant VL_ZERO_ADDR_1155 = "116"; //ERC1155: balance/transfer for zero address
  string public constant VL_NOT_A_CONTRACT = "117"; //Address is not a contract.
  string public constant VL_INVALID_ASSETID_1155 = "118"; //ERC1155 Asset ID is invalid.
  string public constant VL_NO_ERC1155_BALANCE = "119"; //ERC1155: insufficient balance for transfer.
  string public constant VL_MISSING_ERC1155_APPROVAL = "120"; //ERC1155: transfer caller is not owner nor approved.
  string public constant VL_RECEIVER_REJECT_1155 = "121"; //ERC1155Receiver rejected tokens
  string public constant VL_RECEIVER_CONTRACT_NON_1155 = "122"; //ERC1155: transfer to non ERC1155Receiver implementer
  string public constant VL_OPTIMIZER_FEE_SMALL = "123"; //Fuji OptimizerFee has to be > 1 RAY (1e27)
  string public constant VL_UNDERCOLLATERIZED_ERROR = "124"; // Flashloan-Flashclose cannot be used when User's collateral is worth less than intended debt position to close.
  string public constant VL_MINIMUM_PAYBACK_ERROR = "125"; // Minimum Amount payback should be at least Fuji Optimizerfee accrued interest.
  string public constant VL_HARVESTING_FAILED = "126"; // Harvesting Function failed, check provided _farmProtocolNum or no claimable balance.
  string public constant VL_FLASHLOAN_FAILED = "127"; // Flashloan failed
  string public constant VL_ERC1155_NOT_TRANSFERABLE = "128"; // ERC1155: Not Transferable
  string public constant VL_SWAP_SLIPPAGE_LIMIT_EXCEED = "129"; // ERC1155: Not Transferable
  string public constant VL_ZERO_ADDR = "130"; // Zero Address

  string public constant MATH_DIVISION_BY_ZERO = "201";
  string public constant MATH_ADDITION_OVERFLOW = "202";
  string public constant MATH_MULTIPLICATION_OVERFLOW = "203";

  string public constant RF_INVALID_RATIO_VALUES = "301"; // Ratio Value provided is invalid, _ratioA/_ratioB <= 1, and > 0, or activeProvider borrowBalance = 0

  string public constant VLT_CALLER_MUST_BE_VAULT = "401"; // The caller of this function must be a vault

  string public constant ORACLE_INVALID_LENGTH = "501"; // The assets length and price feeds length doesn't match
  string public constant ORACLE_NONE_PRICE_FEED = "502"; // The price feed is not found
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

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
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

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
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
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
    ) external returns (bytes4);

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
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC1155Upgradeable.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURIUpgradeable is IERC1155Upgradeable {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
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

{
  "optimizer": {
    "enabled": true,
    "runs": 1000
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}