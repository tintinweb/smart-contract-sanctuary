// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

/**
 *      ____        _            _     _ _     _
 *     / ___|  __ _| |_ ___  ___| |__ (_) |__ | | ___  ___
 *     \___ \ / _` | __/ _ \/ __| '_ \| | '_ \| |/ _ \/ __|
 *      ___) | (_| | || (_) \__ \ | | | | |_) | |  __/\__ \
 *     |____/ \__,_|\__\___/|___/_| |_|_|_.__/|_|\___||___/
 *      ____  _             _        ____       _     _
 *     / ___|| |_ __ _  ___| | _____| __ ) _ __(_) __| | __ _  ___
 *     \___ \| __/ _` |/ __| |/ / __|  _ \| '__| |/ _` |/ _` |/ _ \
 *      ___) | || (_| | (__|   <\__ \ |_) | |  | | (_| | (_| |  __/
 *     |____/ \__\__,_|\___|_|\_\___/____/|_|  |_|\__,_|\__, |\___|
 *                                                      |___/
 */

import "./ERC721Receiver.sol";
import "./Interfaces.sol";
import "./MerkleProof.sol";
import "./OwnableSafe.sol";

/**
 * @title Satoshibles Stacks Bridge Lock
 * @notice Locker for the ethereum side of the Satoshibles Stacks Bridge.
 * @author Aaron Hanson <[email protected]>
 * The StacksBridge can be used at https://stacksbridge.com/
 */
