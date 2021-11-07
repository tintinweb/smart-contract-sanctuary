//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./interfaces/IERC20.sol";
import "./interfaces/IERC721.sol";
import "./libraries/Ownable.sol";
import "./libraries/ECDSA.sol";
import "./libraries/TransferHelper.sol";

contract ExchangeNFT is Ownable {
    using ECDSA for bytes32;

    address public ERC721;

    // Mitigating Replay Attacks
    mapping(address => mapping(uint256 => bool)) seenNonces;

    // Events
    // addrs: from, to, token
    event BuyNFTNormal(
        address[3] addrs,
        uint256 tokenId,
        uint256 amount
    );
    event BuyNFTETH(address[3] addrs, uint256 tokenId, uint256 amount);
    event AuctionNFT(
        address[3] addrs,
        uint256 tokenId,
        uint256 amount
    );
    event AcceptOfferNFT(
        address[3] addrs,
        uint256 tokenId,
        uint256 amount
    );

    constructor(
        address _erc721
    ) public {
        ERC721 = _erc721;
    }

    function setNFTAddress(address _nft) public onlyOwner {
        ERC721 = _nft;
    }

    modifier verifySignature(
        uint256 nonce,
        address[4] memory _tradeAddress,
        uint256[3] memory _attributes,
        bytes memory signature
    ) {
        // This recreates the message hash that was signed on the client.
        // bytes32 hash = keccak256(
        //     abi.encodePacked(
        //         msg.sender,
        //         nonce,
        //         _tradeAddress,
        //         _attributes
        //     )
        // );
        // bytes32 messageHash = hash.toEthSignedMessageHash();
        // // Verify that the message's signer is the owner of the order
        // require(messageHash.recover(signature) == owner(), "Invalid signature");
        // require(!seenNonces[msg.sender][nonce], "Used nonce");
        // seenNonces[msg.sender][nonce] = true;
        _;
    }

    function checkFeeProductExits(
        address feeAddress,
        uint256[3] memory _attributes
    ) internal pure returns (uint256 amount, uint256 feeProduct) {
        amount = _attributes[0];
        // Check fee address exits
        if (feeAddress != address(0)) {
            feeProduct = (_attributes[0] * _attributes[2]) / 100;
            amount = _attributes[0] - feeProduct;
        }
    }

    // Buy NFT normal by token ERC-20
    // address[4]: buyer, seller, token, fee
    // uint256[3]: amount, tokenId, feePercent
    function buyNFTNormal(
        address[4] calldata _tradeAddress,
        uint256[3] calldata _attributes,
        uint256 nonce,
        bytes calldata signature
    ) external verifySignature(nonce, _tradeAddress, _attributes, signature) {
        // check allowance of buyer
        require(
            IERC20(_tradeAddress[2]).allowance(msg.sender, address(this)) >=
                _attributes[0],
            "token allowance too low"
        );
        (uint256 amount, uint256 feeProduct) = checkFeeProductExits(_tradeAddress[3], _attributes);

        if (feeProduct != 0) {
            // transfer token to fee address
            IERC20(_tradeAddress[2]).transferFrom(
                msg.sender,
                _tradeAddress[3],
                feeProduct
            );
        }
        // transfer token from buyer to seller
        IERC20(_tradeAddress[2]).transferFrom(
            msg.sender,
            _tradeAddress[1],
            amount
        );
        IERC721(ERC721).safeTransferFrom(
            _tradeAddress[1],
            msg.sender,
            _attributes[1]
        );
        emit BuyNFTNormal(
            [msg.sender, _tradeAddress[1], _tradeAddress[2]],
            _attributes[1],
            _attributes[0]
        );
    }

    // Buy NFT normal by ETH
    // address[3]: buyer, seller, token, fee
    // uint256[2]: amount, tokenId, feePercent
    function buyNFTETH(
        address[4] calldata _tradeAddress,
        uint256[3] calldata _attributes,
        uint256 nonce,
        bytes calldata signature
    )
        external
        payable
        verifySignature(nonce, _tradeAddress, _attributes, signature)
    {
        (uint256 amount, uint256 feeProduct) = checkFeeProductExits(_tradeAddress[3], _attributes);
        // transfer token to fee address
        if (feeProduct != 0) {
            TransferHelper.safeTransferETH(_tradeAddress[3], feeProduct);
        }
        TransferHelper.safeTransferETH(_tradeAddress[1], amount);

        IERC721(ERC721).safeTransferFrom(
            _tradeAddress[1],
            msg.sender,
            _attributes[1]
        );
        // refund dust eth, if any
        if (msg.value > _attributes[0])
            TransferHelper.safeTransferETH(
                msg.sender,
                msg.value - _attributes[0]
            );
        emit BuyNFTETH(
            [msg.sender, _tradeAddress[1], _tradeAddress[2]],
            _attributes[1],
            _attributes[0]
        );
    }

    // Auction NFT
    // address[4]: buyer, seller, token, fee
    // uint256[2]: amount, tokenId, feePercent
    function auctionNFT(
        address[4] calldata _tradeAddress,
        uint256[3] calldata _attributes
    ) public onlyOwner {
        // check allowance of buyer
        require(
            IERC20(_tradeAddress[2]).allowance(
                _tradeAddress[0],
                address(this)
            ) >= _attributes[0],
            "token allowance too low"
        );
        if (_tradeAddress[1] == msg.sender) {
            require(
                IERC721(ERC721).isApprovedForAll(msg.sender, address(this)),
                "tokenId do not approve for contract"
            );
        } else {
            require(
                IERC721(ERC721).getApproved(_attributes[1]) == address(this),
                "tokenId do not approve for contract"
            );
        }

        (uint256 amount, uint256 feeProduct) = checkFeeProductExits(_tradeAddress[3], _attributes);
        if (feeProduct != 0) {
            // transfer token to fee address
            IERC20(_tradeAddress[2]).transferFrom(
                _tradeAddress[0],
                _tradeAddress[3],
                feeProduct
            );
        }

        // transfer token from buyer to seller
        IERC20(_tradeAddress[2]).transferFrom(
            _tradeAddress[0],
            _tradeAddress[1],
            amount
        );
        IERC721(ERC721).safeTransferFrom(
            _tradeAddress[1],
            _tradeAddress[0],
            _attributes[1]
        );
        emit AuctionNFT(
            [msg.sender, _tradeAddress[1], _tradeAddress[2]],
            _attributes[1],
            _attributes[0]
        );
    }

    // Accept offer from buyer
    // address[4]: buyer, seller, token, fee
    // uint256[3]: amount, tokenId, feePercent
    function acceptOfferNFT(
        address[4] calldata _tradeAddress,
        uint256[3] calldata _attributes,
        uint256 nonce,
        bytes calldata signature
    ) external verifySignature(nonce, _tradeAddress, _attributes, signature) {
        require(
            IERC721(ERC721).getApproved(_attributes[1]) == address(this),
            "tokenId do not approve for contract"
        );
        // check allowance of buyer
        require(
            IERC20(_tradeAddress[2]).allowance(
                _tradeAddress[0],
                address(this)
            ) >= _attributes[0],
            "token allowance too low"
        );

        (uint256 amount, uint256 feeProduct) = checkFeeProductExits(_tradeAddress[3], _attributes);
        if (feeProduct != 0) {
            // transfer token to fee address
            IERC20(_tradeAddress[2]).transferFrom(
                _tradeAddress[0],
                _tradeAddress[3],
                feeProduct
            );
        }

        // transfer token from buyer to seller
        IERC20(_tradeAddress[2]).transferFrom(
            _tradeAddress[0],
            msg.sender,
            amount
        );

        IERC721(ERC721).safeTransferFrom(
            _tradeAddress[1],
            _tradeAddress[0],
            _attributes[1]
        );
        emit AcceptOfferNFT(
            [msg.sender, _tradeAddress[1], _tradeAddress[2]],
            _attributes[1],
            _attributes[0]
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 (utils/introspection/IERC165.sol)

pragma solidity 0.6.12;

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
pragma solidity 0.6.12;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // EIP 2612
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 (token/ERC721/IERC721.sol)

pragma solidity 0.6.12;

import "./IERC165.sol";

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

//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

library ECDSA {

  /**
   * @dev Recover signer address from a message by using their signature
   * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
   * @param signature bytes signature, the signature is generated using web3.eth.sign()
   */
  function recover(bytes32 hash, bytes memory signature)
    internal
    pure
    returns (address)
  {
    bytes32 r;
    bytes32 s;
    uint8 v;

    // Check the signature length
    if (signature.length != 65) {
      return (address(0));
    }

    // Divide the signature in r, s and v variables with inline assembly.
    assembly {
      r := mload(add(signature, 0x20))
      s := mload(add(signature, 0x40))
      v := byte(0, mload(add(signature, 0x60)))
    }

    // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
    if (v < 27) {
      v += 27;
    }

    // If the version is correct return the signer address
    if (v != 27 && v != 28) {
      return (address(0));
    } else {
      // solium-disable-next-line arg-overflow
      return ecrecover(hash, v, r, s);
    }
  }

  /**
    * toEthSignedMessageHash
    * @dev prefix a bytes32 value with "\x19Ethereum Signed Message:"
    * and hash the result
    */
  function toEthSignedMessageHash(bytes32 hash)
    internal
    pure
    returns (bytes32)
  {
    return keccak256(
      abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
    );
  }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: APPROVE_FAILED");
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FAILED");
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FROM_FAILED");
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    }
}