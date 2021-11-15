// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {Address} from '@openzeppelin/contracts/utils/Address.sol';

import {ISipherNFT} from '../interfaces/ISipherNFT.sol';
import {ISipherNFTSale} from '../interfaces/ISipherNFTSale.sol';
import {Whitelist} from '../utils/Whitelist.sol';


contract SipherNFTSale is ISipherNFTSale, Whitelist {

  using Address for address;

  // at initial launch, the owner can buy up to 500 tokens
  uint64 public constant MAX_OWNER_BOUGHT_INITIAL = 500;
  uint64 public constant CAP_PER_WHITELISTED_ADDRESS = 1;
  uint64 public constant CAP_PER_ADDRESS = 5;
  uint256 public constant SALE_PRICE = 10**17; // 0.1 ether

  bytes32 public override merkleRoot; // store the merkle root data for verification purpose

  ISipherNFT public immutable override nft;
  SaleRecord internal _saleRecord;
  SaleConfig internal _saleConfig;
  mapping (address => UserRecord) internal _userRecord;

  event OwnerBought(address indexed buyer, uint256 amount, uint256 amountWeiPaid);
  event WhitelistBought(address indexed buyer, uint256 amount, uint256 amountWeiPaid);
  event PublicBought(address indexed buyer, uint256 amount, uint256 amountWeiPaid);
  event WithdrawSaleFunds(address indexed recipient, uint256 amount);
  event RollStartIndex(address indexed trigger);
  event UpdateSaleEndTime(uint64 endTime);
  event SetMerkleRoot(bytes32 merkelRoot);

  constructor(
    ISipherNFT _nft,
    uint64 _whitelistTime,
    uint64 _publicTime,
    uint64 _endTime,
    uint64 _maxSupply,
    uint256 _maxWhitelistSize
  ) Whitelist(_maxWhitelistSize) {
    nft = _nft;
    _saleConfig = SaleConfig({
      whitelistTime: _whitelistTime,
      publicTime: _publicTime,
      endTime: _endTime,
      maxSupply: _maxSupply
    });
  }

  function withdrawSaleFunds(address payable recipient, uint256 amount) external onlyOwner {
    (bool success, ) = recipient.call{ value: amount }('');
    require(success, 'SipherNFTSale: withdraw funds failed');
    emit WithdrawSaleFunds(recipient, amount);
  }

  /**
   * @dev Allow owner to set the merkle root only once before whitelist buy time
   */
  function setMerkleRoot(bytes32 _root) external onlyOwner {
    require(
      _blockTimestamp() < _saleConfig.whitelistTime,
      'SipherNFTSale: only update before whitelist buy time'
    );
    require(_root != bytes32(0), 'SipherNFTSale: invalid root');
    require(merkleRoot == bytes32(0), 'SipherNFTSale: already set merkle root');
    merkleRoot = _root;
    emit SetMerkleRoot(_root);
  }

  /**
   * @dev Buy amount of NFT tokens
   *   There are different caps for different users at different times
   *   The total sold tokens should be capped to maxSupply
   * @param amount amount of token to buy
   */
  function buy(uint64 amount) external payable override {
    address buyer = msg.sender;
    // only EOA or the owner can buy, disallow contracts to buy
    require(!buyer.isContract() || buyer == owner(), 'SipherNFTSale: only EOA or owner');
    require(merkleRoot != bytes32(0), 'SipherNFTSale: merkle root is not set yet');

    _validateAndUpdateWithBuyAmount(buyer, amount);

    nft.mintGenesis(amount, buyer);
  }

  /**
   * @dev Roll the final start index of the NFT, only call after sale is ended
   */
  function rollStartIndex() external override {
    require(_blockTimestamp() > _saleConfig.endTime, 'SipherNFTSale: sale not ended');

    address sender = msg.sender;
    require(!sender.isContract() || sender == owner(), 'SipherNFTSale: only EOA or owner');

    require(merkleRoot != bytes32(0), 'SipherNFTSale: merkle root is not set yet');
    nft.rollStartIndex();

    emit RollStartIndex(sender);
  }

  /**
   * @dev Update sale end time by the owner only
   *  if new sale end time is in the past, the sale round will be halted
   */
  function updateSaleEndTime(uint64 _endTime) external onlyOwner {
    _saleConfig.endTime = _endTime;
    emit UpdateSaleEndTime(_endTime);
  }

  /**
   * @dev Return the config, with times (whitelistTime, publicTime, endTime) and max supply
   */
  function getSaleConfig() external view override returns (SaleConfig memory config) {
    config = _saleConfig;
  }

  /**
   * @dev Return the record, with number of tokens have been sold for different groups
   */
  function getSaleRecord() external view override returns (SaleRecord memory record) {
    record = _saleRecord;
  }

  /**
   * @dev Return the user record
   */
  function getUserRecord(address user) external view override returns (UserRecord memory record) {
    record = _userRecord[user];
  }
  /**
   * @dev Validate if it is valid to buy and update corresponding data
   *  Logics:
   *    1. Can not buy more than maxSupply
   *    2. If the buyer is the owner:
  *       - can buy up to MAX_OWNER_BOUGHT_INITIAL before endTime with price = 0
   *      - after sale is ended, can buy with no limit (but within maxSupply) with price = 0
   *    3. If the buy time is in whitelist buy time:
   *      - each whitelisted buyer can buy up to CAP_PER_WHITELISTED_ADDRESS tokens with SALE_PRICE per token
   *    4. If the buy time is in public buy time:
   *      - each buyer can buy up to total of CAP_PER_ADDRESS tokens with SALE_PRICE per token
   */
  function _validateAndUpdateWithBuyAmount(address buyer, uint64 amount) internal {
    SaleConfig memory config = _saleConfig;

    // ensure total sold doens't exceed max supply
    require(
      _saleRecord.totalSold + amount <= _saleConfig.maxSupply,
      'SipherNFTSale: max supply reached'
    );

    address owner = owner();
    uint256 totalPaid = msg.value;
    uint256 timestamp = _blockTimestamp();

    if (buyer == owner) {
      // if not ended, owner can buy up to MAX_OWNER_BOUGHT_INITIAL, otherwise there is no cap
      if (timestamp <= config.endTime) {
        require(
          _saleRecord.ownerBought + amount <= MAX_OWNER_BOUGHT_INITIAL,
          'SipherNFTSale: max owner initial reached'
        );
      }
      _saleRecord.ownerBought += amount;
      _saleRecord.totalSold += amount;
      emit OwnerBought(buyer, amount, totalPaid);
      return;
    }

    require(config.whitelistTime <= timestamp, 'SipherNFTSale: not started');
    require(timestamp <= config.endTime, 'SipherNFTSale: already ended');

    if (config.whitelistTime <= timestamp && timestamp < config.publicTime) {
      // only whitelisted can buy at this period
      require(isWhitelistedAddress(buyer), 'SipherNFTSale: only whitelisted buyer');
      // whitelisted address can buy up to CAP_PER_WHITELISTED_ADDRESS token
      require(totalPaid == amount * SALE_PRICE, 'SipherNFTSale: invalid paid value');
      require(
        _userRecord[buyer].whitelistBought + amount <= CAP_PER_WHITELISTED_ADDRESS,
        'SipherNFTSale: whitelisted cap reached'
      );
      _saleRecord.totalWhitelistSold += amount;
      _userRecord[buyer].whitelistBought += amount;
      _saleRecord.totalSold += amount;
      emit WhitelistBought(buyer, amount, totalPaid);
      return;
    }

    if (config.publicTime <= timestamp && timestamp < config.endTime) {
      // anyone can buy up to CAP_PER_ADDRESS tokens with price of SALE_PRICE eth per token
      // it is applied for total of whitelistBought + publicBought
      require(totalPaid == amount * SALE_PRICE, 'SipherNFTSale: invalid paid value');
      require(
        _userRecord[buyer].publicBought + _userRecord[buyer].whitelistBought + amount <= CAP_PER_ADDRESS,
        'SipherNFTSale: normal cap reached'
      );
      _saleRecord.totalPublicSold += amount;
      _userRecord[buyer].publicBought += amount;
      _saleRecord.totalSold += amount;
      emit PublicBought(buyer, amount, totalPaid);
    }
  }

  function _blockTimestamp() internal view returns (uint256) {
    return block.timestamp;
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {IERC721Enumerable} from '@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';


interface ISipherNFT is IERC721Enumerable {
  /**
   * @dev Call only by the Genesis Minter to roll the start index
   */
  function rollStartIndex() external;

  /**
   * @dev Call to mint new genesis tokens, only by Genesis Minter
   *  Can mint up to MAX_GENESIS_SUPPLY tokens
   * @param amount amount of genesis tokens to mint
   * @param to recipient of genesis tokens
   */
  function mintGenesis(uint256 amount, address to) external;

  /**
   * @dev Call to mint a fork of a tokenId, only by Fork Minter
   *  need to wait for all genesis to be minted before minting forks
   *  allow to mint multile forks for a tokenId
   * @param tokenId id of token to mint a fork
   */
  function mintFork(uint256 tokenId) external;

  /**
   * @dev Return the original of a fork token
   * @param forkId fork id to get its original token id
   */
  function originals(uint256 forkId)
    external
    view
    returns (uint256 originalId);

  /**
   * @dev Return the current genesis minter address
   */
  function genesisMinter() external view returns (address);

  /**
   * @dev Return the current fork minter address
   */
  function forkMinter() external view returns (address);

  /**
   * @dev Return the randomized start index, 0 if has not rolled yet
   */
  function randomizedStartIndex() external view returns (uint256);

  /**
   * @dev Return the current genesis token id, default 0, the first token has id of 1
   */
  function currentId() external view returns (uint256);

  /**
   * @dev Return the base Sipher URI for tokens
   */
  function baseSipherURI() external view returns (string memory);

  /**
   * @dev Return the store front URI
   */
  function contractURI() external view returns (string memory);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {ISipherNFT} from '../interfaces/ISipherNFT.sol';


interface ISipherNFTSale {
  struct SaleConfig {
    uint64 whitelistTime;     // time that the owner & whitelisted addresses can start buying
    uint64 publicTime;        // time that other addresses can start buying
    uint64 endTime;           // end time for the sale, only the owner can buy the rest of the supply
    uint64 maxSupply;         // max supply of the nft tokens for this sale round
  }

  struct SaleRecord {
    uint64 totalSold;         // total amount of tokens have been sold
    uint64 ownerBought;       // total amount of tokens that the owner has bought
    uint64 totalWhitelistSold;// total amount of tokens that whitelisted addresses have bought
    uint64 totalPublicSold;   // total amount of tokens that have sold to public
  }

  struct UserRecord {
    uint64 whitelistBought;   // amount of tokens that have bought as a whitelisted address
    uint64 publicBought;      // amount of tokens that have bought as a public address
  }

  /**
   * @dev Buy amount of NFT tokens
   *   There are different caps for different users at different times
   *   The total sold tokens should be capped to maxSupply
   */
  function buy(uint64 amount) external payable;

  /**
   * @dev Roll the final start index of the NFT
   */
  function rollStartIndex() external;

  /**
   * @dev Return the config, with times (t0, t1, t2) and max supply
   */
  function getSaleConfig() external view returns (SaleConfig memory config);

  /**
   * @dev Return the sale record
   */
  function getSaleRecord() external view returns (SaleRecord memory record);

  /**
   * @dev Return the user record
   */
  function getUserRecord(address user) external view returns (UserRecord memory record);

  function merkleRoot() external view returns (bytes32);
  function nft() external view returns (ISipherNFT);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {EnumerableSet} from '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';

import {IWhitelist} from '../interfaces/IWhitelist.sol';


contract Whitelist is IWhitelist, Ownable {

  using EnumerableSet for EnumerableSet.AddressSet;

  // list of whitelisted addresses
  EnumerableSet.AddressSet internal _whitelistGroup;
  // maximum number of addresses in the _whitelistGroup
  uint256 public immutable maxWhitelistSize;

  constructor(uint256 _maxWhitelistSize)  {
    maxWhitelistSize = _maxWhitelistSize;
  }

  /**
   * @dev Update the list of whitelisted addresses
   * @param accounts list of addresses to be updated
   * @param isWhitelisted indicate whether to add or remove from the whitelisted list
   */
  function updateWhitelistedGroup(
    address[] calldata accounts,
    bool isWhitelisted
  ) external override onlyOwner {
    for(uint256 i = 0; i < accounts.length; i++) {
      if (isWhitelisted && _whitelistGroup.add(accounts[i])) {
        emit UpdateWhitelistedAddress(accounts[i], true);
      } else if (!isWhitelisted && _whitelistGroup.remove(accounts[i])) {
        emit UpdateWhitelistedAddress(accounts[i], false);
      }
    }
    if (isWhitelisted) {
      // simplify by checking only in the end, only when adding new accounts
      require(_whitelistGroup.length() <= maxWhitelistSize, 'Whitelist: too many addresses');
    }
  }

  function getWhitelistedGroup() external view override returns (address[] memory accounts) {
    uint256 len = getWhitelistedGroupLength();
    accounts = new address[](len);
    for(uint256 i = 0; i < len; i++) {
      accounts[i] = getWhitelistedAddressAt(i);
    }
  }

  function isWhitelistedAddress(address account) public view override returns (bool) {
    return _whitelistGroup.contains(account);
  }

  function getWhitelistedGroupLength() public view override returns (uint256 length) {
    length = _whitelistGroup.length();
  }

  function getWhitelistedAddressAt(uint256 index) public view override returns (address account) {
    account = _whitelistGroup.at(index);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

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

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
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

pragma solidity ^0.8.0;

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
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
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
        mapping(bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

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
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
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
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
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
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
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
        return address(uint160(uint256(_at(set._inner, index))));
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

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;


interface IWhitelist {

  event UpdateWhitelistedAddress(
    address account,
    bool isWhitelisted
  );

  /**
   * @dev Update the list of whitelisted addresses
   * @param accounts list of addresses to be updated
   * @param isWhitelisted indicate whether to add or remove from the whitelisted list
   */
  function updateWhitelistedGroup(
    address[] calldata accounts,
    bool isWhitelisted
  ) external;

  function isWhitelistedAddress(address account) external view returns (bool);
  function getWhitelistedGroup() external view returns (address[] memory accounts);
  function getWhitelistedGroupLength() external view returns (uint256 length);
  function getWhitelistedAddressAt(uint256 index) external view returns (address account);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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

