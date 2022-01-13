// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "../interfaces/IForwarder.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IERC721CollectionV2.sol";
import "../interfaces/IERC721CollectionFactoryV2.sol";
import "../interfaces/IRarities.sol";
import "../commons/OwnableInitializable.sol";
import "../commons/NativeMetaTransaction.sol";


contract CollectionManager is OwnableInitializable, NativeMetaTransaction {

    using SafeMath for uint256;

    IERC20  public acceptedToken;
    IRarities public rarities;
    address public committee;
    address public feesCollector;
    uint256 public pricePerItem;

    mapping(bytes4 => bool) public allowedCommitteeMethods;


    event AcceptedTokenSet(IERC20 indexed _oldAcceptedToken, IERC20 indexed _newAcceptedToken);
    event CommitteeSet(address indexed _oldCommittee, address indexed _newCommittee);
    event CommitteeMethodSet(bytes4 indexed _method, bool _isAllowed);
    event FeesCollectorSet(address indexed _oldFeesCollector, address indexed _newFeesCollector);
    event RaritiesSet(IRarities indexed _oldRarities, IRarities indexed _newRarities);

    /**
    * @notice Create the contract
    * @param _owner - owner of the contract
    * @param _acceptedToken - accepted ERC20 token for collection deployment
    * @param _committee - committee contract
    * @param _feesCollector - fees collector
    * @param _rarities - rarities contract
    * @param _committeeMethods - method selectors
    * @param _committeeValues - whether the method is allowed or not
    */
    constructor(
        address _owner,
        IERC20 _acceptedToken,
        address _committee,
        address _feesCollector,
        IRarities _rarities,
        bytes4[] memory _committeeMethods,
        bool[] memory _committeeValues
    ) {
        // EIP712 init
        _initializeEIP712('Decentraland Collection Manager', '1');
        // Ownable init
        _initOwnable();

        setAcceptedToken(_acceptedToken);

        // Committee
        setCommittee(_committee);
        setCommitteeMethods(_committeeMethods, _committeeValues);

        setFeesCollector(_feesCollector);
        setRarities(_rarities);

        transferOwnership(_owner);
    }

    /**
    * @notice Set the accepted token
    * @param _newAcceptedToken - accepted ERC20 token for collection deployment
    */
    function setAcceptedToken(IERC20 _newAcceptedToken) onlyOwner public {
        require(address(_newAcceptedToken) != address(0), "CollectionManager#setAcceptedToken: INVALID_ACCEPTED_TOKEN");

        emit AcceptedTokenSet(acceptedToken, _newAcceptedToken);
        acceptedToken = _newAcceptedToken;
    }

    /**
    * @notice Set the committee
    * @param _newCommittee - committee contract
    */
    function setCommittee(address _newCommittee) onlyOwner public {
        require(_newCommittee != address(0), "CollectionManager#setCommittee: INVALID_COMMITTEE");

        emit CommitteeSet(committee, _newCommittee);
        committee = _newCommittee;
    }

    /**
    * @notice Set methods to be allowed by the committee
    * @param _methods - method selectors
    * @param _values - whether the method is allowed or not
    */
    function setCommitteeMethods(bytes4[] memory _methods, bool[] memory _values) onlyOwner public {
        uint256 length = _methods.length;
        require(length > 0 && length == _values.length, "CollectionManager#setCommitteeMethods: EMPTY_METHODS");

        for (uint256 i = 0; i < length; i++) {
            bytes4 method = _methods[i];
            bool value = _values[i];

            allowedCommitteeMethods[method] = value;

            emit CommitteeMethodSet(method, value);
        }
    }

    /**
    * @notice Set the fees collector
    * @param _newFeesCollector - fees collector
    */
    function setFeesCollector(address _newFeesCollector) onlyOwner public {
        require(_newFeesCollector != address(0), "CollectionManager#setFeesCollector: INVALID_FEES_COLLECTOR");

        emit FeesCollectorSet(feesCollector, _newFeesCollector);
        feesCollector = _newFeesCollector;
    }

    /**
    * @notice Set the rarities
    * @param _newRarities - price per item
    */
    function setRarities(IRarities _newRarities) onlyOwner public {
        require(address(_newRarities) != address(0), "CollectionManager#setRarities: INVALID_RARITIES");

        emit RaritiesSet(rarities, _newRarities);
        rarities = _newRarities;
    }

    /**
    * @notice Create a collection
    * @param _forwarder - forwarder contract owner of the collection factory
    * @param _factory - collection factory
    * @param _salt - arbitrary 32 bytes hexa
    * @param _name - name of the contract
    * @param _symbol - symbol of the contract
    * @param _baseURI - base URI for token URIs
    * @param _creator - creator address
    * @param _items - items to be added
    */
    function createCollection(
        IForwarder _forwarder,
        IERC721CollectionFactoryV2 _factory,
        bytes32 _salt,
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        address _creator,
        IERC721CollectionV2.ItemParam[] memory _items
     ) external {
        require(address(_forwarder) != address(this), "CollectionManager#createCollection: FORWARDER_CANT_BE_THIS");
        uint256 amount = 0;

        for (uint256 i = 0; i < _items.length; i++) {
            IERC721CollectionV2.ItemParam memory item = _items[i];

            IRarities.Rarity memory rarity = rarities.getRarityByName(item.rarity);

            amount = amount.add(rarity.price);
        }

        // Transfer fees to collector
        if (amount > 0) {
            require(
                acceptedToken.transferFrom(_msgSender(), feesCollector, amount),
                "CollectionManager#createCollection: TRANSFER_FEES_FAILED"
            );
        }

        bytes memory data = abi.encodeWithSelector(
            IERC721CollectionV2.initialize.selector,
            _name,
            _symbol,
            _baseURI,
            _creator,
            true, // Collection should be completed
            false, // Collection should start disapproved
            rarities,
            _items
        );

        (bool success,) = _forwarder.forwardCall(address(_factory), abi.encodeWithSelector(_factory.createCollection.selector, _salt, data));
        require(
            success,
             "CollectionManager#createCollection: FORWARD_FAILED"
        );
    }

    /**
    * @notice Manage a collection
    * @param _forwarder - forwarder contract owner of the collection factory
    * @param _collection - collection to be managed
    * @param _data - call data to be used
    */
    function manageCollection(IForwarder _forwarder, IERC721CollectionV2 _collection, bytes calldata _data) external {
        require(address(_forwarder) != address(this), "CollectionManager#manageCollection: FORWARDER_CANT_BE_THIS");
        require(
            _msgSender() == committee,
            "CollectionManager#manageCollection: UNAUTHORIZED_SENDER"
        );

        (bytes4 method) = abi.decode(_data, (bytes4));
        require(allowedCommitteeMethods[method], "CollectionManager#manageCollection: COMMITTEE_METHOD_NOT_ALLOWED");

        bool success;
        bytes memory res;

        (success, res) = address(_collection).staticcall(abi.encodeWithSelector(_collection.COLLECTION_HASH.selector));
        require(
            success && abi.decode(res, (bytes32)) == keccak256("Decentraland Collection"),
            "CollectionManager#manageCollection: INVALID_COLLECTION"
        );

        (success,) = _forwarder.forwardCall(address(_collection), _data);
        require(
            success,
            "CollectionManager#manageCollection: FORWARD_FAILED"
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;


interface IForwarder {
   function forwardCall(address _address, bytes calldata _data) external returns (bool, bytes memory);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;


interface IERC20 {
    function balanceOf(address from) external view returns (uint256);
    function transferFrom(address from, address to, uint tokens) external returns (bool);
    function transfer(address to, uint tokens) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function burn(uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;


interface IERC721CollectionV2 {
    function COLLECTION_HASH() external view returns (bytes32);

    struct ItemParam {
        string rarity;
        uint256 price;
        address beneficiary;
        string metadata;
    }

    function issueTokens(address[] calldata _beneficiaries, uint256[] calldata _itemIds) external;
    function setApproved(bool _value) external;
    /// @dev For some reason using the Struct Item as an output parameter fails, but works as an input parameter
    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        address _creator,
        bool _shouldComplete,
        bool _isApproved,
        address _rarities,
        ItemParam[] memory _items
    ) external;
    function items(uint256 _itemId) external view returns (string memory, uint256, uint256, uint256, address, string memory, string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;


interface IERC721CollectionFactoryV2 {
    function createCollection(bytes32 _salt, bytes memory _data) external returns (address addr);
    function transferOwnership(address newOwner) external;
    function isCollectionFromFactory(address _collection) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;


interface IRarities {

    struct Rarity {
        string name;
        uint256 maxSupply;
        uint256 price;
    }

    function getRarityByName(string calldata rarity) external view returns (Rarity memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "./ContextMixin.sol";

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
abstract contract OwnableInitializable is ContextMixin {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function _initOwnable () internal {
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

pragma solidity ^0.7.6;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

import { EIP712Base } from "./EIP712Base.sol";

contract NativeMetaTransaction is EIP712Base {
    using SafeMath for uint256;
    bytes32 private constant META_TRANSACTION_TYPEHASH = keccak256(
        bytes(
            "MetaTransaction(uint256 nonce,address from,bytes functionSignature)"
        )
    );
    event MetaTransactionExecuted(
        address userAddress,
        address relayerAddress,
        bytes functionSignature
    );
    mapping(address => uint256) nonces;

    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) external payable returns (bytes memory) {
        MetaTransaction memory metaTx = MetaTransaction({
            nonce: nonces[userAddress],
            from: userAddress,
            functionSignature: functionSignature
        });

        require(
            verify(userAddress, metaTx, sigR, sigS, sigV),
            "NMT#executeMetaTransaction: SIGNER_AND_SIGNATURE_DO_NOT_MATCH"
        );

        // increase nonce for user (to avoid re-use)
        nonces[userAddress] = nonces[userAddress].add(1);

        emit MetaTransactionExecuted(
            userAddress,
            msg.sender,
            functionSignature
        );

        // Append userAddress and relayer address at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call{value: msg.value}(
            abi.encodePacked(functionSignature, userAddress)
        );
        require(success, "NMT#executeMetaTransaction: CALL_FAILED");

        return returnData;
    }

    function hashMetaTransaction(MetaTransaction memory metaTx)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    META_TRANSACTION_TYPEHASH,
                    metaTx.nonce,
                    metaTx.from,
                    keccak256(metaTx.functionSignature)
                )
            );
    }

    function getNonce(address user) external view returns (uint256 nonce) {
        nonce = nonces[user];
    }

    function verify(
        address signer,
        MetaTransaction memory metaTx,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) internal view returns (bool) {
        require(signer != address(0), "NMT#verify: INVALID_SIGNER");
        return
            signer ==
            ecrecover(
                toTypedMessageHash(hashMetaTransaction(metaTx)),
                sigV,
                sigR,
                sigS
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;


abstract contract ContextMixin {
    function _msgSender()
        internal
        view
        virtual
        returns (address payable sender)
    {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = msg.sender;
        }
        return sender;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;


contract EIP712Base {
    struct EIP712Domain {
        string name;
        string version;
        address verifyingContract;
        bytes32 salt;
    }

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH = keccak256(
        bytes(
            "EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)"
        )
    );
    bytes32 public domainSeparator;

    // supposed to be called once while initializing.
    // one of the contractsa that inherits this contract follows proxy pattern
    // so it is not possible to do this in a constructor
    function _initializeEIP712(
        string memory name,
        string memory version
    )
        internal
    {
        domainSeparator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                address(this),
                bytes32(getChainId())
            )
        );
    }

    function getChainId() public pure returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /**
     * Accept message hash and returns hash message in EIP712 compatible form
     * So that it can be used to recover signer from signature signed using EIP712 formatted data
     * https://eips.ethereum.org/EIPS/eip-712
     * "\\x19" makes the encoding deterministic
     * "\\x01" is the version byte to make it compatible to EIP-191
     */
    function toTypedMessageHash(bytes32 messageHash)
        internal
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19\x01", domainSeparator, messageHash)
            );
    }
}