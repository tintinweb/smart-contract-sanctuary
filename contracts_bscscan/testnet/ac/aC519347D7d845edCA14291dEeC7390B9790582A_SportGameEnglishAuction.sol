// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./SportGameAuctionBase.sol";
import "./VerifySignature.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


contract SportGameEnglishAuction is SportGameAuctionBase {

    struct NFTSaleModel {
        uint256 tokenId;
        uint256 floorPrice;
        string symbol;
        uint256 deadline;
    }

    mapping(uint256 => NFTSaleModel) private _tokenPrices;


    event NFTForSaleEvent(address owner, uint256 tokenId, uint256 unitPrice, string symbol, uint256 deadline);
    event AcceptOfferEvent(address from, address to, uint256 tokenId, string symbol, uint256 amount);
    event CancelListingNFTEvent(address owner, uint256 tokenId);

    constructor(address nftContract) SportGameAuctionBase(nftContract) {}

    function nftForSale(uint256 tokenId, uint256 floorPrice, string memory symbol, uint256 deadline) public {
        require(floorPrice > 0, "Err: UnitPrice-Cannot-Zero");

        if (compareStrings("ETH", symbol) || compareStrings("BNB", symbol) || compareStrings("MATIC", symbol)) {
            revert("Err: Wrong-Symbol");
        }

        address contractAddress = _tokenContracts[symbol];
        require(contractAddress != address(0x0), "Err: Symbol-Does-Not-Supported-Yet");
 
        require(tokenExists(tokenId), concatenate("Err: Token-Id-Does-Not-Exists-", Strings.toString(tokenId)));
        require(tokenIsMine(tokenId), concatenate("Err: Token-Id-Is-Not-Mine-", Strings.toString(tokenId)));
        if (_nftContract.getApproved(tokenId) != address(this)) {
            require(_nftContract.isApprovedForAll(_msgSender(), address(this)), concatenate("Err: Token-Id-Does-Not-Approve", Strings.toString(tokenId)));
        }

        // set unit price for each NFT item
        _tokenPrices[tokenId] = NFTSaleModel(tokenId, floorPrice, symbol, deadline);
        
        emit NFTForSaleEvent(_msgSender(), tokenId, floorPrice, symbol, deadline);
    }

    function acceptOffer(address _signer, uint256 offerPrice, uint256 tokenId, string memory _message, uint nonce, bytes memory signature) public {
        require(tokenExists(tokenId), "Err: Token-Id-Does-Not-Exists");

        address _to = _signer;
        require(VerifySignature.verify(_signer, _to, offerPrice, tokenId, _message, nonce, signature), "Err: Verification-Signature-Failure");

        NFTSaleModel memory model = _tokenPrices[tokenId];
        require(offerPrice > model.floorPrice, "Err: Offer-Price-Invalid");
        
        require(model.deadline >= block.timestamp, "Err: NFT-Auction-Time-Ended");

        address contractAddress = _tokenContracts[model.symbol];
        require(contractAddress != address(0x0), "Err: Symbol-Does-Not-Supported-Yet");

        IERC20 _tokenContract = IERC20(_tokenContracts[model.symbol]);
        require(_tokenContract.allowance(_to, address(this)) >= offerPrice, "Err: Allowance-Insufficient");
        require(_tokenContract.balanceOf(_to) >= offerPrice, "Err: Balance-Insufficient");

        // Firstly transfer NFT to buyer
        address nftOwner = _nftContract.ownerOf(tokenId);
        _nftContract.safeTransferFrom(nftOwner, _to, tokenId);

        // Secondly transfer token from buyer to seller
        require(_tokenContract.transferFrom(_to, nftOwner, offerPrice), "Err: TransferFrom-Failure");
        
        delete _tokenPrices[tokenId];

        emit AcceptOfferEvent(nftOwner, _to, tokenId, model.symbol, offerPrice);
    }
 
    function cancelListingNFT(uint256 tokenId) public {
        require(tokenExists(tokenId), "Err: Token-Id-Does-Not-Exists");
        require(tokenIsMine(tokenId), "Err: Token-Is-Not-Yours");

        require(_tokenPrices[tokenId].deadline > 0, "Err: NFT-Not-On-Sale");

        delete _tokenPrices[tokenId];

        emit CancelListingNFTEvent(_msgSender(), tokenId);
    }

    // Fetch NFT by token ids
    // function fetchTokenSaleInfo(uint256[] memory tokenIds) public view returns (NFTSaleModel[] memory) {
    //     NFTSaleModel[] memory list = new NFTSaleModel[](tokenIds.length);
    //     for (uint256 i = 0; i < tokenIds.length; i++) {
    //         list[i] = _tokenPrices[tokenIds[i]];
    //     }
    //     return list;
    // }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

library VerifySignature {
    
    function getMessageHash(
        address _to,
        uint256 _amount,
        uint256 _tokenId,
        string memory _message,
        uint _nonce
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_to, _amount, _tokenId, _message, _nonce));
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash)
            );
    }

    function verify(
        address _signer,
        address _to,
        uint256 _amount,
        uint256 _tokenId,
        string memory _message,
        uint _nonce,
        bytes memory signature
    ) internal pure returns (bool) {
        bytes32 messageHash = getMessageHash(_to, _amount, _tokenId, _message, _nonce);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature) == _signer;
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)
        internal
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
 
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";  
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol"; 


