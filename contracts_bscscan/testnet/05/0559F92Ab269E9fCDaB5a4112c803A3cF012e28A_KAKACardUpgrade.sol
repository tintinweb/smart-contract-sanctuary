// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

interface IDODO{
    function tokenURI(uint256 tokenId) external view returns(string memory);
    function getApproved(uint256 tokenId) external view returns(address operator);
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovalForAll(address owner, address operator) external view returns(bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external returns(address user);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

interface IKTN {
    function mintBatch(address to_, uint256[] memory ids_, uint256[] memory amounts_) external returns (bool);
    function safeBatchTransferFrom(address from_, address to_, uint256[] memory ids_, uint256[] memory amounts_, bytes memory data_) external;
    function setApprovalForAll(address operator, bool approved) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

interface IKTA{
    function balanceOf(address owner) external returns(uint256);
    function cardIdMap(uint) external view returns(uint); // tokenId => cardId
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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interface/Ikaka721.sol";
import "../interface/Ikaka1155.sol";
import "../interface/Idodo.sol";

contract KAKACardUpgrade is Ownable, ERC721Holder, ERC1155Holder {
    bool public status;

    IKTA public oldKTA;
    IKTA public newKTA;
    IKTN public oldKTN;
    IKTN public newKTN;
    IDODO public dodo;

    event Swap721(address indexed user, uint indexed tokenIdOld, uint indexed tokenIdNew);
    event Swap1155(address indexed user);
    event SwapDodo(address indexed user, uint indexed tokenIdOld, uint indexed tokenIdNew);

    constructor(){}

    function setAddr(address _dodo, address oldKTN_, address oldKTA_, address newKTN_, address newKTA_) public onlyOwner{
        dodo = IDODO(_dodo);
        oldKTN = IKTN(oldKTN_);
        oldKTA = IKTA(oldKTA_);
        newKTN = IKTN(newKTN_);
        newKTA = IKTA(newKTA_);
    }

    function open() public onlyOwner {
        require(!status,"opened");
        status = true;
    }

    function close() public onlyOwner {
        require(status,"closed");
        status = false;
    }

    function setApprovalForAll(address account_, bool approval_) public onlyOwner returns (bool){
        oldKTA.setApprovalForAll(account_, approval_);
        oldKTN.setApprovalForAll(account_, approval_);
        newKTA.setApprovalForAll(account_, approval_);
        newKTN.setApprovalForAll(account_, approval_);
        dodo.setApprovalForAll(account_, approval_);
        return true;
    }
    // ------------- onlyOwner end

    modifier onlyOpen {
        require(status, "not open");
        _;
    }

    // token id => card Id
    function dodoIdMap(uint tokenId_) public pure returns(uint){
        require(tokenId_>=1 && tokenId_<=5337,"token id does not exist");
        if(tokenId_ <=1000){return 20001;}
        else if(tokenId_ <= 1735){return 20002;}
        else if(tokenId_ <= 2445){return 20003;}
        else if(tokenId_ <= 3150){return 20004;}
        else if(tokenId_ <= 3850){return 20005;}
        else if(tokenId_ <= 4465){return 20006;}
        else if(tokenId_ <= 4743){return 20007;}
        else if(tokenId_ <= 5036){return 20008;}
        else if(tokenId_ <= 5329){return 20009;}
        else if(tokenId_ <= 5334){return 20010;}
        else if(tokenId_ <= 5337){return 20011;}

        return 0;
    }

    function swap(uint[] calldata dodoIds_, uint[] calldata ktaIds_, uint[] calldata ktnIds_, uint[] calldata ktnAmounts_) public onlyOpen returns (bool) {
        swapDodo(dodoIds_);
        swap721(ktaIds_);
        swap1155(ktnIds_, ktnAmounts_);
        return true;
    }

    function swapDodo(uint[] calldata ids_) public onlyOpen returns (bool) {
        for(uint i=0; i < ids_.length; i++){
            require(dodo.ownerOf(ids_[i]) == msg.sender,"Not the owner of this card");
            dodo.safeTransferFrom(msg.sender, address(this), ids_[i]);

            uint new_cid = dodoIdMap(ids_[i]);

            uint tokenId_new = newKTA.mint(msg.sender, new_cid);
            emit SwapDodo(msg.sender, ids_[i], tokenId_new);
        }
        return true;
    }

    function swap721(uint[] calldata ids_) public onlyOpen returns (bool) {
        for (uint i = 0; i < ids_.length; ++i) {
            uint tokenId = ids_[i];
            if (tokenId == 1193 || tokenId == 1313) {
                swapWrong721(tokenId);
                continue;
            }
            uint cardId = oldKTA.cardIdMap(tokenId);
            oldKTA.safeTransferFrom(_msgSender(), address(this), tokenId);
            uint tokenIdNew = newKTA.mint(_msgSender(), cardId);
            emit Swap721(_msgSender(), tokenId, tokenIdNew);
        }
        return true;
    }

    function swap1155(uint[] calldata ids_, uint[] calldata amounts_) public onlyOpen returns (bool) {
        oldKTN.safeBatchTransferFrom(_msgSender(), address(this), ids_, amounts_, "");
        newKTN.mintBatch(_msgSender(), ids_, amounts_);
        emit Swap1155(_msgSender());
        return true;
    }

    function swapWrong721(uint tokenId_) internal {
        require(tokenId_ == 1193 || tokenId_ == 1313, "must be wrong ids");

        uint cardId = oldKTA.cardIdMap(tokenId_);
        require(cardId == 20006, "not this one");
        // recall a Spider man
        oldKTA.safeTransferFrom(_msgSender(), address(this), tokenId_);
        // mint a new Thor 
        uint tokenIdNew = newKTA.mint(_msgSender(), 20007);
        emit Swap721(_msgSender(), tokenId_, tokenIdNew);
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
    )
        external
        returns(bytes4);

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
    )
        external
        returns(bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
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
        return interfaceId == type(IERC1155Receiver).interfaceId
            || super.supportsInterface(interfaceId);
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
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
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
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
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

