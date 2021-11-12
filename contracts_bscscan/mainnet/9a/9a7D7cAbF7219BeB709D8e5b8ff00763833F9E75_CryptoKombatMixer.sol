//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol';
import './interfaces/ICollection.sol';

contract CryptoKombatMixer is ERC1155Holder, Ownable {
    enum HeroEdition {
        EMPTY,
        GENESIS,
        EPIC,
        RARE,
        COMMON
    }

    struct MixRequest {
        address account;
        HeroEdition editionIn;
        uint256[] inIds;
    }

    struct MixYield {
        HeroEdition edition;
        uint256 chance;
    }

    mapping(HeroEdition => MixYield[]) public mixerConfigs;
    mapping(HeroEdition => bool) public mixerConfigExists;
    mapping(uint256 => HeroEdition) public heroIdToEdition;
    mapping(HeroEdition => uint256[]) public editionToHeroIds;

    ICollection public collection;

    address private constant DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    uint256 private constant DECIMAL_PRECISION = 3;
    uint256 private constant PERCENTS_SUM = 100 * 10**DECIMAL_PRECISION;
    uint256 private randomNonce;

    uint256 private mixRequestId;

    mapping(bytes32 => MixRequest) public mixRequests;

    // EVENTS
    event MixRequested(address indexed account, bytes32 indexed requestId);
    event HeroesMixSuceess(
        address indexed account,
        bytes32 indexed requestId,
        HeroEdition editionIn,
        HeroEdition editionOut,
        uint256 tokenId
    );
    event HeroesMixReverted(address indexed account, bytes32 indexed requestId, HeroEdition editionIn);
    event MixerConfigSet(HeroEdition indexed editionIn, HeroEdition[] indexed editionsOut, uint256[] indexed chances);
    event EditionToIdMappingSet(HeroEdition indexed edition, uint256[] indexed ids);
    event EditionToIdMappingAdded(HeroEdition indexed edition, uint256 indexed id);

    // CONSTRUCTOR
    constructor(address collection_) {
        require(collection_ != address(0), 'CryptoKombatMixer: Collection zero address');
        collection = ICollection(collection_);
    }

    // PUBLIC FUNCTIONS

    function mixHeroes(uint256[] memory _ids) external virtual {
        require(_ids.length == 3, 'CryptoKombatMixer: Incorrect input length');
        require(isSameEditions(_ids), 'CryptoKombatMixer: Input editions are not same');
        require(isConfigExists(heroIdToEdition[_ids[0]]), 'CryptoKombatMixer: Mixer config does not exist');

        collection.safeBatchTransferFrom(msg.sender, address(this), _ids, _getFilledArray(_ids.length, 1), bytes('0x0'));
        //collection.burnBatch(msg.sender, _ids, _getFilledArray(3, 1));
        mixRequestId++;
        mixRequests[bytes32(mixRequestId)] = MixRequest({ account: msg.sender, editionIn: heroIdToEdition[_ids[0]], inIds: _ids });

        emit MixRequested(msg.sender, bytes32(mixRequestId));

        _getOutcome(bytes32(mixRequestId), random());
    }

    // PRIVATE FUNCTIONS

    function _getOutcome(bytes32 requestId, uint256 randomValue) internal {
        MixRequest memory mixRequest = mixRequests[requestId];

        HeroEdition editionOut = _getOutputEdition(mixRequest.editionIn, randomValue);
        uint256 tokenId = _getValidOutputTokenId(editionOut, randomValue);

        if (tokenId > 0) {
            collection.mint(mixRequest.account, tokenId, 1, bytes('0x0'));

            emit HeroesMixSuceess(mixRequest.account, requestId, mixRequest.editionIn, editionOut, tokenId);
        } else {
            collection.safeBatchTransferFrom(
                address(this),
                mixRequest.account,
                mixRequest.inIds,
                _getFilledArray(mixRequest.inIds.length, 1),
                bytes('0x0')
            );
            emit HeroesMixReverted(mixRequest.account, requestId, mixRequest.editionIn);
        }
        delete mixRequests[requestId];
    }

    function _getOutputEdition(HeroEdition editionIn, uint256 randomValue) internal view returns (HeroEdition editionOut) {
        uint256 randomChance = randomValue % PERCENTS_SUM;

        for (uint256 i = mixerConfigs[editionIn].length - 1; i > 0; i--) {
            uint256 checkChance = mixerConfigs[editionIn][i].chance;
            if (randomChance < checkChance) {
                return mixerConfigs[editionIn][i].edition;
            } else {
                randomChance = randomChance - checkChance;
            }
        }
        return mixerConfigs[editionIn][0].edition;
    }

    function _getValidOutputTokenId(HeroEdition editionOut, uint256 randomValue) internal view returns (uint256 tokenId) {
        uint256[] memory randomArray = expandRandom(randomValue, editionToHeroIds[editionOut].length);
        for (uint256 i = 1; i < randomArray.length; i++) {
            uint256 randomIndex = randomArray[i] % editionToHeroIds[editionOut].length;
            tokenId = editionToHeroIds[editionOut][randomIndex];
            if (collection.totalSupply(tokenId) + 1 < collection.maxSupply(tokenId)) {
                return tokenId;
            }
        }
        return 0;
    }

    // Helper functions

    function isSameEditions(uint256[] memory _ids) internal view returns (bool) {
        HeroEdition _prevEdition = heroIdToEdition[_ids[0]];
        for (uint256 i = 1; i < _ids.length; i++) {
            HeroEdition _currentEdition = heroIdToEdition[_ids[0]];
            if (_prevEdition != _currentEdition) {
                return false;
            }
            _prevEdition = _currentEdition;
        }
        return true;
    }

    function isConfigExists(HeroEdition _edition) internal view returns (bool) {
        return mixerConfigExists[_edition];
    }

    function random() private returns (uint256) {
        randomNonce++;
        return uint256(keccak256(abi.encodePacked(block.number, block.timestamp, block.difficulty, _msgSender(), randomNonce)));
    }

    function expandRandom(uint256 randomValue, uint256 n) internal pure returns (uint256[] memory expandedValues) {
        expandedValues = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
            expandedValues[i] = uint256(keccak256(abi.encode(randomValue, i)));
        }
        return expandedValues;
    }

    function _getFilledArray(uint256 n, uint256 v) internal pure returns (uint256[] memory array) {
        array = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
            array[i] = v;
        }
        return array;
    }

    function _transferHeroes(uint256[] memory _ids, address _to) internal {
        collection.safeBatchTransferFrom(address(this), _to, _ids, _getFilledArray(_ids.length, 1), bytes('0x0'));
    }

    function _transferAllHeroes(address _to) internal {
        uint256[] memory ids = editionToHeroIds[HeroEdition.COMMON];

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 balance = collection.balanceOf(address(this), ids[i]);
            if (balance > 0) {
                collection.safeTransferFrom(address(this), _to, ids[i], balance, bytes('0x0'));
            }
        }

        ids = editionToHeroIds[HeroEdition.RARE];

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 balance = collection.balanceOf(address(this), ids[i]);
            if (balance > 0) {
                collection.safeTransferFrom(address(this), _to, ids[i], balance, bytes('0x0'));
            }
        }

        ids = editionToHeroIds[HeroEdition.EPIC];

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 balance = collection.balanceOf(address(this), ids[i]);
            if (balance > 0) {
                collection.safeTransferFrom(address(this), _to, ids[i], balance, bytes('0x0'));
            }
        }
    }

    // Admin functions

    /*
        Set mixer config, chances should be in increasing order
        
        For COMMON in
        - [EPIC,RARE,COMMON] [3700,36600,59700]
        For RARE in
        - [COMMON,EPIC,RARE] [9700,34700,55600]
        
        Sum should be eq DECIMAL_PRECISION       
    */
    function setMixerConfig(
        HeroEdition _in,
        HeroEdition[] memory _out,
        uint256[] memory _chances
    ) external onlyOwner {
        require(_out.length == _chances.length, 'CryptoKombatMixer: Params length mismatch');

        uint256 sum;
        uint256 prevChance;

        for (uint256 i = 0; i < _chances.length; i++) {
            require(_chances[i] > prevChance, 'CryptoKombatMixer: Chances should be in increasing order');
            prevChance = _chances[i];
            sum += _chances[i];

            if (mixerConfigs[_in].length > i) {
                mixerConfigs[_in][i] = MixYield({ edition: _out[i], chance: _chances[i] });
            } else {
                mixerConfigs[_in].push(MixYield({ edition: _out[i], chance: _chances[i] }));
            }
        }

        require(sum <= PERCENTS_SUM, 'CryptoKombatMixer: Chances sum exceed 100%');

        if (!mixerConfigExists[_in]) {
            mixerConfigExists[_in] = true;
        }

        emit MixerConfigSet(_in, _out, _chances);
    }

    function setEditionToIdMapping(HeroEdition _edition, uint256[] memory _ids) external onlyOwner {
        require(_edition != HeroEdition.EMPTY, 'CryptoKombatMixer: Cannot set ids for EMPTY edition');

        for (uint256 i = 0; i < _ids.length; i++) {
            heroIdToEdition[_ids[i]] = _edition;
        }
        editionToHeroIds[_edition] = _ids;

        emit EditionToIdMappingSet(_edition, _ids);
    }

    function addEditionToIdMapping(HeroEdition _edition, uint256 _id) external onlyOwner {
        require(_edition != HeroEdition.EMPTY, 'CryptoKombatMixer: Cannot set ids for EMPTY edition');

        heroIdToEdition[_id] = _edition;
        editionToHeroIds[_edition].push(_id);

        emit EditionToIdMappingAdded(_edition, _id);
    }

    function recoverHeroes(uint256[] memory _ids) external onlyOwner {
        _transferHeroes(_ids, msg.sender);
    }

    function recoverAllHeroes() external onlyOwner {
        _transferAllHeroes(msg.sender);
    }

    function burnHeroesBatch(uint256[] memory _ids) external onlyOwner {
        _transferHeroes(_ids, DEAD_ADDRESS);
    }

    function burnAllHeroes() external onlyOwner {
        _transferAllHeroes(DEAD_ADDRESS);
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

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ICollection {
    function totalSupply(uint256 _id) external view returns (uint256);

    function maxSupply(uint256 _id) external view returns (uint256);

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function mint(
        address _to,
        uint256 _id,
        uint256 _quantity,
        bytes memory _data
    ) external;

    function mintBatch(
        address _to,
        uint256[] memory _ids,
        uint256[] memory _quantities,
        bytes memory _data
    ) external;

    function burn(
        address _from,
        uint256 _id,
        uint256 _quantity
    ) external;

    function burnBatch(
        address _from,
        uint256[] memory _ids,
        uint256[] memory _quantities
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

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