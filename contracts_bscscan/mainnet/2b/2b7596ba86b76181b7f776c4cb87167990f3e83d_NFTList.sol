// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "../libraries/helpers/Errors.sol";
import "../libraries/logic/NFTInfoLogic.sol";
import "../interfaces/IAddressesProvider.sol";
import "../libraries/helpers/ArrayLib.sol";

/**
 * @title NFTList contract
 * @dev Agencies for users to register nft address and market admin will accept so that they can be sell / buy / exchange on the Market.
 * - Owned by the PiProtocol
 * @author PiProtocol
 **/
contract NFTList is Initializable {
    using NFTInfoLogic for NFTInfoType.NFTInfo;
    using ArrayLib for uint256[];

    IAddressesProvider public addressesProvider;

    mapping(address => NFTInfoType.NFTInfo) internal _nftToInfo;
    address[] internal _nftsList;
    uint256[] internal _acceptedList;

    event Initialized(address indexed provider);
    event NFTRegistered(address indexed nftAddress, bool erc1155);
    event NFTAccepted(address indexed nftAddress);
    event NFTRevoked(address indexed nftAddress);
    event NFTAdded(address indexed nftAddress, bool erc1155);

    modifier onlyMarketAdmin() {
        require(addressesProvider.getAdmin() == msg.sender, Errors.CALLER_NOT_MARKET_ADMIN);
        _;
    }

    modifier onlyCreativeStudio {
        require(
            addressesProvider.getCreativeStudio() == msg.sender,
            Errors.CALLER_NOT_CREATIVE_STUDIO
        );
        _;
    }

    /**
     * @dev Function is invoked by the proxy contract when the NFTList contract is added to the
     * AddressesProvider of the market.
     * - Caching the address of the AddressesProvider in order to reduce gas consumption
     *   on subsequent operations
     * @param provider The address of the AddressesProvider
     **/
    function initialize(address provider) external initializer {
        addressesProvider = IAddressesProvider(provider);
        emit Initialized(provider);
    }

    /**
     * @dev Register a nft address
     * - Can be called by anyone
     * @param nftAddress The address of nft contract
     * @param isErc1155 What type of nft, ERC1155 or ERC721?
     **/
    function registerNFT(address nftAddress, bool isErc1155) external {
        require(!_nftToInfo[nftAddress].isRegistered, Errors.NFT_ALREADY_REGISTERED);

        if (isErc1155) {
            require(IERC1155(nftAddress).balanceOf(address(this), 0) >= 0);
        } else {
            require(IERC721(nftAddress).balanceOf(address(this)) >= 0);
        }

        _nftToInfo[nftAddress].register(_nftsList.length, nftAddress, isErc1155, msg.sender);

        _nftsList.push(nftAddress);

        emit NFTRegistered(nftAddress, isErc1155);
    }

    /**
     * @dev Accept a nft address
     * - Can only be called by admin
     * @param nftAddress The address of nft contract
     **/
    function acceptNFT(address nftAddress) external onlyMarketAdmin {
        require(_nftToInfo[nftAddress].isRegistered, Errors.NFT_NOT_REGISTERED);
        require(!_nftToInfo[nftAddress].isAccepted, Errors.NFT_ALREADY_ACCEPTED);

        _nftToInfo[nftAddress].accept();
        _acceptedList.push(_nftToInfo[nftAddress].id);

        emit NFTAccepted(nftAddress);
    }

    /**
     * @dev Revoke a nft address
     * - Can only be called by admin
     * @param nftAddress The address of nft contract
     **/
    function revokeNFT(address nftAddress) external onlyMarketAdmin {
        require(_nftToInfo[nftAddress].isRegistered, Errors.NFT_NOT_REGISTERED);
        require(_nftToInfo[nftAddress].isAccepted, Errors.NFT_NOT_ACCEPTED);

        _nftToInfo[nftAddress].revoke();
        _acceptedList.removeAtValue(_nftToInfo[nftAddress].id);

        emit NFTRevoked(nftAddress);
    }

    /**
     * Check nft is ERC1155 or not?
     * @param nftAddress The address of nft
     * @return is ERC1155 or not?
     */
    function isERC1155(address nftAddress) external view returns (bool) {
        require(
            _nftToInfo[nftAddress].isRegistered == true ||
                _nftToInfo[nftAddress].isAccepted == true,
            Errors.NFT_NOT_REGISTERED
        );
        return _nftToInfo[nftAddress].isERC1155;
    }

    /**
     * @dev Register and accepts a nft address directly
     * - Can only be called by creative studio
     * @param nftAddress The address of nft contract
     * @param isErc1155 What type of nft, ERC1155 or ERC721?
     **/
    function addNFTDirectly(
        address nftAddress,
        bool isErc1155,
        address registrant
    ) external onlyCreativeStudio {
        _nftToInfo[nftAddress].register(_nftsList.length, nftAddress, isErc1155, registrant);
        _nftsList.push(nftAddress);
        _nftToInfo[nftAddress].accept();
        _acceptedList.push(_nftToInfo[nftAddress].id);
        emit NFTAdded(nftAddress, isErc1155);
    }

    /**
     * @dev Get the information of a nft
     * @param nftAddress The address of nft
     * @return The information of nft
     **/
    function getNFTInfo(address nftAddress) external view returns (NFTInfoType.NFTInfo memory) {
        return _nftToInfo[nftAddress];
    }

    /**
     * @dev Get the amount of registered nfts
     * @return The amount of registered nfts
     **/
    function getNFTCount() external view returns (uint256) {
        return _nftsList.length;
    }

    /**
     * @dev Get address of all accepted nfts
     * @return The address of all accepted nfts
     **/
    function getAcceptedNFTs() external view returns (address[] memory) {
        address[] memory result = new address[](_acceptedList.length);
        for (uint256 i = 0; i < _acceptedList.length; i++) {
            result[i] = _nftsList[_acceptedList[i]];
        }
        return result;
    }

    /**
     * @dev Check nft has been accepted or not
     * @param nftAddress The address of nft
     * @return Nft has been accepted or not?
     */
    function isAcceptedNFT(address nftAddress) external view returns (bool) {
        return _nftToInfo[nftAddress].isAccepted;
    }

    function getAllNFT() external view returns (NFTInfoType.NFTInfo[] memory) {
        NFTInfoType.NFTInfo[] memory result = new NFTInfoType.NFTInfo[](_nftsList.length);
        for (uint256 i = 0; i < _nftsList.length; i++) {
            result[i] = _nftToInfo[_nftsList[i]];
        }

        return result;
    }

    function getAllNFTAddress() external view returns (address[] memory) {
        return _nftsList;
    }
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

import "../../utils/introspection/IERC165.sol";

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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

library Errors {
    // common errors
    string public constant CALLER_NOT_MARKET_ADMIN = "Caller is not the market admin"; // 'The caller must be the market admin'
    string public constant CALLER_NOT_MARKET = "Caller is not the market"; // 'The caller must be Market'
    string public constant CALLER_NOT_NFT_OWNER = "Caller is not nft owner"; // 'The caller must be the owner of nft'
    string public constant CALLER_NOT_SELLER = "Caller is not seller"; // 'The caller must be the seller'
    string public constant CALLER_IS_SELLER = "Caller is seller"; // 'The caller must be not the seller'
    string public constant CALLER_NOT_CONTRACT_OWNER = "Caller is not contract owner"; // 'The caller must be contract owner'

    string public constant CALLER_NOT_CREATIVE_STUDIO = "Caller is not creative studio"; // 'The caller must be creative studio'

    string public constant REWARD_TOKEN_BE_NOT_SET = "Reward token be not set"; // 'The caller must be contract owner'
    string public constant REWARD_ALREADY_SET = "Reward already set"; // 'The caller must be contract owner'

    string public constant INVALID_START_TIME = "Invalid start time"; // 'Invalid start time'
    string public constant PERIOD_MUST_BE_GREATER_THAN_ZERO = "Period must be greater than zero"; // 'Period must be greater than zero"'
    string public constant NUMBER_OF_CYCLE_MUST_BE_GREATER_THAN_ZERO =
        "Number of cycle must be greater than zero"; // 'Number of cycle must be greater than zero'
    string public constant FIRST_RATE_MUST_BE_GREATER_THAN_ZERO =
        "First rate must be greater than zero"; // 'First rate must be greater than zero'

    string public constant SUPPLY_IS_NOT_AVAILABLE = "Supply is not available"; // 'Invalid start time'

    string public constant NFT_NOT_CONTRACT = "NFT address is not contract"; // 'The address must be contract address'
    string public constant NFT_ALREADY_REGISTERED = "NFT already registered"; // 'The nft already registered'
    string public constant NFT_NOT_REGISTERED = "NFT is not registered"; // 'The nft not registered'
    string public constant NFT_ALREADY_ACCEPTED = "NFT already accepted"; // 'The nft not registered'
    string public constant NFT_NOT_ACCEPTED = "NFT is not accepted"; // 'The nft address muse be accepted'
    string public constant NFT_NOT_APPROVED_FOR_MARKET = "NFT is not approved for Market"; // 'The nft must be approved for Market'

    string public constant SELL_ORDER_NOT_ACTIVE = "Sell order is not active"; // 'The sell order must be active'
    string public constant SELL_ORDER_DUPLICATE = "Sell order is duplicate"; // 'The sell order must be unique'

    string public constant NOT_ENOUGH_MONEY = "Send not enough token"; // 'The msg.value must be equal amount'
    string public constant VALUE_NOT_EQUAL_PRICE = "Msg.value not equal price"; // 'The msg.value must equal price'
    string public constant DEMONINATOR_NOT_GREATER_THAN_NUMERATOR =
        "Demoninator not greater than numerator"; // 'The fee denominator must be greater than fee numerator'

    string public constant RANGE_IS_INVALID = "Range is invalid"; // 'The range must be valid'

    string public constant PRICE_NOT_CHANGE = "Price is not change"; // 'The new price must be not equal price'
    string public constant INSUFFICIENT_BALANCE = "Insufficient balance"; // 'The fund must be equal or greater than amount to withdraw'

    string public constant PARAMETERS_NOT_MATCH = "The parameters are not match"; // 'The parameters must be match'
    string public constant EXCHANGE_ORDER_DUPLICATE = "Exchange order is duplicate"; // 'The exchange order must be unique'
    string public constant PRICE_IS_ZERO = "Price is zero"; // 'The new price must be greater than zero'
    string public constant TOKEN_ALREADY_ACCEPTED = "Token already accepted"; // 'Token already accepted'
    string public constant TOKEN_ALREADY_REVOKED = "Token already revoked"; // 'Token must be accepted'
    string public constant TOKEN_NOT_ACCEPTED = "Token is not accepted"; // 'Token is not accepted'
    string public constant AMOUNT_IS_ZERO = "Amount is zero"; // 'Amount must be accepted'
    string public constant AMOUNT_IS_NOT_ENOUGH = "Amount is not enough"; // 'Amount is not enough'
    string public constant AMOUNT_IS_NOT_EQUAL_ONE = "Amount is not equal 1"; // 'Amount must equal 1'
    string public constant INVALID_CALLDATA = "Invalid call data"; // 'Invalid call data'
    string public constant INVALID_DESTINATION = "Invalid destination"; // 'Invalid destination id'
    string public constant INVALID_BENEFICIARY = "Invalid beneficiary";
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "../types/NFTInfoType.sol";

library NFTInfoLogic {
    /**
     * @dev Register a nft address so it can buy, sell, exchange on Market
     * @param nftInfo NftInfo object
     * @param id NftInfo id
     * @param nftAddress Nft address
     * @param isERC1155 Is that nft erc1155 or not?
     **/
    function register(
        NFTInfoType.NFTInfo storage nftInfo,
        uint256 id,
        address nftAddress,
        bool isERC1155,
        address registrant
    ) internal {
        nftInfo.id = id;
        nftInfo.nftAddress = nftAddress;
        nftInfo.isERC1155 = isERC1155;
        nftInfo.isRegistered = true;
        nftInfo.isAccepted = false;
        nftInfo.registrant = registrant;
    }

    /**
     * @dev Admin accepts a nft address so it can trade in the market
     * @param nftInfo nftInfo object
     **/
    function accept(NFTInfoType.NFTInfo storage nftInfo) internal {
        nftInfo.isAccepted = true;
    }

    /**
     * @dev Admin revokdes a nft address
     * @param nftInfo nftInfo object
     **/
    function revoke(NFTInfoType.NFTInfo storage nftInfo) internal {
        nftInfo.isAccepted = false;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/**
 * @title Interface of AddressesProvider contract
 * - Owned by the PiProtocol
 * @author PiProtocol
 **/
interface IAddressesProvider {
    function setAddress(
        bytes32 id,
        address newAddress,
        bytes memory params
    ) external;

    function setAddressAsProxy(bytes32 id, address impl) external;

    function getAddress(bytes32 id) external view returns (address);

    function setAddress(bytes32 id, address newAddress) external;

    function getNFTList() external view returns (address);

    function setNFTListImpl(address ercList, bytes memory params) external;

    function getMarket() external view returns (address);

    function setMarketImpl(address market, bytes memory params) external;

    function getSellOrderList() external view returns (address);

    function setSellOrderListImpl(address sellOrderList, bytes memory params) external;

    function getExchangeOrderList() external view returns (address);

    function setExchangeOrderListImpl(address exchangeOrderList, bytes memory params) external;

    function getVault() external view returns (address);

    function setVaultImpl(address vault, bytes memory params) external;

    function getCreativeStudio() external view returns (address);

    function setCreativeStudioImpl(address creativeStudio, bytes memory params) external;

    function getAdmin() external view returns (address);

    function setAdmin(address admin) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/**
 * @title Calculation library for Array
 * - Owned by the PiProtocol
 * @author PiProtocol
 **/
library ArrayLib {
    /**
     * @dev Find a value in array
     * @param array The  array
     * @param value Value to find
     * @return (index, found)
     **/
    function find(uint256[] memory array, uint256 value) internal pure returns (uint256, bool) {
        require(array.length > 0, "Array is empty");
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == value) {
                return (i, true);
            }
        }
        return (0, false);
    }

    /**
     * @dev Remove element at index
     * @param array The array
     * @param index Index to remove
     **/
    function removeAtIndex(uint256[] storage array, uint256 index) internal {
        require(array.length > index, "Invalid index");

        if (array.length > 1) {
            array[index] = array[array.length - 1];
        }

        array.pop();
    }

    /**
     * @dev Remove the first element whose value is equal to value
     * @param array The  array
     * @param value Value to remove
     **/
    function removeAtValue(uint256[] storage array, uint256 value) internal {
        require(array.length > 0, "Array is empty");

        (uint256 index, bool found) = find(array, value);

        if (found == true) {
            removeAtIndex(array, index);
        }
    }
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

library NFTInfoType {
    struct NFTInfo {
        // the id of the nft in array
        uint256 id;
        // nft address
        address nftAddress;
        // is ERC1155
        bool isERC1155;
        // is registered
        bool isRegistered;
        // is accepted by admin
        bool isAccepted;
        // registrant
        address registrant;
    }
}