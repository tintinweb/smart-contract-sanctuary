// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "../interface/Ikaka1155.sol";
import "../interface/Ikaka721.sol";


contract BnftConvert is ERC721Holder, ERC1155Holder, Ownable {
    struct MetaInfo {
        address Banker;
        bool Out;
        IKTA BNFT;
        IKTA BNFT_II;
        IKTA KTA;
        IKTN KBOX;
    }
    MetaInfo public Meta;

    struct ConvertInfo {
        bool init;
        bool status;
        uint bnftId;
        uint cardId;
        uint tokenId;
        address owner;
    }
    mapping(uint => ConvertInfo) convert;

    struct CardBagInfo {
        uint bnftId;
        uint cardId;
        address owner;
    }
    mapping(uint => CardBagInfo) public cardBag;

    mapping(uint => uint) public ktaToBnft;
    mapping(uint => uint) public BnftToKta;

    modifier isOpen {
        require(Meta.Out, "not open yet");
        _;
    }

    constructor() {
        Meta.Out = true;
        Meta.Banker = 0xbBAA0201E3c854Cd48d068de9BC72f3Bb7D26954;
        Meta.BNFT = IKTA(0x618AE2792Cad1b838e233b79a4357799Bf2ebE2F);
        Meta.KTA = IKTA(0x3D7bDcF5e0Bb389DE1c4D12Ee6a88B90E14c6486);
        Meta.KBOX = IKTN(0x36e209A5042f582004250560a7748d8f536359Fc);
    }

    function setBNFT(address bnft) public onlyOwner {
        Meta.BNFT = IKTA(bnft);
    }

    function setKTA(address kta) public onlyOwner {
        Meta.KTA = IKTA(kta);
    }

    function setKBOX(address kbox) public onlyOwner {
        Meta.KBOX = IKTN(kbox);
    }

    function setBanker(address banker) external onlyOwner {
        Meta.Banker = banker;
    }

    function setOpen(bool operate) public onlyOwner {
        Meta.Out = operate;
    }

    function setApprovalForAll(address account) public onlyOwner {
        Meta.KTA.setApprovalForAll(account, true);
    }

    function mint(uint tokenId_, uint cardId_, uint mode_) internal returns(uint) {
        if (mode_ == 1 || mode_ == 2) {
            Meta.KTA.mintWithId(_msgSender(), cardId_, tokenId_);
            return tokenId_;
        }
        if (mode_ == 3) {
            return Meta.KTA.mint(_msgSender(), cardId_); 
        }
        return 0;
    }

    function convertByKtaId(uint tokenId_) public view returns(ConvertInfo memory)  {
        uint bnftId = ktaToBnft[tokenId_];
        return convert[bnftId];
    }
    function convertByBnftId(uint bnftId_) public view returns(ConvertInfo memory)  {
        return convert[bnftId_];
    }

    function kakaToBnft(uint bnftId_) public isOpen returns(uint) {
        require(convert[bnftId_].init, "not activate");
        require(convert[bnftId_].status, "is convert");
        
        Meta.KTA.safeTransferFrom(_msgSender(), address(this), convert[bnftId_].tokenId);
        Meta.BNFT.safeTransferFrom(address(this), _msgSender(), bnftId_);

        convert[bnftId_].status = false;
        return convert[bnftId_].tokenId;
    }

    function bnftToKaka(uint bnftId_, uint cardId_, uint tokenId_ , uint mode_, uint expireAt_, bytes32 r_, bytes32 s_, uint8 v_) public returns(uint) {
        require(block.timestamp <= expireAt_, "Signature expired");
        bytes32 hash =  keccak256(abi.encodePacked(_msgSender(), bnftId_, tokenId_, cardId_, mode_, expireAt_));
        address a = ecrecover(hash, v_, r_, s_);
        require(a == Meta.Banker, "Invalid signature");

        Meta.BNFT.safeTransferFrom(_msgSender(), address(this), bnftId_);

        if (mode_ == 4) {
            Meta.KBOX.mint(_msgSender(), cardId_, 1);
            cardBag[bnftId_] = CardBagInfo({
                bnftId: bnftId_,
                cardId: cardId_,
                owner: _msgSender()
            });
            return cardId_;
        }

        if (convert[bnftId_].init) {
            Meta.KTA.safeTransferFrom(address(this), _msgSender(), tokenId_);
            convert[bnftId_].status = true;
            return convert[bnftId_].tokenId;
        }

        uint tokenId = mint(tokenId_, cardId_, mode_);
        ktaToBnft[tokenId] = bnftId_;
        convert[bnftId_] = ConvertInfo({
            init: true,
            status: true,
            bnftId: bnftId_,
            cardId: cardId_,
            tokenId: tokenId,
            owner: _msgSender()
        });
        return tokenId;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

interface IKTA{
    function balanceOf(address owner) external view returns(uint256);
    function cardIdMap(uint) external returns(uint); // tokenId => cardId
    function cardInfoes(uint) external returns(uint cardId, string memory name, uint currentAmount, uint maxAmount, string memory _tokenURI);
    function tokenURI(uint256 tokenId_) external view returns(string memory);
    function mint(address player_, uint cardId_) external returns(uint256);
    function mintMulti(address player_, uint cardId_, uint amount_) external returns(uint256);
    function burn(uint tokenId_) external returns (bool);
    function burnMulti(uint[] calldata tokenIds_) external returns (bool);
    function ownerOf(uint256 tokenId) external view returns (address);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool approved) external;
    function tokenOfOwnerByIndex(address owner, uint256 index) external returns (uint256);

    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function mintWithId(address player_, uint id_, uint tokenId_) external returns (bool);
    function totalSupply() external view returns (uint);
    function burned() external view returns (uint);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

interface IKTN {
    function mintBatch(address to_, uint256[] memory ids_, uint256[] memory amounts_) external returns (bool);
    function mint(address to_, uint cardId_, uint amount_) external returns (bool);
    function safeTransferFrom(address from, address to, uint256 cardId, uint256 amount, bytes memory data_) external;
    function safeBatchTransferFrom(address from_, address to_, uint256[] memory ids_, uint256[] memory amounts_, bytes memory data_) external;
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function balanceOf(address account, uint256 tokenId) external view returns (uint);
    function burned(uint) external view returns (uint);
    function burn(address account, uint256 id, uint256 value) external;
    function cardInfoes(uint) external view returns(uint cardId, string memory name, uint currentAmount, uint burnedAmount, uint maxAmount, string memory _tokenURI);
    
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

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
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