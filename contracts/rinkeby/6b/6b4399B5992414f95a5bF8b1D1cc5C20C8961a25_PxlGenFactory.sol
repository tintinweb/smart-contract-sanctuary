// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IFactory.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

interface IPxlGen {
    function mintCell(address to, uint256 index) external;

    function isIndexMinted(uint256 index) external view returns (bool);
}

contract PxlGenFactory is IFactory, Ownable, ReentrancyGuard {
    IPxlGen public pxlGen;
    ProxyRegistry public proxyRegistry;
    string public baseMetadataURI;

    uint256 public constant NUM_OPTIONS = 400;
    mapping(uint256 => uint256) public optionToTokenID;

    constructor(
        address _proxyRegistryAddress,
        address _pxlGen,
        string memory _baseURI
    ) {
        proxyRegistry = ProxyRegistry(_proxyRegistryAddress);
        pxlGen = IPxlGen(_pxlGen);
        baseMetadataURI = _baseURI;
    }

    function name() external pure override returns (string memory) {
        return "PxlGen Pre-Sale";
    }

    function symbol() external pure override returns (string memory) {
        return "PXL";
    }

    function supportsFactoryInterface() external pure override returns (bool) {
        return true;
    }

    function factorySchemaName() external pure override returns (string memory) {
        return "ERC1155";
    }

    function numOptions() external pure override returns (uint256) {
        return NUM_OPTIONS;
    }

    function canMint(uint256 _index, uint256 _amount) external view override returns (bool) {
        return _canMint(msg.sender, _index, _amount);
    }

    function mint(
        uint256 _index,
        address _toAddress,
        uint256 _amount,
        bytes calldata _data
    ) external override nonReentrant() {
        return _mint(_index, _toAddress, _amount, _data);
    }

    function uri(uint256 _index) external view override returns (string memory) {
        return string(abi.encodePacked(baseMetadataURI, "/", toString(_index), ".json"));
    }

    function _mint(
        uint256 _index,
        address _to,
        uint256 _amount,
        bytes memory
    ) internal {
        require(_isOwnerOrProxy(msg.sender), "!authorised");
        require(_canMint(msg.sender, _index, _amount), "Already minted");
        pxlGen.mintCell(_to, _index);
    }

    function balanceOf(address, uint256 _index) public view override returns (uint256) {
        bool isMinted = pxlGen.isIndexMinted(_index);
        // if isMinted then balance is 0 else there is 1 available
        return isMinted ? 0 : 1;
    }

    function safeTransferFrom(
        address,
        address _to,
        uint256 _index,
        uint256 _amount,
        bytes calldata _data
    ) external override {
        _mint(_index, _to, _amount, _data);
    }

    function isApprovedForAll(address _owner, address _operator) public view override returns (bool) {
        return owner() == _owner && _isOwnerOrProxy(_operator);
    }

    function _canMint(
        address,
        uint256 _index,
        uint256
    ) internal view returns (bool) {
        if (_index < 1 || _index > NUM_OPTIONS) return false;
        return !pxlGen.isIndexMinted(_index);
    }

    function _isOwnerOrProxy(address _address) internal view returns (bool) {
        return owner() == _address || address(proxyRegistry.proxies(owner())) == _address;
    }

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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * This is a generic factory contract that can be used to mint tokens. The configuration
 * for minting is specified by an _optionId, which can be used to delineate various
 * ways of minting.
 */
interface IFactory {
    /**
     * Returns the name of this factory.
     */
    function name() external view returns (string memory);

    /**
     * Returns the symbol for this factory.
     */
    function symbol() external view returns (string memory);

    /**
     * Number of options the factory supports.
     */
    function numOptions() external view returns (uint256);

    /**
     * @dev Returns whether the option ID can be minted. Can return false if the developer wishes to
     * restrict a total supply per option ID (or overall).
     */
    function canMint(uint256 _optionId, uint256 _amount) external view returns (bool);

    /**
     * @dev Returns a URL specifying some metadata about the option. This metadata can be of the
     * same structure as the ERC1155 metadata.
     */
    function uri(uint256 _optionId) external view returns (string memory);

    /**
     * Indicates that this is a factory contract. Ideally would use EIP 165 supportsInterface()
     */
    function supportsFactoryInterface() external view returns (bool);

    /**
     * Indicates the Wyvern schema name for assets in this lootbox, e.g. "ERC1155"
     */
    function factorySchemaName() external view returns (string memory);

    /**
     * @dev Mints asset(s) in accordance to a specific address with a particular "option". This should be
     * callable only by the contract owner or the owner's Wyvern Proxy (later universal login will solve this).
     * Options should also be delineated 0 - (numOptions() - 1) for convenient indexing.
     * @param _optionId the option id
     * @param _toAddress address of the future owner of the asset(s)
     * @param _amount amount of the option to mint
     * @param _data Extra data to pass during safeTransferFrom
     */
    function mint(
        uint256 _optionId,
        address _toAddress,
        uint256 _amount,
        bytes calldata _data
    ) external;

    ///////
    // Get things to work on OpenSea with mock methods below
    ///////

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _optionId,
        uint256 _amount,
        bytes calldata _data
    ) external;

    function balanceOf(address _owner, uint256 _optionId) external view returns (uint256);

    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

