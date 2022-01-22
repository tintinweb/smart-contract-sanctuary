// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "./vendors/ERC721Initializable.sol";
import "./vendors/access/ManagerLikeOwner.sol";
import "./vendors/utils/CompareStrings.sol";
import "./interfaces/IWinePool.sol";
import "./interfaces/IWineManager.sol";
import "./interfaces/IWineFactory.sol";
import "./WinePoolParts/WineStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract WinePoolCode is
    ERC721Initializable,
    ManagerLikeOwner,
    Pausable,
    IWinePool,
    WineStorage
{
    using CompareStrings for string;
    using Strings for uint256;

//////////////////////////////////////// DescriptionFields


    function updateAllDescriptionFields(
        string memory wineName,
        string memory wineProductionCountry,
        string memory wineProductionRegion,
        string memory wineProductionYear,
        string memory wineProducerName,
        string memory wineBottleVolume,
        string memory linkToDocuments
    )
        public override
        onlyManager
    {
        setStorage(WINE_NAME, wineName);
        setStorage(WINE_PRODUCTION_COUNTRY, wineProductionCountry);
        setStorage(WINE_PRODUCTION_REGION, wineProductionRegion);
        setStorage(WINE_PRODUCTION_YEAR, wineProductionYear);
        setStorage(WINE_PRODUCTION_NAME, wineProducerName);
        setStorage(WINE_PRODUCTION_VOLUME, wineBottleVolume);
        setStorage(LINK_TO_DOCUMENTS, linkToDocuments);
    }

    function editDescriptionField(bytes32 param, string memory value)
        public override
        onlyManager
    {
        if (param == "wineName") {
            setStorage(WINE_NAME, value);
        } else if (param == "wineProductionCountry") {
            setStorage(WINE_PRODUCTION_COUNTRY, value);
        } else if (param == "wineProductionRegion") {
            setStorage(WINE_PRODUCTION_REGION, value);
        } else if (param == "wineProductionYear") {
            setStorage(WINE_PRODUCTION_YEAR, value);
        } else if (param == "wineProducerName") {
            setStorage(WINE_PRODUCTION_NAME, value);
        } else if (param == "wineBottleVolume") {
            setStorage(WINE_PRODUCTION_VOLUME, value);
        } else if (param == "linkToDocuments") {
            setStorage(LINK_TO_DOCUMENTS, value);
        } else revert("editDescriptionField: unrecognized-param");
    }

//////////////////////////////////////// System fields

    uint256 public override getPoolId;
    uint256 public override getMaxTotalSupply;
    uint256 public override getWinePrice;

    function _initializeSystemFields(
        uint256 poolId,
        uint256 maxTotalSupply,
        uint256 winePrice
    ) internal {
        getPoolId = poolId;
        getMaxTotalSupply = maxTotalSupply;
        getWinePrice = winePrice;
    }

    function editMaxTotalSupply(uint256 value)
        override
        public
        onlyManager enabled
    {
        require(value >= tokensCount, "editMaxTotalSupply: tokensCount > value");
        getMaxTotalSupply = value;
    }
    function editWinePrice(uint256 value)
        override
        public
        onlyManager
    {
        getWinePrice = value;
    }

//////////////////////////////////////// Pausable

    function pause()
        public override
        onlyOwner
    {
        _pause();
    }

    function unpause()
        public override
        onlyOwner
    {
        _unpause();
    }

    function _transfer(address from, address to, uint256 tokenId)
        internal virtual override
        whenNotPaused()
    {
        super._transfer(from, to, tokenId);
    }

    function _mint(address to, uint256 tokenId)
        internal virtual override
        whenNotPaused()
    {
        super._mint(to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal virtual override
        whenNotPaused()
    {
        super._burn(tokenId);
    }

//////////////////////////////////////// Initialize

    function initialize(
        string memory name,
        string memory symbol,

        address manager,

        uint256 poolId,
        uint256 maxTotalSupply,
        uint256 winePrice
    )
        override
        public payable
        initializer
        returns (bool)
    {
        _initializeManager(manager);

        _initializeInheritedOwner(_msgSender());
        _initializeERC721(name, symbol);
        _initializeSystemFields(
            poolId,
            maxTotalSupply,
            winePrice
        );
        disabled = false;
        return true;
    }

//////////////////////////////////////// Disable

    bool public override disabled;

    modifier onlyFactory() {
        require(IWineManager(manager()).factory() == _msgSender(), "OnlyFactory: caller is not the factory");
        _;
    }

    modifier enabled() {
        require(disabled == false, "enabled: contract is disabled");
        _;
    }

    function disablePool()
        override
        public
        onlyFactory
    {
        getMaxTotalSupply = tokensCount;
        if (tokensCount == 0) {
            _pause();
        }
        disabled = true;
    }

//////////////////////////////////////// ERC721

    function _baseURI()
        virtual override
        internal view
        returns (string memory)
    {
        return string(
            abi.encodePacked(
                IWineFactory(IWineManager(manager()).factory()).baseUri(),
                getPoolId.toString(),
                "/"
            )
        );
    }

//////////////////////////////////////// default methods

    uint256 public override tokensCount;
    modifier tokenIdExists(uint256 tokenId) {
        require(_exists(tokenId), "tokenIdExists: tokenId is not exists");
        _;
    }

    modifier onlyMinter() {
        require(IWineManager(manager()).allowMint(_msgSender()), "onlyMinter: caller is not the minter");
        _;
    }

    modifier onlyAllowInternalTransfers() {
        require(IWineManager(manager()).allowInternalTransfers(_msgSender()), "onlyAllowInternalTransfers: caller is not the minter");
        _;
    }

    modifier onlyAllowBurn() {
        require(IWineManager(manager()).allowBurn(_msgSender()), "onlyMinter: caller is not the minter");
        _;
    }


    function mint(address to)
        override
        public
        onlyMinter
        returns (uint256)
    {
        uint256 tokenId = tokensCount;
        ++tokensCount;

        require(tokensCount < getMaxTotalSupply, "mint: maxTotalSupply limit");

        _mint(to, tokenId);
        return tokenId;
    }

    function burn(uint256 tokenId)
        override
        public
        onlyAllowBurn tokenIdExists(tokenId)
    {
        require(ownerOf(tokenId) == _msgSender(), "ERC721: burn of token that is not own");
        _burn(tokenId);
    }

//////////////////////////////////////// internal users and tokens

    mapping(address => bool) public override internalUsersExists;
    mapping(uint256 => address) public override internalOwnedTokens;

    function mintToInternalUser(address internalUser)
        override
        public
        onlyMinter
        returns (uint256)
    {
        uint256 tokenId = mint(address(this));
        internalOwnedTokens[tokenId] = internalUser;
        internalUsersExists[internalUser] = true;
        return tokenId;
    }

    function transferInternalToInternal(address internalFrom, address internalTo, uint256 tokenId)
        override
        public
        tokenIdExists(tokenId) onlyManager whenNotPaused
    {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "_transferInternalToInternal - transfer caller is not owner nor approved");
        require(internalOwnedTokens[tokenId] == internalFrom, "_transferInternalToInternal - transfer of token that is not owned this innerUser");
        require(internalUsersExists[internalTo], "_transferInternalToInternal - innerUser is not exists");

        internalOwnedTokens[tokenId] = internalTo;
        emit InternalTransfer(internalFrom, internalTo, tokenId);
    }

    function transferOuterToInternal(address outerFrom, address internalTo, uint256 tokenId)
        override
        public
        tokenIdExists(tokenId)
    {
        require(internalUsersExists[internalTo], "_transferOuterToInternal - innerUser is not exists");

        transferFrom(outerFrom, address(this), tokenId);
        internalOwnedTokens[tokenId] = internalTo;
        emit InternalTransfer(address(0), internalTo, tokenId);
    }

    function transferInternalToOuter(address internalFrom, address outerTo, uint256 tokenId)
        override
        public
        tokenIdExists(tokenId) onlyAllowInternalTransfers
    {
        require(internalOwnedTokens[tokenId] == internalFrom, "_transferInternalToOuter - transfer of token that is not owned this innerUser");

        safeTransferFrom(address(this), outerTo, tokenId);
        internalOwnedTokens[tokenId] = address(0);
        emit InternalTransfer(internalFrom, address(0), tokenId);
    }


////////////////////////////////////////

    function isApprovedForAll(address owner, address operator)
        virtual override
        public view
        returns (bool)
    {
        if (owner == address(this) && IWineManager(manager()).allowInternalTransfers(operator)) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


library CompareStrings {

    function memcmp(bytes memory a, bytes memory b) internal pure returns(bool){
        return (a.length == b.length) && (keccak256(a) == keccak256(b));
    }

    function strcmp(string memory a, string memory b) internal pure returns(bool){
        return memcmp(bytes(a), bytes(b));
    }

    function isEmpty(string memory a) internal pure returns(bool){
        return strcmp(a, "");
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an manager) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the manager account will be the one that deploys the contract. This
 * can later be changed with {transferManagership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyManager`, which can be applied to your functions to restrict their use to
 * the manager.
 */
contract ManagerLikeOwner is Context {
    address private _manager;

    event ManagershipTransferred(address indexed previousManager, address indexed newManager);

    /**
     * @dev Initializes the contract setting the deployer as the initial manager.
     */
    function _initializeManager(address manager_)
        internal
    {
        _transferManagership(manager_);
    }

    /**
     * @dev Returns the address of the current manager.
     */
    function manager()
        public view
        returns (address)
    {
        return _manager;
    }

    /**
     * @dev Throws if called by any account other than the manager.
     */
    modifier onlyManager() {
        require(_manager == _msgSender(), "ManagerIsOwner: caller is not the manager");
        _;
    }

    /**
     * @dev Leaves the contract without manager. It will not be possible to call
     * `onlyManager` functions anymore. Can only be called by the current manager.
     *
     * NOTE: Renouncing managership will leave the contract without an manager,
     * thereby removing any functionality that is only available to the manager.
     */
    function renounceManagership()
        virtual
        public
        onlyManager
    {
        _beforeTransferManager(address(0));

        emit ManagershipTransferred(_manager, address(0));
        _manager = address(0);
    }

    /**
     * @dev Transfers managership of the contract to a new account (`newManager`).
     * Can only be called by the current manager.
     */
    function transferManagership(address newManager)
        virtual
        public
        onlyManager
    {
        _transferManagership(newManager);
    }

    function _transferManagership(address newManager)
        virtual
        internal
    {
        require(newManager != address(0), "ManagerIsOwner: new manager is the zero address");
        _beforeTransferManager(newManager);

        emit ManagershipTransferred(_manager, newManager);
        _manager = newManager;
    }

    /**
     * @dev Hook that is called before manger transfer. This includes initialize and renounce
     */
    function _beforeTransferManager(address newManager)
        virtual
        internal
    {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "./IOwnable.sol";

/**
 * see openzeppelin/contracts/access/Ownable.sol
 * doc modification to inherit owner of parent, initializable
 */
abstract contract InheritedOwner is Context, IOwnable {
    address private _parent;

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function _initializeInheritedOwner(address parent_)
        internal
    {
        require(_parent == address(0), 'InheritedOwner: initialized yet');
        require(parent_ != address(0), 'InheritedOwner: parent is null');

        _parent = parent_;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner()
        override virtual
        public view
        returns (address)
    {
        return IOwnable(_parent).owner();
    }

    function parent()
        public view
        returns (address)
    {
        return _parent;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * see openzeppelin/contracts/access/Ownable.sol
 */
interface IOwnable {

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./access/InheritedOwner.sol";

contract ERC721Initializable is ERC721, InheritedOwner, Initializable
{
    constructor() ERC721("__", "__") {}

    // Token name
    string private __name;
    // Token symbol
    string private __symbol;

    function _initializeERC721(
        string memory name_,
        string memory symbol_
    )
        virtual
        internal
    {
        __name = name_;
        __symbol = symbol_;
    }

    function name()
        virtual override
        public view
        returns (string memory)
    {
        return __name;
    }

    function symbol()
        virtual override
        public view
        returns (string memory)
    {
        return __symbol;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IWinePool.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";


interface IWinePoolFull is IERC165, IERC721, IERC721Metadata, IWinePool
{
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IWinePool
{
//////////////////////////////////////// DescriptionFields

    function updateAllDescriptionFields(
        string memory wineName,
        string memory wineProductionCountry,
        string memory wineProductionRegion,
        string memory wineProductionYear,
        string memory wineProducerName,
        string memory wineBottleVolume,
        string memory linkToDocuments
    ) external;
    function editDescriptionField(bytes32 param, string memory value) external;

//////////////////////////////////////// System fields

    function getPoolId() external view returns (uint256);
    function getMaxTotalSupply() external view returns (uint256);
    function getWinePrice() external view returns (uint256);

    function editMaxTotalSupply(uint256 value) external;
    function editWinePrice(uint256 value) external;

//////////////////////////////////////// Pausable

    function pause() external;
    function unpause() external;

//////////////////////////////////////// Initialize

    function initialize(
        string memory name,
        string memory symbol,

        address manager,

        uint256 poolId,
        uint256 maxTotalSupply,
        uint256 winePrice
    ) external payable returns (bool);

//////////////////////////////////////// Disable

    function disabled() external view returns (bool);

    function disablePool() external;

//////////////////////////////////////// default methods

    function tokensCount() external view returns (uint256);

    function burn(uint256 tokenId) external;

    function mint(address to) external returns (uint256);

//////////////////////////////////////// internal users and tokens

    event InternalTransfer(address indexed from, address indexed to, uint256 indexed tokenId);

    function internalUsersExists(address) external view returns (bool);
    function internalOwnedTokens(uint256) external view returns (address);

    function mintToInternalUser(address internalUser) external returns (uint256);

    function transferInternalToInternal(address internalFrom, address internalTo, uint256 tokenId) external;

    function transferOuterToInternal(address outerFrom, address internalTo, uint256 tokenId) external;

    function transferInternalToOuter(address internalFrom, address outerTo, uint256 tokenId) external;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IWineManagerPoolIntegration {

    function allowMint(address) external view returns (bool);
    function allowInternalTransfers(address) external view returns (bool);
    function allowBurn(address) external view returns (bool);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IWineManagerMarketPlaceIntegration {

    function marketPlace() external view returns (address);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IWineManagerFirstSaleMarketIntegration {

    function firstSaleMarket() external view returns (address);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IWinePoolFull.sol";

interface IWineManagerFactoryIntegration {

    function factory() external view returns (address);

    function getPoolAddress(uint256 poolId) external view returns (address);

    function getPoolAsContract(uint256 poolId) external view returns (IWinePoolFull);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IWineManagerDeliveryServiceIntegration {

    function deliveryService() external view returns (address);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IWineManagerFactoryIntegration.sol";
import "./IWineManagerFirstSaleMarketIntegration.sol";
import "./IWineManagerMarketPlaceIntegration.sol";
import "./IWineManagerDeliveryServiceIntegration.sol";
import "./IWineManagerPoolIntegration.sol";

interface IWineManager is
    IWineManagerFactoryIntegration,
    IWineManagerFirstSaleMarketIntegration,
    IWineManagerMarketPlaceIntegration,
    IWineManagerDeliveryServiceIntegration,
    IWineManagerPoolIntegration
{

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IWineFactory {

    event WinePoolCreated(uint256 poolId, address winePool);

    function winePoolCode() external view returns (address);
    function baseUri() external view returns (string memory);
    function baseSymbol() external view returns (string memory);

    function initialize(
        address proxyAdmin_,
        address winePoolCode_,
        address manager_,
        string memory baseUri_,
        string memory baseSymbol_
    ) external;

    function getPool(uint256 poolId) external view returns (address);

    function allPoolsLength() external view returns (uint);

    function createWinePool(
        string memory name_,

        uint256 maxTotalSupply_,
        uint256 winePrice_
    ) external returns (address winePoolAddress);

    function disablePool(uint256 poolId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./Constants.sol";


contract WineStorage is Constants{
    // tokenId => (key => value)
    mapping(uint256 => string) internal data;


    function setStorage(uint256 key, string memory value) internal
    {
        data[key] = value;
    }


    function getStorage(uint256 key) public view returns(string memory)
    {
        return data[key];
    }
    
    function getWineName() public view returns(string memory)
    {
        return data[WINE_NAME];
    }

    function getWineProductionCountry() public view returns(string memory)
    {
        return data[WINE_PRODUCTION_COUNTRY];
    }

    function getWineProductionRegion() public view returns(string memory)
    {
        return data[WINE_PRODUCTION_REGION];
    }

    function getWineProductionYear() public view returns(string memory)
    {
        return data[WINE_PRODUCTION_YEAR];
    }

    function getWineProducerName() public view returns(string memory)
    {
        return data[WINE_PRODUCTION_NAME];
    }

    function getWineBottleVolume() public view returns(string memory)
    {
        return data[WINE_PRODUCTION_VOLUME];
    }

    function getLinkToDocuments() public view returns(string memory)
    {
        return data[LINK_TO_DOCUMENTS];
    }


}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;



contract Constants {
    uint256 internal constant WINE_NAME = 1000;
    uint256 internal constant WINE_PRODUCTION_COUNTRY = 1001;
    uint256 internal constant WINE_PRODUCTION_REGION = 1002;
    uint256 internal constant WINE_PRODUCTION_YEAR = 1003;
    uint256 internal constant WINE_PRODUCTION_NAME = 1004;
    uint256 internal constant WINE_PRODUCTION_VOLUME = 1005;
    uint256 internal constant LINK_TO_DOCUMENTS = 1006;
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

import "../IERC721.sol";

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

pragma solidity ^0.8.0;

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
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
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
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
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
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
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
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
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
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
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

        _balances[to] += 1;
        _owners[tokenId] = to;

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
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

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
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
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
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
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
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
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
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
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