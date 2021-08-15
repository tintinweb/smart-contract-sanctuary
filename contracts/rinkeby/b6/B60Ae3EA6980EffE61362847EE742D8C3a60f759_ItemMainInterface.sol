/**
 *Submitted for verification at Etherscan.io on 2021-08-15
*/

// File: node_modules\@openzeppelin\contracts\utils\introspection\IERC165.sol

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

// File: @openzeppelin\contracts\token\ERC1155\IERC1155.sol

// SPDX_License_Identifier: MIT

pragma solidity ^0.8.0;


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

// File: contracts\model\IERC1155Views.sol

// SPDX_License_Identifier: MIT

pragma solidity >=0.7.0;

/**
 * @title IERC1155Views - An optional utility interface to improve the ERC-1155 Standard.
 * @dev This interface introduces some additional capabilities for ERC-1155 Tokens.
 */
interface IERC1155Views {

    /**
     * @dev Returns the total supply of the given token id
     * @param itemId the id of the token whose availability you want to know 
     */
    function totalSupply(uint256 itemId) external view returns (uint256);

    /**
     * @dev Returns the name of the given token id
     * @param itemId the id of the token whose name you want to know 
     */
    function name(uint256 itemId) external view returns (string memory);

    /**
     * @dev Returns the symbol of the given token id
     * @param itemId the id of the token whose symbol you want to know 
     */
    function symbol(uint256 itemId) external view returns (string memory);

    /**
     * @dev Returns the decimals of the given token id
     * @param itemId the id of the token whose decimals you want to know 
     */
    function decimals(uint256 itemId) external view returns (uint256);

    /**
     * @dev Returns the uri of the given token id
     * @param itemId the id of the token whose uri you want to know 
     */
    function uri(uint256 itemId) external view returns (string memory);
}

// File: contracts\model\Item.sol

//SPDX_License_Identifier: MIT

pragma solidity >=0.7.0;
pragma abicoder v2;



struct Header {
    address host;
    string name;
    string symbol;
    string uri;
}

struct CreateItem {
    Header header;
    bytes32 collectionId;
    uint256 id;
    address[] accounts;
    uint256[] amounts;
}

interface Item is IERC1155, IERC1155Views {

    event CollectionItem(bytes32 indexed fromCollectionId, bytes32 indexed toCollectionId, uint256 indexed itemId);

    function name() external view returns(string memory);
    function symbol() external view returns(string memory);

    function burn(address account, uint256 itemId, uint256 amount) external;
    function burnBatch(address account, uint256[] calldata itemIds, uint256[] calldata amounts) external;

    function burn(address account, uint256 itemId, uint256 amount, bytes calldata data) external;
    function burnBatch(address account, uint256[] calldata itemIds, uint256[] calldata amounts, bytes calldata data) external;

    function mintItems(CreateItem[] calldata items) external returns(uint256[] memory itemIds);
    function setItemsCollection(uint256[] calldata itemIds, bytes32[] calldata collectionIds) external returns(bytes32[] memory oldCollectionIds);
    function setItemsMetadata(uint256[] calldata itemIds, Header[] calldata amounts) external returns(Header[] memory oldValues);

    function interoperableOf(uint256 itemId) external view returns(address);
}

// File: node_modules\@ethereansos\swissknife\contracts\generic\model\ILazyInitCapableElement.sol

// SPDX_License_Identifier: MIT
pragma solidity >=0.7.0;


interface ILazyInitCapableElement is IERC165 {

    function lazyInit(bytes calldata lazyInitData) external returns(bytes memory initResponse);
    function initializer() external view returns(address);

    event Host(address indexed from, address indexed to);

    function host() external view returns(address);
    function setHost(address newValue) external returns(address oldValue);

    function subjectIsAuthorizedFor(address subject, address location, bytes4 selector, bytes calldata payload, uint256 value) external view returns(bool);
}

// File: @ethereansos\swissknife\contracts\dynamicMetadata\model\IDynamicMetadataCapableElement.sol

//SPDX_License_Identifier: MIT
pragma solidity >=0.7.0;


interface IDynamicMetadataCapableElement is ILazyInitCapableElement {

    function uri() external view returns(string memory);
    function plainUri() external view returns(string memory);

    function setUri(string calldata newValue) external returns (string memory oldValue);

    function dynamicUriResolver() external view returns(address);
    function setDynamicUriResolver(address newValue) external returns(address oldValue);
}

// File: contracts\model\IItemMainInterface.sol

//SPDX_License_Identifier: MIT
pragma solidity >=0.7.0;



struct ItemData {
    bytes32 collectionId;
    Header header;
    bytes32 domainSeparator;
    uint256 totalSupply;
    mapping(address => uint256) balanceOf;
    mapping(address => mapping(address => uint256)) allowance;
    mapping(address => uint256) nonces;
}

interface IItemMainInterface is Item, IDynamicMetadataCapableElement {

    event Collection(address indexed from, address indexed to, bytes32 indexed collectionId);

    function interoperableInterfaceModel() external view returns(address);
    function setInteroperableInterfaceModel(address value) external returns(address oldValue);