contract SportGameAuctionBase is Context, Ownable {

    IERC721 internal _nftContract;

    mapping(string => address) internal _tokenContracts;

    constructor(address nftContract) {
        _nftContract = IERC721(nftContract);

        _tokenContracts["ETH"] = address(0x01);
        _tokenContracts["BNB"] = address(0x02);
        _tokenContracts["MATIC"] = address(0x03);

        _tokenContracts["WETH"] = address(0xc778417E063141139Fce010982780140Aa0cD5Ab); // rinkeby
        _tokenContracts["WETH"] = address(0x3C655B9671273F7660D7fDF411c9A2729bdd57Ef); // testnet on BSC
    }

    function setTokenContract(string memory symbol, address contractAddress) public onlyOwner  {
        _tokenContracts[symbol] = contractAddress;
    }

    function getTokenContract(string memory symbol) public view returns (address)  {
        return _tokenContracts[symbol];
    }

    function tokenExists(uint256 tokenId) internal view returns (bool) { 
        return _nftContract.ownerOf(tokenId) != address(0x0);
    }

    function tokenIsMine(uint256 tokenId) internal view returns (bool) { 
        return _nftContract.ownerOf(tokenId) == _msgSender();
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function concatenate(string memory a, string memory b) internal pure returns(string memory) {
        return string(abi.encodePacked(a, " ", b));
    }


    function renounce(address to) public payable onlyOwner {
        address payable addr = payable(to);
        selfdestruct(addr);
    }

    // Use this in case ETH/BNB/MATIC are sent to the contract by mistake
    event SettleCoinEvent(bool isSuccess, bytes data, address to, uint256 amount);
    function settleCoin(address to) public onlyOwner {   
        uint256 total = address(this).balance;
        require(total > 0, "Coin-Balance-Insufficient");
        // payable(to).transfer(total); 
        (bool sent, bytes memory data) = payable(to).call{value: total}("");
        emit SettleCoinEvent(sent, data, to, total);
    }   

    // Use this in case other tokens are sent to the contract by mistake
    function settleToken(address tokenAddress, address to) public onlyOwner {   
        uint256 total = IERC20(tokenAddress).balanceOf(address(this));
        require(total > 0, "Token-Balance-Insufficient");
        require(IERC20(tokenAddress).transfer(to, total), "SettleAccount-Transfer-Failure"); 
    } 

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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