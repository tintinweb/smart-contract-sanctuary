// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interface/Ikaka721.sol";

contract KeyUpgrade is Ownable, ERC721Holder {
    bool public isOpen;
    uint public openTime;

    IKTA public krb;
    IKTA public kmk;

    event Upgrade(address indexed user, uint indexed tokenIdOld, uint indexed tokenIdNew);

    constructor(){}

    function setAddr(address kmk_, address krb_) public onlyOwner {
        kmk = IKTA(kmk_);
        krb = IKTA(krb_);
    }

    function setIsOpen(bool isOpen_) public onlyOwner {
        isOpen = isOpen_;
    }

    function setOpenTime(uint openTime_) public onlyOwner {
        openTime = openTime_;
    }

    function setApprovalForAll(address account_, bool approval_) public onlyOwner {
        krb.setApprovalForAll(account_, approval_);
        kmk.setApprovalForAll(account_, approval_);
    }
    // ------------- onlyOwner end

    modifier onlyOpen {
        require(isOpen, "Not open");
        _;
    }

    function inventory() public view returns (uint) {
        return krb.balanceOf(address(this));
    }

    function upgradeRabbit() public onlyOpen returns (uint) {
        require(inventory() > 0, "No inventory");
        require(block.timestamp >= openTime, "Not started yet");

        uint kmkId = kmk.tokenOfOwnerByIndex(_msgSender(), 0);
        kmk.safeTransferFrom(_msgSender(), address(this), kmkId);
        uint krbId = krb.tokenOfOwnerByIndex(address(this), 0);
        krb.safeTransferFrom(address(this), _msgSender(), krbId);

        if (inventory() == 0) {
            openTime = openTime + 604800;
        }

        emit Upgrade(_msgSender(), kmkId, krbId);
        return krbId;
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