    function collection(bytes32 collectionId) external view returns(address host, string memory name, string memory symbol, string memory uri);
    function collectionUri(bytes32 collectionId) external view returns(string memory);
    function createCollection(Header calldata _collection, CreateItem[] calldata items) external returns(bytes32 collectionId, uint256[] memory itemIds);
    function setCollectionsMetadata(bytes32[] calldata collectionIds, Header[] calldata values) external returns(Header[] memory oldValues);
    function isApprovedForCollection(address account, address operator, bytes32 collectionId) external view returns (bool);
    function setApprovalForCollection(bytes32 collectionId, address account, address operator, bool approved) external;

    function item(uint256 itemId) external view returns(bytes32 collectionId, Header memory header, bytes32 domainSeparator, uint256 totalSupply);

    function mintTransferOrBurn(bool isMulti, bytes calldata data) external;

    function allowance(address account, address spender, uint256 itemId) external view returns(uint256);
    function approve(address account, address spender, uint256 amount, uint256 itemId) external;
    function TYPEHASH_PERMIT() external view returns (bytes32);
    function EIP712_PERMIT_DOMAINSEPARATOR_NAME_AND_VERSION() external view returns(string memory domainSeparatorName, string memory domainSeparatorVersion);
    function permit(uint256 itemId, address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    function nonces(uint256 itemId, address owner) external view returns(uint256);
}

// File: @openzeppelin\contracts\token\ERC20\IERC20.sol

// SPDX_License_Identifier: MIT

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

// File: @openzeppelin\contracts\token\ERC20\extensions\IERC20Metadata.sol

// SPDX_License_Identifier: MIT

pragma solidity ^0.8.0;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// File: @openzeppelin\contracts\token\ERC20\extensions\draft-IERC20Permit.sol

// SPDX_License_Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// File: contracts\model\IItemInteroperableInterface.sol

//SPDX_License_Identifier: MIT

pragma solidity >=0.7.0;




interface IItemInteroperableInterface is IERC20, IERC20Metadata, IERC20Permit {

