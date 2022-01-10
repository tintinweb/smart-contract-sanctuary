// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

interface ISide {
    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory);
}

contract PolygonSide is Ownable {
    Cell[16] public cells;
    ISide sideContract;
    address nftCollection = 0x3616a7Bac3B94B9BB27885CbEF29e2571EdA55D1;
    event ChangeTitleEvent(uint256 indexed _index, string _title);
    event ChangeDescriptionEvent(uint256 indexed _index, string _description);
    event ChangeImageEvent(uint256 indexed _index, string _title);
    event ChangeHyperLinkEvent(uint256 indexed _index, string _title);

    struct Cell {
        string title; // TODO: define max length
        string description; // TODO: define max length
        string imageUrl;
        string hyperLink;
    }

    constructor() {
        sideContract = ISide(nftCollection);
    }

    function changeCellTitle(uint256 index, string calldata newTitle) external {
        require(index < 16 && index >= 0, "NFT index is out of range!");
        require(checkOwnership(index), "You don't own this NFT!");
        cells[index].title = newTitle;
        emit ChangeTitleEvent(index, newTitle);
    }

    function changeCellDescription(uint256 index, string calldata newDescription) external {
        require(index < 16 && index >= 0, "NFT index is out of range!");
        require(checkOwnership(index), "You don't own this NFT!");
        cells[index].description = newDescription;
        emit ChangeDescriptionEvent(index, newDescription);
    }

    function changeCellImageUrl(uint256 index, string calldata newImageUrl) external {
        require(index < 16 && index >= 0, "NFT index is out of range!");
        require(checkOwnership(index), "You don't own this NFT!");
        cells[index].imageUrl = newImageUrl;
        emit ChangeImageEvent(index, newImageUrl);
    }

    function changeCellHyperLink(uint256 index, string calldata newHyperLink) external {
        require(index < 16 && index >= 0, "NFT index is out of range!");
        require(checkOwnership(index), "You don't own this NFT!");
        cells[index].hyperLink = newHyperLink;
        emit ChangeHyperLinkEvent(index, newHyperLink);
    }

    function checkOwnership(uint256 nftIndex) internal view returns (bool) {
        uint256[] memory tokens = sideContract.tokensOfOwner(msg.sender);
        bool result = false;
        for (uint256 index; index < tokens.length; index++) {
            if (tokens[index] == nftIndex) {
                result = true;
                break;
            }
        }
        return result;
    }

    function getCells() public view returns(Cell[16] memory) {
        return cells;
    }

    function myNFTs() external view returns (uint256[] memory) {
        return sideContract.tokensOfOwner(msg.sender);
    }

    // TODO:
    // Withdraw Coin
    // Withdraw ERC20

    function withdraw() public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ether coin to withdraw");

        (bool success, ) = (msg.sender).call{value: balance}("");
        require(success, "Transfer failed.");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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