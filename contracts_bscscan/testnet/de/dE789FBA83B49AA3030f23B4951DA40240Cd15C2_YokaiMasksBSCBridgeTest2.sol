// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IYokaiMasks {
    function ownerOf(uint256 tokenId) external returns (address);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
}

contract YokaiMasksBSCBridgeTest2 is IERC721Receiver, Ownable {
    // Signer address
    address public signerAddress;

    // Address of the Yokai Masks Ethereum contract
    address public yokaiMasksContract;

    // Nonces for tracking mint transactions
    mapping(address => mapping(uint256 => bool)) public processedNonces;

    event SentToBridge(
        address indexed from,
        uint256 indexed mintIndex,
        uint256 indexed date,
        uint256 nonce,
        bytes signature
    );

    event MaskClaimed(
        address indexed to,
        uint256 indexed mintIndex,
        uint256 indexed date,
        uint256 nonce,
        bytes signature
    );

    constructor() {
        signerAddress = 0x13cacbc303b5d45164e31E6b6d73c1c445b4BA52;
    }

     /**
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function sendMaskToBridge(uint256 _mintIndex, uint256 _nonce, bytes calldata _signature) external {
        address from = msg.sender;
        bytes32 message = prefixed(keccak256(abi.encodePacked(
            from,
            _mintIndex,
            _nonce
        )));

        require(recoverSigner(message, _signature) == signerAddress, 'Wrong signature');
        require(processedNonces[from][_nonce] == false, 'Transfer already processed');

        processedNonces[from][_nonce] = true;

        IYokaiMasks(yokaiMasksContract).safeTransferFrom(msg.sender, address(this), _mintIndex);
        
        emit SentToBridge(msg.sender, _mintIndex, block.timestamp, _nonce, _signature);
    }

    function claimMask(uint256 _mintIndex, uint256 _nonce, bytes calldata _signature) external {
        address from = msg.sender;
        bytes32 message = prefixed(keccak256(abi.encodePacked(
            from,
            _mintIndex,
            _nonce
        )));

        require(recoverSigner(message, _signature) == signerAddress, 'Wrong signature');
        require(processedNonces[from][_nonce] == false, 'Transfer already processed');

        processedNonces[from][_nonce] = true;

        if (IYokaiMasks(yokaiMasksContract).ownerOf(_mintIndex) == address(this)) {
            IYokaiMasks(yokaiMasksContract).safeTransferFrom(address(this), msg.sender, _mintIndex);
        }
        
        emit MaskClaimed(msg.sender, _mintIndex, block.timestamp, _nonce, _signature);
    }

    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(
            '\x19Ethereum Signed Message:\n32', 
            hash
        ));
    }

    function recoverSigner(bytes32 message, bytes memory sig)
        internal
        pure
        returns (address)
    {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = splitSignature(sig);

        return ecrecover(message, v, r, s);
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (uint8, bytes32, bytes32)
    {
        require(sig.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    /**
     * @dev Update signer address by the owner
     */
    function setSigner(address payable _signerAddress) external onlyOwner {
        signerAddress = _signerAddress;
    }

    /**
     * @dev Set the Yokai Masks Ethereum contract address
     */
    function setYokaiMasksContract(address _address) external onlyOwner {
        yokaiMasksContract = _address;
    }
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

