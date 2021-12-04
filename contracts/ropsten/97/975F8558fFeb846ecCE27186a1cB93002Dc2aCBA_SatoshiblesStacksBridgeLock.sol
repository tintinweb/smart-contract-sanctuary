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

import "@openzeppelin/contracts/access/Ownable.sol";

import "./Interfaces.sol";

/**
 * @title Satoshibles Stacks Bridge Lock
 * @notice Locker for the ethereum side of the Satoshibles Stacks Bridge.
 * The StacksBridge can be used at https://stacksbridge.com/
 * @author Aaron Hanson <[email protected]>
 */
contract SatoshiblesStacksBridgeLock is IERC721Receiver, Ownable {

    /// The maximum token batch size for locks/releases
    uint256 public constant MAX_BATCH_SIZE = 50;

    /// Magic value for IERC721Receiver interface
    bytes4 constant ERC721_RECEIVED = 0x150b7a02;

    /// Satoshibles contract instance
    IERC721 public immutable SATOSHIBLE_CONTRACT;

    /// Bridge worker address
    address public worker;

    /// The current state of the bridge
    bool public bridgeIsOpen;

    /// The escrowed fee charged when locking, to pay for gas to release later
    uint256 public gasEscrowFee;

    /**
     * @notice Emitted when the bridgeIsOpen flag changes
     * @param isOpen Indicates whether or not the bridge is now open
     */
    event BridgeStateChanged(
        bool indexed isOpen
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
            "Bridge is currently closed"
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
     * @notice Limits how many tokens can be batch locked/released in one tx
     * @param _tokenIds Array of tokenIds being locked/released
     */
    modifier doesntExceedMaxBatchSize(uint256[] calldata _tokenIds)
    {
        require(
            _tokenIds.length <= MAX_BATCH_SIZE,
            "Batch size too large"
        );
        _;
    }

    /**
     * @notice Boom... Let's go!
     * @param _immutableSatoshible Satoshible contract address
     */
    constructor(
        address _immutableSatoshible,
        address _worker
    ) {
        SATOSHIBLE_CONTRACT = IERC721(
            _immutableSatoshible
        );

        worker = _worker;
        bridgeIsOpen = true;
        gasEscrowFee = 0.01 ether;
    }

    /**
     * @notice Locks a satoshible to bridge it to Stacks
     * @param _tokenId The satoshible token ID
     * @param _stacksReceiver The stacks address to receive the satoshible
     */
    function lock(
        uint256 _tokenId,
        string calldata _stacksReceiver
    )
        external
        payable
        onlyWhenBridgeIsOpen
    {
        require(
            msg.value == gasEscrowFee,
            "Not enough ether"
        );

        _lock(
            _tokenId,
            _stacksReceiver
        );
    }

    /**
     * @notice Locks a batch of satoshibles to bridge to Stacks
     * @param _tokenIds The satoshible token IDs
     * @param _stacksReceiver The stacks address to receive the satoshibles
     */
    function lockBatch(
        uint256[] calldata _tokenIds,
        string calldata _stacksReceiver
    )
        external
        payable
        onlyWhenBridgeIsOpen
        doesntExceedMaxBatchSize(_tokenIds)
    {
        unchecked {
            require(
                msg.value == gasEscrowFee * _tokenIds.length,
                "Not enough ether"
            );

            for (uint256 i = 0; i < _tokenIds.length; i++) {
                _lock(
                    _tokenIds[i],
                    _stacksReceiver
                );
            }
        }
    }

    /**
     * @notice Releases a satoshible after bridging from Stacks
     * @param _tokenId The satoshible token ID
     * @param _receiver The eth address to receive the satoshible
     */
    function release(
        uint256 _tokenId,
        address _receiver
    )
        external
        onlyWorker
        onlyWhenBridgeIsOpen
    {
        _release(
            _tokenId,
            _receiver
        );
    }

    /**
     * @notice Releases a batch of satoshibles after bridging from Stacks
     * @param _tokenIds The satoshible token IDs
     * @param _receiver The eth address to receive the satoshibles
     */
    function releaseBatch(
        uint256[] calldata _tokenIds,
        address _receiver
    )
        external
        onlyWorker
        onlyWhenBridgeIsOpen
        doesntExceedMaxBatchSize(_tokenIds)
    {
        unchecked {
            for (uint256 i = 0; i < _tokenIds.length; i++) {
                _release(
                    _tokenIds[i],
                    _receiver
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
     * @notice Disables Ownable's renounceOwnership()
     */
    function renounceOwnership()
        public
        view
        override
        onlyOwner
    {
        revert("Cannot renounce ownership");
    }

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
        return ERC721_RECEIVED;
    }

    /**
     * @dev Locks a satoshible to bridge to Stacks
     * @param _tokenId The satoshible token ID
     * @param _stacksReceiver The stacks address to receive the satoshible
     */
    function _lock(
        uint256 _tokenId,
        string calldata _stacksReceiver
    )
        private
    {
        SATOSHIBLE_CONTRACT.safeTransferFrom(
            _msgSender(),
            address(this),
            _tokenId
        );

        emit Locked(
            _tokenId,
            _msgSender(),
            _stacksReceiver
        );
    }

    /**
     * @dev Releases a satoshible after bridging from Stacks
     * @param _tokenId The satoshible token ID
     * @param _receiver The eth address to receive the satoshible
     */
    function _release(
        uint256 _tokenId,
        address _receiver
    )
        private
    {
        SATOSHIBLE_CONTRACT.safeTransferFrom(
            address(this),
            _receiver,
            _tokenId
        );
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

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
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