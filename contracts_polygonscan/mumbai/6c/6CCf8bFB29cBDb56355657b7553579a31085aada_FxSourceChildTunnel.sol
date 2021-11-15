// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct HeroInfo {
    uint256 tokenId;
    uint256 seed;
    uint256 edition;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./HeroInfo.sol";

interface ISourceBuilder {
    function render(HeroInfo memory info) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./token/ERC721/extensions/IERC721Enumerable.sol";
import "./ISourceComposer.sol";

interface ISourceChild is IERC721Enumerable {
    function seeds(uint256 tokenId) external view returns (uint256);
    function composer() external view returns (ISourceComposer);
    function mint(address to, uint256 tokenId, uint256 seed, bytes memory data) external;
    function burn(uint256 tokenId, bytes memory data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ISourceBuilder.sol";

interface ISourceComposer {
    function currentEdition() external view returns (uint256);
    function builders(uint256 edition) external view returns (ISourceBuilder);
    function generateSeed(address addr, uint256 tokenId, uint256 edition) external view returns (uint256);
    function constantSeed(address addr, uint256 num, uint256 edition) external view returns (uint256);
    function compose(uint256 tokenId, uint256 seed) external view returns (string memory);
    function isValidEdition(uint256 edition) external view returns (bool);
    function isValidSeed(uint256 seed) external view returns (bool);
    function editionOf(uint256 seed) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// IFxMessageProcessor represents interface to process message
interface IFxMessageProcessor {
    function processMessageFromRoot(uint256 stateId, address rootMessageSender, bytes calldata data) external;
}

/**
* @notice Mock child tunnel contract to receive and send message from L2
*/
abstract contract FxBaseChildTunnel is IFxMessageProcessor{
    // MessageTunnel on L1 will get data from this event
    event MessageSent(bytes message);

    // fx child
    address public fxChild;

    // fx root tunnel
    address public fxRootTunnel;

    constructor(address _fxChild) {
        fxChild = _fxChild;
    }

    // Sender must be fxRootTunnel in case of ERC20 tunnel
    modifier validateSender(address sender) {
        require(sender == fxRootTunnel, "FxBaseChildTunnel: INVALID_SENDER_FROM_ROOT");
        _;
    }

    // set fxRootTunnel if not set already
    function setFxRootTunnel(address _fxRootTunnel) external {
        require(fxRootTunnel == address(0x0), "FxBaseChildTunnel: ROOT_TUNNEL_ALREADY_SET");
        fxRootTunnel = _fxRootTunnel;
    }

    function processMessageFromRoot(uint256 stateId, address rootMessageSender, bytes calldata data) external override {
        require(msg.sender == fxChild, "FxBaseChildTunnel: INVALID_SENDER");
        _processMessageFromRoot(stateId, rootMessageSender, data);
    }

    /**
     * @notice Emit message that can be received on Root Tunnel
     * @dev Call the internal function when need to emit message
     * @param message bytes message that will be sent to Root Tunnel
     * some message examples -
     *   abi.encode(tokenId);
     *   abi.encode(tokenId, tokenMetadata);
     *   abi.encode(messageType, messageData);
     */
    function _sendMessageToRoot(bytes memory message) internal {
        emit MessageSent(message);
    }

    /**
     * @notice Process message received from Root Tunnel
     * @dev function needs to be implemented to handle message as per requirement
     * This is called by onStateReceive function.
     * Since it is called via a system call, any event will not be emitted during its execution.
     * @param stateId unique state id
     * @param sender root message sender
     * @param message bytes message that was sent from Root Tunnel
     */
    function _processMessageFromRoot(uint256 stateId, address sender, bytes memory message) virtual internal;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../ISourceChild.sol";
import './FxBaseChildTunnel.sol';

/**
 * @title FxSourceChildTunnel
 */
contract FxSourceChildTunnel is FxBaseChildTunnel {
    bytes32 public constant WITHDRAW_SINGLE = keccak256("WITHDRAW_SINGLE");
    bytes32 public constant WITHDRAW_BATCH = keccak256("WITHDRAW_BATCH");
    bytes32 public constant DEPOSIT_SINGLE = keccak256("DEPOSIT_SINGLE");
    bytes32 public constant DEPOSIT_BATCH = keccak256("DEPOSIT_BATCH");
    uint256 public constant BATCH_LIMIT = 20;

    // event for token maping
    event TokenMap(address indexed rootToken, address indexed childToken);
    // child to root token
    mapping(address => address) public childToRootTokens;
    // root to child token
    mapping(address => address) public rootToChildTokens;

    constructor(address _fxChild)
        FxBaseChildTunnel(_fxChild) 
    {
    }

    /**
     * @notice Map a token to enable its movement via the PoS Portal
     * @param rootToken address of token on root chain
     * @param childToken address of token on child chain
     */
    function mapToken(address rootToken, address childToken) public {
        // check if token is already mapped
        require(rootToChildTokens[rootToken] == address(0x0), "FxSourceChildTunnel: ALREADY_MAPPED");
        require(childToRootTokens[childToken] == address(0x0), "FxSourceChildTunnel: ALREADY_MAPPED");
        rootToChildTokens[rootToken] = childToken;
        childToRootTokens[childToken] = rootToken;
        emit TokenMap(rootToken, childToken);
    }

    // WITHDRAW_SINGLE
    function withdraw(address childToken, uint256 tokenId, bytes memory tokenData) external {
        address rootToken = childToRootTokens[childToken];
        require (childToken == rootToChildTokens[rootToken], "FxSourceChildTunnel: NOT_MAPPED");

        // withdraw token
        ISourceChild(childToken).burn(tokenId, tokenData);

        // send message to root regarding token burn
        _sendMessageToRoot(abi.encode(WITHDRAW_SINGLE, rootToken, childToken, msg.sender, tokenId, tokenData));
    }

    // WITHDRAW_BATCH
    function withdraw(address childToken, uint256[] memory tokenIds, bytes[] memory tokenDatas) external {
        require(tokenIds.length <= BATCH_LIMIT, "FxSourceChildTunnel: EXCEEDS_BATCH_LIMIT");
        require(tokenDatas.length == tokenIds.length || tokenDatas.length == 0, "FxSourceChildTunnel: TOKEN_DATAS_MISMATCHED");
        address rootToken = childToRootTokens[childToken];
        require(childToken == rootToChildTokens[rootToken], "FxSourceChildTunnel: NOT_MAPPED");

        // withdraw tokens
        for (uint i=0; i<tokenIds.length; i++) {
            ISourceChild(childToken).burn(tokenIds[i], tokenDatas.length == tokenIds.length ? tokenDatas[i] : bytes(''));
        }

        // send message to root regarding token burn
        _sendMessageToRoot(abi.encode(WITHDRAW_BATCH, rootToken, childToken, msg.sender, tokenIds, tokenDatas));
    }

    //
    // Internal methods
    //
    function _processMessageFromRoot(uint256 /* stateId */, address sender, bytes memory data)
        internal
        override
        validateSender(sender) {

        // decode incoming data
        (bytes32 syncType, bytes memory syncData) = abi.decode(data, (bytes32, bytes));

        if (syncType == DEPOSIT_SINGLE) {
            _syncDepositSingle(syncData);
        }  else if (syncType == DEPOSIT_BATCH) {
            _syncDepositBatch(syncData);
        } else {
            revert("FxSourceChildTunnel: INVALID_SYNC_TYPE");
        }
    }

    function _syncDepositSingle(bytes memory syncData) internal {
        (address rootToken, address depositor, address receiveAddress, uint256 tokenId, uint256 seed, bytes memory tokenData) = abi.decode(syncData, (address, address, address, uint256, uint256, bytes));
        
        address childToken = rootToChildTokens[rootToken];

        // deposit token
        ISourceChild(childToken).mint(receiveAddress, tokenId, seed, tokenData);
    }

    function _syncDepositBatch(bytes memory syncData) internal {
        (address rootToken, address depositor, address receiveAddress, uint256[] memory tokenIds, uint256[] memory seeds, bytes[] memory tokenDatas) = abi.decode(syncData, (address, address, address, uint256[], uint256[], bytes[]));
        require(tokenIds.length > 0 && tokenIds.length == seeds.length);
        
        address childToken = rootToChildTokens[rootToken];

        for (uint i=0; i<tokenIds.length; i++) {
            // deposit tokens
            ISourceChild(childToken).mint(receiveAddress, tokenIds[i], seeds[i], tokenDatas.length == tokenIds.length ? tokenDatas[i] : bytes(''));
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