    function init() external;
    function mainInterface() external view returns(address);
    function itemId() external view returns(uint256);
    function emitEvent(bool forApprove, bool isMulti, bytes calldata data) external;
    function burn(uint256 amount) external;
    function EIP712_PERMIT_DOMAINSEPARATOR_NAME_AND_VERSION() external view returns(string memory name, string memory version);
}

// File: node_modules\@ethereansos\swissknife\contracts\dynamicMetadata\model\IDynamicUriResolver.sol

//SPDX_License_Identifier: MIT
pragma solidity >=0.7.0;

interface IDynamicUriResolver {
    function resolve(address subject, string calldata plainUri, bytes calldata inputData, address caller) external view returns(string memory);
}

// File: node_modules\@ethereansos\swissknife\contracts\lib\GeneralUtilities.sol

// SPDX_License_Identifier: MIT
pragma solidity >=0.7.0;

library BehaviorUtilities {

    function randomKey(uint256 i) internal view returns (bytes32) {
        return keccak256(abi.encode(i, block.timestamp, block.number, tx.origin, tx.gasprice, block.coinbase, block.difficulty, msg.sender, blockhash(block.number - 5)));
    }

    function calculateProjectedArraySizeAndLoopUpperBound(uint256 arraySize, uint256 start, uint256 offset) internal pure returns(uint256 projectedArraySize, uint256 projectedArrayLoopUpperBound) {
        if(arraySize != 0 && start < arraySize && offset != 0) {
            uint256 length = start + offset;
            if(start < (length = length > arraySize ? arraySize : length)) {
                projectedArraySize = (projectedArrayLoopUpperBound = length) - start;
            }
        }
    }
}

library ReflectionUtilities {

    function read(address subject, bytes memory inputData) internal view returns(bytes memory returnData) {
        bool result;
        (result, returnData) = subject.staticcall(inputData);
        if(!result) {
            assembly {
                revert(add(returnData, 0x20), mload(returnData))
            }
        }
    }

    function submit(address subject, uint256 value, bytes memory inputData) internal returns(bytes memory returnData) {
        bool result;
        (result, returnData) = subject.call{value : value}(inputData);
        if(!result) {
            assembly {
                revert(add(returnData, 0x20), mload(returnData))
            }
        }
    }

    function isContract(address subject) internal view returns (bool) {
        if(subject == address(0)) {
            return false;
        }
        uint256 codeLength;
        assembly {
            codeLength := extcodesize(subject)
        }
        return codeLength > 0;
    }

    function clone(address originalContract) internal returns(address copyContract) {
        assembly {
            mstore(
                0,
                or(
                    0x5880730000000000000000000000000000000000000000803b80938091923cF3,
                    mul(originalContract, 0x1000000000000000000)
                )
            )
            copyContract := create(0, 0, 32)
            switch extcodesize(copyContract)
                case 0 {
                    invalid()
                }
        }
    }
}

library BytesUtilities {

    bytes private constant ALPHABET = "0123456789abcdef";

    function asAddress(bytes memory b) internal pure returns(address) {
        if(b.length == 0) {
            return address(0);
        }
        if(b.length == 20) {
            address addr;
            assembly {
                addr := mload(add(b, 20))
            }
            return addr;
        }
        return abi.decode(b, (address));
    }

    function asAddressArray(bytes memory b) internal pure returns(address[] memory callResult) {
        if(b.length > 0) {
            return abi.decode(b, (address[]));
        }
    }

    function asBool(bytes memory bs) internal pure returns(bool) {
        return asUint256(bs) != 0;
    }

    function asBoolArray(bytes memory b) internal pure returns(bool[] memory callResult) {
        if(b.length > 0) {
            return abi.decode(b, (bool[]));
        }
    }

    function asBytesArray(bytes memory b) internal pure returns(bytes[] memory callResult) {
        if(b.length > 0) {
            return abi.decode(b, (bytes[]));
        }
    }

    function asString(bytes memory b) internal pure returns(string memory callResult) {
        if(b.length > 0) {
            return abi.decode(b, (string));
        }
    }

    function asStringArray(bytes memory b) internal pure returns(string[] memory callResult) {
        if(b.length > 0) {
            return abi.decode(b, (string[]));
        }
    }

    function asUint256(bytes memory bs) internal pure returns(uint256 x) {
        if (bs.length >= 32) {
            assembly {
                x := mload(add(bs, add(0x20, 0)))
            }
        }
    }

    function asUint256Array(bytes memory b) internal pure returns(uint256[] memory callResult) {
        if(b.length > 0) {
            return abi.decode(b, (uint256[]));
        }
    }

    function toString(bytes memory data) internal pure returns(string memory) {
        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint i = 0; i < data.length; i++) {
            str[2+i*2] = ALPHABET[uint(uint8(data[i] >> 4))];
            str[3+i*2] = ALPHABET[uint(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }
}

library StringUtilities {

    bytes1 private constant CHAR_0 = bytes1('0');
    bytes1 private constant CHAR_A = bytes1('A');
    bytes1 private constant CHAR_a = bytes1('a');
    bytes1 private constant CHAR_f = bytes1('f');

    function isEmpty(string memory test) internal pure returns (bool) {
        return equals(test, "");
    }

    function equals(string memory a, string memory b) internal pure returns(bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    function toLowerCase(string memory str) internal pure returns(string memory) {
        bytes memory bStr = bytes(str);
        for (uint i = 0; i < bStr.length; i++) {
            bStr[i] = bStr[i] >= 0x41 && bStr[i] <= 0x5A ? bytes1(uint8(bStr[i]) + 0x20) : bStr[i];
        }
        return string(bStr);
    }

    function asBytes(string calldata str) internal pure returns(bytes memory toDecode) {
        bytes memory data = abi.encodePacked(str);
        if(data.length == 0 || data[0] != "0" || (data[1] != "x" && data[1] != "X")) {
            return "";
        }
        uint256 start = 2;
        toDecode = new bytes((data.length - 2) / 2);

        for(uint256 i = 0; i < toDecode.length; i++) {
            toDecode[i] = bytes1(_fromHexChar(uint8(data[start++])) + _fromHexChar(uint8(data[start++])) * 16);
        }
    }

    function _fromHexChar(uint8 c) private pure returns (uint8) {
        bytes1 charc = bytes1(c);
        return charc < CHAR_0 || charc > CHAR_f ? 0 : (charc < CHAR_A ? 0 : 10) + c - uint8(charc < CHAR_A ? CHAR_0 : charc < CHAR_a ? CHAR_A : CHAR_a);
    }
}

library Uint256Utilities {
    function asSingletonArray(uint256 n) internal pure returns(uint256[] memory array) {
        array = new uint256[](1);
        array[0] = n;
    }

    function toString(uint256 _i) internal pure returns (string memory) {
        return BytesUtilities.toString(abi.encodePacked(_i));
    }
}

library AddressUtilities {
    function asSingletonArray(address a) internal pure returns(address[] memory array) {
        array = new address[](1);
        array[0] = a;
    }

    function toString(address _addr) internal pure returns (string memory) {
        return _addr == address(0) ? "0x0000000000000000000000000000000000000000" : BytesUtilities.toString(abi.encodePacked(_addr));
    }
}

library Bytes32Utilities {

    function asSingletonArray(bytes32 a) internal pure returns(bytes32[] memory array) {
        array = new bytes32[](1);
        array[0] = a;
    }

    function toString(bytes32 bt) internal pure returns (string memory) {
        return bt == bytes32(0) ?  "0x0000000000000000000000000000000000000000000000000000000000000000" : BytesUtilities.toString(abi.encodePacked(bt));
    }
}

// File: node_modules\@ethereansos\swissknife\contracts\generic\impl\LazyInitCapableElement.sol

// SPDX_License_Identifier: MIT
pragma solidity >=0.7.0;



abstract contract LazyInitCapableElement is ILazyInitCapableElement {
    using ReflectionUtilities for address;

    address public override initializer;
    address public override host;

    constructor(bytes memory lazyInitData) {
        if(lazyInitData.length > 0) {
            _privateLazyInit(lazyInitData);
        }
    }

    function lazyInit(bytes calldata lazyInitData) override external returns (bytes memory lazyInitResponse) {
        return _privateLazyInit(lazyInitData);
    }

    function supportsInterface(bytes4 interfaceId) override external view returns(bool) {
        return
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == this.supportsInterface.selector ||
            interfaceId == type(ILazyInitCapableElement).interfaceId ||
            interfaceId == this.lazyInit.selector ||
            interfaceId == this.initializer.selector ||
            interfaceId == this.subjectIsAuthorizedFor.selector ||
            interfaceId == this.host.selector ||
            interfaceId == this.setHost.selector ||
            _supportsInterface(interfaceId);
    }

    function setHost(address newValue) external override authorizedOnly returns(address oldValue) {
        emit Host(oldValue = host, host = newValue);
    }

    function subjectIsAuthorizedFor(address subject, address location, bytes4 selector, bytes calldata payload, uint256 value) public override virtual view returns(bool) {
        (bool chidlElementValidationIsConsistent, bool chidlElementValidationResult) = _subjectIsAuthorizedFor(subject, location, selector, payload, value);
        if(chidlElementValidationIsConsistent) {
            return chidlElementValidationResult;
        }
        if(subject == host) {
            return true;
        }
        if(!host.isContract()) {
            return false;
        }
        (bool result, bytes memory resultData) = host.staticcall(abi.encodeWithSelector(ILazyInitCapableElement(host).subjectIsAuthorizedFor.selector, subject, location, selector, payload, value));
        return result && abi.decode(resultData, (bool));
    }

    function _privateLazyInit(bytes memory lazyInitData) private returns (bytes memory lazyInitResponse) {
        require(initializer == address(0), "init");
        initializer = msg.sender;
        (host, lazyInitResponse) = abi.decode(lazyInitData, (address, bytes));
        emit Host(address(0), host);
        lazyInitResponse = _lazyInit(lazyInitResponse);
    }

    function _lazyInit(bytes memory) internal virtual returns (bytes memory) {
        return "";
    }

    function _supportsInterface(bytes4 selector) internal virtual view returns (bool);

    function _subjectIsAuthorizedFor(address, address, bytes4, bytes calldata, uint256) internal virtual view returns(bool, bool) {
    }

    modifier authorizedOnly {
        require(_authorizedOnly(), "unauthorized");
        _;
    }

    function _authorizedOnly() internal returns(bool) {
        return subjectIsAuthorizedFor(msg.sender, address(this), msg.sig, msg.data, msg.value);
    }
}

// File: @ethereansos\swissknife\contracts\dynamicMetadata\impl\DynamicMetadataCapableElement.sol

//SPDX_License_Identifier: MIT
pragma solidity >=0.7.0;




abstract contract DynamicMetadataCapableElement is IDynamicMetadataCapableElement, LazyInitCapableElement {

    string public override plainUri;
    address public override dynamicUriResolver;

    constructor(bytes memory lazyInitData) LazyInitCapableElement(lazyInitData) {
    }

    function _lazyInit(bytes memory lazyInitData) internal override returns (bytes memory lazyInitResponse) {
        (plainUri, dynamicUriResolver, lazyInitResponse) = abi.decode(lazyInitData, (string, address, bytes));
        lazyInitResponse = _dynamicMetadataElementLazyInit(lazyInitResponse);
    }

    function _supportsInterface(bytes4 interfaceId) internal override view returns(bool) {
        return
            interfaceId == type(IDynamicMetadataCapableElement).interfaceId ||
            interfaceId == this.plainUri.selector ||
            interfaceId == this.uri.selector ||
            interfaceId == this.dynamicUriResolver.selector ||
            interfaceId == this.setUri.selector ||
            interfaceId == this.setDynamicUriResolver.selector ||
            _dynamicMetadataElementSupportsInterface(interfaceId);
    }

    function uri() external override view returns(string memory) {
        return _uri(plainUri, "");
    }

    function setUri(string calldata newValue) external override authorizedOnly returns (string memory oldValue) {
        oldValue = plainUri;
        plainUri = newValue;
    }

    function setDynamicUriResolver(address newValue) external override authorizedOnly returns(address oldValue) {
        oldValue = dynamicUriResolver;
        dynamicUriResolver = newValue;
    }

    function _uri(string memory _plainUri, bytes memory additionalData) internal view returns(string memory) {
        if(dynamicUriResolver == address(0)) {
            return _plainUri;
        }
        return IDynamicUriResolver(dynamicUriResolver).resolve(address(this), _plainUri, additionalData, msg.sender);
    }

    function _dynamicMetadataElementLazyInit(bytes memory lazyInitData) internal virtual returns(bytes memory);

    function _dynamicMetadataElementSupportsInterface(bytes4 interfaceId) internal virtual view returns(bool);
}

// File: @openzeppelin\contracts\token\ERC1155\IERC1155Receiver.sol

// SPDX_License_Identifier: MIT

pragma solidity ^0.8.0;


/**
 * @dev _Available since v3.1._
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

// File: contracts\util\ERC1155CommonLibrary.sol

//SPDX_License_Identifier: MIT
pragma solidity >=0.7.0;



library ERC1155CommonLibrary {
    using ReflectionUtilities for address;

    function doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) internal {
        if (to.isContract()) {
            try
                IERC1155Receiver(to).onERC1155Received(
                    operator,
                    from,
                    id,
                    amount,
                    data
                )
            returns (bytes4 response) {
                if (
                    response != IERC1155Receiver(to).onERC1155Received.selector
                ) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) internal {
        if (to.isContract()) {
            try
                IERC1155Receiver(to).onERC1155BatchReceived(
                    operator,
                    from,
                    ids,
                    amounts,
                    data
                )
            returns (bytes4 response) {
                if (
                    response !=
                    IERC1155Receiver(to).onERC1155BatchReceived.selector
                ) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }
}

// File: contracts\impl\ItemMainInterface.sol

//SPDX_License_Identifier: MIT

pragma solidity >=0.7.0;
//pragma abicoder v2;






contract ItemMainInterface is IItemMainInterface, DynamicMetadataCapableElement {
    using ReflectionUtilities for address;

    bytes32 override public constant TYPEHASH_PERMIT = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    address override public interoperableInterfaceModel;

    mapping(bytes32 => Header) override public collection;
    mapping(uint256 => ItemData) override public item;
    mapping(address => mapping(address => mapping(bytes32 => bool))) private _isApprovedForCollection;

    uint256 private _keyIndex;

    mapping(uint256 => uint256[]) private _items;
    uint256 private _itemsLength;
    mapping(uint256 => uint256) private _itemsIndexes;

    mapping(bytes32 => uint256[]) private _batchItems;
    mapping(bytes32 => mapping(uint256 => uint256)) private _batchAmounts;
    bytes32[] private _batchKeys;

    constructor(bytes memory lazyInitData) DynamicMetadataCapableElement(lazyInitData) {
    }

    function _dynamicMetadataElementLazyInit(bytes memory lazyInitData) internal override returns(bytes memory) {
        interoperableInterfaceModel = abi.decode(lazyInitData, (address));
        return "";
    }

    function _dynamicMetadataElementSupportsInterface(bytes4 interfaceId) internal override pure returns (bool) {
        /*return interfaceId == type(IERC1155).interfaceId ||
        interfaceId == type(IERC1155Views).interfaceId ||
        interfaceId == type(Item).interfaceId ||
        interfaceId == type(IItemMainInterface).interfaceId;
        interfaceId == this.balanceOf.selector ||
        interfaceId == this.balanceOfBatch.selector ||
        interfaceId == this.setApprovalForAll.selector ||
        interfaceId == this.isApprovedForAll.selector ||
        interfaceId == this.safeTransferFrom.selector ||
        interfaceId == this.safeBatchTransferFrom.selector ||
        interfaceId == this.totalSupply.selector ||
        interfaceId == 0x00ad800c ||//name(uint256)
        interfaceId == 0x4e41a1fb ||//symbol(uint256)
        interfaceId == this.decimals.selector ||
        interfaceId == 0x0e89341c ||//uri(uint256)
        interfaceId == 0x06fdde03 ||//name()
        interfaceId == 0x95d89b41 ||//symbol()
        interfaceId == 0xf5298aca ||//burn(address,uint256,uint256)
        interfaceId == 0x6b20c454 ||//burnBatch(address,uint256[],uint256[])
        interfaceId == 0x8a94b05f ||//burn(address,uint256,uint256,bytes)
        interfaceId == 0x5473422e ||//burnBatch(address,uint256[],uint256[],bytes)
        interfaceId == this.mintItems.selector ||
        interfaceId == this.setItemsCollection.selector ||
        interfaceId == this.setItemsMetadata.selector ||
        interfaceId == this.interoperableOf.selector ||
        interfaceId == this.interoperableInterfaceModel.selector ||
        interfaceId == this.setInteroperableInterfaceModel.selector ||
        interfaceId == this.collection.selector ||
        interfaceId == this.collectionUri.selector ||
        interfaceId == this.createCollection.selector ||
        interfaceId == this.setCollectionsMetadata.selector ||
        interfaceId == this.isApprovedForCollection.selector ||
        interfaceId == this.setApprovalForCollection.selector ||
        interfaceId == this.item.selector ||
        interfaceId == this.mintTransferOrBurn.selector ||
        interfaceId == this.allowance.selector ||
        interfaceId == this.approve.selector ||
        interfaceId == this.TYPEHASH_PERMIT.selector ||
        interfaceId == this.EIP712_PERMIT_DOMAINSEPARATOR_NAME_AND_VERSION.selector ||
        interfaceId == this.permit.selector ||
        interfaceId == this.nonces.selector;*/
    }

    function setInteroperableInterfaceModel(address value) authorizedOnly override external returns(address oldValue) {
        oldValue = interoperableInterfaceModel;
        interoperableInterfaceModel = value;
    }

    function name() override external pure returns(string memory) {
        return "EthItem";
    }

    function name(uint256 itemId) override external view returns(string memory) {
        return item[itemId].header.name;
    }

    function symbol() override external pure returns(string memory) {
        return "ITEM";
    }

    function symbol(uint256 itemId) override external view returns(string memory) {
        return item[itemId].header.symbol;
    }

    function decimals(uint256) override external pure returns(uint256) {
        return 18;
    }

    function collectionUri(bytes32 collectionId) override external view returns(string memory) {
        return _uri(collection[collectionId].uri, abi.encode(collectionId, 0));
    }

    function uri(uint256 itemId) override external view returns(string memory) {
        ItemData storage itemData = item[itemId];
        return _uri(itemData.header.uri, abi.encode(itemData.collectionId, itemId));
    }

    function setCollectionsMetadata(bytes32[] calldata collectionIds, Header[] calldata values) override external returns(Header[] memory oldValues) {
        oldValues = new Header[](values.length);
        for(uint256 i = 0; i < values.length; i++) {
            Header storage oldValue = collection[collectionIds[i]];
            require((oldValues[i] = oldValue).host == msg.sender, "Unauthorized");
            address newHost = (collection[collectionIds[i]] = _validateHeader(values[i], bytes32(0))).host;
            if(newHost != oldValues[i].host) {
                emit Collection(oldValues[i].host, newHost, collectionIds[i]);
            }
        }
    }

    function setItemsCollection(uint256[] calldata itemIds, bytes32[] calldata collectionIds) override external returns(bytes32[] memory oldCollectionIds) {
        oldCollectionIds = new bytes32[](itemIds.length);
        for(uint256 i = 0; i < itemIds.length; i++) {
            ItemData storage itemData = item[itemIds[i]];
            require(collection[oldCollectionIds[i] = itemData.collectionId].host == msg.sender, "Unauthorized");
            require(!_stringIsEmpty(collection[itemData.collectionId = collectionIds[i]].name), "collection");
            emit CollectionItem(oldCollectionIds[i], collectionIds[i], itemIds[i]);
        }
    }

    function setItemsMetadata(uint256[] calldata itemIds, Header[] calldata values) override external returns(Header[] memory oldValues) {
        oldValues = new Header[](values.length);
        for(uint256 i = 0; i < values.length; i++) {
            ItemData storage itemData = item[itemIds[i]];
            oldValues[i] = itemData.header;
            require(collection[itemData.collectionId].host == msg.sender, "Unauthorized");
            itemData.header = _validateHeader(values[i], itemData.collectionId);
            if(keccak256(bytes(itemData.header.uri)) != keccak256(bytes(oldValues[i].uri))) {
                emit URI(itemData.header.uri, itemIds[i]);
            }
        }
    }

    function totalSupply(uint256 itemId) override external view returns(uint256) {
        return item[itemId].totalSupply;
    }

    function balanceOf(address account, uint256 id) override external view returns (uint256) {
        return item[id].balanceOf[account];
    }

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) override external view returns (uint256[] memory balances) {
        balances = new uint256[](ids.length);
        for(uint256 i = 0; i < balances.length; i++) {
            balances[i] = item[ids[i]].balanceOf[accounts[i]];
        }
    }

    function isApprovedForCollection(address account, address operator, bytes32 collectionId) override public view returns (bool) {
        return _isApprovedForCollection[account][operator][bytes32(0)] || _isApprovedForCollection[account][operator][collectionId];
    }

    function allowance(address owner, address spender, uint256 itemId) override external view returns (uint256) {
        return isApprovedForCollection(owner, spender, item[itemId].collectionId) ? 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff : item[itemId].allowance[owner][spender];
    }

    function isApprovedForAll(address account, address operator) override external view returns (bool) {
        return _isApprovedForCollection[account][operator][bytes32(0)];
    }

    function setApprovalForAll(address operator, bool approved) override external {
        _isApprovedForCollection[msg.sender][operator][bytes32(0)] = approved;
    }

    function setApprovalForCollection(bytes32 collectionId, address account, address operator, bool approved) override external {
        require(collectionId == bytes32(0) || keccak256(bytes(collection[collectionId].symbol)) != keccak256(""), "No collection");
        require(account == msg.sender || collection[collectionId].host == msg.sender, "Unauthorized");
        _isApprovedForCollection[account][operator][collectionId] = approved;
    }

    function interoperableOf(uint256 itemId) override external view returns(address) {
        return item[itemId].collectionId == bytes32(0) ? address(0) : address(uint160(itemId));
    }

    function safeTransferFrom(address from, address to, uint256 itemId, uint256 amount, bytes calldata data) override external {
        _mintTransferOrBurn(item[itemId], msg.sender, from, to, itemId, amount, true);
        ERC1155CommonLibrary.doSafeTransferAcceptanceCheck(msg.sender, from, to, itemId, amount, data);
    }

    function safeBatchTransferFrom(address from, address to, uint256[] calldata itemIds, uint256[] calldata amounts, bytes calldata data) override external {
        _mintTransferOrBurn(msg.sender, from, to, itemIds, amounts, false, true);
        ERC1155CommonLibrary.doSafeBatchTransferAcceptanceCheck(msg.sender, from, to, itemIds, amounts, data);
    }

    function burn(address account, uint256 itemId, uint256 amount) override external {
        burn(account, itemId, amount, "");
    }

    function burnBatch(address account, uint256[] calldata itemIds, uint256[] calldata amounts) override external {
        burnBatch(account, itemIds, amounts, "");
    }

    function burn(address account, uint256 itemId, uint256 amount, bytes memory) override public {
        _mintTransferOrBurn(item[itemId], msg.sender, account, address(0), itemId, amount, true);
    }

    function burnBatch(address account, uint256[] calldata itemIds, uint256[] calldata amounts, bytes memory) override public {
        _mintTransferOrBurn(msg.sender, account, address(0), itemIds, amounts, false, true);
    }

    function createCollection(Header calldata _collection, CreateItem[] calldata items) override external returns(bytes32 collectionId, uint256[] memory itemIds) {
        Header storage storageCollection = (collection[collectionId = BehaviorUtilities.randomKey(_keyIndex++)] = _validateHeader(_collection, bytes32(0)));
        require(storageCollection.host != address(0) || items.length > 0, "Empty");
        emit Collection(address(0), storageCollection.host, collectionId);
        itemIds = _createOrMintItems(collectionId, items);
    }

    function mintItems(CreateItem[] calldata items) override external returns(uint256[] memory) {
        return _createOrMintItems(bytes32(0), items);
    }

    function approve(address account, address spender, uint256 amount, uint256 itemId) override external {
        ItemData storage itemData = msg.sender == account ? item[itemId] : _checkItemPermissionAndRetrieveData(itemId);
        require(spender != address(0), "approve to the zero address");
        itemData.allowance[account][spender] = amount;
    }

    function mintTransferOrBurn(bool isMulti, bytes calldata data) override external {
        if(isMulti) {
            _mintTransferOrBurn(data);
            return;
        }
        (address operator, address sender, address recipient, uint256 itemId, uint256 amount) = abi.decode(data, (address, address, address, uint256, uint256));
        _mintTransferOrBurn(_checkItemPermissionAndRetrieveData(itemId), operator, sender, recipient, itemId, amount, true);
    }

    function permit(uint256 itemId, address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) override external {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");
        ItemData storage itemData = item[itemId];
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                itemData.domainSeparator,
                keccak256(abi.encode(TYPEHASH_PERMIT, owner, spender, value, itemData.nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'INVALID_SIGNATURE');
        itemData.allowance[owner][spender] = value;
    }

    function nonces(uint256 itemId, address owner) external override view returns(uint256) {
        return item[itemId].nonces[owner];
    }

    function EIP712_PERMIT_DOMAINSEPARATOR_NAME_AND_VERSION() public override pure returns(string memory, string memory) {
        return ("Item", "1");
    }

    function _validateHeader(Header memory header, bytes32 collectionId) private view returns(Header memory) {
        require(!_stringIsEmpty(header.name = _stringIsEmpty(header.name) && collectionId != bytes32(0) ? collection[collectionId].name : header.name), "name");
        require(!_stringIsEmpty(header.symbol = _stringIsEmpty(header.symbol) && collectionId != bytes32(0) ? collection[collectionId].symbol : header.symbol), "symbol");
        require(!_stringIsEmpty(header.uri = _stringIsEmpty(header.uri) && collectionId != bytes32(0) ? collection[collectionId].uri : header.uri), "uri");
        header.host = collectionId != bytes32(0) ? address(0) : header.host;
        return header;
    }

    function _createOrMintItems(bytes32 createdCollectionId, CreateItem[] calldata items) private returns(uint256[] memory itemIds) {
        itemIds = new uint256[](items.length);
        for(uint256 i = 0; i < items.length; i++) {
            CreateItem memory itemToCreate = items[i];
            itemIds[i] = createdCollectionId != bytes32(0) ? 0 : itemToCreate.id;
            itemToCreate.collectionId = createdCollectionId != bytes32(0) ? createdCollectionId : itemToCreate.id != 0 ? item[itemToCreate.id].collectionId : itemToCreate.collectionId;
            require(createdCollectionId != bytes32(0) || (itemToCreate.collectionId != bytes32(0) && msg.sender == collection[itemToCreate.collectionId].host), "Unauthorized");
            if(itemIds[i] == 0) {
                address interoperableInterfaceAddress = interoperableInterfaceModel.clone();
                IItemInteroperableInterface(interoperableInterfaceAddress).init();
                ItemData storage newItem = item[itemIds[i] = uint160(interoperableInterfaceAddress)];
                newItem.collectionId = itemToCreate.collectionId;
                newItem.header = _validateHeader(itemToCreate.header, itemToCreate.collectionId);
                (string memory domainSeparatorName, string memory domainSeparatorVersion) = EIP712_PERMIT_DOMAINSEPARATOR_NAME_AND_VERSION();
                newItem.domainSeparator = keccak256(
                    abi.encode(
                        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                        keccak256(bytes(domainSeparatorName)),
                        keccak256(bytes(domainSeparatorVersion)),
                        block.chainid,
                        address(uint160(itemIds[i]))
                    )
                );
                emit CollectionItem(bytes32(0), newItem.collectionId, itemIds[i]);
                emit URI(newItem.header.uri, itemIds[i]);
            }
            _mint(itemIds[i], itemToCreate.accounts, itemToCreate.amounts);
        }
    }

    function _mint(uint256 itemId, address[] memory accounts, uint256[] memory amounts) private {
        for(uint256 i = 0; i < accounts.length; i++) {
            require(accounts[i] != address(0), "mint to the zero address");
            _mintTransferOrBurn(address(0), address(0), accounts[i], itemId, amounts[i], false);
        }
        _emitMultiEventsAndClear();
    }

    function _mintTransferOrBurn(bytes memory data) private {
        bool batch;
        (batch, data) = abi.decode(data, (bool, bytes));
        if(batch) {
            _mintTransferOrBurnBatch(data);
        } else {
            (address[] memory origins, address[] memory senders, address[] memory recipients, uint256[] memory itemIds, uint256[] memory amounts) = abi.decode(data, (address[], address[], address[], uint256[], uint256[]));
            for(uint256 i = 0; i < itemIds.length; i++) {
                _mintTransferOrBurn(origins[i], senders[i], recipients[i], itemIds[i], amounts[i], true);
            }
        }
        _emitMultiEventsAndClear();
    }

    function _mintTransferOrBurnBatch(bytes memory data) private {
        bytes[] memory batches = abi.decode(data, (bytes[]));
        for(uint256 i = 0; i < batches.length; i++) {
            (address operator, address sender, address recipient, uint256[] memory itemIds, uint256[] memory amounts) = abi.decode(batches[i], (address, address, address, uint256[], uint256[]));
            _mintTransferOrBurn(operator, sender, recipient, itemIds, amounts, true, false);
        }
    }

    function _mintTransferOrBurn(address operator, address sender, address recipient, uint256[] memory itemIds, uint256[] memory amounts, bool check, bool launchEvents) private {
        for(uint256 i = 0; i < itemIds.length; i++) {
            _mintTransferOrBurn(operator, sender, recipient, itemIds[i], amounts[i], check);
        }
        if(launchEvents) {
            _emitMultiEventsAndClear();
        }
    }

    function _mintTransferOrBurn(address operator, address sender, address recipient, uint256 itemId, uint256 amount, bool check) private {
        if(amount == 0) {
            return;
        }
        uint256 tokenIndex = _itemsIndexes[itemId];
        uint256[] storage items = _items[tokenIndex];
        if(items.length == 0 || items[0] != itemId) {
            items = _items[tokenIndex = _itemsIndexes[itemId] = _itemsLength++];
            items.push(itemId);
        }
        items.push(uint160(sender));
        items.push(uint160(recipient));
        items.push(amount);

        bytes32 key = keccak256(abi.encodePacked(operator, sender, recipient));
        items = _batchItems[key];
        if(items.length == 0) {
            _batchKeys.push(key);
            items.push(uint160(operator));
            items.push(uint160(sender));
            items.push(uint160(recipient));
        }
        if(_batchAmounts[key][itemId] == 0) {
            items.push(itemId);
        }
        _batchAmounts[key][itemId] += amount;
        _mintTransferOrBurn(check ? _checkItemPermissionAndRetrieveData(itemId) : item[itemId], operator, sender, recipient, itemId, amount, false);
    }

    function _mintTransferOrBurn(ItemData storage itemData, address operator, address sender, address recipient, uint256 itemId, uint256 amount, bool launchEvent) private {
        if(sender != address(0)) {
            if(operator != sender) {
                require(itemData.allowance[sender][operator] >= amount || isApprovedForCollection(sender, operator, itemData.collectionId), "amount exceeds allowance");
                if(itemData.allowance[sender][operator] >= amount) {
                    itemData.allowance[sender][operator] -= amount;
                } else {
                    delete itemData.allowance[sender][operator];
                }
            }
            require(itemData.balanceOf[sender] >= amount, "amount exceeds balance");
            itemData.balanceOf[sender] -= amount;
        } else {
            itemData.totalSupply += amount;
        }
        if(recipient != address(0)) {
            itemData.balanceOf[recipient] += amount;
        } else {
            itemData.totalSupply -= amount;
        }
        if(launchEvent) {
            emit TransferSingle(operator, sender, recipient, itemId, amount);
            if(itemId != uint160(msg.sender)) {
                IItemInteroperableInterface(address(uint160(itemId))).emitEvent(false, false, abi.encode(sender, recipient, amount));
            }
        }
    }

    function _checkItemPermissionAndRetrieveData(uint256 itemId) private view returns (ItemData storage itemData) {
        require(collection[(itemData = item[itemId]).collectionId].host == msg.sender || uint160(msg.sender) == itemId, "Unauthorized");
    }

    function _stringIsEmpty(string memory test) private pure returns(bool) {
        return keccak256(bytes(test)) == keccak256("");
    }

    function _emitMultiEventsAndClear() private {
        for(uint256 i = 0; i < _itemsLength; i++) {
            uint256[] storage items = _items[i];
            uint256 itemId = items[0];
            delete items[0];
            uint256 length = (items.length - 1) / 3;
            address[] memory senders = new address[](length);
            address[] memory receivers = new address[](length);
            uint256[] memory amounts = new uint256[](length);
            uint256 inc = 0;
            for(uint256 z = 1; z < items.length; z += 3) {
                senders[inc] = address(uint160(items[z]));
                delete items[z];
                receivers[inc] = address(uint160(items[z + 1]));
                delete items[z + 1];
                amounts[inc++] = items[z + 2];
                delete items[z + 2];
            }
            IItemInteroperableInterface(address(uint160(itemId))).emitEvent(false, true, abi.encode(senders, receivers, amounts));
            delete _itemsIndexes[itemId];
            delete _items[i];
        }
        delete _itemsLength;
        _emitMultiEventsAndClearBatch();
    }

    function _emitMultiEventsAndClearBatch() private {
        for(uint256 i = 0; i < _batchKeys.length; i++) {
            bytes32 key = _batchKeys[i];
            uint256[] storage items = _batchItems[key];
            uint256 length = items.length - 3;
            address operator = address(uint160(items[0]));
            delete items[0];
            address sender = address(uint160(items[1]));
            delete items[1];
            address receiver = address(uint160(items[2]));
            delete items[2];
            uint256 inc = 0;
            uint256[] memory itemIds = new uint256[](length);
            uint256[] memory amounts = new uint256[](length);
            for(uint256 z = 3; z < items.length; z++) {
                amounts[inc] = _batchAmounts[key][itemIds[inc] = items[z]];
                delete items[z];
                delete _batchAmounts[key][inc++];
            }
            emit TransferBatch(operator, sender, receiver, itemIds, amounts);
            delete _batchItems[key];
        }
        delete _batchKeys;
    }
}