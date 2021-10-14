/**
 *Submitted for verification at Etherscan.io on 2021-10-14
*/

pragma solidity ^0.8.0;


// SPDX-License-Identifier: MIT
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


abstract contract OGB {
    function ownerOf(uint256 tokenId) public virtual view returns (address);
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual;
}

abstract contract EVB {
    function ownerOf(uint256 tokenId) public virtual view returns (address);
    function getTimeVaulted(uint256 tokenId) external virtual view returns(uint256);
}

contract OG_Vault is ERC721Holder, Ownable {
    OGB ogb;
    EVB evb;

    uint256 stakePeriod = 300; // 5 minutes for testing purposes
    mapping(uint256 => uint256) tokenToTimeVaulted;

    event ClaimedMultiple(address _from, uint256[] _tokenIds);
    event Claimed(address _from, uint256 _tokenId);

    constructor(){
        ogb = OGB(0xAa30A3471bb9e817FAB451fC2c3B831D7991F95B);
    }

    function claimBull(uint256 tokenId) public {
        require(evb.getTimeVaulted(tokenId) + stakePeriod < block.timestamp, "Not vaulted for 1 year or longer");
        require(evb.ownerOf(tokenId) == msg.sender, "You must own the Evolved Bull of the Bull you're trying to claim");

        ogb.safeTransferFrom(address(this), msg.sender, tokenId);
        emit Claimed(msg.sender, tokenId);
    }

    function claimNBulls(uint256[] memory tokenIds) public {
        require(tokenIds.length < 31, "Can't claim more than 30 bulls at once.");

        for (uint i = 0; i < tokenIds.length; i++) {
            require(evb.getTimeVaulted(tokenIds[i]) + stakePeriod < block.timestamp, "Not vaulted for 1 year or longer");
            require(evb.ownerOf(tokenIds[i]) == msg.sender, "You must own the Evolved Bull of the Bull you're trying to claim");

            ogb.safeTransferFrom(address(this), msg.sender, tokenIds[i]);
        }
        emit ClaimedMultiple(msg.sender, tokenIds);
    }

    function setEvolvedBullContract(address _address) external onlyOwner{
        evb = EVB(_address);
    }


}