contract SatoshiblesStacksBridgeLock is OwnableSafe, ERC721Receiver {

    /// The maximum number of tokens that can be locked/released in one tx
    uint256 public constant MAX_BATCH_SIZE = 50;

    /// Satoshibles contract instance
    IERC721 public immutable SATOSHIBLE_CONTRACT;

    /// Bridge worker address
    address public worker;

    /// Whether the bridge is open overall
    bool public bridgeIsOpen;

    /// Whether the bridge is open to the public
    bool public bridgeIsOpenToPublic;

    /// The gas escrow fee paid when locking, to cover gas to release later
    uint256 public gasEscrowFee;

    /// Merkle root summarizing all accounts with early access
    bytes32 public earlyAccessMerkleRoot;

    /// Tracks number of early access tickets used per address
    mapping(address => uint256) public earlyAccessTicketsUsed;

    /**
     * @notice Emitted when the bridgeIsOpen flag changes
     * @param isOpen Indicates whether or not the bridge is now open
     */
    event BridgeStateChanged(
        bool indexed isOpen
    );

    /**
     * @notice Emitted when the bridgeIsOpenToPublic flag changes
     * @param isOpenToPublic Indicates whether or not the bridge is now open to the public
     */
    event BridgePublicStateChanged(
        bool indexed isOpenToPublic
    );

    /**
     * @notice Emitted when a Satoshible is locked (bridging to Stacks)
     * @param tokenId The satoshible token ID
     * @param ethereumSender The sender's eth address
     * @param stacksReceiver The receiver's stacks address
     */
    event Locked(
        uint256 indexed tokenId,
        address indexed ethereumSender,
        string stacksReceiver
    );

    /**
     * @notice Requires the bridge to be open
     */
    modifier onlyWhenBridgeIsOpen()
    {
        require(
            bridgeIsOpen == true,
            "Bridge is not open"
        );
        _;
    }

    /**
     * @notice Requires the bridge to be open to the public
     */
    modifier onlyWhenBridgeIsOpenToPublic()
    {
        require(
            bridgeIsOpen == true && bridgeIsOpenToPublic == true,
            "Bridge is not open to public"
        );
        _;
    }

    /**
     * @notice Requires the msg.sender to be the Worker address
     */
    modifier onlyWorker()
    {
        require(
             _msgSender() == worker,
            "Caller is not the worker"
        );
        _;
    }

    /**
     * @param _immutableSatoshible Satoshible contract address
     * @param _worker Bridge worker address
     * @param _earlyAccessMerkleRoot The initial early access merkle root
     */
    constructor(
        address _immutableSatoshible,
        address _worker,
        bytes32 _earlyAccessMerkleRoot
    ) {
        SATOSHIBLE_CONTRACT = IERC721(
            _immutableSatoshible
        );

        worker = _worker;
        earlyAccessMerkleRoot = _earlyAccessMerkleRoot;
        bridgeIsOpen = true;
    }

    /**
     * @notice Locks one or more satoshibles to bridge to Stacks
     * @param _tokenIds The satoshible token IDs
     * @param _stacksReceiver The stacks address to receive the satoshibles
     */
    function lock(
        uint256[] calldata _tokenIds,
        string calldata _stacksReceiver
    )
        external
        payable
        onlyWhenBridgeIsOpenToPublic
    {
        _lock(
            _tokenIds,
            _stacksReceiver
        );
    }

    /**
     * @notice Locks one or more satoshibles to bridge to Stacks (early access)
     * @param _tokenIds The satoshible token IDs
     * @param _stacksReceiver The stacks address to receive the satoshibles
     * @param _earlyAccessTickets Number of early access tickets for _account
     * @param _proof Merkle proof to be verified
     */
    function lockEarlyAccess(
        uint256[] calldata _tokenIds,
        string calldata _stacksReceiver,
        uint256 _earlyAccessTickets,
        bytes32[] calldata _proof
    )
        external
        payable
        onlyWhenBridgeIsOpen
    {
        unchecked {
            require(
                verifyEarlyAccessTickets(
                    _msgSender(),
                    _earlyAccessTickets,
                    _proof
                ) == true,
                "Invalid early access proof"
            );

            require(
                earlyAccessTicketsUsed[_msgSender()] + _tokenIds.length <= _earlyAccessTickets,
                "Not enough tickets remaining"
            );

            earlyAccessTicketsUsed[_msgSender()] += _tokenIds.length;
        }

        _lock(
            _tokenIds,
            _stacksReceiver
        );
    }

    /**
     * @notice Releases one or more satoshibles after bridging from Stacks
     * @param _tokenIds The satoshible token IDs
     * @param _receiver The eth address to receive the satoshibles
     */
    function release(
        uint256[] calldata _tokenIds,
        address _receiver
    )
        external
        onlyWorker
        onlyWhenBridgeIsOpen
    {
        require(
            _tokenIds.length > 0,
            "No token IDs specified"
        );

        require(
            _tokenIds.length <= MAX_BATCH_SIZE,
            "Too many token IDs (max 50)"
        );

        unchecked {
            for (uint256 i = 0; i < _tokenIds.length; i++) {
                SATOSHIBLE_CONTRACT.safeTransferFrom(
                    address(this),
                    _receiver,
                    _tokenIds[i]
                );
            }
        }
    }

    /**
     * @notice Opens or closes the bridge
     * @param _isOpen Whether to open or close the bridge
     */
    function setBridgeIsOpen(
        bool _isOpen
    )
        external
        onlyOwner
    {
        bridgeIsOpen = _isOpen;

        emit BridgeStateChanged(
            _isOpen
        );
    }

    /**
     * @notice Opens or closes the bridge to the public
     * @param _isOpenToPublic Whether to open or close the bridge to the public
     */
    function setBridgeIsOpenToPublic(
        bool _isOpenToPublic
    )
        external
        onlyOwner
    {
        bridgeIsOpenToPublic = _isOpenToPublic;

        emit BridgePublicStateChanged(
            _isOpenToPublic
        );
    }

    /**
     * @notice Sets new earlyAccessMerkleRoot
     * @param _newMerkleRoot The new merkle root
     */
    function setEarlyAccessMerkleRoot(
        bytes32 _newMerkleRoot
    )
        external
        onlyOwner
    {
        earlyAccessMerkleRoot = _newMerkleRoot;
    }

    /**
     * @notice Sets a new worker address
     * @param _newWorker New worker address
     */
    function setWorker(
        address _newWorker
    )
        external
        onlyOwner
    {
        worker = _newWorker;
    }

    /**
     * @notice Sets a new gas escrow fee
     * @param _newGasEscrowFee New gas escrow fee amount in wei
     */
    function setGasEscrowFee(
        uint256 _newGasEscrowFee
    )
        external
        onlyOwner
    {
        gasEscrowFee = _newGasEscrowFee;
    }

    /**
     * @notice Transfers gas escrow ether to worker address
     * @param _amount Amount to transfer (in wei)
     */
    function transferGasEscrowToWorker(
        uint256 _amount
    )
        external
        onlyOwner
    {
        payable(worker).transfer(
            _amount
        );
    }

    /**
     * @notice Withdraws any ERC20 tokens
     * @dev WARNING: Double check token transfer function before calling this
     * @param _token Contract address of token
     * @param _to Address to which to withdraw
     * @param _amount Amount to withdraw
     * @param _hasVerifiedToken Must be true (sanity check)
     */
    function withdrawERC20(
        address _token,
        address _to,
        uint256 _amount,
        bool _hasVerifiedToken
    )
        external
        onlyOwner
    {
        require(
            _hasVerifiedToken == true,
            "Need to verify token"
        );

        IERC20(_token).transfer(
            _to,
            _amount
        );
    }

    /**
     * @notice Withdraws any ERC721 tokens
     * @dev WARNING: Double check token is legit before calling this
     * @param _token Contract address of token
     * @param _to Address to which to withdraw
     * @param _tokenIds Token IDs to withdraw
     * @param _hasVerifiedToken Must be true (sanity check)
     */
    function withdrawERC721(
        address _token,
        address _to,
        uint256[] calldata _tokenIds,
        bool _hasVerifiedToken
    )
        external
        onlyOwner
    {
        require(
            _hasVerifiedToken == true,
            "Need to verify token"
        );

        unchecked {
            for (uint256 i = 0; i < _tokenIds.length; i++) {
                IERC721(_token).safeTransferFrom(
                    address(this),
                    _to,
                    _tokenIds[i]
                );
            }
        }
    }

    /**
     * @notice Verifies a merkle proof for an account's early access tickets
     * @param _account Account to verify
     * @param _earlyAccessTickets Number of early access tickets for _account
     * @param _proof Merkle proof to be verified
     * @return isVerified True if the merkle proof is verified
     */
    function verifyEarlyAccessTickets(
        address _account,
        uint256 _earlyAccessTickets,
        bytes32[] calldata _proof
    )
        public
        view
        returns (bool isVerified)
    {
        bytes32 node = keccak256(
            abi.encodePacked(
                _account,
                _earlyAccessTickets
            )
        );

        isVerified = MerkleProof.verify(
            _proof,
            earlyAccessMerkleRoot,
            node
        );
    }

    /**
     * @dev Locks one or more satoshibles to bridge to Stacks
     * @param _tokenIds The satoshible token IDs
     * @param _stacksReceiver The stacks address to receive the satoshibles
     */
    function _lock(
        uint256[] calldata _tokenIds,
        string calldata _stacksReceiver
    )
        private
    {
        require(
            _tokenIds.length > 0,
            "No token IDs specified"
        );

        require(
            _tokenIds.length <= MAX_BATCH_SIZE,
            "Too many token IDs (max 50)"
        );

        unchecked {
            require(
                msg.value == gasEscrowFee * _tokenIds.length,
                "Incorrect gas escrow ether"
            );

            for (uint256 i = 0; i < _tokenIds.length; i++) {
                SATOSHIBLE_CONTRACT.safeTransferFrom(
                    _msgSender(),
                    address(this),
                    _tokenIds[i]
                );

                emit Locked(
                    _tokenIds[i],
                    _msgSender(),
                    _stacksReceiver
                );
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// Based on OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)
// With renounceOwnership() removed

pragma solidity ^0.8.0;

import "./ContextSimple.sol";

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
abstract contract OwnableSafe is ContextSimple {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

library MerkleProof {
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    )
        internal
        pure
        returns (bool)
    {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        return computedHash == root;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IERC20 {
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);
}

interface IERC721 {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

/**
 * @notice ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
contract ERC721Receiver {

    /**
     * @notice ERC721 token receiver interface
     * @dev Interface for any contract that wants to support safeTransfers
     * from ERC721 asset contracts.
     */
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    )
        external
        pure
        returns (bytes4)
    {
        return 0x150b7a02;
    }
}

// SPDX-License-Identifier: MIT
// Based on OpenZeppelin Contracts v4.4.0 (utils/Context.sol)
// With _msgData() removed

pragma solidity ^0.8.0;

/**
 * @dev Provides the msg.sender in the current execution context.
 */
abstract contract ContextSimple {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}